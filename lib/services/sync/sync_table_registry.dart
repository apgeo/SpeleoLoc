import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/sync/sync_serializer.dart';
import 'package:speleoloc/services/sync/sync_table_handler.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Owns the ordered list of synced tables and the generic per-table
/// upsert logic. Extracted from [SyncArchiveService] so the big handler
/// list lives in one place and the service body stays focused on the
/// archive/zip/manifest orchestration.
///
/// Tables are listed in FK-dependency order: parents before children.
class SyncTableRegistry {
  SyncTableRegistry(this._db);

  final AppDatabase _db;
  static const _serializer = SyncValueSerializer();
  final _log = AppLogger.of('SyncTableRegistry');

  /// Metadata columns excluded from conflict diff (audit/bookkeeping).
  static const _metaColumnsForDiff = <String>{
    'created_at',
    'updated_at',
    'deleted_at',
    'created_by_user_uuid',
    'last_modified_by_user_uuid',
  };

  static const SyncValueSerializer serializer = _serializer;

  /// All tables exported/imported by the sync archive, in FK order.
  List<SyncTableHandler> tables() => <SyncTableHandler>[
        SyncTableHandler(
          name: 'users',
          dump: () async => (await _db.select(_db.users).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows, resolver) async => upsertRows<User>(
            rows,
            (j) => User.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.users,
            resolver,
          ),
        ),
        SyncTableHandler(
          name: 'surface_areas',
          dump: () async => (await _db.select(_db.surfaceAreas).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows, resolver) async => upsertRows<SurfaceArea>(
            rows,
            (j) => SurfaceArea.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.surfaceAreas,
            resolver,
          ),
        ),
        SyncTableHandler(
          name: 'caves',
          dump: () async => (await _db.select(_db.caves).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows, resolver) async => upsertRows<Cave>(
            rows,
            (j) => Cave.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.caves,
            resolver,
          ),
        ),
        SyncTableHandler(
          name: 'cave_areas',
          dump: () async => (await _db.select(_db.caveAreas).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows, resolver) async => upsertRows<CaveArea>(
            rows,
            (j) => CaveArea.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.caveAreas,
            resolver,
          ),
        ),
        SyncTableHandler(
          name: 'cave_places',
          dump: () async => (await _db.select(_db.cavePlaces).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows, resolver) async => upsertRows<CavePlace>(
            rows,
            (j) => CavePlace.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.cavePlaces,
            resolver,
          ),
        ),
        SyncTableHandler(
          name: 'raster_maps',
          dump: () async => (await _db.select(_db.rasterMaps).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows, resolver) async => upsertRows<RasterMap>(
            rows,
            (j) => RasterMap.fromJson(
              // Older archives (schema <= v12) lack order_index.
              {'order_index': 0, ...j},
              serializer: _serializer,
            ),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.rasterMaps,
            resolver,
          ),
        ),
        SyncTableHandler(
          name: 'cave_place_to_raster_map_definitions',
          dump: () async =>
              (await _db.select(_db.cavePlaceToRasterMapDefinitions).get())
                  .map((r) => r.toJson(serializer: _serializer))
                  .toList(),
          upsert: (rows, resolver) async =>
              upsertRows<CavePlaceToRasterMapDefinition>(
            rows,
            (j) => CavePlaceToRasterMapDefinition.fromJson(
              j,
              serializer: _serializer,
            ),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.cavePlaceToRasterMapDefinitions,
            resolver,
          ),
        ),
        SyncTableHandler(
          name: 'cave_trips',
          dump: () async => (await _db.select(_db.caveTrips).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows, resolver) async => upsertRows<CaveTrip>(
            rows,
            (j) => CaveTrip.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.caveTrips,
            resolver,
          ),
        ),
        SyncTableHandler(
          name: 'cave_trip_points',
          dump: () async => (await _db.select(_db.caveTripPoints).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows, resolver) async => upsertRows<CaveTripPoint>(
            rows,
            (j) => CaveTripPoint.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.caveTripPoints,
            resolver,
          ),
        ),
        SyncTableHandler(
          name: 'documentation_files',
          dump: () async => (await _db.select(_db.documentationFiles).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows, resolver) async => upsertRows<DocumentationFile>(
            rows,
            (j) => DocumentationFile.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.documentationFiles,
            resolver,
          ),
        ),
        SyncTableHandler(
          name: 'documentation_files_to_geofeatures',
          dump: () async =>
              (await _db.select(_db.documentationFilesToGeofeatures).get())
                  .map((r) => r.toJson(serializer: _serializer))
                  .toList(),
          upsert: (rows, resolver) async =>
              upsertRows<DocumentationFilesToGeofeature>(
            rows,
            (j) => DocumentationFilesToGeofeature.fromJson(
              j,
              serializer: _serializer,
            ),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.documentationFilesToGeofeatures,
            resolver,
          ),
        ),
        SyncTableHandler(
          name: 'documentation_files_to_cave_trips',
          dump: () async =>
              (await _db.select(_db.documentationFilesToCaveTrips).get())
                  .map((r) => r.toJson(serializer: _serializer))
                  .toList(),
          upsert: (rows, resolver) async =>
              upsertRows<DocumentationFilesToCaveTrip>(
            rows,
            (j) => DocumentationFilesToCaveTrip.fromJson(
              j,
              serializer: _serializer,
            ),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            // Link table has no updated_at; LWW falls back to created_at.
            (r) => r.createdAt,
            _db.documentationFilesToCaveTrips,
            resolver,
          ),
        ),
        SyncTableHandler(
          name: 'trip_report_templates',
          dump: () async => (await _db.select(_db.tripReportTemplates).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows, resolver) async => upsertRows<TripReportTemplate>(
            rows,
            (j) => TripReportTemplate.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.tripReportTemplates,
            resolver,
          ),
        ),
      ];

