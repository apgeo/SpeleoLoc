import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/uuid.dart';

/// Abstract contract for the cave repository.
abstract class ICaveRepository {
  Future<List<Cave>> getCaves();
  Stream<List<Cave>> watchCaves();
  Future<Uuid> addCave(
    String title, {
    Uuid? surfaceAreaUuid,
    String? description,
  });
  Future<void> updateCave(
    Uuid uuid,
    String title, {
    Uuid? surfaceAreaUuid,
    String? description,
  });
  Future<void> deleteCave(Uuid uuid);
  Future<List<CaveArea>> getCaveAreas(Uuid caveUuid);
}

/// Abstract contract for the cave-place repository.
abstract class ICavePlaceRepository {
  Future<List<CavePlace>> getCavePlaces(Uuid caveUuid);
  Stream<List<CavePlace>> watchCavePlaces(Uuid caveUuid);
  Future<void> addCavePlace(
    Uuid caveUuid,
    String title, {
    bool isEntrance = false,
    bool isMainEntrance = false,
  });

  /// Insert a cave place from an arbitrary companion. The repository
  /// stamps audit columns (`createdAt`, `updatedAt`, `createdByUserUuid`,
  /// `lastModifiedByUserUuid`) when not provided and writes a `change_log`
  /// header so syncing detects the new row.
  ///
  /// Returns the persisted row's uuid.
  Future<Uuid> addCavePlaceFromCompanion(CavePlacesCompanion companion);

  /// Update an existing cave place from a partial companion. Only fields
  /// whose `Value.present` is true are written. The repository refreshes
  /// `updatedAt` / `lastModifiedByUserUuid` automatically and writes a
  /// `change_log` diff.
  Future<void> updateCavePlace(Uuid uuid, CavePlacesCompanion patch);

  Future<void> deleteCavePlace(Uuid uuid);
  Future<CavePlace?> findById(Uuid uuid);
  Future<CavePlace?> findCavePlaceByQrCode(int qrCode, Uuid caveUuid);
}

/// Abstract contract for the raster-map repository.
abstract class IRasterMapRepository {
  Future<List<RasterMap>> getRasterMaps(Uuid caveUuid);
  Future<List<CavePlaceWithDefinition>> getCavePlacesWithDefinitionsForRasterMap(
    Uuid caveUuid,
    Uuid rasterMapUuid,
  );
  Future<void> addRasterMap(RasterMapsCompanion companion);
  Future<void> updateRasterMap(RasterMap rasterMap);
  Future<void> deleteRasterMap(Uuid uuid);
}

/// Abstract contract for the cave-place ↔ raster-map definition repository.
abstract class IDefinitionRepository {
  Future<CavePlaceToRasterMapDefinition?> findDefinition(
    Uuid cavePlaceUuid,
    Uuid rasterMapUuid,
  );
  Future<List<CavePlaceWithDefinition>> getCavePlacesWithDefinitionsForRasterMap(
    Uuid caveUuid,
    Uuid rasterMapUuid,
  );
  Future<CavePlaceToRasterMapDefinition> saveDefinition(
    Uuid cavePlaceUuid,
    Uuid rasterMapUuid,
    double imageX,
    double imageY,
  );
  Future<bool> deleteDefinition(Uuid cavePlaceUuid, Uuid rasterMapUuid);
}
