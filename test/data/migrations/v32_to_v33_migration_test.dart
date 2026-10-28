import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/data/source/database/migrations/migrations.dart';

/// Functional coverage for [V32ToV33Migration]: the trip entries learn the
/// caver an installation names as an empty column, keeping every row, and a
/// second run changes nothing.
void main() {
  late AppDatabase db;
  final recording = Uuid.v7();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // forTesting opens at the current schema. Recreate the v32 table the
    // migration runs against, with one received recording already recorded.
    await db.customStatement('DROP TABLE silexgis_trip_entry');
    await db.customStatement(
      'CREATE TABLE silexgis_trip_entry ('
      'profile_uuid TEXT(36) NOT NULL, '
      'entity_uuid BLOB NOT NULL, '
      'recording_uuid BLOB NOT NULL, '
      'is_scan BOOLEAN NOT NULL DEFAULT 0, '
      'received BOOLEAN NOT NULL DEFAULT 0, '
      'sent BOOLEAN NOT NULL DEFAULT 0, '
      'author_device_user_id TEXT(36), '
      'PRIMARY KEY (profile_uuid, entity_uuid))',
    );
    await db.customStatement(
      'INSERT INTO silexgis_trip_entry '
      '(profile_uuid, entity_uuid, recording_uuid, received, '
      'author_device_user_id) VALUES (?, ?, ?, 1, ?)',
      ['p-1', recording.bytes, recording.bytes, 'u-1'],
    );
  });

  tearDown(() => db.close());

  Future<Set<String>> columns() async => <String>{
    for (final row
        in await db
            .customSelect('PRAGMA table_info(silexgis_trip_entry)')
            .get())
      row.read<String>('name'),
  };

  Future<void> migrate() =>
      const V32ToV33Migration().apply(db, db.createMigrator());

  test('adds the named caver, empty, and keeps the rows', () async {
    await migrate();

    expect(await columns(), contains('author_caver_id'));
    final row = await db.select(db.silexgisTripEntry).getSingle();
    expect(row.entityUuid, recording);
    expect(row.received, isTrue);
    expect(row.authorDeviceUserId, 'u-1');
    expect(row.authorCaverId, isNull);
  });

  test('running it again changes nothing', () async {
    await migrate();
    await migrate();

    expect((await columns()).length, 8);
    expect(
      await db.customSelect('SELECT * FROM silexgis_trip_entry').get(),
      hasLength(1),
    );
  });
}