  /// Generic last-writer-wins upsert with optional [resolver] callback for
  /// surfacing conflicts to the user.
  Future<UpsertCounters> upsertRows<D extends Insertable<D>>(
    List<Map<String, dynamic>> rows,
    D Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic> Function(D) toJson,
    Uuid Function(D) uuidOf,
    int? Function(D) tsOf,
    TableInfo<Table, D> table,
    ConflictResolver? resolver,
  ) async {
    var inserted = 0;
    var updated = 0;
    var skipped = 0;

    for (final raw in rows) {
      final D incoming;
      try {
        incoming = fromJson(raw);
      } catch (e) {
        _log.warning('skipping malformed ${table.actualTableName} row: $e');
        continue;
      }
      final uuid = uuidOf(incoming);
      final incomingTs = tsOf(incoming) ?? 0;

      final local = await _loadLocal<D>(table, uuid);
      if (local == null) {
        await _db.into(table).insert(incoming);
        inserted++;
        continue;
      }

      final localTs = tsOf(local) ?? 0;
      final localJson = toJson(local);
      final incomingJson = toJson(incoming);
      final diff = _diffMeaningfulFields(localJson, incomingJson);

      if (diff.isEmpty) {
        skipped++;
        continue;
      }

      var action = incomingTs > localTs
          ? SyncConflictAction.useIncoming
          : SyncConflictAction.keepLocal;

      if (resolver != null) {
        final decision = await resolver(SyncConflict(
          tableName: table.actualTableName,
          entityUuid: uuid,
          localFields: localJson,
          incomingFields: incomingJson,
          differingFields: diff,
          localUpdatedAt: localTs == 0 ? null : localTs,
          incomingUpdatedAt: incomingTs == 0 ? null : incomingTs,
        ));
        if (decision == SyncConflictAction.cancel) {
          throw const SyncImportCancelledException();
        }
        if (decision != null) action = decision;
      }

      if (action == SyncConflictAction.useIncoming) {
        await _db.into(table).insert(
              incoming,
              mode: InsertMode.insertOrReplace,
            );
        updated++;
      } else {
        skipped++;
      }
    }

    return UpsertCounters(
      inserted: inserted,
      updated: updated,
      skipped: skipped,
    );
  }

  Future<D?> _loadLocal<D>(TableInfo<Table, D> table, Uuid uuid) async {
    final row = await _db.customSelect(
      'SELECT * FROM ${table.actualTableName} WHERE uuid = ? LIMIT 1',
      variables: [Variable<Uint8List>(uuid.bytes)],
    ).getSingleOrNull();
    if (row == null) return null;
    return await table.map(row.data);
  }

  List<String> _diffMeaningfulFields(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final keys = <String>{...a.keys, ...b.keys};
    final diff = <String>[];
    for (final k in keys) {
      if (_metaColumnsForDiff.contains(k)) continue;
      if (a[k] != b[k]) diff.add(k);
    }
    return diff;
  }
}
