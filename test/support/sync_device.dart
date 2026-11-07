import 'dart:io';

import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/beacon/beacon_repository.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/cave_trip_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/documentation_repository.dart';
import 'package:speleoloc/services/sync/archive_held_row_repository.dart';
import 'package:speleoloc/services/sync/archive_sync_decisions_service.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/sync/sync_merge_engine.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/utils/clock.dart';

/// One phone in a device-to-device sync test: its own in-memory database,
/// its own `system` user and device identity, the repositories that write
/// through the change log, the archive service and the decisions a merge
/// leaves. Every row a test puts in is invented.
///
/// The [clock] reaches every service here that takes one. The user,
/// configuration and trip writes, and the database's own insert helpers,
/// still read the wall clock, so a test that mixes them with a fake clock
/// must keep the fake one close to real time.
class SyncTestDevice {
  SyncTestDevice._(
    this.db,
    this.clock,
    this.currentUser,
    this.logger,
    this.caves,
    this.places,
    this.trips,
    this.documents,
    this.beacons,
    this.sync,
    this.held,
    this.decisions,
    this.assetsDir,
  );

  final AppDatabase db;
  final Clock clock;
  final CurrentUserService currentUser;
  final ChangeLogger logger;
  final CaveRepository caves;
  final CavePlaceRepository places;
  final CaveTripRepository trips;
  final DocumentationRepository documents;
  final BeaconRepository beacons;
  final SyncArchiveService sync;
  final ArchiveHeldRowRepository held;
  final ArchiveSyncDecisionsService decisions;

  /// The folder this phone's archive service reads and writes asset files
  /// in, standing in for the app documents directory.
  final Directory assetsDir;

  Uuid get author => currentUser.currentUserUuid.value!;

  static Future<SyncTestDevice> create({
    QueryExecutor? executor,
    Clock clock = const SystemClock(),
  }) async {
    final db = AppDatabase.forTesting(executor ?? NativeDatabase.memory());
    late ChangeLogger loggerRef;
    final userRepo = UserRepository(db, () => loggerRef);
    final currentUser = CurrentUserService(
      db,
      userRepo,
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    final logger = loggerRef = ChangeLogger(db, currentUser, clock: clock);
    // Each phone has its own 'system' user, as on first run.
    await currentUser.currentOrSystem();
    final assetsDir = await Directory.systemTemp.createTemp('sync_assets_');
    final held = ArchiveHeldRowRepository(db, clock: clock);
    return SyncTestDevice._(
      db,
      clock,
      currentUser,
      logger,
      CaveRepository(db, currentUser, logger, clock: clock),
      CavePlaceRepository(db, currentUser, logger, clock: clock),
      CaveTripRepository(db, logger),
      DocumentationRepository(db, logger, currentUser),
      BeaconRepository(db, currentUser, logger, clock: clock),
      SyncArchiveService(
        db,
        logger,
        assetsBaseDirResolver: () async => assetsDir,
        clock: clock,
      ),
      held,
      ArchiveSyncDecisionsService(
        db: db,
        logger: logger,
        currentUser: currentUser,
        engine: SyncMergeEngine(db, logger, heldRows: held),
        heldRows: held,
        clock: clock,
      ),
      assetsDir,
    );
  }

  /// Closes the database and removes the assets folder.
  Future<void> dispose() async {
    await db.close();
    if (await assetsDir.exists()) await assetsDir.delete(recursive: true);
  }

  Future<File> export(Directory dir, String name) => sync.exportToZip(
    dir.path,
    filenameHint: name,
    includeDocumentationFiles: false,
    includeRasterMaps: false,
  );

  /// Exports this device and imports the archive on [other].
  Future<SyncImportReport> sendTo(
    SyncTestDevice other,
    Directory dir,
    String name,
  ) async => other.sync.importFromZip((await export(dir, name)).path);

  Future<Uuid> placeUuid(Uuid cave, String title) async =>
      (await places.findCavePlaceByTitle(cave, title))!.uuid;

  Future<Set<Uuid>> uuidsOf(String table) async => <Uuid>{
    for (final row in await db.customSelect('SELECT uuid FROM $table').get())
      Uuid.fromBytes(row.read('uuid')),
  };
}

/// Lets the millisecond clock move on, so successive steps get distinct
/// timestamps.
Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 5));
