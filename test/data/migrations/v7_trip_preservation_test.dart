import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

/// Guards finding 3.6 / WS-C C1: the v7 -> v8 migration must PRESERVE
/// cave_trips rows, not drop them.
///
/// The shipped v7 fixture (`speleo_loc_export_20260423.sqlite`,
/// user_version 7) has 0 trips, so a trip is injected into a temp copy at
/// the raw sqlite level — before drift's migration ladder runs — to make the
/// old drop+create data loss observable.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('v7 -> current migration keeps existing cave_trips', () async {
    final source = File(
      'test_data/db/binaries/speleo_loc_export_20260423.sqlite',
    );
    expect(source.existsSync(), isTrue, reason: 'v7 fixture missing');

    final tmpDir = await Directory.systemTemp.createTemp('v7_trip_test_');
    final tmpFile = File(p.join(tmpDir.path, 'v7.sqlite'));
    await source.copy(tmpFile.path);

    // Inject a trip at the raw level, before AppDatabase migrations run.
    final raw = sqlite3.open(tmpFile.path);
    try {
      final userVersion =
          raw.select('PRAGMA user_version').first.values.first as int;
      expect(userVersion, 7, reason: 'fixture must be at schema v7');
      final caveUuid =
          raw.select('SELECT uuid FROM caves LIMIT 1').first.values.first
              as List<int>;
      final tripUuid = List<int>.generate(16, (i) => i + 1);
      raw.execute(
        'INSERT INTO cave_trips '
        '(uuid, cave_uuid, title, trip_started_at, created_at) '
        'VALUES (?, ?, ?, ?, ?)',
        [tripUuid, caveUuid, 'Survivor Trip', 1000, 1000],
      );
    } finally {
      raw.close();
    }

    // Opening as AppDatabase runs the migration ladder (v7 -> current).
    final db = AppDatabase.forTesting(NativeDatabase(tmpFile));
    try {
      expect(db.schemaVersion, greaterThanOrEqualTo(8));
      final trips = await db.select(db.caveTrips).get();
      expect(
        trips.map((t) => t.title),
        contains('Survivor Trip'),
        reason: 'the v7->v8 migration must preserve trips, not drop them',
      );
    } finally {
      await db.close();
      await tmpDir.delete(recursive: true);
    }
  });
}
