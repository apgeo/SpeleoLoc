import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/utils/app_exceptions.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/clock.dart';

class CaveRepository implements ICaveRepository {
  final AppDatabase _database;
  final CurrentUserService _currentUser;
  final ChangeLogger _logger;
  final Clock _clock;
  final _log = AppLogger.of('CaveRepository');

  CaveRepository(this._database, this._currentUser, this._logger, {Clock clock = const SystemClock()}) : _clock = clock;

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
  Future<Uuid> addCave(String title, {Uuid? surfaceAreaUuid, String? description, String? caveLocalIndex}) async {
    try {
      final newUuid = Uuid.v7();
      final now = _clock.nowMs();
      final author = await _currentUser.currentOrSystem();
      final companion = CavesCompanion.insert(
        uuid: newUuid,
        title: title,
        surfaceAreaUuid: Value(surfaceAreaUuid),
        description: Value(description),
        caveLocalIndex: Value(caveLocalIndex),
        createdAt: Value(now),
        updatedAt: Value(now),
        createdByUserUuid: Value(author),
        lastModifiedByUserUuid: Value(author),
      );
      await _database.into(_database.caves).insert(companion);
      await _logger.logInsert('caves', newUuid);
      return newUuid;
    } catch (e, st) {
      _log.severe('Failed to add cave', e, st);
      throw DbException('Failed to add cave', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> updateCave(Uuid id, String title, {Uuid? surfaceAreaUuid, String? description, String? caveLocalIndex}) async {
    try {
      final now = _clock.nowMs();
      final author = await _currentUser.currentOrSystem();
      final old = await (_database.select(_database.caves)
            ..where((c) => c.uuid.equalsValue(id))
            ..limit(1))
          .getSingleOrNull();
      await (_database.update(_database.caves)..where((c) => c.uuid.equalsValue(id))).write(
        CavesCompanion(
          title: Value(title),
          surfaceAreaUuid: Value(surfaceAreaUuid),
          description: Value(description),
          caveLocalIndex: Value(caveLocalIndex),
          updatedAt: Value(now),
          lastModifiedByUserUuid: Value(author),
        ),
      );
      if (old != null) {
        await _logger.logUpdate(
          'caves',
          id,
          oldValues: {
            'title': old.title,
            'surface_area_uuid': old.surfaceAreaUuid,
            'description': old.description,
            'cave_local_index': old.caveLocalIndex,
          },
          newValues: {
            'title': title,
            'surface_area_uuid': surfaceAreaUuid,
            'description': description,
            'cave_local_index': caveLocalIndex,
          },
        );
      }
    } catch (e, st) {
      _log.severe('Failed to update cave', e, st);
      throw DbException('Failed to update cave', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteCave(Uuid id) async {
    try {
      await _database.transaction(() async {
        // Capture pre-image of the cave for the tombstone so peers can
        // LWW-delete locally on sync import.
        final caveRow = await (_database.select(_database.caves)
              ..where((c) => c.uuid.equalsValue(id))
              ..limit(1))
            .getSingleOrNull();
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

        // Log deletion tombstones for the cave itself and its direct
        // children (places, maps, areas, trips). Peers will use these
        // during sync import to propagate the delete cascade.
        if (caveRow != null) {
          await _logger.logDelete(
            'caves',
            id,
            oldValues: {
              'title': caveRow.title,
              'description': caveRow.description,
              'surface_area_uuid': caveRow.surfaceAreaUuid,
            },
          );
        }
        for (final p in cavePlaces) {
          await _logger.logDelete('cave_places', p.uuid, oldValues: {
            'title': p.title,
            'cave_uuid': p.caveUuid,
          });
        }
        for (final m in rasterMaps) {
          await _logger.logDelete('raster_maps', m.uuid, oldValues: {
            'title': m.title,
            'cave_uuid': m.caveUuid,
          });
        }
        for (final a in caveAreas) {
          await _logger.logDelete('cave_areas', a.uuid, oldValues: {
            'title': a.title,
            'cave_uuid': a.caveUuid,
          });
        }
        for (final t in caveTrips) {
          await _logger.logDelete('cave_trips', t.uuid, oldValues: {
            'title': t.title,
            'cave_uuid': t.caveUuid,
          });
        }
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

  @override
  Future<Cave?> findById(Uuid uuid) async {
    try {
      return await (_database.select(_database.caves)
            ..where((c) => c.uuid.equalsValue(uuid)))
          .getSingleOrNull();
    } catch (e, st) {
      _log.severe('Failed to find cave by id', e, st);
      throw DbException('Failed to find cave', cause: e, stackTrace: st);
    }
  }

  @override
  Future<List<SurfaceArea>> getSurfaceAreas() async {
    try {
      return await _database.select(_database.surfaceAreas).get();
    } catch (e, st) {
      _log.severe('Failed to load surface areas', e, st);
      throw DbException('Failed to load surface areas',
          cause: e, stackTrace: st);
    }
  }

  @override
  Future<CaveArea?> findCaveAreaById(Uuid uuid) async {
    try {
      return await (_database.select(_database.caveAreas)
            ..where((a) => a.uuid.equalsValue(uuid)))
          .getSingleOrNull();
    } catch (e, st) {
      _log.severe('Failed to find cave area by id', e, st);
      throw DbException('Failed to find cave area', cause: e, stackTrace: st);
    }
  }

  @override
  Future<Uuid> addCaveArea(Uuid caveUuid, String title) async {
    try {
      final newUuid = Uuid.v7();
      final now = _clock.nowMs();
      final author = await _currentUser.currentOrSystem();
      await _database.into(_database.caveAreas).insert(
            CaveAreasCompanion.insert(
              uuid: newUuid,
              title: title,
              caveUuid: caveUuid,
              createdAt: Value(now),
              updatedAt: Value(now),
              createdByUserUuid: Value(author),
              lastModifiedByUserUuid: Value(author),
            ),
          );
      await _logger.logInsert('cave_areas', newUuid);
      return newUuid;
    } catch (e, st) {
      _log.severe('Failed to add cave area', e, st);
      throw DbException('Failed to add cave area', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> updateCaveAreaTitle({
    required Uuid uuid,
    required String newTitle,
    String? oldTitle,
  }) async {
    try {
      final now = _clock.nowMs();
      final author = await _currentUser.currentOrSystem();
      await (_database.update(_database.caveAreas)
            ..where((a) => a.uuid.equalsValue(uuid)))
          .write(
        CaveAreasCompanion(
          title: Value(newTitle),
          updatedAt: Value(now),
          lastModifiedByUserUuid: Value(author),
        ),
      );
      if (oldTitle != null && oldTitle != newTitle) {
        await _logger.logUpdate(
          'cave_areas',
          uuid,
          oldValues: {'title': oldTitle},
          newValues: {'title': newTitle},
        );
      }
    } catch (e, st) {
      _log.severe('Failed to update cave area', e, st);
      throw DbException('Failed to update cave area',
          cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteCaveArea(CaveArea area) async {
    try {
      await (_database.delete(_database.caveAreas)
            ..where((a) => a.uuid.equalsValue(area.uuid)))
          .go();
      await _logger.logDelete(
        'cave_areas',
        area.uuid,
        oldValues: {
          'title': area.title,
          'cave_uuid': area.caveUuid,
        },
      );
    } catch (e, st) {
      _log.severe('Failed to delete cave area', e, st);
      throw DbException('Failed to delete cave area',
          cause: e, stackTrace: st);
    }
  }

  @override
  Future<Uuid> addSurfaceArea({
    required String title,
    String? description,
    String? generalAreaIdentifier,
  }) async {
    try {
      final newUuid = Uuid.v7();
      final now = _clock.nowMs();
      final author = await _currentUser.currentOrSystem();
      await _database.into(_database.surfaceAreas).insert(
            SurfaceAreasCompanion.insert(
              uuid: newUuid,
              title: title,
              description: Value(description),
              generalAreaIdentifier: Value(generalAreaIdentifier),
              createdAt: Value(now),
              updatedAt: Value(now),
              createdByUserUuid: Value(author),
              lastModifiedByUserUuid: Value(author),
            ),
          );
      await _logger.logInsert('surface_areas', newUuid);
      return newUuid;
    } catch (e, st) {
      _log.severe('Failed to add surface area', e, st);
      throw DbException('Failed to add surface area',
          cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> updateSurfaceArea({
    required SurfaceArea existing,
    required String title,
    String? description,
    String? generalAreaIdentifier,
  }) async {
    try {
      final now = _clock.nowMs();
      final author = await _currentUser.currentOrSystem();
      await (_database.update(_database.surfaceAreas)
            ..where((a) => a.uuid.equalsValue(existing.uuid)))
          .write(
        SurfaceAreasCompanion(
          title: Value(title),
          description: Value(description),
          generalAreaIdentifier: Value(generalAreaIdentifier),
          updatedAt: Value(now),
          lastModifiedByUserUuid: Value(author),
        ),
      );
      await _logger.logUpdate(
        'surface_areas',
        existing.uuid,
        oldValues: {
          'title': existing.title,
          'description': existing.description,
          'general_area_identifier': existing.generalAreaIdentifier,
        },
        newValues: {
          'title': title,
          'description': description,
          'general_area_identifier': generalAreaIdentifier,
        },
      );
    } catch (e, st) {
      _log.severe('Failed to update surface area', e, st);
      throw DbException('Failed to update surface area',
          cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteSurfaceArea(SurfaceArea area) async {
    try {
      await (_database.delete(_database.surfaceAreas)
            ..where((a) => a.uuid.equalsValue(area.uuid)))
          .go();
      await _logger.logDelete(
        'surface_areas',
        area.uuid,
        oldValues: {
          'title': area.title,
          'description': area.description,
        },
      );
    } catch (e, st) {
      _log.severe('Failed to delete surface area', e, st);
      throw DbException('Failed to delete surface area',
          cause: e, stackTrace: st);
    }
  }
}