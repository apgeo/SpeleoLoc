import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/data/source/database/migrations/migrations.dart';

/// Functional coverage for [V33ToV34Migration]: a v33 database gains the two
/// 3D-model tables and their index, and a second run changes nothing.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // forTesting opens at the current schema; take the database back to v33.
    await db.customStatement('DROP TABLE cave_place_model_stations');
    await db.customStatement('DROP TABLE cave_default_survey_models');
  });

  tearDown(() => db.close());

  Future<Set<String>> objects() async => <String>{
    for (final row
        in await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE name LIKE 'cave_%model%' "
              "OR name LIKE 'idx_cave_place_model%'",
            )
            .get())
      row.read<String>('name'),
  };

  Future<void> migrate() =>
      const V33ToV34Migration().apply(db, db.createMigrator());

  test('creates both tables and the index', () async {
    expect(await objects(), isEmpty);
    await migrate();
    expect(await objects(), {
      'cave_place_model_stations',
      'cave_default_survey_models',
      'idx_cave_place_model_stations_model',
    });
    expect(await db.select(db.cavePlaceModelStations).get(), isEmpty);
  });

  test('running it again changes nothing', () async {
    await migrate();
    await migrate();
    expect(await objects(), hasLength(3));
  });
}
