import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/beacon/beacon_repository.dart';
import 'package:speleoloc/services/ruuvi/ruuvi_history_repository.dart';
import 'package:speleoloc/services/ruuvi/ruuvi_history_service.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/cave_document_import_service.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/cave_trip_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/definition_repository.dart';
import 'package:speleoloc/services/documentation_byte_edit_service.dart';
import 'package:speleoloc/services/documentation_repository.dart';
import 'package:speleoloc/services/cave_geo_service.dart';
import 'package:speleoloc/services/location/location_service.dart';
import 'package:speleoloc/services/network/connectivity_network_kind_probe.dart';
import 'package:speleoloc/services/network/network_kind_probe.dart';
import 'package:speleoloc/services/geo_transfer/place_transfer_service.dart';
import 'package:speleoloc/services/map/mbtiles_registry.dart';
import 'package:speleoloc/services/map/tile_disk_cache.dart';
import 'package:speleoloc/services/place_code/batch/place_code_batch_runner.dart';
import 'package:speleoloc/services/place_code/place_code_service.dart';
import 'package:speleoloc/services/range_code_generator.dart';
import 'package:speleoloc/services/qr_code_lookup_service.dart';
import 'package:speleoloc/services/raster_map_repository.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/trip_media/media_scan_cache.dart';
import 'package:speleoloc/services/trip_media/trip_media_import_service.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile_repository.dart';
import 'package:speleoloc/services/sync/ftp/ftp_sync_controller.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/silexgis_decision.dart';
import 'package:speleoloc/services/silexgis/silexgis_decisions_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_decisions.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_downloader.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_file_store.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_importer.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_link_decisions.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_linker.dart';
import 'package:speleoloc/services/silexgis/silexgis_documents_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_feature_decisions.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_fetcher.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_map_picture_copies.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_decisions.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_link_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_rows.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_version_reread.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_controller.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_decisions.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_origin_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_state_repository.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/state/app_notifiers.dart';
import 'package:speleoloc/widgets/qr_code_lookup_handler.dart';
import 'package:speleoloc/utils/clock.dart';

/// Central place that wires all app-wide dependencies via Riverpod.
///
/// Every concrete dependency (database, repositories, services) is exposed as
/// a `Provider<Interface>` so tests can override wholesale via
/// `ProviderScope(overrides: [...])` without touching production wiring.

/// The single [AppDatabase] instance.
///
/// During the migration away from the legacy global `appDatabase`, this
/// provider returns the same instance. Tests override with an in-memory DB.
final appDatabaseProvider = Provider<AppDatabase>((ref) => appDatabase);

/// Wall-clock source. Override in tests with a [FakeClock] to make
/// timestamp-sensitive logic deterministic.
final clockProvider = Provider<Clock>((ref) => const SystemClock());

/// Key/value access to the `configurations` table. See
/// [IConfigurationRepository] for the contract.
final configurationRepositoryProvider = Provider<IConfigurationRepository>(
  (ref) => ConfigurationRepository(ref.watch(appDatabaseProvider)),
);

final caveRepositoryProvider = Provider<ICaveRepository>(
  (ref) => CaveRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(currentUserServiceProvider),
    ref.watch(changeLoggerProvider),
    clock: ref.watch(clockProvider),
  ),
);

final userRepositoryProvider = Provider<IUserRepository>(_buildUserRepository);

IUserRepository _buildUserRepository(Ref ref) => UserRepository(
  ref.watch(appDatabaseProvider),
  () => ref.read(changeLoggerProvider),
);

final currentUserServiceProvider = Provider<CurrentUserService>((ref) {
  final svc = CurrentUserService(
    ref.watch(appDatabaseProvider),
    ref.watch(userRepositoryProvider),
    ref.watch(configurationRepositoryProvider),
  );
  // Fire-and-forget init; readers that need the values before init finishes
  // should await `svc.initialize()` themselves.
  svc.initialize();
  return svc;
});

