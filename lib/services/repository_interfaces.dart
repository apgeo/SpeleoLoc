import 'package:speleoloc/data/source/database/app_database.dart';

/// Abstract contract for the cave repository.
///
/// Consumers (screens, services, providers) should depend on this interface
/// rather than the concrete Drift implementation — enables fakes in tests.
abstract class ICaveRepository {
  Future<List<Cave>> getCaves();
  Stream<List<Cave>> watchCaves();
  Future<int> addCave(
    String title, {
    int? surfaceAreaId,
    String? description,
  });
  Future<void> updateCave(
    int id,
    String title, {
    int? surfaceAreaId,
    String? description,
  });
  Future<void> deleteCave(int id);
  Future<List<CaveArea>> getCaveAreas(int caveId);
}

/// Abstract contract for the cave-place repository.
abstract class ICavePlaceRepository {
  Future<List<CavePlace>> getCavePlaces(int caveId);
  Stream<List<CavePlace>> watchCavePlaces(int caveId);
  Future<void> addCavePlace(int caveId, String title);
  Future<void> deleteCavePlace(int id);
  Future<CavePlace?> findById(int id);
  Future<CavePlace?> findCavePlaceByQrCode(int qrCode, int caveId);
}

/// Abstract contract for the raster-map repository.
abstract class IRasterMapRepository {
  Future<List<RasterMap>> getRasterMaps(int caveId);
  Future<List<CavePlaceWithDefinition>> getCavePlacesWithDefinitionsForRasterMap(
    int caveId,
    int rasterMapId,
  );
  Future<void> addRasterMap(RasterMapsCompanion companion);
  Future<void> updateRasterMap(RasterMap rasterMap);
  Future<void> deleteRasterMap(int id);
}

/// Abstract contract for the cave-place ↔ raster-map definition repository.
abstract class IDefinitionRepository {
  Future<CavePlaceToRasterMapDefinition?> findDefinition(
    int cavePlaceId,
    int rasterMapId,
  );
  Future<List<CavePlaceWithDefinition>> getCavePlacesWithDefinitionsForRasterMap(
    int caveId,
    int rasterMapId,
  );
  Future<CavePlaceToRasterMapDefinition> saveDefinition(
    int cavePlaceId,
    int rasterMapId,
    double imageX,
    double imageY,
  );
  Future<bool> deleteDefinition(int cavePlaceId, int rasterMapId);
}
