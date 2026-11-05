import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/data_export_import_repository.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile_repository.dart';
import 'package:speleoloc/services/device_preferences_carry_over.dart';
import 'package:speleoloc/services/database_restore_helper.dart';
import 'package:speleoloc/services/database_swap/live_database_swap.dart';

import 'package:speleoloc/services/archive/archive_extraction.dart';
import 'package:speleoloc/services/archive/archive_models.dart';
import 'package:speleoloc/services/archive/zip_file_writer.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/user_identity/user_handover.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/clock.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/contained_path.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_sign_in_carry_over.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_registry.dart';
// Re-export so existing callers (e.g. UI code, tests) that import models
// via data_archive_service.dart keep working after the Phase 2.4 split.
export 'package:speleoloc/services/archive/archive_models.dart';

// =============================================================================
//  Service
// =============================================================================

/// Orchestrates full-data export (zip) and import (replace / merge-sync).
///
/// Delegates raw DB access to [DataExportImportRepository] and receives
/// conflict-resolution decisions via UI callbacks.
class DataArchiveService {
  final DataExportImportRepository _repo;
  final Clock _clock;
  final LiveDatabaseSwap _databaseSwap;
  final _log = AppLogger.of('DataArchiveService');

  /// Pass the app's [databaseSwap] (from its provider) wherever a replace
  /// import can run, so the import is refused while a sync run is active.
  DataArchiveService(
    this._repo, {
    Clock clock = const SystemClock(),
    LiveDatabaseSwap? databaseSwap,
  }) : _clock = clock,
       _databaseSwap = databaseSwap ?? LiveDatabaseSwap();

  // ---------------------------------------------------------------------------
  //  EXPORT
  // ---------------------------------------------------------------------------

  /// Creates a zip archive at [outputDir] and returns the full path written.
  ///
  /// Pass [profileRepository] when [ExportSettings.includeFtpPasswords] is
  /// true — the method reads each profile's password from the OS keystore and
  /// stores them in `ftp_credentials.json` inside the archive.
  Future<String> exportArchive({
    required ExportSettings settings,
    required String outputDir,
    ProgressCallback? onProgress,
    FtpProfileRepository? profileRepository,
  }) async {
    onProgress?.call('Preparing export...');

    final docsDir = await getApplicationDocumentsDirectory();
    final entries = <ZipEntrySource>[];
    final workDir = await Directory.systemTemp.createTemp('speleo_loc_export_');
    try {
      // 1. Flush the WAL and snapshot the database file at once, so writes
      // made while the zip is built do not tear the copy.
      await appDatabase.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
      final dbFile = File('${docsDir.path}/$databaseFileName');
      if (await dbFile.exists()) {
        final snapshot = await dbFile.copy('${workDir.path}/$databaseFileName');
        entries.add(ZipEntrySource.file(databaseFileName, snapshot.path));
      }

      return await _writeExport(
        settings: settings,
        outputDir: outputDir,
        docsDir: docsDir,
        entries: entries,
        onProgress: onProgress,
        profileRepository: profileRepository,
      );
    } finally {
      try {
        await workDir.delete(recursive: true);
      } catch (e, st) {
        _log.fine('best-effort export work dir delete failed', e, st);
      }
    }
  }

