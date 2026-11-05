import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/cave_trip/trip_log_stale_banner.dart';
import 'package:speleoloc/screens/cave_trip_page.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/services/trip_log_update.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/product_tour.dart';

import '../support/device_profiles.dart';
import '../support/layout_harness.dart';

/// What the log page saves must be what the trip page shows and exports
/// once the caver comes back to it.
void main() {
  useLayoutHarness();

  late AppDatabase db;
  late ProviderContainer container;
  late CaveTripService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    initRootContainer(container);
    service = container.read(caveTripServiceProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('accepting the log on the log page clears the trip page\'s '
      'out-of-date banner', (tester) async {
    final uuid = (await tester.runAsync(() async {
      await setAutoToursDisabled(true);
      final cave = await container.read(caveRepositoryProvider).addCave('C');
      await container.read(cavePlaceRepositoryProvider).addCavePlace(cave, 'P');
      final place = (await container
          .read(cavePlaceRepositoryProvider)
          .findCavePlaceByTitle(cave, 'P'))!;
      final uuid = await service.startTrip(cave, 'Trip');
      await service.stopTrip();
      await service.addPointAt(
        tripUuid: uuid,
        cavePlaceUuid: place.uuid,
        at: DateTime(2026, 10, 13, 10),
        logUpdate: TripLogUpdate.markStale,
      );
      return uuid;
    }))!;

    LayoutHarness.applyProfile(tester, deviceProfiles[1]);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CaveTripPage(tripUuid: uuid),
          // Stands in for the log page; the test accepts the log while it
          // is open, as the page's "keep" would.
          onGenerateRoute: (settings) => settings.name == caveTripLogRoute
              ? MaterialPageRoute<void>(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('back'),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
    await settle(tester);
    expect(find.byType(TripLogStaleBanner), findsOneWidget);

    await tester.tap(find.text(LocServ.inst.t('trip_log')));
    await settle(tester);
    await tester.runAsync(() => service.keepLogAsWritten(uuid));
    await tester.tap(find.text('back'));
    await settle(tester);
    await settle(tester);

    expect(find.byType(TripLogStaleBanner), findsNothing);
  });
}
