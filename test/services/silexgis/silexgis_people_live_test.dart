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
import 'package:speleoloc/services/silexgis/model/sync_people.dart';
import 'package:speleoloc/services/silexgis/model/sync_set.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_batch.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
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
import 'package:speleoloc/services/silexgis/silexgis_sync_controller.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_progress.dart';
import 'package:speleoloc/services/user_repository.dart';

import 'live_server.dart';

/// The people directory, against a real installation.
///
/// Off by default, like every live test. To run it:
///
/// 1. From a SilexGIS checkout: `node deploy/speleoloc-dev.mjs up`.
/// 2. `SPELEO_LOC_SILEXGIS_LIVE=1 flutter test test/services/silexgis/silexgis_people_live_test.dart`
///
/// `SPELEO_LOC_SILEXGIS_URL` overrides the base address.
void main() {
  final env = Platform.environment;
  if (env['SPELEO_LOC_SILEXGIS_LIVE'] != '1') {
    test(
      'SilexGIS people live test skipped (set SPELEO_LOC_SILEXGIS_LIVE=1)',
      () {},
    );
    return;
  }

  final baseUri = Uri.parse(
    env['SPELEO_LOC_SILEXGIS_URL'] ?? 'http://127.0.0.1:5205',
  );
  // The development server's plain member: the directory is on, and this
  // account may be told who people are.
  const email = 'member@dev.local';
  const password = 'dev-member-pass-1';
  const demoCaver = 'Demo Caver';

  late SilexgisAuthService auth;
  late SilexgisSyncApi api;
  late SyncSet set;

  setUpAll(() async {
    auth = SilexgisAuthService(
      baseUri: baseUri,
      profileUuid: 'people-live-test',
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
        name: 'people live ${DateTime.now().millisecondsSinceEpoch}',
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

  Future<String> demoCaverId() async {
    final directory = await api.people();
    return directory.people.firstWhere((p) => p.fullName == demoCaver).id;
  }

  test('the installation offers the directory to this account', () async {
    expect((await api.capabilities()).servesPeople, isTrue);
  });

  test('the directory lists the club member, by name only', () async {
    final directory = await api.people();
    final caver = directory.people.firstWhere((p) => p.fullName == demoCaver);
    expect(caver.hasAccount, isFalse);
    expect(caver.isMe, isFalse);
    // The member's phone already reported `democaver`, linked to that person.
    expect(directory.links.map((l) => l.caverId), contains(caver.id));
  });

  test('a phone user sent with that caver is created, and linked', () async {
    final caverId = await demoCaverId();
    final user = Uuid.v7();
    final result = await api.upload(
      set.id,
      SyncUploadBatch(
        batchId: Uuid.v7().toString(),
        clientFeatures: SilexgisContract.clientFeatures,
        sections: <SyncUploadSection, List<SyncUploadItem>>{
          SyncUploadSection.people: <SyncUploadItem>[
            SyncUploadPerson(
              deviceUserId: user.toString(),
              username: 'live${user.toString().substring(0, 8)}',
              firstName: 'Invented',
              lastName: 'Person',
              caverId: caverId,
            ),
          ],
        },
      ),
    );

    final answer = result.answersFor(SyncUploadSection.people)!.single;
    expect(answer.id, user.toString());
    expect(answer.status, SyncRowStatus.created);
    expect(answer.revision, isNull);

    final links = (await api.people()).links;
    expect(
      links.firstWhere((l) => l.deviceUserId == user.toString()).caverId,
      caverId,
    );
  });

  test('a caver the directory does not list is refused', () async {
    final result = await api.upload(
      set.id,
      SyncUploadBatch(
        batchId: Uuid.v7().toString(),
        clientFeatures: SilexgisContract.clientFeatures,
        sections: <SyncUploadSection, List<SyncUploadItem>>{
          SyncUploadSection.people: <SyncUploadItem>[
            SyncUploadPerson(
              deviceUserId: Uuid.v7().toString(),
              username: 'unlisted',
              caverId: Uuid.v7().toString(),
            ),
          ],
        },
      ),
    );
    final answer = result.answersFor(SyncUploadSection.people)!.single;
    expect(answer.status, SyncRowStatus.rejected);
    expect(answer.code, 'sync.person_not_listed');
  });

  group('a whole run, through the controller', () {
    late AppDatabase db;
    late SilexgisPeopleRepository people;
    late SilexgisSyncController controller;
    final user = Uuid.v7();

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
      people = SilexgisPeopleRepository(db);

      final tokens = InMemoryRefreshTokenStore();
      final session = SilexgisAuthService(
        baseUri: baseUri,
        profileUuid: 'people-live',
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
          profileUuid: 'people-live',
          displayName: 'Development server',
          baseUrl: baseUri.toString(),
          accountEmail: email,
          syncSetId: set.id,
        ),
      );
      controller = SilexgisSyncController(
        db: db,
        profiles: profiles,
        localState: localState,
        heldRows: SilexgisHeldRowRepository(db),
        people: people,
        catalogue: SilexgisDocumentCatalogueRepository(db),
        logger: logger,
        caves: CaveRepository(db, currentUser, logger),
        places: CavePlaceRepository(db, currentUser, logger),
        tokens: tokens,
      );

      await db
          .into(db.users)
          .insert(
            User(
              uuid: user,
              username: 'phone${user.toString().substring(0, 8)}',
              firstName: 'Invented',
            ),
          );
    });

    tearDownAll(() => db.close());

    test('reads the directory onto the device', () async {
      await controller.syncDefault();

      expect(
        controller.progress.phase,
        SilexgisSyncPhase.completed,
        reason: controller.progress.message,
      );
      final directory = await people.readDirectory('people-live');
      expect(directory.map((c) => c.fullName), contains(demoCaver));
    });

    test('a caver chosen here goes up and stands', () async {
      final caverId = (await people.readDirectory(
        'people-live',
      )).firstWhere((c) => c.fullName == demoCaver).caverId;
      await people.choose('people-live', user, caverId);

      await controller.syncDefault();

      expect(
        controller.progress.phase,
        SilexgisSyncPhase.completed,
        reason: controller.progress.message,
      );
      expect(controller.progress.upload?.refusals, isEmpty);
      final link = (await people.readLink('people-live', user))!;
      expect(link.caverId, caverId);
      expect(link.choicePending, isFalse);
      expect(link.source, SilexgisLinkSource.phone);
    });
  });
}