final changeLoggerProvider = Provider<ChangeLogger>(
  (ref) => ChangeLogger(
    ref.watch(appDatabaseProvider),
    ref.watch(currentUserServiceProvider),
    clock: ref.watch(clockProvider),
  ),
);

final syncArchiveServiceProvider = Provider<SyncArchiveService>(
  (ref) => SyncArchiveService(
    ref.watch(appDatabaseProvider),
    ref.watch(changeLoggerProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Stores configured FTP/SFTP endpoints plus their passwords (passwords are
/// kept in the OS keystore, not in the SQLite DB).
final ftpProfileRepositoryProvider = Provider<FtpProfileRepository>(
  (ref) => FtpProfileRepository(ref.watch(appDatabaseProvider)),
);

/// Singleton orchestrator for one-tap FTP sync. Exposed as a ChangeNotifier
/// so UI can react to live progress via `ref.watch(...).progress`.
final ftpSyncControllerProvider = ChangeNotifierProvider<FtpSyncController>(
  (ref) => FtpSyncController(
    db: ref.watch(appDatabaseProvider),
    profileRepository: ref.watch(ftpProfileRepositoryProvider),
    archiveService: ref.watch(syncArchiveServiceProvider),
    currentUserService: ref.watch(currentUserServiceProvider),
  ),
);

// -----------------------------------------------------------------------------
// SilexGIS server sync. Entirely optional: with no profile configured every one
// of these is inert and the application behaves exactly as it does with no
// server in the world. Deliberately separate from the FTP wiring above — the
// two channels work independently and neither impersonates the other.
// -----------------------------------------------------------------------------

/// A server profile's refresh token, in the OS keystore rather than in the
/// database a plaintext export would carry off.
final silexgisTokenStoreProvider = Provider<SilexgisRefreshTokenStore>(
  (ref) => SilexgisSecureTokenStore(),
);

/// This device's download position and per-row server revisions. Local-only:
/// none of it leaves the device except back to the installation that issued it.
final silexgisLocalStateProvider = Provider<SilexgisLocalStateRepository>(
  (ref) => SilexgisLocalStateRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Rows an installation holds for a reviewer, and the decisions on them.
/// Local-only, like the rest of this device's SilexGIS state.
final silexgisHeldRowsProvider = Provider<SilexgisHeldRowRepository>(
  (ref) => SilexgisHeldRowRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// An installation's people directory and this device's choice of caver per
/// phone user. Local-only.
final silexgisPeopleRepositoryProvider = Provider<SilexgisPeopleRepository>(
  (ref) => SilexgisPeopleRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// An installation's photo and document catalogue. Local-only, metadata only.
final silexgisDocumentCatalogueProvider =
    Provider<SilexgisDocumentCatalogueRepository>(
      (ref) =>
          SilexgisDocumentCatalogueRepository(ref.watch(appDatabaseProvider)),
    );

/// Saves an editor's new content of a documentation file — in place, or as a
/// new document when the file is a server copy that is not the file itself.
final documentationByteEditServiceProvider =
    Provider<DocumentationByteEditService>(
      (ref) => DocumentationByteEditService(
        db: ref.watch(appDatabaseProvider),
        logger: ref.watch(changeLoggerProvider),
        currentUser: ref.watch(currentUserServiceProvider),
        copies: ref.watch(silexgisFileCopyRepositoryProvider),
        baseDir: getApplicationDocumentsDirectory,
        clock: ref.watch(clockProvider),
      ),
    );

/// What each documentation file on this device is a copy of, when it came
/// from a server. About the files here, not about any one installation.
final silexgisFileCopyRepositoryProvider = Provider<SilexgisFileCopyRepository>(
  (ref) => SilexgisFileCopyRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// The document links each installation holds. Local-only.
final silexgisServerLinksProvider = Provider<SilexgisServerLinkRepository>(
  (ref) => SilexgisServerLinkRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// What a feature has on the active installation that this device does not,
/// and fetching it on the caver's say-so.
final silexgisDocumentsServiceProvider = Provider<SilexgisDocumentsService>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  final tokens = ref.watch(silexgisTokenStoreProvider);
  final catalogue = ref.watch(silexgisDocumentCatalogueProvider);
  final logger = ref.watch(changeLoggerProvider);
  final localState = ref.watch(silexgisLocalStateProvider);
  final clock = ref.watch(clockProvider);
  final copies = ref.watch(silexgisFileCopyRepositoryProvider);
  final serverLinks = ref.watch(silexgisServerLinksProvider);
  return SilexgisDocumentsService(
    profiles: ref.watch(silexgisProfileRepositoryProvider),
    catalogue: catalogue,
    documents: ref.watch(documentationRepositoryProvider),
    sessionBuilder: (profile) => SilexgisSession.signedIn(profile, tokens),
    downloaderBuilder: (profile, api) => SilexgisDocumentDownloader(
      db: db,
      api: api,
      fetcher: SilexgisFileFetcher(baseUri: profile.baseUri),
      store: SilexgisDocumentFileStore(
        baseDir: getApplicationDocumentsDirectory,
      ),
      catalogue: catalogue,
      importer: SilexgisDocumentImporter(
        db: db,
        logger: logger,
        localState: localState,
        copies: copies,
        linker: SilexgisDocumentLinker(
          db: db,
          logger: logger,
          catalogue: catalogue,
          copies: copies,
          serverLinks: serverLinks,
          profileUuid: profile.profileUuid,
          clock: clock,
        ),
        profileUuid: profile.profileUuid,
        clock: clock,
      ),
      profileUuid: profile.profileUuid,
    ),
  );
});

/// The catalogue entries one feature has on the active installation and not
/// here, or null when there is no profile or nothing to show.
final silexgisServerDocumentsProvider = FutureProvider.autoDispose
    .family<SilexgisServerDocuments?, Uuid>(
      (ref, featureId) =>
          ref.watch(silexgisDocumentsServiceProvider).forFeature(featureId),
    );

/// The choice of caver per phone user, for the user screens.
final silexgisPeopleServiceProvider = Provider<SilexgisPeopleService>(
  (ref) => SilexgisPeopleService(
    profiles: ref.watch(silexgisProfileRepositoryProvider),
    people: ref.watch(silexgisPeopleRepositoryProvider),
  ),
);

/// Which caver one phone user is on the active installation, or null when
/// there is no profile or no directory to choose from.
final silexgisCaverChoiceProvider = FutureProvider.autoDispose
    .family<SilexgisCaverChoice?, Uuid>(
      (ref, userUuid) =>
          ref.watch(silexgisPeopleServiceProvider).choiceFor(userUuid),
    );

/// Which recordings on this device came from the active installation and
/// were made on another phone, for the trips list to keep out of the way.
final silexgisTripOriginServiceProvider = Provider<SilexgisTripOriginService>(
  (ref) => SilexgisTripOriginService(
    profiles: ref.watch(silexgisProfileRepositoryProvider),
    trips: SilexgisTripStateRepository(ref.watch(appDatabaseProvider)),
    people: ref.watch(silexgisPeopleRepositoryProvider),
  ),
);

/// What the caver can do about what an installation did not write, section by
/// section.
final silexgisDecisionsServiceProvider = Provider<SilexgisDecisionsService>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  final logger = ref.watch(changeLoggerProvider);
  final localState = ref.watch(silexgisLocalStateProvider);
  final heldRows = ref.watch(silexgisHeldRowsProvider);
  final caves = ref.watch(caveRepositoryProvider);
  final places = ref.watch(cavePlaceRepositoryProvider);
  final reread = SilexgisServerVersionReread(
    localState: localState,
    heldRows: heldRows,
  );
  final placer = buildSilexgisServerRowPlacer(
    db: db,
    logger: logger,
    localState: localState,
    heldRows: heldRows,
    caves: caves,
    places: places,
    catalogue: ref.watch(silexgisDocumentCatalogueProvider),
    trips: SilexgisTripStateRepository(db),
    rasters: SilexgisRasterStateRepository(db),
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
        documents: ref.watch(documentationRepositoryProvider),
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
        trips: ref.watch(caveTripRepositoryProvider),
        removeScan: (scan) =>
            ref.read(caveTripServiceProvider).deletePoint(scan),
      ),
      SilexgisRasterDecisions(
        db: db,
        reread: reread,
        placer: placer,
        maps: ref.watch(rasterMapRepositoryProvider),
        pins: ref.watch(definitionRepositoryProvider),
      ),
    ],
  );
});

/// The server copy a raster map shows as its picture, with what the
/// installation says of the picture as stored; null when the map shows the
/// caver's own picture or the original.
final rasterMapPictureProvider = FutureProvider.autoDispose
    .family<SilexgisMapPicture?, Uuid>(
      (ref, mapUuid) => SilexgisMapPictureCopies(
        ref.watch(appDatabaseProvider),
      ).pictureOf(mapUuid),
    );

/// The configured SilexGIS installations. Its own configuration key — a server
/// profile follows the FTP-profile pattern without joining that machinery.
final silexgisProfileRepositoryProvider = Provider<SilexgisProfileRepository>(
  (ref) => SilexgisProfileRepository(
    ref.watch(configurationRepositoryProvider),
    ref.watch(silexgisTokenStoreProvider),
    ref.watch(silexgisLocalStateProvider),
  ),
);

/// Live progress of one server sync, for the UI to watch.
final silexgisSyncControllerProvider =
    ChangeNotifierProvider<SilexgisSyncController>(
      (ref) => SilexgisSyncController(
        db: ref.watch(appDatabaseProvider),
        profiles: ref.watch(silexgisProfileRepositoryProvider),
        localState: ref.watch(silexgisLocalStateProvider),
        heldRows: ref.watch(silexgisHeldRowsProvider),
        people: ref.watch(silexgisPeopleRepositoryProvider),
        catalogue: ref.watch(silexgisDocumentCatalogueProvider),
        logger: ref.watch(changeLoggerProvider),
        caves: ref.watch(caveRepositoryProvider),
        places: ref.watch(cavePlaceRepositoryProvider),
        tokens: ref.watch(silexgisTokenStoreProvider),
        copies: ref.watch(silexgisFileCopyRepositoryProvider),
        serverLinks: ref.watch(silexgisServerLinksProvider),
        networkProbe: ref.watch(networkKindProbeProvider),
      ),
    );

/// Which kind of network the device is on, for settings that keep files for
/// Wi-Fi.
final networkKindProbeProvider = Provider<NetworkKindProbe>(
  (ref) => ConnectivityNetworkKindProbe(),
);

/// The configured server profiles, re-read whenever the settings page asks.
final silexgisProfilesProvider = FutureProvider<List<SilexgisProfile>>(
  (ref) => ref.watch(silexgisProfileRepositoryProvider).list(),
);

final usersStreamProvider = StreamProvider<List<User>>((ref) {
  return ref.watch(userRepositoryProvider).watchUsers();
});

final cavePlaceRepositoryProvider = Provider<ICavePlaceRepository>(
  (ref) => CavePlaceRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(currentUserServiceProvider),
    ref.watch(changeLoggerProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// BLE beacon registrations (cave_place_beacons).
final beaconRepositoryProvider = Provider<BeaconRepository>(
  (ref) => BeaconRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(currentUserServiceProvider),
    ref.watch(changeLoggerProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Downloaded Ruuvi on-tag history (ruuvi_sensor_history, local-only).
final ruuviHistoryRepositoryProvider = Provider<RuuviHistoryRepository>(
  (ref) => RuuviHistoryRepository(ref.watch(appDatabaseProvider)),
);

/// GATT download of a Ruuvi tag's on-board log.
final ruuviHistoryServiceProvider = Provider<RuuviHistoryService>(
  (ref) => RuuviHistoryService(
    ref.watch(ruuviHistoryRepositoryProvider),
    ref.watch(beaconRepositoryProvider),
  ),
);

/// Stored history readings of one tag (keyed by MAC), oldest first.
final ruuviHistoryStreamProvider =
    StreamProvider.family<List<RuuviSensorHistoryData>, String>(
      (ref, macAddress) =>
          ref.watch(ruuviHistoryRepositoryProvider).watchReadings(macAddress),
    );

/// The single chokepoint for PCI/QCRI generation, validation and write
/// integration. See `docs/features/place-code-identifiers.md`.
final placeCodeServiceProvider = Provider<PlaceCodeService>(
  (ref) => PlaceCodeService(ref.watch(appDatabaseProvider)),
);

/// Batch runner orchestrating PCI/QCRI generation over a scope.
final placeCodeBatchRunnerProvider = Provider<PlaceCodeBatchRunner>(
  (ref) => PlaceCodeBatchRunner(
    ref.watch(appDatabaseProvider),
    ref.watch(placeCodeServiceProvider),
    ref.watch(cavePlaceRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Composes QR-ready codes for a range of not-yet-recorded cave entrances
/// (per surface area) or cave places (per cave), without persisting them.
final rangeCodeGeneratorProvider = Provider<RangeCodeGenerator>(
  (ref) => RangeCodeGenerator(
    ref.watch(appDatabaseProvider),
    ref.watch(placeCodeServiceProvider),
  ),
);

final rasterMapRepositoryProvider = Provider<IRasterMapRepository>(
  (ref) => RasterMapRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(currentUserServiceProvider),
    ref.watch(changeLoggerProvider),
    clock: ref.watch(clockProvider),
  ),
);

final definitionRepositoryProvider = Provider<IDefinitionRepository>(
  (ref) => DefinitionRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(currentUserServiceProvider),
    ref.watch(changeLoggerProvider),
    clock: ref.watch(clockProvider),
  ),
);

final caveTripServiceProvider = Provider<CaveTripService>(
  (ref) => CaveTripService(
    ref.watch(appDatabaseProvider),
    ref.watch(changeLoggerProvider),
    ref.watch(currentUserServiceProvider),
    ref.watch(configurationRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Bulk file-to-geofeature importer. New call sites take it from here;
/// the two document screens that predate this provider still build their
/// own instance.
final caveDocumentImportServiceProvider = Provider<CaveDocumentImportService>(
  (ref) => CaveDocumentImportService(
    ref.watch(documentationRepositoryProvider),
    ref.watch(changeLoggerProvider),
  ),
);

/// What reading device pictures for QR labels found, remembered on this
/// device so the points-from-pictures screen does not read them again.
final mediaScanCacheProvider = Provider<MediaScanCache>(
  (ref) => MediaScanCache(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Applies the decisions made on the trip-media screen: track points at the
/// capture times, the stored media, and the links binding each picture to
/// both its cave place and its track point.
final tripMediaImportServiceProvider = Provider<TripMediaImportService>(
  (ref) => TripMediaImportService(
    ref.watch(appDatabaseProvider),
    ref.watch(caveTripServiceProvider),
    ref.watch(caveDocumentImportServiceProvider),
    ref.watch(changeLoggerProvider),
    ref.watch(currentUserServiceProvider),
  ),
);

/// Read/mutation surface for `cave_trips`, `cave_trip_points`, and
/// `trip_report_templates` tables. Trip runtime state lives in
/// [CaveTripService]; this provider exposes the pure DB operations so
/// screens stop reaching into the global [AppDatabase].
final caveTripRepositoryProvider = Provider<ICaveTripRepository>(
  (ref) => CaveTripRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(changeLoggerProvider),
  ),
);

/// Canonical QR-code lookup handler (camera scans, manual input, deep links).
/// Fully injected so it is unit-testable without the service_locator globals.
final qrCodeLookupHandlerProvider = Provider<QrCodeLookupHandler>(
  (ref) => QrCodeLookupHandler(
    QrCodeLookupService(ref.watch(appDatabaseProvider)),
    ref.watch(caveTripServiceProvider),
    ref.watch(rasterMapRepositoryProvider),
    ref.watch(definitionRepositoryProvider),
    ref.watch(caveRepositoryProvider),
    ref.watch(caveTripRepositoryProvider),
  ),
);

/// Documentation-file helper surface used by editor pages and the
/// documentation list. Currently only exposes `getDocumentationParentLink`;
/// other writes still flow through [DocumentationFileHelper] until those
/// call-sites are migrated in a follow-up PR-2 slice.
final documentationRepositoryProvider = Provider<IDocumentationRepository>(
  (ref) => DocumentationRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(changeLoggerProvider),
    ref.watch(currentUserServiceProvider),
  ),
);

/// Discovers `.mbtiles` basemap/overlay files in the app-managed folder
/// used by the surface map (see docs/workflows/mbtiles-layers.md).
final mbTilesRegistryProvider = Provider<MbTilesRegistry>(
  (ref) => MbTilesRegistry(),
);

/// Disk cache for online base-map tiles, under the app-support directory
/// (not documents — it is disposable data the user never browses).
final tileDiskCacheProvider = FutureProvider<TileDiskCache>((ref) async {
  final support = await getApplicationSupportDirectory();
  return TileDiskCache(
    Directory('${support.path}${Platform.pathSeparator}tile_cache'),
  );
});

/// Generic device-location access (permission + position stream/one-shot)
/// used by the surface map's GPS features.
final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);

/// Creates and positions geographic cave points (new cave + entrance, new
/// entrance for a cave, set a place's location) from the surface map.
final caveGeoServiceProvider = Provider<CaveGeoService>(
  (ref) => CaveGeoService(
    ref.watch(caveRepositoryProvider),
    ref.watch(cavePlaceRepositoryProvider),
  ),
);

/// GPX/KML exchange of cave places with external mapping tools.
final placeTransferServiceProvider = Provider<PlaceTransferService>(
  (ref) => PlaceTransferService(
    ref.watch(appDatabaseProvider),
    ref.watch(caveRepositoryProvider),
    ref.watch(cavePlaceRepositoryProvider),
  ),
);

/// Session-level preferences that persist for the lifetime of the app process.
class SessionPrefs {
  SessionPrefs._();
  static final SessionPrefs instance = SessionPrefs._();

  /// User has confirmed auto-save when switching map/place.
  /// Resets on app restart.
  bool autoSaveConfirmed = false;

  void reset() {
    autoSaveConfirmed = false;
  }
}

final sessionPrefsProvider = Provider<SessionPrefs>(
  (ref) => SessionPrefs.instance,
);

// -----------------------------------------------------------------------------
// Stream providers — reactive list of rows backed by Drift `.watch()`.
// -----------------------------------------------------------------------------

/// Live stream of all caves. Emits on any write to the `caves` table.
final cavesStreamProvider = StreamProvider<List<Cave>>((ref) {
  return ref.watch(caveRepositoryProvider).watchCaves();
});

/// Live stream of cave places filtered by cave id.
final cavePlacesStreamProvider = StreamProvider.family<List<CavePlace>, Uuid>((
  ref,
  caveUuid,
) {
  return ref.watch(cavePlaceRepositoryProvider).watchCavePlaces(caveUuid);
});

// -----------------------------------------------------------------------------
// Global UI-state notifiers exposed as Riverpod providers.
// The underlying [ValueNotifier] instances in `lib/state/app_notifiers.dart`
// remain the source of truth during the migration. These providers surface
// the current value and rebuild consumers on change.
// -----------------------------------------------------------------------------

final debugModeProvider = ChangeNotifierProvider<ValueNotifier<bool>>(
  (ref) => debugModeNotifier,
);

final homePageRefreshProvider = ChangeNotifierProvider<ValueNotifier<int>>(
  (ref) => homePageRefreshNotifier,
);

final activeTripIdProvider = ChangeNotifierProvider<ValueNotifier<Uuid?>>(
  (ref) => ref.watch(caveTripServiceProvider).activeTripIdNotifier,
);

final tripPausedProvider = ChangeNotifierProvider<ValueNotifier<bool>>(
  (ref) => ref.watch(caveTripServiceProvider).isPausedNotifier,
);
