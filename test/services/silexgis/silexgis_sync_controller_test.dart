import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_controller.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_progress.dart';
import 'package:speleoloc/services/user_repository.dart';

import 'scripted_client.dart';

/// One run, end to end, against a scripted server.
void main() {
  const setId = 'set-1';
  const profile = SilexgisProfile(
    profileUuid: 'p-1',
    displayName: 'Clubul Speo Example',
    baseUrl: 'https://club.example.org',
    accountEmail: 'caver@example.org',
    syncSetId: setId,
  );

  late AppDatabase db;
  late SilexgisProfileRepository profiles;
  late InMemoryRefreshTokenStore tokens;
  late SilexgisLocalStateRepository localState;
  late ChangeLogger logger;
  late CaveRepository caves;
  late CavePlaceRepository places;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger loggerRef;
    final users = UserRepository(db, () => loggerRef);
    final currentUser = CurrentUserService(
      db,
      users,
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    logger = loggerRef = ChangeLogger(db, currentUser);
    localState = SilexgisLocalStateRepository(db);
    tokens = InMemoryRefreshTokenStore();
    profiles = SilexgisProfileRepository(
      ConfigurationRepository(db),
      tokens,
      localState,
    );
    caves = CaveRepository(db, currentUser, logger);
    places = CavePlaceRepository(db, currentUser, logger);
  });
  tearDown(() => db.close());

  SilexgisSyncController controllerFor(ScriptedClient client) =>
      SilexgisSyncController(
        db: db,
        profiles: profiles,
        localState: localState,
        logger: logger,
        caves: caves,
        places: places,
        tokens: tokens,
        sessionBuilder: (p) {
          final auth = SilexgisAuthService(
            baseUri: p.baseUri,
            profileUuid: p.profileUuid,
            store: tokens,
            client: client,
          );
          return SilexgisSession(
            auth: auth,
            api: SilexgisSyncApi(
              SilexgisHttp(baseUri: p.baseUri, tokens: auth, client: client),
            ),
          );
        },
      );

  ScriptedResponse refreshed() => ScriptedResponse.json(
    path: SilexgisContract.tokenPath,
    json: <String, Object?>{
      'access_token': 'access-1',
      'token_type': 'Bearer',
      'expires_in': 900,
      'scope': 'openid profile email roles offline_access',
      'refresh_token': 'refresh-2',
    },
  );

  ScriptedResponse capabilities({
    int contractVersion = 1,
    List<String> features = const <String>['download', 'upload'],
  }) => ScriptedResponse.json(
    path: SilexgisContract.capabilitiesPath,
    json: <String, Object?>{
      'contractVersion': contractVersion,
      'pageSizeMax': 500,
      'uploadRowsMax': 500,
      'features': features,
    },
  );

  ScriptedResponse emptyPage() => ScriptedResponse.json(
    path: SilexgisContract.downloadPath(setId),
    json: <String, Object?>{
      'setRevision': 1,
      'settings': const <String, Object?>{},
      'features': const <Object?>[],
      'tombstones': const <Object?>[],
      'nextCursor': null,
      'hasMore': false,
    },
  );

  group('with no server configured', () {
    test('a sync is a no-op, not a failure', () async {
      // A server profile is exactly as optional as an FTP profile. Its absence
      // fails soft, and a build with the feature unconfigured behaves the same
      // as today's in every respect a caver can observe.
      final client = ScriptedClient(<ScriptedResponse>[]);
      final controller = controllerFor(client);

      await controller.syncDefault();

      expect(controller.progress.phase, SilexgisSyncPhase.idle);
      expect(client.sent, isEmpty);
    });
  });

  test(
    'a profile with no set chosen asks the caver, and sends nothing',
    () async {
      final client = ScriptedClient(<ScriptedResponse>[]);
      final controller = controllerFor(client);

      await controller.sync(profile.copyWith(clearSyncSet: true));

      expect(controller.progress.phase, SilexgisSyncPhase.failed);
      expect(controller.progress.action, SilexgisAction.surfaceToUser);
      expect(client.sent, isEmpty);
    },
  );

  test(
    'a lapsed credential asks for a password rather than losing anything',
    () async {
      // A session that has run out is a reason to ask for a password, not a
      // reason to discard or re-download anything: the local database remains
      // the source of truth for everything the device holds.
      await profiles.save(profile);
      final client = ScriptedClient(<ScriptedResponse>[]);
      final controller = controllerFor(client);

      await controller.syncDefault();

      expect(controller.progress.phase, SilexgisSyncPhase.failed);
      expect(controller.progress.action, SilexgisAction.reAuth);
    },
  );

  test('a server that has moved on is answered, not guessed at', () async {
    await profiles.save(profile);
    await tokens.write('p-1', 'refresh-1');
    final client = ScriptedClient(<ScriptedResponse>[
      refreshed(),
      capabilities(contractVersion: 99),
    ]);
    final controller = controllerFor(client);

    await controller.syncDefault();

    expect(controller.progress.phase, SilexgisSyncPhase.failed);
    // Nothing the device can do makes this request succeed; the application
    // needs updating, or the installation does.
    expect(controller.progress.action, SilexgisAction.stop);
    expect(controller.progress.code, SilexgisCodes.contractUnsupported);
    expect(controller.progress.message, contains('99'));
    // And no row was ever composed against a version this server cannot serve.
    expect(client.sent.where((r) => r.url.path.endsWith('/upload')), isEmpty);
  });

  test('a whole run reports what it did', () async {
    await profiles.save(profile);
    await tokens.write('p-1', 'refresh-1');
    final caveId = Uuid.v7();
    final client = ScriptedClient(<ScriptedResponse>[
      refreshed(),
      capabilities(),
      ScriptedResponse.json(
        path: SilexgisContract.downloadPath(setId),
        json: <String, Object?>{
          'setRevision': 3,
          'settings': const <String, Object?>{'digits': 4},
          'features': <Object?>[
            <String, Object?>{
              'id': caveId.toString(),
              'kind': 'cave',
              'name': 'Peștera Mică',
              'updatedAt': '2026-08-28T09:00:00.000Z',
              'properties': const <String, Object?>{},
              'parents': const <Object?>[],
            },
          ],
          'tombstones': const <Object?>[],
          'nextCursor': 'c1',
          'hasMore': false,
        },
      ),
    ]);
    final controller = controllerFor(client);

    final phases = <SilexgisSyncPhase>[];
    controller.addListener(() => phases.add(controller.progress.phase));

    await controller.syncDefault();

    expect(controller.progress.phase, SilexgisSyncPhase.completed);
    expect(controller.progress.rowsApplied, 1);
    expect(controller.progress.download?.setRevision, 3);
    expect(controller.progress.needsAttention, isFalse);
    expect(
      phases,
      containsAllInOrder(<SilexgisSyncPhase>[
        SilexgisSyncPhase.authenticating,
        SilexgisSyncPhase.askingCapabilities,
        SilexgisSyncPhase.uploading,
        SilexgisSyncPhase.downloading,
        SilexgisSyncPhase.completed,
      ]),
    );
    // The downloaded cave is here, and applying it logged nothing.
    expect(await db.select(db.caves).get(), hasLength(1));
    expect(await db.select(db.changeLog).get(), isEmpty);
    // And this device's position on that installation is stored.
    expect((await localState.readSetState('p-1', setId)).cursor, 'c1');
  });

  test(
    'a build that serves only the read half does not try to write',
    () async {
      // `features` is how a device meets a server that has shipped some of the
      // protocol and not the rest, and takes what is there.
      await profiles.save(profile);
      await tokens.write('p-1', 'refresh-1');
      final client = ScriptedClient(<ScriptedResponse>[
        refreshed(),
        capabilities(features: const <String>['download']),
        emptyPage(),
      ]);
      final controller = controllerFor(client);

      await controller.syncDefault();

      expect(controller.progress.phase, SilexgisSyncPhase.completed);
      expect(client.sent.where((r) => r.method == 'POST'), hasLength(1));
      expect(client.sent.last.url.path, SilexgisContract.downloadPath(setId));
    },
  );

  test(
    'a second call while a run is in flight joins it rather than doubling',
    () async {
      await profiles.save(profile);
      await tokens.write('p-1', 'refresh-1');
      final client = ScriptedClient(<ScriptedResponse>[
        refreshed(),
        capabilities(),
        emptyPage(),
      ]);
      final controller = controllerFor(client);

      await Future.wait(<Future<void>>[
        controller.syncDefault(),
        controller.syncDefault(),
      ]);

      expect(controller.progress.phase, SilexgisSyncPhase.completed);
      // One sign-in, one capabilities read, one page.
      expect(client.sent, hasLength(3));
    },
  );
}
