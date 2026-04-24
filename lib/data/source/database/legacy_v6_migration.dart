import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/uuid.dart';

/// One-time conversion from the pre-v7 integer-PK schema to the v7 UUID-PK
/// schema.
///
/// The previous schema used `INTEGER AUTOINCREMENT` primary keys and FK
/// columns like `cave_id`, `cave_place_id`, etc. The new schema uses
/// `BLOB` UUID primary keys named `uuid` and FK columns named
/// `<entity>_uuid`.
///
/// Used in three phases by [AppDatabase.migration]:
///   1. [snapshotLegacyV6]   — read every row, pre-compute `int -> Uuid`.
///   2. [dropLegacyV6Tables] — drop old tables; caller then creates new ones.
///   3. [reinsertLegacyData] — re-insert every row with UUID PKs and
///                             remapped FKs.
///
/// The `documentation_files_to_geofeatures.geofeature_id` pseudo-FK is
/// remapped based on `geofeature_type` (`cave`, `cave_place`, `cave_area`).
/// `configurations` is preserved verbatim because it keeps its INTEGER PK.

// =============================================================================
// Two-phase API (used by onUpgrade)
// =============================================================================

/// Opaque snapshot of every row in the pre-v7 database plus the
/// `int -> Uuid` maps for every table. Consumed by [reinsertLegacyData].
class LegacyV6Snapshot {
  LegacyV6Snapshot._({
    required this.surfaceAreas,
    required this.caves,
    required this.caveAreas,
    required this.cavePlaces,
    required this.rasterMaps,
    required this.cavePlaceDefs,
    required this.documentationFiles,
    required this.docToGeo,
    required this.caveTrips,
    required this.caveTripPoints,
    required this.docToTrips,
    required this.tripReportTemplates,
    required this.surfacePlaces,
    required this.caveEntrances,
    required this.configurations,
    required this.surfaceAreaMap,
    required this.caveMap,
    required this.caveAreaMap,
    required this.cavePlaceMap,
    required this.rasterMapMap,
    required this.cavePlaceDefMap,
    required this.documentationFileMap,
    required this.docToGeoMap,
    required this.caveTripMap,
    required this.caveTripPointMap,
    required this.docToTripMap,
    required this.tripReportTemplateMap,
    required this.surfacePlaceMap,
    required this.caveEntranceMap,
  });

  final List<Map<String, Object?>> surfaceAreas;
  final List<Map<String, Object?>> caves;
  final List<Map<String, Object?>> caveAreas;
  final List<Map<String, Object?>> cavePlaces;
  final List<Map<String, Object?>> rasterMaps;
  final List<Map<String, Object?>> cavePlaceDefs;
  final List<Map<String, Object?>> documentationFiles;
  final List<Map<String, Object?>> docToGeo;
  final List<Map<String, Object?>> caveTrips;
  final List<Map<String, Object?>> caveTripPoints;
  final List<Map<String, Object?>> docToTrips;
  final List<Map<String, Object?>> tripReportTemplates;
  final List<Map<String, Object?>> surfacePlaces;
  final List<Map<String, Object?>> caveEntrances;
  final List<Map<String, Object?>> configurations;

  final Map<int, Uuid> surfaceAreaMap;
  final Map<int, Uuid> caveMap;
  final Map<int, Uuid> caveAreaMap;
  final Map<int, Uuid> cavePlaceMap;
  final Map<int, Uuid> rasterMapMap;
  final Map<int, Uuid> cavePlaceDefMap;
  final Map<int, Uuid> documentationFileMap;
  final Map<int, Uuid> docToGeoMap;
  final Map<int, Uuid> caveTripMap;
  final Map<int, Uuid> caveTripPointMap;
  final Map<int, Uuid> docToTripMap;
  final Map<int, Uuid> tripReportTemplateMap;
  final Map<int, Uuid> surfacePlaceMap;
  final Map<int, Uuid> caveEntranceMap;

  int get totalRows =>
      surfaceAreas.length +
      caves.length +
      caveAreas.length +
      cavePlaces.length +
      rasterMaps.length +
      cavePlaceDefs.length +
      documentationFiles.length +
      docToGeo.length +
      caveTrips.length +
      caveTripPoints.length +
      docToTrips.length +
      tripReportTemplates.length +
      surfacePlaces.length +
      caveEntrances.length +
      configurations.length;
}

