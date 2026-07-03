import 'dart:io';

import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/sync/sync_table_registry.dart';
import 'package:speleoloc/services/user_repository.dart';

/// WS-D D5 precondition: a real, migrated production dataset must survive an
/// export/import round-trip through the current sync format without row loss.
///
/// Uses the richest shipped fixture (`speleo_loc_export_20260425.sqlite`,
/// user_version 9). Opening it migrates it to the current schema (15) — the
/// same path `legacy_v6_migration_test.dart` exercises for the older
/// binaries — then it is exported and imported into a fresh database and the
/// per-table row counts are compared. The pre-v7 fixtures (user_version 0/1)
/// are intentionally not round-tripped here: drift treats user_version 0 as a
/// brand-new database and runs onCreate instead of the migration ladder, so
/// they can't be opened as a live dataset this way (migration coverage for
/// those is WS-I I1).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_fixture_rt_');
  });
  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<(AppDatabase, SyncArchiveService)> buildStack(
    QueryExecutor executor,
    Directory assets,
  ) async {
    final db = AppDatabase.forTesting(executor);
    late ChangeLogger loggerRef;
    final userRepo = UserRepository(db, () => loggerRef);
    final currentUser = CurrentUserService(
      db,
      userRepo,
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    loggerRef = ChangeLogger(db, currentUser);
    final sync = SyncArchiveService(
      db,
      loggerRef,
      assetsBaseDirResolver: () async => assets,
    );
    return (db, sync);
  }

  test(
    'richest fixture round-trips through the sync format without row loss',
    () async {
      final source = File(
        'test_data/db/binaries/speleo_loc_export_20260425.sqlite',
      );
      expect(source.existsSync(), isTrue, reason: 'fixture missing');

      // Copy so the on-open migration (user_version 9 -> 15) does not mutate
      // the tracked fixture.
      final srcCopy = File(p.join(tempDir.path, 'source.sqlite'));
      await source.copy(srcCopy.path);

      final srcAssets = await Directory.systemTemp.createTemp('rt_src_');
      final (srcDb, srcSync) = await buildStack(
        NativeDatabase(srcCopy),
        srcAssets,
      );
      final tgtAssets = await Directory.systemTemp.createTemp('rt_tgt_');
      final (tgtDb, tgtSync) = await buildStack(
        NativeDatabase.memory(),
        tgtAssets,
      );

      try {
        // Opening migrated the fixture to the current schema.
        expect(srcDb.schemaVersion, kSyncArchiveDbSchemaVersion);

        // Per-table dump counts on the migrated source.
        final srcRegistry = SyncTableRegistry(srcDb);
        final srcCounts = <String, int>{};
        for (final t in srcRegistry.tables()) {
          srcCounts[t.name] = (await t.dump()).length;
        }
        expect(
          srcCounts['caves'],
          greaterThan(0),
          reason: 'fixture is expected to contain caves',
        );

        final zip = await srcSync.exportToZip(
          tempDir.path,
          filenameHint: 'rt.zip',
          includeDocumentationFiles: false,
          includeRasterMaps: false,
        );

        final report = await tgtSync.importFromZip(zip.path);
        expect(report.rowsInserted, greaterThan(0));

        // Every synced table has the same dump count on the fresh target.
        // `users` is compared by username instead of raw count because sync
        // merges the auto-created 'system' user across devices by username.
        final tgtRegistry = SyncTableRegistry(tgtDb);
        for (final t in tgtRegistry.tables()) {
          if (t.name == 'users') continue;
          final tgtCount = (await t.dump()).length;
          expect(
            tgtCount,
            srcCounts[t.name],
            reason:
                'row-count mismatch for ${t.name}: '
                'src=${srcCounts[t.name]} tgt=$tgtCount '
                '(warnings: ${report.warnings.join("; ")})',
          );
        }

        final srcUsernames = (await srcDb.select(srcDb.users).get())
            .map((u) => u.username)
            .toSet();
        final tgtUsernames = (await tgtDb.select(tgtDb.users).get())
            .map((u) => u.username)
            .toSet();
        expect(
          tgtUsernames.containsAll(srcUsernames),
          isTrue,
          reason: 'every source user should survive the round-trip',
        );
      } finally {
        await srcDb.close();
        await tgtDb.close();
      }
    },
  );
}
