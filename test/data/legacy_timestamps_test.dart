import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/data/source/database/legacy_timestamps.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/user_repository.dart';

void main() {
  const seconds = 1600000000; // 2020-09-13, as older data stored it
  const millis = 1600000000000;

  late Directory tempDir;
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('legacy_ts_test_');
  });
  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('timestampToMillis converts only values that must be seconds', () {
    expect(timestampToMillis(seconds), millis);
    expect(timestampToMillis(millis), millis);
    expect(timestampToMillis(0), 0);
    expect(timestampToMillis(null), isNull);
  });

  test('opening a database converts seconds and leaves the rest', () async {
    final file = File(p.join(tempDir.path, 'db.sqlite'));
    var db = AppDatabase.forTesting(NativeDatabase(file));
    final secondsCave = Uuid.v7();
    final millisCave = Uuid.v7();
    await db
        .into(db.caves)
        .insert(
          CavesCompanion.insert(
            uuid: secondsCave,
            title: 'Old',
            createdAt: const Value(seconds),
          ),
        );
    await db
        .into(db.caves)
        .insert(
          CavesCompanion.insert(
            uuid: millisCave,
            title: 'New',
            createdAt: const Value(millis),
            updatedAt: const Value(millis + 5),
          ),
        );
    await db.close();

    db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    final byUuid = {for (final c in await db.select(db.caves).get()) c.uuid: c};

    expect(byUuid[secondsCave]!.createdAt, millis);
    expect(byUuid[secondsCave]!.updatedAt, isNull);
    expect(byUuid[millisCave]!.createdAt, millis);
    expect(byUuid[millisCave]!.updatedAt, millis + 5);

    // Idempotent: a second pass changes nothing.
    await normalizeLegacyTimestamps(db);
    final again = await db.select(db.caves).get();
    expect(again.map((c) => c.createdAt), everyElement(millis));
  });

  test('a synced row in seconds is stored in milliseconds', () async {
    Future<(AppDatabase, CaveRepository, SyncArchiveService)> device() async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      late ChangeLogger logger;
      final currentUser = CurrentUserService(
        db,
        UserRepository(db, () => logger),
        ConfigurationRepository(db),
      );
      await currentUser.initialize();
      logger = ChangeLogger(db, currentUser);
      return (
        db,
        CaveRepository(db, currentUser, logger),
        SyncArchiveService(
          db,
          logger,
          assetsBaseDirResolver: () async => tempDir,
        ),
      );
    }

    final (peerDb, peerCaves, peerSync) = await device();
    addTearDown(peerDb.close);
    final cave = await peerCaves.addCave('From an older app');
    // The peer runs an app that still writes seconds.
    await peerDb.customStatement(
      'UPDATE caves SET created_at = ?, updated_at = NULL WHERE uuid = ?',
      [seconds, cave.bytes],
    );
    final zip = await peerSync.exportToZip(tempDir.path, filenameHint: 'p.zip');

    final (db, caves, sync) = await device();
    addTearDown(db.close);
    await sync.importFromZip(zip.path);

    final row = (await caves.getCaves()).single;
    expect(row.uuid, cave);
    expect(row.createdAt, millis);
  });
}