/// Phase 1: read all rows from the legacy (int-PK) schema and pre-compute
/// `int -> Uuid` maps.
Future<LegacyV6Snapshot> snapshotLegacyV6(DatabaseConnectionUser db) async {
  final log = AppLogger.of('LegacyV6Migration');
  log.info('Phase 1: snapshotting pre-v7 tables …');

  final surfaceAreas = await _readAll(db, 'surface_areas');
  final caves = await _readAll(db, 'caves');
  final caveAreas = await _readAll(db, 'cave_areas');
  final cavePlaces = await _readAll(db, 'cave_places');
  final rasterMaps = await _readAll(db, 'raster_maps');
  final cavePlaceDefs =
      await _readAll(db, 'cave_place_to_raster_map_definitions');
  final documentationFiles = await _readAll(db, 'documentation_files');
  final docToGeo = await _readAll(db, 'documentation_files_to_geofeatures');
  final caveTrips = await _readAll(db, 'cave_trips');
  final caveTripPoints = await _readAll(db, 'cave_trip_points');
  final docToTrips = await _readAll(db, 'documentation_files_to_cave_trips');
  final tripReportTemplates = await _readAll(db, 'trip_report_templates');
  final surfacePlaces = await _readAll(db, 'surface_places');
  final caveEntrances = await _readAll(db, 'cave_entrances');
  final configurations = await _readAll(db, 'configurations');

  Map<int, Uuid> mk(List<Map<String, Object?>> rows) => {
        for (final r in rows) (r['id'] as int): Uuid.v7(),
      };

  final snap = LegacyV6Snapshot._(
    surfaceAreas: surfaceAreas,
    caves: caves,
    caveAreas: caveAreas,
    cavePlaces: cavePlaces,
    rasterMaps: rasterMaps,
    cavePlaceDefs: cavePlaceDefs,
    documentationFiles: documentationFiles,
    docToGeo: docToGeo,
    caveTrips: caveTrips,
    caveTripPoints: caveTripPoints,
    docToTrips: docToTrips,
    tripReportTemplates: tripReportTemplates,
    surfacePlaces: surfacePlaces,
    caveEntrances: caveEntrances,
    configurations: configurations,
    surfaceAreaMap: mk(surfaceAreas),
    caveMap: mk(caves),
    caveAreaMap: mk(caveAreas),
    cavePlaceMap: mk(cavePlaces),
    rasterMapMap: mk(rasterMaps),
    cavePlaceDefMap: mk(cavePlaceDefs),
    documentationFileMap: mk(documentationFiles),
    docToGeoMap: mk(docToGeo),
    caveTripMap: mk(caveTrips),
    caveTripPointMap: mk(caveTripPoints),
    docToTripMap: mk(docToTrips),
    tripReportTemplateMap: mk(tripReportTemplates),
    surfacePlaceMap: mk(surfacePlaces),
    caveEntranceMap: mk(caveEntrances),
  );

  log.info('Snapshot complete: ${snap.totalRows} rows.');
  return snap;
}

/// Phase 2: drop all pre-v7 tables. Caller must then run
/// `migrator.createAll()` so the new UUID-PK tables exist before phase 3.
Future<void> dropLegacyV6Tables(DatabaseConnectionUser db) async {
  const tablesToDrop = [
    'documentation_files_to_cave_trips',
    'documentation_files_to_geofeatures',
    'cave_trip_points',
    'cave_trips',
    'cave_place_to_raster_map_definitions',
    'trip_report_templates',
    'cave_entrances',
    'cave_places',
    'raster_maps',
    'cave_areas',
    'caves',
    'surface_places',
    'surface_areas',
    'documentation_files',
    'configurations',
  ];
  await db.customStatement('PRAGMA foreign_keys = OFF');
  for (final t in tablesToDrop) {
    await db.customStatement('DROP TABLE IF EXISTS $t');
  }
}

