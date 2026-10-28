import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_trips.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_batch.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_trips.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';

import 'contract_fixtures.dart';

/// Replays the recorded first page of the trips stream, and composes the
/// `tripRecordings` and `tripPoints` sections of an upload as the protocol
/// states them — there is no recorded upload of either.
void main() {
  group('24-trips-first-page', () {
    final exchange = ContractExchange('24-trips-first-page');

    test('reads the set\'s trips stream', () {
      expect(
        exchange.requestLine,
        'GET ${SilexgisContract.tripsPath('<set>')}',
      );
    });

    test('a recording comes with its scans, in the order they were made', () {
      final page = SyncTripsPage.fromJson(exchange.responseBody);
      expect(page.setRevision, 1);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, '<cursor>');
      expect(page.tombstones, isEmpty);
      // Present and empty: no scan was removed, which is not the same as a
      // server that does not name them.
      expect(page.pointTombstones, isEmpty);

      final recording = page.recordings.single;
      expect(recording.id, '<recording>');
      expect(recording.caveId, '<cave>');
      expect(recording.title, 'Trip');
      expect(recording.log, 'entered; turned back at the sump');
      expect(recording.endedAt, '<timestamp>');
      expect(recording.createdByDeviceUserId, '<uuid-1>');
      // Named only while the directory lists that caver for the reader.
      expect(recording.createdByCaverId, isNull);
      expect(recording.revision, '<timestamp>');

      expect(recording.points.map((p) => p.id), <String>[
        '<scan-at-place>',
        '<scan-at-no-place>',
      ]);
      expect(recording.points.first.placeId, '<place>');
      expect(recording.points.first.notes, 'scan 10');
      // A scan may name no place, and then names no author either here.
      expect(recording.points.last.placeId, isNull);
      expect(recording.points.last.createdByDeviceUserId, isNull);
      expect(recording.points.first.createdByCaverId, isNull);
    });

    test('a page without the member reads as one that does not name scans', () {
      final json = Map<String, Object?>.from(exchange.responseBody)
        ..remove('pointTombstones');
      expect(SyncTripsPage.fromJson(json).pointTombstones, isNull);
    });

    test('a removed scan names its recording and the moment', () {
      final json = Map<String, Object?>.from(exchange.responseBody)
        ..['pointTombstones'] = <Object?>[
          <String, Object?>{
            'id': 's-1',
            'recordingId': 'r-1',
            'deletedAt': '2026-10-28T09:00:00.000Z',
          },
        ];
      final tombstone = SyncTripsPage.fromJson(json).pointTombstones!.single;
      expect(tombstone.id, 's-1');
      expect(tombstone.recordingId, 'r-1');
      expect(tombstone.deletedAt, '2026-10-28T09:00:00.000Z');
    });

    test('carries no position and no device', () {
      final recording =
          (exchange.responseBody['recordings']! as List).single as Map;
      expect(recording.containsKey('deviceUuid'), isFalse);
      for (final point in (recording['points']! as List).cast<Map>()) {
        expect(point.keys.toSet(), <String>{
          'id',
          'placeId',
          'scannedAt',
          'notes',
          'createdByDeviceUserId',
          'createdByCaverId',
          'revision',
        });
      }
    });
  });

  group('the trip sections of an upload', () {
    test('an open recording states no end', () {
      const open = SyncUploadTripRecording(
        id: 'r-1',
        baseRevision: null,
        caveId: 'c-1',
        title: 'Invented',
        startedAt: '2026-10-28T08:00:00.000Z',
        createdByDeviceUserId: 'u-1',
        clientUpdatedAt: '2026-10-28T08:05:00.000Z',
      );
      expect(open.toJson(), <String, Object?>{
        'id': 'r-1',
        'baseRevision': null,
        'deleted': false,
        'caveId': 'c-1',
        'title': 'Invented',
        'description': null,
        'log': null,
        'startedAt': '2026-10-28T08:00:00.000Z',
        'createdByDeviceUserId': 'u-1',
        'clientUpdatedAt': '2026-10-28T08:05:00.000Z',
      });
    });

    test('an author this device cannot name is left out', () {
      const edit = SyncUploadTripRecording(
        id: 'r-1',
        baseRevision: 'rev-1',
        caveId: 'c-1',
        title: 'Invented',
        startedAt: '2026-10-28T08:00:00.000Z',
        endedAt: '2026-10-28T12:00:00.000Z',
      );
      final json = edit.toJson();
      expect(json['endedAt'], '2026-10-28T12:00:00.000Z');
      expect(json.containsKey('createdByDeviceUserId'), isFalse);
    });

    test('a removal states its identity and nothing else', () {
      expect(
        const SyncUploadTripRecording.delete(
          id: 'r-1',
          baseRevision: 'rev-1',
        ).toJson(),
        <String, Object?>{
          'id': 'r-1',
          'baseRevision': 'rev-1',
          'deleted': true,
        },
      );
      expect(
        const SyncUploadTripPoint.delete(
          id: 's-1',
          recordingId: 'r-1',
          baseRevision: 'rev-2',
        ).toJson(),
        <String, Object?>{
          'id': 's-1',
          'recordingId': 'r-1',
          'baseRevision': 'rev-2',
          'deleted': true,
        },
      );
    });

    test('a scan names its recording and its place', () {
      const scan = SyncUploadTripPoint(
        id: 's-1',
        recordingId: 'r-1',
        baseRevision: null,
        placeId: 'p-1',
        scannedAt: '2026-10-28T09:00:00.000Z',
        notes: 'sump',
        createdByDeviceUserId: 'u-1',
      );
      expect(scan.toJson(), <String, Object?>{
        'id': 's-1',
        'recordingId': 'r-1',
        'baseRevision': null,
        'deleted': false,
        'placeId': 'p-1',
        'scannedAt': '2026-10-28T09:00:00.000Z',
        'notes': 'sump',
        'createdByDeviceUserId': 'u-1',
      });
    });

    test('travel in their own arrays, recordings before scans', () {
      const batch = SyncUploadBatch(
        batchId: 'b-1',
        sections: <SyncUploadSection, List<SyncUploadItem>>{
          SyncUploadSection.tripPoints: <SyncUploadItem>[
            SyncUploadTripPoint(
              id: 's-1',
              recordingId: 'r-1',
              baseRevision: null,
              scannedAt: '2026-10-28T09:00:00.000Z',
            ),
          ],
          SyncUploadSection.tripRecordings: <SyncUploadItem>[
            SyncUploadTripRecording(
              id: 'r-1',
              baseRevision: null,
              caveId: 'c-1',
              title: 'Invented',
              startedAt: '2026-10-28T08:00:00.000Z',
            ),
          ],
        },
      );
      final json = batch.toJson();
      expect(json.keys.toList(), <String>[
        'batchId',
        'contractVersion',
        'tripRecordings',
        'tripPoints',
      ]);
    });

    test('the trip codes take the action the error table names', () {
      SilexgisAction actionOf(String code) => SyncRowResult(
        id: 'x',
        status: SyncRowStatus.rejected,
        code: code,
      ).action;
      expect(
        actionOf(SilexgisCodes.caveNotFound),
        SilexgisAction.surfaceToUser,
      );
      expect(
        actionOf(SilexgisCodes.recordingNotFound),
        SilexgisAction.applyAndResubmit,
      );
      expect(
        actionOf(SilexgisCodes.placeNotFound),
        SilexgisAction.applyAndResubmit,
      );
    });
  });
}
