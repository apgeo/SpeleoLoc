import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';

import '../support/sync_device.dart';

Future<List<ChangeLogData>> _tombstones(AppDatabase db) => (db.select(
  db.changeLog,
)..where((t) => t.changeType.equals(ChangeType.delete))).get();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tombstone_zip_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'trip delete writes tombstones for trip, points and doc links',
    () async {
      final d = await SyncTestDevice.create();
      addTearDown(d.dispose);

      final caveUuid = await d.caves.addCave('Cave');
      await d.places.addCavePlace(caveUuid, 'P1');
      final placeUuid = (await d.places.findCavePlaceByTitle(
        caveUuid,
        'P1',
      ))!.uuid;
      final tripUuid = await d.db.insertCaveTrip(
        caveUuid: caveUuid,
        title: 'Trip',
        startedAt: DateTime.now().millisecondsSinceEpoch,
        authorUuid: d.author,
      );
      final pointUuid = await d.db.insertTripPoint(
        tripUuid: tripUuid,
        cavePlaceUuid: placeUuid,
        authorUuid: d.author,
      );
      final docUuid = await d.db.insertDocumentationFile(
        companion: DocumentationFilesCompanion.insert(
          uuid: Uuid.v7(),
          title: 'Doc',
          fileName: 'doc.txt',
          fileSize: 1,
          fileType: 'text_document',
        ),
      );
      await d.db.linkDocumentToTrip(docUuid, tripUuid, authorUuid: d.author);
      final link =
          (await d.db.select(d.db.documentationFilesToCaveTrips).get()).single;

      await d.trips.deleteCaveTrip(tripUuid);

      final tombstones = await _tombstones(d.db);
      final byUuid = {for (final t in tombstones) t.entityUuid: t.entityTable};
      expect(byUuid[tripUuid], 'cave_trips');
      expect(byUuid[pointUuid], 'cave_trip_points');
      expect(byUuid[link.uuid], 'documentation_files_to_cave_trips');
      // The documentation file itself is not deleted by a trip delete.
      expect(byUuid.containsKey(docUuid), isFalse);
    },
  );

  test('trip report template delete writes a tombstone', () async {
    final d = await SyncTestDevice.create();
    addTearDown(d.dispose);

    final uuid = await d.trips.insertTripReportTemplate(
      title: 'Template',
      fileName: 't.odt',
      fileSize: 10,
      format: 'odt',
    );
    await d.trips.deleteTripReportTemplate(uuid);

    final tombstones = await _tombstones(d.db);
    expect(tombstones, hasLength(1));
    expect(tombstones.single.entityUuid, uuid);
    expect(tombstones.single.entityTable, 'trip_report_templates');
  });

  test(
    'documentation file delete writes tombstones for file and links',
    () async {
      final d = await SyncTestDevice.create();
      addTearDown(d.dispose);

      final caveUuid = await d.caves.addCave('Cave');
      final docUuid = await d.db.insertDocumentationFile(
        companion: DocumentationFilesCompanion.insert(
          uuid: Uuid.v7(),
          title: 'Doc',
          fileName: 'doc.txt',
          fileSize: 1,
          fileType: 'text_document',
        ),
        parentLink: DocumentationGeofeatureLink(
          type: GeofeatureType.cave,
          geofeatureUuid: caveUuid,
        ),
      );
      final geoLink =
          (await d.db.select(d.db.documentationFilesToGeofeatures).get())
              .single;

      await d.documents.deleteDocumentationFile(docUuid);

      final tombstones = await _tombstones(d.db);
      final byUuid = {for (final t in tombstones) t.entityUuid: t.entityTable};
      expect(byUuid[docUuid], 'documentation_files');
      expect(byUuid[geoLink.uuid], 'documentation_files_to_geofeatures');
    },
  );

  test(
    'deleted trip does not resurrect on a peer after sync round-trip',
    () async {
      final a = await SyncTestDevice.create();
      final b = await SyncTestDevice.create();
      addTearDown(a.dispose);
      addTearDown(b.dispose);

      // Device A records a trip with one scanned point.
      final caveUuid = await a.caves.addCave('Shared Cave');
      await a.places.addCavePlace(caveUuid, 'P1');
      final placeUuid = (await a.places.findCavePlaceByTitle(
        caveUuid,
        'P1',
      ))!.uuid;
      final tripUuid = await a.db.insertCaveTrip(
        caveUuid: caveUuid,
        title: 'Trip',
        startedAt: DateTime.now().millisecondsSinceEpoch,
        authorUuid: a.author,
      );
      await a.db.insertTripPoint(
        tripUuid: tripUuid,
        cavePlaceUuid: placeUuid,
        authorUuid: a.author,
      );

      // First sync: B receives the trip.
      final zip1 = await a.sync.exportToZip(
        tempDir.path,
        filenameHint: 'sync_1.zip',
        includeDocumentationFiles: false,
        includeRasterMaps: false,
      );
      await b.sync.importFromZip(zip1.path);
      expect(await b.db.select(b.db.caveTrips).get(), hasLength(1));
      expect(await b.db.select(b.db.caveTripPoints).get(), hasLength(1));

      // A deletes the trip; the tombstones must ship with the next archive
      // and remove the trip (and its points) from B instead of letting B's
      // copy survive — the pre-fix resurrection bug.
      await a.trips.deleteCaveTrip(tripUuid);
      final zip2 = await a.sync.exportToZip(
        tempDir.path,
        filenameHint: 'sync_2.zip',
        includeDocumentationFiles: false,
        includeRasterMaps: false,
      );
      final report = await b.sync.importFromZip(zip2.path);

      expect(report.deletesApplied, greaterThanOrEqualTo(2));
      expect(await b.db.select(b.db.caveTrips).get(), isEmpty);
      expect(await b.db.select(b.db.caveTripPoints).get(), isEmpty);
      // The cave and place themselves are untouched.
      expect(await b.db.select(b.db.caves).get(), hasLength(1));
      expect(await b.db.select(b.db.cavePlaces).get(), hasLength(1));
    },
  );

  test(
    'deleted beacon does not resurrect on a peer after sync round-trip',
    () async {
      final a = await SyncTestDevice.create();
      final b = await SyncTestDevice.create();
      addTearDown(a.dispose);
      addTearDown(b.dispose);

      final caveUuid = await a.caves.addCave('Beacon Cave');
      await a.places.addCavePlace(caveUuid, 'P1');
      final placeUuid = (await a.places.findCavePlaceByTitle(
        caveUuid,
        'P1',
      ))!.uuid;
      final beaconUuid = await a.beacons.registerBeacon(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        proximityUuid: '11111111-2222-3333-4444-555555555555',
        major: 1,
        minor: 2,
      );

      final zip1 = await a.sync.exportToZip(
        tempDir.path,
        filenameHint: 'b1.zip',
        includeDocumentationFiles: false,
        includeRasterMaps: false,
      );
      await b.sync.importFromZip(zip1.path);
      expect(await b.beacons.getBeaconsForCave(caveUuid), hasLength(1));

      // A unregisters the beacon (soft-delete + tombstone). deleted_at is
      // excluded from the sync diff, so the row upsert alone skips the
      // change on B; only the tombstone applied via _applyDeletes — which
      // pre-fix did not cover cave_place_beacons — removes it.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await a.beacons.unregisterBeacon(beaconUuid);
      final zip2 = await a.sync.exportToZip(
        tempDir.path,
        filenameHint: 'b2.zip',
        includeDocumentationFiles: false,
        includeRasterMaps: false,
      );
      final report = await b.sync.importFromZip(zip2.path);

      expect(report.deletesApplied, greaterThanOrEqualTo(1));
      expect(await b.beacons.getBeaconsForCave(caveUuid), isEmpty);
      // Physically removed on B, not merely soft-deleted.
      expect(await b.db.select(b.db.cavePlaceBeacons).get(), isEmpty);
    },
  );

  test('a screen watching trips hears a synced trip arrive and go', () async {
    final a = await SyncTestDevice.create();
    final b = await SyncTestDevice.create();
    addTearDown(a.dispose);
    addTearDown(b.dispose);

    final caveUuid = await a.caves.addCave('Watched Cave');
    final tripUuid = await a.db.insertCaveTrip(
      caveUuid: caveUuid,
      title: 'Trip',
      startedAt: DateTime.now().millisecondsSinceEpoch,
      authorUuid: a.author,
    );
    final added = await a.sync.exportToZip(
      tempDir.path,
      filenameHint: 'w1.zip',
      includeDocumentationFiles: false,
      includeRasterMaps: false,
    );

    var heard = 0;
    final sub = b.trips.watchTripChanges().listen((_) => heard++);
    addTearDown(sub.cancel);

    await b.sync.importFromZip(added.path);
    await pumpEventQueue();
    expect(heard, greaterThan(0), reason: 'the import inserted a trip');
    expect(await b.trips.getCaveTrips(caveUuid), hasLength(1));

    await Future<void>.delayed(const Duration(milliseconds: 5));
    await a.trips.deleteCaveTrip(tripUuid);
    final removed = await a.sync.exportToZip(
      tempDir.path,
      filenameHint: 'w2.zip',
      includeDocumentationFiles: false,
      includeRasterMaps: false,
    );
    heard = 0;

    await b.sync.importFromZip(removed.path);
    await pumpEventQueue();
    expect(await b.trips.getCaveTrips(caveUuid), isEmpty);
    expect(heard, greaterThan(0), reason: 'the tombstone deleted the trip');
  });
}
