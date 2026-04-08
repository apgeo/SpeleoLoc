import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/data_export_import_repository.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/database_restore_helper.dart';

// =============================================================================
//  Models
// =============================================================================

/// Parametrises what is included in an export archive.
class ExportSettings {
  final bool includeDocumentationFiles;
  final bool includeRasterMaps;
  final bool diffOnly;
  final List<int>? caveIds; // null = all caves (future use)

  const ExportSettings({
    this.includeDocumentationFiles = true,
    this.includeRasterMaps = true,
    this.diffOnly = false,
    this.caveIds,
  });
}

/// What to do when an imported row conflicts with an existing one.
enum ConflictAction { skip, overwrite }

/// Describes a single unique-constraint collision detected during merge.
class ImportConflict {
  final String tableName;
  final String humanTableName;
  final Map<String, dynamic> existingRecord;
  final Map<String, dynamic> importedRecord;
  final List<String> conflictingColumns;

  const ImportConflict({
    required this.tableName,
    required this.humanTableName,
    required this.existingRecord,
    required this.importedRecord,
    required this.conflictingColumns,
  });
}

/// Replace vs Merge when importing into an existing database.
enum ImportMode { replace, merge }

/// Summary returned after a merge-import completes.
class ImportResult {
  final int tablesProcessed;
  final int recordsImported;
  final int recordsSkipped;
  final int recordsOverwritten;
  final int filesCopied;
  final List<String> warnings;

  const ImportResult({
    this.tablesProcessed = 0,
    this.recordsImported = 0,
    this.recordsSkipped = 0,
    this.recordsOverwritten = 0,
    this.filesCopied = 0,
    this.warnings = const [],
  });
}

/// Callback the sync engine invokes per conflict.
/// Return [ConflictAction] to continue, or `null` to cancel import.
typedef ConflictResolver = Future<ConflictAction?> Function(
    ImportConflict conflict);

/// Optional progress reporting.
typedef ProgressCallback = void Function(String message);

// =============================================================================
//  Table import configurations (order respects FK dependencies)
// =============================================================================

class _TableCfg {
  final String name;
  final String humanName;
  final List<String> columns; // all columns except 'id'
  final List<List<String>> uniqueConstraints;
  final Map<String, String> foreignKeys; // column → referenced table

  const _TableCfg({
    required this.name,
    required this.humanName,
    required this.columns,
    this.uniqueConstraints = const [],
    this.foreignKeys = const {},
  });
}

