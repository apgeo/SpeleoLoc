import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_area_title_clash_exception.dart';
import 'package:speleoloc/services/change_logger.dart';

import 'sync_test_device.dart';

/// Deleting a cave, a place or an area removes or detaches everything that
/// hangs on it, and logs each removal as a delete and each detach as an
/// edit, so a peer that imports the change log ends up without orphans.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SyncTestDevice d;

  setUp(() async => d = await SyncTestDevice.create());
  tearDown(() => d.db.close());

  Future<Set<Uuid>> tombstones(String table) async => <Uuid>{
    for (final r in await (d.db.select(
      d.db.changeLog,
    )..where((c) => c.entityTable.equals(table))).get())
      if (r.changeType == ChangeType.delete) r.entityUuid,
  };

  Future<Set<Uuid>> edits(String table) async => <Uuid>{
    for (final r in await (d.db.select(
      d.db.changeLog,
    )..where((c) => c.entityTable.equals(table))).get())
      if (r.changeType == ChangeType.update) r.entityUuid,
  };

  Future<Uuid> doc(String title) => d.db.insertDocumentationFile(
    companion: DocumentationFilesCompanion.insert(
      uuid: Uuid.v7(),
      title: title,
      fileName: '$title.txt',
      fileSize: 1,
      fileType: 'text_document',
    ),
  );

  Future<Uuid> map(Uuid cave, {Uuid? area}) async {
    final id = Uuid.v7();
    await d.db
        .into(d.db.rasterMaps)
        .insert(
          RasterMapsCompanion.insert(
            uuid: id,
            title: 'Invented map $id',
            mapType: 'plane view',
            fileName: 'map_$id.png',
            caveUuid: cave,
            caveAreaUuid: Value(area),
          ),
        );
    return id;
  }

  Future<Uuid> pin(Uuid place, Uuid map) async {
    final id = Uuid.v7();
    await d.db
        .into(d.db.cavePlaceToRasterMapDefinitions)
        .insert(
          CavePlaceToRasterMapDefinitionsCompanion.insert(
            uuid: id,
            cavePlaceUuid: place,
            rasterMapUuid: map,
          ),
        );
    return id;
  }

  Future<Uuid> geoLink(Uuid docId, GeofeatureType type, Uuid feature) async {
    await d.db.insertDocumentationLink(
      documentationFileUuid: docId,
      link: DocumentationGeofeatureLink(type: type, geofeatureUuid: feature),
    );
    return (await (d.db.select(
      d.db.documentationFilesToGeofeatures,
    )..where((g) => g.geofeatureUuid.equalsValue(feature))).getSingle()).uuid;
  }

  test('a cave whose trip has documents and media goes, with everything on '
      'it tombstoned', () async {
    final cave = await d.caves.addCave('Invented Cave');
    final other = await d.caves.addCave('Neighbour Cave');
    await d.places.addCavePlace(cave, 'Junction');
    final place = await d.placeUuid(cave, 'Junction');
    final trip = await d.db.insertCaveTrip(
      caveUuid: cave,
      title: 'Invented trip',
      startedAt: 1,
      authorUuid: d.author,
    );
    final point = await d.db.insertTripPoint(
      tripUuid: trip,
      cavePlaceUuid: place,
      authorUuid: d.author,
    );
    final recording = await doc('recording');
    final photo = await doc('photo');
    await d.db.linkDocumentToTrip(recording, trip, authorUuid: d.author);
    await d.db.linkDocumentToTripPoint(photo, point, authorUuid: d.author);
    final mapId = await map(cave);
    final pinId = await pin(place, mapId);
    final placeLink = await geoLink(photo, GeofeatureType.cavePlace, place);
    // A trip in another cave that visited this cave's place.
    final otherTrip = await d.db.insertCaveTrip(
      caveUuid: other,
      title: 'Through trip',
      startedAt: 2,
      authorUuid: d.author,
    );
    final visit = await d.db.insertTripPoint(
      tripUuid: otherTrip,
      cavePlaceUuid: place,
      authorUuid: d.author,
    );
    await tick();

    await d.caves.deleteCave(cave);

    for (final table in [
      'documentation_files_to_cave_trips',
      'documentation_files_to_cave_trip_points',
      'documentation_files_to_geofeatures',
      'cave_place_to_raster_map_definitions',
      'cave_places',
      'raster_maps',
    ]) {
      expect(await d.uuidsOf(table), isEmpty, reason: '$table keeps rows');
    }
    expect(
      await d.db.customSelect('PRAGMA foreign_key_check').get(),
      isEmpty,
      reason: 'a row still points at something that was deleted',
    );
    expect(await d.uuidsOf('cave_trips'), {otherTrip});
    expect(await d.uuidsOf('cave_trip_points'), {visit});
    expect(await tombstones('cave_trips'), contains(trip));
    expect(await tombstones('cave_trip_points'), contains(point));
    expect(await tombstones('documentation_files_to_cave_trips'), hasLength(1));
    expect(
      await tombstones('documentation_files_to_cave_trip_points'),
      hasLength(1),
    );
    expect(await tombstones('cave_place_to_raster_map_definitions'), {pinId});
    expect(await tombstones('documentation_files_to_geofeatures'), {placeLink});

    final detached = await (d.db.select(
      d.db.caveTripPoints,
    )..where((p) => p.uuid.equalsValue(visit))).getSingle();
    expect(detached.cavePlaceUuid, isNull);
    expect(detached.updatedAt, greaterThan(detached.createdAt!));
    expect(await edits('cave_trip_points'), {visit});
  });

  test('a place goes with its pins and links tombstoned and its visits '
      'detached as edits', () async {
    final cave = await d.caves.addCave('Invented Cave');
    await d.places.addCavePlace(cave, 'Junction');
    final place = await d.placeUuid(cave, 'Junction');
    final pinId = await pin(place, await map(cave));
    final link = await geoLink(
      await doc('sketch'),
      GeofeatureType.cavePlace,
      place,
    );
    final trip = await d.db.insertCaveTrip(
      caveUuid: cave,
      title: 'Invented trip',
      startedAt: 1,
      authorUuid: d.author,
    );
    final point = await d.db.insertTripPoint(
      tripUuid: trip,
      cavePlaceUuid: place,
      authorUuid: d.author,
    );
    await tick();

    await d.places.deleteCavePlace(place);

    expect(await d.uuidsOf('cave_place_to_raster_map_definitions'), isEmpty);
    expect(await d.uuidsOf('documentation_files_to_geofeatures'), isEmpty);
    expect(await tombstones('cave_place_to_raster_map_definitions'), {pinId});
    expect(await tombstones('documentation_files_to_geofeatures'), {link});
    final kept = await (d.db.select(
      d.db.caveTripPoints,
    )..where((p) => p.uuid.equalsValue(point))).getSingle();
    expect(kept.cavePlaceUuid, isNull);
    expect(kept.updatedAt, greaterThan(kept.createdAt!));
    expect(await edits('cave_trip_points'), {point});
  });

  test('an area in use goes; its places and maps stay in the cave, outside '
      'any area, as logged edits', () async {
    final cave = await d.caves.addCave('Invented Cave');
    final area = await d.caves.addCaveArea(cave, 'Hall');
    final placeId = Uuid.v7();
    await d.db
        .into(d.db.cavePlaces)
        .insert(
          CavePlacesCompanion.insert(
            uuid: placeId,
            title: 'Pillar',
            caveUuid: cave,
            caveAreaUuid: Value(area),
          ),
        );
    final mapId = await map(cave, area: area);
    final link = await geoLink(
      await doc('area photo'),
      GeofeatureType.caveArea,
      area,
    );
    final row = (await d.caves.findCaveAreaById(area))!;

    await d.caves.deleteCaveArea(row);

    expect(await d.caves.findCaveAreaById(area), isNull);
    final place = await (d.db.select(
      d.db.cavePlaces,
    )..where((p) => p.uuid.equalsValue(placeId))).getSingle();
    expect(place.caveAreaUuid, isNull);
    final mapRow = await (d.db.select(
      d.db.rasterMaps,
    )..where((m) => m.uuid.equalsValue(mapId))).getSingle();
    expect(mapRow.caveAreaUuid, isNull);
    expect(await edits('cave_places'), {placeId});
    expect(await edits('raster_maps'), {mapId});
    expect(await tombstones('documentation_files_to_geofeatures'), {link});
    expect(await tombstones('cave_areas'), {area});
  });

  test('an area whose place would clash with one outside any area is kept, '
      'unchanged', () async {
    final cave = await d.caves.addCave('Invented Cave');
    final area = await d.caves.addCaveArea(cave, 'Hall');
    await d.db
        .into(d.db.cavePlaces)
        .insert(
          CavePlacesCompanion.insert(
            uuid: Uuid.v7(),
            title: 'Siphon',
            caveUuid: cave,
            caveAreaUuid: Value(area),
          ),
        );
    await d.places.addCavePlace(cave, 'Siphon');
    final row = (await d.caves.findCaveAreaById(area))!;

    await expectLater(
      d.caves.deleteCaveArea(row),
      throwsA(
        isA<CaveAreaTitleClashException>().having(
          (e) => e.placeTitle,
          'placeTitle',
          'Siphon',
        ),
      ),
    );
    expect(await d.caves.findCaveAreaById(area), isNotNull);
    expect(await edits('cave_places'), isEmpty);
  });

  test('a surface area in use goes; its caves stay, outside any', () async {
    final surface = await d.caves.addSurfaceArea(title: 'Invented Karst');
    final cave = await d.caves.addCave(
      'Invented Cave',
      surfaceAreaUuid: surface,
    );
    final row = (await d.caves.getSurfaceAreas()).single;

    await d.caves.deleteSurfaceArea(row);

    expect(await d.caves.getSurfaceAreas(), isEmpty);
    expect((await d.caves.findById(cave))!.surfaceAreaUuid, isNull);
    expect(await edits('caves'), {cave});
  });

  group('a peer imports the deletion without orphans', () {
    late Directory tmp;
    setUp(() async => tmp = await Directory.systemTemp.createTemp('cascade_'));
    tearDown(() async => tmp.delete(recursive: true));

    test('a place pinned on a map and visited on a trip', () async {
      final b = await SyncTestDevice.create();
      addTearDown(b.db.close);
      final cave = await d.caves.addCave('Invented Cave');
      await d.places.addCavePlace(cave, 'Junction');
      final place = await d.placeUuid(cave, 'Junction');
      await pin(place, await map(cave));
      final trip = await d.db.insertCaveTrip(
        caveUuid: cave,
        title: 'Invented trip',
        startedAt: 1,
        authorUuid: d.author,
      );
      final point = await d.db.insertTripPoint(
        tripUuid: trip,
        cavePlaceUuid: place,
        authorUuid: d.author,
      );
      await d.sendTo(b, tmp, 'a0.zip');
      await tick();

      await d.places.deleteCavePlace(place);
      await tick();
      await d.sendTo(b, tmp, 'a1.zip');

      expect(await b.uuidsOf('cave_places'), isEmpty);
      expect(await b.uuidsOf('cave_place_to_raster_map_definitions'), isEmpty);
      final kept = await (b.db.select(
        b.db.caveTripPoints,
      )..where((p) => p.uuid.equalsValue(point))).getSingle();
      expect(kept.cavePlaceUuid, isNull);
    });
  });
}
