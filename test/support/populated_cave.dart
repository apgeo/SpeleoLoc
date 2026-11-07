import 'package:drift/drift.dart' show Value;
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_model/cave_default_model_repository.dart';
import 'package:speleoloc/services/cave_model/place_station_mapping_repository.dart';

import 'sync_device.dart';

/// A cave holding one of each kind of record that can hang on a cave, all
/// invented: it lies in a surface area, and has an area with a place in it,
/// a place outside it pinned on a map, a beacon, a trip with a point at
/// each place and a document on the trip and on one point, documents linked
/// to the cave and to the area, a default survey model and a station of it
/// mapped to a place.
///
/// [rows] lists, table by table, what deleting the cave removes. The surface
/// area and the three documents outlive the cave, as they do in the app.
class PopulatedCave {
  PopulatedCave._({
    required this.cave,
    required this.surfaceArea,
    required this.area,
    required this.pinnedPlace,
    required this.map,
    required this.trip,
    required this.visit,
    required this.recording,
    required this.model,
    required this.rows,
  });

  final Uuid cave;
  final Uuid surfaceArea;
  final Uuid area;

  /// The place outside the area, pinned on [map] and visited by [trip].
  final Uuid pinnedPlace;
  final Uuid map;
  final Uuid trip;

  /// The trip's point at [pinnedPlace], with a photo linked to it.
  final Uuid visit;

  /// A document linked to [trip].
  final Uuid recording;

  /// The cave's survey model: linked to the cave and to the area, its
  /// default model, with a station mapped to [pinnedPlace].
  final Uuid model;

  final Map<String, Set<Uuid>> rows;

  static Future<PopulatedCave> build(
    SyncTestDevice d, {
    String title = 'Invented Cave',
  }) async {
    final db = d.db;
    final surfaceArea = await d.caves.addSurfaceArea(title: '$title Karst');
    final cave = await d.caves.addCave(title, surfaceAreaUuid: surfaceArea);
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
    await CaveDefaultModelRepository(
      db,
      d.currentUser,
      d.logger,
      clock: d.clock,
    ).setDefaultModel(cave, model);

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
    final defaultModel = await where(
      'cave_default_survey_models',
      "cave_uuid = x'${_hex(cave)}'",
    );

    return PopulatedCave._(
      cave: cave,
      surfaceArea: surfaceArea,
      area: area,
      pinnedPlace: pinned,
      map: map,
      trip: trip,
      visit: atPlace,
      recording: recording,
      model: model,
      rows: {
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
        'cave_default_survey_models': defaultModel,
      },
    );
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