  Future<String> _writeExport({
    required ExportSettings settings,
    required String outputDir,
    required Directory docsDir,
    required List<ZipEntrySource> entries,
    ProgressCallback? onProgress,
    FtpProfileRepository? profileRepository,
  }) async {
    // Determine diff-baseline timestamp.
    int? afterTimestamp;
    if (settings.diffOnly) {
      afterTimestamp = await _repo.getLastExportTimestamp();
    }

    // 2. Documentation files.
    if (settings.includeDocumentationFiles) {
      onProgress?.call('Adding documentation files...');
      final paths = await _repo.getDocumentationFilePaths(
        caveIds: settings.caveIds,
        afterTimestamp: afterTimestamp,
      );
      _addFileEntries(entries, docsDir.path, paths);
    }

    // 3. Raster-map images.
    if (settings.includeRasterMaps) {
      onProgress?.call('Adding raster map images...');
      final paths = await _repo.getRasterMapFilePaths(
        caveIds: settings.caveIds,
        afterTimestamp: afterTimestamp,
      );
      _addFileEntries(entries, docsDir.path, paths);
    }

    // 4. FTP credentials (optional, feature-flag guarded).
    if (settings.includeFtpPasswords && profileRepository != null) {
      onProgress?.call('Adding FTP credentials...');
      final profiles = await profileRepository.list();
      final credentials = <Map<String, dynamic>>[];
      for (final profile in profiles) {
        final password = await profileRepository.readPassword(
          profile.profileUuid,
        );
        credentials.add({...profile.toJson(), 'password': password ?? ''});
      }
      entries.add(
        ZipEntrySource.bytes(
          'ftp_credentials.json',
          utf8.encode(jsonEncode(credentials)),
        ),
      );
    }

    // 5. Manifest.
    final manifest = {
      'version': 1,
      'exportedAt': _clock.nowMs(),
      'isDiff': settings.diffOnly,
      'includesDocumentationFiles': settings.includeDocumentationFiles,
      'includesRasterMaps': settings.includeRasterMaps,
      'caveIds': settings.caveIds,
      'includesFtpPasswords': settings.includeFtpPasswords,
    };
    entries.add(
      ZipEntrySource.bytes('manifest.json', utf8.encode(jsonEncode(manifest))),
    );

    // 5. Encode & write.
    onProgress?.call('Creating archive...');

    final now = _clock.now();
    final ts =
        '${now.year}-${_pad(now.month)}-${_pad(now.day)}'
        '_${_pad(now.hour)}-${_pad(now.minute)}-${_pad(now.second)}';
    final suffix = settings.diffOnly ? '_diff' : '';
    final fileName = 'speleo_loc_$ts$suffix.zip';
    final outputPath = '$outputDir/$fileName';

    try {
      await writeZipFile(outputPath, entries);
    } catch (_) {
      // A half-written zip must not be offered as an export.
      try {
        await File(outputPath).delete();
      } on FileSystemException catch (e, st) {
        _log.fine('could not delete partial export $outputPath', e, st);
      }
      rethrow;
    }

    // 6. Record export timestamp (full exports only).
    if (!settings.diffOnly) {
      await _repo.setLastExportTimestamp(_clock.nowMs());
    }

    return outputPath;
  }

  // ---------------------------------------------------------------------------
  //  IMPORT – REPLACE
  // ---------------------------------------------------------------------------

  /// Replaces the entire local database and files with the archive contents.
  ///
  /// The archive's database is checked before anything local is touched,
  /// and when it fails to open or any later step throws, the previous
  /// database is put back and stays open; see [LiveDatabaseSwap]. Files the
  /// archive carries are copied over local ones of the same name and are not
  /// put back.
  ///
  /// The caller must restart the app after a successful import. Pass
  /// [adoptFtpProfiles] when the archive is the caver's own data rather than
  /// a sample: see [DevicePreferencesCarryOver.applyTo].
  Future<void> importArchiveReplace({
    required String zipPath,
    required SilexgisRefreshTokenStore silexgisTokens,
    SilexgisAuthRegistry? silexgisSignInRegistry,
    ForgetFtpProfileSecrets? adoptFtpProfiles,
    ProgressCallback? onProgress,
  }) async {
    _databaseSwap.ensureNoSyncRunning();
    onProgress?.call('Extracting archive...');
    final tempDir = await _extractZip(zipPath);

    try {
      final importedDbFile = File('${tempDir.path}/speleo_loc.sqlite');
      if (!await importedDbFile.exists()) {
        throw Exception('No database found in archive');
      }

      // Preserve the device-local identity so the restored database keeps
      // this device's UUID (the archive may carry a different device's UUID).
      // This behaviour can be disabled via the archive import/export config
      // flag `copy_device_uuid_from_archive_on_import`.
      final savedDeviceUuid = await _readConfigValue('device_uuid');
      final importExportCfgRaw = await _readConfigValue(
        'archive_sync_import_export_config',
      );
      final copyUuidFromArchive = copiesDeviceUuidFromArchive(
        importExportCfgRaw,
      );
      final userHandover = await UserHandoverStore(appDatabase).capture();
      final devicePreferences = await DevicePreferencesCarryOver.capture(
        appDatabase,
      );
      final silexgisSignIns = await SilexgisSignInCarryOver.capture(
        appDatabase,
        silexgisTokens,
      );

      final docsDir = await getApplicationDocumentsDirectory();
      onProgress?.call('Replacing database...');
      await _databaseSwap.replaceWith(
        importedDbFile,
        afterOpen: (db) async {
          DatabaseRestoreHelper.logMigrationIfAny(
            source: 'archive-import-replace',
          );

          // Restore device identity unless the flag says to adopt the
          // archive's.
          if (!copyUuidFromArchive && savedDeviceUuid != null) {
            await _writeConfigValue(db, 'device_uuid', savedDeviceUuid);
          }
          await UserHandoverStore(db).handOver(userHandover);
          await devicePreferences.applyTo(
            db,
            adoptFtpProfiles: adoptFtpProfiles,
          );
          await silexgisSignIns.applyTo(
            db,
            silexgisTokens,
            signIns: silexgisSignInRegistry,
          );

          // Copy all other files (documentation files, raster maps).
          onProgress?.call('Copying files...');
          await _copyAllExtractedFiles(tempDir, docsDir);

          // Restore FTP passwords from the archive's ftp_credentials.json
          // into the OS keystore (flutter_secure_storage). This must run
          // after the DB is re-opened so FtpProfileRepository can write to it.
          await _restoreFtpCredentialsIfAllowed(
            db,
            tempDir.path,
            onProgress: onProgress,
          );
        },
      );
    } finally {
      try {
        await tempDir.delete(recursive: true);
      } catch (e, st) {
        _log.fine('best-effort tempDir delete failed: ${tempDir.path}', e, st);
      }
    }
  }