/// Phase 3: re-insert every row from the snapshot into the freshly-created
/// v7 tables, remapping integer FKs via the snapshot's `int -> Uuid` maps.
Future<void> reinsertLegacyData(
  DatabaseConnectionUser db,
  LegacyV6Snapshot snap,
) async {
  final log = AppLogger.of('LegacyV6Migration');
  log.info('Phase 3: re-inserting legacy rows into v7 schema …');

  // Disable FK checks during bulk insert so row ordering within a table
  // (e.g. self-referencing orderings, if any) never trips a constraint.
  // createAll() re-enables; we toggle explicitly for clarity.
  await db.customStatement('PRAGMA foreign_keys = OFF');

  // ---- surface_areas ----
  for (final r in snap.surfaceAreas) {
    await db.customInsert(
      'INSERT INTO surface_areas '
      '(uuid, title, description, created_at, updated_at, deleted_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<Uint8List>(snap.surfaceAreaMap[r['id']]!.bytes),
        Variable<String>(r['title'] as String),
        Variable<String>(r['description'] as String?),
        Variable<int>(r['created_at'] as int?),
        Variable<int>(r['updated_at'] as int?),
        Variable<int>(r['deleted_at'] as int?),
      ],
    );
  }

  // ---- caves ----
  for (final r in snap.caves) {
    await db.customInsert(
      'INSERT INTO caves '
      '(uuid, title, description, surface_area_uuid, created_at, updated_at, deleted_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<Uint8List>(snap.caveMap[r['id']]!.bytes),
        Variable<String>(r['title'] as String),
        Variable<String>(r['description'] as String?),
        Variable<Uint8List>(_fkBytes(r['surface_area_id'], snap.surfaceAreaMap)),
        Variable<int>(r['created_at'] as int?),
        Variable<int>(r['updated_at'] as int?),
        Variable<int>(r['deleted_at'] as int?),
      ],
    );
  }

  // ---- cave_areas ----
  for (final r in snap.caveAreas) {
    await db.customInsert(
      'INSERT INTO cave_areas '
      '(uuid, title, description, cave_uuid, created_at, updated_at, deleted_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<Uint8List>(snap.caveAreaMap[r['id']]!.bytes),
        Variable<String>(r['title'] as String),
        Variable<String>(r['description'] as String?),
        Variable<Uint8List>(snap.caveMap[r['cave_id']]!.bytes),
        Variable<int>(r['created_at'] as int?),
        Variable<int>(r['updated_at'] as int?),
        Variable<int>(r['deleted_at'] as int?),
      ],
    );
  }

  // ---- cave_places ----
  for (final r in snap.cavePlaces) {
    await db.customInsert(
      'INSERT INTO cave_places '
      '(uuid, title, description, cave_uuid, place_qr_code_identifier, '
      'cave_area_uuid, latitude, longitude, depth_in_cave, is_entrance, '
      'is_main_entrance, created_at, updated_at, deleted_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<Uint8List>(snap.cavePlaceMap[r['id']]!.bytes),
        Variable<String>(r['title'] as String),
        Variable<String>(r['description'] as String?),
        Variable<Uint8List>(snap.caveMap[r['cave_id']]!.bytes),
        Variable<int>(r['place_qr_code_identifier'] as int?),
        Variable<Uint8List>(_fkBytes(r['cave_area_id'], snap.caveAreaMap)),
        Variable<double>(_asDouble(r['latitude'])),
        Variable<double>(_asDouble(r['longitude'])),
        Variable<double>(_asDouble(r['depth_in_cave'])),
        Variable<int>((r['is_entrance'] as int?) ?? 0),
        Variable<int>((r['is_main_entrance'] as int?) ?? 0),
        Variable<int>(r['created_at'] as int?),
        Variable<int>(r['updated_at'] as int?),
        Variable<int>(r['deleted_at'] as int?),
      ],
    );
  }

  // ---- raster_maps ----
  // v6 had no UNIQUE constraint on (file_name, map_type, cave_id) or
  // (title, map_type, cave_id); v7 does. Disambiguate duplicates by
  // appending the legacy int id so all rows survive the migration.
  final rasterSeenFile = <String>{};
  final rasterSeenTitle = <String>{};
  for (final r in snap.rasterMaps) {
    final legacyId = r['id'] as int;
    final mapType = r['map_type'] as String;
    final caveId = r['cave_id'];
    var title = r['title'] as String;
    var fileName = r['file_name'] as String;
    final fileKey = '$fileName|$mapType|$caveId';
    if (!rasterSeenFile.add(fileKey)) {
      fileName = '$fileName.dup$legacyId';
    }
    final titleKey = '$title|$mapType|$caveId';
    if (!rasterSeenTitle.add(titleKey)) {
      title = '$title (dup $legacyId)';
    }
    await db.customInsert(
      'INSERT INTO raster_maps '
      '(uuid, title, map_type, file_name, cave_uuid, cave_area_uuid, '
      'created_at, updated_at, deleted_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<Uint8List>(snap.rasterMapMap[legacyId]!.bytes),
        Variable<String>(title),
        Variable<String>(mapType),
        Variable<String>(fileName),
        Variable<Uint8List>(snap.caveMap[caveId]!.bytes),
        Variable<Uint8List>(_fkBytes(r['cave_area_id'], snap.caveAreaMap)),
        Variable<int>(r['created_at'] as int?),
        Variable<int>(r['updated_at'] as int?),
        Variable<int>(r['deleted_at'] as int?),
      ],
    );
  }

  // ---- cave_place_to_raster_map_definitions ----
  for (final r in snap.cavePlaceDefs) {
    await db.customInsert(
      'INSERT INTO cave_place_to_raster_map_definitions '
      '(uuid, x_coordinate, y_coordinate, cave_place_uuid, raster_map_uuid, '
      'created_at, updated_at, deleted_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<Uint8List>(snap.cavePlaceDefMap[r['id']]!.bytes),
        Variable<int>(r['x_coordinate'] as int?),
        Variable<int>(r['y_coordinate'] as int?),
        Variable<Uint8List>(snap.cavePlaceMap[r['cave_place_id']]!.bytes),
        Variable<Uint8List>(snap.rasterMapMap[r['raster_map_id']]!.bytes),
        Variable<int>(r['created_at'] as int?),
        Variable<int>(r['updated_at'] as int?),
        Variable<int>(r['deleted_at'] as int?),
      ],
    );
  }

  // ---- documentation_files ----
  for (final r in snap.documentationFiles) {
    await db.customInsert(
      'INSERT INTO documentation_files '
      '(uuid, title, description, file_name, file_size, file_hash, file_type, '
      'created_at, updated_at, deleted_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<Uint8List>(snap.documentationFileMap[r['id']]!.bytes),
        Variable<String>(r['title'] as String),
        Variable<String>(r['description'] as String?),
        Variable<String>(r['file_name'] as String),
        Variable<int>(r['file_size'] as int),
        Variable<String>(r['file_hash'] as String?),
        Variable<String>(r['file_type'] as String),
        Variable<int>(r['created_at'] as int?),
        Variable<int>(r['updated_at'] as int?),
        Variable<int>(r['deleted_at'] as int?),
      ],
    );
  }

  // ---- documentation_files_to_geofeatures ----
  // Pseudo-FK: geofeature_id resolves against the map matching geofeature_type.
  for (final r in snap.docToGeo) {
    final geoType = r['geofeature_type'] as String?;
    final geoId = r['geofeature_id'] as int?;
    Uint8List? geoUuidBytes;
    if (geoId != null && geoType != null) {
      switch (geoType) {
        case 'cave':
          geoUuidBytes = snap.caveMap[geoId]?.bytes;
          break;
        case 'cave_place':
          geoUuidBytes = snap.cavePlaceMap[geoId]?.bytes;
          break;
        case 'cave_area':
          geoUuidBytes = snap.caveAreaMap[geoId]?.bytes;
          break;
      }
    }
    await db.customInsert(
      'INSERT INTO documentation_files_to_geofeatures '
      '(uuid, geofeature_uuid, geofeature_type, documentation_file_uuid, '
      'updated_at, deleted_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<Uint8List>(snap.docToGeoMap[r['id']]!.bytes),
        Variable<Uint8List>(geoUuidBytes),
        Variable<String>(geoType ?? ''),
        Variable<Uint8List>(
            snap.documentationFileMap[r['documentation_file_id']]!.bytes),
        Variable<int>(r['updated_at'] as int?),
        Variable<int>(r['deleted_at'] as int?),
      ],
    );
  }

  // ---- cave_trips ----
  for (final r in snap.caveTrips) {
    await db.customInsert(
      'INSERT INTO cave_trips '
      '(uuid, cave_uuid, title, description, trip_started_at, trip_ended_at, '
      'log, created_at, updated_at, deleted_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<Uint8List>(snap.caveTripMap[r['id']]!.bytes),
        Variable<Uint8List>(snap.caveMap[r['cave_id']]!.bytes),
        Variable<String>(r['title'] as String),
        Variable<String>(r['description'] as String?),
        Variable<int>(r['trip_started_at'] as int),
        Variable<int>(r['trip_ended_at'] as int?),
        Variable<String>(r['log'] as String?),
        Variable<int>(r['created_at'] as int?),
        Variable<int>(r['updated_at'] as int?),
        Variable<int>(r['deleted_at'] as int?),
      ],
    );
  }

  // ---- cave_trip_points ----
  for (final r in snap.caveTripPoints) {
    await db.customInsert(
      'INSERT INTO cave_trip_points '
      '(uuid, cave_trip_uuid, cave_place_uuid, scanned_at, notes, '
      'created_at, updated_at, deleted_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<Uint8List>(snap.caveTripPointMap[r['id']]!.bytes),
        Variable<Uint8List>(snap.caveTripMap[r['cave_trip_id']]!.bytes),
        Variable<Uint8List>(_fkBytes(r['cave_place_id'], snap.cavePlaceMap)),
        Variable<int>(r['scanned_at'] as int),
        Variable<String>(r['notes'] as String?),
        Variable<int>(r['created_at'] as int?),
        Variable<int>(r['updated_at'] as int?),
        Variable<int>(r['deleted_at'] as int?),
      ],
    );
  }

  // ---- documentation_files_to_cave_trips ----
  for (final r in snap.docToTrips) {
    await db.customInsert(
      'INSERT INTO documentation_files_to_cave_trips '
      '(uuid, documentation_file_uuid, cave_trip_uuid, created_at, deleted_at) '
      'VALUES (?, ?, ?, ?, ?)',
      variables: [
        Variable<Uint8List>(snap.docToTripMap[r['id']]!.bytes),
        Variable<Uint8List>(
            snap.documentationFileMap[r['documentation_file_id']]!.bytes),
        Variable<Uint8List>(snap.caveTripMap[r['cave_trip_id']]!.bytes),
        Variable<int>(r['created_at'] as int?),
        Variable<int>(r['deleted_at'] as int?),
      ],
    );
  }

  // ---- trip_report_templates ----
  for (final r in snap.tripReportTemplates) {
    await db.customInsert(
      'INSERT INTO trip_report_templates '
      '(uuid, title, file_name, file_size, format, created_at, updated_at, deleted_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<Uint8List>(snap.tripReportTemplateMap[r['id']]!.bytes),
        Variable<String>(r['title'] as String),
        Variable<String>(r['file_name'] as String),
        Variable<int>(r['file_size'] as int),
        Variable<String>(r['format'] as String),
        Variable<int>(r['created_at'] as int?),
        Variable<int>(r['updated_at'] as int?),
        Variable<int>(r['deleted_at'] as int?),
      ],
    );
  }

  // ---- surface_places (not used, but preserve if present) ----
  for (final r in snap.surfacePlaces) {
    await db.customInsert(
      'INSERT INTO surface_places '
      '(uuid, title, description, type, surface_place_qr_code_identifier, '
      'latitude, longitude, created_at, updated_at, deleted_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<Uint8List>(snap.surfacePlaceMap[r['id']]!.bytes),
        Variable<String>(r['title'] as String),
        Variable<String>(r['description'] as String?),
        Variable<String>(r['type'] as String?),
        Variable<int>(r['surface_place_qr_code_identifier'] as int?),
        Variable<double>(_asDouble(r['latitude'])),
        Variable<double>(_asDouble(r['longitude'])),
        Variable<int>(r['created_at'] as int?),
        Variable<int>(r['updated_at'] as int?),
        Variable<int>(r['deleted_at'] as int?),
      ],
    );
  }

  // ---- cave_entrances (not used, but preserve if present) ----
  for (final r in snap.caveEntrances) {
    await db.customInsert(
      'INSERT INTO cave_entrances '
      '(uuid, cave_uuid, surface_place_uuid, is_main_entrance, title, '
      'created_at, updated_at, deleted_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<Uint8List>(snap.caveEntranceMap[r['id']]!.bytes),
        Variable<Uint8List>(snap.caveMap[r['cave_id']]!.bytes),
        Variable<Uint8List>(
            _fkBytes(r['surface_place_id'], snap.surfacePlaceMap)),
        Variable<int>(r['is_main_entrance'] as int?),
        Variable<String>(r['title'] as String?),
        Variable<int>(r['created_at'] as int?),
        Variable<int>(r['updated_at'] as int?),
        Variable<int>(r['deleted_at'] as int?),
      ],
    );
  }

  // ---- configurations (keeps INTEGER PK) ----
  for (final r in snap.configurations) {
    await db.customInsert(
      'INSERT INTO configurations '
      '(id, title, value, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?)',
      variables: [
        Variable<int>(r['id'] as int),
        Variable<String>(r['title'] as String),
        Variable<String>(r['value'] as String?),
        Variable<int>(r['created_at'] as int?),
        Variable<int>(r['updated_at'] as int?),
      ],
    );
  }

  await db.customStatement('PRAGMA foreign_keys = ON');
  log.info('Phase 3 complete: ${snap.totalRows} rows inserted.');
}

// =============================================================================
// helpers
// =============================================================================

Future<List<Map<String, Object?>>> _readAll(
  DatabaseConnectionUser db,
  String table,
) async {
  // If the table doesn't exist (e.g. old DB predates trip_report_templates),
  // return an empty list instead of throwing.
  final exists = await db.customSelect(
    "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
    variables: [Variable<String>(table)],
  ).get();
  if (exists.isEmpty) return const [];
  final rows = await db.customSelect('SELECT * FROM $table').get();
  return rows.map((r) => r.data).toList();
}

Uint8List? _fkBytes(Object? intId, Map<int, Uuid> map) {
  if (intId == null) return null;
  return map[intId as int]?.bytes;
}

double? _asDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
