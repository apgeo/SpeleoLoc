import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:drift/drift.dart';

class CavePlaceRepository {
  final AppDatabase _database;

  CavePlaceRepository(this._database);

  Future<List<CavePlace>> getCavePlaces(int caveId) async {
    try {
      return await (_database.select(_database.cavePlaces)..where((cp) => cp.caveId.equals(caveId))).get();
    } catch (e) {
      print('[CavePlaceRepository] Failed to load cave places: $e');
      rethrow;
    }
  }

  Future<void> addCavePlace(int caveId, String title) async {
    try {
      await _database.into(_database.cavePlaces).insert(
        CavePlacesCompanion.insert(
          title: title,
          caveId: caveId
        ),
      );
    } catch (e) {
      print('[CavePlaceRepository] Failed to add cave place: $e');
      rethrow;
    }
  }

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
    } catch (e) {
      print('[CavePlaceRepository] Failed to delete cave place: $e');
      rethrow;
    }
  }

  Future<CavePlace?> findById(int id) async {
    try {
      return await (_database.select(_database.cavePlaces)..where((cp) => cp.id.equals(id))).getSingleOrNull();
    } catch (e) {
      print('[CavePlaceRepository] Failed to find cave place: $e');
      rethrow;
    }
  }

  Future<CavePlace?> findCavePlaceByQrCode(int qrCode, int caveId) async {
    try {
      return await (_database.select(_database.cavePlaces)
            ..where((cp) =>
                cp.placeQrCodeIdentifier.equals(qrCode) &
                cp.caveId.equals(caveId)))
          .getSingleOrNull();
    } catch (e) {
      print('[CavePlaceRepository] Failed to find cave place by QR: $e');
      rethrow;
    }
  }
}