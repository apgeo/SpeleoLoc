import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_survey_models.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_place_stations.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';

import 'contract_fixtures.dart';

/// Replays the recorded first page of the survey-models stream and the
/// recorded upload of the `placeStations` section.
void main() {
  group('31-survey-models-first-page', () {
    final exchange = ContractExchange('31-survey-models-first-page');

    test('reads the set\'s survey-models stream', () {
      expect(
        exchange.requestLine,
        'GET ${SilexgisContract.surveyModelsPath('<set>')}',
      );
    });

    test('lists the cave\'s line plots with the one it is shown by', () {
      final page = SyncSurveyModelsPage.fromJson(exchange.responseBody);
      expect(page.setRevision, 1);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, '<cursor>');

      final lox = page.models.firstWhere((m) => m.id == '<lox-model>');
      expect(lox.caveId, '<cave>');
      expect(lox.documentId, '<lox-document>');
      expect(lox.versionId, '<lox-version>');
      expect(lox.name, 'Sistemul');
      expect(lox.format, 'lox');
      expect(lox.extension, 'lox');
      expect(lox.isCurrent, isTrue);
      expect(lox.sizeBytes, 29);
      expect(lox.sha256, '<lox-sha256>');
      expect(lox.revision, '<timestamp>');

      final survex = page.models.firstWhere((m) => m.id == '<survex-model>');
      expect(survex.format, '3d');
      expect(survex.extension, '3d');
      expect(survex.isCurrent, isFalse);
    });

    test('names a model withheld from the account as one to drop', () {
      final page = SyncSurveyModelsPage.fromJson(exchange.responseBody);
      final tombstone = page.tombstones.single;
      expect(tombstone.id, '<withheld-model>');
      expect(tombstone.revision, '<timestamp>');
    });

    test('a place at a station names its model, and no splay', () {
      final page = SyncSurveyModelsPage.fromJson(exchange.responseBody);
      final mapping = page.placeStations.single;
      expect(mapping.id, '<place-station>');
      expect(mapping.placeId, '<place>');
      expect(mapping.surveyModelId, '<lox-model>');
      expect(mapping.documentId, isNull);
      expect(mapping.station, '1.12');
      expect(mapping.splay, isNull);
      expect(page.placeStationTombstones, isEmpty);
    });

    test('a splay end and a survey file read as the protocol states', () {
      final mapping = SyncPlaceStation.fromJson(<String, Object?>{
        'id': 'm-1',
        'placeId': 'p-1',
        'documentId': 'd-1',
        'station': 'A.3',
        'splay': <Object?>[1.5, -2, 0.25],
        'revision': 'r-1',
      });
      expect(mapping.surveyModelId, isNull);
      expect(mapping.documentId, 'd-1');
      expect(mapping.splay, <double>[1.5, -2, 0.25]);
    });
  });

  group('32-upload-place-stations', () {
    final exchange = ContractExchange('32-upload-place-stations');

    test('the section is the last one the server applies', () {
      expect(SyncUploadSection.values.last, SyncUploadSection.placeStations);
      expect(SyncUploadSection.placeStations.wireName, 'placeStations');
    });

    test('composes the recorded items', () {
      final recorded = (exchange.requestBody['placeStations']! as List)
          .cast<Map<String, Object?>>();
      final station = const SyncUploadPlaceStation(
        id: '<place-station>',
        baseRevision: null,
        placeId: '<place>',
        surveyModelId: '<survey-model>',
        station: '1.12',
      ).toJson();
      final splay = const SyncUploadPlaceStation(
        id: '<place-splay>',
        baseRevision: null,
        placeId: '<other-place>',
        documentId: '<survey-document>',
        station: 'A.3',
        splay: <double>[1.5, -2, 0.25],
      ).toJson();
      // The recording leaves out the members a create may omit.
      Map<String, Object?> sent(Map<String, Object?> json) =>
          Map<String, Object?>.from(json)
            ..remove('baseRevision')
            ..remove('deleted');
      expect(sent(station), recorded[0]);
      expect(sent(splay), recorded[1]);
      expect(station['deleted'], isFalse);
      expect(station.containsKey('documentId'), isFalse);
      expect(splay.containsKey('surveyModelId'), isFalse);
    });

    test('a removal carries only what names it', () {
      expect(
        const SyncUploadPlaceStation.delete(
          id: 'm-1',
          baseRevision: 'r-1',
        ).toJson(),
        <String, Object?>{'id': 'm-1', 'baseRevision': 'r-1', 'deleted': true},
      );
    });

    test('each item is answered in its own array', () {
      final result = SyncUploadResult.fromJson(exchange.responseBody);
      final answers = result.answersFor(SyncUploadSection.placeStations)!;
      expect(answers.map((a) => a.id), <String>[
        '<place-station>',
        '<place-splay>',
      ]);
      expect(answers.every((a) => a.status == SyncRowStatus.created), isTrue);
      expect(answers.first.revision, '<timestamp>');
    });

    test('the server\'s limits on a station and a splay', () {
      expect(SyncUploadPlaceStation.fits('1.12', null), isTrue);
      expect(SyncUploadPlaceStation.fits('', null), isFalse);
      expect(SyncUploadPlaceStation.fits('x' * 401, null), isFalse);
      expect(SyncUploadPlaceStation.fits('A.3', <double>[1, 2]), isFalse);
      expect(
        SyncUploadPlaceStation.fits('A.3', <double>[1, 2, 10001]),
        isFalse,
      );
      expect(
        SyncUploadPlaceStation.fits('A.3', <double>[1, double.nan, 0]),
        isFalse,
      );
    });

    test('a second mapping of a place asks to read and resubmit', () {
      final answer = SyncRowResult.fromJson(<String, Object?>{
        'id': 'm-1',
        'status': 'rejected',
        'code': SilexgisCodes.placeStationExists,
      });
      expect(answer.action, SilexgisAction.applyAndResubmit);
    });
  });
}
