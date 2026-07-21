import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/data/source/database/migrations/migrations.dart';

/// Functional coverage for [V16ToV17Migration]: existing NULL-area title
/// twins are renamed before the partial unique index is created, and the
/// index then rejects new twins.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // forTesting opens at the current schema, where the index already
    // exists. Recreate the pre-v17 state the migration runs against.
    await db.customStatement(
      'DROP INDEX IF EXISTS idx_cave_places_title_no_area',
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<Uuid> insertCave(String title) async {
    final uuid = Uuid.v7();
    await db.customStatement(
      'INSERT INTO caves (uuid, title, created_at, updated_at) '
      'VALUES (?, ?, 1, 1)',
      [uuid.bytes, title],
    );
    return uuid;
  }

  Future<Uuid> insertPlace(
    Uuid caveUuid,
    String title, {
    int? createdAt,
    Uuid? areaUuid,
  }) async {
    final uuid = Uuid.v7();
    await db.customStatement(
      'INSERT INTO cave_places '
      '(uuid, title, cave_uuid, cave_area_uuid, is_entrance, '
      'is_main_entrance, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, 0, 0, ?, ?)',
      [uuid.bytes, title, caveUuid.bytes, areaUuid?.bytes, createdAt, createdAt],
    );
    return uuid;
  }

  Future<List<String>> titlesOf(Uuid caveUuid) async {
    final rows = await db
        .customSelect(
          'SELECT title FROM cave_places WHERE cave_uuid = ? ORDER BY title',
          variables: [Variable.withBlob(caveUuid.bytes)],
        )
        .get();
    return rows.map((r) => r.read<String>('title')).toList();
  }

  Future<void> migrate() async {
    await const V16ToV17Migration().apply(db, db.createMigrator());
  }

  test('renames NULL-area twins, keeping the earliest row\'s title', () async {
    final cave = await insertCave('Cave');
    final keeper = await insertPlace(cave, 'Entrance', createdAt: 100);
    await insertPlace(cave, 'Entrance', createdAt: 200);
    await insertPlace(cave, 'Entrance', createdAt: 300);

    await migrate();

    expect(await titlesOf(cave), ['Entrance', 'Entrance 2', 'Entrance 3']);
    final kept = await db
        .customSelect(
          'SELECT title FROM cave_places WHERE uuid = ?',
          variables: [Variable.withBlob(keeper.bytes)],
        )
        .getSingle();
    expect(kept.read<String>('title'), 'Entrance');
  });

  test('rename skips titles already taken in the cave', () async {
    final cave = await insertCave('Cave');
    await insertPlace(cave, 'Entrance', createdAt: 100);
    await insertPlace(cave, 'Entrance', createdAt: 200);
    await insertPlace(cave, 'Entrance 2', createdAt: 50);

    await migrate();

    expect(await titlesOf(cave), ['Entrance', 'Entrance 2', 'Entrance 3']);
  });

  test('leaves distinct titles and non-NULL-area rows alone', () async {
    final cave = await insertCave('Cave');
    await db.customStatement(
      'INSERT INTO cave_areas (uuid, title, cave_uuid) VALUES (?, ?, ?)',
      [Uuid.v7().bytes, 'Area', cave.bytes],
    );
    final areaRow = await db
        .customSelect('SELECT uuid FROM cave_areas LIMIT 1')
        .getSingle();
    final area = Uuid.fromBytes(areaRow.read<Uint8List>('uuid'));

    await insertPlace(cave, 'Lake', createdAt: 100);
    // Same title inside an area: allowed to coexist with the NULL-area one
    // (covered by the table's own UNIQUE) and must not be renamed.
    await insertPlace(cave, 'Lake', createdAt: 200, areaUuid: area);

    await migrate();

    expect(await titlesOf(cave), ['Lake', 'Lake']);
  });

  test('created index rejects new NULL-area twins', () async {
    final cave = await insertCave('Cave');
    await insertPlace(cave, 'Entrance', createdAt: 100);

    await migrate();

    await expectLater(
      insertPlace(cave, 'Entrance', createdAt: 200),
      throwsA(isA<Exception>()),
    );
  });
}
