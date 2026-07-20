import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/repository_interfaces.dart';

/// The cave + entrance-place pair created by [CaveGeoService.addCaveWithEntranceAt].
class CaveWithEntrance {
  final Uuid caveUuid;
  final Uuid entranceUuid;

  const CaveWithEntrance({required this.caveUuid, required this.entranceUuid});
}

/// Orchestrates creating and positioning geographic cave points from the
/// surface map — the point-management use cases that span the cave and
/// cave-place repositories. Kept UI-free so the creation rules (e.g. first
/// entrance of a cave becomes its main entrance) are unit-testable.
class CaveGeoService {
  final ICaveRepository _caveRepo;
  final ICavePlaceRepository _placeRepo;

  CaveGeoService(this._caveRepo, this._placeRepo);

  /// Creates an entrance cave place at ([latitude], [longitude]) in [caveUuid].
  /// The entrance is marked as the cave's main entrance when the cave does
  /// not already have one. Returns the new place's uuid.
  Future<Uuid> addEntranceAt({
    required Uuid caveUuid,
    required String title,
    required double latitude,
    required double longitude,
    double? altitude,
  }) async {
    final existingMain = await _placeRepo.findEntrances(
      caveUuid,
      mainOnly: true,
    );
    final isMain = existingMain.isEmpty;
    return _placeRepo.addCavePlaceFromCompanion(
      CavePlacesCompanion.insert(
        uuid: Uuid.v7(),
        title: title,
        caveUuid: caveUuid,
        isEntrance: const Value(1),
        isMainEntrance: Value(isMain ? 1 : 0),
        latitude: Value(latitude),
        longitude: Value(longitude),
        altitude: altitude != null ? Value(altitude) : const Value.absent(),
      ),
    );
  }

  /// Creates a new cave together with its (main) entrance cave place at
  /// ([latitude], [longitude]). Returns both new uuids.
  Future<CaveWithEntrance> addCaveWithEntranceAt({
    required String caveTitle,
    Uuid? surfaceAreaUuid,
    required String entranceTitle,
    required double latitude,
    required double longitude,
    double? altitude,
  }) async {
    final caveUuid = await _caveRepo.addCave(
      caveTitle,
      surfaceAreaUuid: surfaceAreaUuid,
    );
    final entranceUuid = await addEntranceAt(
      caveUuid: caveUuid,
      title: entranceTitle,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
    );
    return CaveWithEntrance(caveUuid: caveUuid, entranceUuid: entranceUuid);
  }

  /// Sets (or replaces) the coordinates of an existing cave place — used to
  /// define a place's location from a tapped point or the current GPS fix.
  Future<void> setPlaceLocation({
    required Uuid cavePlaceUuid,
    required double latitude,
    required double longitude,
    double? altitude,
  }) {
    return _placeRepo.updateCavePlace(
      cavePlaceUuid,
      CavePlacesCompanion(
        latitude: Value(latitude),
        longitude: Value(longitude),
        altitude: altitude != null ? Value(altitude) : const Value.absent(),
      ),
    );
  }
}
