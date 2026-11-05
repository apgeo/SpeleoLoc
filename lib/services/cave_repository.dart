import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_area_title_clash_exception.dart';
import 'package:speleoloc/services/cave_model/model_links_cleanup.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/delete_cascades.dart';
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

  CaveRepository(
    this._database,
    this._currentUser,
    this._logger, {
    Clock clock = const SystemClock(),
  }) : _clock = clock;

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
  Future<Uuid> addCave(
    String title, {
    Uuid? surfaceAreaUuid,
    String? description,
    String? caveLocalIndex,
  }) async {
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
  Future<void> updateCave(
    Uuid id,
    String title, {
    Uuid? surfaceAreaUuid,
    String? description,
    String? caveLocalIndex,
  }) async {
    try {
      final now = _clock.nowMs();
      final author = await _currentUser.currentOrSystem();
      final old =
          await (_database.select(_database.caves)
                ..where((c) => c.uuid.equalsValue(id))
                ..limit(1))
              .getSingleOrNull();
      await (_database.update(
        _database.caves,
      )..where((c) => c.uuid.equalsValue(id))).write(
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

  /// Writes only the index, so a code generated while another edit of the
  /// cave is open does not overwrite that edit's other fields.
  @override
  Future<void> setCaveLocalIndex(Uuid caveUuid, String caveLocalIndex) async {
    try {
      await _database.transaction(() async {
        final old =
            await (_database.select(_database.caves)
                  ..where((c) => c.uuid.equalsValue(caveUuid))
                  ..limit(1))
                .getSingleOrNull();
        if (old == null || old.caveLocalIndex == caveLocalIndex) return;
        await (_database.update(
          _database.caves,
        )..where((c) => c.uuid.equalsValue(caveUuid))).write(
          CavesCompanion(
            caveLocalIndex: Value(caveLocalIndex),
            updatedAt: Value(_clock.nowMs()),
            lastModifiedByUserUuid: Value(await _currentUser.currentOrSystem()),
          ),
        );
        await _logger.logUpdate(
          'caves',
          caveUuid,
          oldValues: {'cave_local_index': old.caveLocalIndex},
          newValues: {'cave_local_index': caveLocalIndex},
        );
      });
    } catch (e, st) {
      _log.severe('Failed to set cave local index', e, st);
      throw DbException(
        'Failed to set cave local index',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> deleteCave(Uuid id) async {
    try {
      await _database.transaction(() async {
        final now = _clock.nowMs();
        final author = await _currentUser.currentOrSystem();
        // Pre-images, captured before the rows go, for the tombstones peers
        // need to remove the same rows on sync import.
        final caveRow =
            await (_database.select(_database.caves)
                  ..where((c) => c.uuid.equalsValue(id))
                  ..limit(1))
                .getSingleOrNull();
        final caveAreas = await (_database.select(
          _database.caveAreas,
        )..where((ca) => ca.caveUuid.equalsValue(id))).get();
        final caveAreaIds = caveAreas.map((a) => a.uuid).toList();

        final cavePlaces = await (_database.select(
          _database.cavePlaces,
        )..where((cp) => cp.caveUuid.equalsValue(id))).get();
        final cavePlaceIds = cavePlaces.map((p) => p.uuid).toList();

        final rasterMaps = await (_database.select(
          _database.rasterMaps,
        )..where((rm) => rm.caveUuid.equalsValue(id))).get();
        final rasterMapIds = rasterMaps.map((rm) => rm.uuid).toList();

        final caveTrips = await (_database.select(
          _database.caveTrips,
        )..where((t) => t.caveUuid.equalsValue(id))).get();

        final beacons = await (_database.select(
          _database.cavePlaceBeacons,
        )..where((b) => b.caveUuid.equalsValue(id))).get();

        await deleteGeofeatureLinks(_database, _logger, GeofeatureType.cave, [
          id,
        ]);
        await deleteGeofeatureLinks(
          _database,
          _logger,
          GeofeatureType.cavePlace,
          cavePlaceIds,
        );
        await deleteGeofeatureLinks(
          _database,
          _logger,
          GeofeatureType.caveArea,
          caveAreaIds,
        );
        await deletePlaceMapDefinitions(
          _database,
          _logger,
          placeUuids: cavePlaceIds,
          mapUuids: rasterMapIds,
        );
        await deleteTripsWithChildren(_database, _logger, caveTrips);
        // A trip of another cave may have recorded a visit to one of these
        // places; that point stays with its own trip.
        await detachTripPointsFromPlaces(
          _database,
          _logger,
          placeUuids: cavePlaceIds,
          now: now,
          author: author,
        );

        await deleteModelLinks(_database, _logger, caveUuid: id);

        // Remove BLE tag registrations for this cave. Unregistering is a
        // soft delete, so active and already-unregistered rows alike still
        // hold the FK into cave_places/caves; clear them before those
        // parents. Keyed on cave_uuid, which covers both references.
        await (_database.delete(
          _database.cavePlaceBeacons,
        )..where((b) => b.caveUuid.equalsValue(id))).go();

        // Remove cave-linked base data.
        await (_database.delete(
          _database.caveEntrances,
        )..where((e) => e.caveUuid.equalsValue(id))).go();
        await (_database.delete(
          _database.rasterMaps,
        )..where((rm) => rm.caveUuid.equalsValue(id))).go();
        await (_database.delete(
          _database.cavePlaces,
        )..where((cp) => cp.caveUuid.equalsValue(id))).go();
        await (_database.delete(
          _database.caveAreas,
        )..where((ca) => ca.caveUuid.equalsValue(id))).go();

        await (_database.delete(
          _database.caves,
        )..where((c) => c.uuid.equalsValue(id))).go();

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
          await _logger.logDelete(
            'cave_places',
            p.uuid,
            oldValues: {'title': p.title, 'cave_uuid': p.caveUuid},
          );
        }
        for (final m in rasterMaps) {
          await _logger.logDelete(
            'raster_maps',
            m.uuid,
            oldValues: {'title': m.title, 'cave_uuid': m.caveUuid},
          );
        }
        for (final a in caveAreas) {
          await _logger.logDelete(
            'cave_areas',
            a.uuid,
            oldValues: {'title': a.title, 'cave_uuid': a.caveUuid},
          );
        }
        for (final b in beacons) {
          await _logger.logDelete(
            'cave_place_beacons',
            b.uuid,
            oldValues: {
              'cave_place_uuid': b.cavePlaceUuid.toString(),
              'proximity_uuid': b.proximityUuid,
              'major': b.major,
              'minor': b.minor,
            },
          );
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
      return await (_database.select(
        _database.caveAreas,
      )..where((ca) => ca.caveUuid.equalsValue(caveUuid))).get();
    } catch (e, st) {
      _log.severe('Failed to load cave areas', e, st);
      throw DbException('Failed to load cave areas', cause: e, stackTrace: st);
    }
  }

  @override
  Future<Cave?> findById(Uuid uuid) async {
    try {
      return await (_database.select(
        _database.caves,
      )..where((c) => c.uuid.equalsValue(uuid))).getSingleOrNull();
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
      throw DbException(
        'Failed to load surface areas',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<CaveArea?> findCaveAreaById(Uuid uuid) async {
    try {
      return await (_database.select(
        _database.caveAreas,
      )..where((a) => a.uuid.equalsValue(uuid))).getSingleOrNull();
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
      await _database
          .into(_database.caveAreas)
          .insert(
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
      await (_database.update(
        _database.caveAreas,
      )..where((a) => a.uuid.equalsValue(uuid))).write(
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
      throw DbException('Failed to update cave area', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteCaveArea(CaveArea area) async {
    try {
      await _database.transaction(() async {
        final now = _clock.nowMs();
        final author = await _currentUser.currentOrSystem();

        // Its places and maps stay in the cave, outside any area. A place
        // there may already hold the title one of them brings along, and two
        // places outside every area cannot share a title.
        final places = await (_database.select(
          _database.cavePlaces,
        )..where((p) => p.caveAreaUuid.equalsValue(area.uuid))).get();
        if (places.isNotEmpty) {
          final clash =
              await (_database.select(_database.cavePlaces)
                    ..where(
                      (p) =>
                          p.caveUuid.equalsValue(area.caveUuid) &
                          p.caveAreaUuid.isNull() &
                          p.title.isIn(places.map((x) => x.title)),
                    )
                    ..limit(1))
                  .getSingleOrNull();
          if (clash != null) throw CaveAreaTitleClashException(clash.title);
        }
        for (final p in places) {
          await (_database.update(
            _database.cavePlaces,
          )..where((t) => t.uuid.equalsValue(p.uuid))).write(
            CavePlacesCompanion(
              caveAreaUuid: const Value(null),
              updatedAt: Value(now),
              lastModifiedByUserUuid: Value(author),
            ),
          );
          await _logger.logUpdate(
            'cave_places',
            p.uuid,
            oldValues: {'cave_area_uuid': p.caveAreaUuid},
            newValues: {'cave_area_uuid': null},
          );
        }
        final maps = await (_database.select(
          _database.rasterMaps,
        )..where((m) => m.caveAreaUuid.equalsValue(area.uuid))).get();
        for (final m in maps) {
          await (_database.update(
            _database.rasterMaps,
          )..where((t) => t.uuid.equalsValue(m.uuid))).write(
            RasterMapsCompanion(
              caveAreaUuid: const Value(null),
              updatedAt: Value(now),
              lastModifiedByUserUuid: Value(author),
            ),
          );
          await _logger.logUpdate(
            'raster_maps',
            m.uuid,
            oldValues: {'cave_area_uuid': m.caveAreaUuid},
            newValues: {'cave_area_uuid': null},
          );
        }
        await deleteGeofeatureLinks(
          _database,
          _logger,
          GeofeatureType.caveArea,
          [area.uuid],
        );

        await (_database.delete(
          _database.caveAreas,
        )..where((a) => a.uuid.equalsValue(area.uuid))).go();
        await _logger.logDelete(
          'cave_areas',
          area.uuid,
          oldValues: {'title': area.title, 'cave_uuid': area.caveUuid},
        );
      });
    } on CaveAreaTitleClashException {
      rethrow;
    } catch (e, st) {
      _log.severe('Failed to delete cave area', e, st);
      throw DbException('Failed to delete cave area', cause: e, stackTrace: st);
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
      await _database
          .into(_database.surfaceAreas)
          .insert(
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
      throw DbException('Failed to add surface area', cause: e, stackTrace: st);
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
      await (_database.update(
        _database.surfaceAreas,
      )..where((a) => a.uuid.equalsValue(existing.uuid))).write(
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
      throw DbException(
        'Failed to update surface area',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> deleteSurfaceArea(SurfaceArea area) async {
    try {
      await _database.transaction(() async {
        final now = _clock.nowMs();
        final author = await _currentUser.currentOrSystem();
        // Its caves stay, outside any surface area. Caves without one never
        // clash on title, so nothing can block this.
        final caves = await (_database.select(
          _database.caves,
        )..where((c) => c.surfaceAreaUuid.equalsValue(area.uuid))).get();
        for (final c in caves) {
          await (_database.update(
            _database.caves,
          )..where((t) => t.uuid.equalsValue(c.uuid))).write(
            CavesCompanion(
              surfaceAreaUuid: const Value(null),
              updatedAt: Value(now),
              lastModifiedByUserUuid: Value(author),
            ),
          );
          await _logger.logUpdate(
            'caves',
            c.uuid,
            oldValues: {'surface_area_uuid': c.surfaceAreaUuid},
            newValues: {'surface_area_uuid': null},
          );
        }
        await (_database.delete(
          _database.surfaceAreas,
        )..where((a) => a.uuid.equalsValue(area.uuid))).go();
        await _logger.logDelete(
          'surface_areas',
          area.uuid,
          oldValues: {'title': area.title, 'description': area.description},
        );
      });
    } catch (e, st) {
      _log.severe('Failed to delete surface area', e, st);
      throw DbException(
        'Failed to delete surface area',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
