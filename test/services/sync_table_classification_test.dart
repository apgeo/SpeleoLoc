import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/sync/sync_table_registry.dart';

/// Tables kept on this device on purpose: caches, the change log, sync
/// bookkeeping and the SilexGIS mirror. Everything else must travel in an
/// archive.
const _localOnlyTables = <String>{
  // Legacy tables no repository writes any more.
  'cave_entrances',
  'surface_places',
  // Caches and sensor logs rebuilt on the device.
  'media_qr_scan_cache',
  'ruuvi_sensor_history',
  // Change tracking and archive bookkeeping.
  'change_log',
  'change_log_field',
  'archive_held_row',
  // The SilexGIS mirror and its bookkeeping.
  'silexgis_sync_state',
  'silexgis_row_revision',
  'silexgis_stream_cursor',
  'silexgis_deferred_row',
  'silexgis_upload_attempt',
  'silexgis_held_row',
  'silexgis_person',
  'silexgis_person_link',
  'silexgis_document',
  'silexgis_document_link',
  'silexgis_file_copy',
  'silexgis_staged_upload',
  'silexgis_server_link',
  'silexgis_trip_entry',
  'silexgis_raster_entry',
  'silexgis_survey_model',
};

/// A new table has to be decided about: either it joins the archive sync or
/// it is listed above. Left unclassified it would silently never reach the
/// other phones.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('every table is either synced or listed as kept on the device', () {
    final synced = SyncTableRegistry(db).tables().map((t) => t.name).toSet();
    final all = db.allTables.map((t) => t.actualTableName).toSet();

    expect(
      all.difference(synced).difference(_localOnlyTables),
      isEmpty,
      reason: 'tables neither synced nor listed as local-only',
    );
  });

  test('no table is both synced and local-only', () {
    final synced = SyncTableRegistry(db).tables().map((t) => t.name).toSet();
    expect(synced.intersection(_localOnlyTables), isEmpty);
  });

  test('the local-only list names no table that no longer exists', () {
    final all = db.allTables.map((t) => t.actualTableName).toSet();
    expect(_localOnlyTables.difference(all), isEmpty);
  });

  test('every synced table exists in the database', () {
    final all = db.allTables.map((t) => t.actualTableName).toSet();
    final synced = SyncTableRegistry(db).tables().map((t) => t.name).toSet();
    expect(synced.difference(all), isEmpty);
  });
}
