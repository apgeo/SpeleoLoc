import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_rasters.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_row_composer.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_upload_answers.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_part.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// The `rasterPins` section: the pins this run creates, moves or removes.
///
/// Built after the maps part. A pin goes up when its map is on the
/// installation, waits there for a reviewer, or goes in this run; when the
/// place it marks is on the installation or goes in this run; and when its
/// pixel is one the installation takes.
///
/// A pin removed here is sent as a removal naming its map. When the whole map
/// was removed, its pins go with it and are not named.
class SilexgisRasterPinsUploadPart implements SilexgisUploadPart {
  SilexgisRasterPinsUploadPart({
    required AppDatabase db,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required SilexgisRasterStateRepository rasters,
    required SilexgisRasterUploadAnswers answers,
    required String profileUuid,
    SilexgisRasterRowComposer composer = const SilexgisRasterRowComposer(),
  }) : _db = db,
       _localState = localState,
       _heldRows = heldRows,
       _rasters = rasters,
       _answers = answers,
       _profileUuid = profileUuid,
       _composer = composer;

  final AppDatabase _db;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final SilexgisRasterStateRepository _rasters;
  final SilexgisRasterUploadAnswers _answers;
  final String _profileUuid;
  final SilexgisRasterRowComposer _composer;
  final _log = AppLogger.of('SilexgisRasterPinsUploadPart');

  final Map<String, SilexgisPlannedRasterItem> _planned =
      <String, SilexgisPlannedRasterItem>{};

  @override
  SyncUploadSection get section => SyncUploadSection.rasterPins;

  @override
  Future<List<SyncUploadItem>> build(SilexgisUploadContext context) async {
    final revisions = await _localState.readRevisions(_profileUuid);
    final held = await _heldRows.readSection(_profileUuid, section);
    final heldMaps = await _heldRows.readSection(
      _profileUuid,
      SyncUploadSection.rasterMaps,
    );
    final maps = <Uuid>{
      for (final e in revisions.entries)
        if (e.value.entityTable == SilexgisRasterTables.maps) e.key,
      ...context.rasterMapsSent,
      ...heldMaps.keys,
    };
    final places = <Uuid>{
      for (final e in revisions.entries)
        if (e.value.entityTable == 'cave_places') e.key,
      ...context.rowsSent,
    };

    final items = <SyncUploadItem>[];
    final present = <Uuid>{};
    for (final pin
        in await _db.select(_db.cavePlaceToRasterMapDefinitions).get()) {
      present.add(pin.uuid);
      if (!maps.contains(pin.rasterMapUuid)) continue;
      if (!places.contains(pin.cavePlaceUuid)) continue;
      if (!SyncUploadRasterPin.isPixel(pin.xCoordinate) ||
          !SyncUploadRasterPin.isPixel(pin.yCoordinate)) {
        continue;
      }
      final stored = switch (revisions[pin.uuid]) {
        final r? when r.entityTable == SilexgisRasterTables.pins => r,
        _ => null,
      };
      if (stored != null && stored.agreesWith(pin.updatedAt)) continue;
      if (held[pin.uuid]?.stillAsSent(pin.updatedAt) ?? false) continue;

      final item = _composer.pin(pin, baseRevision: stored?.revision);
      _planned[item.id] = SilexgisPlannedRasterItem(
        id: pin.uuid,
        mapId: pin.rasterMapUuid,
        isPin: true,
        localUpdatedAt: pin.updatedAt,
      );
      items.add(item);
    }

    final states = await _rasters.readAll(_profileUuid);
    final liveMaps = <Uuid>{
      for (final map in await _db.select(_db.rasterMaps).get()) map.uuid,
    };
    final orphans = <Uuid>[];
    for (final entry in revisions.entries) {
      if (entry.value.entityTable != SilexgisRasterTables.pins) continue;
      if (present.contains(entry.key)) continue;
      if (held[entry.key]?.isDelete ?? false) continue;
      final map = states[entry.key]?.mapUuid;
      if (map == null) {
        // Nothing here can name its map any more, and a removal without one
        // is refused whole.
        _log.warning('a removed pin names no map; forgetting it');
        orphans.add(entry.key);
        continue;
      }
      // The map's own removal takes it.
      if (!liveMaps.contains(map)) continue;
      final item = SyncUploadRasterPin.delete(
        id: entry.key.toString(),
        rasterMapId: map.toString(),
        baseRevision: entry.value.revision,
      );
      _planned[item.id] = SilexgisPlannedRasterItem(
        id: entry.key,
        mapId: map,
        isPin: true,
        isDelete: true,
      );
      items.add(item);
    }
    await _localState.forgetRevisions(_profileUuid, orphans);
    return items;
  }

  @override
  Future<SilexgisPartAnswers> apply(
    List<SyncUploadItem> sent,
    List<SyncRowResult> answers, {
    required bool resent,
  }) => _answers.apply(section, _planned, answers);
}
