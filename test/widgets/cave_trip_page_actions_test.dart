import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/cave_trip_page.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/product_tour.dart';

import '../support/device_profiles.dart';
import '../support/layout_harness.dart';

/// The trip page's actions reach the trip on screen, never the one this
/// device happens to be recording, and restarting an ended trip asks first.
void main() {
  useLayoutHarness();

  late AppDatabase db;
  late ProviderContainer container;
  late CaveTripService service;
  late Uuid caveUuid;

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

  Future<T> run<T>(WidgetTester tester, Future<T> Function() body) async =>
      (await tester.runAsync(body)) as T;

  // The screen's product tour would otherwise cover the toolbar.
  Future<void> seedCave(WidgetTester tester) => run(tester, () async {
    await setAutoToursDisabled(true);
    caveUuid = await container.read(caveRepositoryProvider).addCave('Cave');
  });

  Future<CaveTrip> row(WidgetTester tester, Uuid uuid) => run(
    tester,
    () async =>
        (await container.read(caveTripRepositoryProvider).findById(uuid))!,
  );

  /// Another phone's recording, received still open.
  Future<Uuid> openElsewhere(WidgetTester tester) => run(
    tester,
    () async => db.insertCaveTrip(
      caveUuid: caveUuid,
      title: 'Other phone',
      startedAt: DateTime(2026, 10, 1, 9).millisecondsSinceEpoch,
      authorUuid: await container
          .read(currentUserServiceProvider)
          .currentOrSystem(),
      deviceUuid: Uuid.v7(),
    ),
  );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> open(WidgetTester tester, Uuid uuid) async {
    final error = await LayoutHarness.renderAndCatch(
      tester,
      deviceProfiles[1],
      () => UncontrolledProviderScope(
        container: container,
        child: CaveTripPage(tripUuid: uuid),
      ),
    );
    expect(error, isNull);
    await settle(tester);
  }

  testWidgets('another phone\'s open recording offers no Stop or Pause', (
    tester,
  ) async {
    await seedCave(tester);
    await run(tester, () => service.startTrip(caveUuid, 'Mine'));
    final other = await openElsewhere(tester);

    await open(tester, other);

    expect(find.text(LocServ.inst.t('trip_stop')), findsNothing);
    expect(find.text(LocServ.inst.t('trip_pause')), findsNothing);
    expect(find.text(LocServ.inst.t('trip_restart')), findsNothing);
    expect(find.text(LocServ.inst.t('trip_open_not_here')), findsOneWidget);
  });

  testWidgets('the recording trip offers Stop and Pause', (tester) async {
    await seedCave(tester);
    final mine = await run(tester, () => service.startTrip(caveUuid, 'Mine'));

    await open(tester, mine);

    expect(find.text(LocServ.inst.t('trip_stop')), findsOneWidget);
    expect(find.text(LocServ.inst.t('trip_pause')), findsOneWidget);
  });

  testWidgets('Stop asks, names the cave, and keeping leaves the trip '
      'recording', (tester) async {
    await seedCave(tester);
    final mine = await run(tester, () => service.startTrip(caveUuid, 'Mine'));
    await open(tester, mine);

    await tester.tap(find.text(LocServ.inst.t('trip_stop')));
    await settle(tester);
    expect(
      find.text(LocServ.inst.t('trip_end_dialog_title', {'cave': 'Cave'})),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('end_trip_keep')));
    await settle(tester);

    expect((await row(tester, mine)).tripEndedAt, isNull);
    expect(service.activeTripIdNotifier.value, mine);

    await tester.tap(find.text(LocServ.inst.t('trip_stop')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('end_trip_confirm')));
    await settle(tester);

    expect((await row(tester, mine)).tripEndedAt, isNotNull);
    expect(service.activeTripIdNotifier.value, isNull);
  });

  testWidgets('Restart asks before replacing the times', (tester) async {
    await seedCave(tester);
    final ended = await run(tester, () async {
      final uuid = await service.startTrip(caveUuid, 'Old');
      await service.stopTrip();
      return uuid;
    });
    final before = await row(tester, ended);
    await open(tester, ended);

    await tester.tap(find.text(LocServ.inst.t('trip_restart')));
    await settle(tester);
    expect(
      find.text(LocServ.inst.t('trip_restart_confirm_title')),
      findsOneWidget,
    );
    await tester.tap(find.text(LocServ.inst.t('cancel')));
    await settle(tester);

    final after = await row(tester, ended);
    expect(after.tripStartedAt, before.tripStartedAt);
    expect(after.tripEndedAt, before.tripEndedAt);
    expect(service.activeTripIdNotifier.value, isNull);

    await tester.tap(find.text(LocServ.inst.t('trip_restart')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('trip_restart_confirm')));
    await settle(tester);

    expect((await row(tester, ended)).tripEndedAt, isNull);
    expect(service.activeTripIdNotifier.value, ended);
  });

  testWidgets('Restart is refused while another trip records', (tester) async {
    await seedCave(tester);
    final ended = await run(tester, () async {
      final uuid = await service.startTrip(caveUuid, 'Old');
      await service.stopTrip();
      return uuid;
    });
    final running = await run(tester, () => service.startTrip(caveUuid, 'Now'));
    await open(tester, ended);

    await tester.tap(find.text(LocServ.inst.t('trip_restart')));
    await settle(tester);

    expect(
      find.text(LocServ.inst.t('trip_restart_confirm_title')),
      findsNothing,
    );
    expect(service.activeTripIdNotifier.value, running);
    expect((await row(tester, ended)).tripEndedAt, isNotNull);
  });
}
