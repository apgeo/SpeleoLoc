import 'package:speleoloc/data/source/database/app_database.dart';

class RasterMapRepository {
  final AppDatabase _database;

  RasterMapRepository(this._database);

  Future<List<RasterMap>> getRasterMaps(int caveId) async {
    try {
      return await (_database.select(_database.rasterMaps)..where((rm) => rm.caveId.equals(caveId))).get();
    } catch (e) {
      print('[RasterMapRepository] Failed to load raster maps: $e');
      rethrow;
    }
  }

  Future<List<CavePlaceWithDefinition>> getCavePlacesWithDefinitionsForRasterMap(int caveId, int rasterMapId) async {
    try {
      return await _database.getCavePlacesWithDefinitionsForRasterMap(caveId, rasterMapId);
    } catch (e) {
      print('[RasterMapRepository] Failed to load definitions: $e');
      rethrow;
    }
  }

  Future<void> addRasterMap(RasterMapsCompanion companion) async {
    try {
      await _database.into(_database.rasterMaps).insert(companion);
    } catch (e) {
      print('[RasterMapRepository] Failed to add raster map: $e');
      rethrow;
    }
  }

  Future<void> updateRasterMap(RasterMap rasterMap) async {
    try {
      await _database.update(_database.rasterMaps).replace(rasterMap);
    } catch (e) {
      print('[RasterMapRepository] Failed to update raster map: $e');
      rethrow;
    }
  }

  Future<void> deleteRasterMap(int id) async {
    try {
      await (_database.delete(_database.rasterMaps)..where((rm) => rm.id.equals(id))).go();
    } catch (e) {
      print('[RasterMapRepository] Failed to delete raster map: $e');
      rethrow;
    }
  }
}