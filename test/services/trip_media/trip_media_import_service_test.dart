import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/services/trip_log_update.dart';
import 'package:speleoloc/services/trip_media/trip_media_import_service.dart';
import 'package:speleoloc/services/trip_media/trip_media_item.dart';
import 'package:speleoloc/utils/localization.dart';

/// End-to-end tests for turning decided media into trip points, stored
/// documents and the links between them.
///
/// Every write has to leave a change_log entry — the FTP upload gate reads
/// nothing else, so an unlogged write is a trip that never leaves the
/// device — and each picture has to end up reachable from both its cave
/// place and the individual track point it produced, which is the whole
/// reason the point link table exists.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;
  late CaveTripService tripService;
  late TripMediaImportService service;
  late Directory storageDir;
  late Directory sourceDir;

  late Uuid caveUuid;
  late Uuid entranceUuid;
  late Uuid chamberUuid;
  late Uuid sumpUuid;

  setUpAll(() async {
    await LocServ.inst.setLocale('en');
    await LocServ.inst.load();
  });

  setUp(() async {
    // One stable documents directory for the whole test: the importer copies
    // files in and then reads them back, so a fresh temp dir per call would
    // lose them.
    storageDir = await Directory.systemTemp.createTemp('speleoloc_media_docs_');
    sourceDir = await Directory.systemTemp.createTemp('speleoloc_media_src_');
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (call) async {
          switch (call.method) {
            case 'getApplicationDocumentsDirectory':
            case 'getApplicationSupportDirectory':
            case 'getTemporaryDirectory':
              return storageDir.path;
          }
          return null;
        });

    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    // CaveTripService reaches currentUserService and the configuration
    // repository through the legacy rootContainer, so register it like
    // main() does.
    initRootContainer(container);

    caveUuid = await container.read(caveRepositoryProvider).addCave('Cave');
    final placeRepo = container.read(cavePlaceRepositoryProvider);
    await placeRepo.addCavePlace(caveUuid, 'Entrance');
    await placeRepo.addCavePlace(caveUuid, 'Chamber');
    await placeRepo.addCavePlace(caveUuid, 'Sump');
    entranceUuid = (await placeRepo.findCavePlaceByTitle(
      caveUuid,
      'Entrance',
    ))!.uuid;
    chamberUuid = (await placeRepo.findCavePlaceByTitle(
      caveUuid,
      'Chamber',
    ))!.uuid;
    sumpUuid = (await placeRepo.findCavePlaceByTitle(caveUuid, 'Sump'))!.uuid;

    tripService = container.read(caveTripServiceProvider);
    service = container.read(tripMediaImportServiceProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    for (final dir in [storageDir, sourceDir]) {
      if (await dir.exists()) await dir.delete(recursive: true);
    }
  });

  Future<int> count(String table, int changeType) async =>
      (await db.select(db.changeLog).get())
          .where((r) => r.entityTable == table && r.changeType == changeType)
          .length;

  /// A tiny distinct JPEG — invented pixels, so each file has its own hash.
  Future<File> jpeg(String name, int seed) async {
    final image = img.Image(width: 4, height: 4);
    image.setPixelRgb(0, 0, seed % 256, (seed * 7) % 256, (seed * 13) % 256);
    final file = File('${sourceDir.path}/$name');
    await file.writeAsBytes(img.encodeJpg(image));
    return file;
  }

  TripMediaCommit commit({
    required String id,
    required Uuid place,
    required DateTime at,
    File? file,
  }) => TripMediaCommit(
    item: TripMediaItem(
      id: id,
      kind: TripMediaKind.photo,
      capturedAt: at,
      capturedAtSource: MediaTimeSource.library,
    ),
    cavePlaceUuid: place,
    at: at,
    file: file,
  );

  Future<Uuid> endedTrip() async {
    final uuid = await tripService.startTrip(caveUuid, 'Trip');
    await tripService.stopTrip();
    return uuid;
  }

  test('adds a point per commit at the picture time', () async {
    final tripUuid = await endedTrip();
    final first = DateTime(2026, 10, 13, 10, 30);
    final second = DateTime(2026, 10, 13, 11, 45);

    final outcome = await service.apply(
      tripUuid: tripUuid,
      commits: [
        commit(id: 'a', place: chamberUuid, at: first),
        commit(id: 'b', place: sumpUuid, at: second),
      ],
      importFiles: false,
      compressImages: false,
    );

    expect(outcome.pointsAdded, 2);
    final points = await db.getTripPoints(tripUuid);
    expect(points, hasLength(2));
    expect(points.map((p) => p.scannedAt), [
      first.millisecondsSinceEpoch,
      second.millisecondsSinceEpoch,
    ], reason: 'points come back in capture order');
    expect(await count('cave_trip_points', ChangeType.insert), 2);
  });

  test('reports progress once per commit', () async {
    final tripUuid = await endedTrip();
    final seen = <int>[];
    await service.apply(
      tripUuid: tripUuid,
      commits: [
        commit(id: 'a', place: chamberUuid, at: DateTime(2026, 10, 13, 10)),
        commit(id: 'b', place: sumpUuid, at: DateTime(2026, 10, 13, 11)),
      ],
      importFiles: false,
      compressImages: false,
      onProgress: (done, total) {
        expect(total, 2);
        seen.add(done);
      },
    );
    expect(seen, [1, 2]);
  });

  test('a point the trip already holds is counted, not failed', () async {
    final tripUuid = await endedTrip();
    final at = DateTime(2026, 10, 13, 10, 30);
    await tripService.addPointAt(
      tripUuid: tripUuid,
      cavePlaceUuid: chamberUuid,
      at: at,
    );

    final outcome = await service.apply(
      tripUuid: tripUuid,
      commits: [commit(id: 'a', place: chamberUuid, at: at)],
      importFiles: false,
      compressImages: false,
    );

    expect(outcome.pointsAdded, 0);
    expect(outcome.pointsDuplicate, 1);
    expect(outcome.pointsFailed, 0);
    expect(await db.getTripPoints(tripUuid), hasLength(1));
  });

  group('with the store-pictures switch on', () {
    test('binds each picture to its place and its track point', () async {
      final tripUuid = await endedTrip();
      final a = await jpeg('chamber.jpg', 1);
      final b = await jpeg('sump.jpg', 2);

      final outcome = await service.apply(
        tripUuid: tripUuid,
        commits: [
          commit(
            id: 'a',
            place: chamberUuid,
            at: DateTime(2026, 10, 13, 10, 30),
            file: a,
          ),
          commit(
            id: 'b',
            place: sumpUuid,
            at: DateTime(2026, 10, 13, 11, 45),
            file: b,
          ),
        ],
        importFiles: true,
        compressImages: false,
      );

      expect(outcome.filesImported, 2);
      expect(outcome.filesFailed, 0);

      // Reachable from the cave place...
      final geoLinks = await db
          .select(db.documentationFilesToGeofeatures)
          .get();
      expect(geoLinks, hasLength(2));
      expect(geoLinks.map((l) => l.geofeatureUuid).toSet(), {
        chamberUuid,
        sumpUuid,
      });
      // ...and from the individual track point.
      final points = await db.getTripPoints(tripUuid);
      for (final point in points) {
        expect(
          await db.getTripPointDocumentLinks(point.uuid),
          hasLength(1),
          reason: 'each point carries the picture that produced it',
        );
      }
      expect(
        await count(
          'documentation_files_to_cave_trip_points',
          ChangeType.insert,
        ),
        2,
      );
      expect(await count('documentation_files', ChangeType.insert), 2);
    });

    test('a picture already stored for the place still binds to the new '
        'point instead of being dropped', () async {
      final tripUuid = await endedTrip();
      final photo = await jpeg('again.jpg', 3);

      await service.apply(
        tripUuid: tripUuid,
        commits: [
          commit(
            id: 'a',
            place: chamberUuid,
            at: DateTime(2026, 10, 13, 10, 0),
            file: photo,
          ),
        ],
        importFiles: true,
        compressImages: false,
      );
      // The same picture, a second visit to the same chamber.
      final outcome = await service.apply(
        tripUuid: tripUuid,
        commits: [
          commit(
            id: 'b',
            place: chamberUuid,
            at: DateTime(2026, 10, 13, 14, 0),
            file: photo,
          ),
        ],
        importFiles: true,
        compressImages: false,
      );

      expect(outcome.filesDuplicate, 1);
      expect(
        await db.select(db.documentationFiles).get(),
        hasLength(1),
        reason: 'the file is stored once, not twice',
      );
      final links = await db
          .select(db.documentationFilesToCaveTripPoints)
          .get();
      expect(links, hasLength(2), reason: 'but both visits point at it');
    });
  });

  test(
    'deletes superseded points before adding, and logs tombstones',
    () async {
      final tripUuid = await endedTrip();
      final at = DateTime(2026, 10, 13, 9, 5);
      final old = await tripService.addPointAt(
        tripUuid: tripUuid,
        cavePlaceUuid: entranceUuid,
        at: at,
      );

      // The replacement lands on the same place and moment as the row it
      // replaces, which only works because the delete runs first.
      final outcome = await service.apply(
        tripUuid: tripUuid,
        commits: [commit(id: 'a', place: entranceUuid, at: at)],
        importFiles: false,
        compressImages: false,
        deletePointUuids: [old],
      );

      expect(outcome.pointsDeleted, 1);
      expect(outcome.pointsAdded, 1);
      final points = await db.getTripPoints(tripUuid);
      expect(points, hasLength(1));
      expect(points.single.uuid, isNot(old));
      expect(await count('cave_trip_points', ChangeType.delete), 1);
    },
  );

  test(
    'moves the trip window when the entrance decision asked for it',
    () async {
      final tripUuid = await endedTrip();
      final newStart = DateTime(2026, 10, 13, 8, 40);
      final newEnd = DateTime(2026, 10, 13, 17, 25);

      final outcome = await service.apply(
        tripUuid: tripUuid,
        commits: [
          commit(id: 'a', place: entranceUuid, at: newStart),
          commit(id: 'b', place: entranceUuid, at: newEnd),
        ],
        importFiles: false,
        compressImages: false,
        newTripStart: newStart,
        newTripEnd: newEnd,
      );

      expect(outcome.tripWindowChanged, isTrue);
      final trip = await container
          .read(caveTripRepositoryProvider)
          .findById(tripUuid);
      expect(trip!.tripStartedAt, newStart.millisecondsSinceEpoch);
      expect(trip.tripEndedAt, newEnd.millisecondsSinceEpoch);
      expect(
        await count('cave_trips', ChangeType.update),
        greaterThanOrEqualTo(1),
      );
    },
  );

  test('refuses to end a live trip through the window update', () async {
    final tripUuid = await tripService.startTrip(caveUuid, 'Live');
    final outcome = await service.apply(
      tripUuid: tripUuid,
      commits: [
        commit(id: 'a', place: chamberUuid, at: DateTime(2026, 10, 13, 10)),
      ],
      importFiles: false,
      compressImages: false,
      newTripEnd: DateTime(2026, 10, 13, 18),
    );

    expect(outcome.tripWindowChanged, isFalse);
    expect(outcome.warnings, contains('trip_window_failed'));
    final trip = await container
        .read(caveTripRepositoryProvider)
        .findById(tripUuid);
    expect(trip!.tripEndedAt, isNull);
  });

  test('the trip log re-renders with the imported points', () async {
    final tripUuid = await endedTrip();
    await service.apply(
      tripUuid: tripUuid,
      commits: [
        commit(id: 'a', place: sumpUuid, at: DateTime(2026, 10, 13, 12, 0)),
        commit(id: 'b', place: chamberUuid, at: DateTime(2026, 10, 13, 10, 0)),
      ],
      importFiles: false,
      logUpdate: TripLogUpdate.regenerate,
      compressImages: false,
    );

    final trip = await container
        .read(caveTripRepositoryProvider)
        .findById(tripUuid);
    final log = trip!.log!;
    expect(
      log.indexOf('Chamber'),
      lessThan(log.indexOf('Sump')),
      reason: 'the log follows capture order, not the order they were added',
    );
  });
}
