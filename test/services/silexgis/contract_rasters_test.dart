import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_rasters.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_batch.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_rasters.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';

import 'contract_fixtures.dart';

/// Replays the recorded first page of the rasters stream, and composes the
/// `rasterMaps` and `rasterPins` sections of an upload as the protocol states
/// them — there is no recorded upload of either.
void main() {
  group('25-rasters-first-page', () {
    final exchange = ContractExchange('25-rasters-first-page');

    test('reads the set\'s rasters stream', () {
      expect(
        exchange.requestLine,
        'GET ${SilexgisContract.rastersPath('<set>')}',
      );
    });

    test('a map comes with the pins of places the member may see', () {
      final page = SyncRastersPage.fromJson(exchange.responseBody);
      expect(page.setRevision, 1);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, '<cursor>');
      expect(page.tombstones, isEmpty);

      final map = page.maps.single;
      expect(map.id, '<map>');
      expect(map.caveId, '<cave>');
      expect(map.caveAreaId, isNull);
      expect(map.title, 'Plan');
      expect(map.mapType, SyncRasterMapType.planView);
      expect(map.sortOrder, 0);
      expect(map.documentId, '<uuid-1>');
      expect(map.revision, '<timestamp>');

      // The map's other pin is on a protected place, and is absent.
      final pin = map.pins.single;
      expect(pin.id, '<pin>');
      expect(pin.placeId, '<place>');
      expect(pin.x, 120);
      expect(pin.y, 80);
      expect(pin.revision, '<timestamp>');
    });

    test('carries no position and no georeference', () {
      final map = (exchange.responseBody['maps']! as List).single as Map;
      expect(map.keys.toSet(), <String>{
        'id',
        'caveId',
        'caveAreaId',
        'title',
        'mapType',
        'sortOrder',
        'documentId',
        'revision',
        'pins',
      });
      for (final pin in (map['pins']! as List).cast<Map>()) {
        expect(pin.keys.toSet(), <String>{
          'id',
          'placeId',
          'x',
          'y',
          'revision',
        });
      }
    });
  });

  group('the map type', () {
    test('maps one to one between the phone and the wire', () {
      const pairs = <String, String>{
        'plane view': 'planView',
        'projected profile': 'projectedProfile',
        'extended profile': 'extendedProfile',
        'other': 'other',
      };
      for (final MapEntry(key: local, value: wire) in pairs.entries) {
        expect(SyncRasterMapType.fromLocal(local).wireName, wire);
        expect(SyncRasterMapType.fromWire(wire).localName, local);
      }
    });

    test('an unheard-of kind reads as other', () {
      expect(SyncRasterMapType.fromWire('isometric'), SyncRasterMapType.other);
      expect(SyncRasterMapType.fromWire(null), SyncRasterMapType.other);
      expect(SyncRasterMapType.fromLocal('sketch'), SyncRasterMapType.other);
    });
  });

  group('the raster sections of an upload', () {
    test('a new map names its staged picture', () {
      const map = SyncUploadRasterMap(
        id: 'm-1',
        baseRevision: null,
        caveId: 'c-1',
        title: 'Invented plan',
        mapType: SyncRasterMapType.projectedProfile,
        sortOrder: 2,
        fileName: 'raster_1.png',
        sha256: 'ab12',
        sizeBytes: 640,
        stagedUploadId: 't-1',
        clientUpdatedAt: '2026-10-28T08:05:00.000Z',
      );
      expect(map.toJson(), <String, Object?>{
        'id': 'm-1',
        'baseRevision': null,
        'deleted': false,
        'caveId': 'c-1',
        'title': 'Invented plan',
        'mapType': 'projectedProfile',
        'sortOrder': 2,
        'fileName': 'raster_1.png',
        'sha256': 'ab12',
        'sizeBytes': 640,
        'stagedUploadId': 't-1',
        'clientUpdatedAt': '2026-10-28T08:05:00.000Z',
      });
    });

    test('an edit keeping its picture names no staged bytes', () {
      const edit = SyncUploadRasterMap(
        id: 'm-1',
        baseRevision: 'rev-1',
        caveId: 'c-1',
        caveAreaId: 'a-1',
        title: 'Renamed',
        mapType: SyncRasterMapType.planView,
        sha256: 'ab12',
      );
      final json = edit.toJson();
      expect(json['caveAreaId'], 'a-1');
      expect(json.containsKey('stagedUploadId'), isFalse);
      expect(edit.withStagedUpload('t-2').toJson()['stagedUploadId'], 't-2');
    });

    test('a removal states its identity and nothing else', () {
      expect(
        const SyncUploadRasterMap.delete(
          id: 'm-1',
          baseRevision: 'rev-1',
        ).toJson(),
        <String, Object?>{
          'id': 'm-1',
          'baseRevision': 'rev-1',
          'deleted': true,
        },
      );
      expect(
        const SyncUploadRasterPin.delete(
          id: 'p-1',
          rasterMapId: 'm-1',
          baseRevision: 'rev-2',
        ).toJson(),
        <String, Object?>{
          'id': 'p-1',
          'rasterMapId': 'm-1',
          'baseRevision': 'rev-2',
          'deleted': true,
        },
      );
    });

    test('a pin names its map, its place and its pixel', () {
      const pin = SyncUploadRasterPin(
        id: 'p-1',
        rasterMapId: 'm-1',
        baseRevision: null,
        placeId: 'pl-1',
        x: 120,
        y: 80,
      );
      expect(pin.toJson(), <String, Object?>{
        'id': 'p-1',
        'rasterMapId': 'm-1',
        'baseRevision': null,
        'deleted': false,
        'placeId': 'pl-1',
        'x': 120,
        'y': 80,
      });
      expect(SyncUploadRasterPin.isPixel(0), isTrue);
      expect(SyncUploadRasterPin.isPixel(1000000), isTrue);
      expect(SyncUploadRasterPin.isPixel(1000001), isFalse);
      expect(SyncUploadRasterPin.isPixel(-1), isFalse);
      expect(SyncUploadRasterPin.isPixel(null), isFalse);
    });

    test('travel in their own arrays, maps before pins', () {
      const batch = SyncUploadBatch(
        batchId: 'b-1',
        sections: <SyncUploadSection, List<SyncUploadItem>>{
          SyncUploadSection.rasterPins: <SyncUploadItem>[
            SyncUploadRasterPin(
              id: 'p-1',
              rasterMapId: 'm-1',
              baseRevision: null,
              placeId: 'pl-1',
              x: 1,
              y: 2,
            ),
          ],
          SyncUploadSection.rasterMaps: <SyncUploadItem>[
            SyncUploadRasterMap(
              id: 'm-1',
              baseRevision: null,
              caveId: 'c-1',
              title: 'Invented',
              mapType: SyncRasterMapType.other,
              sha256: 'ab12',
            ),
          ],
        },
      );
      expect(batch.toJson().keys.toList(), <String>[
        'batchId',
        'contractVersion',
        'rasterMaps',
        'rasterPins',
      ]);
    });

    test('the raster codes take the action the error table names', () {
      SilexgisAction actionOf(String code) => SyncRowResult(
        id: 'x',
        status: SyncRowStatus.rejected,
        code: code,
      ).action;
      expect(actionOf(SilexgisCodes.mapCaveFixed), SilexgisAction.stop);
      expect(
        actionOf(SilexgisCodes.rasterNotAnImage),
        SilexgisAction.surfaceToUser,
      );
      expect(
        actionOf(SilexgisCodes.caveNotFound),
        SilexgisAction.surfaceToUser,
      );
      for (final code in <String>[
        SilexgisCodes.areaNotFound,
        SilexgisCodes.rasterMapNotFound,
        SilexgisCodes.placeNotFound,
        SilexgisCodes.pinExists,
        SilexgisCodes.fileBytesMissing,
        SilexgisCodes.fileHashMismatch,
      ]) {
        expect(actionOf(code), SilexgisAction.applyAndResubmit, reason: code);
      }
    });
  });
}
