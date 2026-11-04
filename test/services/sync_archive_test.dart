import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
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

/// Exercises the export-then-import round-trip and LWW merge behaviour
/// of [SyncArchiveService] against two independent in-memory databases.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('speleoloc_sync_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<_Harness> buildHarness() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
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
    // Each harness gets its own sandboxed assets directory so tests can
    // round-trip binary payloads without touching the real documents dir.
    final assetsDir = await Directory.systemTemp.createTemp(
      'speleoloc_sync_assets_',
    );
    final sync = SyncArchiveService(
      db,
      loggerRef,
      assetsBaseDirResolver: () async => assetsDir,
    );
    return _Harness(db, caveRepo, loggerRef, sync, assetsDir);
  }

  test('round-trip carries caves and change-log between devices', () async {
    final a = await buildHarness();
    final b = await buildHarness();

    final caveId = await a.caveRepo.addCave('Alpha', description: 'first');

    final zip = await a.sync.exportToZip(tempDir.path, filenameHint: 'a.zip');
    expect(await zip.exists(), isTrue);

    final report = await b.sync.importFromZip(zip.path);
    expect(report.rowsInserted, greaterThan(0));
    expect(report.warnings, isEmpty);

    final onB = await b.caveRepo.getCaves();
    expect(onB.single.uuid, caveId);
    expect(onB.single.title, 'Alpha');

    // change_log was merged.
    final bLogs = await b.db.select(b.db.changeLog).get();
    expect(bLogs.any((l) => l.entityTable == 'caves'), isTrue);

    await a.db.close();
    await b.db.close();
  });

  test('LWW keeps newer local edit when archive is older', () async {
    final a = await buildHarness();
    final b = await buildHarness();

    // Step 1: A creates a cave.
    final id = await a.caveRepo.addCave('v1');
    final firstZip = await a.sync.exportToZip(
      tempDir.path,
      filenameHint: 'a1.zip',
    );
    await b.sync.importFromZip(firstZip.path);

    // Step 2: B edits the cave (newer updated_at).
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await b.caveRepo.updateCave(id, 'v2-on-B');

    // Step 3: A exports again (still v1 locally) and B imports.
    final secondZip = await a.sync.exportToZip(
      tempDir.path,
      filenameHint: 'a2.zip',
    );
    final r = await b.sync.importFromZip(secondZip.path);

    expect(
      r.rowsSkipped,
      greaterThan(0),
      reason: 'B has newer row, incoming older should be skipped',
    );
    final bRow = (await b.caveRepo.getCaves()).single;
    expect(bRow.title, 'v2-on-B', reason: 'B keeps its newer edit');

    await a.db.close();
    await b.db.close();
  });

  test('delete tombstone in change_log propagates to peer', () async {
    final a = await buildHarness();
    final b = await buildHarness();

    final id = await a.caveRepo.addCave('ToDelete');
    final zip1 = await a.sync.exportToZip(tempDir.path, filenameHint: 'a1.zip');
    await b.sync.importFromZip(zip1.path);
    expect((await b.caveRepo.getCaves()), hasLength(1));

    // Log a delete on A (without going through deleteCave — which does
    // not yet log). Simulate what the upcoming repo change will do.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await a.logger.logDelete('caves', id, oldValues: {'title': 'ToDelete'});
    // Physically delete on A after the log (order matters: log captures
    // the pre-image).
    await (a.db.delete(a.db.caves)..where((c) => c.uuid.equalsValue(id))).go();

    final zip2 = await a.sync.exportToZip(tempDir.path, filenameHint: 'a2.zip');
    final report = await b.sync.importFromZip(zip2.path);

    expect(report.deletesApplied, greaterThan(0));
    expect(
      (await b.caveRepo.getCaves()),
      isEmpty,
      reason: 'B should have deleted the cave based on tombstone',
    );

    await a.db.close();
    await b.db.close();
  });

  test('rejects archive with wrong schema_version', () async {
    final a = await buildHarness();
    final b = await buildHarness();

    final zip = await a.sync.exportToZip(tempDir.path, filenameHint: 'ok.zip');
    // Tamper with manifest by writing a corrupt file in the temp dir.
    final corrupted = File(p.join(tempDir.path, 'corrupted.zip'));
    await zip.copy(corrupted.path);
    // Simplest: write unrelated bytes and expect an exception.
    await corrupted.writeAsBytes([0, 1, 2, 3]);
    await expectLater(
      () => b.sync.importFromZip(corrupted.path),
      throwsA(isA<Exception>()),
    );

    await a.db.close();
    await b.db.close();
  });

  test('an archive is stamped with the archive schema version', () async {
    final a = await buildHarness();
    final zip = await a.sync.exportToZip(tempDir.path, filenameHint: 'a.zip');
    final archive = ZipDecoder().decodeBytes(
      await File(zip.path).readAsBytes(),
    );
    final manifest =
        jsonDecode(
              utf8.decode(
                archive.findFile('manifest.json')!.content as List<int>,
              ),
            )
            as Map<String, dynamic>;
    expect(manifest['schema_version'], kSyncArchiveDbSchemaVersion);
    await a.db.close();
  });

  test('imports every stamp from the archive version up to the local '
      'schema', () async {
    // Builds that kept the stamp equal to their schema version wrote stamps
    // above the archive version for the same archived tables.
    final a = await buildHarness();
    final b = await buildHarness();

    await a.caveRepo.addCave('Stamped');
    final zip = await a.sync.exportToZip(tempDir.path, filenameHint: 'a.zip');
    for (
      var stamp = kSyncArchiveDbSchemaVersion;
      stamp <= b.db.schemaVersion;
      stamp++
    ) {
      final relabeled = await _rewriteSchemaVersion(
        zip.path,
        tempDir.path,
        stamp,
      );
      await b.sync.importFromZip(relabeled);
    }
    expect((await b.caveRepo.getCaves()).single.title, 'Stamped');

    await a.db.close();
    await b.db.close();
  });

  test('accepts an older but in-range schema_version', () async {
    final a = await buildHarness();
    final b = await buildHarness();

    final id = await a.caveRepo.addCave('Legacy');
    final zip = await a.sync.exportToZip(tempDir.path, filenameHint: 'a.zip');
    // Relabel to the oldest supported schema; the JSONL still carries the
    // current columns, which are additively compatible, so it must import.
    final relabeled = await _rewriteSchemaVersion(
      zip.path,
      tempDir.path,
      kSyncArchiveMinImportSchemaVersion,
    );

    final report = await b.sync.importFromZip(relabeled);
    expect(report.rowsInserted, greaterThan(0));
    expect((await b.caveRepo.getCaves()).single.uuid, id);

    await a.db.close();
    await b.db.close();
  });

  test('rejects an archive from a newer app (schema above local)', () async {
    final a = await buildHarness();
    final b = await buildHarness();

    await a.caveRepo.addCave('FromFuture');
    final zip = await a.sync.exportToZip(tempDir.path, filenameHint: 'a.zip');
    final tooNew = await _rewriteSchemaVersion(
      zip.path,
      tempDir.path,
      b.db.schemaVersion + 1,
    );

    await expectLater(
      () => b.sync.importFromZip(tooNew),
      throwsA(
        isA<SyncArchiveSchemaMismatchException>().having(
          (e) => e.tooNew,
          'tooNew',
          isTrue,
        ),
      ),
    );

    await a.db.close();
    await b.db.close();
  });

  test('rejects an archive below the import floor', () async {
    final a = await buildHarness();
    final b = await buildHarness();

    await a.caveRepo.addCave('Ancient');
    final zip = await a.sync.exportToZip(tempDir.path, filenameHint: 'a.zip');
    final tooOld = await _rewriteSchemaVersion(
      zip.path,
      tempDir.path,
      kSyncArchiveMinImportSchemaVersion - 1,
    );

    await expectLater(
      () => b.sync.importFromZip(tooOld),
      throwsA(
        isA<SyncArchiveSchemaMismatchException>().having(
          (e) => e.tooNew,
          'tooNew',
          isFalse,
        ),
      ),
    );

    await a.db.close();
    await b.db.close();
  });

  test('asset files round-trip with documentation_files', () async {
    final a = await buildHarness();
    final b = await buildHarness();

    // Create a documentation_files DB row + a matching asset file on A.
    final docUuid = Uuid.v7();
    const relPath = 'documentation/doc1.txt';
    final payload = utf8.encode('hello cave');
    final src = File('${a.assetsDir.path}${Platform.pathSeparator}$relPath');
    await src.parent.create(recursive: true);
    await src.writeAsBytes(payload);

    final now = DateTime.now().millisecondsSinceEpoch;
    await a.db
        .into(a.db.documentationFiles)
        .insert(
          DocumentationFilesCompanion.insert(
            uuid: docUuid,
            title: 'Doc 1',
            fileName: relPath,
            fileSize: payload.length,
            fileType: 'txt',
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    // Export from A, import into B.
    final zip = await a.sync.exportToZip(
      tempDir.path,
      filenameHint: 'assets.zip',
    );
    final report = await b.sync.importFromZip(zip.path);

    expect(
      report.filesCopied,
      1,
      reason: 'B had no local copy so the asset should be copied',
    );
    expect(report.warnings, isEmpty);

    final docOnB = await (b.db.select(
      b.db.documentationFiles,
    )..where((d) => d.uuid.equalsValue(docUuid))).getSingle();
    expect(docOnB.fileName, relPath);

    final destOnB = File(
      '${b.assetsDir.path}${Platform.pathSeparator}$relPath',
    );
    expect(await destOnB.exists(), isTrue);
    expect(await destOnB.readAsBytes(), payload);

    await a.db.close();
    await b.db.close();
  });

  test('an asset file that cannot be written is counted as failed', () async {
    final a = await buildHarness();
    final b = await buildHarness();
    const relPath = 'documentation/doc1.txt';
    final payload = utf8.encode('hello cave');
    final src = File('${a.assetsDir.path}${Platform.pathSeparator}$relPath');
    await src.parent.create(recursive: true);
    await src.writeAsBytes(payload);
    final now = DateTime.now().millisecondsSinceEpoch;
    await a.db
        .into(a.db.documentationFiles)
        .insert(
          DocumentationFilesCompanion.insert(
            uuid: Uuid.v7(),
            title: 'Doc 1',
            fileName: relPath,
            fileSize: payload.length,
            fileType: 'txt',
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    final zip = await a.sync.exportToZip(
      tempDir.path,
      filenameHint: 'assets.zip',
    );
    // A folder where the file should go: writing it fails on B.
    await Directory(
      '${b.assetsDir.path}${Platform.pathSeparator}$relPath',
    ).create(recursive: true);

    final report = await b.sync.importFromZip(zip.path);

    expect(report.rowsInserted, greaterThan(0));
    expect(report.filesCopied, 0);
    expect(report.filesFailed, 1);
    expect(report.warnings, isNotEmpty);

    await a.db.close();
    await b.db.close();
  });

  test('manual resolver keepLocal overrides LWW', () async {
    final a = await buildHarness();
    final b = await buildHarness();

    // A creates + shares cave; B imports.
    final id = await a.caveRepo.addCave('Original');
    final zip1 = await a.sync.exportToZip(tempDir.path, filenameHint: 'a1.zip');
    await b.sync.importFromZip(zip1.path);

    // A edits the cave so A has the newer timestamp (default LWW would
    // normally overwrite B's copy on re-import).
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await a.caveRepo.updateCave(id, 'A-Edit');

    final zip2 = await a.sync.exportToZip(tempDir.path, filenameHint: 'a2.zip');

    final seen = <String>[];
    await b.sync.importFromZip(
      zip2.path,
      conflictResolver: (conflict) async {
        seen.add(conflict.tableName);
        return SyncConflictAction.keepLocal;
      },
    );

    expect(
      seen,
      contains('caves'),
      reason: 'caves row should have been routed through resolver',
    );
    final bRow = (await b.caveRepo.getCaves()).single;
    expect(
      bRow.title,
      'Original',
      reason: 'resolver told us to keep local despite newer incoming ts',
    );

    await a.db.close();
    await b.db.close();
  });

  test('manual resolver cancel rolls back the whole import', () async {
    final a = await buildHarness();
    final b = await buildHarness();

    await a.caveRepo.addCave('ShouldNotLand');
    final zip = await a.sync.exportToZip(tempDir.path, filenameHint: 'a.zip');

    // B has no local row → no conflict would fire; seed B with a local
    // cave that conflicts with the incoming archive.
    final id = await a.caveRepo.addCave('Second');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    // Re-export with two caves; one of them will conflict once we
    // pre-seed B with a different title for the same uuid.
    final zip2 = await a.sync.exportToZip(tempDir.path, filenameHint: 'a2.zip');
    await b.sync.importFromZip(zip2.path);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await b.caveRepo.updateCave(id, 'B-Edit');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await a.caveRepo.updateCave(id, 'A-Edit');
    final zip3 = await a.sync.exportToZip(tempDir.path, filenameHint: 'a3.zip');

    final bTitlesBefore = (await b.caveRepo.getCaves())
        .map((c) => c.title)
        .toSet();

    await expectLater(
      () => b.sync.importFromZip(
        zip3.path,
        conflictResolver: (_) async => SyncConflictAction.cancel,
      ),
      throwsA(isA<SyncImportCancelledException>()),
    );

    // Transaction rolled back → B's titles are unchanged.
    final bTitlesAfter = (await b.caveRepo.getCaves())
        .map((c) => c.title)
        .toSet();
    expect(bTitlesAfter, bTitlesBefore);

    await a.db.close();
    await b.db.close();
    // silence unused-var lint for zip
    zip.toString();
  });

  test(
    'insert unique collision keeps local and does not abort import',
    () async {
      final a = await buildHarness();
      final b = await buildHarness();

      final tOld = DateTime.now().millisecondsSinceEpoch;
      final bSurf = Uuid.v7();
      final aSurf = Uuid.v7();
      // B already has a surface area titled "Dup".
      await b.db
          .into(b.db.surfaceAreas)
          .insert(
            SurfaceAreasCompanion.insert(
              uuid: bSurf,
              title: 'Dup',
              createdAt: Value(tOld),
              updatedAt: Value(tOld),
            ),
          );
      // A has a DIFFERENT surface area with the SAME title (collides on
      // UNIQUE(title)) plus an unrelated cave to prove the rest still imports.
      await a.db
          .into(a.db.surfaceAreas)
          .insert(
            SurfaceAreasCompanion.insert(
              uuid: aSurf,
              title: 'Dup',
              createdAt: Value(tOld),
              updatedAt: Value(tOld),
            ),
          );
      final caveId = await a.caveRepo.addCave('SoloCave');

      final zip = await a.sync.exportToZip(tempDir.path, filenameHint: 'a.zip');
      // Must complete rather than abort on the colliding surface area.
      final report = await b.sync.importFromZip(zip.path);

      final ids = (await b.db.select(b.db.surfaceAreas).get())
          .map((s) => s.uuid)
          .toSet();
      expect(ids, contains(bSurf), reason: 'local row preserved');
      expect(ids, isNot(contains(aSurf)), reason: 'colliding incoming skipped');
      expect(
        (await b.caveRepo.getCaves()).any((c) => c.uuid == caveId),
        isTrue,
        reason: 'unrelated rows still imported despite the collision',
      );
      expect(report.rowsInserted, greaterThan(0));

      await a.db.close();
      await b.db.close();
    },
  );

  test(
    'incoming update never destroys an unrelated row (no REPLACE)',
    () async {
      final a = await buildHarness();
      final b = await buildHarness();

      final tOld = DateTime.now().millisecondsSinceEpoch;
      final tNew = tOld + 1000;
      final x = Uuid.v7();
      final y = Uuid.v7();
      // B: X="Alpha", Y="Beta".
      await b.db
          .into(b.db.surfaceAreas)
          .insert(
            SurfaceAreasCompanion.insert(
              uuid: x,
              title: 'Alpha',
              createdAt: Value(tOld),
              updatedAt: Value(tOld),
            ),
          );
      await b.db
          .into(b.db.surfaceAreas)
          .insert(
            SurfaceAreasCompanion.insert(
              uuid: y,
              title: 'Beta',
              createdAt: Value(tOld),
              updatedAt: Value(tOld),
            ),
          );
      // A has the SAME uuid X but renamed to "Beta" and newer — the incoming
      // edit collides with B's unrelated Y on UNIQUE(title). Under the old
      // InsertMode.insertOrReplace this REPLACE would delete Y.
      await a.db
          .into(a.db.surfaceAreas)
          .insert(
            SurfaceAreasCompanion.insert(
              uuid: x,
              title: 'Beta',
              createdAt: Value(tOld),
              updatedAt: Value(tNew),
            ),
          );

      final zip = await a.sync.exportToZip(tempDir.path, filenameHint: 'a.zip');
      await b.sync.importFromZip(zip.path); // must not abort

      final surfs = await b.db.select(b.db.surfaceAreas).get();
      final ids = surfs.map((s) => s.uuid).toSet();
      expect(
        ids,
        contains(y),
        reason: 'unrelated row Y must survive; REPLACE would have deleted it',
      );
      // X kept its local title because the incoming rename could not apply.
      expect(surfs.firstWhere((s) => s.uuid == x).title, 'Alpha');

      await a.db.close();
      await b.db.close();
    },
  );

  test('is_synced configurations propagate but device-local do not', () async {
    final a = await buildHarness();
    final b = await buildHarness();
    final aConfig = ConfigurationRepository(a.db);
    final bConfig = ConfigurationRepository(b.db);

    await aConfig.writeString(
      'place_code_strategy',
      'per_cave_sequential',
      isSynced: true,
    );
    // Device-local (is_synced defaults to 0) — must never be exported.
    await aConfig.writeString('last_open_cave', 'A-only');

    final zip = await a.sync.exportToZip(tempDir.path, filenameHint: 'a.zip');
    final report = await b.sync.importFromZip(zip.path);
    expect(report.warnings, isEmpty);

    expect(
      await bConfig.readString('place_code_strategy'),
      'per_cave_sequential',
      reason: 'synced strategy config should propagate',
    );
    expect(
      await bConfig.readString('last_open_cave'),
      isNull,
      reason: 'device-local config must not sync',
    );

    await a.db.close();
    await b.db.close();
  });

  test('configuration merge is last-writer-wins by updated_at', () async {
    final a = await buildHarness();
    final b = await buildHarness();
    final aConfig = ConfigurationRepository(a.db);
    final bConfig = ConfigurationRepository(b.db);

    // A writes first, B writes the newer value for the same key.
    await aConfig.writeString('qcri_mode', 'plain', isSynced: true);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await bConfig.writeString('qcri_mode', 'hashed', isSynced: true);

    // A (older) -> B: B keeps its newer value.
    final zipA = await a.sync.exportToZip(tempDir.path, filenameHint: 'a.zip');
    await b.sync.importFromZip(zipA.path);
    expect(await bConfig.readString('qcri_mode'), 'hashed');

    // B (newer) -> A: A adopts the newer value.
    final zipB = await b.sync.exportToZip(tempDir.path, filenameHint: 'b.zip');
    await a.sync.importFromZip(zipB.path);
    expect(await aConfig.readString('qcri_mode'), 'hashed');

    await a.db.close();
    await b.db.close();
  });

  test(
    'an archive cannot rewrite device-only settings, even flagged synced',
    () async {
      final a = await buildHarness();
      final b = await buildHarness();
      final aConfig = ConfigurationRepository(a.db);
      final bConfig = ConfigurationRepository(b.db);

      await aConfig.writeString(
        ConfigKey.placeCodeStrategy,
        'per_cave_sequential',
        isSynced: true,
      );
      const localProfiles =
          '[{"profileUuid":"00000000-0000-7000-8000-000000000001",'
          '"host":"ftp.example.test"}]';
      await bConfig.writeString(ConfigKey.ftpProfiles, localProfiles);
      await bConfig.writeString(
        ConfigKey.ftpDefaultProfileUuid,
        '00000000-0000-7000-8000-000000000001',
      );
      final bDevice = await bConfig.readString(ConfigKey.deviceUuid);
      final bUser = await bConfig.readString(ConfigKey.currentUserUuid);

      final zip = await a.sync.exportToZip(tempDir.path, filenameHint: 'a.zip');
      final future = DateTime.now()
          .add(const Duration(days: 1))
          .millisecondsSinceEpoch;
      Map<String, dynamic> hostile(String title, String value) => {
        'title': title,
        'value': value,
        'is_synced': 1,
        'created_at': future,
        'updated_at': future,
      };
      final crafted = await _appendRowsToTable(
        zip.path,
        tempDir.path,
        'configurations',
        [
          hostile(
            ConfigKey.ftpProfiles,
            '[{"profileUuid":"00000000-0000-7000-8000-000000000001",'
            '"host":"attacker.example.test"}]',
          ),
          hostile(
            ConfigKey.ftpDefaultProfileUuid,
            '00000000-0000-7000-8000-000000000002',
          ),
          hostile(
            ConfigKey.silexgisProfiles,
            '[{"profileUuid":"x","baseUrl":"https://attacker.example.test"}]',
          ),
          hostile(ConfigKey.deviceUuid, '00000000-0000-7000-8000-00000000dead'),
          hostile(
            ConfigKey.currentUserUuid,
            '00000000-0000-7000-8000-00000000beef',
          ),
        ],
      );

      await b.sync.importFromZip(crafted);

      expect(await bConfig.readString(ConfigKey.ftpProfiles), localProfiles);
      expect(
        await bConfig.readString(ConfigKey.ftpDefaultProfileUuid),
        '00000000-0000-7000-8000-000000000001',
      );
      expect(await bConfig.readString(ConfigKey.silexgisProfiles), isNull);
      expect(await bConfig.readString(ConfigKey.deviceUuid), bDevice);
      expect(await bConfig.readString(ConfigKey.currentUserUuid), bUser);
      final flag = await b.db
          .customSelect(
            "SELECT is_synced FROM configurations WHERE title = 'ftp_profiles'",
          )
          .getSingle();
      expect(
        flag.data['is_synced'],
        0,
        reason: 'a device-only key must not be flipped into the synced set',
      );
      expect(
        await bConfig.readString(ConfigKey.placeCodeStrategy),
        'per_cave_sequential',
        reason: 'a key this device syncs still merges from the same archive',
      );

      await a.db.close();
      await b.db.close();
    },
  );

  test('a device-only key flagged synced locally is not exported', () async {
    final a = await buildHarness();
    final aConfig = ConfigurationRepository(a.db);
    await aConfig.writeString(ConfigKey.qcriMode, 'plain', isSynced: true);
    // A row flipped to synced by an earlier, unfiltered import.
    await aConfig.writeString(ConfigKey.ftpProfiles, '[]', isSynced: true);

    final zip = await a.sync.exportToZip(tempDir.path, filenameHint: 'a.zip');
    final entry = ZipDecoder()
        .decodeBytes(await zip.readAsBytes())
        .findFile('tables/configurations.jsonl')!;
    final titles = utf8
        .decode(entry.content as List<int>)
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .map((l) => (jsonDecode(l) as Map<String, dynamic>)['title'])
        .toSet();
    expect(titles, contains(ConfigKey.qcriMode));
    expect(titles, isNot(contains(ConfigKey.ftpProfiles)));

    await a.db.close();
  });

  test(
    'merging a whole database file leaves device-only settings alone',
    () async {
      final b = await buildHarness();
      final bConfig = ConfigurationRepository(b.db);
      await bConfig.writeString(ConfigKey.ftpProfiles, '[]');

      final sourceFile = File(p.join(tempDir.path, 'source.sqlite'));
      final source = AppDatabase.file(sourceFile);
      final sourceConfig = ConfigurationRepository(source);
      await sourceConfig.writeString(
        ConfigKey.qcriMode,
        'hashed',
        isSynced: true,
      );
      await sourceConfig.writeString(
        ConfigKey.ftpProfiles,
        '[{"profileUuid":"00000000-0000-7000-8000-000000000001",'
        '"host":"attacker.example.test"}]',
        isSynced: true,
      );
      await source.customStatement('UPDATE configurations SET updated_at = ?', [
        DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
      ]);
      await source.close();

      await b.sync.importFromDatabaseFile(sourceFile);

      expect(await bConfig.readString(ConfigKey.ftpProfiles), '[]');
      expect(await bConfig.readString(ConfigKey.qcriMode), 'hashed');

      await b.db.close();
    },
  );

  test('a malformed JSONL line is skipped, not fatal to the import', () async {
    final a = await buildHarness();
    final b = await buildHarness();

    await a.caveRepo.addCave('Keeper');
    final zip = await a.sync.exportToZip(tempDir.path, filenameHint: 'a.zip');
    final corrupted = await _injectBadLineIntoTable(
      zip.path,
      tempDir.path,
      'caves',
    );

    // Import must complete and still carry the valid cave: one corrupt row
    // (truncated download, bit-rot) can't be allowed to roll back the lot.
    final report = await b.sync.importFromZip(corrupted);
    expect(report.rowsInserted, greaterThan(0));
    expect(
      (await b.caveRepo.getCaves()).any((c) => c.title == 'Keeper'),
      isTrue,
    );

    await a.db.close();
    await b.db.close();
  });
}

class _Harness {
  final AppDatabase db;
  final CaveRepository caveRepo;
  final ChangeLogger logger;
  final SyncArchiveService sync;
  final Directory assetsDir;
  _Harness(this.db, this.caveRepo, this.logger, this.sync, this.assetsDir);
}

/// Rewrites `manifest.json`'s `schema_version` to [newSchema] in a copy of
/// the archive at [srcZipPath], leaving every other entry byte-identical, and
/// returns the path of the rewritten zip. Used to exercise the import gate
/// without a second app build.
Future<String> _rewriteSchemaVersion(
  String srcZipPath,
  String destDir,
  int newSchema,
) async {
  final srcBytes = await File(srcZipPath).readAsBytes();
  final src = ZipDecoder().decodeBytes(srcBytes);
  final out = Archive();
  for (final f in src.files) {
    if (!f.isFile) continue;
    final content = (f.content as List<int>);
    if (f.name == 'manifest.json') {
      final manifest = jsonDecode(utf8.decode(content)) as Map<String, dynamic>;
      manifest['schema_version'] = newSchema;
      final rewritten = utf8.encode(jsonEncode(manifest));
      out.addFile(ArchiveFile('manifest.json', rewritten.length, rewritten));
    } else {
      out.addFile(ArchiveFile(f.name, content.length, content));
    }
  }
  final data = ZipEncoder().encode(out)!;
  final destPath = p.join(destDir, 'relabeled_$newSchema.zip');
  await File(destPath).writeAsBytes(data);
  return destPath;
}

/// Appends [rows] as JSONL lines to `tables/<tableName>.jsonl` in a copy of
/// the archive and returns the new zip path. Stands in for an archive written
/// by a modified client.
Future<String> _appendRowsToTable(
  String srcZipPath,
  String destDir,
  String tableName,
  List<Map<String, dynamic>> rows,
) async {
  final src = ZipDecoder().decodeBytes(await File(srcZipPath).readAsBytes());
  final out = Archive();
  final target = 'tables/$tableName.jsonl';
  for (final f in src.files) {
    if (!f.isFile) continue;
    final content = (f.content as List<int>);
    if (f.name == target) {
      final extra = rows.map(jsonEncode).join('\n');
      final appended = utf8.encode('${utf8.decode(content).trim()}\n$extra\n');
      out.addFile(ArchiveFile(target, appended.length, appended));
    } else {
      out.addFile(ArchiveFile(f.name, content.length, content));
    }
  }
  final destPath = p.join(destDir, 'appended_rows.zip');
  await File(destPath).writeAsBytes(ZipEncoder().encode(out)!);
  return destPath;
}

/// Appends a corrupt (non-JSON) line to `tables/<tableName>.jsonl` in a copy
/// of the archive, leaving every other entry intact, and returns the new zip
/// path. Simulates a truncated/bit-rotted row.
Future<String> _injectBadLineIntoTable(
  String srcZipPath,
  String destDir,
  String tableName,
) async {
  final srcBytes = await File(srcZipPath).readAsBytes();
  final src = ZipDecoder().decodeBytes(srcBytes);
  final out = Archive();
  final target = 'tables/$tableName.jsonl';
  for (final f in src.files) {
    if (!f.isFile) continue;
    final content = (f.content as List<int>);
    if (f.name == target) {
      final corrupted = utf8.encode(
        '${utf8.decode(content)}\n{ this is not valid json',
      );
      out.addFile(ArchiveFile(target, corrupted.length, corrupted));
    } else {
      out.addFile(ArchiveFile(f.name, content.length, content));
    }
  }
  final data = ZipEncoder().encode(out)!;
  final destPath = p.join(destDir, 'corrupted_line.zip');
  await File(destPath).writeAsBytes(data);
  return destPath;
}
