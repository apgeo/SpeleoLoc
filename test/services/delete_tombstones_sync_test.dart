import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/cave_trip_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/documentation_repository.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/user_repository.dart';

/// One simulated device: in-memory DB + the repository/sync stack over it.
class _Device {
  _Device(
    this.db,
    this.currentUser,
    this.caveRepo,
    this.placeRepo,
    this.tripRepo,
    this.docRepo,
    this.sync,
  );

  final AppDatabase db;
  final CurrentUserService currentUser;
  final CaveRepository caveRepo;
  final CavePlaceRepository placeRepo;
  final CaveTripRepository tripRepo;
  final DocumentationRepository docRepo;
  final SyncArchiveService sync;

  Uuid get author => currentUser.currentUserUuid.value!;
}

Future<_Device> _buildDevice() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  late ChangeLogger loggerRef;
  final userRepo = UserRepository(db, () => loggerRef);
  final currentUser = CurrentUserService(
    db,
    userRepo,
    ConfigurationRepository(db),
  );
  await currentUser.initialize();
  final logger = loggerRef = ChangeLogger(db, currentUser);
  final assetsDir = await Directory.systemTemp.createTemp('tombstone_assets_');
  return _Device(
    db,
    currentUser,
    CaveRepository(db, currentUser, logger),
    CavePlaceRepository(db, currentUser, logger),
    CaveTripRepository(db, logger),
    DocumentationRepository(db, logger),
    SyncArchiveService(
      db,
      logger,
      assetsBaseDirResolver: () async => assetsDir,
    ),
  );
}

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
      final d = await _buildDevice();
      addTearDown(d.db.close);

      final caveUuid = await d.caveRepo.addCave('Cave');
      await d.placeRepo.addCavePlace(caveUuid, 'P1');
      final placeUuid = (await d.placeRepo.findCavePlaceByTitle(
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

      await d.tripRepo.deleteCaveTrip(tripUuid);

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
    final d = await _buildDevice();
    addTearDown(d.db.close);

    final uuid = await d.tripRepo.insertTripReportTemplate(
      title: 'Template',
      fileName: 't.odt',
      fileSize: 10,
      format: 'odt',
    );
    await d.tripRepo.deleteTripReportTemplate(uuid);

    final tombstones = await _tombstones(d.db);
    expect(tombstones, hasLength(1));
    expect(tombstones.single.entityUuid, uuid);
    expect(tombstones.single.entityTable, 'trip_report_templates');
  });

  test(
    'documentation file delete writes tombstones for file and links',
    () async {
      final d = await _buildDevice();
      addTearDown(d.db.close);

      final caveUuid = await d.caveRepo.addCave('Cave');
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

      await d.docRepo.deleteDocumentationFile(docUuid);

      final tombstones = await _tombstones(d.db);
      final byUuid = {for (final t in tombstones) t.entityUuid: t.entityTable};
      expect(byUuid[docUuid], 'documentation_files');
      expect(byUuid[geoLink.uuid], 'documentation_files_to_geofeatures');
    },
  );

  test(
    'deleted trip does not resurrect on a peer after sync round-trip',
    () async {
      final a = await _buildDevice();
      final b = await _buildDevice();
      addTearDown(a.db.close);
      addTearDown(b.db.close);

      // Device A records a trip with one scanned point.
      final caveUuid = await a.caveRepo.addCave('Shared Cave');
      await a.placeRepo.addCavePlace(caveUuid, 'P1');
      final placeUuid = (await a.placeRepo.findCavePlaceByTitle(
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
      await a.tripRepo.deleteCaveTrip(tripUuid);
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
}
