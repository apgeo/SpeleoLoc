import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/data/source/database/migrations/migrations.dart';

/// Functional coverage for [V35ToV36Migration]: a v35 database gains the
/// local-only table of download rows waiting for their container, and a
/// second run changes nothing.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // forTesting opens at the current schema; take the database back to v35.
    await db.customStatement('DROP TABLE silexgis_deferred_row');
  });

  tearDown(() => db.close());

  Future<Set<String>> objects() async => <String>{
    for (final row
        in await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE name LIKE "
              "'silexgis_deferred_row%'",
            )
            .get())
      row.read<String>('name'),
  };

  Future<void> migrate() =>
      const V35ToV36Migration().apply(db, db.createMigrator());

  test('creates the table', () async {
    expect(await objects(), isEmpty);
    await migrate();
    expect(await objects(), contains('silexgis_deferred_row'));
    expect(await db.select(db.silexgisDeferredRow).get(), isEmpty);
  });

  test('running it again changes nothing', () async {
    await migrate();
    final first = await objects();
    await migrate();
    expect(await objects(), first);
  });
}
