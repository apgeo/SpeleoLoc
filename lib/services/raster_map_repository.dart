import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/utils/app_logger.dart';

class RasterMapRepository implements IRasterMapRepository {
  final AppDatabase _database;
  final _log = AppLogger.of('RasterMapRepository');

  RasterMapRepository(this._database);

  @override
  Future<List<RasterMap>> getRasterMaps(int caveId) async {
    try {
      return await (_database.select(_database.rasterMaps)..where((rm) => rm.caveId.equals(caveId))).get();
    } catch (e, st) {
      _log.severe('Failed to load raster maps', e, st);
      rethrow;
    }
  }

  @override
  Future<List<CavePlaceWithDefinition>> getCavePlacesWithDefinitionsForRasterMap(int caveId, int rasterMapId) async {
    try {
      return await _database.getCavePlacesWithDefinitionsForRasterMap(caveId, rasterMapId);
    } catch (e, st) {
      _log.severe('Failed to load definitions', e, st);
      rethrow;
    }
  }

  @override
  Future<void> addRasterMap(RasterMapsCompanion companion) async {
    try {
      await _database.into(_database.rasterMaps).insert(companion);
    } catch (e, st) {
      _log.severe('Failed to add raster map', e, st);
      rethrow;
    }
  }

  @override
  Future<void> updateRasterMap(RasterMap rasterMap) async {
    try {
      await _database.update(_database.rasterMaps).replace(rasterMap);
    } catch (e, st) {
      _log.severe('Failed to update raster map', e, st);
      rethrow;
    }
  }

  @override
  Future<void> deleteRasterMap(int id) async {
    try {
      await (_database.delete(_database.rasterMaps)..where((rm) => rm.id.equals(id))).go();
    } catch (e, st) {
      _log.severe('Failed to delete raster map', e, st);
      rethrow;
    }
  }
}