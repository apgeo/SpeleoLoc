import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/beacon/beacon_detection_service.dart';
import 'package:speleoloc/services/beacon/beacon_repository.dart';
import 'package:speleoloc/services/service_locator.dart';

import '../support/cell.dart';
import '../support/flow.dart';
import '../support/recorder.dart';

/// The app's own beacon detection, end to end on a real Android Bluetooth
/// stack. Beside this cell the matrix runs tool/android/netsim_beacons.dart,
/// which advertises the fixture's iBeacon and Ruuvi tag into the emulated
/// radio. Detection is switched on the way Settings switches it on; each
/// registration must then be stamped as seen, which happens only after a
/// sighting has come through the plugins, the match engine and the
/// repository.
void main() {
  flow('beacon_detect', needs: {Need.bluetooth, Need.location}, (driver) async {
    await driver.launch();
    // As in ble_scan: an image whose radio netsim does not reach has
    // nothing to detect with, and that is not the app's failure.
    if (!await FlutterBluePlus.isSupported) {
      Recorder.instance.note('beacon_detect', 'no Bluetooth on this image');
      return;
    }
    final service = BeaconDetectionService.instance;
    expect(
      await service.setEnabled(true),
      isTrue,
      reason: 'detection should switch on with the permissions granted',
    );
    expect(service.isRunning, isTrue, reason: 'detection should be scanning');

    final db = rootContainer.read(appDatabaseProvider);
    final registrations = await db.select(db.cavePlaceBeacons).get();
    final families = {for (final b in registrations) b.beaconType};
    expect(
      families,
      containsAll([BeaconTypes.iBeacon, BeaconTypes.ruuvi]),
      reason: 'the fixture registers one beacon of each family',
    );

    final unseen = {...families};
    final deadline = DateTime.now().add(const Duration(seconds: 90));
    while (unseen.isNotEmpty && DateTime.now().isBefore(deadline)) {
      await driver.tester.pump(const Duration(seconds: 1));
      for (final b in await db.select(db.cavePlaceBeacons).get()) {
        if (b.lastSeenAt != null) unseen.remove(b.beaconType);
      }
    }
    await driver.shoot('50_beacon_detected');
    await service.setEnabled(false);

    Recorder.instance.note(
      'beacon_detect',
      unseen.isEmpty
          ? 'every fixture beacon detected'
          : 'not detected: ${unseen.join(', ')}',
    );
    expect(
      unseen,
      isEmpty,
      reason:
          'each registered beacon should be seen within 90 s; is '
          'tool/android/netsim_beacons.dart running?',
    );
  });
}
