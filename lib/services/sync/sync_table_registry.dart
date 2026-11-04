import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_map_picture_copies.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/sync/sync_serializer.dart';
import 'package:speleoloc/services/sync/sync_row_merger.dart';
import 'package:speleoloc/services/sync/sync_table_handler.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Owns the ordered list of synced tables: how each is dumped into an
/// archive, and which [SyncRowMerger] call merges its rows back. Extracted
/// from [SyncArchiveService] so the big handler list lives in one place.
///
/// Tables are listed in FK-dependency order: parents before children.
class SyncTableRegistry {
  SyncTableRegistry(this._db);

  final AppDatabase _db;
  static const _serializer = SyncValueSerializer();
  final _log = AppLogger.of('SyncTableRegistry');

  /// The one synced table keyed by title rather than by uuid.
  static const configurationsTable = 'configurations';

  static const SyncValueSerializer serializer = _serializer;

  /// Documentation files that are server copies other than the file itself —
  /// a picture without its location, or one the server drew. They stay on the
  /// device that fetched them: another device gets the file from the server,
  /// or not at all, and a copy that travelled could stand in for the original
  /// there. Read from the database being dumped, which is the one that knows.
  Future<Set<Uuid>> _serverOnlyCopies() =>
      SilexgisFileCopyRepository(_db).serverOnlyCopies();

  /// Raster maps showing such a copy of their picture. They stay on the device
  /// with their pins, for the same reason; a map made here, or received as the
  /// original, travels.
  Future<Set<Uuid>> _serverOnlyMaps() async =>
      (await SilexgisMapPictureCopies(_db).serverOnlyPictures()).keys.toSet();

