@Tags(['live'])
library;

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
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
import 'package:speleoloc/services/silexgis/model/sync_set.dart';
import 'package:speleoloc/services/silexgis/model/sync_survey_models.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_controller.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_progress.dart';
import 'package:speleoloc/services/user_repository.dart';

import 'live_server.dart';

/// Survey models and places at their stations, against a real installation.
///
/// Off by default, like every live test. To run it:
///
/// 1. From a SilexGIS checkout: `node deploy/speleoloc-dev.mjs up`.
/// 2. `SPELEO_LOC_SILEXGIS_LIVE=1 flutter test test/services/silexgis/silexgis_survey_models_live_test.dart`
///
/// The member is handed the seeded models of `Peștera Demo Mare` with their
/// two mappings, and the files verified against what the stream lists. The
/// seeded places are the administrator's, so the member then surveys a cave
/// of its own, attaches the invented test survey to it, puts a place at one
/// of its stations, moves it to another, and takes it off.
void main() {
  final env = Platform.environment;
  final skip = liveSkipReason(env);
  if (skip != null) {
    // Registered as skipped rather than left out, so a run reports it.
    test('SilexGIS survey models live test', () {}, skip: skip);
    return;
  }

  final baseUri = liveBaseUri(env);
  const email = 'member@dev.local';
  const password = 'dev-member-pass-1';
  const profileUuid = 'models-live';

  late SilexgisAuthService auth;
  late SilexgisSyncApi api;
  late SyncSet set;

  late Directory base;
  late AppDatabase db;
  late SilexgisSyncController controller;
  late SilexgisLocalStateRepository localState;
  late SilexgisSurveyModelRepository models;

  final areaId = Uuid.v7();
  final caveId = Uuid.v7();
  final placeId = Uuid.v7();
  final surveyId = Uuid.v7();
  final mappingId = Uuid.v7();

  setUpAll(() async {
    final tokens = InMemoryRefreshTokenStore();
    auth = SilexgisAuthService(
      baseUri: baseUri,
      profileUuid: profileUuid,
      store: tokens,
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
        name: 'models live ${DateTime.now().millisecondsSinceEpoch}',
        cavingGroupId: await demoCavingGroupId(baseUri, token),
        uploadVisibility: SyncVisibility.cavingGroup,
        rootFeatureIds: roots,
        settings: const <String, Object?>{'pciStrategy': 'ro-default'},
      ),
    );

    base = await Directory.systemTemp.createTemp('silexgis_models_live_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger loggerRef;
    final currentUser = CurrentUserService(
      db,
      UserRepository(db, () => loggerRef),
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    final logger = loggerRef = ChangeLogger(db, currentUser);
    localState = SilexgisLocalStateRepository(db);
    models = SilexgisSurveyModelRepository(db);

    final profiles = SilexgisProfileRepository(
      ConfigurationRepository(db),
      tokens,
      localState,
    );
    await profiles.save(
      SilexgisProfile(
        profileUuid: profileUuid,
        displayName: 'Development server',
        baseUrl: baseUri.toString(),
        accountEmail: email,
        syncSetId: set.id,
        // The demo caves are the administrator's; what this device surveys
        // goes somewhere of its own.
        uploadsNewRoots: true,
        // No network to ask about here; the rule has its own tests.
        filesOnlyOverWifi: false,
      ),
    );
    controller = SilexgisSyncController(
      db: db,
      profiles: profiles,
      localState: localState,
      heldRows: SilexgisHeldRowRepository(db),
      people: SilexgisPeopleRepository(db),
      catalogue: SilexgisDocumentCatalogueRepository(db),
      logger: logger,
      caves: CaveRepository(db, currentUser, logger),
      places: CavePlaceRepository(db, currentUser, logger),
      tokens: tokens,
      surveyModels: models,
      documentsDir: () async => base,
    );
  });

  tearDownAll(() async {
    await api.deleteSet(set.id);
    auth.close();
    await db.close();
    await base.delete(recursive: true);
  });

  Future<void> sync() async {
    await controller.syncDefault();
    final progress = controller.progress;
    expect(
      progress.phase,
      SilexgisSyncPhase.completed,
      reason: progress.message,
    );
    expect(
      progress.upload?.refusals ?? const [],
      isEmpty,
      reason: progress.upload?.refusals
          .map((r) => '${r.entityTable} ${r.result.code} ${r.result.detail}')
          .join('; '),
    );
  }

  /// Every mapping the stream hands now, read from the beginning.
  Future<List<SyncPlaceStation>> readBack() async {
    final found = <SyncPlaceStation>[];
    String? cursor;
    var more = true;
    while (more) {
      final page = await api.surveyModels(set.id, cursor: cursor);
      found.addAll(page.placeStations);
      cursor = page.nextCursor;
      more = page.hasMore;
    }
    return found;
  }

  Future<CavePlace> placeTitled(String title) => (db.select(
    db.cavePlaces,
  )..where((t) => t.title.equals(title))).getSingle();

  Future<CavePlaceModelStation?> mappingOf(Uuid place) => (db.select(
    db.cavePlaceModelStations,
  )..where((t) => t.cavePlaceUuid.equalsValue(place))).getSingleOrNull();

  test('the installation serves survey models', () async {
    expect((await api.capabilities()).servesSurveyModels, isTrue);
  });

  test(
    'the member gets the cave\'s models, verified, with both mappings',
    () async {
      await sync();

      final listed = (await models.readAll(profileUuid)).values.toList();
      expect(listed.map((m) => m.format), containsAll(<String>['lox', '3d']));
      expect(listed.where((m) => m.isCurrent), hasLength(1));
      expect(
        listed.map((m) => m.name),
        isNot(contains('demo-protected-survey')),
      );
      for (final model in listed) {
        expect(model.fetchedVersionId, model.versionId, reason: model.name);
        final copy = (await (db.select(
          db.documentationFiles,
        )..where((t) => t.uuid.equalsValue(model.documentId))).getSingle());
        expect(copy.fileType, 'survey_model');
        final bytes = await File('${base.path}/${copy.fileName}').readAsBytes();
        expect(bytes, hasLength(model.sizeBytes));
        expect(sha256.convert(bytes).toString(), model.sha256?.toLowerCase());
        final origin = (await SilexgisFileCopyRepository(
          db,
        ).read(model.documentId))!.origin;
        expect(origin, SilexgisCopyOrigin.server);
      }

      final a = (await mappingOf((await placeTitled('Demo marker A')).uuid))!;
      expect(a.station, 'demo.2');
      expect(a.splayEast, isNull);
      expect(a.needsReview, 0);
      final c = (await mappingOf((await placeTitled('Demo marker C')).uuid))!;
      expect(c.station, 'demo.3');
      expect(
        <double?>[c.splayEast, c.splayNorth, c.splayUp],
        <double>[1.5, -0.5, 0.25],
      );
      expect(c.needsReview, 1);
      expect(await db.select(db.changeLog).get(), isEmpty);

      // A second run sends nothing and fetches nothing.
      await sync();
      expect(controller.progress.upload?.batches ?? 0, 0);
      expect(
        (await models.readAll(
          profileUuid,
        )).values.every((m) => m.fetchedVersionId == m.versionId),
        isTrue,
      );
    },
  );

  test('a place of its own at a station of its own survey goes up, moves '
      'and comes off', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final tag = caveId.toString().substring(0, 8);
    await db
        .into(db.surfaceAreas)
        .insert(
          SurfaceArea(
            uuid: areaId,
            title: 'Massif $tag',
            generalAreaIdentifier: 'DU',
            updatedAt: now,
          ),
        );
    await db
        .into(db.caves)
        .insert(
          Cave(
            uuid: caveId,
            title: 'Peștera Model $tag',
            surfaceAreaUuid: areaId,
            caveLocalIndex: 'M1',
            updatedAt: now,
          ),
        );
    await db
        .into(db.cavePlaces)
        .insert(
          CavePlace(
            uuid: placeId,
            title: 'Sala Modelului $tag',
            caveUuid: caveId,
            isEntrance: 0,
            isMainEntrance: 0,
            updatedAt: now,
          ),
        );
    // The invented survey this repository compiles; never real data.
    final bytes = await File(
      'test_data/cave_models/test_cave.lox',
    ).readAsBytes();
    const relPath = 'documentation_files/test_cave.lox';
    final file = File('${base.path}/$relPath');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    await db
        .into(db.documentationFiles)
        .insert(
          DocumentationFilesCompanion.insert(
            uuid: surveyId,
            title: 'test_cave.lox',
            fileName: relPath,
            fileSize: bytes.length,
            fileType: 'survey_model',
          ).copyWith(
            fileHash: Value(sha256.convert(bytes).toString()),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    await db
        .into(db.documentationFilesToGeofeatures)
        .insert(
          DocumentationFilesToGeofeaturesCompanion.insert(
            uuid: Uuid.v7(),
            geofeatureType: GeofeatureType.cave.dbValue,
            documentationFileUuid: surveyId,
            geofeatureUuid: Value(caveId),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    await db
        .into(db.cavePlaceModelStations)
        .insert(
          CavePlaceModelStationsCompanion.insert(
            uuid: mappingId,
            cavePlaceUuid: placeId,
            caveUuid: caveId,
            documentationFileUuid: surveyId,
            station: 'test_cave.main.3',
          ).copyWith(createdAt: Value(now), updatedAt: Value(now)),
        );

    // The survey file goes first; its mapping waits for it to be there.
    await sync();
    await sync();
    var there = (await readBack()).where((m) => m.id == '$mappingId').single;
    expect(there.documentId, '$surveyId');
    expect(there.surveyModelId, isNull);
    expect(there.placeId, '$placeId');
    expect(there.station, 'test_cave.main.3');
    // An uploaded survey file stays a document: it is no server model.
    expect(
      (await models.readAll(profileUuid)).values.map((m) => m.documentId),
      isNot(contains(surveyId)),
    );

    await (db.update(
      db.cavePlaceModelStations,
    )..where((t) => t.uuid.equalsValue(mappingId))).write(
      CavePlaceModelStationsCompanion(
        station: const Value('test_cave.side.3'),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    await sync();
    expect(controller.progress.upload?.written, 1);
    there = (await readBack()).where((m) => m.id == '$mappingId').single;
    expect(there.station, 'test_cave.side.3');

    await (db.delete(
      db.cavePlaceModelStations,
    )..where((t) => t.uuid.equalsValue(mappingId))).go();
    await sync();
    expect((await readBack()).where((m) => m.id == '$mappingId'), isEmpty);
    expect((await localState.readRevisions(profileUuid))[mappingId], isNull);
  });
}
