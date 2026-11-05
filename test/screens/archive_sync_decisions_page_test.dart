import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/settings/archive_sync_decisions_page.dart';

/// A cave area another phone created under a name this one already uses
/// waits on the page with the place inside it; merging it, once confirmed,
/// puts the place in the local area and leaves nothing to decide.
void main() {
  late AppDatabase db;
  late ProviderContainer container;
  final cave = Uuid.v7();
  final localHall = Uuid.v7();
  final incomingHall = Uuid.v7();
  final pillar = Uuid.v7();

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester) async {
    container = ProviderContainer(
      overrides: <Override>[appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await db
          .into(db.caves)
          .insert(CavesCompanion.insert(uuid: cave, title: 'Invented Cave'));
      await db
          .into(db.caveAreas)
          .insert(
            CaveAreasCompanion.insert(
              uuid: localHall,
              title: 'Hall',
              caveUuid: cave,
            ),
          );
      Future<void> hold(
        Uuid uuid,
        String table,
        Map<String, dynamic> row, {
        Uuid? collidesWith,
      }) => db
          .into(db.archiveHeldRow)
          .insert(
            ArchiveHeldRowCompanion.insert(
              entityUuid: uuid,
              entityTable: table,
              groupUuid: incomingHall,
              collidesWithUuid: Value(collidesWith),
              rowJson: jsonEncode(row),
              heldAt: 1,
            ),
          );
      await hold(incomingHall, 'cave_areas', {
        'uuid': incomingHall.toString(),
        'title': 'Hall',
        'cave_uuid': cave.toString(),
        'created_at': 1,
        'updated_at': 1,
      }, collidesWith: localHall);
      await hold(pillar, 'cave_places', {
        'uuid': pillar.toString(),
        'title': 'Pillar',
        'cave_uuid': cave.toString(),
        'cave_area_uuid': incomingHall.toString(),
        'is_entrance': 0,
        'is_main_entrance': 0,
        'created_at': 1,
        'updated_at': 1,
      });
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ArchiveSyncDecisionsPage()),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the held area with what waits on it', (tester) async {
    await pump(tester);

    expect(find.text('Hall'), findsOneWidget);
    expect(find.text('archive_decision_waiting'), findsOneWidget);
    expect(find.text('archive_decision_keep_both'), findsOneWidget);
  });

  testWidgets('merged once confirmed, the place moves to the local area', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('archive_decision_merge'));
    await tester.pumpAndSettle();
    expect(find.text('archive_decision_merge_title'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('archive_decision_merge'),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    final place = await tester.runAsync(
      () => (db.select(
        db.cavePlaces,
      )..where((p) => p.uuid.equalsValue(pillar))).getSingle(),
    );
    expect(place!.caveAreaUuid, localHall);
    expect(
      await tester.runAsync(() => db.select(db.archiveHeldRow).get()),
      isEmpty,
    );
    expect(find.text('archive_decisions_none'), findsOneWidget);
  });
}
