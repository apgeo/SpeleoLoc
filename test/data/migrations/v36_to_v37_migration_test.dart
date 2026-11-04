import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/data/source/database/migrations/migrations.dart';
import 'package:speleoloc/services/current_user_service.dart';

/// Functional coverage for [V36ToV37Migration] on the shapes a database
/// upgraded from v7 still has, and a second run changing nothing. Values are
/// invented.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() => db.close());

  Future<void> migrate() =>
      const V36ToV37Migration().apply(db, db.createMigrator());

  Future<List<Map<String, Object?>>> pragma(String sql) async => [
    for (final r in await db.customSelect(sql).get()) r.data,
  ];

  Future<Set<String>> indexNames() async => {
    for (final r in await pragma(
      "SELECT name FROM sqlite_master WHERE type = 'index' "
      "AND name NOT LIKE 'sqlite_%'",
    ))
      r['name']! as String,
  };

  group('cave places brought up from v7', () {
    final cave = Uuid.v7();
    final place = Uuid.v7();

    setUp(() async {
      // The v7 definition of the entrance flags: nullable, no default.
      await db.customStatement('DROP TABLE cave_places');
      await db.customStatement(
        'CREATE TABLE cave_places (uuid BLOB PRIMARY KEY NOT NULL, '
        'title TEXT NOT NULL, description TEXT, cave_uuid BLOB NOT NULL '
        'REFERENCES caves(uuid), cave_area_uuid BLOB REFERENCES '
        'cave_areas(uuid), latitude REAL, longitude REAL, depth_in_cave REAL, '
        'is_entrance INTEGER, is_main_entrance INTEGER, created_at INTEGER, '
        'updated_at INTEGER, deleted_at INTEGER, created_by_user_uuid BLOB, '
        'last_modified_by_user_uuid BLOB, altitude REAL, '
        'place_code_identifier TEXT, qr_code_resource_identifier TEXT, '
        'UNIQUE(title, cave_uuid, cave_area_uuid) ON CONFLICT ROLLBACK)',
      );
      await db.customStatement(
        'CREATE UNIQUE INDEX idx_cave_places_title_no_area '
        'ON cave_places(title, cave_uuid) WHERE cave_area_uuid IS NULL',
      );
      await db.customStatement(
        'INSERT INTO caves (uuid, title) VALUES (?, ?)',
        [cave.bytes, 'Invented Cave'],
      );
      // An insert that leaves the flags out, as the add-place form does.
      await db.customStatement(
        'INSERT INTO cave_places (uuid, title, cave_uuid, '
        'place_code_identifier, latitude) VALUES (?, ?, ?, ?, ?)',
        [place.bytes, 'Invented Place', cave.bytes, 'A1', 45.5],
      );
    });

    test('get NOT NULL DEFAULT 0 entrance flags, NULLs read as 0', () async {
      await migrate();

      final flags = {
        for (final c in await pragma('PRAGMA table_info(cave_places)'))
          if ((c['name']! as String).startsWith('is_'))
            c['name']: (c['notnull'], c['dflt_value']),
      };
      expect(flags, {'is_entrance': (1, '0'), 'is_main_entrance': (1, '0')});

      final read = await db.select(db.cavePlaces).getSingle();
      expect(read.uuid, place);
      expect(read.title, 'Invented Place');
      expect(read.placeCodeIdentifier, 'A1');
      expect(read.latitude, 45.5);
      expect((read.isEntrance, read.isMainEntrance), (0, 0));
      expect(
        await indexNames(),
        containsAll(<String>[
          'idx_cave_places_title_no_area',
          'idx_cave_places_cave',
          'idx_cave_places_place_code',
          'idx_cave_places_qr_code',
        ]),
      );
    });

    test('a second run changes nothing', () async {
      await migrate();
      final once = await pragma(
        "SELECT name, sql FROM sqlite_master WHERE tbl_name = 'cave_places'",
      );
      await migrate();
      expect(
        await pragma(
          "SELECT name, sql FROM sqlite_master WHERE tbl_name = 'cave_places'",
        ),
        once,
      );
    });
  });

  test(
    'configurations from v7 lose the UNIQUE on their key, rows kept',
    () async {
      await db.customStatement('DROP TABLE configurations');
      await db.customStatement(
        'CREATE TABLE configurations (id INTEGER PRIMARY KEY AUTOINCREMENT '
        'UNIQUE NOT NULL, title TEXT NOT NULL UNIQUE, value TEXT, '
        'created_at INTEGER, updated_at INTEGER, '
        'is_synced INTEGER NOT NULL DEFAULT 0)',
      );
      await db.customStatement(
        "INSERT INTO configurations (id, title, value, is_synced) VALUES "
        "(3, 'invented_a', 'x', 0), (7, 'qcri_mode', 'plain', 1)",
      );

      await migrate();

      final uniqueOnId = <String>[];
      for (final i in await pragma('PRAGMA index_list(configurations)')) {
        final cols = await pragma("PRAGMA index_info('${i['name']}')");
        if (cols.length == 1 && cols.single['name'] == 'id') {
          uniqueOnId.add(i['name']! as String);
        }
      }
      expect(uniqueOnId, isEmpty);
      expect(
        await pragma(
          'SELECT id, title, value, is_synced FROM configurations ORDER BY id',
        ),
        [
          {'id': 3, 'title': 'invented_a', 'value': 'x', 'is_synced': 0},
          {'id': 7, 'title': 'qcri_mode', 'value': 'plain', 'is_synced': 1},
        ],
      );
    },
  );

  test('creates the trip-point link index where it is missing', () async {
    await db.customStatement('DROP INDEX idx_doc_files_to_trip_points_point');

    await migrate();

    expect(await indexNames(), contains('idx_doc_files_to_trip_points_point'));
  });

  group('lookup indexes', () {
    const lookups = {
      'idx_cave_places_cave': 'SELECT * FROM cave_places WHERE cave_uuid = 1',
      'idx_cave_places_place_code':
          "SELECT * FROM cave_places WHERE place_code_identifier = 'a'",
      'idx_cave_places_qr_code':
          "SELECT * FROM cave_places WHERE qr_code_resource_identifier = 'a'",
      'idx_cave_place_definitions_map':
          'SELECT * FROM cave_place_to_raster_map_definitions '
          'WHERE raster_map_uuid = 1',
      'idx_documentation_files_hash':
          "SELECT * FROM documentation_files WHERE file_hash = 'a'",
    };

    test('are created where they are missing', () async {
      for (final name in lookups.keys) {
        await db.customStatement('DROP INDEX $name');
      }

      await migrate();

      expect(await indexNames(), containsAll(lookups.keys));
    });

    test('serve the lookups', () async {
      for (final MapEntry(key: name, value: query) in lookups.entries) {
        final plan = await pragma('EXPLAIN QUERY PLAN $query');
        expect(
          plan.map((r) => r['detail']).join(' '),
          contains(name),
          reason: query,
        );
      }
    });
  });

  test('clears is_synced on every configuration key outside the synced '
      'set', () async {
    const syncedKeys = [
      ConfigKey.placeCodeStrategy,
      ConfigKey.placeCodeStrategyConfig,
      ConfigKey.qcriMode,
      ConfigKey.qcriHashConfig,
    ];
    const deviceOnlyKeys = [
      ConfigKey.ftpProfiles,
      ConfigKey.deviceUuid,
      'invented_device_key',
    ];
    await db.customStatement('DELETE FROM configurations');
    for (final key in [...syncedKeys, ...deviceOnlyKeys]) {
      await db.customStatement(
        'INSERT INTO configurations (title, value, is_synced) VALUES (?, ?, 1)',
        [key, 'invented'],
      );
    }
    await db.customStatement(
      'INSERT INTO configurations (title, value, is_synced) VALUES (?, ?, 0)',
      ['invented_unflagged_key', 'invented'],
    );

    await migrate();

    final flags = {
      for (final r in await pragma(
        'SELECT title, is_synced, value FROM configurations',
      ))
        r['title']: (r['is_synced'], r['value']),
    };
    expect(flags, {
      for (final key in syncedKeys) key: (1, 'invented'),
      for (final key in deviceOnlyKeys) key: (0, 'invented'),
      'invented_unflagged_key': (0, 'invented'),
    });
  });

  test('on a database already in shape, changes no schema', () async {
    final before = await pragma(
      'SELECT type, name, sql FROM sqlite_master ORDER BY name',
    );
    await migrate();
    expect(
      await pragma('SELECT type, name, sql FROM sqlite_master ORDER BY name'),
      before,
    );
  });
}
