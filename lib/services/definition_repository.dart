import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/utils/app_exceptions.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Repository for [CavePlaceToRasterMapDefinition] — querying and persisting
/// the image-space coordinates that link a cave place to a raster map.
class DefinitionRepository implements IDefinitionRepository {
  final AppDatabase _database;
  final _log = AppLogger.of('DefinitionRepository');

  DefinitionRepository(this._database);

  @override
  Future<CavePlaceToRasterMapDefinition?> findDefinition(Uuid cavePlaceUuid, Uuid rasterMapUuid) async {
    try {
      return await _database.getDefinition(cavePlaceUuid, rasterMapUuid);
    } catch (e, st) {
      _log.severe('findDefinition error', e, st);
      throw DbException('Failed to find definition', cause: e, stackTrace: st);
    }
  }

  @override
  Future<List<CavePlaceWithDefinition>> getCavePlacesWithDefinitionsForRasterMap(Uuid caveUuid, Uuid rasterMapUuid) async {
    try {
      return await _database.getCavePlacesWithDefinitionsForRasterMap(caveUuid, rasterMapUuid);
    } catch (e, st) {
      _log.severe('getCavePlacesWithDefinitionsForRasterMap error', e, st);
      throw DbException(
        'Failed to load cave-place definitions',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Upsert a definition. Returns the persisted [CavePlaceToRasterMapDefinition].
  ///
  /// Wrapped in a transaction to prevent duplicate inserts from concurrent
  /// saves for the same (cavePlaceUuid, rasterMapUuid) pair.
  @override
  Future<CavePlaceToRasterMapDefinition> saveDefinition(
    Uuid cavePlaceUuid,
    Uuid rasterMapUuid,
    double imageX,
    double imageY,
  ) async {
    try {
      return await _database.transaction(() async {
        final existing = await findDefinition(cavePlaceUuid, rasterMapUuid);
        if (existing != null) {
          final updated = CavePlaceToRasterMapDefinition(
            uuid: existing.uuid,
            xCoordinate: imageX.toInt(),
            yCoordinate: imageY.toInt(),
            cavePlaceUuid: cavePlaceUuid,
            rasterMapUuid: rasterMapUuid,
          );
          await _database.update(_database.cavePlaceToRasterMapDefinitions).replace(updated);
          return updated;
        } else {
          final newUuid = Uuid.v7();
          final companion = CavePlaceToRasterMapDefinitionsCompanion.insert(
            uuid: newUuid,
            xCoordinate: Value(imageX.toInt()),
            yCoordinate: Value(imageY.toInt()),
            cavePlaceUuid: cavePlaceUuid,
            rasterMapUuid: rasterMapUuid,
          );
          await _database.into(_database.cavePlaceToRasterMapDefinitions).insert(companion);
          return CavePlaceToRasterMapDefinition(
            uuid: newUuid,
            xCoordinate: imageX.toInt(),
            yCoordinate: imageY.toInt(),
            cavePlaceUuid: cavePlaceUuid,
            rasterMapUuid: rasterMapUuid,
          );
        }
      });
    } catch (e, st) {
      _log.severe('saveDefinition error', e, st);
      throw DbException('Failed to save definition', cause: e, stackTrace: st);
    }
  }

  /// Delete the definition that links [cavePlaceUuid] to [rasterMapUuid].
  /// Returns `true` when a row was actually deleted.
  @override
  Future<bool> deleteDefinition(Uuid cavePlaceUuid, Uuid rasterMapUuid) async {
    try {
      final rows = await (_database.delete(_database.cavePlaceToRasterMapDefinitions)
            ..where((d) => d.cavePlaceUuid.equalsValue(cavePlaceUuid) & d.rasterMapUuid.equalsValue(rasterMapUuid)))
          .go();
      return rows > 0;
    } catch (e, st) {
      _log.severe('deleteDefinition error', e, st);
      throw DbException('Failed to delete definition', cause: e, stackTrace: st);
    }
  }
}
