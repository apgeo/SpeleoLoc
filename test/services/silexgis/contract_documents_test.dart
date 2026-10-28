import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_file_links.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';

import 'contract_fixtures.dart';
import 'scripted_client.dart';
import 'token_source.dart';

/// Replays the recorded reads of the documents catalogue and the file-address
/// route.
void main() {
  group('17-documents-first-page', () {
    final exchange = ContractExchange('17-documents-first-page');

    test('is a plain read of the set\'s documents stream', () {
      expect(exchange.requestLine, startsWith('GET '));
      expect(exchange.requestTarget, SilexgisContract.documentsPath('<set>'));
    });

    test('a photo without its location quotes no size and no hash', () {
      final page = SyncDocumentsPage.fromJson(exchange.responseBody);
      expect(page.setRevision, 1);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, '<cursor>');
      expect(page.tombstones, isEmpty);

      final link = page.links.single;
      expect(link.id, '<link>');
      expect(link.documentId, '<document>');
      expect(link.targetKind, 'feature');
      expect(link.targetId, '<cave>');
      expect(link.role, 'photoInterior');
      expect(link.inDefaultSet, isFalse);

      final document = link.document;
      expect(document.title, 'both.jpg');
      expect(document.fileKind, 'photo');
      expect(document.reach, SyncDocumentReach.locationFree);
      expect(document.reach.offersOriginal, isTrue);
      expect(document.sizeBytes, isNull);
      expect(document.sha256, isNull);
      expect(document.renditions, <int>[2400, 1200, 480, 160]);
      // A photo that names no photographer: recorded as null.
      expect(document.createdByDeviceUserId, isNull);
    });

    test('an unknown reach is read as nothing to fetch', () {
      expect(SyncDocumentReach.parse('somethingNew'), SyncDocumentReach.none);
    });
  });

  group('18-files-links', () {
    final exchange = ContractExchange('18-files-links');

    test('the request goes up byte for byte as recorded', () async {
      final client = ScriptedClient(<ScriptedResponse>[
        ScriptedResponse.json(
          path: SilexgisContract.fileLinksPath,
          json: exchange.responseBody,
        ),
      ]);
      final api = SilexgisSyncApi(
        SilexgisHttp(
          baseUri: Uri.parse('https://club.example.org'),
          tokens: FixedTokenSource(),
          client: client,
        ),
      );

      await api.fileLinks(<SyncFileLinkRequest>[
        const SyncFileLinkRequest(
          documentId: '<document>',
          rendition: SyncRendition.original,
        ),
        SyncFileLinkRequest(
          documentId: '<document>',
          rendition: SyncRendition.picture(480),
        ),
      ]);

      expect(
        '${client.sent.single.method} ${client.sent.single.url.path}',
        exchange.requestLine,
      );
      expect(client.sent.single.jsonBody, exchange.requestBody);
    });

    test('an address per item, relative and without numbers', () {
      final answer = SyncFileLinksAnswer.fromJson(exchange.responseBody);
      expect(answer.refused, isEmpty);
      expect(answer.links, hasLength(2));

      final original = answer.links.first;
      expect(original.rendition, SyncRendition.original);
      expect(original.url, startsWith('/api/v1/files/'));
      expect(original.sizeBytes, isNull);
      expect(original.sha256, isNull);

      final picture = answer.links.last;
      expect(picture.rendition, SyncRendition.picture(480));
      expect(picture.url, contains('size=480'));
    });

    test('each refused item names its action', () {
      final answer = SyncFileLinksAnswer.fromJson(const <String, Object?>{
        'links': <Object?>[],
        'refused': <Object?>[
          <String, Object?>{
            'documentId': 'a',
            'rendition': 'original',
            'code': 'sync.document_unavailable',
          },
          <String, Object?>{
            'documentId': 'b',
            'rendition': 'original',
            'code': 'sync.original_withheld',
          },
          <String, Object?>{
            'documentId': 'c',
            'rendition': 480,
            'code': 'sync.rendition_unavailable',
          },
        ],
      });
      expect(answer.refused.map((r) => r.action), <SilexgisAction>[
        SilexgisAction.surfaceToUser,
        SilexgisAction.applyAndResubmit,
        SilexgisAction.applyAndResubmit,
      ]);
      expect(answer.refused.last.rendition, SyncRendition.picture(480));
    });

    test('only the sizes the server draws can be asked for', () {
      expect(() => SyncRendition.picture(640), throwsArgumentError);
      expect(SyncRendition.tryParse(640), isNull);
      expect(SyncRendition.tryParse('original'), SyncRendition.original);
    });
  });
}
