import 'dart:io';

import 'package:drift/native.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_controller.dart';
import 'package:speleoloc/services/silexgis/silexgis_transfer_api.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/utils/clock.dart';

import 'fake_silexgis_server.dart';

/// One phone signed in to a [FakeSilexgisServer]: its own in-memory database
/// and repositories, and the real sync controller, so what travels between
/// two of them goes through everything a phone runs.
class SilexgisTestDevice {
  SilexgisTestDevice._({
    required this.db,
    required this.server,
    required this.profile,
    required this.tokens,
    required this.profiles,
    required this.localState,
    required this.heldRows,
    required this.logger,
    required this.caves,
    required this.places,
    required this.documentsDir,
    required this.controller,
  });

  /// A device signed in to [server] with a chain of its own, carrying the
  /// server's one set. [uploadsNewRoots] is the profile's switch; on, a cave
  /// made here travels. The network is not known here, so files go only while
  /// [filesOnlyOverWifi] is off.
  static Future<SilexgisTestDevice> create(
    FakeSilexgisServer server, {
    required Clock clock,
    String profileUuid = 'p-1',
    bool uploadsNewRoots = true,
    bool sendsFiles = true,
    bool filesOnlyOverWifi = false,
  }) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger loggerRef;
    final users = UserRepository(db, () => loggerRef);
    final currentUser = CurrentUserService(
      db,
      users,
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    final logger = loggerRef = ChangeLogger(db, currentUser, clock: clock);
    final localState = SilexgisLocalStateRepository(db, clock: clock);
    final heldRows = SilexgisHeldRowRepository(db, clock: clock);
    final tokens = InMemoryRefreshTokenStore();
    final profiles = SilexgisProfileRepository(
      ConfigurationRepository(db),
      tokens,
      localState,
    );
    final caves = CaveRepository(db, currentUser, logger, clock: clock);
    final places = CavePlaceRepository(db, currentUser, logger, clock: clock);
    final documentsDir = await Directory.systemTemp.createTemp('silexgis_dev_');

    final profile = SilexgisProfile(
      profileUuid: profileUuid,
      displayName: 'Invented club',
      baseUrl: 'https://club.example.test',
      accountEmail: 'caver@example.test',
      syncSetId: server.setId,
      uploadsNewRoots: uploadsNewRoots,
      sendsFiles: sendsFiles,
      filesOnlyOverWifi: filesOnlyOverWifi,
    );
    await profiles.save(profile);
    await tokens.write(profileUuid, server.signIn());

    final controller = SilexgisSyncController(
      db: db,
      profiles: profiles,
      localState: localState,
      heldRows: heldRows,
      people: SilexgisPeopleRepository(db),
      catalogue: SilexgisDocumentCatalogueRepository(db),
      logger: logger,
      caves: caves,
      places: places,
      tokens: tokens,
      documentsDir: () async => documentsDir,
      sessionBuilder: (p) {
        final client = server.client();
        final auth = SilexgisAuthService(
          baseUri: p.baseUri,
          profileUuid: p.profileUuid,
          store: tokens,
          client: client,
          clock: clock,
          refreshRetryPause: Duration.zero,
        );
        final http = SilexgisHttp(
          baseUri: p.baseUri,
          tokens: auth,
          client: client,
        );
        return SilexgisSession(
          auth: auth,
          api: SilexgisSyncApi(http),
          transfers: SilexgisTransferApi(http),
        );
      },
    );

    return SilexgisTestDevice._(
      db: db,
      server: server,
      profile: profile,
      tokens: tokens,
      profiles: profiles,
      localState: localState,
      heldRows: heldRows,
      logger: logger,
      caves: caves,
      places: places,
      documentsDir: documentsDir,
      controller: controller,
    );
  }

  final AppDatabase db;
  final FakeSilexgisServer server;
  final SilexgisProfile profile;
  final InMemoryRefreshTokenStore tokens;
  final SilexgisProfileRepository profiles;
  final SilexgisLocalStateRepository localState;
  final SilexgisHeldRowRepository heldRows;
  final ChangeLogger logger;
  final CaveRepository caves;
  final CavePlaceRepository places;
  final Directory documentsDir;
  final SilexgisSyncController controller;

  /// One whole run, as the sync button starts it.
  Future<void> sync({bool fromBeginning = false}) =>
      controller.syncDefault(fromBeginning: fromBeginning);

  bool _controllerDisposed = false;

  /// Disposes the controller as a database swap does, once.
  void disposeController() {
    if (_controllerDisposed) return;
    _controllerDisposed = true;
    controller.dispose();
  }

  Future<void> dispose() async {
    disposeController();
    await db.close();
    if (documentsDir.existsSync()) {
      await documentsDir.delete(recursive: true);
    }
  }
}
