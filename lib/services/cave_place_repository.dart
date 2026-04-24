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
  Future<void> addCavePlace(Uuid caveUuid, String title) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final author = await _currentUser.currentOrSystem();
      final newUuid = Uuid.v7();
      await _database.into(_database.cavePlaces).insert(
        CavePlacesCompanion.insert(
          uuid: newUuid,
          title: title,
          caveUuid: caveUuid,
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
  Future<void> deleteCavePlace(Uuid id) async {
    try {
      await _database.transaction(() async {
        // initial delete mechanism
        //await (_database.delete(_database.cavePlaces)..where((cp) => cp.uuid.equalsValue(id))).go();

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