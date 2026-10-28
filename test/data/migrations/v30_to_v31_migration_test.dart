import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/data/source/database/migrations/migrations.dart';

/// Functional coverage for [V30ToV31Migration]: the raster entries learn the
/// stored picture's size and turn as empty columns, keeping every row, and a
/// second run changes nothing.
void main() {
  late AppDatabase db;
  final map = Uuid.v7();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // forTesting opens at the current schema. Recreate the v30 table the
    // migration runs against, with one map already recorded.
    await db.customStatement('DROP TABLE silexgis_raster_entry');
    await db.customStatement(
      'CREATE TABLE silexgis_raster_entry ('
      'profile_uuid TEXT(36) NOT NULL, '
      'entity_uuid BLOB NOT NULL, '
      'map_uuid BLOB NOT NULL, '
      'is_pin BOOLEAN NOT NULL DEFAULT 0, '
      'received BOOLEAN NOT NULL DEFAULT 0, '
      'sent BOOLEAN NOT NULL DEFAULT 0, '
      'document_id BLOB, '
      'picture_version TEXT(36), '
      'picture_sha256 TEXT(64), '
      'area_id BLOB, '
      'PRIMARY KEY (profile_uuid, entity_uuid))',
    );
    await db.customStatement(
      'INSERT INTO silexgis_raster_entry '
      '(profile_uuid, entity_uuid, map_uuid, received, picture_sha256) '
      'VALUES (?, ?, ?, 1, ?)',
      ['p-1', map.bytes, map.bytes, 'ab12'],
    );
  });

  tearDown(() => db.close());

  Future<Set<String>> columns() async => <String>{
    for (final row
        in await db
            .customSelect('PRAGMA table_info(silexgis_raster_entry)')
            .get())
      row.read<String>('name'),
  };

  Future<void> migrate() =>
      const V30ToV31Migration().apply(db, db.createMigrator());

  test('adds the picture frame, empty, and keeps the rows', () async {
    await migrate();

    expect(
      await columns(),
      containsAll(<String>[
        'picture_width',
        'picture_height',
        'picture_mirrored',
        'picture_turn',
      ]),
    );
    final row = await db.select(db.silexgisRasterEntry).getSingle();
    expect(row.entityUuid, map);
    expect(row.received, isTrue);
    expect(row.pictureSha256, 'ab12');
    expect(row.pictureWidth, isNull);
    expect(row.pictureHeight, isNull);
    expect(row.pictureMirrored, isNull);
    expect(row.pictureTurn, isNull);
  });

  test('running it again changes nothing', () async {
    await migrate();
    await migrate();

    expect((await columns()).length, 14);
    expect(await db.select(db.silexgisRasterEntry).get(), hasLength(1));
  });
}
