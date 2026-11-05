import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/services/trip_record_outcome.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';
import 'package:speleoloc/widgets/trip_record_feedback.dart';

/// What the caver is told after a scan or beacon detection: a paused trip
/// warns, with a way to resume, instead of confirming a point it dropped.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await LocServ.inst.setLocale('en');
    await LocServ.inst.load();
  });

  late AppDatabase db;
  late ProviderContainer container;
  late CaveTripService service;

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

  // The service starts by reading the database, which runs real futures
  // the test body's fake-async zone never completes on its own.
  Future<void> host(WidgetTester tester) async {
    await tester.runAsync(() async {
      service = container.read(caveTripServiceProvider);
      await container.read(currentUserServiceProvider).currentOrSystem();
    });
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Stack(
          children: [
            SizedBox.expand(child: child),
            const AppToastHost(),
          ],
        ),
        home: const Scaffold(),
      ),
    );
  }

  const added = 'Point added to trip';
  const paused = 'Trip paused — point not recorded';

  testWidgets('a recorded point is confirmed', (tester) async {
    await host(tester);

    showTripRecordFeedback(service, TripRecordOutcome.recorded);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(added), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
  });

  testWidgets('a paused trip warns instead, and Resume resumes it', (
    tester,
  ) async {
    await host(tester);
    await tester.runAsync(() async {
      final cave = await container.read(caveRepositoryProvider).addCave('C');
      await service.startTrip(cave, 'Trip');
      await service.pauseTrip();
    });

    showTripRecordFeedback(service, TripRecordOutcome.paused);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(added), findsNothing);
    expect(find.text(paused), findsOneWidget);
    await tester.tap(find.text(LocServ.inst.t('trip_resume')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(service.isPausedNotifier.value, isFalse);
    await tester.pump(const Duration(seconds: 7));
  });

  testWidgets('a beacon detection while paused names the place and warns', (
    tester,
  ) async {
    await host(tester);

    showTripRecordFeedback(
      service,
      TripRecordOutcome.paused,
      lead: 'Place detected: "Hall"',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Place detected: "Hall" · $paused'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
  });

  testWidgets('a detection outside the trip only names the place', (
    tester,
  ) async {
    await host(tester);

    showTripRecordFeedback(service, null, lead: 'Place detected: "Hall"');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Place detected: "Hall"'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
  });
}
