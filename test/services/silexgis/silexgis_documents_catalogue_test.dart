import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_linker.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_title.dart';
import 'package:speleoloc/services/silexgis/silexgis_documents_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_document_updater.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_link_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/utils/clock.dart';

import 'contract_fixtures.dart';
import 'scripted_client.dart';
import 'token_source.dart';

/// The photo and document catalogue: read on its own cursor, metadata only,
/// and the one place a fetched document's title follows the server's.
void main() {
  const profileUuid = 'p-1';
  const setId = 'set-1';
  const capabilities = SilexgisCapabilities(
    contractVersion: 1,
    pageSizeMax: 500,
    uploadRowsMax: 500,
    features: <String>['download', 'documents'],
  );
  final clock = FakeClock(DateTime.utc(2026, 10, 28, 8));

  late AppDatabase db;
  late ChangeLogger logger;
  late SilexgisLocalStateRepository localState;
  late SilexgisDocumentCatalogueRepository catalogue;
  late SilexgisFileCopyRepository copies;
  late SilexgisServerLinkRepository serverLinks;

  final caveId = Uuid.v7();
  final documentId = Uuid.v7();

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
    logger = loggerRef = ChangeLogger(db, currentUser, clock: clock);
    localState = SilexgisLocalStateRepository(db, clock: clock);
    catalogue = SilexgisDocumentCatalogueRepository(db);
    copies = SilexgisFileCopyRepository(db, clock: clock);
    serverLinks = SilexgisServerLinkRepository(db, clock: clock);
  });
  tearDown(() => db.close());

  Map<String, Object?> recorded17() =>
      fillPlaceholders(
            ContractExchange('17-documents-first-page').responseBody,
            <String, String>{
              '<link>': 'link-1',
              '<document>': documentId.toString(),
              '<cave>': caveId.toString(),
              '<uuid-1>': 'version-1',
              '<timestamp>': '2026-10-27T10:00:00.000001Z',
              '<cursor>': 'documents-c1',
            },
          )!
          as Map<String, Object?>;

  Map<String, Object?> page({
    List<Map<String, Object?>> links = const <Map<String, Object?>>[],
    List<Map<String, Object?>> tombstones = const <Map<String, Object?>>[],
    String cursor = 'documents-c2',
  }) => <String, Object?>{
    'setRevision': 1,
    'settings': const <String, Object?>{},
    'links': links,
    'tombstones': tombstones,
    'nextCursor': cursor,
    'hasMore': false,
  };

  Map<String, Object?> link(
    String linkId, {
    Uuid? document,
    Uuid? target,
    String title = 'entrance.jpg',
    String? caption,
    String updatedAt = '2026-10-27T10:00:00.000001Z',
  }) => <String, Object?>{
    'id': linkId,
    'documentId': (document ?? documentId).toString(),
    'target': <String, Object?>{
      'kind': 'feature',
      'id': (target ?? caveId).toString(),
    },
    'role': 'photoEntrance',
    'caption': caption,
    'sortOrder': 0,
    'isPrimary': true,
    'inDefaultSet': true,
    'revision': updatedAt,
    'document': <String, Object?>{
      'id': (document ?? documentId).toString(),
      'title': title,
      'description': null,
      'fileKind': 'photo',
      'mimeType': 'image/jpeg',
      'sizeBytes': 1024,
      'sha256': 'ab' * 32,
      'versionId': 'version-1',
      'reach': 'original',
      'renditions': <int>[2400, 1200, 480, 160],
      'capturedAt': null,
      'createdAt': '2026-10-20T18:00:01.000001Z',
      'updatedAt': updatedAt,
    },
  };

  Future<SilexgisDocumentsReport> read(List<Map<String, Object?>> pages) {
    final client = ScriptedClient(<ScriptedResponse>[
      for (final p in pages)
        ScriptedResponse.json(
          path: SilexgisContract.documentsPath(setId),
          json: p,
        ),
    ]);
    return SilexgisDocumentsRunner(
      db: db,
      api: SilexgisSyncApi(
        SilexgisHttp(
          baseUri: Uri.parse('https://club.example.org'),
          tokens: FixedTokenSource(),
          client: client,
        ),
      ),
      localState: localState,
      catalogue: catalogue,
      heldDocuments: SilexgisHeldDocumentUpdater(
        db: db,
        logger: logger,
        localState: localState,
        profileUuid: profileUuid,
        clock: clock,
      ),
      linker: SilexgisDocumentLinker(
        db: db,
        logger: logger,
        catalogue: catalogue,
        copies: copies,
        serverLinks: serverLinks,
        profileUuid: profileUuid,
        clock: clock,
      ),
      profileUuid: profileUuid,
    ).run(setId, capabilities: capabilities);
  }

  group('the documents stream', () {
    test('17: catalogued on its own cursor, and nothing fetched', () async {
      final report = await read(<Map<String, Object?>>[recorded17()]);

      expect(report.links, 1);
      final entry = (await catalogue.entriesFor(profileUuid, caveId)).single;
      expect(entry.documentId, documentId);
      expect(entry.reach, SyncDocumentReach.locationFree);
      expect(entry.document.sizeBytes, isNull);
      expect(entry.document.sha256, isNull);
      expect(entry.renditions, <int>[2400, 1200, 480, 160]);
      // The whole picture, or any of its sizes, may be asked for.
      expect(entry.offered.map((r) => r.toString()), <String>[
        'original',
        '2400',
        '1200',
        '480',
        '160',
      ]);
      expect(entry.sizeOf(entry.offered.first), isNull);

      expect(await db.select(db.documentationFiles).get(), isEmpty);
      expect(
        (await localState.readStreamCursor(
          profileUuid,
          setId,
          SyncStream.documents,
        )).cursor,
        'documents-c1',
      );
      expect(
        (await localState.readSetState(profileUuid, setId)).cursor,
        isNull,
      );
    });

    test('a link sent again replaces the copy held', () async {
      await read(<Map<String, Object?>>[
        page(links: <Map<String, Object?>>[link('link-1')]),
      ]);
      await read(<Map<String, Object?>>[
        page(
          links: <Map<String, Object?>>[
            link('link-1', caption: 'In winter', title: 'renamed.jpg'),
          ],
        ),
      ]);

      final entry = (await catalogue.entriesFor(profileUuid, caveId)).single;
      expect(entry.link.caption, 'In winter');
      expect(entry.document.title, 'renamed.jpg');
      expect(entry.link.inDefaultSet, isTrue);
    });

    test(
      'a tombstone removes the link, and an unlinked document goes too',
      () async {
        final otherCave = Uuid.v7();
        await read(<Map<String, Object?>>[
          page(
            links: <Map<String, Object?>>[
              link('link-1'),
              link('link-2', target: otherCave),
            ],
          ),
        ]);

        final report = await read(<Map<String, Object?>>[
          page(
            tombstones: <Map<String, Object?>>[
              <String, Object?>{
                'id': 'link-1',
                'deletedAt': '2026-10-28T07:00Z',
              },
              // A link never held: a no-op.
              <String, Object?>{
                'id': 'link-9',
                'deletedAt': '2026-10-28T07:00Z',
              },
            ],
          ),
        ]);

        expect(report.removed, 1);
        expect(await catalogue.entriesFor(profileUuid, caveId), isEmpty);
        // Still hung on the other cave.
        expect(await catalogue.document(profileUuid, documentId), isNotNull);

        await read(<Map<String, Object?>>[
          page(
            tombstones: <Map<String, Object?>>[
              <String, Object?>{
                'id': 'link-2',
                'deletedAt': '2026-10-28T07:01Z',
              },
            ],
          ),
        ]);
        expect(await catalogue.document(profileUuid, documentId), isNull);
      },
    );

    test('the uploader is kept when the server names one', () async {
      final withUploader = link('link-1');
      (withUploader['document']!
              as Map<String, Object?>)['createdByDeviceUserId'] =
          'phone-user-1';
      await read(<Map<String, Object?>>[
        page(links: <Map<String, Object?>>[withUploader]),
      ]);
      expect(
        (await catalogue.document(
          profileUuid,
          documentId,
        ))!.createdByDeviceUserId,
        'phone-user-1',
      );
    });

    test('clearing the catalogue drops its position too', () async {
      await read(<Map<String, Object?>>[recorded17()]);

      await catalogue.clear(profileUuid);

      expect(await catalogue.isEmpty(profileUuid), isTrue);
      expect(
        (await localState.readStreamCursor(
          profileUuid,
          setId,
          SyncStream.documents,
        )).cursor,
        isNull,
      );
    });
  });

  group('a fetched document follows the catalogue', () {
    /// A document this device fetched, agreed with the server at [title].
    Future<void> fetched({String title = 'entrance.jpg'}) async {
      final t0 = clock.nowMs();
      await db
          .into(db.documentationFiles)
          .insert(
            DocumentationFilesCompanion.insert(
              uuid: documentId,
              title: title,
              fileName: 'documentation_files/srv_entrance.jpg',
              fileSize: 1024,
              fileType: 'photo',
            ).copyWith(updatedAt: Value(t0)),
          );
      await localState.writeRevision(
        profileUuid,
        documentId,
        entityTable: SilexgisHeldDocumentUpdater.entityTable,
        wireKind: SilexgisHeldDocumentUpdater.wireKind,
        revision: '2026-10-27T10:00:00.000001Z',
        localUpdatedAt: t0,
      );
    }

    Future<DocumentationFile> local() => (db.select(
      db.documentationFiles,
    )..where((t) => t.uuid.equalsValue(documentId))).getSingle();

    test('a renamed document is renamed here, cut and unlogged', () async {
      await fetched();
      clock.advance(const Duration(minutes: 1));
      final longTitle = 'A' * 70;

      final report = await read(<Map<String, Object?>>[
        page(
          links: <Map<String, Object?>>[
            link(
              'link-1',
              title: longTitle,
              updatedAt: '2026-10-28T08:00:00.000001Z',
            ),
          ],
        ),
      ]);

      expect(report.renamed, 1);
      final row = await local();
      expect(row.title, 'A' * 50);
      // The full title stays in the catalogue, and the cut one is not a
      // change the caver made.
      final full = (await catalogue.document(profileUuid, documentId))!.title;
      expect(full, longTitle);
      expect(SilexgisDocumentTitle.changedLocally(row.title, full), isFalse);
      // Agreed again: not an edit waiting to go up.
      final stored = (await localState.readRevisions(profileUuid))[documentId]!;
      expect(stored.revision, '2026-10-28T08:00:00.000001Z');
      expect(stored.agreesWith(row.updatedAt), isTrue);
      expect(await db.select(db.changeLog).get(), isEmpty);
    });

    test('an unsent local edit is not written over', () async {
      await fetched();
      clock.advance(const Duration(minutes: 1));
      await (db.update(
        db.documentationFiles,
      )..where((t) => t.uuid.equalsValue(documentId))).write(
        DocumentationFilesCompanion(
          title: const Value('My own name'),
          updatedAt: Value(clock.nowMs()),
        ),
      );

      final report = await read(<Map<String, Object?>>[
        page(
          links: <Map<String, Object?>>[
            link(
              'link-1',
              title: 'renamed.jpg',
              updatedAt: '2026-10-28T08:00Z',
            ),
          ],
        ),
      ]);

      expect(report.renamed, 0);
      expect((await local()).title, 'My own name');
    });

    test('a file the device never fetched is not touched', () async {
      // Same identifier, but nothing says the two sides ever agreed on it.
      await db
          .into(db.documentationFiles)
          .insert(
            DocumentationFilesCompanion.insert(
              uuid: documentId,
              title: 'Mine',
              fileName: 'documentation_files/doc_mine.jpg',
              fileSize: 10,
              fileType: 'photo',
            ),
          );

      await read(<Map<String, Object?>>[
        page(links: <Map<String, Object?>>[link('link-1', title: 'Theirs')]),
      ]);

      expect((await local()).title, 'Mine');
    });
  });

  test('a title is cut by characters, not by halves of one', () {
    final title = '${'ă' * 49}🦇tail';
    final cut = SilexgisDocumentTitle.local(title);
    expect(cut.runes.length, 50);
    expect(cut.endsWith('🦇'), isTrue);
    expect(SilexgisDocumentTitle.changedLocally('Other', title), isTrue);
  });

  group('a fetched document is hung on what the device comes to hold', () {
    /// A file fetched while the device held none of its features.
    Future<void> fetchedBeforeItsFeature() async {
      await db
          .into(db.documentationFiles)
          .insert(
            DocumentationFilesCompanion.insert(
              uuid: documentId,
              title: 'entrance.jpg',
              fileName: 'documentation_files/srv_entrance.jpg',
              fileSize: 1024,
              fileType: 'photo',
            ),
          );
      await copies.register(
        SilexgisFileCopyEntry(
          documentUuid: documentId,
          heldAs: SilexgisHeldAs.original,
          origin: SilexgisCopyOrigin.server,
          versionId: 'version-1',
        ),
      );
    }

    Future<List<DocumentationFilesToGeofeature>> links() =>
        db.select(db.documentationFilesToGeofeatures).get();

    test('on the next catalogue read, unlogged and recorded', () async {
      await fetchedBeforeItsFeature();
      await read(<Map<String, Object?>>[
        page(links: <Map<String, Object?>>[link('link-1')]),
      ]);
      expect(await links(), isEmpty);

      // The cave arrives with a later feature download.
      await db.into(db.caves).insert(Cave(uuid: caveId, title: 'Invented'));
      final report = await read(<Map<String, Object?>>[page()]);

      expect(report.linked, 1);
      final hung = (await links()).single;
      expect(hung.documentationFileUuid, documentId);
      expect(hung.geofeatureUuid, caveId);
      expect(hung.geofeatureType, GeofeatureType.cave.dbValue);
      expect(await db.select(db.changeLog).get(), isEmpty);
      final held = await serverLinks.readAll(profileUuid);
      expect(held[(documentId, caveId)]!.linkId, 'link-1');

      // Once.
      expect((await read(<Map<String, Object?>>[page()])).linked, 0);
      expect(await links(), hasLength(1));
    });

    test('a link the caver took down is not hung again', () async {
      await fetchedBeforeItsFeature();
      await db.into(db.caves).insert(Cave(uuid: caveId, title: 'Invented'));
      await read(<Map<String, Object?>>[
        page(links: <Map<String, Object?>>[link('link-1')]),
      ]);
      expect(await links(), hasLength(1));

      await db.delete(db.documentationFilesToGeofeatures).go();
      final report = await read(<Map<String, Object?>>[page()]);

      expect(report.linked, 0);
      expect(await links(), isEmpty);
      // Still held there: the removal is what goes up.
      expect(
        (await serverLinks.readAll(profileUuid)).keys,
        contains((documentId, caveId)),
      );
    });

    test('a file of the caver\'s own is not hung by the catalogue', () async {
      await db
          .into(db.documentationFiles)
          .insert(
            DocumentationFilesCompanion.insert(
              uuid: documentId,
              title: 'Mine',
              fileName: 'documentation_files/doc_mine.jpg',
              fileSize: 10,
              fileType: 'photo',
            ),
          );
      await db.into(db.caves).insert(Cave(uuid: caveId, title: 'Invented'));

      await read(<Map<String, Object?>>[
        page(links: <Map<String, Object?>>[link('link-1')]),
      ]);

      expect(await links(), isEmpty);
    });
  });
}
