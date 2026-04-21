import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/utils/app_logger.dart';

class CaveRepository implements ICaveRepository {
  final AppDatabase _database;
  final _log = AppLogger.of('CaveRepository');

  CaveRepository(this._database);

  @override
  Future<List<Cave>> getCaves() async {
    try {
      return await _database.select(_database.caves).get();
    } catch (e, st) {
      _log.severe('Failed to load caves', e, st);
      rethrow;
    }
  }

  @override
  Stream<List<Cave>> watchCaves() {
    return _database.select(_database.caves).watch();
  }

  @override
  Future<int> addCave(String title, {int? surfaceAreaId, String? description}) async {
    try {
      final companion = CavesCompanion(
        title: Value(title),
        surfaceAreaId: Value(surfaceAreaId),
        description: Value(description),
      );
      return await _database.into(_database.caves).insert(companion);
    } catch (e, st) {
      _log.severe('Failed to add cave', e, st);
      rethrow;
    }
  }

  @override
  Future<void> updateCave(int id, String title, {int? surfaceAreaId, String? description}) async {
    try {
      await (_database.update(_database.caves)..where((c) => c.id.equals(id))).write(
        CavesCompanion(
          title: Value(title),
          surfaceAreaId: Value(surfaceAreaId),
          description: Value(description),
        ),
      );
    } catch (e, st) {
      _log.severe('Failed to update cave', e, st);
      rethrow;
    }
  }

  @override
  Future<void> deleteCave(int id) async {
    try {
      await _database.transaction(() async {
        final caveAreas = await (_database.select(_database.caveAreas)
              ..where((ca) => ca.caveId.equals(id)))
            .get();
        final caveAreaIds = caveAreas.map((a) => a.id).toList();

        final cavePlaces = await (_database.select(_database.cavePlaces)
              ..where((cp) => cp.caveId.equals(id)))
            .get();
        final cavePlaceIds = cavePlaces.map((p) => p.id).toList();

        final rasterMaps = await (_database.select(_database.rasterMaps)
              ..where((rm) => rm.caveId.equals(id)))
            .get();
        final rasterMapIds = rasterMaps.map((rm) => rm.id).toList();

        final caveTrips = await (_database.select(_database.caveTrips)
              ..where((t) => t.caveId.equals(id)))
            .get();
        final caveTripIds = caveTrips.map((t) => t.id).toList();

        // Remove geofeature links for cave, cave places and cave areas.
        await (_database.delete(_database.documentationFilesToGeofeatures)
              ..where((g) =>
                  (g.geofeatureType.equals('cave') & g.geofeatureId.equals(id))))
            .go();
        if (cavePlaceIds.isNotEmpty) {
          await (_database.delete(_database.documentationFilesToGeofeatures)
                ..where((g) =>
                    g.geofeatureType.equals('cave_place') &
                    g.geofeatureId.isIn(cavePlaceIds)))
              .go();
        }
        if (caveAreaIds.isNotEmpty) {
          await (_database.delete(_database.documentationFilesToGeofeatures)
                ..where((g) =>
                    g.geofeatureType.equals('cave_area') &
                    g.geofeatureId.isIn(caveAreaIds)))
              .go();
        }

        // Remove place/map definitions tied to this cave.
        if (cavePlaceIds.isNotEmpty || rasterMapIds.isNotEmpty) {
          await (_database.delete(_database.cavePlaceToRasterMapDefinitions)
                ..where((d) {
                  final byPlace = cavePlaceIds.isNotEmpty
                      ? d.cavePlaceId.isIn(cavePlaceIds)
                      : const Constant(false);
                  final byMap = rasterMapIds.isNotEmpty
                      ? d.rasterMapId.isIn(rasterMapIds)
                      : const Constant(false);
                  return byPlace | byMap;
                }))
              .go();
        }

        // Remove trip points and trips for this cave.
        if (caveTripIds.isNotEmpty || cavePlaceIds.isNotEmpty) {
          await (_database.delete(_database.caveTripPoints)
                ..where((tp) {
                  final byTrip = caveTripIds.isNotEmpty
                      ? tp.caveTripId.isIn(caveTripIds)
                      : const Constant(false);
                  final byPlace = cavePlaceIds.isNotEmpty
                      ? tp.cavePlaceId.isIn(cavePlaceIds)
                      : const Constant(false);
                  return byTrip | byPlace;
                }))
              .go();
        }
        await (_database.delete(_database.caveTrips)
              ..where((t) => t.caveId.equals(id)))
            .go();

        // Remove cave-linked base data.
        await (_database.delete(_database.caveEntrances)
              ..where((e) => e.caveId.equals(id)))
            .go();
        await (_database.delete(_database.rasterMaps)
              ..where((rm) => rm.caveId.equals(id)))
            .go();
        await (_database.delete(_database.cavePlaces)
              ..where((cp) => cp.caveId.equals(id)))
            .go();
        await (_database.delete(_database.caveAreas)
              ..where((ca) => ca.caveId.equals(id)))
            .go();

        await (_database.delete(_database.caves)..where((c) => c.id.equals(id))).go();
      });
    } catch (e, st) {
      _log.severe('Failed to delete cave', e, st);
      rethrow;
    }
  }

  @override
  Future<List<CaveArea>> getCaveAreas(int caveId) async {
    try {
      return await (_database.select(_database.caveAreas)..where((ca) => ca.caveId.equals(caveId))).get();
    } catch (e, st) {
      _log.severe('Failed to load cave areas', e, st);
      rethrow;
    }
  }
}