import 'dart:convert';

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
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_people.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_transfer_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_controller.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_progress.dart';
import 'package:speleoloc/services/user_repository.dart';

import 'contract_fixtures.dart';
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
  late SilexgisHeldRowRepository heldRows;
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
    heldRows = SilexgisHeldRowRepository(db);
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
        heldRows: heldRows,
        people: SilexgisPeopleRepository(db),
        catalogue: SilexgisDocumentCatalogueRepository(db),
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

  test('a locked account is told to try later, not to sign in', () async {
    await profiles.save(profile);
    await tokens.write('p-1', 'refresh-1');
    final client = ScriptedClient(<ScriptedResponse>[
      ScriptedResponse.json(
        path: SilexgisContract.tokenPath,
        status: 400,
        json: <String, Object?>{
          'error': 'invalid_grant',
          'error_description': 'The account is locked.',
        },
      ),
    ]);
    final controller = controllerFor(client);

    await controller.syncDefault();

    expect(controller.progress.phase, SilexgisSyncPhase.failed);
    expect(controller.progress.action, SilexgisAction.retry);
    expect(controller.progress.message, contains('locked'));
    expect(controller.progress.message, contains('Try again later'));
    expect(await tokens.read('p-1'), 'refresh-1');
  });

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
    // As is what the installation offered, for the settings page.
    expect((await profiles.find('p-1'))!.servedFeatures, <String>[
      'download',
      'upload',
    ]);
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

  group('a whole-request refusal', () {
    Future<void> holdALocalCave() => db
        .into(db.caves)
        .insert(
          Cave(
            uuid: Uuid.v7(),
            title: 'Invented cave',
            updatedAt: DateTime.utc(2026, 9, 1).millisecondsSinceEpoch,
          ),
        );

    test(
      'an account under review stops the run and asks for an update',
      () async {
        await profiles.save(profile.copyWith(uploadsNewRoots: true));
        await tokens.write('p-1', 'refresh-1');
        await holdALocalCave();
        final recorded = ContractExchange('16-errors/client-update-required');
        final client = ScriptedClient(<ScriptedResponse>[
          refreshed(),
          capabilities(),
          ScriptedResponse(
            path: SilexgisContract.uploadPath(setId),
            status: recorded.status,
            body: jsonEncode(recorded.responseBody),
            headers: const <String, String>{
              'content-type': 'application/problem+json',
            },
          ),
        ]);
        final controller = controllerFor(client);

        await controller.syncDefault();

        expect(controller.progress.phase, SilexgisSyncPhase.failed);
        expect(controller.progress.action, SilexgisAction.stop);
        expect(controller.progress.code, SilexgisCodes.clientUpdateRequired);
        expect(controller.progress.message, contains('Update the app'));
        // Nothing is read after a write that did not go: a read would put
        // back what the caver removed here.
        expect(
          client.sent.where((r) => r.url.path.endsWith('/download')),
          isEmpty,
        );
        expect(await db.select(db.caves).get(), hasLength(1));
      },
    );

    test('a part switched off stops that part, and the run goes on', () async {
      await profiles.save(profile);
      await tokens.write('p-1', 'refresh-1');
      final client = ScriptedClient(<ScriptedResponse>[
        refreshed(),
        capabilities(),
        ScriptedResponse.problem(
          path: SilexgisContract.downloadPath(setId),
          status: 409,
          code: SilexgisCodes.featureDisabled,
          detail: 'Switched off here.',
        ),
      ]);
      final controller = controllerFor(client);

      await controller.syncDefault();

      expect(controller.progress.phase, SilexgisSyncPhase.completed);
      expect(controller.progress.action, isNull);
      final off = controller.progress.unavailable.single;
      expect(off.detail, 'Switched off here.');
      expect(controller.progress.message, contains('does not offer'));
    });

    test('a part switched off last run is asked about again', () async {
      await profiles.save(profile);
      await tokens.write('p-1', 'refresh-1');
      final client = ScriptedClient(<ScriptedResponse>[
        refreshed(),
        capabilities(),
        ScriptedResponse.problem(
          path: SilexgisContract.downloadPath(setId),
          status: 409,
          code: SilexgisCodes.featureDisabled,
        ),
        refreshed(),
        capabilities(),
        emptyPage(),
      ]);
      final controller = controllerFor(client);

      await controller.syncDefault();
      await controller.syncDefault();

      expect(controller.progress.phase, SilexgisSyncPhase.completed);
      expect(controller.progress.unavailable, isEmpty);
      expect(
        client.sent.where((r) => r.url.path.endsWith('/download')),
        hasLength(2),
      );
    });
  });

  group('an account under review', () {
    test(
      '20 then 22: rows go up held, and come back decided last in the run',
      () async {
        await profiles.save(profile.copyWith(uploadsNewRoots: true));
        await tokens.write('p-1', 'refresh-1');
        final caveId = Uuid.v7();
        final entranceId = Uuid.v7();
        final stamp = DateTime.utc(2026, 10, 26).millisecondsSinceEpoch;
        await db
            .into(db.caves)
            .insert(Cave(uuid: caveId, title: 'held cave', updatedAt: stamp));
        await db
            .into(db.cavePlaces)
            .insert(
              CavePlace(
                uuid: entranceId,
                title: 'Intrare',
                caveUuid: caveId,
                latitude: 45.61,
                longitude: 22.51,
                isEntrance: 1,
                isMainEntrance: 1,
                updatedAt: stamp,
              ),
            );
        final ids = <String, String>{
          '<cave>': caveId.toString(),
          '<entrance>': entranceId.toString(),
          '<uuid-2>': 'review-cave',
          '<uuid-3>': 'review-entrance',
          '<review>': 'review-entrance',
          '<timestamp>': '2026-10-26T09:12:44.512Z',
          '<cursor>': 'reviews-c1',
        };
        final client = ScriptedClient(<ScriptedResponse>[
          refreshed(),
          capabilities(
            features: const <String>['download', 'upload', 'reviews'],
          ),
          ScriptedResponse.json(
            path: SilexgisContract.uploadPath(setId),
            json: fillPlaceholders(
              ContractExchange('20-upload-held').responseBody,
              ids,
            ),
          ),
          emptyPage(),
          ScriptedResponse.json(
            path: SilexgisContract.reviewsPath(setId),
            json: fillPlaceholders(
              ContractExchange('22-reviews-current-withheld').responseBody,
              ids,
            ),
          ),
        ]);
        final controller = controllerFor(client);

        await controller.syncDefault();

        expect(controller.progress.phase, SilexgisSyncPhase.completed);
        final upload = client.sent.firstWhere(
          (r) => r.url.path == SilexgisContract.uploadPath(setId),
        );
        expect(upload.jsonBody['clientFeatures'], <String>['held']);
        expect(controller.progress.upload?.held, 2);
        expect(client.sent.last.url.path, SilexgisContract.reviewsPath(setId));
        // The cave still waits; the entrance was turned down.
        expect(controller.progress.reviews.waiting, 1);
        expect(controller.progress.reviews.toDecide, 1);
        expect(controller.progress.needsAttention, isTrue);
        expect(controller.progress.message, contains('waiting for review'));
        final held = await heldRows.readSection('p-1', SyncUploadSection.rows);
        expect(held.keys, unorderedEquals(<Uuid>[caveId, entranceId]));
        // Nothing was written, so nothing holds a revision.
        expect(await localState.readRevisions('p-1'), isEmpty);
      },
    );

    test('a build without the reviews stream does not ask for it', () async {
      await profiles.save(profile);
      await tokens.write('p-1', 'refresh-1');
      final client = ScriptedClient(<ScriptedResponse>[
        refreshed(),
        capabilities(),
        emptyPage(),
      ]);
      final controller = controllerFor(client);

      await controller.syncDefault();

      expect(controller.progress.phase, SilexgisSyncPhase.completed);
      expect(
        client.sent.where((r) => r.url.path.endsWith('/reviews')),
        isEmpty,
      );
    });
  });

  group('the people directory', () {
    ScriptedResponse emptyReviews() => ScriptedResponse.json(
      path: SilexgisContract.reviewsPath(setId),
      json: const <String, Object?>{
        'setRevision': 1,
        'settings': <String, Object?>{},
        'reviews': <Object?>[],
        'nextCursor': null,
        'hasMore': false,
      },
    );

    test('is read after the features and before the reviews', () async {
      await profiles.save(profile);
      await tokens.write('p-1', 'refresh-1');
      final client = ScriptedClient(<ScriptedResponse>[
        refreshed(),
        capabilities(
          features: const <String>['download', 'upload', 'people', 'reviews'],
        ),
        emptyPage(),
        ScriptedResponse.json(
          path: SilexgisContract.peoplePath,
          json: ContractExchange('23-people').responseBody,
        ),
        emptyReviews(),
      ]);
      final controller = controllerFor(client);

      await controller.syncDefault();

      expect(controller.progress.phase, SilexgisSyncPhase.completed);
      expect(client.sent.skip(2).map((r) => r.url.path).toList(), <String>[
        SilexgisContract.downloadPath(setId),
        SilexgisContract.peoplePath,
        SilexgisContract.reviewsPath(setId),
      ]);
      expect(
        await SilexgisPeopleRepository(db).readDirectory('p-1'),
        hasLength(3),
      );
    });

    test('switched off mid-run stops that part, and the run goes on', () async {
      await profiles.save(profile);
      await tokens.write('p-1', 'refresh-1');
      final recorded = ContractExchange('16-errors/feature-disabled');
      final client = ScriptedClient(<ScriptedResponse>[
        refreshed(),
        capabilities(features: const <String>['download', 'upload', 'people']),
        emptyPage(),
        ScriptedResponse(
          path: SilexgisContract.peoplePath,
          status: recorded.status,
          body: jsonEncode(recorded.responseBody),
          headers: const <String, String>{
            'content-type': 'application/problem+json',
          },
        ),
      ]);
      final controller = controllerFor(client);

      await controller.syncDefault();

      expect(controller.progress.phase, SilexgisSyncPhase.completed);
      expect(controller.progress.unavailable.single.part, contains('people'));
    });

    test('not offered, it is forgotten, so no choice is offered', () async {
      await profiles.save(profile);
      await tokens.write('p-1', 'refresh-1');
      final people = SilexgisPeopleRepository(db);
      await people.replaceDirectory('p-1', const <SyncPerson>[
        SyncPerson(id: 'caver-1', fullName: 'Invented Caver'),
      ]);
      final client = ScriptedClient(<ScriptedResponse>[
        refreshed(),
        capabilities(),
        emptyPage(),
      ]);

      await controllerFor(client).syncDefault();

      expect(await people.readDirectory('p-1'), isEmpty);
      expect(client.sent.where((r) => r.url.path.endsWith('/people')), isEmpty);
    });
  });

  group('the documents catalogue', () {
    test('is read after the people and before the reviews', () async {
      await profiles.save(profile);
      await tokens.write('p-1', 'refresh-1');
      final client = ScriptedClient(<ScriptedResponse>[
        refreshed(),
        capabilities(
          features: const <String>[
            'download',
            'upload',
            'people',
            'documents',
            'reviews',
          ],
        ),
        emptyPage(),
        ScriptedResponse.json(
          path: SilexgisContract.peoplePath,
          json: ContractExchange('23-people').responseBody,
        ),
        ScriptedResponse.json(
          path: SilexgisContract.documentsPath(setId),
          json: fillPlaceholders(
            ContractExchange('17-documents-first-page').responseBody,
            <String, String>{
              '<document>': Uuid.v7().toString(),
              '<cave>': Uuid.v7().toString(),
            },
          ),
        ),
        ScriptedResponse.json(
          path: SilexgisContract.reviewsPath(setId),
          json: const <String, Object?>{
            'setRevision': 1,
            'settings': <String, Object?>{},
            'reviews': <Object?>[],
            'nextCursor': null,
            'hasMore': false,
          },
        ),
      ]);
      final controller = controllerFor(client);

      await controller.syncDefault();

      expect(controller.progress.phase, SilexgisSyncPhase.completed);
      expect(client.sent.skip(2).map((r) => r.url.path).toList(), <String>[
        SilexgisContract.downloadPath(setId),
        SilexgisContract.peoplePath,
        SilexgisContract.documentsPath(setId),
        SilexgisContract.reviewsPath(setId),
      ]);
      expect(
        await SilexgisDocumentCatalogueRepository(db).isEmpty('p-1'),
        isFalse,
      );
      // Metadata only: nothing was fetched.
      expect(await db.select(db.documentationFiles).get(), isEmpty);
    });

    test('not offered, it is forgotten with its position', () async {
      await profiles.save(profile);
      await tokens.write('p-1', 'refresh-1');
      final catalogue = SilexgisDocumentCatalogueRepository(db);
      await catalogue.applyPage(
        'p-1',
        SyncDocumentsPage.fromJson(
          fillPlaceholders(
                ContractExchange('17-documents-first-page').responseBody,
                <String, String>{
                  '<document>': Uuid.v7().toString(),
                  '<cave>': Uuid.v7().toString(),
                },
              )!
              as Map<String, Object?>,
        ),
      );
      await localState.writeStreamCursor(
        'p-1',
        setId,
        SyncStream.documents,
        cursor: 'documents-c1',
        setRevision: 1,
      );
      final client = ScriptedClient(<ScriptedResponse>[
        refreshed(),
        capabilities(),
        emptyPage(),
      ]);

      await controllerFor(client).syncDefault();

      expect(await catalogue.isEmpty('p-1'), isTrue);
      expect(
        (await localState.readStreamCursor(
          'p-1',
          setId,
          SyncStream.documents,
        )).cursor,
        isNull,
      );
    });
  });
}
