import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/utils/app_logger.dart';

class CavePlaceRepository implements ICavePlaceRepository {
  final AppDatabase _database;
  final _log = AppLogger.of('CavePlaceRepository');

  CavePlaceRepository(this._database);

  @override
  Future<List<CavePlace>> getCavePlaces(int caveId) async {
    try {
      return await (_database.select(_database.cavePlaces)..where((cp) => cp.caveId.equals(caveId))).get();
    } catch (e, st) {
      _log.severe('Failed to load cave places', e, st);
      rethrow;
    }
  }

  @override
  Stream<List<CavePlace>> watchCavePlaces(int caveId) {
    return (_database.select(_database.cavePlaces)
          ..where((cp) => cp.caveId.equals(caveId)))
        .watch();
  }

  @override
  Future<void> addCavePlace(int caveId, String title) async {
    try {
      await _database.into(_database.cavePlaces).insert(
        CavePlacesCompanion.insert(
          title: title,
          caveId: caveId
        ),
      );
    } catch (e, st) {
      _log.severe('Failed to add cave place', e, st);
      rethrow;
    }
  }

  @override
  Future<void> deleteCavePlace(int id) async {
    try {
      await _database.transaction(() async {
        // initial delete mechanism
        //await (_database.delete(_database.cavePlaces)..where((cp) => cp.id.equals(id))).go();

        // Remove direct FK references from map bindings.
        await (_database.delete(_database.cavePlaceToRasterMapDefinitions)
              ..where((d) => d.cavePlaceId.equals(id)))
            .go();

        // Keep trip points but detach from removed cave place.
        await (_database.update(_database.caveTripPoints)
              ..where((tp) => tp.cavePlaceId.equals(id)))
            .write(const CaveTripPointsCompanion(cavePlaceId: Value(null)));

        // Remove pseudo links to this cave place from documentation links table.
        await (_database.delete(_database.documentationFilesToGeofeatures)
              ..where((g) =>
                  g.geofeatureType.equals('cave_place') &
                  g.geofeatureId.equals(id)))
            .go();

        await (_database.delete(_database.cavePlaces)
              ..where((cp) => cp.id.equals(id)))
            .go();
      });
    } catch (e, st) {
      _log.severe('Failed to delete cave place', e, st);
      rethrow;
    }
  }

  @override
  Future<CavePlace?> findById(int id) async {
    try {
      return await (_database.select(_database.cavePlaces)..where((cp) => cp.id.equals(id))).getSingleOrNull();
    } catch (e, st) {
      _log.severe('Failed to find cave place', e, st);
      rethrow;
    }
  }

  @override
  Future<CavePlace?> findCavePlaceByQrCode(int qrCode, int caveId) async {
    try {
      return await (_database.select(_database.cavePlaces)
            ..where((cp) =>
                cp.placeQrCodeIdentifier.equals(qrCode) &
                cp.caveId.equals(caveId)))
          .getSingleOrNull();
    } catch (e, st) {
      _log.severe('Failed to find cave place by QR', e, st);
      rethrow;
    }
  }
}