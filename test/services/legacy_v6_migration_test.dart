import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

import '../support/schema_snapshots.dart';

/// The integer-keyed schema of the first versions is re-keyed to uuids on
/// upgrade, every reference remapped. Each database here is built from the
/// schema of that version and an invented data set that touches every table
/// and every kind of reference.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('legacy_v6_test_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  for (final version in const [5, 6]) {
    test(
      'a v$version database is re-keyed with its rows and references',
      () async {
        final f = createDatabaseAtVersion(
          p.join(tmp.path, 'legacy_v$version.sqlite'),
          version,
          seed: _seedInventedLegacyData,
        );
        final before = _counts(f);

        final db = AppDatabase.forTesting(NativeDatabase(f));
        try {
          final caves = await db.select(db.caves).get();
          final areas = await db.select(db.caveAreas).get();
          final places = await db.select(db.cavePlaces).get();
          final maps = await db.select(db.rasterMaps).get();
          final trips = await db.select(db.caveTrips).get();
          final points = await db.select(db.caveTripPoints).get();
          final docs = await db.select(db.documentationFiles).get();
          final geoLinks = await db
              .select(db.documentationFilesToGeofeatures)
              .get();
          final tripLinks = await db
              .select(db.documentationFilesToCaveTrips)
              .get();
          final definitions = await db
              .select(db.cavePlaceToRasterMapDefinitions)
              .get();
          final surfaceAreas = await db.select(db.surfaceAreas).get();

          for (final uuid in [
            ...caves.map((r) => r.uuid),
            ...places.map((r) => r.uuid),
            ...maps.map((r) => r.uuid),
            ...areas.map((r) => r.uuid),
            ...surfaceAreas.map((r) => r.uuid),
            ...trips.map((r) => r.uuid),
            ...points.map((r) => r.uuid),
          ]) {
            expect(uuid.bytes, hasLength(16));
          }

          T byTitle<T>(Iterable<T> rows, String Function(T) title, String t) =>
              rows.singleWhere((r) => title(r) == t);
          final alpha = byTitle(caves, (c) => c.title, 'Invented Cave Alpha');
          final beta = byTitle(caves, (c) => c.title, 'Invented Cave Beta');
          final gallery = byTitle(
            areas,
            (a) => a.title,
            'Invented Upper Gallery',
          );
          final entrance = byTitle(places, (c) => c.title, 'Invented Entrance');
          final sump = byTitle(places, (c) => c.title, 'Invented Sump');
          final chamber = byTitle(places, (c) => c.title, 'Invented Chamber');
          final plan = byTitle(maps, (m) => m.title, 'Invented Plan');
          final section = byTitle(maps, (m) => m.title, 'Invented Section');
          final trip = trips.single;

          expect(alpha.surfaceAreaUuid, surfaceAreas.single.uuid);
          expect(beta.surfaceAreaUuid, isNull);
          expect(gallery.caveUuid, alpha.uuid);
          expect(entrance.caveUuid, alpha.uuid);
          expect(sump.caveAreaUuid, gallery.uuid);
          expect(chamber.caveUuid, beta.uuid);
          expect(section.caveAreaUuid, gallery.uuid);
          expect(section.mapType, 'projected profile');

          // A legacy QR number becomes the place code, as text.
          expect(entrance.placeCodeIdentifier, '101');
          expect(chamber.placeCodeIdentifier, '202');
          expect(sump.placeCodeIdentifier, isNull);
          expect(entrance.isEntrance, 1);
          expect(sump.isEntrance, 0, reason: 'a NULL flag reads as not');

          expect(definitions.single.cavePlaceUuid, entrance.uuid);
          expect(definitions.single.rasterMapUuid, plan.uuid);
          expect(definitions.single.xCoordinate, 10);

          expect(trip.caveUuid, alpha.uuid);
          expect(trip.log, _tripLog);
          expect(trip.tripStartedAt, 1700000000000);
          expect(trip.tripEndedAt, 1700003600000);
          final linked = points.singleWhere((pt) => pt.cavePlaceUuid != null);
          expect(linked.cavePlaceUuid, entrance.uuid);
          expect(linked.caveTripUuid, trip.uuid);
          expect(linked.notes, 'invented note at the entrance');
          expect(points, hasLength(2));

          final sketch = docs.single;
          expect(tripLinks.single.documentationFileUuid, sketch.uuid);
          expect(tripLinks.single.caveTripUuid, trip.uuid);
          expect(
            {for (final l in geoLinks) l.geofeatureType: l.geofeatureUuid},
            {
              'cave': alpha.uuid,
              'cave_place': sump.uuid,
              'cave_area': gallery.uuid,
            },
          );

          final stamp = await db
              .customSelect('PRAGMA user_version')
              .getSingle();
          expect(stamp.data.values.single, db.schemaVersion);
        } finally {
          await db.close();
        }

        final after = _counts(f);
        for (final MapEntry(key: table, value: count) in before.entries) {
          if (table == 'configurations') {
            // The upgrade adds keys of its own beside the one kept here.
            expect(after[table], greaterThan(count), reason: table);
          } else {
            expect(after[table], count, reason: table);
          }
        }
        expect(foreignKeyViolations(f), isEmpty);
      },
    );
  }

  test('a re-keying that fails part-way leaves the integer-keyed tables as '
      'they were', () async {
    final f = createDatabaseAtVersion(
      p.join(tmp.path, 'legacy_failing.sqlite'),
      6,
      seed: (d) {
        _seedInventedLegacyData(d);
        // A point of a trip that is not there has no uuid to point at, so
        // its reinsert throws after every earlier table is already written.
        d.execute(
          'INSERT INTO cave_trip_points (id, cave_trip_id, scanned_at) '
          'VALUES (99, 99, 1700000000000)',
        );
      },
    );
    final before = _counts(f);

    Future<Object?> tryOpen() async {
      final db = AppDatabase.forTesting(NativeDatabase(f));
      try {
        await db.customSelect('SELECT 1').get();
        return null;
      } catch (e) {
        return e;
      } finally {
        await db.close();
      }
    }

    expect(await tryOpen(), isNotNull);
    expect(userVersionOf(f), 6);
    expect(_counts(f), before);
    expect(_columns(f, 'caves'), contains('id'));
    expect(_columns(f, 'caves'), isNot(contains('uuid')));

    // Nothing was left half-done for the next open to trip over.
    expect(await tryOpen(), isNotNull);
    expect(userVersionOf(f), 6);
    expect(_counts(f), before);
  });
}

