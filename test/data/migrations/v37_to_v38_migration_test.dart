import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/data/source/database/migrations/migrations.dart';

/// Functional coverage for [V37ToV38Migration]: an older database gains the
/// local-only table of archive rows waiting for a decision, and a second run
/// changes nothing.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // forTesting opens at the current schema; take the table away again.
    await db.customStatement('DROP TABLE archive_held_row');
  });

  tearDown(() => db.close());

  Future<bool> exists() async =>
      (await db
              .customSelect(
                "SELECT name FROM sqlite_master WHERE type = 'table' "
                "AND name = 'archive_held_row'",
              )
              .get())
          .isNotEmpty;

  Future<void> migrate() =>
      const V37ToV38Migration().apply(db, db.createMigrator());

  test('creates the table, empty', () async {
    expect(await exists(), isFalse);
    await migrate();
    expect(await exists(), isTrue);
    expect(await db.select(db.archiveHeldRow).get(), isEmpty);
  });

  test('running it again changes nothing', () async {
    await migrate();
    await db
        .into(db.archiveHeldRow)
        .insert(
          ArchiveHeldRowCompanion.insert(
            entityUuid: Uuid.v7(),
            entityTable: 'cave_areas',
            groupUuid: Uuid.v7(),
            rowJson: '{}',
            heldAt: 1,
          ),
        );
    await migrate();
    expect(await db.select(db.archiveHeldRow).get(), hasLength(1));
  });
}
