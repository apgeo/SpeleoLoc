import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/utils/app_exceptions.dart';
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
      throw DbException('Failed to load caves', cause: e, stackTrace: st);
    }
  }

  @override
  Stream<List<Cave>> watchCaves() {
    return _database.select(_database.caves).watch();
  }

  @override
  Future<Uuid> addCave(String title, {Uuid? surfaceAreaUuid, String? description}) async {
    try {
      final newUuid = Uuid.v7();
      final companion = CavesCompanion.insert(
        uuid: newUuid,
        title: title,
        surfaceAreaUuid: Value(surfaceAreaUuid),
        description: Value(description),
      );
      await _database.into(_database.caves).insert(companion);
      return newUuid;
    } catch (e, st) {
      _log.severe('Failed to add cave', e, st);
      throw DbException('Failed to add cave', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> updateCave(Uuid id, String title, {Uuid? surfaceAreaUuid, String? description}) async {
    try {
      await (_database.update(_database.caves)..where((c) => c.uuid.equalsValue(id))).write(
        CavesCompanion(
          title: Value(title),
          surfaceAreaUuid: Value(surfaceAreaUuid),
          description: Value(description),
        ),
      );
    } catch (e, st) {
      _log.severe('Failed to update cave', e, st);
      throw DbException('Failed to update cave', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteCave(Uuid id) async {
    try {
      await _database.transaction(() async {
        final caveAreas = await (_database.select(_database.caveAreas)
              ..where((ca) => ca.caveUuid.equalsValue(id)))
            .get();
        final caveAreaIds = caveAreas.map((a) => a.uuid).toList();

        final cavePlaces = await (_database.select(_database.cavePlaces)
              ..where((cp) => cp.caveUuid.equalsValue(id)))
            .get();
        final cavePlaceIds = cavePlaces.map((p) => p.uuid).toList();

        final rasterMaps = await (_database.select(_database.rasterMaps)
              ..where((rm) => rm.caveUuid.equalsValue(id)))
            .get();
        final rasterMapIds = rasterMaps.map((rm) => rm.uuid).toList();

        final caveTrips = await (_database.select(_database.caveTrips)
              ..where((t) => t.caveUuid.equalsValue(id)))
            .get();
        final caveTripIds = caveTrips.map((t) => t.uuid).toList();

        // Remove geofeature links for cave, cave places and cave areas.
        await (_database.delete(_database.documentationFilesToGeofeatures)
              ..where((g) =>
                  (g.geofeatureType.equals('cave') & g.geofeatureUuid.equalsValue(id))))
            .go();
        if (cavePlaceIds.isNotEmpty) {
          await (_database.delete(_database.documentationFilesToGeofeatures)
                ..where((g) =>
                    g.geofeatureType.equals('cave_place') &
                    g.geofeatureUuid.isInValues(cavePlaceIds)))
              .go();
        }
        if (caveAreaIds.isNotEmpty) {
          await (_database.delete(_database.documentationFilesToGeofeatures)
                ..where((g) =>
                    g.geofeatureType.equals('cave_area') &
                    g.geofeatureUuid.isInValues(caveAreaIds)))
              .go();
        }

        // Remove place/map definitions tied to this cave.
        if (cavePlaceIds.isNotEmpty || rasterMapIds.isNotEmpty) {
          await (_database.delete(_database.cavePlaceToRasterMapDefinitions)
                ..where((d) {
                  final byPlace = cavePlaceIds.isNotEmpty
                      ? d.cavePlaceUuid.isInValues(cavePlaceIds)
                      : const Constant(false);
                  final byMap = rasterMapIds.isNotEmpty
                      ? d.rasterMapUuid.isInValues(rasterMapIds)
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
                      ? tp.caveTripUuid.isInValues(caveTripIds)
                      : const Constant(false);
                  final byPlace = cavePlaceIds.isNotEmpty
                      ? tp.cavePlaceUuid.isInValues(cavePlaceIds)
                      : const Constant(false);
                  return byTrip | byPlace;
                }))
              .go();
        }
        await (_database.delete(_database.caveTrips)
              ..where((t) => t.caveUuid.equalsValue(id)))
            .go();

        // Remove cave-linked base data.
        await (_database.delete(_database.caveEntrances)
              ..where((e) => e.caveUuid.equalsValue(id)))
            .go();
        await (_database.delete(_database.rasterMaps)
              ..where((rm) => rm.caveUuid.equalsValue(id)))
            .go();
        await (_database.delete(_database.cavePlaces)
              ..where((cp) => cp.caveUuid.equalsValue(id)))
            .go();
        await (_database.delete(_database.caveAreas)
              ..where((ca) => ca.caveUuid.equalsValue(id)))
            .go();

        await (_database.delete(_database.caves)..where((c) => c.uuid.equalsValue(id))).go();
      });
    } catch (e, st) {
      _log.severe('Failed to delete cave', e, st);
      throw DbException('Failed to delete cave', cause: e, stackTrace: st);
    }
  }

  @override
  Future<List<CaveArea>> getCaveAreas(Uuid caveUuid) async {
    try {
      return await (_database.select(_database.caveAreas)..where((ca) => ca.caveUuid.equalsValue(caveUuid))).get();
    } catch (e, st) {
      _log.severe('Failed to load cave areas', e, st);
      throw DbException('Failed to load cave areas', cause: e, stackTrace: st);
    }
  }
}