  /// All tables exported/imported by the sync archive, in FK order.
  List<SyncTableHandler> tables() => <SyncTableHandler>[
    SyncTableHandler(
      name: 'users',
      dump: () async => (await _db.select(_db.users).get())
          .map((r) => r.toJson(serializer: _serializer))
          .toList(),
      upsert: (rows, resolver, merger) async => merger.upsertRows<User>(
        rows,
        (j) => User.fromJson(j, serializer: _serializer),
        (r) => r.toJson(serializer: _serializer),
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
      upsert: (rows, resolver, merger) async => merger.upsertRows<SurfaceArea>(
        rows,
        (j) => SurfaceArea.fromJson(j, serializer: _serializer),
        (r) => r.toJson(serializer: _serializer),
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
      upsert: (rows, resolver, merger) async => merger.upsertRows<Cave>(
        rows,
        (j) => Cave.fromJson(j, serializer: _serializer),
        (r) => r.toJson(serializer: _serializer),
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
      upsert: (rows, resolver, merger) async => merger.upsertRows<CaveArea>(
        rows,
        (j) => CaveArea.fromJson(j, serializer: _serializer),
        (r) => r.toJson(serializer: _serializer),
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
      upsert: (rows, resolver, merger) async => merger.upsertRows<CavePlace>(
        rows,
        (j) => CavePlace.fromJson(j, serializer: _serializer),
        (r) => r.toJson(serializer: _serializer),
        (r) => r.updatedAt ?? r.createdAt,
        _db.cavePlaces,
        resolver,
      ),
    ),
    SyncTableHandler(
      name: 'cave_place_beacons',
      dump: () async => (await _db.select(_db.cavePlaceBeacons).get())
          .map((r) => r.toJson(serializer: _serializer))
          .toList(),
      upsert: (rows, resolver, merger) async =>
          merger.upsertRows<CavePlaceBeacon>(
            rows,
            // Older archives (schema <= v15) lack beacon_type.
            (j) => CavePlaceBeacon.fromJson({
              'beacon_type': 'ibeacon',
              ...j,
            }, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.updatedAt ?? r.createdAt,
            _db.cavePlaceBeacons,
            resolver,
          ),
    ),
    SyncTableHandler(
      name: 'raster_maps',
      dump: () async {
        final local = await _serverOnlyMaps();
        return (await _db.select(_db.rasterMaps).get())
            .where((r) => !local.contains(r.uuid))
            .map((r) => r.toJson(serializer: _serializer))
            .toList();
      },
      upsert: (rows, resolver, merger) async => merger.upsertRows<RasterMap>(
        rows,
        (j) => RasterMap.fromJson(
          // Older archives (schema <= v12) lack order_index.
          {'order_index': 0, ...j},
          serializer: _serializer,
        ),
        (r) => r.toJson(serializer: _serializer),
        (r) => r.updatedAt ?? r.createdAt,
        _db.rasterMaps,
        resolver,
      ),
    ),
    SyncTableHandler(
      name: 'cave_place_to_raster_map_definitions',
      dump: () async {
        final local = await _serverOnlyMaps();
        return (await _db.select(_db.cavePlaceToRasterMapDefinitions).get())
            .where((r) => !local.contains(r.rasterMapUuid))
            .map((r) => r.toJson(serializer: _serializer))
            .toList();
      },
      upsert: (rows, resolver, merger) async =>
          merger.upsertRows<CavePlaceToRasterMapDefinition>(
            rows,
            (j) => CavePlaceToRasterMapDefinition.fromJson(
              j,
              serializer: _serializer,
            ),
            (r) => r.toJson(serializer: _serializer),
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
      upsert: (rows, resolver, merger) async => merger.upsertRows<CaveTrip>(
        rows,
        (j) => CaveTrip.fromJson(j, serializer: _serializer),
        (r) => r.toJson(serializer: _serializer),
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
      upsert: (rows, resolver, merger) async =>
          merger.upsertRows<CaveTripPoint>(
            rows,
            (j) => CaveTripPoint.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.updatedAt ?? r.createdAt,
            _db.caveTripPoints,
            resolver,
          ),
    ),
    SyncTableHandler(
      name: 'documentation_files',
      dump: () async {
        final local = await _serverOnlyCopies();
        return (await _db.select(_db.documentationFiles).get())
            .where((r) => !local.contains(r.uuid))
            .map((r) => r.toJson(serializer: _serializer))
            .toList();
      },
      upsert: (rows, resolver, merger) async =>
          merger.upsertRows<DocumentationFile>(
            rows,
            (j) => DocumentationFile.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.updatedAt ?? r.createdAt,
            _db.documentationFiles,
            resolver,
          ),
    ),
    SyncTableHandler(
      name: 'documentation_files_to_geofeatures',
      dump: () async {
        final local = await _serverOnlyCopies();
        return (await _db.select(_db.documentationFilesToGeofeatures).get())
            .where((r) => !local.contains(r.documentationFileUuid))
            .map((r) => r.toJson(serializer: _serializer))
            .toList();
      },
      upsert: (rows, resolver, merger) async =>
          merger.upsertRows<DocumentationFilesToGeofeature>(
            rows,
            (j) => DocumentationFilesToGeofeature.fromJson(
              j,
              serializer: _serializer,
            ),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.updatedAt ?? r.createdAt,
            _db.documentationFilesToGeofeatures,
            resolver,
          ),
    ),
    SyncTableHandler(
      name: 'documentation_files_to_cave_trips',
      dump: () async {
        final local = await _serverOnlyCopies();
        return (await _db.select(_db.documentationFilesToCaveTrips).get())
            .where((r) => !local.contains(r.documentationFileUuid))
            .map((r) => r.toJson(serializer: _serializer))
            .toList();
      },
      upsert: (rows, resolver, merger) async =>
          merger.upsertRows<DocumentationFilesToCaveTrip>(
            rows,
            (j) => DocumentationFilesToCaveTrip.fromJson(
              j,
              serializer: _serializer,
            ),
            (r) => r.toJson(serializer: _serializer),
            // Link table has no updated_at; LWW falls back to created_at.
            (r) => r.createdAt,
            _db.documentationFilesToCaveTrips,
            resolver,
          ),
    ),
    SyncTableHandler(
      name: 'documentation_files_to_cave_trip_points',
      dump: () async {
        final local = await _serverOnlyCopies();
        return (await _db.select(_db.documentationFilesToCaveTripPoints).get())
            .where((r) => !local.contains(r.documentationFileUuid))
            .map((r) => r.toJson(serializer: _serializer))
            .toList();
      },
      upsert: (rows, resolver, merger) async =>
          merger.upsertRows<DocumentationFilesToCaveTripPoint>(
            rows,
            (j) => DocumentationFilesToCaveTripPoint.fromJson(
              j,
              serializer: _serializer,
            ),
            (r) => r.toJson(serializer: _serializer),
            // Link table has no updated_at; LWW falls back to created_at.
            (r) => r.createdAt,
            _db.documentationFilesToCaveTripPoints,
            resolver,
          ),
    ),
    SyncTableHandler(
      name: 'cave_place_model_stations',
      dump: () async => (await _db.select(_db.cavePlaceModelStations).get())
          .map((r) => r.toJson(serializer: _serializer))
          .toList(),
      upsert: (rows, resolver, merger) async =>
          merger.upsertRows<CavePlaceModelStation>(
            rows,
            (j) => CavePlaceModelStation.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.updatedAt ?? r.createdAt,
            _db.cavePlaceModelStations,
            resolver,
          ),
    ),
    SyncTableHandler(
      name: 'cave_default_survey_models',
      dump: () async => (await _db.select(_db.caveDefaultSurveyModels).get())
          .map((r) => r.toJson(serializer: _serializer))
          .toList(),
      upsert: (rows, resolver, merger) async =>
          merger.upsertRows<CaveDefaultSurveyModel>(
            rows,
            (j) => CaveDefaultSurveyModel.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.updatedAt ?? r.createdAt,
            _db.caveDefaultSurveyModels,
            resolver,
          ),
    ),
    SyncTableHandler(
      name: 'trip_report_templates',
      dump: () async => (await _db.select(_db.tripReportTemplates).get())
          .map((r) => r.toJson(serializer: _serializer))
          .toList(),
      upsert: (rows, resolver, merger) async =>
          merger.upsertRows<TripReportTemplate>(
            rows,
            (j) => TripReportTemplate.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.updatedAt ?? r.createdAt,
            _db.tripReportTemplates,
            resolver,
          ),
    ),
    // `configurations` is the one syncable table with an INTEGER primary key
    // and no uuid/audit columns, so it can't use the generic uuid-keyed
    // upsert. Only the keys in [ConfigKey.synced] (the place-code strategy
    // and QCRI settings) travel, on both export and import; a local
    // `is_synced = 1` on any other key may have come from an older, unfiltered
    // import, so the flag alone is not trusted. Keyed on the `title` UNIQUE,
    // plain last-writer-wins on updated_at — a config setting is a "latest
    // wins" value, so it is not routed through the resolver.
    SyncTableHandler(
      name: configurationsTable,
      dump: () async {
        final rows = await _db
            .customSelect(
              'SELECT title, value, is_synced, created_at, updated_at '
              'FROM configurations WHERE is_synced = 1',
            )
            .get();
        return rows
            .where((r) => ConfigKey.synced.contains(r.data['title']))
            .map((r) => Map<String, dynamic>.from(r.data))
            .toList();
      },
      upsert: (rows, _, _) => _upsertConfigurations(rows),
    ),
  ];

  /// Title-keyed LWW merge for the syncable `configurations` rows. Ignores
  /// any incoming row whose title is not in [ConfigKey.synced], whatever its
  /// `is_synced` says, so a malformed or hostile archive can neither rewrite
  /// a device-only key nor flip one into the synced set.
  Future<UpsertCounters> _upsertConfigurations(
    List<Map<String, dynamic>> rows,
  ) async {
    var inserted = 0;
    var updated = 0;
    var skipped = 0;

    for (final row in rows) {
      final title = row['title'];
      if (title is! String || !ConfigKey.synced.contains(title)) {
        _log.warning('ignoring incoming configuration row for "$title"');
        skipped++;
        continue;
      }
      final incomingValue = row['value'] as String?;
      final incomingTs =
          (row['updated_at'] as int?) ?? (row['created_at'] as int?) ?? 0;

      final local = await _db
          .customSelect(
            'SELECT value, created_at, updated_at FROM configurations '
            'WHERE title = ? LIMIT 1',
            variables: [Variable<String>(title)],
          )
          .getSingleOrNull();

      if (local == null) {
        await _db.customStatement(
          'INSERT INTO configurations '
          '(title, value, is_synced, created_at, updated_at) '
          'VALUES (?, ?, 1, ?, ?)',
          [title, incomingValue, row['created_at'], row['updated_at']],
        );
        inserted++;
        continue;
      }

      final localValue = local.data['value'] as String?;
      final localTs =
          (local.data['updated_at'] as int?) ??
          (local.data['created_at'] as int?) ??
          0;
      if (localValue == incomingValue) {
        skipped++;
      } else if (incomingTs > localTs) {
        await _db.customStatement(
          'UPDATE configurations SET value = ?, is_synced = 1, updated_at = ? '
          'WHERE title = ?',
          [incomingValue, row['updated_at'], title],
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
}
