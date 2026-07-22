import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/geo_transfer/geo_waypoint.dart';
import 'package:speleoloc/services/geo_transfer/geo_waypoint_reader.dart';
import 'package:speleoloc/services/geo_transfer/gpx_writer.dart';
import 'package:speleoloc/services/geo_transfer/kml_writer.dart';
import 'package:speleoloc/services/geo_transfer/place_transfer_service.dart';
import 'package:speleoloc/services/user_repository.dart';

void main() {
  const waypoints = [
    GeoWaypoint(
      name: 'Entrance - Cave A',
      latitude: 45.3592,
      longitude: 22.7147,
      altitude: 1450.5,
      description: 'main sink',
    ),
    GeoWaypoint(name: 'Lake - Cave B', latitude: -33.9, longitude: 151.2),
  ];

  group('codec round trips', () {
    test('GPX write → parse preserves every field', () {
      final parsed = parseWaypoints(writeGpx(waypoints));
      expect(parsed, hasLength(2));
      expect(parsed[0].name, 'Entrance - Cave A');
      expect(parsed[0].latitude, closeTo(45.3592, 1e-6));
      expect(parsed[0].longitude, closeTo(22.7147, 1e-6));
      expect(parsed[0].altitude, closeTo(1450.5, 0.01));
      expect(parsed[0].description, 'main sink');
      expect(parsed[1].altitude, isNull);
      expect(parsed[1].description, isNull);
    });

    test('KML write → parse preserves every field', () {
      final parsed = parseWaypoints(writeKml(waypoints));
      expect(parsed, hasLength(2));
      expect(parsed[0].name, 'Entrance - Cave A');
      expect(parsed[0].latitude, closeTo(45.3592, 1e-6));
      expect(parsed[0].longitude, closeTo(22.7147, 1e-6));
      expect(parsed[0].altitude, closeTo(1450.5, 0.01));
      expect(parsed[1].latitude, closeTo(-33.9, 1e-6));
    });

    test('XML-significant characters survive the round trip', () {
      const tricky = [
        GeoWaypoint(name: 'A <&> "B"', latitude: 1, longitude: 2),
      ];
      expect(parseWaypoints(writeGpx(tricky)).single.name, 'A <&> "B"');
      expect(parseWaypoints(writeKml(tricky)).single.name, 'A <&> "B"');
    });
  });

  group('parseWaypoints on foreign files', () {
    test('reads a namespaced Google Earth KML with folders', () {
      const kml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document><Folder>
    <Placemark>
      <name>Pit</name>
      <Point><coordinates>
        22.7147000,45.3592000,1450
      </coordinates></Point>
    </Placemark>
    <Placemark><name>A line, not a point</name>
      <LineString><coordinates>1,1 2,2</coordinates></LineString>
    </Placemark>
  </Folder></Document>
</kml>''';
      final parsed = parseWaypoints(kml);
      expect(parsed, hasLength(1));
      expect(parsed.single.name, 'Pit');
      expect(parsed.single.altitude, 1450);
    });

    test('reads a Garmin-style GPX with cmt instead of desc', () {
      const gpx = '''
<?xml version="1.0"?>
<gpx version="1.1" creator="x" xmlns="http://www.topografix.com/GPX/1/1">
  <wpt lat="45.5" lon="22.5"><name>W1</name><cmt>note</cmt></wpt>
  <wpt lat="999" lon="22.5"><name>bad lat is skipped</name></wpt>
</gpx>''';
      final parsed = parseWaypoints(gpx);
      expect(parsed, hasLength(1));
      expect(parsed.single.description, 'note');
    });

    test('rejects non-XML and unknown roots', () {
      expect(() => parseWaypoints('not xml'), throwsFormatException);
      expect(
        () => parseWaypoints('<svg xmlns="http://www.w3.org/2000/svg"/>'),
        throwsFormatException,
      );
    });

    test('NaN coordinates are skipped, not imported', () {
      const gpx = '''
<gpx version="1.1" creator="x" xmlns="http://www.topografix.com/GPX/1/1">
  <wpt lat="NaN" lon="22.5"><name>bad</name></wpt>
  <wpt lat="45.5" lon="22.5"><name>good</name></wpt>
</gpx>''';
      final parsed = parseWaypoints(gpx);
      expect(parsed.map((w) => w.name), ['good']);
    });
  });

  group('PlaceTransferService', () {
    late AppDatabase db;
    late CaveRepository caveRepo;
    late CavePlaceRepository placeRepo;
    late PlaceTransferService service;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      late ChangeLogger loggerRef;
      final users = UserRepository(db, () => loggerRef);
      final currentUser = CurrentUserService(
        db,
        users,
        ConfigurationRepository(db),
      );
      await currentUser.initialize();
      loggerRef = ChangeLogger(db, currentUser);
      caveRepo = CaveRepository(db, currentUser, loggerRef);
      placeRepo = CavePlaceRepository(db, currentUser, loggerRef);
      service = PlaceTransferService(db, caveRepo, placeRepo);
    });

    tearDown(() => db.close());

    Future<Uuid> insertPlace(
      Uuid caveUuid,
      String title, {
      double? lat,
      double? lng,
    }) async {
      final uuid = Uuid.v7();
      await db
          .into(db.cavePlaces)
          .insert(
            CavePlacesCompanion.insert(
              uuid: uuid,
              title: title,
              caveUuid: caveUuid,
              latitude: Value(lat),
              longitude: Value(lng),
            ),
          );
      return uuid;
    }

    test('collectWaypoints exports located places with list labels', () async {
      final caveA = await caveRepo.addCave('Cave A');
      final caveB = await caveRepo.addCave('Cave B');
      await insertPlace(caveA, 'Entrance', lat: 45.1, lng: 22.1);
      await insertPlace(caveA, 'No coordinates');
      await insertPlace(caveB, 'Lake', lat: 46.0, lng: 23.0);

      final all = await service.collectWaypoints();
      expect(all.map((w) => w.name).toSet(), {
        'Entrance - Cave A',
        'Lake - Cave B',
      });

      final onlyA = await service.collectWaypoints(caveUuids: {caveA});
      expect(onlyA.single.name, 'Entrance - Cave A');
      expect(onlyA.single.latitude, 45.1);
    });

    test('importWaypoints creates places and skips duplicate titles', () async {
      final cave = await caveRepo.addCave('Cave');
      await insertPlace(cave, 'Existing', lat: 1, lng: 1);

      final result = await service.importWaypoints(cave, const [
        GeoWaypoint(name: 'New point', latitude: 45.2, longitude: 22.2),
        GeoWaypoint(name: 'existing', latitude: 45.3, longitude: 22.3),
        GeoWaypoint(name: '', latitude: 45.4, longitude: 22.4),
      ]);

      expect(result.created, 2);
      expect(result.skipped, 1);
      final places = await placeRepo.getCavePlaces(cave);
      final titles = places.map((p) => p.title).toSet();
      expect(titles, {'Existing', 'New point', 'Waypoint 1'});
      final imported = places.firstWhere((p) => p.title == 'New point');
      expect(imported.latitude, 45.2);
      expect(imported.longitude, 22.2);
      expect(imported.isEntrance, 0);
    });

    test('import → export round trip', () async {
      final cave = await caveRepo.addCave('Cave');
      await service.importWaypoints(cave, const [
        GeoWaypoint(
          name: 'P1',
          latitude: 45.5,
          longitude: 22.5,
          altitude: 900,
        ),
      ]);

      final exported = await service.collectWaypoints(caveUuids: {cave});
      expect(exported.single.name, 'P1 - Cave');
      expect(exported.single.altitude, 900);
    });

    test('re-importing this app\'s own export twins nothing', () async {
      final cave = await caveRepo.addCave('Cave A');
      await insertPlace(cave, 'Entrance', lat: 45.1, lng: 22.1);

      // Names carry the export decoration '<place> - <cave>'.
      final exported = await service.collectWaypoints(caveUuids: {cave});
      final result = await service.importWaypoints(cave, exported);

      expect(result.created, 0);
      expect(result.skipped, 1);
      expect(await placeRepo.getCavePlaces(cave), hasLength(1));
    });

    test('an empty cave set exports nothing, not everything', () async {
      final cave = await caveRepo.addCave('Cave');
      await insertPlace(cave, 'Entrance', lat: 45.1, lng: 22.1);

      expect(await service.collectWaypoints(caveUuids: const {}), isEmpty);
      expect(await service.collectWaypoints(), hasLength(1));
    });
  });
}
