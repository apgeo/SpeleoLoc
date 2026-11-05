import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/add_new_cave.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/widgets/product_tour.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Fails the first entrance-place write, as a locked database would.
class _FailOncePlaces extends CavePlaceRepository {
  _FailOncePlaces(super.db, super.currentUser, super.logger);

  bool failNext = true;

  @override
  Future<void> addCavePlace(
    Uuid caveUuid,
    String title, {
    bool isEntrance = false,
    bool isMainEntrance = false,
  }) async {
    if (failNext) {
      failNext = false;
      throw StateError('database is locked');
    }
    return super.addCavePlace(
      caveUuid,
      title,
      isEntrance: isEntrance,
      isMainEntrance: isMainEntrance,
    );
  }
}

/// The page keeps a repeating animation running, so it never settles.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
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
        cavePlaceRepositoryProvider.overrideWith(
          (ref) => _FailOncePlaces(
            ref.watch(appDatabaseProvider),
            ref.watch(currentUserServiceProvider),
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

  testWidgets('a retry after the entrance place failed adds no second cave', (
    tester,
  ) async {
    // The first-visit tour would cover the form.
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
                  MaterialPageRoute(builder: (_) => const CaveFormPage()),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Test Cave');

    await tester.tap(find.text('add'));
    await settle(tester);
    expect(find.byType(CaveFormPage), findsOneWidget);
    expect(find.textContaining('database is locked'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));

    await tester.tap(find.text('add'));
    await settle(tester);
    expect(find.byType(CaveFormPage), findsNothing);

    final caves = await db.select(db.caves).get();
    expect(caves.map((c) => c.title), ['Test Cave']);
    final places = await db.select(db.cavePlaces).get();
    expect(places.length, 1);
    expect(places.single.caveUuid, caves.single.uuid);
  });
}
