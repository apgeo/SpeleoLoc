import 'dart:io';

import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/cave_trip_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/sync/archive_held_row_repository.dart';
import 'package:speleoloc/services/sync/archive_sync_decisions_service.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/sync/sync_merge_engine.dart';
import 'package:speleoloc/services/user_repository.dart';

/// One phone in a device-to-device sync test: its own in-memory database,
/// its own `system` user and device identity, the repositories that write
/// through the change log, the archive service and the decisions a merge
/// leaves. Every row a test puts in is invented.
class SyncTestDevice {
  SyncTestDevice._(
    this.db,
    this.currentUser,
    this.logger,
    this.caves,
    this.places,
    this.trips,
    this.sync,
    this.held,
    this.decisions,
    this.assetsDir,
  );

  final AppDatabase db;
  final CurrentUserService currentUser;
  final ChangeLogger logger;
  final CaveRepository caves;
  final CavePlaceRepository places;
  final CaveTripRepository trips;
  final SyncArchiveService sync;
  final ArchiveHeldRowRepository held;
  final ArchiveSyncDecisionsService decisions;

  /// The folder this phone's archive service reads and writes asset files
  /// in, standing in for the app documents directory.
  final Directory assetsDir;

  Uuid get author => currentUser.currentUserUuid.value!;

  static Future<SyncTestDevice> create({QueryExecutor? executor}) async {
    final db = AppDatabase.forTesting(executor ?? NativeDatabase.memory());
    late ChangeLogger loggerRef;
    final userRepo = UserRepository(db, () => loggerRef);
    final currentUser = CurrentUserService(
      db,
      userRepo,
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    final logger = loggerRef = ChangeLogger(db, currentUser);
    // Each phone has its own 'system' user, as on first run.
    await currentUser.currentOrSystem();
    final assetsDir = await Directory.systemTemp.createTemp('sync_assets_');
    final held = ArchiveHeldRowRepository(db);
    return SyncTestDevice._(
      db,
      currentUser,
      logger,
      CaveRepository(db, currentUser, logger),
      CavePlaceRepository(db, currentUser, logger),
      CaveTripRepository(db, logger),
      SyncArchiveService(
        db,
        logger,
        assetsBaseDirResolver: () async => assetsDir,
      ),
      held,
      ArchiveSyncDecisionsService(
        db: db,
        logger: logger,
        currentUser: currentUser,
        engine: SyncMergeEngine(db, logger, heldRows: held),
        heldRows: held,
      ),
      assetsDir,
    );
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
