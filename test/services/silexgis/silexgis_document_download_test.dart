import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_file_links.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_downloader.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_file_store.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_importer.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_linker.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_link_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_fetcher.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/utils/clock.dart';

import 'scripted_client.dart';
import 'token_source.dart';

/// Fetching files the caver chose from the catalogue: rule 13, verification,
/// resuming, and the address route's limits.
void main() {
  const profileUuid = 'p-1';
  final baseUri = Uri.parse('https://club.example.org');
  final clock = FakeClock(DateTime.utc(2026, 10, 28, 9));

  late Directory base;
  late AppDatabase db;
  late ChangeLogger logger;
  late SilexgisLocalStateRepository localState;
  late SilexgisDocumentCatalogueRepository catalogue;
  late SilexgisFileCopyRepository copies;
  late FakeFileServer files;

  final caveId = Uuid.v7();

  setUp(() async {
    base = await Directory.systemTemp.createTemp('silexgis_download_');
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
    files = FakeFileServer();
    await db
        .into(db.caves)
        .insert(Cave(uuid: caveId, title: 'Peștera Inventată'));
  });
  tearDown(() async {
    await db.close();
    await base.delete(recursive: true);
  });

  /// Invented bytes; never a real picture.
  Uint8List bytesOf(int length, [int seed = 1]) =>
      Uint8List.fromList(List<int>.generate(length, (i) => (i * seed) % 251));

  String hashOf(List<int> bytes) => sha256.convert(bytes).toString();

  Map<String, Object?> catalogueLink(
    String linkId,
    Uuid documentId, {
    Uuid? target,
    String role = 'photoInterior',
    String reach = 'original',
    int? sizeBytes,
    String? sha,
    String title = 'invented.jpg',
    List<int> renditions = const <int>[2400, 1200, 480, 160],
  }) => <String, Object?>{
    'id': linkId,
    'documentId': documentId.toString(),
    'target': <String, Object?>{
      'kind': 'feature',
      'id': (target ?? caveId).toString(),
    },
    'role': role,
    'caption': null,
    'sortOrder': 0,
    'isPrimary': false,
    'inDefaultSet': false,
    'revision': '2026-10-27T10:00:00.000001Z',
    'document': <String, Object?>{
      'id': documentId.toString(),
      'title': title,
      'description': null,
      'fileKind': 'photo',
      'mimeType': 'image/jpeg',
      'sizeBytes': sizeBytes,
      'sha256': sha,
      'versionId': 'version-1',
      'reach': reach,
      'renditions': renditions,
      'capturedAt': null,
      'createdAt': '2026-10-20T18:00:01.000001Z',
      'updatedAt': '2026-10-27T10:00:00.000001Z',
    },
  };

  Future<void> catalogued(List<Map<String, Object?>> links) =>
      catalogue.applyPage(
        profileUuid,
        SyncDocumentsPage.fromJson(<String, Object?>{
          'setRevision': 1,
          'links': links,
          'tombstones': const <Object?>[],
          'nextCursor': 'c1',
          'hasMore': false,
        }),
      );

  Map<String, Object?> address(
    Uuid documentId, {
    Object rendition = 'original',
    String? url,
    int? sizeBytes,
    String? sha,
  }) => <String, Object?>{
    'documentId': documentId.toString(),
    'rendition': rendition,
    'url': url ?? '/api/v1/files/f-$documentId/content?token=t1',
    'expiresAt': '2026-10-28T13:00:00Z',
    'sizeBytes': sizeBytes,
    'sha256': sha,
  };

  ScriptedResponse addresses({
    List<Map<String, Object?>> links = const <Map<String, Object?>>[],
    List<Map<String, Object?>> refused = const <Map<String, Object?>>[],
  }) => ScriptedResponse.json(
    path: SilexgisContract.fileLinksPath,
    json: <String, Object?>{'links': links, 'refused': refused},
  );

  ({SilexgisDocumentDownloader downloader, ScriptedClient api}) downloaderFor(
    List<ScriptedResponse> script,
  ) {
    final api = ScriptedClient(script);
    return (
      downloader: SilexgisDocumentDownloader(
        db: db,
        api: SilexgisSyncApi(
          SilexgisHttp(
            baseUri: baseUri,
            tokens: FixedTokenSource(),
            client: api,
          ),
        ),
        fetcher: SilexgisFileFetcher(baseUri: baseUri, client: files),
        store: SilexgisDocumentFileStore(baseDir: () async => base),
        catalogue: catalogue,
        importer: SilexgisDocumentImporter(
          db: db,
          logger: logger,
          localState: localState,
          copies: copies,
          linker: SilexgisDocumentLinker(
            db: db,
            logger: logger,
            catalogue: catalogue,
            copies: copies,
            serverLinks: SilexgisServerLinkRepository(db),
            profileUuid: profileUuid,
            clock: clock,
          ),
          profileUuid: profileUuid,
          clock: clock,
        ),
        profileUuid: profileUuid,
      ),
      api: api,
    );
  }

  Future<DocumentationFile?> localFile(Uuid id) => (db.select(
    db.documentationFiles,
  )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull();

  group('rule 13: a file the device holds is never fetched again', () {
    test('held under the document\'s own identifier', () async {
      final documentId = Uuid.v7();
      final bytes = bytesOf(300);
      await catalogued(<Map<String, Object?>>[
        catalogueLink(
          'l1',
          documentId,
          sizeBytes: bytes.length,
          sha: hashOf(bytes),
        ),
      ]);
      await db
          .into(db.documentationFiles)
          .insert(
            DocumentationFilesCompanion.insert(
              uuid: documentId,
              title: 'Mine',
              fileName: 'documentation_files/doc_mine.jpg',
              fileSize: 12,
              fileType: 'photo',
            ),
          );
      final run = downloaderFor(const <ScriptedResponse>[]);

      final result = await run.downloader.download(<SilexgisDownloadRequest>[
        SilexgisDownloadRequest(
          documentId: documentId,
          rendition: SyncRendition.original,
        ),
      ]);

      expect(result.single.outcome, SilexgisDownloadOutcome.alreadyHeld);
      expect(run.api.sent, isEmpty);
      expect(files.requests, isEmpty);
      expect((await localFile(documentId))!.title, 'Mine');
    });

    test('held with the same bytes under another document', () async {
      final documentId = Uuid.v7();
      final bytes = bytesOf(300);
      await catalogued(<Map<String, Object?>>[
        catalogueLink(
          'l1',
          documentId,
          sizeBytes: bytes.length,
          sha: hashOf(bytes),
        ),
      ]);
      // The caver's own photo, which the server holds as its document.
      await db
          .into(db.documentationFiles)
          .insert(
            DocumentationFilesCompanion.insert(
              uuid: Uuid.v7(),
              title: 'My photo',
              fileName: 'documentation_files/doc_own.jpg',
              fileSize: bytes.length,
              fileType: 'photo',
            ).copyWith(fileHash: Value(hashOf(bytes))),
          );
      final run = downloaderFor(const <ScriptedResponse>[]);

      final result = await run.downloader.download(<SilexgisDownloadRequest>[
        SilexgisDownloadRequest(
          documentId: documentId,
          rendition: SyncRendition.original,
        ),
      ]);

      expect(result.single.outcome, SilexgisDownloadOutcome.alreadyHeld);
      expect(run.api.sent, isEmpty);
      expect(await localFile(documentId), isNull);
    });
  });

  group('fetching', () {
    test('an original is verified, stored under a new name and linked, '
        'unlogged', () async {
      final documentId = Uuid.v7();
      final otherCave = Uuid.v7();
      final bytes = bytesOf(4096);
      await catalogued(<Map<String, Object?>>[
        catalogueLink(
          'l1',
          documentId,
          sizeBytes: bytes.length,
          sha: hashOf(bytes),
          title: 'A very long title of an invented photo that goes on.jpg',
        ),
        // Hung on a cave this device does not carry: no local link.
        catalogueLink(
          'l2',
          documentId,
          target: otherCave,
          sizeBytes: bytes.length,
          sha: hashOf(bytes),
          title: 'A very long title of an invented photo that goes on.jpg',
        ),
      ]);
      files.serve('/api/v1/files/f-$documentId/content', bytes);
      final run = downloaderFor(<ScriptedResponse>[
        addresses(links: <Map<String, Object?>>[address(documentId)]),
      ]);

      final result = await run.downloader.download(<SilexgisDownloadRequest>[
        SilexgisDownloadRequest(
          documentId: documentId,
          rendition: SyncRendition.original,
        ),
      ]);

      expect(result.single.outcome, SilexgisDownloadOutcome.downloaded);
      // The signed address is the credential; no bearer token goes with it.
      expect(files.requests.single.headers, isNot(contains('Authorization')));

      final row = (await localFile(documentId))!;
      expect(row.title.runes.length, 50);
      expect(row.fileHash, hashOf(bytes));
      expect(row.fileSize, bytes.length);
      expect(row.fileName, startsWith('documentation_files/srv_'));
      expect(row.fileType, 'photo');
      expect(await File('${base.path}/${row.fileName}').readAsBytes(), bytes);

      final links = await db.select(db.documentationFilesToGeofeatures).get();
      expect(links.single.geofeatureUuid, caveId);
      expect(links.single.geofeatureType, 'cave');

      final copy = (await copies.read(documentId))!;
      expect(copy.heldAs, SilexgisHeldAs.original);
      expect(copy.origin, SilexgisCopyOrigin.server);
      expect(copy.versionId, 'version-1');
      expect(
        await localState.readRevision(profileUuid, documentId),
        '2026-10-27T10:00:00.000001Z',
      );
      expect(await db.select(db.changeLog).get(), isEmpty);
    });

    test(
      'a raster map\'s picture is not hung on the cave as a document',
      () async {
        final documentId = Uuid.v7();
        final bytes = bytesOf(100);
        await catalogued(<Map<String, Object?>>[
          catalogueLink(
            'l1',
            documentId,
            role: 'map2d',
            sizeBytes: bytes.length,
            sha: hashOf(bytes),
          ),
        ]);
        files.serve('/api/v1/files/f-$documentId/content', bytes);
        final run = downloaderFor(<ScriptedResponse>[
          addresses(links: <Map<String, Object?>>[address(documentId)]),
        ]);

        await run.downloader.download(<SilexgisDownloadRequest>[
          SilexgisDownloadRequest(
            documentId: documentId,
            rendition: SyncRendition.original,
          ),
        ]);

        expect(await localFile(documentId), isNotNull);
        expect(
          await db.select(db.documentationFilesToGeofeatures).get(),
          isEmpty,
        );
      },
    );

    test('a copy without its location, with no numbers, is checked against '
        'the response\'s length and registered as such', () async {
      final documentId = Uuid.v7();
      final bytes = bytesOf(2000, 3);
      await catalogued(<Map<String, Object?>>[
        catalogueLink('l1', documentId, reach: 'locationFree'),
      ]);
      files.serve('/api/v1/files/f-$documentId/content', bytes);
      final run = downloaderFor(<ScriptedResponse>[
        addresses(links: <Map<String, Object?>>[address(documentId)]),
      ]);

      final result = await run.downloader.download(<SilexgisDownloadRequest>[
        SilexgisDownloadRequest(
          documentId: documentId,
          rendition: SyncRendition.original,
        ),
      ]);

      expect(result.single.outcome, SilexgisDownloadOutcome.downloaded);
      expect(
        (await copies.read(documentId))!.heldAs,
        SilexgisHeldAs.locationFree,
      );
    });

    test(
      'a copy that does not match the address\'s numbers is not stored',
      () async {
        final documentId = Uuid.v7();
        final bytes = bytesOf(2000, 3);
        await catalogued(<Map<String, Object?>>[
          catalogueLink('l1', documentId, reach: 'locationFree'),
        ]);
        files.serve('/api/v1/files/f-$documentId/content', bytes);
        final run = downloaderFor(<ScriptedResponse>[
          addresses(
            links: <Map<String, Object?>>[
              address(documentId, sizeBytes: bytes.length, sha: 'cd' * 32),
            ],
          ),
        ]);

        final result = await run.downloader.download(<SilexgisDownloadRequest>[
          SilexgisDownloadRequest(
            documentId: documentId,
            rendition: SyncRendition.original,
          ),
        ]);

        expect(result.single.outcome, SilexgisDownloadOutcome.failed);
        expect(await localFile(documentId), isNull);
        expect(await copies.read(documentId), isNull);
        final partials = Directory(
          '${base.path}/documentation_files/.silexgis_partial',
        );
        expect(
          partials.existsSync() ? partials.listSync() : const <Object>[],
          isEmpty,
        );
      },
    );

    test('a dropped original resumes with Range where it stopped', () async {
      final documentId = Uuid.v7();
      final bytes = bytesOf(10000, 7);
      await catalogued(<Map<String, Object?>>[
        catalogueLink(
          'l1',
          documentId,
          sizeBytes: bytes.length,
          sha: hashOf(bytes),
        ),
      ]);
      files.serve(
        '/api/v1/files/f-$documentId/content',
        bytes,
        dropAfter: 3000,
      );
      final run = downloaderFor(<ScriptedResponse>[
        addresses(links: <Map<String, Object?>>[address(documentId)]),
      ]);

      final result = await run.downloader.download(<SilexgisDownloadRequest>[
        SilexgisDownloadRequest(
          documentId: documentId,
          rendition: SyncRendition.original,
        ),
      ]);

      expect(result.single.outcome, SilexgisDownloadOutcome.downloaded);
      expect(files.requests, hasLength(2));
      expect(files.requests.first.headers, isNot(contains('Range')));
      expect(files.requests.last.headers['Range'], 'bytes=3000-');
      expect((await localFile(documentId))!.fileHash, hashOf(bytes));
    });

    test(
      'an expired address is asked for again, and the fetch resumes',
      () async {
        final documentId = Uuid.v7();
        final bytes = bytesOf(5000, 5);
        await catalogued(<Map<String, Object?>>[
          catalogueLink(
            'l1',
            documentId,
            sizeBytes: bytes.length,
            sha: hashOf(bytes),
          ),
        ]);
        files
          ..serve('/api/v1/files/f-$documentId/content', bytes, dropAfter: 1000)
          ..expireAfterFirst('/api/v1/files/f-$documentId/content');
        files.serve('/api/v1/files/g-$documentId/content', bytes);
        final run = downloaderFor(<ScriptedResponse>[
          addresses(links: <Map<String, Object?>>[address(documentId)]),
          addresses(
            links: <Map<String, Object?>>[
              address(
                documentId,
                url: '/api/v1/files/g-$documentId/content?token=t2',
              ),
            ],
          ),
        ]);

        final result = await run.downloader.download(<SilexgisDownloadRequest>[
          SilexgisDownloadRequest(
            documentId: documentId,
            rendition: SyncRendition.original,
          ),
        ]);

        expect(result.single.outcome, SilexgisDownloadOutcome.downloaded);
        expect(run.api.sent, hasLength(2));
        expect(
          files.requests.last.url.path,
          '/api/v1/files/g-$documentId/content',
        );
        expect(files.requests.last.headers['Range'], 'bytes=1000-');
        expect((await localFile(documentId))!.fileHash, hashOf(bytes));
      },
    );
  });

  group('the address route', () {
    test('is asked at most 200 items at a time', () async {
      final ids = List<Uuid>.generate(450, (_) => Uuid.v7());
      await catalogued(<Map<String, Object?>>[
        for (final (i, id) in ids.indexed) catalogueLink('l$i', id),
      ]);
      List<Map<String, Object?>> refusedAll(Iterable<Uuid> chunk) =>
          <Map<String, Object?>>[
            for (final id in chunk)
              <String, Object?>{
                'documentId': id.toString(),
                'rendition': 'original',
                'code': 'sync.document_unavailable',
              },
          ];
      final run = downloaderFor(<ScriptedResponse>[
        addresses(refused: refusedAll(ids.take(200))),
        addresses(refused: refusedAll(ids.skip(200).take(200))),
        addresses(refused: refusedAll(ids.skip(400))),
      ]);

      final result = await run.downloader.download(<SilexgisDownloadRequest>[
        for (final id in ids)
          SilexgisDownloadRequest(
            documentId: id,
            rendition: SyncRendition.original,
          ),
      ]);

      expect(
        run.api.sent.map((r) => (r.jsonBody['items']! as List).length),
        <int>[200, 200, 50],
      );
      expect(
        result.every((r) => r.outcome == SilexgisDownloadOutcome.unavailable),
        isTrue,
      );
      // Each one leaves the catalogue copy until a read lists it again.
      expect(await catalogue.isEmpty(profileUuid), isTrue);
    });

    test(
      'a withheld original is asked for again as the largest picture',
      () async {
        final documentId = Uuid.v7();
        final picture = bytesOf(700, 11);
        await catalogued(<Map<String, Object?>>[
          catalogueLink('l1', documentId, renditions: const <int>[1200, 480]),
        ]);
        files.serve(
          '/api/v1/files/f-$documentId/thumbnail',
          picture,
          contentType: 'image/webp',
        );
        final run = downloaderFor(<ScriptedResponse>[
          addresses(
            refused: <Map<String, Object?>>[
              <String, Object?>{
                'documentId': documentId.toString(),
                'rendition': 'original',
                'code': 'sync.original_withheld',
              },
            ],
          ),
          addresses(
            links: <Map<String, Object?>>[
              address(
                documentId,
                rendition: 1200,
                url: '/api/v1/files/f-$documentId/thumbnail?size=1200&token=t',
              ),
            ],
          ),
        ]);

        final result = await run.downloader.download(<SilexgisDownloadRequest>[
          SilexgisDownloadRequest(
            documentId: documentId,
            rendition: SyncRendition.original,
          ),
        ]);

        expect(result.single.outcome, SilexgisDownloadOutcome.downloaded);
        expect(result.single.rendition, SyncRendition.picture(1200));
        expect(
          (run.api.sent.last.jsonBody['items']! as List).single,
          <String, Object?>{
            'documentId': documentId.toString(),
            'rendition': 1200,
          },
        );
        final copy = (await copies.read(documentId))!;
        expect(copy.heldAs, SilexgisHeldAs.rendition);
        expect(copy.rendition, 1200);
        expect((await localFile(documentId))!.fileName, endsWith('_1200.webp'));
      },
    );

    test('a size the catalogue does not offer is not asked for', () async {
      final documentId = Uuid.v7();
      await catalogued(<Map<String, Object?>>[
        catalogueLink(
          'l1',
          documentId,
          reach: 'none',
          renditions: const <int>[],
        ),
      ]);
      final run = downloaderFor(const <ScriptedResponse>[]);

      final result = await run.downloader.download(<SilexgisDownloadRequest>[
        SilexgisDownloadRequest(
          documentId: documentId,
          rendition: SyncRendition.original,
        ),
      ]);

      expect(result.single.outcome, SilexgisDownloadOutcome.notOffered);
      expect(run.api.sent, isEmpty);
    });
  });
}

/// One request the fake file server saw.
class FileRequest {
  FileRequest(this.url, this.headers);
  final Uri url;
  final Map<String, String> headers;
}

/// Serves invented bytes by path, honouring `Range`, and can drop a
/// connection part-way or answer an address as expired.
class FakeFileServer extends http.BaseClient {
  final Map<String, _Served> _files = <String, _Served>{};
  final Set<String> _expireAfterFirst = <String>{};
  final Map<String, int> _hits = <String, int>{};
  final List<FileRequest> requests = <FileRequest>[];

  void serve(
    String path,
    List<int> bytes, {
    int? dropAfter,
    String contentType = 'image/jpeg',
  }) => _files[path] = _Served(bytes, dropAfter, contentType);

  /// The first request for [path] is served (and may drop); every later one
  /// answers `404`, as an expired address does.
  void expireAfterFirst(String path) => _expireAfterFirst.add(path);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(FileRequest(request.url, Map.of(request.headers)));
    final path = request.url.path;
    final hit = _hits[path] = (_hits[path] ?? 0) + 1;
    final served = _files[path];
    if (served == null || (_expireAfterFirst.contains(path) && hit > 1)) {
      return http.StreamedResponse(
        Stream<List<int>>.value(utf8.encode('')),
        404,
        request: request,
      );
    }

    final range = RegExp(
      r'bytes=(\d+)-',
    ).firstMatch(request.headers['Range'] ?? '');
    final start = range == null ? 0 : int.parse(range.group(1)!);
    final body = served.bytes.sublist(start);
    final drop = hit == 1 ? served.dropAfter : null;

    Stream<List<int>> stream() async* {
      if (drop == null) {
        yield body;
        return;
      }
      yield body.sublist(0, drop);
      throw http.ClientException('connection dropped');
    }

    return http.StreamedResponse(
      stream(),
      range == null ? 200 : 206,
      contentLength: body.length,
      request: request,
      headers: <String, String>{
        'content-type': served.contentType,
        if (range != null)
          'content-range':
              'bytes $start-${served.bytes.length - 1}/${served.bytes.length}',
      },
    );
  }
}

class _Served {
  _Served(this.bytes, this.dropAfter, this.contentType);
  final List<int> bytes;
  final int? dropAfter;
  final String contentType;
}
