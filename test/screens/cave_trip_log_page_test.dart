import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/cave_trip_log_page.dart';
import 'package:speleoloc/services/cave_trip_repository.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/widgets/product_tour.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Writes fail as they would on a locked database.
class _LockedTrips extends CaveTripRepository {
  _LockedTrips(super.db, super.logger);

  @override
  Future<void> updateTripLog(Uuid tripUuid, String log) async {
    throw StateError('database is locked');
  }
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        caveTripRepositoryProvider.overrideWith(
          (ref) => _LockedTrips(
            ref.watch(appDatabaseProvider),
            ref.watch(changeLoggerProvider),
          ),
        ),
      ],
    );
    initRootContainer(container);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  testWidgets('a save that fails says so and keeps the page and the text', (
    tester,
  ) async {
    await setAutoToursDisabled(true);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => Stack(
            children: [
              SizedBox.expand(child: child),
              const AppToastHost(),
            ],
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CaveTripLogPage(tripUuid: Uuid.v7()),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'what happened');

    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(find.textContaining('database is locked'), findsOneWidget);
    expect(find.byType(CaveTripLogPage), findsOneWidget);
    expect(find.text('what happened'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });
}
