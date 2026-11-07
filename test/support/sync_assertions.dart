import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/sync/sync_table_registry.dart';

/// Fails when a row of [db] points at a row that is not there: the foreign
/// keys SQLite knows of, and the document links, which name the feature
/// they document by type rather than by a foreign key.
Future<void> expectNoOrphans(AppDatabase db, {String? reason}) async {
  final broken = await db.customSelect('PRAGMA foreign_key_check').get();
  expect(
    broken.map((r) => r.data).toList(),
    isEmpty,
    reason: reason ?? 'foreign_key_check',
  );
  final dangling = await db.customSelect('''
    SELECT l.geofeature_type AS type, COUNT(*) AS n
    FROM documentation_files_to_geofeatures l
    WHERE (l.geofeature_type = 'cave'
           AND NOT EXISTS (SELECT 1 FROM caves c WHERE c.uuid = l.geofeature_uuid))
       OR (l.geofeature_type = 'cave_area'
           AND NOT EXISTS (SELECT 1 FROM cave_areas a WHERE a.uuid = l.geofeature_uuid))
       OR (l.geofeature_type = 'cave_place'
           AND NOT EXISTS (SELECT 1 FROM cave_places p WHERE p.uuid = l.geofeature_uuid))
    GROUP BY l.geofeature_type
    ''').get();
  expect(
    dangling.map((r) => r.data).toList(),
    isEmpty,
    reason: reason ?? 'document links to a missing feature',
  );
}

/// What [db] would send in a sync archive, table by table: each table's
/// records as a sorted list of canonical JSON lines, so two databases
/// holding the same records compare equal whatever order they were written
/// in.
///
/// A record is what a merge compares: its stamps, authorship and the
/// readings a device refreshes on its own are left out, as a merge leaves
/// a row alone when only those differ; and a row stamped deleted, as an
/// unregistered beacon is, counts as gone. Users are matched by name across
/// devices, and each device keeps its own `system` user, so a user stands
/// here for its name: as a row of `users`, and wherever another row names
/// one.
Future<Map<String, List<String>>> syncedContent(AppDatabase db) async {
  final names = <String, String>{
    for (final u in await db.select(db.users).get())
      u.uuid.toString(): 'user:${u.username}',
  };
  Object? named(Object? value) => names[value] ?? value;
  return {
    for (final table in SyncTableRegistry(db).tables())
      table.name: [
        for (final row in await table.dump())
          if (row['deleted_at'] == null)
            table.name == 'users'
                ? 'user:${row['username']}'
                : _canonical({
                    for (final MapEntry(:key, :value) in row.entries)
                      if (!_bookkeeping.contains(key)) key: named(value),
                  }),
      ]..sort(),
  };
}

const _bookkeeping = <String>{
  'created_at',
  'updated_at',
  'deleted_at',
  'created_by_user_uuid',
  'last_modified_by_user_uuid',
  'last_seen_at',
  'last_battery_mv',
  'last_temperature_c',
  'last_humidity_pct',
  'last_pressure_hpa',
  'last_movement_counter',
  'firmware_version',
  'log_stale_since',
};

/// Fails when [a] and [b] would not send the same records, field for field,
/// naming the first table that differs.
Future<void> expectConverged(AppDatabase a, AppDatabase b) async {
  final left = await syncedContent(a);
  final right = await syncedContent(b);
  for (final table in left.keys) {
    expect(right[table], left[table], reason: '$table differs');
  }
}

String _canonical(Map<String, Object?> row) =>
    jsonEncode(Map.fromEntries(row.entries.toList()..sort(_byKey)));

int _byKey(MapEntry<String, Object?> x, MapEntry<String, Object?> y) =>
    x.key.compareTo(y.key);
