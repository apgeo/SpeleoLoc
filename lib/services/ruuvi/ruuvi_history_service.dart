import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:speleoloc/services/beacon/beacon_repository.dart';
import 'package:speleoloc/services/ruuvi/ruuvi_history_repository.dart';
import 'package:speleoloc/services/ruuvi/ruuvi_log_protocol.dart';
import 'package:speleoloc/services/ruuvi/ruuvi_scan_service.dart';
import 'package:speleoloc/utils/app_exceptions.dart';
import 'package:speleoloc/utils/app_logger.dart';

enum RuuviDownloadPhase { searching, connecting, downloading, storing }

class RuuviDownloadProgress {
  final RuuviDownloadPhase phase;
  final int samplesReceived;
  const RuuviDownloadProgress(this.phase, this.samplesReceived);
}

class RuuviDownloadResult {
  /// Distinct timestamps written (merged wide rows, after dedupe).
  final int timestampsStored;
  final String? firmwareVersion;
  const RuuviDownloadResult({
    required this.timestampsStored,
    this.firmwareVersion,
  });
}

/// Downloads a Ruuvi tag's on-board measurement log over GATT and stores
/// it via [RuuviHistoryRepository].
///
/// Flow: locate the peripheral through the shared advertisement scan (the
/// payload MAC is the only identity iOS exposes), connect, subscribe to
/// NUS TX notifications *first* (production firmware drops unregistered
/// centrals after ~12 s), then request the log since the newest stored
/// reading (minus a small overlap — the upsert dedupes). Samples are
/// accumulated and stored in one transaction at the end; a tag-side error
/// message resumes the request from the last received timestamp. The
/// firmware revision is read from the Device Information Service while
/// connected. Foreground-only by design.
class RuuviHistoryService {
  static const _findTimeout = Duration(seconds: 30);
  static const _connectTimeout = Duration(seconds: 15);

  /// The tag streams continuously during a transfer; a silent gap this
  /// long means the link died (the tag's own transfer watchdog is 5 min).
  static const _inactivityTimeout = Duration(seconds: 30);
  static const _sinceOverlap = Duration(minutes: 10);
  static const _maxErrorResumes = 2;

  static const _disServiceUuid = '180A';
  static const _disFirmwareRevisionUuid = '2A26';

  final RuuviHistoryRepository _history;
  final BeaconRepository _beacons;
  final _log = AppLogger.of('RuuviHistoryService');

  RuuviHistoryService(this._history, this._beacons);

  Future<RuuviDownloadResult> download(
    String macAddress, {
    void Function(RuuviDownloadProgress progress)? onProgress,
  }) async {
    final mac = macAddress.toUpperCase();
    onProgress?.call(
      const RuuviDownloadProgress(RuuviDownloadPhase.searching, 0),
    );
    final device = await _findDevice(mac);
    onProgress?.call(
      const RuuviDownloadProgress(RuuviDownloadPhase.connecting, 0),
    );
    try {
      // License acknowledgment required by flutter_blue_plus 2.x for GATT
      // connects: nonprofit/personal use covers this app; a commercial
      // release would need their paid license.
      await device.connect(
        license: fbp.License.nonprofit,
        timeout: _connectTimeout,
      );
      final services = await device.discoverServices();
      final nus = _requiredService(services, ruuviNusServiceUuid);
      final rx = _requiredCharacteristic(nus, ruuviNusRxCharacteristicUuid);
      final tx = _requiredCharacteristic(nus, ruuviNusTxCharacteristicUuid);
      await tx.setNotifyValue(true);

      final samples = await _readLog(rx: rx, tx: tx, mac: mac, onProgress: onProgress);
      onProgress?.call(
        RuuviDownloadProgress(RuuviDownloadPhase.storing, samples.length),
      );
      final stored = await _history.upsertSamples(mac, samples);

      final firmware = await _readFirmwareVersion(services);
      if (firmware != null) {
        for (final m in await _beacons.findByMac(mac)) {
          await _beacons.updateHealth(m.beacon.uuid, firmwareVersion: firmware);
        }
      }
      // The sample time range diagnoses tags whose clock was never synced
      // (their log timestamps then land far in the past and vanish behind
      // the history screen's recent-range filters).
      final times = [for (final s in samples) s.measuredAt]..sort();
      _log.info(
        'Ruuvi history download for $mac: ${samples.length} samples '
        '${times.isEmpty ? '' : '(${times.first} … ${times.last}) '}'
        '→ $stored timestamps stored, firmware ${firmware ?? 'unknown'}',
      );
      return RuuviDownloadResult(
        timestampsStored: stored,
        firmwareVersion: firmware,
      );
    } finally {
      try {
        await device.disconnect();
      } catch (_) {
        // link may already be gone — nothing to release
      }
    }
  }

