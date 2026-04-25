import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/utils/app_exceptions.dart';
import 'package:speleoloc/utils/app_logger.dart';

class RasterMapRepository implements IRasterMapRepository {
  final AppDatabase _database;
  final CurrentUserService _currentUser;
  final ChangeLogger _logger;
  final _log = AppLogger.of('RasterMapRepository');

  RasterMapRepository(this._database, this._currentUser, this._logger);

  @override
  Future<List<RasterMap>> getRasterMaps(Uuid caveUuid) async {
    try {
      return await (_database.select(_database.rasterMaps)..where((rm) => rm.caveUuid.equalsValue(caveUuid))).get();
    } catch (e, st) {
      _log.severe('Failed to load raster maps', e, st);
      throw DbException('Failed to load raster maps', cause: e, stackTrace: st);
    }
  }

  @override
  Future<List<CavePlaceWithDefinition>> getCavePlacesWithDefinitionsForRasterMap(Uuid caveUuid, Uuid rasterMapUuid) async {
    try {
      return await _database.getCavePlacesWithDefinitionsForRasterMap(caveUuid, rasterMapUuid);
    } catch (e, st) {
      _log.severe('Failed to load definitions', e, st);
      throw DbException('Failed to load definitions', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> addRasterMap(RasterMapsCompanion companion) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final author = await _currentUser.currentOrSystem();
      final stamped = companion.copyWith(
        createdAt: Value(now),
        updatedAt: Value(now),
        createdByUserUuid: Value(author),
        lastModifiedByUserUuid: Value(author),
      );
      await _database.into(_database.rasterMaps).insert(stamped);
      if (stamped.uuid.present) {
        await _logger.logInsert('raster_maps', stamped.uuid.value);
      }
    } catch (e, st) {
      _log.severe('Failed to add raster map', e, st);
      throw DbException('Failed to add raster map', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> updateRasterMap(RasterMap rasterMap) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final author = await _currentUser.currentOrSystem();
      final old = await (_database.select(_database.rasterMaps)
            ..where((rm) => rm.uuid.equalsValue(rasterMap.uuid))
            ..limit(1))
          .getSingleOrNull();
      final updated = rasterMap.copyWith(
        updatedAt: Value(now),
        lastModifiedByUserUuid: Value(author),
      );
      await _database.update(_database.rasterMaps).replace(updated);
      if (old != null) {
        await _logger.logUpdate(
          'raster_maps',
          rasterMap.uuid,
          oldValues: {
            'title': old.title,
            'map_type': old.mapType,
            'file_name': old.fileName,
            'cave_uuid': old.caveUuid,
            'cave_area_uuid': old.caveAreaUuid,
          },
          newValues: {
            'title': rasterMap.title,
            'map_type': rasterMap.mapType,
            'file_name': rasterMap.fileName,
            'cave_uuid': rasterMap.caveUuid,
            'cave_area_uuid': rasterMap.caveAreaUuid,
          },
        );
      }
    } catch (e, st) {
      _log.severe('Failed to update raster map', e, st);
      throw DbException('Failed to update raster map', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteRasterMap(Uuid id) async {
    try {
      final old = await (_database.select(_database.rasterMaps)
            ..where((rm) => rm.uuid.equalsValue(id))
            ..limit(1))
          .getSingleOrNull();
      await (_database.delete(_database.rasterMaps)..where((rm) => rm.uuid.equalsValue(id))).go();
      if (old != null) {
        await _logger.logDelete(
          'raster_maps',
          id,
          oldValues: {
            'title': old.title,
            'map_type': old.mapType,
            'file_name': old.fileName,
            'cave_uuid': old.caveUuid,
          },
        );
      }
    } catch (e, st) {
      _log.severe('Failed to delete raster map', e, st);
      throw DbException('Failed to delete raster map', cause: e, stackTrace: st);
    }
  }
}