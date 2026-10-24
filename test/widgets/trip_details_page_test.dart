import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/cave_trip/trip_details_page.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/localization.dart';

import '../support/device_profiles.dart';
import '../support/layout_harness.dart';

void main() {
  useLayoutHarness();

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    initRootContainer(container);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<Uuid> trip(WidgetTester tester) async => (await tester.runAsync(
    () async {
      final cave = await container.read(caveRepositoryProvider).addCave('Cave');
      final service = container.read(caveTripServiceProvider);
      final uuid = await service.startTrip(cave, 'Trip');
      await service.stopTrip();
      return uuid;
    },
  ))!;

  Future<CaveTrip> stored(WidgetTester tester, Uuid uuid) async =>
      (await tester.runAsync(
        () => container.read(caveTripRepositoryProvider).findById(uuid),
      ))!;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> open(WidgetTester tester, Uuid uuid, [int profile = 1]) async {
    await LayoutHarness.renderAndCatch(
      tester,
      deviceProfiles[profile],
      () => UncontrolledProviderScope(
        container: container,
        child: TripDetailsPage(tripUuid: uuid),
      ),
    );
    await settle(tester);
  }

  testWidgets('lays out on every device profile', (tester) async {
    final uuid = await trip(tester);
    await tester.runAsync(
      () => container
          .read(caveTripRepositoryProvider)
          .updateTripDetails(
            uuid,
            participants:
                'Ana Popescu, Bogdan Ionescu, Cristina Dumitrescu, '
                'Dan Marinescu, Elena Georgescu',
            details: 'Long details\n' * 12,
          ),
    );
    final failures = <String>[];
    for (var i = 0; i < deviceProfiles.length; i++) {
      await open(tester, uuid, i);
      final error = tester.takeException();
      if (error != null) failures.add('${deviceProfiles[i].name}: $error');
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  testWidgets('a participant added through the popup is saved with the '
      'details', (tester) async {
    final uuid = await trip(tester);
    await open(tester, uuid);

    await tester.enterText(
      find.widgetWithText(TextField, LocServ.inst.t('trip_participants')),
      'Ana, Bogdan',
    );
    await tester.tap(find.byTooltip(LocServ.inst.t('trip_participant_add')));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, LocServ.inst.t('trip_participant_name')),
      'Cristi',
    );
    await tester.tap(find.text(LocServ.inst.t('trip_participant_add_button')));
    await settle(tester);
    expect(find.widgetWithText(InputChip, 'Cristi'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, LocServ.inst.t('trip_details')),
      'Rope on the second pitch.\nWater high.',
    );
    await tester.tap(find.byTooltip(LocServ.inst.t('save')));
    await settle(tester);

    final t = await stored(tester, uuid);
    expect(t.participants, 'Ana, Bogdan, Cristi');
    expect(t.description, 'Rope on the second pitch.\nWater high.');
    final logged = await tester.runAsync(() => db.select(db.changeLog).get());
    expect(
      logged!.where(
        (r) =>
            r.entityTable == 'cave_trips' && r.changeType == ChangeType.update,
      ),
      isNotEmpty,
      reason: 'the change must reach the sync upload gate',
    );
  });

  testWidgets('removing a chip takes the name out of the field', (
    tester,
  ) async {
    final uuid = await trip(tester);
    await open(tester, uuid);
    await tester.enterText(
      find.widgetWithText(TextField, LocServ.inst.t('trip_participants')),
      'Ana, Bogdan, Cristi',
    );
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(InputChip, 'Bogdan'),
        matching: find.byTooltip(LocServ.inst.t('trip_participant_remove')),
      ),
    );
    await tester.pump();
    expect(find.text('Ana, Cristi'), findsOneWidget);
  });

  testWidgets('blank fields are stored as none', (tester) async {
    final uuid = await trip(tester);
    await open(tester, uuid);
    await tester.enterText(
      find.widgetWithText(TextField, LocServ.inst.t('trip_participants')),
      ' , ',
    );
    await tester.tap(find.byTooltip(LocServ.inst.t('save')));
    await settle(tester);
    final t = await stored(tester, uuid);
    expect(t.participants, isNull);
    expect(t.description, isNull);
  });
}
