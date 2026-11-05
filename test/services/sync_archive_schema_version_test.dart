import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/sync/sync_table_registry.dart';

/// The archive schema version moves only when an archived table changes, and
/// then it has to: a phone on an older app reads the stamp to decide whether
/// it knows the tables an archive carries.
///
/// [_recordedFor] and [_archivedColumns] are the archived tables as they stood
/// at that archive version. When the first test fails, an archived table
/// changed: set `kSyncArchiveDbSchemaVersion` to the schema version of the
/// change, then record the new columns and that version here. Changes to
/// local-only tables, indexes or constraints leave both alone.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test(
    'archived tables still match the snapshot of the archive version',
    () async {
      final names = [
        for (final t in SyncTableRegistry(db).tables()) t.name,
        'change_log',
        'change_log_field',
      ];
      final actual = <String, Set<String>>{
        for (final name in names)
          name: {
            for (final c
                in await db.customSelect('PRAGMA table_info($name)').get())
              '${c.read<String>('name')} ${c.read<String>('type')}',
          },
      };

      expect(
        actual,
        _archivedColumns,
        reason:
            'an archived table changed its columns: move '
            'kSyncArchiveDbSchemaVersion to this schema version and record the '
            'new columns for it',
      );
      expect(
        kSyncArchiveDbSchemaVersion,
        _recordedFor,
        reason:
            'the archive version moved: record the archived columns for it '
            'in this test',
      );
    },
  );

  test('the archive version never runs ahead of the schema', () {
    expect(kSyncArchiveDbSchemaVersion, lessThanOrEqualTo(db.schemaVersion));
    expect(
      kSyncArchiveDbSchemaVersion,
      greaterThanOrEqualTo(kSyncArchiveMinImportSchemaVersion),
    );
  });
}

const int _recordedFor = 34;