const _tripLog =
    '10:02 Invented entry at the entrance\n'
    '10:40 Invented note: water level low';

/// Every table of the integer-keyed schema, with each kind of reference:
/// required and optional parents, a cave area, a map pinned by a place, a
/// document linked to a cave, a place, an area and a trip, and trip points
/// with and without a place. Tables a version lacks are skipped.
void _seedInventedLegacyData(Database d) {
  final tables = {
    for (final r in d.select(
      "SELECT name FROM sqlite_master WHERE type='table'",
    ))
      r['name'] as String,
  };
  void insert(String table, String columns, List<List<Object?>> rows) {
    if (!tables.contains(table)) return;
    final marks = List.filled(rows.first.length, '?').join(', ');
    for (final row in rows) {
      d.execute('INSERT INTO $table ($columns) VALUES ($marks)', row);
    }
  }

  const t = 1700000000000;
  insert('surface_areas', 'id, title, created_at', [
    [1, 'Invented Karst Plateau', t],
  ]);
  insert('caves', 'id, title, surface_area_id, created_at, updated_at', [
    [1, 'Invented Cave Alpha', 1, t, t + 1],
    [2, 'Invented Cave Beta', null, t, t + 2],
  ]);
  insert('cave_areas', 'id, title, cave_id, created_at', [
    [1, 'Invented Upper Gallery', 1, t],
  ]);
  insert(
    'cave_places',
    'id, title, cave_id, cave_area_id, place_qr_code_identifier, latitude, '
        'longitude, depth_in_cave, is_entrance, created_at',
    [
      [1, 'Invented Entrance', 1, null, 101, 45.5, 25.25, 0.0, 1, t],
      [2, 'Invented Sump', 1, 1, null, null, null, 42.5, null, t],
      [3, 'Invented Chamber', 2, null, 202, null, null, 7.0, 0, t],
    ],
  );
  insert(
    'raster_maps',
    'id, title, map_type, file_name, cave_id, cave_area_id, created_at',
    [
      [1, 'Invented Plan', 'plane view', 'invented_plan.png', 1, null, t],
      [
        2,
        'Invented Section',
        'projected profile',
        'invented_section.png',
        1,
        1,
        t,
      ],
    ],
  );
  insert(
    'cave_place_to_raster_map_definitions',
    'id, x_coordinate, y_coordinate, cave_place_id, raster_map_id',
    [
      [1, 10, 20, 1, 1],
    ],
  );
  insert(
    'documentation_files',
    'id, title, file_name, file_size, file_type, created_at',
    [
      [1, 'Invented Sketch', 'invented_sketch.jpg', 2048, 'image', t],
    ],
  );
  insert(
    'documentation_files_to_geofeatures',
    'id, geofeature_id, geofeature_type, documentation_file_id',
    [
      [1, 1, 'cave', 1],
      [2, 2, 'cave_place', 1],
      [3, 1, 'cave_area', 1],
    ],
  );
  insert('configurations', 'id, title, value', [
    [1, 'invented_setting', 'on'],
  ]);
  insert(
    'cave_trips',
    'id, cave_id, title, trip_started_at, trip_ended_at, log, created_at',
    [
      [1, 1, 'Invented Survey Trip', t, t + 3600000, _tripLog, t],
    ],
  );
  insert(
    'cave_trip_points',
    'id, cave_trip_id, cave_place_id, scanned_at, '
        'notes',
    [
      [1, 1, 1, t + 60000, 'invented note at the entrance'],
      [2, 1, null, t + 120000, null],
    ],
  );
  insert(
    'documentation_files_to_cave_trips',
    'id, documentation_file_id, cave_trip_id, created_at',
    [
      [1, 1, 1, t],
    ],
  );
  insert(
    'trip_report_templates',
    'id, title, file_name, file_size, format, created_at',
    [
      [1, 'Invented Template', 'invented_template.docx', 1234, 'docx', t],
    ],
  );
  insert(
    'surface_places',
    'id, title, surface_place_qr_code_identifier, latitude, longitude',
    [
      [1, 'Invented Sinkhole', 9001, 45.5, 25.5],
    ],
  );
  insert('cave_entrances', 'id, cave_id, surface_place_id, title', [
    [1, 1, 1, 'Invented Main Entrance'],
  ]);
}

Map<String, int> _counts(File f) {
  final d = sqlite3.open(f.path, mode: OpenMode.readOnly);
  try {
    return {
      for (final r in d.select(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%'",
      ))
        r['name'] as String:
            d.select('SELECT COUNT(*) AS n FROM "${r['name']}"').single['n']
                as int,
    };
  } finally {
    d.close();
  }
}

Set<String> _columns(File f, String table) {
  final d = sqlite3.open(f.path, mode: OpenMode.readOnly);
  try {
    return {
      for (final r in d.select('PRAGMA table_info($table)'))
        r['name'] as String,
    };
  } finally {
    d.close();
  }
}
