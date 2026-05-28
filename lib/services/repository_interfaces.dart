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
    String? caveLocalIndex,
  });
  Future<void> updateCave(
    Uuid uuid,
    String title, {
    Uuid? surfaceAreaUuid,
    String? description,
    String? caveLocalIndex,
  });
  Future<void> deleteCave(Uuid uuid);
  Future<List<CaveArea>> getCaveAreas(Uuid caveUuid);

  /// Returns the single [Cave] with [uuid], or `null` if none exists.
  Future<Cave?> findById(Uuid uuid);

  /// Returns all [SurfaceArea] rows. Used by list pages that render
  /// `cave.surfaceAreaUuid` as a human-readable label.
  Future<List<SurfaceArea>> getSurfaceAreas();
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
  Future<CavePlace?> findCavePlaceByCode(String code, Uuid caveUuid);

  /// Returns the cave-places whose uuid is in [uuids]. Used to resolve a
  /// batch of place references (e.g. trip points) in one round-trip.
  Future<List<CavePlace>> findByIds(Iterable<Uuid> uuids);

  /// Returns the cave-places whose `place_code_identifier == code`,
  /// optionally restricted to a single cave via [caveUuid] (when null the
  /// search is global), and optionally excluding [excludeUuid] (typically
  /// the place currently being edited).
  Future<List<CavePlace>> findByPlaceCodeIdentifier(
    String code, {
    Uuid? caveUuid,
    Uuid? excludeUuid,
  });

  /// Returns the cave-places (across all caves) whose
  /// `qr_code_resource_identifier == code`, optionally excluding
  /// [excludeUuid].
  Future<List<CavePlace>> findByQrCodeResourceIdentifier(
    String code, {
    Uuid? excludeUuid,
  });

  /// Returns the cave-places flagged as entrances in [caveUuid].
  /// When [mainOnly] is true, restricts the result to main entrances.
  /// Optionally excludes [excludeUuid] (the place currently being edited).
  Future<List<CavePlace>> findEntrances(
    Uuid caveUuid, {
    bool mainOnly = false,
    Uuid? excludeUuid,
  });
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
  Future<void> updateRasterMapOrder(List<Uuid> orderedIds);
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

  /// Returns the number of point definitions linked to [rasterMapUuid].
  Future<int> countDefinitionsForRasterMap(Uuid rasterMapUuid);

  /// Deletes all point definitions linked to [rasterMapUuid]. Returns the number of rows deleted.
  Future<int> deleteAllDefinitionsForRasterMap(Uuid rasterMapUuid);

  /// Returns every definition whose `raster_map_uuid` is in
  /// [rasterMapUuids]. Empty input returns an empty list without hitting
  /// the database.
  Future<List<CavePlaceToRasterMapDefinition>> getDefinitionsForRasterMaps(
    Iterable<Uuid> rasterMapUuids,
  );
}

/// Abstract contract for the cave-trip read-only / mutation operations.
///
/// Note: trip *state* (active trip, paused flag, log appending) is owned by
/// [CaveTripService]. This repository only exposes table-level operations
/// (lookup by id, list, rename, delete, report-template lookup) so screens
/// don't reach into the global `AppDatabase` for them.
abstract class ICaveTripRepository {
  Future<CaveTrip?> findById(Uuid uuid);
  Future<List<CaveTrip>> getCaveTrips(Uuid caveUuid);
  Future<List<String>> getCaveTripTitles(Uuid caveUuid);
  Future<List<CaveTripPoint>> getTripPoints(Uuid tripUuid);
  Future<List<TripReportTemplate>> getTripReportTemplates();
  Future<void> renameCaveTrip(Uuid tripUuid, String newTitle);
  Future<void> deleteCaveTrip(Uuid tripUuid);
}

