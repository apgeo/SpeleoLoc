import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/sync/sync_table_registry.dart';

/// Focused tests for the extracted [SyncTableRegistry]. Verifies the
/// table list shape (FK-dependency order, no surprise duplicates) so a
/// future refactor that accidentally reorders or drops a table is
/// flagged here instead of only blowing up via the broader
/// `sync_archive_test.dart` import round-trip.
void main() {
  late AppDatabase db;
  late SyncTableRegistry registry;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    registry = SyncTableRegistry(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('tables() returns the expected 13 handlers in FK order', () {
    final names = registry.tables().map((t) => t.name).toList();
    expect(names, const <String>[
      // Parents first.
      'users',
      'surface_areas',
      'caves',
      'cave_areas',
      'cave_places',
      'raster_maps',
      'cave_place_to_raster_map_definitions',
      'cave_trips',
      'cave_trip_points',
      'documentation_files',
      'documentation_files_to_geofeatures',
      'documentation_files_to_cave_trips',
      'trip_report_templates',
    ]);
  });

  test('tables() entries are unique', () {
    final names = registry.tables().map((t) => t.name).toList();
    expect(names.toSet().length, names.length);
  });

  test('dump on an empty database returns empty lists per table', () async {
    for (final t in registry.tables()) {
      final rows = await t.dump();
      expect(rows, isEmpty, reason: 'expected ${t.name} to be empty');
    }
  });
}