  /// Resolves the payload MAC to a connectable peripheral via the shared
  /// scan — required on iOS, where the OS-level device id is opaque.
  Future<fbp.BluetoothDevice> _findDevice(String mac) async {
    final completer = Completer<fbp.BluetoothDevice>();
    final sub = RuuviScanService.instance.sightings.listen((s) {
      if (s.advertisement.macAddress == mac && !completer.isCompleted) {
        completer.complete(s.device);
      }
    });
    try {
      return await completer.future.timeout(
        _findTimeout,
        onTimeout: () =>
            throw IoException('Ruuvi tag $mac not seen in a scan'),
      );
    } finally {
      await sub.cancel();
    }
  }

  Future<List<RuuviLogSample>> _readLog({
    required fbp.BluetoothCharacteristic rx,
    required fbp.BluetoothCharacteristic tx,
    required String mac,
    void Function(RuuviDownloadProgress progress)? onProgress,
  }) async {
    final latest = await _history.latestTimestamp(mac);
    var lowerBound = latest != null
        ? latest.subtract(_sinceOverlap)
        : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    final done = Completer<void>();
    final samples = <RuuviLogSample>[];
    var latestReceived = lowerBound;
    var resumes = 0;
    Timer? inactivity;

    void resetInactivity() {
      inactivity?.cancel();
      inactivity = Timer(_inactivityTimeout, () {
        if (!done.isCompleted) {
          done.completeError(
            IoException('Ruuvi log transfer stalled for $mac'),
          );
        }
      });
    }

    Future<void> sendRequest() async {
      resetInactivity();
      await rx.write(
        encodeLogReadRequest(now: DateTime.now(), since: lowerBound),
      );
    }

    final sub = tx.onValueReceived.listen((data) {
      for (final msg in RuuviLogMessage.parseAll(data)) {
        resetInactivity();
        if (msg.isEndOfData) {
          if (!done.isCompleted) done.complete();
          return;
        }
        if (msg.isError) {
          // Tag-side abort (e.g. its 5-min transfer watchdog): resume from
          // the newest sample we did get, a bounded number of times.
          if (resumes < _maxErrorResumes && samples.isNotEmpty) {
            resumes++;
            lowerBound = latestReceived;
            _log.info('Ruuvi log error from $mac — resuming ($resumes)');
            unawaited(sendRequest());
          } else if (!done.isCompleted) {
            done.completeError(
              IoException('Ruuvi tag $mac reported a log-read error'),
            );
          }
          return;
        }
        final sample = msg.sample;
        if (sample == null) continue;
        samples.add(sample);
        if (sample.measuredAt.isAfter(latestReceived)) {
          latestReceived = sample.measuredAt;
        }
        if (samples.length % 100 == 0) {
          onProgress?.call(
            RuuviDownloadProgress(
              RuuviDownloadPhase.downloading,
              samples.length,
            ),
          );
        }
      }
    });
    try {
      await sendRequest();
      await done.future;
      return samples;
    } finally {
      inactivity?.cancel();
      await sub.cancel();
    }
  }

  Future<String?> _readFirmwareVersion(List<fbp.BluetoothService> services) async {
    try {
      for (final s in services) {
        if (s.uuid != fbp.Guid(_disServiceUuid)) continue;
        for (final c in s.characteristics) {
          if (c.uuid != fbp.Guid(_disFirmwareRevisionUuid)) continue;
          final raw = await c.read();
          final text = utf8.decode(raw, allowMalformed: true).trim();
          return text.isEmpty ? null : text;
        }
      }
    } catch (e, st) {
      // Firmware info is nice-to-have — never fail the download over it.
      _log.warning('DIS firmware read failed', e, st);
    }
    return null;
  }

  fbp.BluetoothService _requiredService(
    List<fbp.BluetoothService> services,
    String uuid,
  ) => services.firstWhere(
    (s) => s.uuid == fbp.Guid(uuid),
    orElse: () => throw IoException('Service $uuid missing on tag'),
  );

  fbp.BluetoothCharacteristic _requiredCharacteristic(
    fbp.BluetoothService service,
    String uuid,
  ) => service.characteristics.firstWhere(
    (c) => c.uuid == fbp.Guid(uuid),
    orElse: () => throw IoException('Characteristic $uuid missing on tag'),
  );
}
