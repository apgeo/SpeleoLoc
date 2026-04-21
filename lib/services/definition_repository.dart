import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Repository for [CavePlaceToRasterMapDefinition] — querying and persisting
/// the image-space coordinates that link a cave place to a raster map.
class DefinitionRepository implements IDefinitionRepository {
  final AppDatabase _database;
  final _log = AppLogger.of('DefinitionRepository');

  DefinitionRepository(this._database);

  @override
  Future<CavePlaceToRasterMapDefinition?> findDefinition(int cavePlaceId, int rasterMapId) async {
    try {
      return await _database.getDefinition(cavePlaceId, rasterMapId);
    } catch (e, st) {
      _log.severe('findDefinition error', e, st);
      rethrow;
    }
  }

  @override
  Future<List<CavePlaceWithDefinition>> getCavePlacesWithDefinitionsForRasterMap(int caveId, int rasterMapId) async {
    try {
      return await _database.getCavePlacesWithDefinitionsForRasterMap(caveId, rasterMapId);
    } catch (e, st) {
      _log.severe('getCavePlacesWithDefinitionsForRasterMap error', e, st);
      rethrow;
    }
  }

  /// Upsert a definition. Returns the persisted [CavePlaceToRasterMapDefinition].
  ///
  /// Wrapped in a transaction to prevent duplicate inserts from concurrent
  /// saves for the same (cavePlaceId, rasterMapId) pair.
  @override
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
    } catch (e, st) {
      _log.severe('saveDefinition error', e, st);
      rethrow;
    }
  }

  /// Delete the definition that links [cavePlaceId] to [rasterMapId].
  /// Returns `true` when a row was actually deleted.
  @override
  Future<bool> deleteDefinition(int cavePlaceId, int rasterMapId) async {
    try {
      final rows = await (_database.delete(_database.cavePlaceToRasterMapDefinitions)
            ..where((d) => d.cavePlaceId.equals(cavePlaceId) & d.rasterMapId.equals(rasterMapId)))
          .go();
      return rows > 0;
    } catch (e, st) {
      _log.severe('deleteDefinition error', e, st);
      rethrow;
    }
  }
}