  // ---------------------------------------------------------------------------
  //  IMPORT – MERGE
  // ---------------------------------------------------------------------------

  /// Merges the archive into the existing database through [merger], the
  /// same last-writer-wins merge FTP and file sync use, so rows are matched by
  /// uuid and deletes recorded in the archive's change log are applied.
  /// [conflictResolver] is asked whenever an incoming row would change a
  /// local one; files are copied only where none exists locally.
  Future<SyncImportReport> importArchiveMerge({
    required String zipPath,
    required SyncArchiveService merger,
    ConflictResolver? conflictResolver,
    ProgressCallback? onProgress,
  }) async {
    onProgress?.call('Extracting archive...');
    final tempDir = await _extractZip(zipPath);

    try {
      final importedDb = File('${tempDir.path}/speleo_loc.sqlite');
      if (!await importedDb.exists()) {
        throw Exception('No database found in archive');
      }

      onProgress?.call('Merging data...');
      final report = await merger.importFromDatabaseFile(
        importedDb,
        conflictResolver: conflictResolver,
      );

      onProgress?.call('Copying files...');
      final filesCopied = await _copyNewFiles(tempDir.path, report.warnings);

      await _restoreFtpCredentialsIfAllowed(
        appDatabase,
        tempDir.path,
        onProgress: onProgress,
      );

      return report.copyWith(filesCopied: filesCopied);
    } finally {
      try {
        await tempDir.delete(recursive: true);
      } catch (e, st) {
        _log.fine('best-effort tempDir delete failed: ${tempDir.path}', e, st);
      }
    }
  }

  // ---------------------------------------------------------------------------
  //  File helpers
  // ---------------------------------------------------------------------------

  /// Adds the files at [relativePaths] (relative to [baseDir]) to
  /// [entries]; a file that no longer exists is left out when the zip is
  /// written.
  void _addFileEntries(
    List<ZipEntrySource> entries,
    String baseDir,
    List<String> relativePaths,
  ) {
    for (final relPath in relativePaths) {
      final path = containedDocumentsPath(baseDir, relPath);
      if (path == null) {
        _log.warning(
          'not exporting a file outside the documents folder: $relPath',
        );
        continue;
      }
      entries.add(ZipEntrySource.file(relPath, path));
    }
  }

  /// Extract zip to a new temporary directory.
  Future<Directory> _extractZip(String zipPath) async {
    final tempDir = await Directory.systemTemp.createTemp('speleo_loc_import_');
    try {
      for (final name in await extractZipFileInto(zipPath, tempDir.path)) {
        _log.warning('skipping archive entry outside the import folder: $name');
      }
    } catch (_) {
      await tempDir.delete(recursive: true);
      rethrow;
    }
    return tempDir;
  }

  /// Copy all extracted files (except DB & manifest) into [docsDir],
  /// overwriting existing files.
  Future<void> _copyAllExtractedFiles(
    Directory extractDir,
    Directory docsDir,
  ) async {
    await for (final entity in extractDir.list(recursive: true)) {
      if (entity is File) {
        final relPath = entity.path
            .substring(extractDir.path.length + 1)
            .replaceAll('\\', '/');
        if (relPath == 'speleo_loc.sqlite' ||
            relPath == 'manifest.json' ||
            relPath == 'ftp_credentials.json') {
          continue;
        }
        final destPath = containedDocumentsPath(docsDir.path, relPath);
        if (destPath == null) {
          _log.warning('not restoring a file named as the database: $relPath');
          continue;
        }
        final dest = File(destPath);
        await dest.parent.create(recursive: true);
        await entity.copy(dest.path);
      }
    }
  }

