import 'package:drift/drift.dart' show Value;
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_model/place_station_mapping_repository.dart';

import 'sync_device.dart';

/// A cave holding one of each kind of record that can hang on a cave, all
/// invented: an area with a place in it, a place outside it pinned on a
/// map, a beacon, a trip with a point at a place and a document on each,
/// documents linked to the cave and to the area, and a survey-model station
/// mapped to a place.
///
/// [rows] lists, table by table, what deleting the cave removes. The three
/// documents themselves outlive the cave, as they do in the app.
class PopulatedCave {
  PopulatedCave._(this.cave, this.area, this.pinnedPlace, this.rows);

  final Uuid cave;
  final Uuid area;

  /// The place outside the area, pinned on the cave's map and visited by
  /// the trip.
  final Uuid pinnedPlace;

  final Map<String, Set<Uuid>> rows;

  static Future<PopulatedCave> build(
    SyncTestDevice d, {
    String title = 'Invented Cave',
  }) async {
    final db = d.db;
    final cave = await d.caves.addCave(title);
    final area = await d.caves.addCaveArea(cave, 'Invented Hall');
    final inArea = Uuid.v7();
    await db
        .into(db.cavePlaces)
        .insert(
          CavePlacesCompanion.insert(
            uuid: inArea,
            title: 'Invented Pool',
            caveUuid: cave,
            caveAreaUuid: Value(area),
          ),
        );
    await d.places.addCavePlace(cave, 'Invented Junction');
    final pinned = await d.placeUuid(cave, 'Invented Junction');

    final map = Uuid.v7();
    await db
        .into(db.rasterMaps)
        .insert(
          RasterMapsCompanion.insert(
            uuid: map,
            title: 'Invented plan',
            mapType: 'plane view',
            fileName: 'invented_plan.png',
            caveUuid: cave,
          ),
        );
    final pin = Uuid.v7();
    await db
        .into(db.cavePlaceToRasterMapDefinitions)
        .insert(
          CavePlaceToRasterMapDefinitionsCompanion.insert(
            uuid: pin,
            cavePlaceUuid: pinned,
            rasterMapUuid: map,
          ),
        );

    final beacon = await d.beacons.registerBeacon(
      cavePlaceUuid: inArea,
      caveUuid: cave,
      proximityUuid: 'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0',
      major: 1,
      minor: 2,
    );

    final trip = await db.insertCaveTrip(
      caveUuid: cave,
      title: 'Invented trip',
      startedAt: DateTime.now().millisecondsSinceEpoch,
      authorUuid: d.author,
    );
    final atPlace = await db.insertTripPoint(
      tripUuid: trip,
      cavePlaceUuid: pinned,
      authorUuid: d.author,
    );
    final atPool = await db.insertTripPoint(
      tripUuid: trip,
      cavePlaceUuid: inArea,
      authorUuid: d.author,
    );
    final recording = await _doc(d, 'invented_recording');
    final photo = await _doc(d, 'invented_photo');
    final model = await _doc(d, 'invented_survey');
    await db.linkDocumentToTrip(recording, trip, authorUuid: d.author);
    final pointLink = await db.linkDocumentToTripPoint(
      photo,
      atPlace,
      authorUuid: d.author,
    );
    for (final (type, feature) in [
      (GeofeatureType.cave, cave),
      (GeofeatureType.caveArea, area),
    ]) {
      await db.insertDocumentationLink(
        documentationFileUuid: model,
        link: DocumentationGeofeatureLink(type: type, geofeatureUuid: feature),
      );
    }
    final station =
        await PlaceStationMappingRepository(
          db,
          d.currentUser,
          d.logger,
          clock: d.clock,
        ).saveMapping(
          cavePlaceUuid: pinned,
          caveUuid: cave,
          documentationFileUuid: model,
          station: 'A1',
        );

    Future<Set<Uuid>> where(String table, String sql) async => {
      for (final r
          in await db.customSelect('SELECT uuid FROM $table WHERE $sql').get())
        Uuid.fromBytes(r.read('uuid')),
    };
    final tripLinks = await where(
      'documentation_files_to_cave_trips',
      "cave_trip_uuid = x'${_hex(trip)}'",
    );
    final featureLinks = await where(
      'documentation_files_to_geofeatures',
      "geofeature_uuid IN (x'${_hex(cave)}', x'${_hex(area)}')",
    );

    return PopulatedCave._(cave, area, pinned, {
      'caves': {cave},
      'cave_areas': {area},
      'cave_places': {inArea, pinned},
      'raster_maps': {map},
      'cave_place_to_raster_map_definitions': {pin},
      'cave_place_beacons': {beacon},
      'cave_trips': {trip},
      'cave_trip_points': {atPlace, atPool},
      'documentation_files_to_cave_trips': tripLinks,
      'documentation_files_to_cave_trip_points': {pointLink},
      'documentation_files_to_geofeatures': featureLinks,
      'cave_place_model_stations': {station.uuid},
    });
  }

  static Future<Uuid> _doc(SyncTestDevice d, String title) =>
      d.db.insertDocumentationFile(
        companion: DocumentationFilesCompanion.insert(
          uuid: Uuid.v7(),
          title: title,
          fileName: '$title.txt',
          fileSize: 1,
          fileType: 'text_document',
        ),
      );

  static String _hex(Uuid id) =>
      id.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
