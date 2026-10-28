import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_set.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_link_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_staged_upload_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_controller.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_progress.dart';
import 'package:speleoloc/services/user_repository.dart';

import 'live_server.dart';

/// Photos and documents up, against a real installation.
///
/// Off by default, like every live test. To run it:
///
/// 1. From a SilexGIS checkout: `node deploy/speleoloc-dev.mjs up`.
/// 2. `SPELEO_LOC_SILEXGIS_LIVE=1 flutter test test/services/silexgis/silexgis_documents_upload_live_test.dart`
///
/// `SPELEO_LOC_SILEXGIS_URL` overrides the base address. The photograph is
/// drawn by the test itself; nothing real is sent. The member may not hang
/// files on the administrator's caves, so it surveys a cave of its own: a
/// cave the same upload creates is exempt from the target checks.
void main() {
  final env = Platform.environment;
  if (env['SPELEO_LOC_SILEXGIS_LIVE'] != '1') {
    test(
      'SilexGIS documents upload live test skipped '
      '(set SPELEO_LOC_SILEXGIS_LIVE=1)',
      () {},
    );
    return;
  }

  final baseUri = Uri.parse(
    env['SPELEO_LOC_SILEXGIS_URL'] ?? 'http://127.0.0.1:5205',
  );
  const email = 'member@dev.local';
  const password = 'dev-member-pass-1';
  const profileUuid = 'documents-upload-live';

  late SilexgisAuthService auth;
  late SilexgisSyncApi api;
  late SyncSet set;

  late Directory base;
  late AppDatabase db;
  late SilexgisSyncController controller;
  late SilexgisDocumentCatalogueRepository catalogue;
  late SilexgisStagedUploadRepository staged;
  late SilexgisServerLinkRepository serverLinks;
  late SilexgisLocalStateRepository localState;

  final areaId = Uuid.v7();
  final caveId = Uuid.v7();
  final documentId = Uuid.v7();
  late String photoHash;
  late int photoSize;

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
        name: 'documents upload live ${DateTime.now().millisecondsSinceEpoch}',
        cavingGroupId: await demoCavingGroupId(baseUri, token),
        uploadVisibility: SyncVisibility.cavingGroup,
        rootFeatureIds: roots,
        settings: const <String, Object?>{'pciStrategy': 'ro-default'},
      ),
    );

    base = await Directory.systemTemp.createTemp('silexgis_docs_up_live_');
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
    localState = SilexgisLocalStateRepository(db);
    catalogue = SilexgisDocumentCatalogueRepository(db);
    staged = SilexgisStagedUploadRepository(db);
    serverLinks = SilexgisServerLinkRepository(db);

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
      catalogue: catalogue,
      logger: logger,
      caves: CaveRepository(db, currentUser, logger),
      places: CavePlaceRepository(db, currentUser, logger),
      tokens: tokens,
      staged: staged,
      serverLinks: serverLinks,
      documentsDir: () async => base,
    );

    // An invented picture, drawn here: a gradient, no camera, no position.
    final picture = img.Image(width: 160, height: 120);
    for (final pixel in picture) {
      pixel
        ..r = pixel.x
        ..g = pixel.y * 2
        ..b = 128;
    }
    final bytes = img.encodeJpg(picture, quality: 80);
    photoHash = sha256.convert(bytes).toString();
    photoSize = bytes.length;
    const relPath = 'documentation_files/doc_1761000000000_invented_live.jpg';
    final file = File('${base.path}/$relPath');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);

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
            title: 'Peștera Foto $tag',
            surfaceAreaUuid: areaId,
            caveLocalIndex: 'F1',
            updatedAt: now,
          ),
        );
    await db
        .into(db.documentationFiles)
        .insert(
          DocumentationFilesCompanion.insert(
            uuid: documentId,
            title: 'Invented entrance $tag',
            fileName: relPath,
            fileSize: bytes.length,
            fileType: 'photo',
          ).copyWith(
            description: const Value('Drawn by the live test'),
            fileHash: Value(photoHash),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    await db
        .into(db.documentationFilesToGeofeatures)
        .insert(
          DocumentationFilesToGeofeaturesCompanion.insert(
            uuid: Uuid.v7(),
            geofeatureType: 'cave',
            documentationFileUuid: documentId,
            geofeatureUuid: Value(caveId),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  });

  tearDownAll(() async {
    await api.deleteSet(set.id);
    auth.close();
    await db.close();
    await base.delete(recursive: true);
  });

  test('the installation takes documents from this account', () async {
    final capabilities = await api.capabilities();
    expect(capabilities.servesDocumentUpload, isTrue);
    expect(capabilities.servesDocuments, isTrue);
  });

  test(
    'the picture is staged and sent, hung on the cave sent with it',
    () async {
      await controller.syncDefault();

      final progress = controller.progress;
      expect(
        progress.phase,
        SilexgisSyncPhase.completed,
        reason: progress.message,
      );
      expect(
        progress.upload?.refusals,
        isEmpty,
        reason: progress.upload?.refusals
            .map((r) => '${r.entityTable} ${r.result.code} ${r.result.detail}')
            .join('; '),
      );
      expect(progress.files.staged, 1);
      expect(progress.files.held, 0);
      // The area, the cave, the document and its link.
      expect(progress.upload?.written, 4);

      final adopted = (await staged.read(profileUuid, documentId))!;
      expect(adopted.state, SilexgisStagedState.adopted);
      expect(adopted.sha256, photoHash);
      expect(await localState.readRevision(profileUuid, documentId), isNotNull);
      final link = (await serverLinks.readAll(
        profileUuid,
      ))[(documentId, caveId)];
      expect(link?.linkId, isNotNull);
    },
  );

  test('the next run, once the massif is carried, lists it', () async {
    // A set names roots, and the new massif is not one yet: naming it is
    // what makes the device carry it, and with it the cave's catalogue.
    final current = await api.getSet(set.id);
    await api.replaceSet(
      set.id,
      current.toWrite().copyWith(
        rootFeatureIds: <String>[...current.rootFeatureIds, areaId.toString()],
      ),
    );

    await controller.syncDefault();
    expect(
      controller.progress.phase,
      SilexgisSyncPhase.completed,
      reason: controller.progress.message,
    );
    // Nothing went up a second time.
    expect(controller.progress.upload?.batches ?? 0, 0);
    expect(controller.progress.files.staged, 0);

    final entries = await catalogue.entriesFor(profileUuid, caveId);
    final entry = entries.singleWhere((e) => e.documentId == documentId);
    expect(entry.document.title, startsWith('Invented entrance'));
    expect(entry.document.fileKind, 'photo');
    expect(entry.document.sizeBytes, photoSize);
    expect(entry.document.sha256?.toLowerCase(), photoHash);
    // Its uploader's own file: handed over as stored.
    expect(entry.reach, SyncDocumentReach.original);
    expect(
      entry.link.linkId,
      (await serverLinks.readAll(profileUuid))[(documentId, caveId)]!.linkId,
    );
  });
}
