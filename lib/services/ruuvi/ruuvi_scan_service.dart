import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:speleoloc/services/ruuvi/ruuvi_advertisement_parser.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// One decoded Ruuvi advertisement observation.
class RuuviSighting {
  final RuuviAdvertisement advertisement;

  /// `RUUVI/<MAC>` — never null (payloads without a MAC are dropped).
  final String identity;

  /// Handle for a later GATT connection (history download); on iOS this is
  /// the only way to reach the peripheral, since the OS hides real MACs.
  final fbp.BluetoothDevice device;

  final int rssi;
  final DateTime seenAt;

  const RuuviSighting({
    required this.advertisement,
    required this.identity,
    required this.device,
    required this.rssi,
    required this.seenAt,
  });
}

/// Shared Ruuvi advertisement source over the (global) flutter_blue_plus
/// scanner. Consumers — picker, live view, detection — listen to
/// [sightings]; the BLE scan runs while at least one listener is attached
/// (the broadcast controller's onListen/onCancel ref-count it), so the
/// radio is only busy when something actually wants Ruuvi frames.
///
/// A singleton because the underlying scanner is process-global static
/// state; wrapping it in per-consumer instances would only fake isolation.
/// Callers must run the permission/location gate (`BeaconScanHelper`)
/// before listening — this service never prompts.
class RuuviScanService {
  RuuviScanService._();
  static final RuuviScanService instance = RuuviScanService._();

  final _log = AppLogger.of('RuuviScanService');
  StreamSubscription<List<fbp.ScanResult>>? _resultsSub;
  late final StreamController<RuuviSighting> _controller =
      StreamController.broadcast(
        onListen: () => unawaited(_start()),
        onCancel: () => unawaited(_stop()),
      );

  /// Decoded sightings of every Ruuvi tag in radio range, one event per
  /// received advertisement.
  Stream<RuuviSighting> get sightings => _controller.stream;

  Future<void> _start() async {
    try {
      if (await fbp.FlutterBluePlus.adapterState.first !=
          fbp.BluetoothAdapterState.on) {
        _log.warning('Ruuvi scan not started: Bluetooth is off');
        return;
      }
      _resultsSub = fbp.FlutterBluePlus.scanResults.listen(
        _onResults,
        onError: (Object e, StackTrace st) {
          _log.warning('Ruuvi scan stream error', e, st);
        },
      );
      await fbp.FlutterBluePlus.startScan(
        continuousUpdates: true,
        androidUsesFineLocation: true,
      );
    } catch (e, st) {
      _log.warning('Ruuvi scan start failed', e, st);
    }
  }

  void _onResults(List<fbp.ScanResult> results) {
    final now = DateTime.now();
    for (final r in results) {
      final adv = RuuviAdvertisement.fromManufacturerData(
        r.advertisementData.manufacturerData,
      );
      final identity = adv?.identity;
      if (adv == null || identity == null) continue;
      _controller.add(
        RuuviSighting(
          advertisement: adv,
          identity: identity,
          device: r.device,
          rssi: r.rssi,
          seenAt: now,
        ),
      );
    }
  }

  Future<void> _stop() async {
    await _resultsSub?.cancel();
    _resultsSub = null;
    try {
      await fbp.FlutterBluePlus.stopScan();
    } catch (_) {
      // adapter may already be off — nothing to stop
    }
  }
}