  /// Copy only files that don't yet exist locally (for merge-import).
  Future<int> _copyNewFiles(String extractDir, List<String> warnings) async {
    final docsDir = await getApplicationDocumentsDirectory();
    int copied = 0;

    final dir = Directory(extractDir);
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final relPath = entity.path
            .substring(extractDir.length + 1)
            .replaceAll('\\', '/');
        if (relPath == 'speleo_loc.sqlite' ||
            relPath == 'manifest.json' ||
            relPath == 'ftp_credentials.json') {
          continue;
        }
        final destPath = containedDocumentsPath(docsDir.path, relPath);
        if (destPath == null) {
          warnings.add('Skipped $relPath: named as the database');
          continue;
        }
        final dest = File(destPath);
        if (!await dest.exists()) {
          try {
            await dest.parent.create(recursive: true);
            await entity.copy(dest.path);
            copied++;
          } catch (e) {
            warnings.add('Failed to copy $relPath: $e');
          }
        }
      }
    }
    return copied;
  }

  // ---------------------------------------------------------------------------
  //  Misc helpers
  // ---------------------------------------------------------------------------

  /// Restores `ftp_credentials.json` only on a build that can also export
  /// it. The restore upserts profiles by uuid and keeps the stored password
  /// of a profile whose host it replaces, so on any other build an archive
  /// carrying the file could redirect a saved login to another server.
  Future<void> _restoreFtpCredentialsIfAllowed(
    AppDatabase db,
    String extractDir, {
    ProgressCallback? onProgress,
  }) async {
    if (!exportFtpPasswordsEnabled) {
      if (await File('$extractDir/ftp_credentials.json').exists()) {
        _log.warning(
          'archive carries ftp_credentials.json; ignored on this build',
        );
      }
      return;
    }
    await _restoreFtpPasswords(db, extractDir, onProgress: onProgress);
  }

  /// Reads `ftp_credentials.json` from [extractDir] (if present) and upserts
  /// each FTP profile together with its password into [FtpProfileRepository].
  ///
  /// Called after the DB has been (re-)opened so the repository can write to
  /// it. Any entry whose `password` field is empty is saved without touching
  /// the stored password (preserves an existing keystore entry).
  Future<void> _restoreFtpPasswords(
    AppDatabase db,
    String extractDir, {
    ProgressCallback? onProgress,
  }) async {
    final credFile = File('$extractDir/ftp_credentials.json');
    if (!await credFile.exists()) return;

    onProgress?.call('Restoring FTP credentials...');

    List<dynamic> list;
    try {
      list = jsonDecode(await credFile.readAsString()) as List<dynamic>;
    } catch (e, st) {
      _log.warning(
        'ftp_credentials.json is malformed — skipping restore',
        e,
        st,
      );
      return;
    }

    final profileRepo = FtpProfileRepository(db);
    for (final entry in list) {
      if (entry is! Map<String, dynamic>) continue;
      final password = entry['password'] as String?;
      final profileData = Map<String, Object?>.from(entry)..remove('password');
      try {
        final profile = FtpProfile.fromJson(profileData);
        // Pass password only when non-empty; null means "don't touch the
        // existing keystore entry" (FtpProfileRepository.save semantics).
        await profileRepo.save(
          profile,
          password: (password != null && password.isNotEmpty) ? password : null,
        );
      } catch (e, st) {
        _log.warning('Failed to restore FTP profile entry from archive', e, st);
      }
    }
  }

  /// Reads a single value from `configurations` by [key] using the open DB.
  Future<String?> _readConfigValue(String key) async {
    final rows = await appDatabase
        .customSelect(
          'SELECT value FROM configurations WHERE title = ? LIMIT 1',
          variables: [Variable<String>(key)],
        )
        .get();
    if (rows.isEmpty) return null;
    return rows.first.data['value'] as String?;
  }

  /// Writes (upserts) a value into `configurations` of [db].
  Future<void> _writeConfigValue(
    AppDatabase db,
    String key,
    String value,
  ) async {
    final now = _clock.nowMs();
    await db.customStatement(
      'INSERT INTO configurations (title, value, created_at, updated_at) '
      'VALUES (?, ?, ?, ?) '
      'ON CONFLICT(title) DO UPDATE SET value = excluded.value, '
      'updated_at = excluded.updated_at',
      [key, value, now, now],
    );
  }

  /// Parses the `copy_device_uuid_from_archive_on_import` flag from the raw
  /// JSON stored under [ConfigKey.archiveSyncImportExportConfig].
  ///
  /// Returns `true` **only** when the flag is explicitly `true`.
  /// Any other value — absent config row, absent key in the JSON object,
  /// `null` value, `false`, or unparseable JSON — returns `false`, so
  /// the local device_uuid is preserved.
  static bool copiesDeviceUuidFromArchive(String? raw) {
    if (raw == null || raw.isEmpty) return false;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      // null, absent key, false → all evaluate to false via == true.
      return map['copy_device_uuid_from_archive_on_import'] == true;
    } catch (e, st) {
      AppLogger.of('DataArchiveService').fine(
        'Malformed archive sync config JSON — treating copyDeviceUuid as false',
        e,
        st,
      );
      return false;
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
