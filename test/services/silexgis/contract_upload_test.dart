import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/silexgis/model/geo_json_geometry.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_batch.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';

import 'contract_fixtures.dart';

/// Replays the five recorded writes.
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

      expectComposes(
        (ours['rows']! as List).single as Map<String, Object?>,
        ((recorded['rows']! as List).single as Map<String, Object?>),
        // Sent on every row rather than only when they changed: this server
        // clears a text field an upload does not mention (see
        // docs/integrations/silexgis/found-defects.md), and stating them is
        // sound regardless because the row carries the base revision it was
        // read at.
        deliberateAdditions: <String>{'description', 'properties'},
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
}
