import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/cave_trip/trip_log_stale_banner.dart';
import 'package:speleoloc/screens/cave_trip/trip_media_tile.dart';
import 'package:speleoloc/screens/cave_trip/trip_point_pictures_sheet.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/utils/navigator_key.dart';

import 'support/cell.dart';
import 'support/flow.dart';

/// Drives the points-from-pictures screen against the invented fixture, on
/// a device whose media library was seeded by
/// `tool/android/seed_test_media.sh`.
///
/// This is the test for the two things no host-side test can reach: the
/// device's own media library, read through the platform, and a QR label
/// decoded out of a stored photograph. It asserts on invented names and so
/// only runs when the device is known to hold the fixture.
void main() {
  flow(
    'trip_media',
    needs: {Need.media},
    inventedOnly: true,
    timeout: const Duration(minutes: 10),
    (driver) async {
      final tester = driver.tester;
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
      // Read off every row that is built, on screen or in the scroll cache
      // below it, so a short screen does not hide the last few.
      final times = find.textContaining(
        RegExp(r'2026/10/13 \d\d:\d\d:\d\d'),
        skipOffstage: false,
      );
      final byPosition = [
        for (final e in times.evaluate())
          (
            // From the render box itself: a finder skips a row that is laid
            // out in the scroll cache but not on screen.
            y: (e.renderObject! as RenderBox).localToGlobal(Offset.zero).dy,
            text: (e.widget as Text).data ?? '',
          ),
      ]..sort((a, b) => a.y.compareTo(b.y));
      final listed = [for (final r in byPosition) r.text];
      expect(listed.length, greaterThanOrEqualTo(2));
      expect(listed, [...listed]..sort(), reason: 'rows out of order: $listed');

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
      final links = await db
          .select(db.documentationFilesToCaveTripPoints)
          .get();
      expect(links, hasLength(2));
      expect(
        links.map((l) => l.caveTripPointUuid).toSet(),
        hasLength(2),
        reason: 'one picture per point, not both on the same one',
      );

      // Regenerating on edits is off by default, so the import kept the
      // log as written and marked it out of date instead.
      final afterImport = await (db.select(
        db.caveTrips,
      )..where((t) => t.uuid.equalsValue(trip.uuid))).getSingle();
      expect(afterImport.logStaleSince, isNotNull);
      expect(afterImport.log, trip.log, reason: 'the text was left alone');

      // On the trip screen: the warning, and each new point's picture.
      unawaited(
        navigatorKey.currentState!.pushNamed<bool>(
          caveTripRoute,
          arguments: trip.uuid,
        ),
      );
      await driver.pumpUntil(
        () => find.byType(TripLogStaleBanner).evaluate().isNotEmpty,
        reason: 'the trip screen to say its log is out of date',
      );
      // By tooltip: each says how many pictures its own point holds. Off
      // screen included — on a short phone the later points are below the
      // fold, under the warning card.
      final badges = find.byTooltip(
        LocServ.inst.t('trip_point_pictures', {'n': '1'}),
        skipOffstage: false,
      );
      await driver.pumpUntil(
        () => badges.evaluate().length >= 2,
        reason: 'both imported points to show their picture',
      );
      await driver.shoot('13_trip_after_import');

      await tester.ensureVisible(badges.first);
      await driver.settle();
      await tester.tap(badges.first);
      await driver.pumpUntil(
        () => find.byType(TripPointPicturesSheet).evaluate().isNotEmpty,
        reason: 'the point\'s pictures to open',
      );
      await driver.shoot('14_point_pictures');
      await tester.tapAt(const Offset(20, 40)); // outside the sheet
      await driver.settle();

      final keep = find.text(
        LocServ.inst.t('trip_log_keep_as_written'),
        skipOffstage: false,
      );
      await tester.ensureVisible(keep);
      await driver.settle();
      await tester.tap(keep);
      await driver.pumpUntil(
        () => find.byType(TripLogStaleBanner).evaluate().isEmpty,
        reason: 'keeping the log to clear the warning',
      );
      final kept = await (db.select(
        db.caveTrips,
      )..where((t) => t.uuid.equalsValue(trip.uuid))).getSingle();
      expect(kept.logStaleSince, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
