import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

/// Repository for [CavePlaceToRasterMapDefinition] — querying and persisting
/// the image-space coordinates that link a cave place to a raster map.
class DefinitionRepository {
  final AppDatabase _database;

  DefinitionRepository(this._database);

  Future<CavePlaceToRasterMapDefinition?> findDefinition(int cavePlaceId, int rasterMapId) async {
    try {
      return await _database.getDefinition(cavePlaceId, rasterMapId);
    } catch (e) {
      print('[DefinitionRepository] findDefinition error: $e');
      rethrow;
    }
  }

  Future<List<CavePlaceWithDefinition>> getCavePlacesWithDefinitionsForRasterMap(int caveId, int rasterMapId) async {
    try {
      return await _database.getCavePlacesWithDefinitionsForRasterMap(caveId, rasterMapId);
    } catch (e) {
      print('[DefinitionRepository] getCavePlacesWithDefinitionsForRasterMap error: $e');
      rethrow;
    }
  }

  /// Upsert a definition. Returns the persisted [CavePlaceToRasterMapDefinition].
  ///
  /// Wrapped in a transaction to prevent duplicate inserts from concurrent
  /// saves for the same (cavePlaceId, rasterMapId) pair.
  Future<CavePlaceToRasterMapDefinition> saveDefinition(
    int cavePlaceId,
    int rasterMapId,
    double imageX,
    double imageY,
  ) async {
    try {
      return await _database.transaction(() async {
        final existing = await findDefinition(cavePlaceId, rasterMapId);
        if (existing != null) {
          final updated = CavePlaceToRasterMapDefinition(
            id: existing.id,
            xCoordinate: imageX.toInt(),
            yCoordinate: imageY.toInt(),
            cavePlaceId: cavePlaceId,
            rasterMapId: rasterMapId,
          );
          await _database.update(_database.cavePlaceToRasterMapDefinitions).replace(updated);
          return updated;
        } else {
          final companion = CavePlaceToRasterMapDefinitionsCompanion(
            xCoordinate: Value(imageX.toInt()),
            yCoordinate: Value(imageY.toInt()),
            cavePlaceId: Value(cavePlaceId),
            rasterMapId: Value(rasterMapId),
          );
          final newId = await _database.into(_database.cavePlaceToRasterMapDefinitions).insert(companion);
          return CavePlaceToRasterMapDefinition(
            id: newId,
            xCoordinate: imageX.toInt(),
            yCoordinate: imageY.toInt(),
            cavePlaceId: cavePlaceId,
            rasterMapId: rasterMapId,
          );
        }
      });
    } catch (e) {
      print('[DefinitionRepository] saveDefinition error: $e');
      rethrow;
    }
  }

  /// Delete the definition that links [cavePlaceId] to [rasterMapId].
  /// Returns `true` when a row was actually deleted.
  Future<bool> deleteDefinition(int cavePlaceId, int rasterMapId) async {
    try {
      final rows = await (_database.delete(_database.cavePlaceToRasterMapDefinitions)
            ..where((d) => d.cavePlaceId.equals(cavePlaceId) & d.rasterMapId.equals(rasterMapId)))
          .go();
      return rows > 0;
    } catch (e) {
      print('[DefinitionRepository] deleteDefinition error: $e');
      rethrow;
    }
  }
}
