import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/silexgis/model/geo_json_geometry.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_batch.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_row_composer.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_upload_planner.dart';

import 'contract_fixtures.dart';

/// Replays the recorded writes.
///
/// A write is the half this application has to **compose** rather than merely
/// parse, so each case rebuilds the recorded request from the same inputs and
/// compares it member by member, and only then reads the answer.
void main() {
  /// Asserts that everything the recording sends, we send identically — and
  /// names the members we add on purpose, so a third one cannot appear
  /// unnoticed.
  void expectComposes(
    Map<String, Object?> ours,
    Map<String, Object?> recorded, {
    Set<String> deliberateAdditions = const <String>{},
  }) {
    for (final entry in recorded.entries) {
      expect(
        ours,
        containsPair(entry.key, entry.value),
        reason: 'row member `${entry.key}`',
      );
    }
    expect(
      ours.keys.toSet().difference(recorded.keys.toSet()),
      deliberateAdditions,
    );
  }

  group('11-upload-create', () {
    final exchange = ContractExchange('11-upload-create');

    test('composes the recorded create', () {
      final recorded = exchange.requestBody;
      final row = SyncUploadRow(
        id: '<place>',
        kind: SyncUploadKind.generic,
        baseRevision: null,
        parentId: '<cave>',
        name: 'Sump <marker>',
        featureTypeCode: 'cave_place',
        geometry: GeoJsonGeometry.point(latitude: 45.601, longitude: 25.501),
        clientUpdatedAt: '<timestamp>',
      );
      final batch = SyncUploadBatch(
        batchId: '<batch>',
        rows: <SyncUploadRow>[row],
      );
      final ours = batch.toJson();

      expect(ours['batchId'], recorded['batchId']);
      expect(ours['contractVersion'], recorded['contractVersion']);
      expect(ours['contractVersion'], 1);
      // A rows-only upload is the body a device sent before sections existed:
      // no `clientFeatures`, no empty arrays beside `rows`, the same order.
      expect(ours.keys.toList(), recorded.keys.toList());

      expectComposes(
        (ours['rows']! as List).single as Map<String, Object?>,
        ((recorded['rows']! as List).single as Map<String, Object?>),
        // Stated on every row rather than only when it changed: the device
        // owns it, the row carries the base revision it was read at, and an
        // absent member and an explicit null are the same value here — so
        // this is the only way the device's text reaches the server at all.
        deliberateAdditions: <String>{'description'},
      );
      expect(row.isNew, isTrue);
    });

    test('answers with the revision to send back next time', () {
      final result = SyncUploadResult.fromJson(exchange.responseBody);
      expect(result.replayed, isFalse);
      expect(result.written, 1);
      expect(result.refused, 0);
      expect(result.rows.single.status, SyncRowStatus.created);
      expect(result.rows.single.revision, isNotNull);
      expect(result.rows.single.code, isNull);
      expect(result.rows.single.action, SilexgisAction.ignore);
      expect(result.conflicts, isEmpty);
      expect(result.duplicates, isEmpty);
    });
  });

  group('12-upload-retry', () {
    final exchange = ContractExchange('12-upload-retry');

    test('is the same bytes as the create it repeats', () {
      expect(
        exchange.requestBody,
        ContractExchange('11-upload-create').requestBody,
      );
    });

    test('returns the first answer and writes nothing a second time', () {
      final result = SyncUploadResult.fromJson(exchange.responseBody);
      final first = SyncUploadResult.fromJson(
        ContractExchange('11-upload-create').responseBody,
      );
      expect(result.replayed, isTrue);
      expect(result.importBatchId, first.importBatchId);
      expect(result.rows.single.status, SyncRowStatus.created);
      expect(result.written, 1);
    });
  });

  group('13-upload-conflict', () {
    final exchange = ContractExchange('13-upload-conflict');

    test('a stale base revision is refused and not applied', () {
      final result = SyncUploadResult.fromJson(exchange.responseBody);
      expect(result.written, 0);
      expect(result.refused, 1);

      final row = result.rows.single;
      expect(row.status, SyncRowStatus.conflict);
      expect(row.code, SilexgisCodes.conflict);
      expect(row.action, SilexgisAction.applyAndResubmit);
      expect(row.isWritten, isFalse);
    });

    test(
      'the server\'s own row rides back so no second round trip is needed',
      () {
        final result = SyncUploadResult.fromJson(exchange.responseBody);
        final echo = result.conflictFor(result.rows.single.id)!;
        // Shaped exactly as a download would have delivered it.
        expect(echo.featureTypeCode, 'cave_place');
        expect(echo.name, 'Sump lower <marker>');
        expect(echo.geometry!.latitude, 45.601);
        expect(echo.primaryParent, isNotNull);
        // And it carries the revision to merge against and resend with.
        expect(echo.updatedAt, isNotEmpty);
      },
    );
  });

  group('14-upload-conflict-withheld', () {
    final exchange = ContractExchange('14-upload-conflict-withheld');
    late SyncUploadResult result;
    setUpAll(() => result = SyncUploadResult.fromJson(exchange.responseBody));

    test('both losers are named in the decisions', () {
      expect(result.refused, 2);
      expect(result.rows, hasLength(2));
      expect(
        result.rows.every((r) => r.status == SyncRowStatus.conflict),
        isTrue,
      );
    });

    test('only the readable one is echoed; the other is absent', () {
      expect(result.conflicts, hasLength(1));
      final readable = result.rows[0].id;
      final withheld = result.rows[1].id;
      expect(result.conflictFor(readable), isNotNull);
      // Absence, never a blurred stand-in — the same answer the download
      // gives. A missing echo means "re-read this row", not "an error".
      expect(result.conflictFor(withheld), isNull);
      expect(result.rows[1].action, SilexgisAction.applyAndResubmit);
    });
  });

  group('a partial row', () {
    test('states only what it carries, so the rest is left alone', () {
      // An upload is a partial write: a member the row does not carry is one
      // the server leaves alone. A row built to change a single field must not
      // quietly restate the others.
      const row = SyncUploadRow(
        id: '<place>',
        kind: SyncUploadKind.generic,
        baseRevision: '<timestamp>',
        name: 'Renamed',
      );
      final json = row.toJson();
      expect(
        json.keys,
        unorderedEquals(<String>[
          'id',
          'kind',
          'baseRevision',
          'deleted',
          'isMain',
          'name',
          'description',
        ]),
      );
      // An empty property document is a value, not an absence: sending one
      // would replace the codes the row already carries.
      expect(json.containsKey('properties'), isFalse);
      expect(json.containsKey('geometry'), isFalse);
      expect(json.containsKey('altitude'), isFalse);
    });

    test('states its property document when it has one', () {
      const row = SyncUploadRow(
        id: '<place>',
        kind: SyncUploadKind.generic,
        baseRevision: '<timestamp>',
        properties: <String, Object?>{'speleolocPci': 'AB-0007'},
      );
      expect(row.toJson()['properties'], <String, Object?>{
        'speleolocPci': 'AB-0007',
      });
    });
  });

  group('15-upload-delete', () {
    final exchange = ContractExchange('15-upload-delete');

    test('composes the recorded tombstone', () {
      const batch = SyncUploadBatch(
        batchId: '<batch>',
        rows: <SyncUploadRow>[
          SyncUploadRow.delete(
            id: '<place>',
            kind: SyncUploadKind.generic,
            baseRevision: '<timestamp>',
          ),
        ],
      );
      expect(batch.toJson().keys.toList(), exchange.requestBody.keys.toList());
      expectComposes(
        (batch.toJson()['rows']! as List).single as Map<String, Object?>,
        ((exchange.requestBody['rows']! as List).single
            as Map<String, Object?>),
      );
    });

    test('a removal is arbitrated exactly as an edit is', () {
      final result = SyncUploadResult.fromJson(exchange.responseBody);
      expect(result.written, 1);
      expect(result.rows.single.status, SyncRowStatus.deleted);
      expect(result.rows.single.action, SilexgisAction.ignore);
    });
  });

  group('16-errors/file-bytes-missing', () {
    final exchange = ContractExchange('16-errors/file-bytes-missing');
    late SyncUploadResult result;
    setUpAll(() => result = SyncUploadResult.fromJson(exchange.responseBody));

    test('a refused item rides a 200, in its own section', () {
      expect(exchange.status, 200);
      expect(result.refused, 1);
      final document = result.answersFor(SyncUploadSection.documents)!.single;
      expect(document.status, SyncRowStatus.rejected);
      expect(document.code, 'sync.file_bytes_missing');
      expect(document.revision, isNull);
    });

    test('an empty array is present, and an absent one is absent', () {
      // `rows: []` is the server saying "you sent no rows"; a section it
      // does not mention at all was not in the upload.
      expect(result.answersFor(SyncUploadSection.rows), isEmpty);
      expect(result.answersFor(SyncUploadSection.rows), isNotNull);
      for (final section in <SyncUploadSection>[
        SyncUploadSection.people,
        SyncUploadSection.documentLinks,
        SyncUploadSection.tripRecordings,
        SyncUploadSection.tripPoints,
        SyncUploadSection.rasterMaps,
        SyncUploadSection.rasterPins,
      ]) {
        expect(result.answersFor(section), isNull, reason: section.wireName);
      }
    });

    test('an upload with no rows states none', () {
      const batch = SyncUploadBatch(
        batchId: '<batch>',
        sections: <SyncUploadSection, List<SyncUploadItem>>{
          SyncUploadSection.documents: <SyncUploadItem>[
            SyncUploadDocument(
              id: '<document>',
              title: 'Never staged',
              fileName: 'IMG_0102.jpg',
              sha256: '<sha256>',
            ),
          ],
        },
      );
      expect(batch.toJson(), exchange.requestBody);
      expect(batch.itemCount, 1);
    });

    test('names the bytes to send again before the row', () {
      final document = result.answersFor(SyncUploadSection.documents)!.single;
      expect(document.action, SilexgisAction.applyAndResubmit);
      expect(document.isWritten, isFalse);
    });
  });

  group('19-upload-document-and-link', () {
    final exchange = ContractExchange('19-upload-document-and-link');
    late SyncUploadResult result;
    setUpAll(() => result = SyncUploadResult.fromJson(exchange.responseBody));

    test('composes the sections in the recorded order', () {
      final recorded = exchange.requestBody;
      // Given out of order on purpose: the wire order is the apply order.
      const batch = SyncUploadBatch(
        batchId: '<batch>',
        sections: <SyncUploadSection, List<SyncUploadItem>>{
          SyncUploadSection.documentLinks: <SyncUploadItem>[
            SyncUploadDocumentLink(
              documentId: '<document>',
              targetKind: 'feature',
              targetId: '<cave>',
            ),
          ],
          SyncUploadSection.documents: <SyncUploadItem>[
            SyncUploadDocument(
              id: '<document>',
              title: 'Shaft entrance',
              fileName: 'photo.jpg',
              sha256: '<sha256>',
              stagedUploadId: '<staged-upload>',
            ),
          ],
        },
      );
      final ours = batch.toJson();
      expect(ours, recorded);
      expect(ours.keys.toList(), recorded.keys.toList());
      expect(batch.itemCount, 2);
    });

    test('a new photo of the caver\'s own composes the recorded row', () {
      final recorded =
          (exchange.requestBody['documents']! as List).single
              as Map<String, Object?>;
      final row = const SilexgisDocumentRowComposer().compose(
        SilexgisPlannedDocument(
          id: Uuid.v7(),
          row: DocumentationFile(
            uuid: Uuid.v7(),
            title: 'Shaft entrance',
            fileName: 'documentation_files/doc_1761000000000_photo.jpg',
            fileSize: 2048,
            fileType: 'photo',
            createdAt: 1761000000000,
            updatedAt: 1761000000000,
          ),
          sendsBytes: true,
        ),
        content: const SilexgisStagedContent(
          transferId: '<staged-upload>',
          sha256: '<sha256>',
          sizeBytes: 2048,
        ),
      )!;
      final ours = <String, Object?>{...row.toJson(), 'id': '<document>'};
      expectComposes(
        ours,
        recorded,
        // Stated because the device knows them: the size is checked against
        // the staged bytes, the capture time stands only where the file
        // states none, and the edit time is provenance.
        deliberateAdditions: <String>{
          'sizeBytes',
          'capturedAt',
          'clientUpdatedAt',
        },
      );
      // No base revision and no removal flag: absent says "new" and "not
      // removed" exactly as the recording does.
      expect(ours.containsKey('baseRevision'), isFalse);
      expect(ours.containsKey('deleted'), isFalse);
    });

    test('answers each section in the array of the same name', () {
      expect(result.written, 2);
      expect(result.rows, isEmpty);
      final document = result.answersFor(SyncUploadSection.documents)!.single;
      expect(document.id, '<document>');
      expect(document.status, SyncRowStatus.created);
      expect(document.revision, isNotNull);
      // The link is given its identifier by the server.
      final link = result.answersFor(SyncUploadSection.documentLinks)!.single;
      expect(link.id, isNot('<document>'));
      expect(link.status, SyncRowStatus.created);
      expect(link.action, SilexgisAction.ignore);
      expect(result.answersFor(SyncUploadSection.people), isNull);
    });
  });

  group('20-upload-held', () {
    final exchange = ContractExchange('20-upload-held');

    test('states clientFeatures where the recording does', () {
      const batch = SyncUploadBatch(
        batchId: '<batch>',
        clientFeatures: <String>['held'],
        rows: <SyncUploadRow>[
          SyncUploadRow(
            id: '<cave>',
            kind: SyncUploadKind.cave,
            baseRevision: null,
            name: 'held cave',
            caveTypeCode: 'cave',
          ),
        ],
      );
      final ours = batch.toJson();
      expect(ours.keys.toList(), exchange.requestBody.keys.toList());
      expect(ours['clientFeatures'], exchange.requestBody['clientFeatures']);
    });

    test('a held row carries its review and no revision', () {
      final result = SyncUploadResult.fromJson(exchange.responseBody);
      expect(result.written, 0);
      expect(result.refused, 0);
      expect(result.rows, hasLength(2));
      for (final row in result.rows) {
        expect(row.status, SyncRowStatus.held);
        expect(row.revision, isNull);
        expect(row.reviewId, isNotNull);
        expect(row.isWritten, isFalse);
        expect(row.action, SilexgisAction.ignore);
      }
      expect(result.rows[0].reviewId, isNot(result.rows[1].reviewId));
    });

    test('an account that is not reviewed is answered with no review', () {
      final result = SyncUploadResult.fromJson(
        ContractExchange('11-upload-create').responseBody,
      );
      expect(result.rows.single.reviewId, isNull);
    });
  });
}
