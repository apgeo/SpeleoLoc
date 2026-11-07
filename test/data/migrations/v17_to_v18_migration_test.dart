import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

import '../../support/schema_snapshots.dart';

/// The v17 to v18 step rebuilds cave_place_beacons so that a tag's identity
/// is unique among its active registrations only: an unassigned tag can be
/// registered again in the same cave, a registered one cannot be registered
/// twice. The rebuild must keep every registration as it was, a removed one
/// still removed. Every value here is invented.
void main() {
  late Directory tmp;
  late File f;

  final cave = Uuid.v7();
  final place = Uuid.v7();
  final active = Uuid.v7();
  final removed = Uuid.v7();
  final ruuvi = Uuid.v7();
  const activeTag = ('a0000000-0000-4000-8000-000000000001', 1, 1);
  const removedTag = ('a0000000-0000-4000-8000-000000000002', 2, 2);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('v17_to_v18_');
    f = createDatabaseAtVersion(
      p.join(tmp.path, 'v17.sqlite'),
      17,
      seed: (d) {
        d.execute('INSERT INTO caves (uuid, title) VALUES (?, ?)', [
          cave.bytes,
          'Invented Cave',
        ]);
        d.execute(
          'INSERT INTO cave_places (uuid, title, cave_uuid) VALUES (?, ?, ?)',
          [place.bytes, 'Invented Place', cave.bytes],
        );
        for (final (uuid, (proximity, major, minor), deletedAt) in [
          (active, activeTag, null),
          (removed, removedTag, 1700000005000),
        ]) {
          d.execute(
            'INSERT INTO cave_place_beacons (uuid, cave_place_uuid, '
            'cave_uuid, beacon_type, proximity_uuid, major, minor, '
            'last_battery_mv, created_at, updated_at, deleted_at) '
            "VALUES (?, ?, ?, 'ibeacon', ?, ?, ?, 2900, 1700000001000, "
            '1700000002000, ?)',
            [
              uuid.bytes,
              place.bytes,
              cave.bytes,
              proximity,
              major,
              minor,
              deletedAt,
            ],
          );
        }
        d.execute(
          'INSERT INTO cave_place_beacons (uuid, cave_place_uuid, cave_uuid, '
          'beacon_type, mac_address, last_battery_mv, last_temperature_c, '
          'firmware_version, created_at) '
          "VALUES (?, ?, ?, 'ruuvi', 'AA:BB:CC:00:00:01', 3010, 7.5, "
          "'invented-fw', 1700000003000)",
          [ruuvi.bytes, place.bytes, cave.bytes],
        );
      },
    );
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Map<Uuid, Row> beacons() {
    final d = sqlite3.open(f.path, mode: OpenMode.readOnly);
    try {
      return {
        for (final r in d.select('SELECT * FROM cave_place_beacons'))
          Uuid.fromBytes(r['uuid'] as List<int>): r,
      };
    } finally {
      d.close();
    }
  }

  test('keeps every registration as it was', () async {
    final before = beacons();

    await openThroughApp(f);

    final after = beacons();
    expect(after.keys, unorderedEquals(before.keys));
    for (final uuid in before.keys) {
      for (final column in before[uuid]!.keys) {
        expect(
          after[uuid]![column],
          before[uuid]![column],
          reason: '$column of ${before[uuid]!['beacon_type']} $uuid',
        );
      }
    }
    expect(after[removed]!['deleted_at'], 1700000005000);
    expect(after[ruuvi]!['last_battery_mv'], 3010);
  });

  group('a new registration', () {
    void register(Database d, (String, int, int) tag) {
      final (proximity, major, minor) = tag;
      d.execute(
        'INSERT INTO cave_place_beacons (uuid, cave_place_uuid, cave_uuid, '
        "beacon_type, proximity_uuid, major, minor) VALUES (?, ?, ?, "
        "'ibeacon', ?, ?, ?)",
        [Uuid.v7().bytes, place.bytes, cave.bytes, proximity, major, minor],
      );
    }

    test('of a removed tag is accepted', () async {
      await openThroughApp(f);
      final d = sqlite3.open(f.path);
      try {
        register(d, removedTag);
        expect(
          d
              .select(
                'SELECT COUNT(*) AS n FROM cave_place_beacons WHERE major = 2',
              )
              .single['n'],
          2,
        );
      } finally {
        d.close();
      }
    });

    test('of a tag registered in the cave is refused', () async {
      await openThroughApp(f);
      final d = sqlite3.open(f.path);
      try {
        expect(() => register(d, activeTag), throwsA(isA<SqliteException>()));
      } finally {
        d.close();
      }
    });
  });
}
