import 'dart:io';

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
import 'package:speleoloc/services/silexgis/model/sync_set.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_batch.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_controller.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_progress.dart';
import 'package:speleoloc/services/user_repository.dart';

import 'live_server.dart';

/// An account whose uploads wait for a reviewer, against a real installation.
///
/// Covers the held half of the cycle: a build that cannot be told is refused,
/// one that can has its rows held, and the reviews stream has nothing to say
/// until somebody decides. A decision is made by a person in the browser, and
/// the development server has no scripted way to make one yet, so the cycle
/// stops there.
///
/// Off by default, like every live test. To run it:
///
/// 1. From a SilexGIS checkout: `node deploy/speleoloc-dev.mjs up`.
/// 2. `SPELEO_LOC_SILEXGIS_LIVE=1 flutter test test/services/silexgis/silexgis_review_live_test.dart`
///
/// `SPELEO_LOC_SILEXGIS_URL` overrides the base address.
void main() {
  final env = Platform.environment;
  if (env['SPELEO_LOC_SILEXGIS_LIVE'] != '1') {
    test(
      'SilexGIS review live test skipped (set SPELEO_LOC_SILEXGIS_LIVE=1)',
      () {},
    );
    return;
  }

  final baseUri = Uri.parse(
    env['SPELEO_LOC_SILEXGIS_URL'] ?? 'http://127.0.0.1:5205',
  );
  // The member's twin, except that what it uploads waits for a reviewer. It
  // signs in with the member's password.
  const email = 'review@dev.local';
  const password = 'dev-member-pass-1';

  late SilexgisAuthService auth;
  late SilexgisSyncApi api;
  late SyncSet set;

  setUpAll(() async {
    auth = SilexgisAuthService(
      baseUri: baseUri,
      profileUuid: 'review-live-test',
      store: InMemoryRefreshTokenStore(),
    );
    await auth.signIn(email: email, password: password);
    api = SilexgisSyncApi(SilexgisHttp(baseUri: baseUri, tokens: auth));

    final token = await auth.accessToken();
    final roots = await demoCaveFeatureIds(
      baseUri,
      token,
      names: const <String>{'Peștera Demo Mare'},
    );
    expect(
      roots,
      hasLength(1),
      reason:
          'the demonstration dataset is not seeded — run '
          '`node deploy/speleoloc-dev.mjs reset` then `up`',
    );
    set = await api.createSet(
      SyncSetWrite(
        name: 'review live ${DateTime.now().millisecondsSinceEpoch}',
        cavingGroupId: await demoCavingGroupId(baseUri, token),
        uploadVisibility: SyncVisibility.cavingGroup,
        rootFeatureIds: roots,
        settings: const <String, Object?>{'pciStrategy': 'ro-default'},
      ),
    );
  });

  tearDownAll(() async {
    await api.deleteSet(set.id);
    auth.close();
  });

  SyncUploadBatch newCave(
    Uuid id, {
    List<String> clientFeatures = const <String>[],
  }) => SyncUploadBatch(
    batchId: Uuid.v7().toString(),
    clientFeatures: clientFeatures,
    rows: <SyncUploadRow>[
      SyncUploadRow(
        id: id.toString(),
        kind: SyncUploadKind.cave,
        baseRevision: null,
        name: 'Held cave ${id.toString().substring(0, 8)}',
        caveTypeCode: 'cave',
      ),
    ],
  );

  test('the installation serves the reviews stream', () async {
    final capabilities = await api.capabilities();
    expect(capabilities.servesReviews, isTrue);
  });

  test('an upload that cannot be told about held is refused whole', () async {
    await expectLater(
      api.upload(set.id, newCave(Uuid.v7())),
      throwsA(
        isA<SilexgisProblemException>().having(
          (e) => e.code,
          'code',
          SilexgisCodes.clientUpdateRequired,
        ),
      ),
    );
  });

  test(
    'with held, the row waits under a review and nothing is written',
    () async {
      final id = Uuid.v7();
      final first = await api.upload(
        set.id,
        newCave(id, clientFeatures: SilexgisContract.clientFeatures),
      );
      expect(first.written, 0);
      final answer = first.rows.single;
      expect(answer.status, SyncRowStatus.held);
      expect(answer.revision, isNull);
      expect(answer.reviewId, isNotNull);

      // The same content again is the same proposal.
      final again = await api.upload(
        set.id,
        newCave(id, clientFeatures: SilexgisContract.clientFeatures),
      );
      expect(again.rows.single.status, SyncRowStatus.held);
      expect(again.rows.single.reviewId, answer.reviewId);

      // And nothing of it reaches anybody's download until it is accepted.
      final page = await api.download(set.id, pageSize: 500);
      expect(page.features.map((f) => f.id), isNot(contains(id.toString())));
    },
  );

  test('the reviews stream has nothing until somebody decides', () async {
    final page = await api.reviews(set.id);
    expect(page.reviews, isEmpty);
    expect(page.hasMore, isFalse);
  });

  group('a whole run, through the controller', () {
    late AppDatabase db;
    late SilexgisHeldRowRepository heldRows;
    late SilexgisSyncController controller;
    final caveId = Uuid.v7();

    setUpAll(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      late ChangeLogger loggerRef;
      final users = UserRepository(db, () => loggerRef);
      final currentUser = CurrentUserService(
        db,
        users,
        ConfigurationRepository(db),
      );
      await currentUser.initialize();
      final logger = loggerRef = ChangeLogger(db, currentUser);
      final localState = SilexgisLocalStateRepository(db);
      heldRows = SilexgisHeldRowRepository(db);

      final tokens = InMemoryRefreshTokenStore();
      final session = SilexgisAuthService(
        baseUri: baseUri,
        profileUuid: 'review-live',
        store: tokens,
      );
      await session.signIn(email: email, password: password);
      session.close();

      final profiles = SilexgisProfileRepository(
        ConfigurationRepository(db),
        tokens,
        localState,
      );
      await profiles.save(
        SilexgisProfile(
          profileUuid: 'review-live',
          displayName: 'Development server',
          baseUrl: baseUri.toString(),
          accountEmail: email,
          syncSetId: set.id,
          uploadsNewRoots: true,
        ),
      );
      controller = SilexgisSyncController(
        db: db,
        profiles: profiles,
        localState: localState,
        heldRows: heldRows,
        logger: logger,
        caves: CaveRepository(db, currentUser, logger),
        places: CavePlaceRepository(db, currentUser, logger),
        tokens: tokens,
      );

      await db
          .into(db.caves)
          .insert(
            Cave(
              uuid: caveId,
              title: 'Proposed ${caveId.toString().substring(0, 8)}',
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    });

    tearDownAll(() => db.close());

    test('a cave surveyed here goes up held and waits', () async {
      await controller.syncDefault();

      expect(
        controller.progress.phase,
        SilexgisSyncPhase.completed,
        reason: controller.progress.message,
      );
      expect(controller.progress.upload?.held, 1);
      expect(controller.progress.upload?.refusals, isEmpty);
      expect(controller.progress.reviews.waiting, 1);
      final held = await heldRows.readSection(
        'review-live',
        SyncUploadSection.rows,
      );
      expect(held[caveId]?.isWaiting, isTrue);
      // The caver's cave is still here, as they left it.
      expect(await db.select(db.caves).get(), isNotEmpty);
    });

    test('and is not sent again while it waits unchanged', () async {
      await controller.syncDefault();

      expect(
        controller.progress.phase,
        SilexgisSyncPhase.completed,
        reason: controller.progress.message,
      );
      expect(controller.progress.upload?.isEmpty, isTrue);
      expect(controller.progress.reviews.waiting, 1);
    });
  });
}
