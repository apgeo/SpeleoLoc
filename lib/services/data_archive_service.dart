import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/data_export_import_repository.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile_repository.dart';
import 'package:speleoloc/services/device_preferences_carry_over.dart';
import 'package:speleoloc/services/database_restore_helper.dart';
import 'package:speleoloc/services/service_locator.dart';

import 'package:speleoloc/services/archive/archive_models.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/user_identity/user_handover.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/clock.dart';
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
  final _log = AppLogger.of('DataArchiveService');

  DataArchiveService(this._repo, {Clock clock = const SystemClock()})
    : _clock = clock;

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
    final archive = Archive();

    // 1. Flush WAL and add database file.
    await appDatabase.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    final dbFile = File('${docsDir.path}/speleo_loc.sqlite');
    if (await dbFile.exists()) {
      final bytes = await dbFile.readAsBytes();
      archive.addFile(ArchiveFile('speleo_loc.sqlite', bytes.length, bytes));
    }

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
      await _addFilesToArchive(archive, docsDir.path, paths);
    }

    // 3. Raster-map images.
    if (settings.includeRasterMaps) {
      onProgress?.call('Adding raster map images...');
      final paths = await _repo.getRasterMapFilePaths(
        caveIds: settings.caveIds,
        afterTimestamp: afterTimestamp,
      );
      await _addFilesToArchive(archive, docsDir.path, paths);
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
      final credBytes = utf8.encode(jsonEncode(credentials));
      archive.addFile(
        ArchiveFile('ftp_credentials.json', credBytes.length, credBytes),
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
    final manifestBytes = utf8.encode(jsonEncode(manifest));
    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );

    // 5. Encode & write.
    onProgress?.call('Creating archive...');
    final zipData = ZipEncoder().encode(archive);

    final now = _clock.now();
    final ts =
        '${now.year}-${_pad(now.month)}-${_pad(now.day)}'
        '_${_pad(now.hour)}-${_pad(now.minute)}-${_pad(now.second)}';
    final suffix = settings.diffOnly ? '_diff' : '';
    final fileName = 'speleo_loc_$ts$suffix.zip';
    final outputPath = '$outputDir/$fileName';

    await File(outputPath).writeAsBytes(zipData!);

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
  /// The caller must restart the app afterwards.
  Future<void> importArchiveReplace({
    required String zipPath,
    ProgressCallback? onProgress,
  }) async {
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
      final copyUuidFromArchive = _parseCopyDeviceUuidFlag(importExportCfgRaw);
      final userHandover = await UserHandoverStore(appDatabase).capture();
      final devicePreferences = await DevicePreferencesCarryOver.capture(
        appDatabase,
      );

      // Close current database.
      await appDatabase.close();

      final docsDir = await getApplicationDocumentsDirectory();

      // Replace database.
      onProgress?.call('Replacing database...');
      final targetDb = File('${docsDir.path}/speleo_loc.sqlite');
      if (await targetDb.exists()) await targetDb.delete();
      await importedDbFile.copy(targetDb.path);

      // Copy all other files (documentation files, raster maps).
      onProgress?.call('Copying files...');
      await _copyAllExtractedFiles(tempDir, docsDir);

      // Re-open database.
      replaceAppDatabase(AppDatabase());
      DatabaseRestoreHelper.logMigrationIfAny(source: 'archive-import-replace');

      // Restore device identity unless the flag says to adopt the archive's.
      if (!copyUuidFromArchive && savedDeviceUuid != null) {
        await _writeConfigValue('device_uuid', savedDeviceUuid);
      }
      await UserHandoverStore(appDatabase).handOver(userHandover);
      await devicePreferences.applyTo(appDatabase);

      // Restore FTP passwords from the archive's ftp_credentials.json into
      // the OS keystore (flutter_secure_storage). This must run after the
      // DB is re-opened so FtpProfileRepository can write to it.
      await _restoreFtpPasswords(tempDir.path, onProgress: onProgress);
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

      // Restore FTP passwords from the archive's ftp_credentials.json.
      await _restoreFtpPasswords(tempDir.path, onProgress: onProgress);

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

  /// Add files at [relativePaths] (relative to [baseDir]) into [archive].
  Future<void> _addFilesToArchive(
    Archive archive,
    String baseDir,
    List<String> relativePaths,
  ) async {
    for (final relPath in relativePaths) {
      final file = File('$baseDir/$relPath');
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile(relPath, bytes.length, bytes));
      }
    }
  }

  /// Extract zip to a new temporary directory.
  Future<Directory> _extractZip(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final tempDir = await Directory.systemTemp.createTemp('speleo_loc_import_');

    for (final file in archive) {
      final name = file.name.replaceAll('\\', '/');
      if (file.isFile) {
        final content = file.content;
        if (content != null) {
          final outFile = File('${tempDir.path}/$name');
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(content as List<int>);
        }
      }
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
        final dest = File('${docsDir.path}/$relPath');
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
        final dest = File('${docsDir.path}/$relPath');
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

  /// Reads `ftp_credentials.json` from [extractDir] (if present) and upserts
  /// each FTP profile together with its password into [FtpProfileRepository].
  ///
  /// Called after the DB has been (re-)opened so the repository can write to
  /// it. Any entry whose `password` field is empty is saved without touching
  /// the stored password (preserves an existing keystore entry).
  Future<void> _restoreFtpPasswords(
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

    final profileRepo = FtpProfileRepository(appDatabase);
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

  /// Writes (upserts) a value into `configurations` using the open DB.
  Future<void> _writeConfigValue(String key, String value) async {
    final now = _clock.nowMs();
    await appDatabase.customStatement(
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
  static bool _parseCopyDeviceUuidFlag(String? raw) {
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
