import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/cave_trip_repository.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/definition_repository.dart';
import 'package:speleoloc/services/documentation_repository.dart';
import 'package:speleoloc/services/raster_map_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_decision.dart';
import 'package:speleoloc/services/silexgis/silexgis_decisions_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_decisions.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_link_decisions.dart';
import 'package:speleoloc/services/silexgis/silexgis_feature_decisions.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_decisions.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_rows.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_version_reread.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_decisions.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_state_repository.dart';
import 'package:speleoloc/utils/clock.dart';

/// The decisions service with every section's resolver, wired the way the
/// application wires it.
SilexgisDecisionsService buildDecisionsService({
  required AppDatabase db,
  required ChangeLogger logger,
  required CurrentUserService currentUser,
  required SilexgisLocalStateRepository localState,
  required SilexgisHeldRowRepository heldRows,
  Clock clock = const SystemClock(),
}) {
  final reread = SilexgisServerVersionReread(
    localState: localState,
    heldRows: heldRows,
  );
  final caves = CaveRepository(db, currentUser, logger, clock: clock);
  final places = CavePlaceRepository(db, currentUser, logger, clock: clock);
  final placer = buildSilexgisServerRowPlacer(
    db: db,
    logger: logger,
    localState: localState,
    heldRows: heldRows,
    caves: caves,
    places: places,
    catalogue: SilexgisDocumentCatalogueRepository(db),
    trips: SilexgisTripStateRepository(db),
    rasters: SilexgisRasterStateRepository(db),
    clock: clock,
  );
  final tripService = CaveTripService(
    db,
    logger,
    currentUser,
    ConfigurationRepository(db),
    clock: clock,
  );
  return SilexgisDecisionsService(
    localState: localState,
    heldRows: heldRows,
    resolvers: <SilexgisDecisionResolver>[
      SilexgisFeatureDecisions(
        db: db,
        reread: reread,
        placer: placer,
        caves: caves,
        places: places,
      ),
      SilexgisDocumentDecisions(
        db: db,
        reread: reread,
        placer: placer,
        documents: DocumentationRepository(db, logger, currentUser),
      ),
      SilexgisDocumentLinkDecisions(
        db: db,
        logger: logger,
        reread: reread,
        placer: placer,
      ),
      SilexgisTripDecisions(
        db: db,
        reread: reread,
        placer: placer,
        trips: CaveTripRepository(db, logger),
        removeScan: tripService.deletePoint,
      ),
      SilexgisRasterDecisions(
        db: db,
        reread: reread,
        placer: placer,
        maps: RasterMapRepository(db, currentUser, logger, clock: clock),
        pins: DefinitionRepository(db, currentUser, logger, clock: clock),
      ),
    ],
  );
}
