import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/cave_trip/trip_media_tile.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/utils/navigator_key.dart';

import 'support/driver.dart';

/// Drives the points-from-pictures screen against the invented fixture, on
/// a device whose media library was seeded by
/// `tool/android/seed_test_media.sh`.
///
/// This is the test for the two things no host-side test can reach: the
/// device's own media library, read through the platform, and a QR label
/// decoded out of a stored photograph. It asserts on invented names and so
/// only runs when the device is known to hold the fixture — see
/// `suite_test.dart`.
void main() {
  final binding = AppDriver.ensureInitialized();

  testWidgets('pictures on the trip day become track points', (tester) async {
    final driver = AppDriver(binding, tester);
    await driver.launch();

    expect(
      find.text('Test Cave Alpha'),
      findsOneWidget,
      reason: 'the device does not hold the invented fixture',
    );

    final db = rootContainer.read(appDatabaseProvider);
    final trip = await (db.select(
      db.caveTrips,
    )..where((t) => t.title.equals('Fixture trip 1 (ended)'))).getSingle();
    final pointsBefore = (await db.getTripPoints(trip.uuid)).length;

    // Straight to the screen under test. How a caver reaches it through the
    // menus is the trip screen's concern and would only make this brittle.
    unawaited(
      navigatorKey.currentState!.pushNamed<bool>(
        caveTripMediaPointsRoute,
        arguments: trip.uuid,
      ),
    );

    await driver.pumpUntil(
      () => find.byType(TripMediaTile).evaluate().isNotEmpty,
      reason: 'the media library to list the seeded pictures',
    );
    await driver.shoot('10_media_listed');

    // The screen opens on the trip's own day, so the fixture dated two days
    // earlier must not be offered — even though it arrived on the device at
    // the same moment as the rest, which is all the platform's own date
    // filter looks at.
    expect(find.textContaining('2026/10/13'), findsWidgets);
    expect(find.textContaining('2026/10/11'), findsNothing);

    // Listed in the order they were taken, not the order they arrived.
    final earliest = tester.getTopLeft(find.textContaining('10:03:00')).dy;
    final latest = tester.getTopLeft(find.textContaining('11:28:00')).dy;
    expect(earliest, lessThan(latest));

    // Two of the seeded pictures carry a QR label for a fixture place.
    final fromQr = find.text(LocServ.inst.t('trip_media_from_qr'));
    await driver.pumpUntil(
      () => fromQr.evaluate().length >= 2,
      reason: 'both QR-labelled pictures to resolve to their cave place',
      timeout: const Duration(minutes: 3),
    );
    await driver.shoot('11_qr_resolved');

    await tester.tap(find.byType(FloatingActionButton));
    await driver.settle();

    // One of the two labels is the cave's entrance, so the entrance
    // reconciliation has to ask before anything is written. Leaving it
    // untouched is the "just add the points" answer.
    final ok = find.text(LocServ.inst.t('ok'));
    await driver.pumpUntil(
      () => ok.evaluate().isNotEmpty,
      reason: 'the entrance dialog',
    );
    await driver.shoot('12_entrance_dialog');
    await tester.tap(ok.first);

    await driver.pumpUntil(
      () => find.byType(TripMediaTile).evaluate().isEmpty,
      reason: 'the import to finish and the screen to close',
      timeout: const Duration(minutes: 2),
    );
    await driver.settle();

    final pointsAfter = await db.getTripPoints(trip.uuid);
    expect(pointsAfter.length, pointsBefore + 2);

    // The store-pictures switch is on by default: both files are kept, and
    // each is bound to the track point it produced.
    final links = await db.select(db.documentationFilesToCaveTripPoints).get();
    expect(links, hasLength(2));
    expect(
      links.map((l) => l.caveTripPointUuid).toSet(),
      hasLength(2),
      reason: 'one picture per point, not both on the same one',
    );
    expect(tester.takeException(), isNull);
  });
}
