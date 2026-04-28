import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/utils/app_exceptions.dart';
import 'package:speleoloc/utils/app_logger.dart';

class CavePlaceRepository implements ICavePlaceRepository {
  final AppDatabase _database;
  final CurrentUserService _currentUser;
  final ChangeLogger _logger;
  final _log = AppLogger.of('CavePlaceRepository');

  CavePlaceRepository(this._database, this._currentUser, this._logger);

  @override
  Future<List<CavePlace>> getCavePlaces(Uuid caveUuid) async {
    try {
      return await (_database.select(_database.cavePlaces)..where((cp) => cp.caveUuid.equalsValue(caveUuid))).get();
    } catch (e, st) {
      _log.severe('Failed to load cave places', e, st);
      throw DbException('Failed to load cave places', cause: e, stackTrace: st);
    }
  }

  @override
  Stream<List<CavePlace>> watchCavePlaces(Uuid caveUuid) {
    return (_database.select(_database.cavePlaces)
          ..where((cp) => cp.caveUuid.equalsValue(caveUuid)))
        .watch();
  }

  @override
  Future<void> addCavePlace(
    Uuid caveUuid,
    String title, {
    bool isEntrance = false,
    bool isMainEntrance = false,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final author = await _currentUser.currentOrSystem();
      final newUuid = Uuid.v7();
      await _database.into(_database.cavePlaces).insert(
        CavePlacesCompanion.insert(
          uuid: newUuid,
          title: title,
          caveUuid: caveUuid,
          isEntrance: Value(isEntrance ? 1 : 0),
          isMainEntrance: Value(isEntrance && isMainEntrance ? 1 : 0),
          createdAt: Value(now),
          updatedAt: Value(now),
          createdByUserUuid: Value(author),
          lastModifiedByUserUuid: Value(author),
        ),
      );
      await _logger.logInsert('cave_places', newUuid);
    } catch (e, st) {
      _log.severe('Failed to add cave place', e, st);
      throw DbException('Failed to add cave place', cause: e, stackTrace: st);
    }
  }

  @override
  Future<Uuid> addCavePlaceFromCompanion(CavePlacesCompanion companion) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final author = await _currentUser.currentOrSystem();
      final newUuid =
          companion.uuid.present ? companion.uuid.value : Uuid.v7();
      final stamped = companion.copyWith(
        uuid: Value(newUuid),
        createdAt:
            companion.createdAt.present ? companion.createdAt : Value(now),
        updatedAt:
            companion.updatedAt.present ? companion.updatedAt : Value(now),
        createdByUserUuid: companion.createdByUserUuid.present
            ? companion.createdByUserUuid
            : Value(author),
        lastModifiedByUserUuid: companion.lastModifiedByUserUuid.present
            ? companion.lastModifiedByUserUuid
            : Value(author),
      );
      await _database.into(_database.cavePlaces).insert(stamped);
      await _logger.logInsert('cave_places', newUuid);
      return newUuid;
    } catch (e, st) {
      _log.severe('Failed to add cave place', e, st);
      throw DbException('Failed to add cave place', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> updateCavePlace(Uuid id, CavePlacesCompanion patch) async {
    try {
      await _database.transaction(() async {
        final old = await (_database.select(_database.cavePlaces)
              ..where((cp) => cp.uuid.equalsValue(id))
              ..limit(1))
            .getSingleOrNull();
        if (old == null) {
          throw DbException('Cave place $id not found');
        }
        final now = DateTime.now().millisecondsSinceEpoch;
        final author = await _currentUser.currentOrSystem();
        final stamped = patch.copyWith(
          updatedAt: Value(now),
          lastModifiedByUserUuid: Value(author),
        );
        await (_database.update(_database.cavePlaces)
              ..where((cp) => cp.uuid.equalsValue(id)))
            .write(stamped);

        // Build new values map only for fields the caller actually set.
        final newValues = <String, Object?>{};
        final oldValues = <String, Object?>{};
        void cmp<T>(String col, Value<T> v, T oldVal) {
          if (v.present) {
            newValues[col] = v.value;
            oldValues[col] = oldVal;
          }
        }
        cmp('title', patch.title, old.title);
        cmp('description', patch.description, old.description);
        cmp('depth_in_cave', patch.depthInCave, old.depthInCave);
        cmp('place_qr_code_identifier',
            patch.placeQrCodeIdentifier, old.placeQrCodeIdentifier);
        cmp('latitude', patch.latitude, old.latitude);
        cmp('longitude', patch.longitude, old.longitude);
        cmp('altitude', patch.altitude, old.altitude);
        cmp('cave_area_uuid', patch.caveAreaUuid, old.caveAreaUuid);
        cmp('cave_uuid', patch.caveUuid, old.caveUuid);
        cmp('is_entrance', patch.isEntrance, old.isEntrance);
        cmp('is_main_entrance', patch.isMainEntrance, old.isMainEntrance);

        await _logger.logUpdate(
          'cave_places',
          id,
          oldValues: oldValues,
          newValues: newValues,
        );
      });
    } catch (e, st) {
      _log.severe('Failed to update cave place', e, st);
      throw DbException('Failed to update cave place',
          cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteCavePlace(Uuid id) async {
    try {
      await _database.transaction(() async {
        final old = await (_database.select(_database.cavePlaces)
              ..where((cp) => cp.uuid.equalsValue(id))
              ..limit(1))
            .getSingleOrNull();

        // Remove direct FK references from map bindings.
        await (_database.delete(_database.cavePlaceToRasterMapDefinitions)
              ..where((d) => d.cavePlaceUuid.equalsValue(id)))
            .go();

        // Keep trip points but detach from removed cave place.
        await (_database.update(_database.caveTripPoints)
              ..where((tp) => tp.cavePlaceUuid.equalsValue(id)))
            .write(const CaveTripPointsCompanion(cavePlaceUuid: Value(null)));

        // Remove pseudo links to this cave place from documentation links table.
        await (_database.delete(_database.documentationFilesToGeofeatures)
              ..where((g) =>
                  g.geofeatureType.equals('cave_place') &
                  g.geofeatureUuid.equalsValue(id)))
            .go();

        await (_database.delete(_database.cavePlaces)
              ..where((cp) => cp.uuid.equalsValue(id)))
            .go();

        if (old != null) {
          await _logger.logDelete('cave_places', id, oldValues: {
            'title': old.title,
            'description': old.description,
            'cave_uuid': old.caveUuid,
            'cave_area_uuid': old.caveAreaUuid,
          });
        }
      });
    } catch (e, st) {
      _log.severe('Failed to delete cave place', e, st);
      throw DbException('Failed to delete cave place', cause: e, stackTrace: st);
    }
  }

  @override
  Future<CavePlace?> findById(Uuid id) async {
    try {
      return await (_database.select(_database.cavePlaces)..where((cp) => cp.uuid.equalsValue(id))).getSingleOrNull();
    } catch (e, st) {
      _log.severe('Failed to find cave place', e, st);
      throw DbException('Failed to find cave place', cause: e, stackTrace: st);
    }
  }

  @override
  Future<CavePlace?> findCavePlaceByQrCode(int qrCode, Uuid caveUuid) async {
    try {
      final results = await (_database.select(_database.cavePlaces)
            ..where((cp) =>
                cp.placeQrCodeIdentifier.equals(qrCode) &
                cp.caveUuid.equalsValue(caveUuid)))
          .get();
      return results.firstOrNull;
    } catch (e, st) {
      _log.severe('Failed to find cave place by QR', e, st);
      throw DbException('Failed to find cave place by QR', cause: e, stackTrace: st);
    }
  }
}