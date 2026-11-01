import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/data/source/database/migrations/migrations.dart';

/// Functional coverage for [V34ToV35Migration]: a v34 database gains the
/// local-only table of an installation's survey models, and a second run
/// changes nothing.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // forTesting opens at the current schema; take the database back to v34.
    await db.customStatement('DROP TABLE silexgis_survey_model');
  });

  tearDown(() => db.close());

  Future<Set<String>> objects() async => <String>{
    for (final row
        in await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE name LIKE "
              "'%silexgis_survey_model%' AND name NOT LIKE 'sqlite_%'",
            )
            .get())
      row.read<String>('name'),
  };

  Future<void> migrate() =>
      const V34ToV35Migration().apply(db, db.createMigrator());

  test('creates the table and its index', () async {
    expect(await objects(), isEmpty);
    await migrate();
    expect(await objects(), {
      'silexgis_survey_model',
      'idx_silexgis_survey_model_document',
    });
    expect(await db.select(db.silexgisSurveyModel).get(), isEmpty);
  });

  test('running it again changes nothing', () async {
    await migrate();
    await migrate();
    expect(await objects(), hasLength(2));
  });
}
