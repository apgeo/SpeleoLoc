import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/cell.dart';
import '../support/flow.dart';
import '../support/recorder.dart';

/// The Bluetooth path the beacon features stand on, on a real Android
/// stack: the scan permissions as this Android version defines them, the
/// adapter coming up, and the plugin the app uses receiving
/// advertisements.
///
/// The matrix starts emulators with netsim's test beacons, two BLE
/// advertisers the emulated radio can hear. Images too old for netsim's
/// Bluetooth have no adapter at all; there the flow records that and
/// passes, because there is nothing to scan with.
void main() {
  flow('ble_scan', needs: {Need.bluetooth}, (driver) async {
    await driver.launch();
    if (!await FlutterBluePlus.isSupported) {
      Recorder.instance.note('ble_scan', 'no Bluetooth on this image');
      return;
    }
    final state = await FlutterBluePlus.adapterState
        .where((s) => s != BluetoothAdapterState.unknown)
        .first
        .timeout(const Duration(seconds: 20));
    if (state != BluetoothAdapterState.on) {
      Recorder.instance.note('ble_scan', 'adapter $state');
      return;
    }
    final seen = <String>{};
    final sub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        seen.add(r.device.remoteId.str);
      }
    });
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
    ).timeout(const Duration(seconds: 25));
    await driver.pumpUntil(
      () => !FlutterBluePlus.isScanningNow,
      reason: 'the scan to end',
      timeout: const Duration(seconds: 30),
    );
    await sub.cancel();
    Recorder.instance.note('ble_scan', '${seen.length} advertiser(s) heard');
    expect(
      seen,
      isNotEmpty,
      reason: 'the emulated radio should hear netsim\'s test beacons',
    );
  });
}
