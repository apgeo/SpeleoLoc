import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

import '../support/sync_device.dart';

/// How an archive's deletions meet this device's data: a deletion is never
/// undone by a snapshot older than it, reaches every table it names, takes
/// along what the deleting device never saw, and loses to work done after
/// it. Every outcome commits, and both devices end up with the same rows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  late SyncTestDevice a;
  late SyncTestDevice b;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('deletions_');
    a = await SyncTestDevice.create();
    b = await SyncTestDevice.create();
  });
  tearDown(() async {
    await a.dispose();
    await b.dispose();
    await tmp.delete(recursive: true);
  });

  Future<Uuid> trip(SyncTestDevice d, Uuid cave, String title) =>
      d.db.insertCaveTrip(
        caveUuid: cave,
        title: title,
        startedAt: DateTime.now().millisecondsSinceEpoch,
        authorUuid: d.author,
      );

  Future<Uuid> doc(SyncTestDevice d, String title) =>
      d.db.insertDocumentationFile(
        companion: DocumentationFilesCompanion.insert(
          uuid: Uuid.v7(),
          title: title,
          fileName: '$title.txt',
          fileSize: 1,
          fileType: 'text_document',
        ),
      );

  test('a snapshot taken before a deletion does not bring the record back, '
      'there or on the device that took it', () async {
    final cave = await a.caves.addCave('Invented Cave');
    await a.places.addCavePlace(cave, 'X');
    final x = await a.placeUuid(cave, 'X');
    await a.sendTo(b, tmp, 'a0.zip');

    // B syncs for some unrelated reason: its archive carries X alive.
    await tick();
    final b1 = await b.export(tmp, 'b1.zip');

    // A deletes X afterwards, then sees B1 for the first time.
    await tick();
    await a.places.deleteCavePlace(x);
    await tick();
    await a.sync.importFromZip(b1.path);
    expect(await a.uuidsOf('cave_places'), isEmpty);

    await tick();
    final report = await a.sendTo(b, tmp, 'a1.zip');
    expect(await b.uuidsOf('cave_places'), isEmpty);
    expect(report.deletesApplied, 1);
  });

  test('a deletion this device received from a third device is not undone '
      'by an older snapshot either', () async {
    final c = await SyncTestDevice.create();
    addTearDown(c.dispose);
    final cave = await c.caves.addCave('Invented Cave');
    await c.places.addCavePlace(cave, 'X');
    final x = await c.placeUuid(cave, 'X');
    await c.sendTo(a, tmp, 'c0.zip');
    await c.sendTo(b, tmp, 'c0b.zip');
    await tick();
    final stale = await b.export(tmp, 'b1.zip');

    await tick();
    await c.places.deleteCavePlace(x);
    await tick();
    await c.sendTo(a, tmp, 'c1.zip');
    expect(await a.uuidsOf('cave_places'), isEmpty);

    await a.sync.importFromZip(stale.path);
    expect(await a.uuidsOf('cave_places'), isEmpty);
  });

  test(
    'a trip deleted with a linked document is removed with the link',
    () async {
      final cave = await a.caves.addCave('Invented Cave');
      final t = await trip(a, cave, 'Invented trip');
      final recording = await doc(a, 'recording');
      await a.db.linkDocumentToTrip(recording, t, authorUuid: a.author);
      await a.sendTo(b, tmp, 'a0.zip');
      expect(
        await b.uuidsOf('documentation_files_to_cave_trips'),
        hasLength(1),
      );

      await tick();
      await a.trips.deleteCaveTrip(t);
      await tick();
      final report = await a.sendTo(b, tmp, 'a1.zip');

      expect(await b.uuidsOf('cave_trips'), isEmpty);
      expect(await b.uuidsOf('documentation_files_to_cave_trips'), isEmpty);
      // Each phone made its own 'system' user; matching them is expected.
      expect(
        report.warnings.where((w) => !w.startsWith('remapped user')),
        isEmpty,
      );
    },
  );

  // Link tables keep no updated_at; their deletions are compared on
  // created_at. No screen removes one link alone yet, so the deletion is
  // written here the way a repository would.
  test('a link removed on its own is removed on the peer', () async {
    final cave = await a.caves.addCave('Invented Cave');
    await a.places.addCavePlace(cave, 'P');
    final t = await trip(a, cave, 'Invented trip');
    final point = await a.db.insertTripPoint(
      tripUuid: t,
      cavePlaceUuid: await a.placeUuid(cave, 'P'),
      authorUuid: a.author,
    );
    final photo = await doc(a, 'photo');
    await a.db.linkDocumentToTripPoint(photo, point, authorUuid: a.author);
    await a.sendTo(b, tmp, 'a0.zip');
    expect(
      await b.uuidsOf('documentation_files_to_cave_trip_points'),
      hasLength(1),
    );

    await tick();
    final link = (await a.db.getTripPointDocumentLinks(point)).single;
    await a.db.transaction(() async {
      await (a.db.delete(
        a.db.documentationFilesToCaveTripPoints,
      )..where((l) => l.uuid.equalsValue(link.uuid))).go();
      await a.logger.logDelete(
        'documentation_files_to_cave_trip_points',
        link.uuid,
        oldValues: const {},
      );
    });
    await tick();
    await a.sendTo(b, tmp, 'a1.zip');

    expect(await b.uuidsOf('documentation_files_to_cave_trip_points'), isEmpty);
    expect(await b.uuidsOf('cave_trip_points'), {point});
  });

  test('a place deleted on one phone after the other recorded a visit there '
      'stays, with the visit, on both', () async {
    final cave = await a.caves.addCave('Invented Cave');
    await a.places.addCavePlace(cave, 'P');
    final p = await a.placeUuid(cave, 'P');
    await a.sendTo(b, tmp, 'a0.zip');

    await tick();
    await a.places.deleteCavePlace(p);
    await tick();
    final a1 = await a.export(tmp, 'a1.zip');

    // B, still offline, records a trip point at P after A's delete.
    await tick();
    final t = await trip(b, cave, 'Invented trip B');
    final point = await b.db.insertTripPoint(
      tripUuid: t,
      cavePlaceUuid: p,
      authorUuid: b.author,
    );
    await tick();

    final onB = await b.sync.importFromZip(a1.path);
    expect(await b.uuidsOf('cave_places'), {p});
    expect(onB.rowsSkipped, greaterThanOrEqualTo(1));
    expect(onB.warnings, contains(contains('after its deletion')));

    await b.sendTo(a, tmp, 'b1.zip');
    expect(await a.uuidsOf('cave_places'), {p});
    final arrived = await (a.db.select(
      a.db.caveTripPoints,
    )..where((x) => x.uuid.equalsValue(point))).getSingle();
    expect(arrived.cavePlaceUuid, p);
  });

  group('a place kept for a visit recorded after its deletion', () {
    late SyncTestDevice c;
    late Uuid cave;
    late Uuid p;
    late Uuid t;
    late File deletion;

    setUp(() async {
      c = await SyncTestDevice.create();
      cave = await a.caves.addCave('Invented Cave');
      await a.places.addCavePlace(cave, 'P');
      p = await a.placeUuid(cave, 'P');
      await a.sendTo(b, tmp, 'a0.zip');
      await a.sendTo(c, tmp, 'a0c.zip');

      await tick();
      await a.places.deleteCavePlace(p);
      await tick();
      deletion = await a.export(tmp, 'a1.zip');
      await c.sync.importFromZip(deletion.path);
      expect(await c.uuidsOf('cave_places'), isEmpty);

      // B, still offline, records a visit at P after A's delete.
      await tick();
      t = await trip(b, cave, 'Invented trip B');
      await b.db.insertTripPoint(
        tripUuid: t,
        cavePlaceUuid: p,
        authorUuid: b.author,
      );
      await tick();
    });
    tearDown(() => c.dispose());

    test('comes back on every phone, also once the visit is deleted', () async {
      await b.sync.importFromZip(deletion.path);
      expect(await b.uuidsOf('cave_places'), {p});

      await tick();
      await b.trips.deleteCaveTrip(t);
      await tick();
      await b.sendTo(c, tmp, 'b1.zip');
      await b.sendTo(a, tmp, 'b1a.zip');

      for (final d in [a, b, c]) {
        expect(await d.uuidsOf('cave_places'), {p});
      }
    });

    test('is passed on by the phone that deleted it, once it took it back, '
        'also after the visit is deleted', () async {
      await b.sendTo(a, tmp, 'b1.zip');
      expect(await a.uuidsOf('cave_places'), {p});

      await tick();
      await b.trips.deleteCaveTrip(t);
      await tick();
      await b.sendTo(a, tmp, 'b2.zip');
      expect(await a.uuidsOf('cave_trips'), isEmpty);
      await a.sendTo(c, tmp, 'a2.zip');

      expect(await c.uuidsOf('cave_places'), {p});
    });
  });

  test('a deleted place goes with a document link the deleting phone never '
      'saw, and the document stays', () async {
    final cave = await a.caves.addCave('Invented Cave');
    await a.places.addCavePlace(cave, 'P');
    final p = await a.placeUuid(cave, 'P');
    await a.sendTo(b, tmp, 'a0.zip');
    final photo = await doc(b, 'photo');
    await b.db
        .into(b.db.documentationFilesToGeofeatures)
        .insert(
          DocumentationFilesToGeofeaturesCompanion.insert(
            uuid: Uuid.v7(),
            geofeatureType: GeofeatureType.cavePlace.dbValue,
            documentationFileUuid: photo,
            geofeatureUuid: Value(p),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    await tick();
    await a.places.deleteCavePlace(p);
    await tick();
    await a.sendTo(b, tmp, 'a1.zip');

    expect(await b.uuidsOf('cave_places'), isEmpty);
    expect(await b.uuidsOf('documentation_files_to_geofeatures'), isEmpty);
    expect(await b.uuidsOf('documentation_files'), {photo});
  });

  // No screen writes cave entrances any more, and they do not sync; a
  // database upgraded from an older app can still hold one.
  test('a deleted cave goes with an entrance an older app left on the '
      'peer', () async {
    final cave = await a.caves.addCave('Invented Cave');
    await a.sendTo(b, tmp, 'a0.zip');
    await b.db
        .into(b.db.caveEntrances)
        .insert(
          CaveEntrancesCompanion.insert(
            uuid: Uuid.v7(),
            caveUuid: cave,
            title: const Value('Invented entrance'),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    await tick();
    await a.caves.deleteCave(cave);
    await tick();
    await a.sendTo(b, tmp, 'a1.zip');

    expect(await b.uuidsOf('caves'), isEmpty);
    expect(await b.uuidsOf('cave_entrances'), isEmpty);
  });

  test('what the deleting phone never saw goes with the record, as it would '
      'have there', () async {
    final cave = await a.caves.addCave('Invented Cave');
    await a.places.addCavePlace(cave, 'P');
    final p = await a.placeUuid(cave, 'P');
    await a.sendTo(b, tmp, 'a0.zip');

    // B pins P on a map and records a visit, and does not sync.
    final map = Uuid.v7();
    await b.db
        .into(b.db.rasterMaps)
        .insert(
          RasterMapsCompanion.insert(
            uuid: map,
            title: 'Invented map',
            mapType: 'plane view',
            fileName: 'map.png',
            caveUuid: cave,
          ),
        );
    await b.db
        .into(b.db.cavePlaceToRasterMapDefinitions)
        .insert(
          CavePlaceToRasterMapDefinitionsCompanion.insert(
            uuid: Uuid.v7(),
            cavePlaceUuid: p,
            rasterMapUuid: map,
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
    final point = await b.db.insertTripPoint(
      tripUuid: await trip(b, cave, 'Invented trip B'),
      cavePlaceUuid: p,
      authorUuid: b.author,
    );

    // A deletes P later, never having seen either.
    await tick();
    await a.places.deleteCavePlace(p);
    await tick();
    await a.sendTo(b, tmp, 'a1.zip');

    expect(await b.uuidsOf('cave_places'), isEmpty);
    expect(await b.uuidsOf('cave_place_to_raster_map_definitions'), isEmpty);
    final kept = await (b.db.select(
      b.db.caveTripPoints,
    )..where((x) => x.uuid.equalsValue(point))).getSingle();
    expect(kept.cavePlaceUuid, isNull);
  });
}
