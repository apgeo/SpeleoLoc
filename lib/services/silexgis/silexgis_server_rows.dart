import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_link_server_row.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_server_row.dart';
import 'package:speleoloc/services/silexgis/silexgis_feature_server_row.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_server_row.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_row_handler.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_row_placer.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_version_reread.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_server_row.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_state_repository.dart';
import 'package:speleoloc/utils/clock.dart';

/// The placer with every section's handler, so the decisions page and the
/// review read put the server's rows back the same way.
SilexgisServerRowPlacer buildSilexgisServerRowPlacer({
  required AppDatabase db,
  required ChangeLogger logger,
  required SilexgisLocalStateRepository localState,
  required SilexgisHeldRowRepository heldRows,
  required ICaveRepository caves,
  required ICavePlaceRepository places,
  required SilexgisDocumentCatalogueRepository catalogue,
  required SilexgisTripStateRepository trips,
  required SilexgisRasterStateRepository rasters,
  Clock clock = const SystemClock(),
}) => SilexgisServerRowPlacer(
  reread: SilexgisServerVersionReread(
    localState: localState,
    heldRows: heldRows,
  ),
  handlers: <SilexgisServerRowHandler>[
    SilexgisFeatureServerRow(
      db: db,
      logger: logger,
      localState: localState,
      heldRows: heldRows,
      caves: caves,
      places: places,
    ),
    SilexgisDocumentServerRow(
      db: db,
      logger: logger,
      localState: localState,
      catalogue: catalogue,
      clock: clock,
    ),
    SilexgisDocumentLinkServerRow(
      db: db,
      logger: logger,
      localState: localState,
      catalogue: catalogue,
      clock: clock,
    ),
    SilexgisTripServerRow(
      db: db,
      logger: logger,
      localState: localState,
      heldRows: heldRows,
      trips: trips,
      clock: clock,
    ),
    SilexgisRasterServerRow(
      db: db,
      logger: logger,
      localState: localState,
      heldRows: heldRows,
      rasters: rasters,
      catalogue: catalogue,
      clock: clock,
    ),
  ],
);
