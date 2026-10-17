import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/cave_trip/trip_log_stale_banner.dart';
import 'package:speleoloc/screens/cave_trip/trip_log_update_prompt.dart';
import 'package:speleoloc/screens/cave_trip_log_page.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/services/trip_log_update.dart';
import 'package:speleoloc/utils/localization.dart';

import '../support/device_profiles.dart';
import '../support/layout_harness.dart';

/// What the trip screens tell the user about the trip log once editing
/// points stopped rewriting it by default: a warning and a choice when the
/// log has fallen behind, a question before regenerating would replace
/// text, and — on the log page — which of the two the setting does.
void main() {
  useLayoutHarness();

  late AppDatabase db;
  late ProviderContainer container;
  late CaveTripService service;
  late Uuid caveUuid;
  late Uuid chamber;

  setUp(() async {
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

  // Data is set up inside each test through tester.runAsync: the database
  // runs real futures, which the test body's fake-async zone never
  // completes on its own.
  Future<void> seedCave(WidgetTester tester) => tester.runAsync(() async {
    caveUuid = await container.read(caveRepositoryProvider).addCave('Cave');
    final places = container.read(cavePlaceRepositoryProvider);
    await places.addCavePlace(caveUuid, 'Chamber');
    chamber = (await places.findCavePlaceByTitle(caveUuid, 'Chamber'))!.uuid;
  });

  Future<CaveTrip> trip(WidgetTester tester, Uuid uuid) async =>
      (await tester.runAsync(
        () => container.read(caveTripRepositoryProvider).findById(uuid),
      ))!;

  /// An ended trip with a hand-written line, whose points then changed.
  Future<Uuid> staleTrip(WidgetTester tester, {bool stale = true}) async {
    await seedCave(tester);
    return (await tester.runAsync(() async {
      final uuid = await service.startTrip(caveUuid, 'Trip');
      await service.stopTrip();
      final t = await container.read(caveTripRepositoryProvider).findById(uuid);
      await container
          .read(caveTripRepositoryProvider)
          .updateTripLog(uuid, '${t!.log}\nMet the other team here.');
      if (stale) {
        await service.addPointAt(
          tripUuid: uuid,
          cavePlaceUuid: chamber,
          at: DateTime(2026, 10, 13, 10),
          logUpdate: TripLogUpdate.markStale,
        );
      }
      return uuid;
    }))!;
  }

  Widget scoped(Widget child) =>
      UncontrolledProviderScope(container: container, child: child);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('the out-of-date banner', () {
    testWidgets('lays out on every device profile', (tester) async {
      final uuid = await staleTrip(tester);
      final t = await trip(tester, uuid);
      final failures = <String>[];
      for (final profile in deviceProfiles) {
        final error = await LayoutHarness.renderAndCatch(
          tester,
          profile,
          () => scoped(
            Scaffold(
              body: TripLogStaleBanner(
                trip: t,
                onRegenerated: () {},
                onKept: () {},
              ),
            ),
          ),
        );
        if (error != null) failures.add('${profile.name}: $error');
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    testWidgets('keeping it clears the mark and leaves the text', (
      tester,
    ) async {
      final uuid = await staleTrip(tester);
      final before = await trip(tester, uuid);
      var kept = false;
      await LayoutHarness.renderAndCatch(
        tester,
        deviceProfiles[1],
        () => scoped(
          Scaffold(
            body: TripLogStaleBanner(
              trip: before,
              onRegenerated: () {},
              onKept: () => kept = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text(LocServ.inst.t('trip_log_keep_as_written')));
      await settle(tester);

      final after = await trip(tester, uuid);
      expect(kept, isTrue);
      expect(after.logStaleSince, isNull);
      expect(after.log, before.log);
    });

    testWidgets('regenerating asks first, then rewrites the log', (
      tester,
    ) async {
      final uuid = await staleTrip(tester);
      var regenerated = false;
      await LayoutHarness.renderAndCatch(
        tester,
        deviceProfiles[1],
        () => scoped(
          Scaffold(
            body: Builder(
              builder: (_) => FutureBuilder<CaveTrip?>(
                future: container
                    .read(caveTripRepositoryProvider)
                    .findById(uuid),
                builder: (_, snap) => snap.data == null
                    ? const SizedBox()
                    : TripLogStaleBanner(
                        trip: snap.data!,
                        onRegenerated: () => regenerated = true,
                        onKept: () {},
                      ),
              ),
            ),
          ),
        ),
      );
      await settle(tester);

      await tester.tap(find.text(LocServ.inst.t('trip_log_regenerate')));
      await settle(tester);
      expect(
        find.text(LocServ.inst.t('trip_log_regenerate_confirm_body')),
        findsOneWidget,
        reason: 'it warns that hand-typed text is replaced',
      );
      await tester.tap(find.text(LocServ.inst.t('trip_log_regenerate')).last);
      await settle(tester);

      final after = await trip(tester, uuid);
      expect(regenerated, isTrue);
      expect(after.logStaleSince, isNull);
      expect(after.log, isNot(contains('Met the other team here.')));
      expect(after.log, contains('Chamber'));
    });
  });

  group('the question before an edit', () {
    /// Runs the prompt from a real context and returns what it decided.
    Future<TripLogUpdate?> decide(
      WidgetTester tester,
      Uuid tripUuid, {
      String? answer,
    }) async {
      TripLogUpdate? result;
      var done = false;
      await LayoutHarness.renderAndCatch(
        tester,
        deviceProfiles[1],
        () => scoped(
          Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () async {
                  result = await TripLogUpdatePrompt.decide(
                    context,
                    ref,
                    tripUuid,
                  );
                  done = true;
                },
                child: const Text('edit'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('edit'));
      await settle(tester);
      if (answer != null) {
        await tester.tap(find.text(answer).last);
        await settle(tester);
      }
      expect(done, isTrue, reason: 'the prompt never returned');
      return result;
    }

    Future<void> regenerateOnEdit(WidgetTester tester) => tester.runAsync(
      () => container
          .read(currentUserServiceProvider)
          .setTripLogRegenerateOnEdit(true),
    );

    testWidgets('with the setting off nothing is asked', (tester) async {
      final uuid = await staleTrip(tester, stale: false);
      expect(await decide(tester, uuid), TripLogUpdate.markStale);
    });

    testWidgets('a log its points would render the same is regenerated '
        'without asking', (tester) async {
      await seedCave(tester);
      await regenerateOnEdit(tester);
      final uuid = (await tester.runAsync(() async {
        final uuid = await service.startTrip(caveUuid, 'Trip');
        await service.stopTrip();
        return uuid;
      }))!;
      expect(await decide(tester, uuid), TripLogUpdate.regenerate);
    });

    testWidgets('a log with typed text gets the question', (tester) async {
      final uuid = await staleTrip(tester, stale: false);
      await regenerateOnEdit(tester);
      expect(
        await decide(
          tester,
          uuid,
          answer: LocServ.inst.t('trip_log_keep_as_written'),
        ),
        TripLogUpdate.markStale,
      );
    });

    testWidgets('and cancelling it cancels the edit', (tester) async {
      final uuid = await staleTrip(tester, stale: false);
      await regenerateOnEdit(tester);
      expect(
        await decide(tester, uuid, answer: LocServ.inst.t('cancel')),
        isNull,
      );
    });
  });

  group('the log page', () {
    // The page's first-visit product tour lays an overlay over everything
    // and takes the taps; switched off the way the app's own test does.
    setUp(() => SettingsHelper.saveStringConfig('tour_auto_disabled', 'true'));

    testWidgets('says what editing points does here', (tester) async {
      final uuid = await staleTrip(tester, stale: false);
      await LayoutHarness.renderAndCatch(
        tester,
        deviceProfiles[1],
        () => scoped(CaveTripLogPage(tripUuid: uuid)),
      );
      await settle(tester);
      expect(find.text(LocServ.inst.t('trip_log_mode_keeps')), findsOneWidget);
      expect(
        find.text(LocServ.inst.t('trip_log_stale_title')),
        findsNothing,
        reason: 'a log that has not fallen behind gets no warning',
      );
    });

    testWidgets('keeping a stale log leaves unsaved typing alone', (
      tester,
    ) async {
      final uuid = await staleTrip(tester);
      await LayoutHarness.renderAndCatch(
        tester,
        deviceProfiles[1],
        () => scoped(CaveTripLogPage(tripUuid: uuid)),
      );
      await settle(tester);
      expect(find.text(LocServ.inst.t('trip_log_stale_title')), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'typed, not saved');
      await tester.tap(find.text(LocServ.inst.t('trip_log_keep_as_written')));
      await settle(tester);

      expect(find.text('typed, not saved'), findsOneWidget);
      expect(find.text(LocServ.inst.t('trip_log_stale_title')), findsNothing);
    });
  });
}