const Map<String, Set<String>> _archivedColumns = {
  'users': {
    'uuid BLOB',
    'username TEXT',
    'first_name TEXT',
    'last_name TEXT',
    'details TEXT',
    'created_at INTEGER',
    'updated_at INTEGER',
    'deleted_at INTEGER',
    'created_by_user_uuid BLOB',
    'last_modified_by_user_uuid BLOB',
  },
  'surface_areas': {
    'uuid BLOB',
    'title TEXT',
    'description TEXT',
    'general_area_identifier TEXT',
    'created_at INTEGER',
    'updated_at INTEGER',
    'deleted_at INTEGER',
    'created_by_user_uuid BLOB',
    'last_modified_by_user_uuid BLOB',
  },
  'caves': {
    'uuid BLOB',
    'title TEXT',
    'description TEXT',
    'surface_area_uuid BLOB',
    'cave_local_index TEXT',
    'created_at INTEGER',
    'updated_at INTEGER',
    'deleted_at INTEGER',
    'created_by_user_uuid BLOB',
    'last_modified_by_user_uuid BLOB',
  },
  'cave_areas': {
    'uuid BLOB',
    'title TEXT',
    'description TEXT',
    'cave_uuid BLOB',
    'created_at INTEGER',
    'updated_at INTEGER',
    'deleted_at INTEGER',
    'created_by_user_uuid BLOB',
    'last_modified_by_user_uuid BLOB',
  },
  'cave_places': {
    'uuid BLOB',
    'title TEXT',
    'description TEXT',
    'cave_uuid BLOB',
    'place_code_identifier TEXT',
    'qr_code_resource_identifier TEXT',
    'cave_area_uuid BLOB',
    'latitude REAL',
    'longitude REAL',
    'altitude REAL',
    'depth_in_cave REAL',
    'is_entrance INTEGER',
    'is_main_entrance INTEGER',
    'created_at INTEGER',
    'updated_at INTEGER',
    'deleted_at INTEGER',
    'created_by_user_uuid BLOB',
    'last_modified_by_user_uuid BLOB',
  },
  'cave_place_beacons': {
    'uuid BLOB',
    'cave_place_uuid BLOB',
    'cave_uuid BLOB',
    'beacon_type TEXT',
    'proximity_uuid TEXT',
    'major INTEGER',
    'minor INTEGER',
    'mac_address TEXT',
    'local_name TEXT',
    'model TEXT',
    'measured_power INTEGER',
    'firmware_version TEXT',
    'title TEXT',
    'notes TEXT',
    'last_seen_at INTEGER',
    'last_battery_mv INTEGER',
    'last_temperature_c REAL',
    'last_humidity_pct REAL',
    'last_pressure_hpa REAL',
    'last_movement_counter INTEGER',
    'created_at INTEGER',
    'updated_at INTEGER',
    'deleted_at INTEGER',
    'created_by_user_uuid BLOB',
    'last_modified_by_user_uuid BLOB',
  },
  'raster_maps': {
    'uuid BLOB',
    'title TEXT',
    'map_type TEXT',
    'file_name TEXT',
    'file_hash TEXT',
    'file_size INTEGER',
    'order_index INTEGER',
    'cave_uuid BLOB',
    'cave_area_uuid BLOB',
    'created_at INTEGER',
    'updated_at INTEGER',
    'deleted_at INTEGER',
    'created_by_user_uuid BLOB',
    'last_modified_by_user_uuid BLOB',
  },
  'cave_place_to_raster_map_definitions': {
    'uuid BLOB',
    'x_coordinate INTEGER',
    'y_coordinate INTEGER',
    'cave_place_uuid BLOB',
    'raster_map_uuid BLOB',
    'created_at INTEGER',
    'updated_at INTEGER',
    'deleted_at INTEGER',
    'created_by_user_uuid BLOB',
    'last_modified_by_user_uuid BLOB',
  },
  'cave_trips': {
    'uuid BLOB',
    'cave_uuid BLOB',
    'title TEXT',
    'description TEXT',
    'trip_started_at INTEGER',
    'trip_ended_at INTEGER',
    'log TEXT',
    'log_stale_since INTEGER',
    'participants TEXT',
    'created_at INTEGER',
    'updated_at INTEGER',
    'deleted_at INTEGER',
    'created_by_user_uuid BLOB',
    'last_modified_by_user_uuid BLOB',
    'device_uuid BLOB',
  },
  'cave_trip_points': {
    'uuid BLOB',
    'cave_trip_uuid BLOB',
    'cave_place_uuid BLOB',
    'scanned_at INTEGER',
    'notes TEXT',
    'created_at INTEGER',
    'updated_at INTEGER',
    'deleted_at INTEGER',
    'created_by_user_uuid BLOB',
    'last_modified_by_user_uuid BLOB',
  },
  'documentation_files': {
    'uuid BLOB',
    'title TEXT',
    'description TEXT',
    'file_name TEXT',
    'file_size INTEGER',
    'file_hash TEXT',
    'file_type TEXT',
    'created_at INTEGER',
    'updated_at INTEGER',
    'deleted_at INTEGER',
    'created_by_user_uuid BLOB',
    'last_modified_by_user_uuid BLOB',
  },
  'documentation_files_to_geofeatures': {
    'uuid BLOB',
    'geofeature_uuid BLOB',
    'geofeature_type TEXT',
    'documentation_file_uuid BLOB',
    'created_at INTEGER',
    'updated_at INTEGER',
    'deleted_at INTEGER',
    'created_by_user_uuid BLOB',
    'last_modified_by_user_uuid BLOB',
  },
  'documentation_files_to_cave_trips': {
    'uuid BLOB',
    'documentation_file_uuid BLOB',
    'cave_trip_uuid BLOB',
    'created_at INTEGER',
    'deleted_at INTEGER',
    'created_by_user_uuid BLOB',
    'last_modified_by_user_uuid BLOB',
  },
  'documentation_files_to_cave_trip_points': {
    'uuid BLOB',
    'documentation_file_uuid BLOB',
    'cave_trip_point_uuid BLOB',
    'created_at INTEGER',
    'deleted_at INTEGER',
    'created_by_user_uuid BLOB',
    'last_modified_by_user_uuid BLOB',
  },
  'cave_place_model_stations': {
    'uuid BLOB',
    'cave_place_uuid BLOB',
    'cave_uuid BLOB',
    'documentation_file_uuid BLOB',
    'station TEXT',
    'splay_east REAL',
    'splay_north REAL',
    'splay_up REAL',
    'needs_review INTEGER',
    'created_at INTEGER',
    'updated_at INTEGER',
    'created_by_user_uuid BLOB',
    'last_modified_by_user_uuid BLOB',
  },
  'cave_default_survey_models': {
    'uuid BLOB',
    'cave_uuid BLOB',
    'documentation_file_uuid BLOB',
    'created_at INTEGER',
    'updated_at INTEGER',
    'created_by_user_uuid BLOB',
    'last_modified_by_user_uuid BLOB',
  },
  'trip_report_templates': {
    'uuid BLOB',
    'title TEXT',
    'file_name TEXT',
    'file_size INTEGER',
    'format TEXT',
    'created_at INTEGER',
    'updated_at INTEGER',
    'deleted_at INTEGER',
    'created_by_user_uuid BLOB',
    'last_modified_by_user_uuid BLOB',
  },
  'configurations': {
    'id INTEGER',
    'title TEXT',
    'value TEXT',
    'is_synced INTEGER',
    'created_at INTEGER',
    'updated_at INTEGER',
  },
  'change_log': {
    'uuid BLOB',
    'entity_table TEXT',
    'entity_uuid BLOB',
    'change_type INTEGER',
    'changed_at INTEGER',
    'changed_by_user_uuid BLOB',
    'device_uuid BLOB',
  },
  'change_log_field': {
    'change_uuid BLOB',
    'field_name TEXT',
    'old_value_short BLOB',
    'old_value_truncated INTEGER',
  },
};
