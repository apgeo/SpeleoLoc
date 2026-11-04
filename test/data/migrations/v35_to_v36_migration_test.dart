import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/data/source/database/migrations/migrations.dart';

/// Functional coverage for [V35ToV36Migration]: a v35 database gains the
/// local-only tables of download rows waiting for their container and of
/// upload rows waiting for their answer, and a second run changes nothing.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // forTesting opens at the current schema; take the database back to v35.
    await db.customStatement('DROP TABLE silexgis_deferred_row');
    await db.customStatement('DROP TABLE silexgis_upload_attempt');
  });

  tearDown(() => db.close());

  Future<Set<String>> tables() async => <String>{
    for (final row
        in await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN "
              "('silexgis_deferred_row', 'silexgis_upload_attempt')",
            )
            .get())
      row.read<String>('name'),
  };

  Future<void> migrate() =>
      const V35ToV36Migration().apply(db, db.createMigrator());

  test('creates both tables, empty', () async {
    expect(await tables(), isEmpty);
    await migrate();
    expect(await tables(), <String>{
      'silexgis_deferred_row',
      'silexgis_upload_attempt',
    });
    expect(await db.select(db.silexgisDeferredRow).get(), isEmpty);
    expect(await db.select(db.silexgisUploadAttempt).get(), isEmpty);
  });

  test('running it again changes nothing', () async {
    await migrate();
    await migrate();
    expect(await tables(), hasLength(2));
  });
}
