import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/utils/app_exceptions.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Repository for [CavePlaceToRasterMapDefinition] — querying and persisting
/// the image-space coordinates that link a cave place to a raster map.
class DefinitionRepository implements IDefinitionRepository {
  final AppDatabase _database;
  final CurrentUserService _currentUser;
  final ChangeLogger _logger;
  final _log = AppLogger.of('DefinitionRepository');

  DefinitionRepository(this._database, this._currentUser, this._logger);

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
        final now = DateTime.now().millisecondsSinceEpoch;
        final author = await _currentUser.currentOrSystem();
        final existing = await findDefinition(cavePlaceUuid, rasterMapUuid);
        if (existing != null) {
          await (_database.update(_database.cavePlaceToRasterMapDefinitions)
                ..where((d) => d.uuid.equalsValue(existing.uuid)))
              .write(CavePlaceToRasterMapDefinitionsCompanion(
            xCoordinate: Value(imageX.toInt()),
            yCoordinate: Value(imageY.toInt()),
            updatedAt: Value(now),
            lastModifiedByUserUuid: Value(author),
          ));
          await _logger.logUpdate(
            'cave_place_to_raster_map_definitions',
            existing.uuid,
            oldValues: {
              'x_coordinate': existing.xCoordinate,
              'y_coordinate': existing.yCoordinate,
            },
            newValues: {
              'x_coordinate': imageX.toInt(),
              'y_coordinate': imageY.toInt(),
            },
          );
          return (await findDefinition(cavePlaceUuid, rasterMapUuid))!;
        } else {
          final newUuid = Uuid.v7();
          final companion = CavePlaceToRasterMapDefinitionsCompanion.insert(
            uuid: newUuid,
            xCoordinate: Value(imageX.toInt()),
            yCoordinate: Value(imageY.toInt()),
            cavePlaceUuid: cavePlaceUuid,
            rasterMapUuid: rasterMapUuid,
            createdAt: Value(now),
            updatedAt: Value(now),
            createdByUserUuid: Value(author),
            lastModifiedByUserUuid: Value(author),
          );
          await _database
              .into(_database.cavePlaceToRasterMapDefinitions)
              .insert(companion);
          await _logger.logInsert(
              'cave_place_to_raster_map_definitions', newUuid);
          return (await findDefinition(cavePlaceUuid, rasterMapUuid))!;
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
      final old = await (_database.select(_database.cavePlaceToRasterMapDefinitions)
            ..where((d) =>
                d.cavePlaceUuid.equalsValue(cavePlaceUuid) &
                d.rasterMapUuid.equalsValue(rasterMapUuid))
            ..limit(1))
          .getSingleOrNull();
      final rows = await (_database.delete(_database.cavePlaceToRasterMapDefinitions)
            ..where((d) => d.cavePlaceUuid.equalsValue(cavePlaceUuid) & d.rasterMapUuid.equalsValue(rasterMapUuid)))
          .go();
      if (rows > 0 && old != null) {
        await _logger.logDelete(
          'cave_place_to_raster_map_definitions',
          old.uuid,
          oldValues: {
            'cave_place_uuid': old.cavePlaceUuid,
            'raster_map_uuid': old.rasterMapUuid,
            'x_coordinate': old.xCoordinate,
            'y_coordinate': old.yCoordinate,
          },
        );
      }
      return rows > 0;
    } catch (e, st) {
      _log.severe('deleteDefinition error', e, st);
      throw DbException('Failed to delete definition', cause: e, stackTrace: st);
    }
  }
}
