import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_decision.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_row_lookup.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_version_reread.dart';

/// Decisions about raster maps and their pins.
///
/// No answer about a map carries the server's version of it, so going back to
/// it means reading the rasters stream again from the beginning. A pin is
/// named after its map and the place it marks. A pin refused because another
/// already marks its place can be removed, and the next read then brings the
/// one the installation holds.
class SilexgisRasterDecisions implements SilexgisDecisionResolver {
  SilexgisRasterDecisions({
    required AppDatabase db,
    required SilexgisServerVersionReread reread,
    required IRasterMapRepository maps,
    required IDefinitionRepository pins,
  }) : _db = db,
       _reread = reread,
       _maps = maps,
       _pins = pins,
       _mapRows = SilexgisLocalRowLookup(
         db,
         tables: const <String>{SilexgisRasterTables.maps},
       );

  final AppDatabase _db;
  final SilexgisServerVersionReread _reread;
  final IRasterMapRepository _maps;
  final IDefinitionRepository _pins;
  final SilexgisLocalRowLookup _mapRows;

  @override
  Set<SyncUploadSection> get sections => const <SyncUploadSection>{
    SyncUploadSection.rasterMaps,
    SyncUploadSection.rasterPins,
  };

  @override
  Future<String?> title(SilexgisHeldItem held) async {
    if (held.entityTable == SilexgisRasterTables.maps) {
      return (await _mapRows.read(held.entityTable, held.entityUuid))?.title;
    }
    final pin = await _pin(held.entityUuid);
    if (pin == null) return null;
    return '${pin.read<String>('map')} · ${pin.read<String>('place')}';
  }

  @override
  Future<bool> isNew(
    SilexgisHeldItem held,
    Map<Uuid, StoredRevision> revisions,
  ) async => !revisions.containsKey(held.entityUuid);

  @override
  Future<bool> useServerVersion(
    SilexgisProfile profile,
    SilexgisHeldItem held,
  ) async {
    await _reread.giveUp(
      profile.profileUuid,
      held,
      localUpdatedAt: held.entityTable == SilexgisRasterTables.maps
          ? (await _mapRows.read(held.entityTable, held.entityUuid))?.updatedAt
          : (await _pin(held.entityUuid))?.read<int?>('updated_at'),
    );
    await _reread.rereadFromBeginning(profile, SyncStream.rasters);
    return false;
  }

  @override
  Future<void> delete(SilexgisProfile profile, SilexgisHeldItem held) async {
    if (held.entityTable == SilexgisRasterTables.maps) {
      await _pins.deleteAllDefinitionsForRasterMap(held.entityUuid);
      await _maps.deleteRasterMap(held.entityUuid);
      return;
    }
    final pin = await _pin(held.entityUuid);
    if (pin == null) return;
    await _pins.deleteDefinition(
      Uuid.fromBytes(pin.read<Uint8List>('place_uuid')),
      Uuid.fromBytes(pin.read<Uint8List>('map_uuid')),
    );
    if (held.code == SilexgisCodes.pinExists) {
      // The pin already on the server for that place arrives with the next
      // read of the whole stream.
      await _reread.rereadFromBeginning(profile, SyncStream.rasters);
    }
  }

  Future<QueryRow?> _pin(Uuid uuid) async {
    final rows = await _db
        .customSelect(
          'SELECT m.title AS map, c.title AS place, d.updated_at AS updated_at, '
          'd.cave_place_uuid AS place_uuid, d.raster_map_uuid AS map_uuid '
          'FROM cave_place_to_raster_map_definitions d '
          'JOIN raster_maps m ON m.uuid = d.raster_map_uuid '
          'JOIN cave_places c ON c.uuid = d.cave_place_uuid '
          'WHERE d.uuid = ? LIMIT 1',
          variables: <Variable<Object>>[Variable<Uint8List>(uuid.bytes)],
        )
        .get();
    return rows.isEmpty ? null : rows.single;
  }
}
