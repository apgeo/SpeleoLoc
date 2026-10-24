import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;

/// Merging the database inside a full data export: the "Import (merge)"
/// path, which shares the sync archive's last-writer-wins merge.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('speleoloc_dbfile_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<_Harness> buildHarness(AppDatabase db) async {
    late ChangeLogger loggerRef;
    final userRepo = UserRepository(db, () => loggerRef);
    final currentUser = CurrentUserService(
      db,
      userRepo,
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    loggerRef = ChangeLogger(db, currentUser);
    final caveRepo = CaveRepository(db, currentUser, loggerRef);
    final sync = SyncArchiveService(
      db,
      loggerRef,
      assetsBaseDirResolver: () async => tempDir,
    );
    return _Harness(db, caveRepo, sync);
  }

  /// A device whose database lives in a file, as an exported one does.
  Future<(_Harness, File)> buildFileHarness() async {
    final file = File(p.join(tempDir.path, 'speleo_loc.sqlite'));
    final h = await buildHarness(AppDatabase.forTesting(NativeDatabase(file)));
    return (h, file);
  }

  test('merges into a database that already holds its own data', () async {
    final (source, file) = await buildFileHarness();
    final sourceCave = await source.caveRepo.addCave('From the export');
    await source.db.close();

    final local = await buildHarness(
      AppDatabase.forTesting(NativeDatabase.memory()),
    );
    addTearDown(local.db.close);
    final localCave = await local.caveRepo.addCave('Already here');

    final report = await local.sync.importFromDatabaseFile(file);

    expect(report.rowsInserted, greaterThan(0));
    final caves = {
      for (final c in await local.caveRepo.getCaves()) c.uuid: c.title,
    };
    expect(caves[sourceCave], 'From the export');
    expect(caves[localCave], 'Already here');
  });

  test(
    'merging the same export twice changes nothing the second time',
    () async {
      final (source, file) = await buildFileHarness();
      await source.caveRepo.addCave('Once');
      await source.db.close();

      final local = await buildHarness(
        AppDatabase.forTesting(NativeDatabase.memory()),
      );
      addTearDown(local.db.close);

      await local.sync.importFromDatabaseFile(file);
      final again = await local.sync.importFromDatabaseFile(file);

      expect(again.rowsInserted, 0);
      expect(again.rowsUpdated, 0);
      expect(await local.caveRepo.getCaves(), hasLength(1));
    },
  );

  test('keeps a row the export still holds despite an old delete', () async {
    final (source, file) = await buildFileHarness();
    final cave = await source.caveRepo.addCave('Restored');
    final row = (await source.caveRepo.getCaves()).single;
    await source.caveRepo.deleteCave(cave);
    // Put back with the same uuid and a creation time in seconds, the way
    // older data carries it, so every timestamp says the delete is newer.
    await source.db
        .into(source.db.caves)
        .insert(
          row.copyWith(
            createdAt: Value(row.createdAt! ~/ 1000),
            updatedAt: const Value(null),
          ),
        );
    await source.db.close();

    final local = await buildHarness(
      AppDatabase.forTesting(NativeDatabase.memory()),
    );
    addTearDown(local.db.close);

    final report = await local.sync.importFromDatabaseFile(file);

    expect(report.deletesApplied, 0);
    expect((await local.caveRepo.getCaves()).map((c) => c.uuid), [cave]);
  });

  test('carries deletes recorded in the export', () async {
    final (source, file) = await buildFileHarness();
    final gone = await source.caveRepo.addCave('Deleted later');
    await source.caveRepo.addCave('Kept');
    final firstCopy = File(p.join(tempDir.path, 'first.sqlite'));
    await source.db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    await file.copy(firstCopy.path);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await source.caveRepo.deleteCave(gone);
    await source.db.close();

    final local = await buildHarness(
      AppDatabase.forTesting(NativeDatabase.memory()),
    );
    addTearDown(local.db.close);
    await local.sync.importFromDatabaseFile(firstCopy);
    expect(await local.caveRepo.getCaves(), hasLength(2));

    final report = await local.sync.importFromDatabaseFile(file);

    expect(report.deletesApplied, 1);
    final titles = (await local.caveRepo.getCaves()).map((c) => c.title);
    expect(titles, ['Kept']);
  });

  test('refuses an export made by a newer app', () async {
    final (source, file) = await buildFileHarness();
    await source.caveRepo.addCave('Future');
    await source.db.close();
    final raw = sqlite3.open(file.path);
    raw.userVersion = 999;
    raw.close();

    final local = await buildHarness(
      AppDatabase.forTesting(NativeDatabase.memory()),
    );
    addTearDown(local.db.close);

    await expectLater(
      local.sync.importFromDatabaseFile(file),
      throwsA(
        isA<SyncArchiveSchemaMismatchException>().having(
          (e) => e.tooNew,
          'tooNew',
          isTrue,
        ),
      ),
    );
    expect(await local.caveRepo.getCaves(), isEmpty);
  });
}

class _Harness {
  _Harness(this.db, this.caveRepo, this.sync);
  final AppDatabase db;
  final CaveRepository caveRepo;
  final SyncArchiveService sync;
}
