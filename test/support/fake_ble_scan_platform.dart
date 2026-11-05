import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:speleoloc/services/beacon/ble_scan_platform.dart';

/// Behaves like flutter_blue_plus where it matters: the current adapter
/// state and the latest result list are replayed to every new listener,
/// and each list holds every device seen since the scan started.
class FakeBleScanPlatform implements BleScanPlatform {
  FakeBleScanPlatform({this.adapter = fbp.BluetoothAdapterState.on});

  fbp.BluetoothAdapterState adapter;
  final _adapterChanges =
      StreamController<fbp.BluetoothAdapterState>.broadcast();
  final _results = StreamController<List<fbp.ScanResult>>.broadcast();
  List<fbp.ScanResult> _latest = const [];

  /// The filter of every startScan call, in order.
  final List<List<int>> startedFilters = [];
  int stopCount = 0;
  bool get isScanning => _scanning;
  bool _scanning = false;

  List<int>? get currentFilter => _scanning ? startedFilters.last : null;

  @override
  Stream<fbp.BluetoothAdapterState> get adapterState async* {
    yield adapter;
    yield* _adapterChanges.stream;
  }

  @override
  Stream<List<fbp.ScanResult>> get scanResults async* {
    yield _latest;
    yield* _results.stream;
  }

  @override
  Future<void> startScan({required List<int> manufacturerIds}) async {
    startedFilters.add(List.of(manufacturerIds));
    _scanning = true;
    emit(const []);
  }

  @override
  Future<void> stopScan() async {
    stopCount++;
    _scanning = false;
  }

  void setAdapter(fbp.BluetoothAdapterState state) {
    adapter = state;
    if (state != fbp.BluetoothAdapterState.on) _scanning = false;
    _adapterChanges.add(state);
  }

  void emit(List<fbp.ScanResult> results) {
    _latest = List.of(results);
    _results.add(_latest);
  }
}

/// A scan result stamped [at], as the plugin stamps each advertisement on
/// arrival.
fbp.ScanResult scanResult(
  String remoteId, {
  required DateTime at,
  int rssi = -60,
  Map<int, List<int>> manufacturerData = const {},
}) => fbp.ScanResult(
  device: fbp.BluetoothDevice.fromId(remoteId),
  advertisementData: fbp.AdvertisementData(
    advName: '',
    txPowerLevel: null,
    appearance: null,
    connectable: false,
    manufacturerData: manufacturerData,
    serviceData: const {},
    serviceUuids: const [],
  ),
  rssi: rssi,
  timeStamp: at,
);
