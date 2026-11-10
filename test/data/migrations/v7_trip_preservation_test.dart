import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/source/database/app_database.dart';

import '../../support/schema_snapshots.dart';

/// The v7 to v8 step rebuilds cave_trips for a new UNIQUE constraint. It
/// must keep the trips a v7 database holds, not drop them, including two
/// trips of one cave that share a title, which v7 allowed. The database is
/// built from the v7 schema with invented rows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('v7_trip_test_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('v7 -> current migration keeps existing cave_trips', () async {
    final cave = Uuid.v7();
    final survivor = Uuid.v7();
    final twins = [Uuid.v7(), Uuid.v7()];
    final f = createDatabaseAtVersion(
      p.join(tmp.path, 'v7.sqlite'),
      7,
      seed: (d) {
        d.execute('INSERT INTO caves (uuid, title) VALUES (?, ?)', [
          cave.bytes,
          'Invented Cave',
        ]);
        for (final (uuid, title, startedAt) in [
          (survivor, 'Survivor Trip', 1700000001000),
          (twins[0], 'Invented Twin Trip', 1700000002000),
          (twins[1], 'Invented Twin Trip', 1700000003000),
        ]) {
          d.execute(
            'INSERT INTO cave_trips (uuid, cave_uuid, title, log, '
            'trip_started_at, trip_ended_at, created_at, updated_at) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [
              uuid.bytes,
              cave.bytes,
              title,
              'invented log of $title',
              startedAt,
              startedAt + 500,
              startedAt,
              startedAt + 600,
            ],
          );
        }
      },
    );

    final db = AppDatabase.forTesting(NativeDatabase(f));
    try {
      final trips = {
        for (final t in await db.select(db.caveTrips).get()) t.uuid: t,
      };
      expect(trips.keys, unorderedEquals([survivor, ...twins]));
      expect(trips[survivor]!.title, 'Survivor Trip');
      expect(trips[survivor]!.log, 'invented log of Survivor Trip');
      expect(trips[survivor]!.tripEndedAt, 1700000001500);
      expect(trips[twins[1]]!.updatedAt, 1700000003600);
      expect(
        trips.values.where((t) => t.title == 'Invented Twin Trip'),
        hasLength(2),
        reason: 'same-titled trips of one cave were allowed at v7',
      );
    } finally {
      await db.close();
    }
  });
}