const List<_TableCfg> _tableConfigs = [
  _TableCfg(
    name: 'surface_areas',
    humanName: 'Surface Areas',
    columns: [
      'title', 'description', 'created_at', 'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['title']
    ],
  ),
  _TableCfg(
    name: 'surface_places',
    humanName: 'Surface Places',
    columns: [
      'title', 'description', 'type', 'surface_place_qr_code_identifier',
      'latitude', 'longitude', 'created_at', 'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['title'] // best-effort match by title
    ],
  ),
  _TableCfg(
    name: 'caves',
    humanName: 'Caves',
    columns: [
      'title', 'description', 'surface_area_id', 'created_at', 'updated_at',
      'deleted_at'
    ],
    uniqueConstraints: [
      ['title', 'surface_area_id']
    ],
    foreignKeys: {'surface_area_id': 'surface_areas'},
  ),
  _TableCfg(
    name: 'cave_areas',
    humanName: 'Cave Areas',
    columns: [
      'title', 'description', 'cave_id', 'created_at', 'updated_at',
      'deleted_at'
    ],
    uniqueConstraints: [
      ['title', 'cave_id']
    ],
    foreignKeys: {'cave_id': 'caves'},
  ),
  _TableCfg(
    name: 'cave_entrances',
    humanName: 'Cave Entrances',
    columns: [
      'cave_id', 'surface_place_id', 'is_main_entrance', 'title',
      'created_at', 'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['cave_id', 'title']
    ],
    foreignKeys: {'cave_id': 'caves', 'surface_place_id': 'surface_places'},
  ),
  _TableCfg(
    name: 'cave_places',
    humanName: 'Cave Places',
    columns: [
      'title', 'description', 'cave_id', 'place_qr_code_identifier',
      'cave_area_id', 'latitude', 'longitude', 'depth_in_cave', 'created_at',
      'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['title', 'cave_id', 'cave_area_id']
    ],
    foreignKeys: {'cave_id': 'caves', 'cave_area_id': 'cave_areas'},
  ),
  _TableCfg(
    name: 'raster_maps',
    humanName: 'Raster Maps',
    columns: [
      'title', 'map_type', 'file_name', 'cave_id', 'cave_area_id',
      'created_at', 'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['title', 'map_type', 'cave_id'],
      ['file_name', 'map_type', 'cave_id'],
    ],
    foreignKeys: {'cave_id': 'caves', 'cave_area_id': 'cave_areas'},
  ),
  _TableCfg(
    name: 'cave_place_to_raster_map_definitions',
    humanName: 'Map Point Definitions',
    columns: [
      'x_coordinate', 'y_coordinate', 'cave_place_id', 'raster_map_id',
      'created_at', 'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['cave_place_id', 'raster_map_id']
    ],
    foreignKeys: {
      'cave_place_id': 'cave_places',
      'raster_map_id': 'raster_maps',
    },
  ),
  _TableCfg(
    name: 'documentation_files',
    humanName: 'Documentation Files',
    columns: [
      'title', 'description', 'file_name', 'file_size', 'file_hash',
      'file_type', 'created_at', 'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['title', 'file_name', 'file_size', 'file_hash']
    ],
  ),
  _TableCfg(
    name: 'documentation_files_to_geofeatures',
    humanName: 'Document Links',
    columns: [
      'geofeature_id', 'geofeature_type', 'documentation_file_id',
      'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['geofeature_id', 'geofeature_type', 'documentation_file_id']
    ],
    foreignKeys: {'documentation_file_id': 'documentation_files'},
    // geofeature_id FK depends on geofeature_type – handled specially.
  ),
  _TableCfg(
    name: 'configurations',
    humanName: 'Configurations',
    columns: ['title', 'value', 'created_at', 'updated_at'],
    uniqueConstraints: [
      ['title']
    ],
  ),
  _TableCfg(
    name: 'cave_trips',
    humanName: 'Cave Trips',
    columns: [
      'cave_id', 'title', 'description', 'trip_started_at', 'trip_ended_at',
      'created_at', 'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [],
    foreignKeys: {'cave_id': 'caves'},
  ),
  _TableCfg(
    name: 'cave_trip_points',
    humanName: 'Cave Trip Points',
    columns: [
      'cave_trip_id', 'cave_place_id', 'scanned_at', 'notes',
      'created_at', 'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['cave_trip_id', 'cave_place_id', 'scanned_at']
    ],
    foreignKeys: {'cave_trip_id': 'cave_trips', 'cave_place_id': 'cave_places'},
  ),
  _TableCfg(
    name: 'documentation_files_to_cave_trips',
    humanName: 'Document-Trip Links',
    columns: [
      'documentation_file_id', 'cave_trip_id', 'created_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['documentation_file_id', 'cave_trip_id']
    ],
    foreignKeys: {
      'documentation_file_id': 'documentation_files',
      'cave_trip_id': 'cave_trips',
    },
  ),
];

/// Configuration keys that should *not* be imported (device-local settings).
const Set<String> _skipConfigKeys = {lastOpenCaveKey, lastExportTimestampKey, activeTripConfigKey};

/// Maps geofeature_type DB value to the table name used for id-remapping.
String? _geofeatureTypeToTable(String type) {
  switch (type) {
    case 'cave':
      return 'caves';
    case 'cave_place':
      return 'cave_places';
    case 'cave_area':
      return 'cave_areas';
    default:
      return null;
  }
}

// =============================================================================
//  Service
// =============================================================================

/// Orchestrates full-data export (zip) and import (replace / merge-sync).
///
/// Delegates raw DB access to [DataExportImportRepository] and receives
/// conflict-resolution decisions via UI callbacks.
class DataArchiveService {
  final DataExportImportRepository _repo;

  DataArchiveService(this._repo);

  // ---------------------------------------------------------------------------
  //  EXPORT
  // ---------------------------------------------------------------------------

  /// Creates a zip archive at [outputDir] and returns the full path written.
  Future<String> exportArchive({
    required ExportSettings settings,
    required String outputDir,
    ProgressCallback? onProgress,
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

    // 4. Manifest.
    final manifest = {
      'version': 1,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'isDiff': settings.diffOnly,
      'includesDocumentationFiles': settings.includeDocumentationFiles,
      'includesRasterMaps': settings.includeRasterMaps,
      'caveIds': settings.caveIds,
    };
    final manifestBytes = utf8.encode(jsonEncode(manifest));
    archive.addFile(
        ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    // 5. Encode & write.
    onProgress?.call('Creating archive...');
    final zipData = ZipEncoder().encode(archive);

    final now = DateTime.now();
    final ts = '${now.year}-${_pad(now.month)}-${_pad(now.day)}'
        '_${_pad(now.hour)}-${_pad(now.minute)}-${_pad(now.second)}';
    final suffix = settings.diffOnly ? '_diff' : '';
    final fileName = 'speleo_loc_$ts$suffix.zip';
    final outputPath = '$outputDir/$fileName';

    await File(outputPath).writeAsBytes(zipData!);

    // 6. Record export timestamp (full exports only).
    if (!settings.diffOnly) {
      await _repo
          .setLastExportTimestamp(DateTime.now().millisecondsSinceEpoch);
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
      appDatabase = AppDatabase();
      DatabaseRestoreHelper.logMigrationIfAny(source: 'archive-import-replace');
    } finally {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------------------
  //  IMPORT – MERGE
  // ---------------------------------------------------------------------------

  /// Merges the archive into the existing database, asking [conflictResolver]
  /// whenever a unique-constraint collision is detected.
  Future<ImportResult> importArchiveMerge({
    required String zipPath,
    required ConflictResolver conflictResolver,
    ProgressCallback? onProgress,
  }) async {
    onProgress?.call('Extracting archive...');
    final tempDir = await _extractZip(zipPath);

    try {
      final importedDbPath = '${tempDir.path}/speleo_loc.sqlite';
      if (!await File(importedDbPath).exists()) {
        throw Exception('No database found in archive');
      }

      return await _syncMerge(
        importedDbPath: importedDbPath,
        extractDir: tempDir.path,
        conflictResolver: conflictResolver,
        onProgress: onProgress,
      );
    } finally {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------------------
  //  Sync engine (merge)
  // ---------------------------------------------------------------------------

  Future<ImportResult> _syncMerge({
    required String importedDbPath,
    required String extractDir,
    required ConflictResolver conflictResolver,
    ProgressCallback? onProgress,
  }) async {
    // oldId → newId per table.
    final idMappings = <String, Map<int, int>>{};
    int imported = 0, skipped = 0, overwritten = 0;
    final warnings = <String>[];

    await _repo.attachImportedDb(importedDbPath);

    try {
      for (final cfg in _tableConfigs) {
        onProgress?.call('Syncing ${cfg.humanName}...');
        idMappings[cfg.name] = {};

        List<Map<String, dynamic>> importedRows;
        try {
          importedRows = await _repo.getImportedTableRows(cfg.name);
        } catch (e) {
          // Table may not exist in older exports – skip gracefully.
          warnings.add('Table ${cfg.humanName} not found in archive');
          continue;
        }

        for (final row in importedRows) {
          final oldId = row['id'] as int;

          // Skip device-local configuration keys.
          if (cfg.name == 'configurations') {
            final title = row['title'] as String?;
            if (title != null && _skipConfigKeys.contains(title)) continue;
          }

          // Build a mutable copy without 'id' (auto-generated on insert).
          final remapped = Map<String, dynamic>.from(row)..remove('id');

          // Remap declared foreign keys.
          for (final fk in cfg.foreignKeys.entries) {
            final oldFkId = remapped[fk.key];
            if (oldFkId != null && oldFkId is int) {
              final newFkId = idMappings[fk.value]?[oldFkId];
              if (newFkId == null) {
                warnings.add(
                    '${cfg.humanName}: could not remap ${fk.key}=$oldFkId');
              }
              remapped[fk.key] = newFkId;
            }
          }

          // Polymorphic FK for documentation_files_to_geofeatures.
          if (cfg.name == 'documentation_files_to_geofeatures') {
            final geoType = remapped['geofeature_type'] as String?;
            final geoId = remapped['geofeature_id'];
            if (geoType != null && geoId != null && geoId is int) {
              final refTable = _geofeatureTypeToTable(geoType);
              if (refTable != null) {
                remapped['geofeature_id'] = idMappings[refTable]?[geoId];
              }
            }
          }

          // Detect conflict.
          final existing = await _repo.findConflict(
            cfg.name,
            cfg.uniqueConstraints,
            remapped,
          );

          if (existing != null) {
            final existingId = existing['id'] as int;
            final conflict = ImportConflict(
              tableName: cfg.name,
              humanTableName: cfg.humanName,
              existingRecord: existing,
              importedRecord: remapped,
              conflictingColumns:
                  _conflictCols(cfg.uniqueConstraints, remapped, existing),
            );

            final action = await conflictResolver(conflict);
            if (action == null) {
              // User cancelled import.
              throw _ImportCancelledException();
            }

            if (action == ConflictAction.skip) {
              idMappings[cfg.name]![oldId] = existingId;
              skipped++;
            } else {
              await _repo.updateRow(
                  cfg.name, existingId, cfg.columns, remapped);
              idMappings[cfg.name]![oldId] = existingId;
              overwritten++;
            }
          } else {
            try {
              final newId =
                  await _repo.insertRow(cfg.name, cfg.columns, remapped);
              idMappings[cfg.name]![oldId] = newId;
              imported++;
            } catch (e) {
              warnings.add('${cfg.humanName} insert failed: $e');
            }
          }
        }
      }
    } finally {
      try {
        await _repo.detachImportedDb();
      } catch (_) {}
    }

    // Copy binary files that don't already exist locally.
    onProgress?.call('Copying files...');
    final filesCopied = await _copyNewFiles(extractDir, warnings);

    return ImportResult(
      tablesProcessed: _tableConfigs.length,
      recordsImported: imported,
      recordsSkipped: skipped,
      recordsOverwritten: overwritten,
      filesCopied: filesCopied,
      warnings: warnings,
    );
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

    final tempDir =
        await Directory.systemTemp.createTemp('speleo_loc_import_');

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
      Directory extractDir, Directory docsDir) async {
    await for (final entity in extractDir.list(recursive: true)) {
      if (entity is File) {
        final relPath = entity.path
            .substring(extractDir.path.length + 1)
            .replaceAll('\\', '/');
        if (relPath == 'speleo_loc.sqlite' || relPath == 'manifest.json') {
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
        if (relPath == 'speleo_loc.sqlite' || relPath == 'manifest.json') {
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

  static String _pad(int n) => n.toString().padLeft(2, '0');

  /// Identify which unique-constraint columns actually collide between
  /// [imported] and [existing].
  static List<String> _conflictCols(
    List<List<String>> constraints,
    Map<String, dynamic> imported,
    Map<String, dynamic> existing,
  ) {
    for (final group in constraints) {
      bool allMatch = true;
      for (final col in group) {
        if (imported[col] == null || existing[col] == null) {
          allMatch = false;
          break;
        }
        if (imported[col].toString() != existing[col].toString()) {
          allMatch = false;
          break;
        }
      }
      if (allMatch) return group;
    }
    return constraints.isNotEmpty ? constraints.first : [];
  }
}

// ---------------------------------------------------------------------------
//  Internal exception used to signal user-cancellation during merge.
// ---------------------------------------------------------------------------

class _ImportCancelledException implements Exception {
  @override
  String toString() => 'Import cancelled by user';
}
