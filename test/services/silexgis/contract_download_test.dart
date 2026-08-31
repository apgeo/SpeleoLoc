import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/silexgis/model/sync_download_page.dart';
import 'package:speleoloc/services/silexgis/model/sync_feature_row.dart';

import 'contract_fixtures.dart';

/// Replays the four recorded reads. These bytes are the specification: where
/// the documents and these files disagree, the files are right.
void main() {
  group('07-download-first-page', () {
    final exchange = ContractExchange('07-download-first-page');
    late SyncDownloadPage page;
    setUpAll(() => page = SyncDownloadPage.fromJson(exchange.responseBody));

    test('is a plain download with no cursor and no page size', () {
      expect(exchange.requestLine, 'GET /api/v1/sync/sets/<set>/download');
      expect(exchange.status, 200);
    });

    test('carries the settings document with the revision it belongs to', () {
      expect(page.setRevision, 1);
      expect(page.settings, {'digits': 4, 'pciStrategy': 'ro-default'});
    });

    test('carries a cave and the place inside it, in change order', () {
      expect(page.features.map((f) => f.kind), [
        SilexgisKinds.cave,
        SilexgisKinds.generic,
      ]);

      final cave = page.features[0];
      expect(cave.featureTypeCode, isNull);
      expect(cave.category, 'underground');
      expect(cave.geometry, isNull);
      expect(cave.parents, isEmpty);
      expect(cave.propertiesSchemaVersion, isNull);

      final place = page.features[1];
      expect(place.featureTypeCode, 'cave_place');
      expect(place.propertiesSchemaVersion, 1);
      expect(place.primaryParent?.parentId, cave.id);
      expect(place.parents.single.isPrimary, isTrue);
    });

    test('reads a point longitude-first, as GeoJSON orders one', () {
      final geometry = page.features[1].geometry!;
      expect(geometry.type, 'Point');
      expect(geometry.longitude, 25.441);
      expect(geometry.latitude, 45.531);
    });

    test('keeps a watermark even though the device has caught up', () {
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNotNull);
    });

    test('carries clientUpdatedAt null on a row the web interface wrote', () {
      expect(page.features.every((f) => f.clientUpdatedAt == null), isTrue);
    });
  });

  group('08-download-cursor-restart', () {
    final exchange = ContractExchange('08-download-cursor-restart');

    test('resumes with the cursor the first page returned', () {
      expect(
        exchange.requestTarget,
        '/api/v1/sync/sets/<set>/download?cursor=<cursor>&pageSize=1',
      );
    });

    test('says to come back rather than that the set is exhausted', () {
      final page = SyncDownloadPage.fromJson(exchange.responseBody);
      expect(page.features, hasLength(1));
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, isNotNull);
    });
  });

  group('09-download-tombstones', () {
    final exchange = ContractExchange('09-download-tombstones');

    test(
      'a removed row arrives as an identifier and a moment, and no more',
      () {
        final page = SyncDownloadPage.fromJson(exchange.responseBody);
        expect(page.features, isEmpty);
        expect(page.tombstones, hasLength(1));
        expect(page.tombstones.single.id, isNotEmpty);
        expect(page.tombstones.single.deletedAt, isNotEmpty);

        // Nothing else, ever: a name is half of what protection hides and the
        // ancestry would publish which cave a deleted place hung under.
        final raw =
            (exchange.responseBody['tombstones']! as List).single
                as Map<String, Object?>;
        expect(raw.keys, unorderedEquals(<String>['id', 'deletedAt']));
      },
    );
  });

  group('10-download-protected-withheld', () {
    final exchange = ContractExchange('10-download-protected-withheld');
    late SyncDownloadPage page;
    setUpAll(() => page = SyncDownloadPage.fromJson(exchange.responseBody));

    test('a row the caller may not place is absent, not blurred', () {
      expect(page.features, hasLength(2));
      expect(page.features.map((f) => f.name), [
        'Withhold cave <marker>',
        'Open place <marker>',
      ]);
      // Every row that is here has an exact position or none of its own; there
      // is no approximate stand-in on this channel to mistake for one.
      expect(page.features.every((f) => !f.protectedEffective), isTrue);
    });

    test('nothing in the payload says a row was kept back', () {
      expect(page.tombstones, isEmpty);
      expect(page.hasMore, isFalse);
      // A withheld row does not shorten a page, is not counted, and is not
      // reported as a deletion. The device cannot tell it from one that was
      // never there, and that is deliberate.
      expect(
        exchange.responseBody.keys,
        unorderedEquals(<String>[
          'setRevision',
          'settings',
          'features',
          'tombstones',
          'nextCursor',
          'hasMore',
        ]),
      );
    });
  });

  test('an unrecognised kind is a row to store, never an error', () {
    // An installation's taxonomy grows without a contract change, so a kind or
    // a type code this build has never heard of has to survive parsing.
    final row = SyncFeatureRow.fromJson(<String, Object?>{
      'id': '0198f1b4-0000-7000-8000-000000000001',
      'kind': 'somethingNewEntirely',
      'featureTypeCode': 'glacier_cave',
      'updatedAt': '2026-08-28T09:14:52.113Z',
      'aFieldThisBuildHasNeverSeen': 42,
    });
    expect(row.kind, 'somethingNewEntirely');
    expect(row.featureTypeCode, 'glacier_cave');
  });
}
