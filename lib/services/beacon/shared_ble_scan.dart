import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:speleoloc/services/beacon/ble_scan_platform.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// The one owner of flutter_blue_plus's process-wide BLE scan.
///
/// The plugin has a single scan: starting one replaces whatever another
/// screen was running, and stopping it silences everyone. So every consumer
/// (Ruuvi detection, the picker, the live view, Beacon Lab's raw scan)
/// listens to [advertisements] here instead, and the platform scan runs
/// while at least one listener is attached, filtered to what they all want.
///
/// Callers run the permission and location gate (`BeaconScanHelper`) before
/// listening; this never prompts.
class SharedBleScan {
  SharedBleScan({
    BleScanPlatform platform = const FlutterBluePlusScanPlatform(),
    DateTime Function() clock = DateTime.now,
  }) : _platform = platform,
       _clock = clock;

  static final SharedBleScan instance = SharedBleScan();

  final BleScanPlatform _platform;
  final DateTime Function() _clock;
  final _log = AppLogger.of('SharedBleScan');

  final List<_ScanClient> _clients = [];
  StreamSubscription<fbp.BluetoothAdapterState>? _adapterSub;
  StreamSubscription<List<fbp.ScanResult>>? _resultsSub;
  bool _adapterOn = false;

  /// The filter of the platform scan now running; null while none runs.
  List<int>? _runningFilter;
  DateTime? _scanStartedAt;

  /// Timestamp of the newest advertisement passed on, per device: the
  /// plugin re-sends every device it has seen with each new advertisement.
  final Map<fbp.DeviceIdentifier, DateTime> _lastPassedOn = {};
  Future<void> _pending = Future.value();

  /// Freshly received advertisements, one event per packet.
  ///
  /// With [manufacturerIds], only packets carrying manufacturer data for one
  /// of them, and the platform scan is filtered to them: Android suspends an
  /// unfiltered scan while the screen is off. Without, every packet, and the
  /// scan runs unfiltered while that listener stays attached.
  Stream<fbp.ScanResult> advertisements({Set<int> manufacturerIds = const {}}) {
    late final _ScanClient client;
    final controller = StreamController<fbp.ScanResult>(
      onListen: () {
        _clients.add(client);
        unawaited(_reconcile());
      },
      onCancel: () {
        _clients.remove(client);
        return _reconcile();
      },
    );
    client = _ScanClient(manufacturerIds, controller);
    return controller.stream;
  }

  Future<void> _reconcile() {
    return _pending = _pending.then((_) => _apply()).catchError((
      Object e,
      StackTrace st,
    ) {
      _log.warning('BLE scan update failed', e, st);
    });
  }

  Future<void> _apply() async {
    if (_clients.isEmpty) {
      await _shutDown();
      return;
    }
    _resultsSub ??= _platform.scanResults.listen(
      _onResults,
      onError: _onScanError,
    );
    // At a cold start the adapter briefly reports `unknown` before the real
    // state, so follow it: scan while it is on, resume when it comes back.
    _adapterSub ??= _platform.adapterState.listen(
      _onAdapterState,
      onError: (Object e, StackTrace st) {
        _log.warning('Bluetooth adapter state watch error', e, st);
      },
    );
    if (!_adapterOn) return;
    final wanted = _wantedFilter();
    if (listEquals(_runningFilter, wanted)) return;
    _scanStartedAt = _clock();
    _runningFilter = wanted;
    try {
      await _platform.startScan(manufacturerIds: wanted);
    } catch (e, st) {
      _runningFilter = null;
      _log.warning('BLE scan start failed', e, st);
      for (final c in List.of(_clients)) {
        c.controller.addError(e, st);
      }
    }
  }

  /// Unfiltered as soon as one listener wants everything.
  List<int> _wantedFilter() {
    if (_clients.any((c) => c.manufacturerIds.isEmpty)) return const [];
    return {for (final c in _clients) ...c.manufacturerIds}.toList()..sort();
  }

  void _onAdapterState(fbp.BluetoothAdapterState state) {
    _adapterOn = state == fbp.BluetoothAdapterState.on;
    if (!_adapterOn) {
      // The platform scan dies with the adapter; start afresh when it is on.
      _runningFilter = null;
      if (state == fbp.BluetoothAdapterState.off) {
        _log.warning('BLE scan interrupted: Bluetooth is off');
      }
    }
    unawaited(_reconcile());
  }

  void _onResults(List<fbp.ScanResult> results) {
    final startedAt = _scanStartedAt;
    if (_runningFilter == null || startedAt == null) return;
    for (final r in results) {
      // A list replayed from an earlier scan, or a device that has not
      // advertised again since it was last passed on: not a sighting now.
      if (r.timeStamp.isBefore(startedAt)) continue;
      final id = r.device.remoteId;
      final last = _lastPassedOn[id];
      if (last != null && !r.timeStamp.isAfter(last)) continue;
      _lastPassedOn[id] = r.timeStamp;
      for (final c in List.of(_clients)) {
        if (c.wants(r)) c.controller.add(r);
      }
    }
  }

  void _onScanError(Object e, StackTrace st) {
    // The plugin ends the scan when it reports a failure.
    _runningFilter = null;
    _log.warning('BLE scan stream error', e, st);
    for (final c in List.of(_clients)) {
      c.controller.addError(e, st);
    }
  }

  Future<void> _shutDown() async {
    await _adapterSub?.cancel();
    _adapterSub = null;
    await _resultsSub?.cancel();
    _resultsSub = null;
    _adapterOn = false;
    _lastPassedOn.clear();
    if (_runningFilter == null) return;
    _runningFilter = null;
    try {
      await _platform.stopScan();
    } catch (e, st) {
      // The adapter may already be off, with nothing left to stop.
      _log.fine('BLE scan stop failed', e, st);
    }
  }
}

class _ScanClient {
  _ScanClient(this.manufacturerIds, this.controller);

  final Set<int> manufacturerIds;
  final StreamController<fbp.ScanResult> controller;

  bool wants(fbp.ScanResult r) =>
      manufacturerIds.isEmpty ||
      r.advertisementData.manufacturerData.keys.any(manufacturerIds.contains);
}
