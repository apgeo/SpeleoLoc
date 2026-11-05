import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

/// The flutter_blue_plus calls [SharedBleScan] makes.
abstract interface class BleScanPlatform {
  Stream<fbp.BluetoothAdapterState> get adapterState;

  /// Every device seen since the scan started, re-sent whole on each
  /// advertisement, and replayed on listen even after the scan stopped.
  Stream<List<fbp.ScanResult>> get scanResults;

  /// Starts (or restarts, replacing any running scan) the one process-wide
  /// scan. An empty [manufacturerIds] scans unfiltered.
  Future<void> startScan({required List<int> manufacturerIds});

  Future<void> stopScan();
}

class FlutterBluePlusScanPlatform implements BleScanPlatform {
  const FlutterBluePlusScanPlatform();

  @override
  Stream<fbp.BluetoothAdapterState> get adapterState =>
      fbp.FlutterBluePlus.adapterState;

  @override
  Stream<List<fbp.ScanResult>> get scanResults =>
      fbp.FlutterBluePlus.scanResults;

  @override
  Future<void> startScan({required List<int> manufacturerIds}) =>
      fbp.FlutterBluePlus.startScan(
        withMsd: [for (final id in manufacturerIds) fbp.MsdFilter(id)],
        // Without it the platform reports each device once per scan, and
        // RSSI-based detection needs every advertisement.
        continuousUpdates: true,
        androidUsesFineLocation: true,
      );

  @override
  Future<void> stopScan() => fbp.FlutterBluePlus.stopScan();
}
