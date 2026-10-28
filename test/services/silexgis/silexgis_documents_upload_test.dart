import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_links_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_upload_planner.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_upload_run.dart';
import 'package:speleoloc/services/silexgis/silexgis_documents_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_sending_gate.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_stager.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_link_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_staged_upload_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_transfer_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_builder.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_runner.dart';
import 'package:speleoloc/utils/clock.dart';

import 'scripted_client.dart';
import 'token_source.dart';

/// Photos and documents up: which files go, what each row says, and what is
/// kept of each answer. Rule 13 is the thread through it — a copy the server
/// handed down without its location, or drew smaller, never goes up as bytes.
void main() {
  const profile = 'p-1';
  const setId = 'set-1';
  const transferId = 'transfer-1';
  const capabilities = SilexgisCapabilities(
    contractVersion: 1,
    pageSizeMax: 500,
    uploadRowsMax: 500,
    features: <String>['download', 'upload', 'documents', 'documentUpload'],
  );
  final clock = FakeClock(DateTime.utc(2026, 10, 28, 8));
  final uploadPath = SilexgisContract.uploadPath(setId);

  late Directory base;
  late AppDatabase db;
  late SilexgisLocalStateRepository localState;
  late SilexgisHeldRowRepository heldRows;
  late SilexgisFileCopyRepository copies;
  late SilexgisStagedUploadRepository staged;
  late SilexgisServerLinkRepository serverLinks;
  late SilexgisDocumentCatalogueRepository catalogue;

  final caveId = Uuid.v7();

  setUp(() async {
    base = await Directory.systemTemp.createTemp('silexgis_docs_up_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localState = SilexgisLocalStateRepository(db, clock: clock);
    heldRows = SilexgisHeldRowRepository(db, clock: clock);
    copies = SilexgisFileCopyRepository(db, clock: clock);
    staged = SilexgisStagedUploadRepository(db, clock: clock);
    serverLinks = SilexgisServerLinkRepository(db, clock: clock);
    catalogue = SilexgisDocumentCatalogueRepository(db);

    // A cave the installation holds, as last agreed.
    final t0 = clock.nowMs();
    await db
        .into(db.caves)
        .insert(Cave(uuid: caveId, title: 'Invented', updatedAt: t0));
    await localState.writeRevision(
      profile,
      caveId,
      entityTable: 'caves',
      wireKind: 'cave',
      revision: '2026-10-27T10:00:00Z',
      localUpdatedAt: t0,
    );
  });
  tearDown(() async {
    await db.close();
    await base.delete(recursive: true);
  });

  /// A documentation file with invented bytes, hung on [target].
  Future<(Uuid, List<int>)> photo(
    String name, {
    Uuid? target,
    String? description,
  }) async {
    final id = Uuid.v7();
    final bytes = utf8.encode('invented picture $name');
    final relPath = 'documentation_files/doc_1761000000000_$name';
    final file = File('${base.path}/$relPath');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    final now = clock.nowMs();
    await db
        .into(db.documentationFiles)
        .insert(
          DocumentationFilesCompanion.insert(
            uuid: id,
            title: name,
            fileName: relPath,
            fileSize: bytes.length,
            fileType: 'photo',
          ).copyWith(
            description: Value(description),
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
            geofeatureType: 'cave',
            documentationFileUuid: id,
            geofeatureUuid: Value(target ?? caveId),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return (id, bytes);
  }

  /// [id] as the installation holds it, agreed at the row's current stamp.
  Future<void> agreed(Uuid id, {String revision = 'r-1'}) async {
    final row = await (db.select(
      db.documentationFiles,
    )..where((t) => t.uuid.equalsValue(id))).getSingle();
    await localState.writeRevision(
      profile,
      id,
      entityTable: 'documentation_files',
      wireKind: 'document',
      revision: revision,
      localUpdatedAt: row.updatedAt,
    );
    await serverLinks.record(
      profile,
      SilexgisServerLinkEntry(
        documentUuid: id,
        targetKind: 'feature',
        targetId: caveId,
        linkId: 'link-of-$id',
      ),
    );
  }

  Future<void> editCaption(Uuid id, String caption) async {
    clock.advance(const Duration(minutes: 1));
    await (db.update(
      db.documentationFiles,
    )..where((t) => t.uuid.equalsValue(id))).write(
      DocumentationFilesCompanion(
        description: Value(caption),
        updatedAt: Value(clock.nowMs()),
      ),
    );
  }

  ScriptedResponse answer({
    List<Map<String, Object?>>? documents,
    List<Map<String, Object?>>? links,
  }) => ScriptedResponse.json(
    path: uploadPath,
    json: <String, Object?>{
      'batchId': 'b',
      'importBatchId': 'i',
      'replayed': false,
      'written': 0,
      'refused': 0,
      'rows': const <Object?>[],
      'conflicts': const <Object?>[],
      'duplicates': const <Object?>[],
      'documents': ?documents,
      'documentLinks': ?links,
    },
  );

  Map<String, Object?> verdict(
    String id,
    String status, {
    String? code,
    String? revision,
    String? reviewId,
  }) => <String, Object?>{
    'id': id,
    'status': status,
    'revision': revision ?? (code == null ? '2026-10-28T08:00:00Z' : null),
    'code': code,
    'detail': null,
    'reviewId': ?reviewId,
  };

  /// The transfer routes for one file of [bytes], sent whole.
  List<ScriptedResponse> staging(List<int> bytes, {String id = transferId}) {
    final path = SilexgisContract.fileUploadPath(id);
    return <ScriptedResponse>[
      ScriptedResponse.json(
        path: SilexgisContract.fileUploadsPath,
        status: 201,
        json: <String, Object?>{
          'id': id,
          'receivedBytes': 0,
          'chunkBytes': 8 * 1024 * 1024,
          'expiresAt': '2026-10-29T08:00:00Z',
        },
      ),
      ScriptedResponse.json(
        path: path,
        method: 'PUT',
        json: <String, Object?>{
          'id': id,
          'receivedBytes': bytes.length,
          'chunkBytes': 8 * 1024 * 1024,
        },
      ),
      ScriptedResponse.json(
        path: SilexgisContract.fileUploadCompletePath(id),
        json: <String, Object?>{
          'id': id,
          'sizeBytes': bytes.length,
          'sha256': sha256.convert(bytes).toString(),
          'mimeType': 'image/jpeg',
          'expiresAt': '2026-11-04T08:00:00Z',
        },
      ),
    ];
  }

  ScriptedResponse config() => ScriptedResponse.json(
    path: SilexgisContract.filesConfigPath,
    json: <String, Object?>{
      'maxUploadBytes': 1 << 30,
      'remainingBytes': null,
      'chunkBytes': 8 * 1024 * 1024,
    },
  );

  Future<(SilexgisUploadReport, SilexgisDocumentUploadRun)> run(
    ScriptedClient client, {
    SilexgisFileSendingGate gate = const SilexgisFilesAlwaysGo(),
  }) async {
    final http = SilexgisHttp(
      baseUri: Uri.parse('https://club.example.org'),
      tokens: FixedTokenSource(),
      client: client,
    );
    final documents = SilexgisDocumentUploadRun();
    final report = await SilexgisUploadRunner(
      api: SilexgisSyncApi(http),
      builder: SilexgisUploadBuilder(
        db: db,
        localState: localState,
        heldRows: heldRows,
        profileUuid: profile,
      ),
      localState: localState,
      heldRows: heldRows,
      profileUuid: profile,
      parts: [
        SilexgisDocumentsUploadPart(
          planner: SilexgisDocumentUploadPlanner(
            db: db,
            localState: localState,
            heldRows: heldRows,
            copies: copies,
            staged: staged,
            catalogue: catalogue,
            serverLinks: serverLinks,
            profileUuid: profile,
          ),
          run: documents,
          stager: SilexgisFileStager(
            api: SilexgisTransferApi(http),
            staged: staged,
            profileUuid: profile,
            clock: clock,
          ),
          gate: gate,
          staged: staged,
          localState: localState,
          heldRows: heldRows,
          baseDir: () async => base,
          profileUuid: profile,
        ),
        SilexgisDocumentLinksUploadPart(
          run: documents,
          serverLinks: serverLinks,
          heldRows: heldRows,
          profileUuid: profile,
        ),
      ],
    ).run(setId, capabilities: capabilities);
    return (report, documents);
  }

  List<Map<String, Object?>> sentSection(
    ScriptedClient client,
    SyncUploadSection section,
  ) => <Map<String, Object?>>[
    for (final r in client.sent.where((r) => r.url.path == uploadPath))
      for (final item in (r.jsonBody[section.wireName] as List? ?? const []))
        item as Map<String, Object?>,
  ];

  bool touchedTransfers(ScriptedClient client) =>
      client.sent.any((r) => r.url.path.startsWith('/api/v1/files/'));

  group('a photo of the caver\'s own', () {
    test('goes up with its bytes and its link, and is kept as sent', () async {
      final (id, bytes) = await photo('IMG_0001.jpg', description: 'Shaft');
      final client = ScriptedClient(<ScriptedResponse>[
        config(),
        ...staging(bytes),
        answer(
          documents: <Map<String, Object?>>[verdict(id.toString(), 'created')],
          links: <Map<String, Object?>>[verdict('link-9', 'created')],
        ),
      ]);

      final (report, documents) = await run(client);

      expect(report.refusals, isEmpty);
      expect(documents.files.staged, 1);
      final row = sentSection(client, SyncUploadSection.documents).single;
      expect(row['id'], id.toString());
      expect(row['stagedUploadId'], transferId);
      expect(row['sha256'], sha256.convert(bytes).toString());
      expect(row['sizeBytes'], bytes.length);
      expect(row['fileName'], 'IMG_0001.jpg');
      expect(row['title'], 'IMG_0001.jpg');
      expect(row['description'], 'Shaft');
      expect(row.containsKey('baseRevision'), isFalse);
      final link = sentSection(client, SyncUploadSection.documentLinks).single;
      expect(link, <String, Object?>{
        'documentId': id.toString(),
        'target': <String, Object?>{'kind': 'feature', 'id': caveId.toString()},
        'deleted': false,
      });
      // Its bytes stand for the document now, and the link is the server's.
      expect(
        (await localState.readRevisions(profile))[id]!.revision,
        '2026-10-28T08:00:00Z',
      );
      expect(
        (await staged.read(profile, id))!.state,
        SilexgisStagedState.adopted,
      );
      expect(
        (await serverLinks.readAll(profile))[(id, caveId)]!.linkId,
        'link-9',
      );
    });

    test('hung on nothing the installation holds, stays here', () async {
      await photo('elsewhere.jpg', target: Uuid.v7());
      final client = ScriptedClient(<ScriptedResponse>[]);

      final (report, _) = await run(client);

      expect(report.isEmpty, isTrue);
      expect(client.sent, isEmpty);
    });

    test('a caption edit sends no bytes', () async {
      final (id, bytes) = await photo('IMG_0002.jpg');
      await agreed(id);
      await staged.write(
        profile,
        SilexgisStagedFile(
          documentUuid: id,
          sha256: sha256.convert(bytes).toString(),
          sizeBytes: bytes.length,
          state: SilexgisStagedState.adopted,
          transferId: transferId,
        ),
      );
      await editCaption(id, 'Looking down');
      final client = ScriptedClient(<ScriptedResponse>[
        answer(
          documents: <Map<String, Object?>>[verdict(id.toString(), 'updated')],
        ),
      ]);

      await run(client);

      expect(touchedTransfers(client), isFalse);
      final row = sentSection(client, SyncUploadSection.documents).single;
      expect(row['baseRevision'], 'r-1');
      expect(row['description'], 'Looking down');
      expect(row.containsKey('stagedUploadId'), isFalse);
      // No revision of the bytes is known here, so the hash says they are
      // the same.
      expect(row['sha256'], sha256.convert(bytes).toString());
      expect(sentSection(client, SyncUploadSection.documentLinks), isEmpty);
    });

    test(
      'bytes the server lost are staged again and the row sent once more',
      () async {
        final (id, bytes) = await photo('IMG_0003.jpg');
        final client = ScriptedClient(<ScriptedResponse>[
          config(),
          ...staging(bytes),
          answer(
            documents: <Map<String, Object?>>[
              verdict(
                id.toString(),
                'rejected',
                code: SilexgisCodes.fileBytesMissing,
              ),
            ],
            links: <Map<String, Object?>>[
              verdict(
                id.toString(),
                'rejected',
                code: SilexgisCodes.documentUnavailable,
              ),
            ],
          ),
          ...staging(bytes, id: 'transfer-2'),
          answer(
            documents: <Map<String, Object?>>[
              verdict(id.toString(), 'created'),
            ],
            links: <Map<String, Object?>>[verdict('link-9', 'created')],
          ),
        ]);

        final (report, _) = await run(client);

        expect(report.refusals, isEmpty);
        final rows = sentSection(client, SyncUploadSection.documents);
        expect(rows.map((r) => r['stagedUploadId']), <String>[
          transferId,
          'transfer-2',
        ]);
        expect(
          sentSection(client, SyncUploadSection.documentLinks),
          hasLength(2),
        );
        expect(client.isExhausted, isTrue);
      },
    );
  });

  group('rule 13: a copy the server handed down', () {
    test('without location, never goes up as bytes', () async {
      final (id, _) = await photo('location_free.jpg');
      await copies.register(
        SilexgisFileCopyEntry(
          documentUuid: id,
          heldAs: SilexgisHeldAs.locationFree,
          origin: SilexgisCopyOrigin.server,
          versionId: 'version-7',
        ),
      );
      await agreed(id);
      await editCaption(id, 'Renamed here');
      final client = ScriptedClient(<ScriptedResponse>[
        answer(
          documents: <Map<String, Object?>>[verdict(id.toString(), 'updated')],
        ),
      ]);

      await run(client);

      expect(touchedTransfers(client), isFalse);
      final row = sentSection(client, SyncUploadSection.documents).single;
      // A metadata edit only: the revision of the bytes, and no hash — the
      // copy's hash was never the stored file's.
      expect(row['baseVersionId'], 'version-7');
      expect(row.containsKey('stagedUploadId'), isFalse);
      expect(row.containsKey('sha256'), isFalse);
      expect(row.containsKey('sizeBytes'), isFalse);
      expect(row['description'], 'Renamed here');
    });

    test('drawn smaller, is never offered as a new document', () async {
      final (id, _) = await photo('rendition_480.jpg');
      await copies.register(
        SilexgisFileCopyEntry(
          documentUuid: id,
          heldAs: SilexgisHeldAs.rendition,
          origin: SilexgisCopyOrigin.server,
          rendition: 480,
        ),
      );
      final client = ScriptedClient(<ScriptedResponse>[]);

      final (report, _) = await run(client);

      expect(report.isEmpty, isTrue);
      expect(client.sent, isEmpty);
    });

    test('with no known revision, is not edited at all', () async {
      final (id, _) = await photo('location_free.jpg');
      await copies.register(
        SilexgisFileCopyEntry(
          documentUuid: id,
          heldAs: SilexgisHeldAs.locationFree,
          origin: SilexgisCopyOrigin.server,
        ),
      );
      await agreed(id);
      await editCaption(id, 'Renamed here');
      final client = ScriptedClient(<ScriptedResponse>[]);

      final (_, documents) = await run(client);

      expect(client.sent, isEmpty);
      expect(documents.keptBack, contains(id));
    });
  });

  group('a title cut to the phone\'s fifty characters', () {
    Future<Uuid> catalogued(String serverTitle) async {
      final (id, _) = await photo('cut.jpg');
      await (db.update(
        db.documentationFiles,
      )..where((t) => t.uuid.equalsValue(id))).write(
        DocumentationFilesCompanion(title: Value(serverTitle.substring(0, 50))),
      );
      await db
          .into(db.silexgisDocument)
          .insert(
            SilexgisDocumentCompanion.insert(
              profileUuid: profile,
              documentId: id,
              title: serverTitle,
              fileKind: 'photo',
              reach: 'original',
              versionId: const Value('version-1'),
              sha256: Value(
                (await (db.select(
                  db.documentationFiles,
                )..where((t) => t.uuid.equalsValue(id))).getSingle()).fileHash,
              ),
            ),
          );
      await copies.register(
        SilexgisFileCopyEntry(
          documentUuid: id,
          heldAs: SilexgisHeldAs.original,
          origin: SilexgisCopyOrigin.server,
          versionId: 'version-1',
        ),
      );
      await agreed(id);
      return id;
    }

    test('is not sent back with a caption edit', () async {
      final id = await catalogued('T' * 70);
      await editCaption(id, 'A caption');
      final client = ScriptedClient(<ScriptedResponse>[
        answer(
          documents: <Map<String, Object?>>[verdict(id.toString(), 'updated')],
        ),
      ]);

      await run(client);

      final row = sentSection(client, SyncUploadSection.documents).single;
      expect(row.containsKey('title'), isFalse);
      expect(row['baseVersionId'], 'version-1');
      // The server's own file, unchanged: no bytes and no hash needed.
      expect(row.containsKey('stagedUploadId'), isFalse);
      expect(row.containsKey('sha256'), isFalse);
    });

    test('a title the caver changed is sent', () async {
      final id = await catalogued('T' * 70);
      clock.advance(const Duration(minutes: 1));
      await (db.update(
        db.documentationFiles,
      )..where((t) => t.uuid.equalsValue(id))).write(
        DocumentationFilesCompanion(
          title: const Value('Mine now'),
          updatedAt: Value(clock.nowMs()),
        ),
      );
      final client = ScriptedClient(<ScriptedResponse>[
        answer(
          documents: <Map<String, Object?>>[verdict(id.toString(), 'updated')],
        ),
      ]);

      await run(client);

      expect(
        sentSection(client, SyncUploadSection.documents).single['title'],
        'Mine now',
      );
    });
  });

  group('removals', () {
    test(
      'a document removed here goes as a removal, and its link too',
      () async {
        final (id, _) = await photo('gone.jpg');
        await agreed(id);
        await db.delete(db.documentationFilesToGeofeatures).go();
        await db.delete(db.documentationFiles).go();
        final client = ScriptedClient(<ScriptedResponse>[
          answer(
            documents: <Map<String, Object?>>[
              verdict(
                id.toString(),
                'rejected',
                code: SilexgisCodes.rowDeleteForbidden,
              ),
            ],
            links: <Map<String, Object?>>[verdict('link-of-$id', 'deleted')],
          ),
        ]);

        final (report, _) = await run(client);

        expect(
          sentSection(client, SyncUploadSection.documents).single,
          <String, Object?>{
            'id': id.toString(),
            'baseRevision': 'r-1',
            'deleted': true,
          },
        );
        expect(
          sentSection(
            client,
            SyncUploadSection.documentLinks,
          ).single['deleted'],
          isTrue,
        );
        // The removal of the document is refused and reported; the link came
        // down all the same.
        expect(
          report.refusals.single.result.code,
          SilexgisCodes.rowDeleteForbidden,
        );
        expect(await serverLinks.readAll(profile), isEmpty);
      },
    );
  });

  group('held for a reviewer', () {
    test('a held document and link are not sent again unedited', () async {
      final (id, bytes) = await photo('held.jpg');
      final client = ScriptedClient(<ScriptedResponse>[
        config(),
        ...staging(bytes),
        answer(
          documents: <Map<String, Object?>>[
            verdict(id.toString(), 'held', revision: '', reviewId: 'rev-1'),
          ],
          links: <Map<String, Object?>>[
            verdict(id.toString(), 'held', revision: '', reviewId: 'rev-2'),
          ],
        ),
      ]);

      final (report, _) = await run(client);
      expect(report.held, 2);
      expect(
        (await heldRows.readSection(
          profile,
          SyncUploadSection.documents,
        ))[id]!.reviewId,
        'rev-1',
      );
      // The staged bytes wait on the server with the proposal.
      expect(
        (await staged.read(profile, id))!.state,
        SilexgisStagedState.staged,
      );

      final again = ScriptedClient(<ScriptedResponse>[]);
      final (second, _) = await run(again);
      expect(second.isEmpty, isTrue);
    });
  });

  group('files kept for another network', () {
    test('wait, while a row with no file still goes', () async {
      final (waiting, _) = await photo('new.jpg');
      final (edited, bytes) = await photo('known.jpg');
      await agreed(edited);
      await staged.write(
        profile,
        SilexgisStagedFile(
          documentUuid: edited,
          sha256: sha256.convert(bytes).toString(),
          sizeBytes: bytes.length,
          state: SilexgisStagedState.adopted,
        ),
      );
      await editCaption(edited, 'Still goes');
      final client = ScriptedClient(<ScriptedResponse>[
        answer(
          documents: <Map<String, Object?>>[
            verdict(edited.toString(), 'updated'),
          ],
        ),
      ]);

      final (_, documents) = await run(client, gate: const _NotNow());

      expect(touchedTransfers(client), isFalse);
      expect(
        sentSection(client, SyncUploadSection.documents).map((r) => r['id']),
        <String>[edited.toString()],
      );
      // Its link waits with it.
      expect(sentSection(client, SyncUploadSection.documentLinks), isEmpty);
      expect(documents.keptBack, contains(waiting));
      expect(documents.files.waitingForNetwork, 1);
    });
  });
}

class _NotNow implements SilexgisFileSendingGate {
  const _NotNow();

  @override
  Future<bool> mayFilesGo({required int files, required int bytes}) async =>
      false;
}
