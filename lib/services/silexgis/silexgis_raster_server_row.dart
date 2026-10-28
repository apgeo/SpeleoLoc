import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/silexgis/model/sync_download_page.dart';
import 'package:speleoloc/services/silexgis/model/sync_rasters.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_row_handler.dart';
import 'package:speleoloc/utils/clock.dart';

/// The server's row of a raster map — with its pins — or of one pin, written
/// by the rasters stream's applier.
///
/// A pin comes without its map, so it is written on the one this device holds
/// it on, or held it on before the caver removed it. A map's new picture is
/// fetched by the next run, as one a read brings is.
class SilexgisRasterServerRow implements SilexgisServerRowHandler {
  SilexgisRasterServerRow({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required SilexgisRasterStateRepository rasters,
    required SilexgisDocumentCatalogueRepository catalogue,
    Clock clock = const SystemClock(),
  }) : _db = db,
       _logger = logger,
       _localState = localState,
       _heldRows = heldRows,
       _rasters = rasters,
       _catalogue = catalogue,
       _clock = clock;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final SilexgisRasterStateRepository _rasters;
  final SilexgisDocumentCatalogueRepository _catalogue;
  final Clock _clock;

  @override
  Set<SyncUploadSection> get sections => const <SyncUploadSection>{
    SyncUploadSection.rasterMaps,
    SyncUploadSection.rasterPins,
  };

  @override
  SyncStream get stream => SyncStream.rasters;

  @override
  Future<bool> write(
    String profileUuid,
    SilexgisHeldItem held,
    Map<String, Object?> current,
  ) async {
    final applier = SilexgisRasterApplier(
      db: _db,
      logger: _logger,
      localState: _localState,
      heldRows: _heldRows,
      rasters: _rasters,
      catalogue: _catalogue,
      profileUuid: profileUuid,
      clock: _clock,
    );
    if (held.section == SyncUploadSection.rasterMaps) {
      final applied = await applier.applyPage(
        SyncRastersPage(
          setRevision: 0,
          maps: <SyncRasterMap>[SyncRasterMap.fromJson(current)],
          tombstones: const <SyncTombstone>[],
          // The decision hands over the map, not its removed pins: those come
          // on the stream, and a pin merely missing here is kept.
          pinTombstones: const <SyncPinTombstone>[],
          nextCursor: null,
          hasMore: false,
        ),
      );
      return applied.mapsInserted + applied.mapsUpdated > 0;
    }
    final map = await _mapOf(profileUuid, held.entityUuid);
    if (map == null) return false;
    final applied = await applier.applyPin(
      map,
      SyncRasterPin.fromJson(current),
    );
    return applied.pinsInserted + applied.pinsUpdated > 0;
  }

  Future<Uuid?> _mapOf(String profileUuid, Uuid pin) async =>
      (await (_db.select(
            _db.cavePlaceToRasterMapDefinitions,
          )..where((t) => t.uuid.equalsValue(pin))).getSingleOrNull())
          ?.rasterMapUuid ??
      (await _rasters.readAll(profileUuid))[pin]?.mapUuid;
}
