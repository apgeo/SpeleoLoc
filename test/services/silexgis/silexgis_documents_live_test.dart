import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/documentation_repository.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_file_links.dart';
import 'package:speleoloc/services/silexgis/model/sync_set.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_downloader.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_file_store.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_importer.dart';
import 'package:speleoloc/services/silexgis/silexgis_documents_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_fetcher.dart';
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

/// Photos and documents down, against a real installation.
///
/// Off by default, like every live test. To run it:
///
/// 1. From a SilexGIS checkout: `node deploy/speleoloc-dev.mjs up`.
/// 2. `SPELEO_LOC_SILEXGIS_LIVE=1 flutter test test/services/silexgis/silexgis_documents_live_test.dart`
///
/// `SPELEO_LOC_SILEXGIS_URL` overrides the base address. The photos are the
/// development server's generated pictures; only their sizes and hashes are
/// looked at.
void main() {
  final env = Platform.environment;
  if (env['SPELEO_LOC_SILEXGIS_LIVE'] != '1') {
    test(
      'SilexGIS documents live test skipped (set SPELEO_LOC_SILEXGIS_LIVE=1)',
      () {},
    );
    return;
  }

  final baseUri = Uri.parse(
    env['SPELEO_LOC_SILEXGIS_URL'] ?? 'http://127.0.0.1:5205',
  );
  // The plain member: the open cave's photo is handed over as stored, the
  // one also hung on the protected cave without its position.
  const email = 'member@dev.local';
  const password = 'dev-member-pass-1';
  const profileUuid = 'documents-live';
  const openPhoto = 'Demo photo — open cave';
  const sharedPhoto = 'Demo photo — open and protected caves';

  late SilexgisAuthService auth;
  late SilexgisSyncApi api;
  late SyncSet set;
  late String caveId;

  late Directory base;
  late AppDatabase db;
  late SilexgisSyncController controller;
  late SilexgisDocumentCatalogueRepository catalogue;
  late SilexgisFileCopyRepository copies;
  late SilexgisDocumentsService documents;

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
    caveId = roots.single;
    set = await api.createSet(
      SyncSetWrite(
        name: 'documents live ${DateTime.now().millisecondsSinceEpoch}',
        cavingGroupId: await demoCavingGroupId(baseUri, token),
        uploadVisibility: SyncVisibility.cavingGroup,
        rootFeatureIds: roots,
        settings: const <String, Object?>{'pciStrategy': 'ro-default'},
      ),
    );

    base = await Directory.systemTemp.createTemp('silexgis_documents_live_');
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
    catalogue = SilexgisDocumentCatalogueRepository(db);
    copies = SilexgisFileCopyRepository(db);

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
    );
    documents = SilexgisDocumentsService(
      profiles: profiles,
      catalogue: catalogue,
      documents: DocumentationRepository(db, logger, currentUser),
      // The session signed in above, whose refresh token the store holds.
      sessionBuilder: (_) => SilexgisSession(auth: auth, api: api),
      downloaderBuilder: (profile, api) => SilexgisDocumentDownloader(
        db: db,
        api: api,
        fetcher: SilexgisFileFetcher(baseUri: profile.baseUri),
        store: SilexgisDocumentFileStore(baseDir: () async => base),
        catalogue: catalogue,
        importer: SilexgisDocumentImporter(
          db: db,
          logger: logger,
          localState: localState,
          copies: copies,
          profileUuid: profile.profileUuid,
        ),
        profileUuid: profile.profileUuid,
      ),
    );
  });

  tearDownAll(() async {
    await api.deleteSet(set.id);
    auth.close();
    await db.close();
    await base.delete(recursive: true);
  });

  Future<SilexgisCatalogueEntry> catalogued(String title) async =>
      (await catalogue.entriesFor(
        profileUuid,
        Uuid.parse(caveId),
      )).firstWhere((e) => e.document.title == title);

  test('the installation offers documents to this account', () async {
    expect((await api.capabilities()).servesDocuments, isTrue);
  });

  test(
    'a run catalogues the cave\'s photos and fetches none of them',
    () async {
      await controller.syncDefault();

      expect(
        controller.progress.phase,
        SilexgisSyncPhase.completed,
        reason: controller.progress.message,
      );
      final open = await catalogued(openPhoto);
      expect(open.reach, SyncDocumentReach.original);
      expect(open.document.sizeBytes, isNotNull);
      expect(open.document.sha256, isNotNull);

      final shared = await catalogued(sharedPhoto);
      expect(shared.reach, SyncDocumentReach.locationFree);
      expect(shared.document.sizeBytes, isNull);
      expect(shared.document.sha256, isNull);

      expect(await db.select(db.documentationFiles).get(), isEmpty);
      final offered = (await documents.forFeature(Uuid.parse(caveId)))!;
      expect(
        offered.documents.map((d) => d.title),
        containsAll(<String>[openPhoto, sharedPhoto]),
      );
    },
  );

  test('both are fetched, each held as what it is', () async {
    final open = await catalogued(openPhoto);
    final shared = await catalogued(sharedPhoto);

    final summary = await documents.download(<SilexgisDownloadRequest>[
      SilexgisDownloadRequest(
        documentId: open.documentId,
        rendition: SyncRendition.original,
      ),
      SilexgisDownloadRequest(
        documentId: shared.documentId,
        rendition: SyncRendition.original,
      ),
    ]);

    expect(
      summary.results.map((r) => r.outcome),
      everyElement(SilexgisDownloadOutcome.downloaded),
      reason: summary.results.map((r) => r.detail).join('; '),
    );

    final original = await (db.select(
      db.documentationFiles,
    )..where((t) => t.uuid.equalsValue(open.documentId))).getSingle();
    final onDisk = File('${base.path}/${original.fileName}');
    // The bytes themselves, measured here, against the catalogue's numbers.
    expect(
      (await sha256.bind(onDisk.openRead()).first).toString(),
      open.document.sha256!.toLowerCase(),
    );
    expect(await onDisk.length(), open.document.sizeBytes);
    expect(
      (await copies.read(open.documentId))!.heldAs,
      SilexgisHeldAs.original,
    );

    final copy = await (db.select(
      db.documentationFiles,
    )..where((t) => t.uuid.equalsValue(shared.documentId))).getSingle();
    expect(copy.fileHash, isNotNull);
    expect(
      (await copies.read(shared.documentId))!.heldAs,
      SilexgisHeldAs.locationFree,
    );

    // Hung on the cave the device carries.
    final links = await db.select(db.documentationFilesToGeofeatures).get();
    expect(
      links
          .where((l) => l.geofeatureUuid == Uuid.parse(caveId))
          .map((l) => l.documentationFileUuid),
      containsAll(<Uuid>[open.documentId, shared.documentId]),
    );
    // Server-driven: nothing in the change log.
    expect(
      (await db.select(db.changeLog).get()).where(
        (c) => c.entityTable == 'documentation_files',
      ),
      isEmpty,
    );
  });

  test('a file held is not fetched again, and is no longer offered', () async {
    final open = await catalogued(openPhoto);
    final summary = await documents.download(<SilexgisDownloadRequest>[
      SilexgisDownloadRequest(
        documentId: open.documentId,
        rendition: SyncRendition.original,
      ),
    ]);
    expect(summary.results.single.outcome, SilexgisDownloadOutcome.alreadyHeld);
    final offered = await documents.forFeature(Uuid.parse(caveId));
    expect(
      offered?.documents.map((d) => d.title) ?? const <String>[],
      isNot(contains(openPhoto)),
    );
  });
}
