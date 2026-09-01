import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_feature_row.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_batch.dart';
import 'package:speleoloc/services/silexgis/silexgis_feature_mapper.dart';

/// Which SpeleoLoc record becomes which SilexGIS record, which fields carry
/// across, and — as importantly — which values may never be sent at all.
void main() {
  const mapper = SilexgisFeatureMapper();

  final caveUuid = Uuid.v7();
  final areaUuid = Uuid.v7();
  final placeUuid = Uuid.v7();

  Cave aCave({String? localIndex = 'C7'}) => Cave(
    uuid: caveUuid,
    title: 'Peștera Mică',
    description: 'A short cave.',
    surfaceAreaUuid: areaUuid,
    caveLocalIndex: localIndex,
    updatedAt: DateTime.utc(2026, 8, 28, 7, 2, 11).millisecondsSinceEpoch,
  );

  CavePlace aPlace({
    bool entrance = false,
    bool main = false,
    double? latitude = 45.531,
    double? longitude = 25.441,
    double? altitude = 1240,
  }) => CavePlace(
    uuid: placeUuid,
    title: 'Sala Mare',
    description: 'Large chamber.',
    caveUuid: caveUuid,
    placeCodeIdentifier: 'AB-0007',
    qrCodeResourceIdentifier: 'k3f9zq81',
    latitude: latitude,
    longitude: longitude,
    altitude: altitude,
    depthInCave: 137.5,
    isEntrance: entrance ? 1 : 0,
    isMainEntrance: main ? 1 : 0,
    updatedAt: DateTime.utc(2026, 8, 28, 7, 2, 11).millisecondsSinceEpoch,
  );

  /// The property document a row actually puts on the wire. Absent means the
  /// row states none, which is not the same as stating an empty one.
  Map<String, Object?> propertiesOf(SyncUploadRow row) =>
      (row.toJson()['properties'] as Map<String, Object?>?) ??
      const <String, Object?>{};

  group('a cave', () {
    test('never carries a geometry', () {
      // A cave's own map point is not a field: it is a copy of its main
      // entrance's, kept in step by the server. Sending one is a silent no-op
      // that looks like it worked.
      final row = mapper.caveRow(aCave(), baseRevision: null);
      expect(row.geometry, isNull);
      expect(row.toJson().containsKey('geometry'), isFalse);
    });

    test('is created under its surface area, by the shared identifier', () {
      final row = mapper.caveRow(
        aCave(),
        baseRevision: null,
        parentSurfaceAreaId: areaUuid.toString(),
      );
      expect(row.id, caveUuid.toString());
      expect(row.kind, SyncUploadKind.cave);
      expect(row.toJson()['parentId'], areaUuid.toString());
      expect(row.toJson()['caveTypeCode'], 'cave');
    });

    test('states no container and no type once the row exists there', () {
      // Both are read only on a create. Sending them on an update would be
      // ignored, and would overwrite nothing — but it would also suggest this
      // contract can re-parent a row or change its kind, which it cannot.
      final row = mapper.caveRow(
        aCave(),
        baseRevision: '2026-08-28T09:14:52.113Z',
        parentSurfaceAreaId: areaUuid.toString(),
      );
      final json = row.toJson();
      expect(json.containsKey('parentId'), isFalse);
      expect(json.containsKey('caveTypeCode'), isFalse);
      expect(json['baseRevision'], '2026-08-28T09:14:52.113Z');
    });

    test('carries its local index and the device row-shape version', () {
      final row = mapper.caveRow(aCave(), baseRevision: null);
      expect(propertiesOf(row), <String, Object?>{
        'speleolocCaveLocalIndex': 'C7',
        'speleolocSchemaVersion': kSpeleolocPropertySchemaVersion,
      });
    });

    test('omits an identifier it does not have rather than sending null', () {
      final row = mapper.caveRow(aCave(localIndex: null), baseRevision: null);
      expect(propertiesOf(row).containsKey('speleolocCaveLocalIndex'), isFalse);
    });
  });

  group('a cave place', () {
    test('becomes a generic cave_place under its container', () {
      final row = mapper.cavePlaceRow(
        CavePlaceUpload(place: aPlace()),
        baseRevision: null,
        parentId: caveUuid.toString(),
      );
      expect(row.kind, SyncUploadKind.generic);
      expect(row.toJson()['featureTypeCode'], 'cave_place');
      expect(row.toJson()['parentId'], caveUuid.toString());
      expect(row.isMain, isFalse);
    });

    test('becomes an entrance when the local row says it is one', () {
      final row = mapper.cavePlaceRow(
        CavePlaceUpload(place: aPlace(entrance: true, main: true)),
        baseRevision: null,
        parentId: caveUuid.toString(),
      );
      expect(row.kind, SyncUploadKind.caveEntrance);
      expect(row.isMain, isTrue);
      expect(row.toJson()['entranceTypeCode'], 'natural');
      // An entrance is not a generic feature and names no feature type.
      expect(row.toJson().containsKey('featureTypeCode'), isFalse);
    });

    test('writes a point longitude-first', () {
      final row = mapper.cavePlaceRow(
        CavePlaceUpload(place: aPlace()),
        baseRevision: null,
        parentId: caveUuid.toString(),
      );
      expect(row.geometry!.toJson(), <String, Object?>{
        'type': 'Point',
        'coordinates': <Object?>[25.441, 45.531],
      });
      // The altitude travels in its own field, not folded in as a third
      // ordinate, so nothing states the same thing twice.
      expect(row.toJson()['altitude'], 1240);
    });

    test('a place with no fix is a legitimate row, not an error', () {
      final row = mapper.cavePlaceRow(
        CavePlaceUpload(place: aPlace(latitude: null, longitude: null)),
        baseRevision: null,
        parentId: caveUuid.toString(),
      );
      expect(row.geometry, isNull);
      // Absent, not null: absent means "leave the stored position alone",
      // which is what a device with nothing to assert wants.
      expect(row.toJson().containsKey('geometry'), isFalse);
    });

    test('carries the codes, including the two borrowed from above it', () {
      final row = mapper.cavePlaceRow(
        CavePlaceUpload(
          place: aPlace(),
          caveLocalIndex: 'C7',
          generalAreaIdentifier: 'BV',
        ),
        baseRevision: null,
        parentId: caveUuid.toString(),
      );
      expect(propertiesOf(row), <String, Object?>{
        'speleolocPci': 'AB-0007',
        'speleolocQcri': 'k3f9zq81',
        'speleolocCaveLocalIndex': 'C7',
        'speleolocGeneralAreaIdentifier': 'BV',
        'speleolocDepthInCave': 137.5,
        'speleolocSchemaVersion': kSpeleolocPropertySchemaVersion,
      });
    });
  });

  group('no coordinate ever reaches a property document', () {
    // The document is emitted verbatim to every reader that can see the row,
    // with no protection filter anywhere on its path — including a reader for
    // whom the geometry was just withheld. On the two kinds that carry a
    // schema an undeclared key is refused; on every other kind here there is
    // none, so a latitude would be accepted silently and published. The rule
    // is this client's alone and there is no server-side backstop.
    const forbidden = <String>{
      'latitude',
      'longitude',
      'lat',
      'lon',
      'lng',
      'altitude',
      'elevation',
      'coordinates',
      'geometry',
      'easting',
      'northing',
    };

    final rows = <String, SyncUploadRow>{
      'cave': mapper.caveRow(aCave(), baseRevision: null),
      'surface area': mapper.surfaceAreaRow(
        SurfaceArea(
          uuid: areaUuid,
          title: 'Bucegi',
          generalAreaIdentifier: 'BV',
        ),
        baseRevision: null,
      ),
      'cave area': mapper.caveAreaRow(
        CaveArea(uuid: areaUuid, title: 'Galeria', caveUuid: caveUuid),
        baseRevision: null,
        parentCaveId: caveUuid.toString(),
      ),
      'cave place': mapper.cavePlaceRow(
        CavePlaceUpload(
          place: aPlace(),
          caveLocalIndex: 'C7',
          generalAreaIdentifier: 'BV',
        ),
        baseRevision: null,
        parentId: caveUuid.toString(),
      ),
      'entrance': mapper.cavePlaceRow(
        CavePlaceUpload(place: aPlace(entrance: true, main: true)),
        baseRevision: null,
        parentId: caveUuid.toString(),
      ),
    };

    for (final entry in rows.entries) {
      test('${entry.key}: no locating key, and no locating value', () {
        final properties = propertiesOf(entry.value);
        for (final key in properties.keys) {
          expect(
            forbidden.contains(key.toLowerCase()),
            isFalse,
            reason: 'property `$key` on a ${entry.key}',
          );
          expect(
            key.startsWith('speleoloc'),
            isTrue,
            reason: 'undeclared property `$key` on a ${entry.key}',
          );
        }
        // The place's own coordinates are nowhere in the document.
        expect(properties.values, isNot(contains(45.531)));
        expect(properties.values, isNot(contains(25.441)));
        expect(properties.values, isNot(contains(1240)));
      });
    }

    test('a cave area states no property document at all', () {
      // It has nothing of the device's to say. Sending an empty one would be a
      // statement — that the row's property document is empty — and would
      // replace whatever the web interface put there.
      expect(rows['cave area']!.toJson().containsKey('properties'), isFalse);
    });

    test('every key the schema-bearing kinds declare, and no other', () {
      // `cave_place` and `surface_area` declare additionalProperties: false,
      // so an undeclared key is a `feature.properties_invalid` refusal rather
      // than a silent store.
      const declared = <String>{
        'speleolocPci',
        'speleolocQcri',
        'speleolocCaveLocalIndex',
        'speleolocGeneralAreaIdentifier',
        'speleolocDepthInCave',
        'speleolocSchemaVersion',
      };
      expect(
        propertiesOf(rows['cave place']!).keys,
        everyElement(isIn(declared)),
      );
      expect(
        propertiesOf(rows['surface area']!).keys,
        everyElement(
          isIn(<String>{
            'speleolocGeneralAreaIdentifier',
            'speleolocSchemaVersion',
          }),
        ),
      );
    });
  });

  group('reading a downloaded row', () {
    SyncFeatureRow row(Map<String, Object?> overrides) =>
        SyncFeatureRow.fromJson(<String, Object?>{
          'id': placeUuid.toString(),
          'kind': SilexgisKinds.generic,
          'updatedAt': '2026-08-28T09:14:52.113Z',
          ...overrides,
        });

    test('a cave keeps its local index', () {
      final mapped = mapper.read(
        row(<String, Object?>{
          'kind': SilexgisKinds.cave,
          'name': 'Peștera Mică',
          'properties': <String, Object?>{
            'speleolocCaveLocalIndex': 'C7',
            'speleolocSchemaVersion': 1,
          },
        }),
      );
      expect(mapped, isA<MappedCave>());
      expect((mapped as MappedCave).caveLocalIndex, 'C7');
      expect(mapped.title, 'Peștera Mică');
    });

    test('an entrance reads its altitude off the point\'s third ordinate', () {
      // The wire row has no altitude member at all, and the protocol
      // document's row table says it is the whole row — so a client reading
      // only the first two ordinates drops every entrance altitude silently.
      final mapped =
          mapper.read(
                row(<String, Object?>{
                  'kind': SilexgisKinds.caveEntrance,
                  'name': 'Main entrance',
                  'geometry': <String, Object?>{
                    'type': 'Point',
                    'coordinates': <Object?>[25.6, 45.6, 1240],
                  },
                }),
              )
              as MappedCavePlace;
      expect(mapped.isEntrance, isTrue);
      expect(mapped.longitude, 25.6);
      expect(mapped.latitude, 45.6);
      expect(mapped.altitude, 1240);
    });

    test('a two-dimensional point simply has no altitude', () {
      final mapped =
          mapper.read(
                row(<String, Object?>{
                  'featureTypeCode': 'cave_place',
                  'geometry': <String, Object?>{
                    'type': 'Point',
                    'coordinates': <Object?>[25.441, 45.531],
                  },
                  'properties': <String, Object?>{
                    'speleolocPci': 'AB-0007',
                    'speleolocDepthInCave': 137.5,
                  },
                }),
              )
              as MappedCavePlace;
      expect(mapped.altitude, isNull);
      expect(mapped.placeCodeIdentifier, 'AB-0007');
      expect(mapped.depthInCave, 137.5);
    });

    test('a withheld row is absent, so a null position means no position', () {
      // A row this caller may not place is not in the payload at all. A null
      // geometry on a row that *is* here therefore means the position was
      // never recorded, and must not be read as "withheld".
      final mapped =
          mapper.read(row(<String, Object?>{'featureTypeCode': 'cave_place'}))
              as MappedCavePlace;
      expect(mapped.latitude, isNull);
      expect(mapped.longitude, isNull);
    });

    test('the containment edge is the parent to hang the row under', () {
      final mapped = mapper.read(
        row(<String, Object?>{
          'featureTypeCode': 'cave_area',
          'name': 'Galeria',
          'parents': <Object?>[
            <String, Object?>{
              'parentId': caveUuid.toString(),
              'isPrimary': true,
            },
          ],
        }),
      );
      expect(mapped, isA<MappedCaveArea>());
      expect(mapped.parentUuid, caveUuid);
    });

    test(
      'a row inside a cave the caller cannot see arrives with no parents',
      () {
        // `parents` is filtered to parents this caller may read, so it is not
        // necessarily a complete ancestry — and protection is never derived from
        // it.
        final mapped = mapper.read(
          row(<String, Object?>{
            'featureTypeCode': 'cave_place',
            'protectedEffective': true,
          }),
        );
        expect(mapped.parentUuid, isNull);
        expect(mapped.row.protectedEffective, isTrue);
      },
    );

    test('a kind this build has never heard of is not an error', () {
      final mapped = mapper.read(row(<String, Object?>{'kind': 'centerline'}));
      expect(mapped, isA<UnmappedFeature>());
      expect((mapped as UnmappedFeature).kind, 'centerline');
    });

    test('a generic row of an unknown type code is not an error either', () {
      // An installation's taxonomy is its own and grows without a contract
      // change.
      final mapped = mapper.read(
        row(<String, Object?>{'featureTypeCode': 'karst_area'}),
      );
      expect(mapped, isA<UnmappedFeature>());
      expect((mapped as UnmappedFeature).featureTypeCode, 'karst_area');
    });
  });
}
