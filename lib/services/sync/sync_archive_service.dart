import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/sync/sync_serializer.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Current on-disk sync archive format version. Bump when the layout
/// changes in a non-backwards-compatible way.
///
/// v2: asset files (documentation_files, raster_maps) are shipped inside
///     the zip under `assets/<relative path>` mirroring the app's
///     documents directory layout.
const int kSyncArchiveVersion = 2;

/// Database schema version this archive format targets. Imports with a
/// different `schema_version` are refused (rather than silently mis-merging).
const int kSyncArchiveDbSchemaVersion = 9;

/// Result of an import operation.
class SyncImportReport {
  final int rowsInserted;
  final int rowsUpdated;
  final int rowsSkipped; // local copy already newer
  final int deletesApplied;
  final int changeLogMerged;
  final int filesCopied;
  final int filesSkipped; // already present locally
  final List<String> warnings;

  const SyncImportReport({
    required this.rowsInserted,
    required this.rowsUpdated,
    required this.rowsSkipped,
    required this.deletesApplied,
    required this.changeLogMerged,
    required this.filesCopied,
    required this.filesSkipped,
    required this.warnings,
  });

  @override
  String toString() =>
      'SyncImportReport(inserted=$rowsInserted, updated=$rowsUpdated, '
      'skipped=$rowsSkipped, deletes=$deletesApplied, '
      'changeLog=$changeLogMerged, filesCopied=$filesCopied, '
      'filesSkipped=$filesSkipped, warnings=${warnings.length})';
}

/// Offline archive-based sync across devices.
///
/// Export produces a `.zip` containing, in addition to a small manifest,
/// one JSONL file per synced table plus the `change_log` / `change_log_field`
/// rows. Import replays those files with a last-writer-wins policy keyed on
/// `updated_at` (falling back to `created_at`). Change-log entries carrying
/// a delete tombstone are used to propagate deletes across devices without
/// requiring an app-wide soft-delete query refactor.
///
/// The whole import runs inside [ChangeLogger.runSuspended] so replay does
/// not double-log into the local `change_log`.
class SyncArchiveService {
  SyncArchiveService(
    this._db,
    this._logger, {
    Future<Directory> Function()? assetsBaseDirResolver,
  }) : _assetsBaseDirResolver =
            assetsBaseDirResolver ?? getApplicationDocumentsDirectory;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final Future<Directory> Function() _assetsBaseDirResolver;
  final _log = AppLogger.of('SyncArchiveService');

  static const _serializer = SyncValueSerializer();
  static const _assetsPrefix = 'assets/';

  // Tables exported (in FK-dependency order). Each entry is a small struct
  // holding dump/restore callbacks so the big ordered list is the single
  // source of truth for sync scope.
  List<_SyncTable> _syncedTables() => <_SyncTable>[
        _SyncTable(
          name: 'users',
          dump: () async => (await _db.select(_db.users).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows) async => _upsertRows<User>(
            rows,
            (j) => User.fromJson(j, serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.users,
          ),
        ),
        _SyncTable(
          name: 'surface_areas',
          dump: () async => (await _db.select(_db.surfaceAreas).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows) async => _upsertRows<SurfaceArea>(
            rows,
            (j) => SurfaceArea.fromJson(j, serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.surfaceAreas,
          ),
        ),
        _SyncTable(
          name: 'caves',
          dump: () async => (await _db.select(_db.caves).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows) async => _upsertRows<Cave>(
            rows,
            (j) => Cave.fromJson(j, serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.caves,
          ),
        ),
        _SyncTable(
          name: 'cave_areas',
          dump: () async => (await _db.select(_db.caveAreas).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows) async => _upsertRows<CaveArea>(
            rows,
            (j) => CaveArea.fromJson(j, serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.caveAreas,
          ),
        ),
        _SyncTable(
          name: 'cave_places',
          dump: () async => (await _db.select(_db.cavePlaces).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows) async => _upsertRows<CavePlace>(
            rows,
            (j) => CavePlace.fromJson(j, serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.cavePlaces,
          ),
        ),
        _SyncTable(
          name: 'raster_maps',
          dump: () async => (await _db.select(_db.rasterMaps).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows) async => _upsertRows<RasterMap>(
            rows,
            (j) => RasterMap.fromJson(j, serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.rasterMaps,
          ),
        ),
        _SyncTable(
          name: 'cave_place_to_raster_map_definitions',
          dump: () async =>
              (await _db.select(_db.cavePlaceToRasterMapDefinitions).get())
                  .map((r) => r.toJson(serializer: _serializer))
                  .toList(),
          upsert: (rows) async =>
              _upsertRows<CavePlaceToRasterMapDefinition>(
            rows,
            (j) => CavePlaceToRasterMapDefinition.fromJson(
              j,
              serializer: _serializer,
            ),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.cavePlaceToRasterMapDefinitions,
          ),
        ),
        _SyncTable(
          name: 'cave_trips',
          dump: () async => (await _db.select(_db.caveTrips).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows) async => _upsertRows<CaveTrip>(
            rows,
            (j) => CaveTrip.fromJson(j, serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.caveTrips,
          ),
        ),
        _SyncTable(
          name: 'cave_trip_points',
          dump: () async => (await _db.select(_db.caveTripPoints).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows) async => _upsertRows<CaveTripPoint>(
            rows,
            (j) => CaveTripPoint.fromJson(j, serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.caveTripPoints,
          ),
        ),
        _SyncTable(
          name: 'documentation_files',
          dump: () async => (await _db.select(_db.documentationFiles).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows) async => _upsertRows<DocumentationFile>(
            rows,
            (j) => DocumentationFile.fromJson(j, serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.documentationFiles,
          ),
        ),
        _SyncTable(
          name: 'documentation_files_to_geofeatures',
          dump: () async =>
              (await _db.select(_db.documentationFilesToGeofeatures).get())
                  .map((r) => r.toJson(serializer: _serializer))
                  .toList(),
          upsert: (rows) async => _upsertRows<DocumentationFilesToGeofeature>(
            rows,
            (j) => DocumentationFilesToGeofeature.fromJson(
              j,
              serializer: _serializer,
            ),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.documentationFilesToGeofeatures,
          ),
        ),
        _SyncTable(
          name: 'documentation_files_to_cave_trips',
          dump: () async =>
              (await _db.select(_db.documentationFilesToCaveTrips).get())
                  .map((r) => r.toJson(serializer: _serializer))
                  .toList(),
          upsert: (rows) async => _upsertRows<DocumentationFilesToCaveTrip>(
            rows,
            (j) => DocumentationFilesToCaveTrip.fromJson(
              j,
              serializer: _serializer,
            ),
            (r) => r.uuid,
            // Link table has no updated_at; LWW falls back to created_at.
            (r) => r.createdAt,
            _db.documentationFilesToCaveTrips,
          ),
        ),
        _SyncTable(
          name: 'trip_report_templates',
          dump: () async =>
              (await _db.select(_db.tripReportTemplates).get())
                  .map((r) => r.toJson(serializer: _serializer))
                  .toList(),
          upsert: (rows) async => _upsertRows<TripReportTemplate>(
            rows,
            (j) => TripReportTemplate.fromJson(j, serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.tripReportTemplates,
          ),
        ),
      ];

  // ---------------------------------------------------------------------------
  //  EXPORT
  // ---------------------------------------------------------------------------

  /// Writes a sync archive to [outputDir] and returns the file.
  ///
  /// Optionally bundles asset files (documentation files, raster map images)
  /// under `assets/<relative path>` in the zip, mirroring the app's documents
  /// directory layout.
  Future<File> exportToZip(
    String outputDir, {
    String? filenameHint,
    bool includeDocumentationFiles = true,
    bool includeRasterMaps = true,
  }) async {
    final archive = Archive();
    final tables = _syncedTables();

    for (final t in tables) {
      final rows = await t.dump();
      archive.addFile(_jsonlFile('tables/${t.name}.jsonl', rows));
    }

    // change_log + change_log_field (shipped verbatim; dedup by uuid on
    // import).
    final changeLogRows = (await _db.select(_db.changeLog).get())
        .map((r) => r.toJson(serializer: _serializer))
        .toList();
    archive.addFile(_jsonlFile('change_log.jsonl', changeLogRows));

    final fieldRows = (await _db.select(_db.changeLogField).get())
        .map((r) => r.toJson(serializer: _serializer))
        .toList();
    archive.addFile(_jsonlFile('change_log_field.jsonl', fieldRows));

    // Asset files: read from the app's documents directory and add them
    // under `assets/<relative path>`.
    var assetCount = 0;
    Directory? baseDir;
    try {
      baseDir = await _assetsBaseDirResolver();
    } catch (e) {
      _log.warning('assets base dir unavailable, skipping asset files: $e');
    }
    if (baseDir != null) {
      if (includeDocumentationFiles) {
        final paths = (await _db.customSelect(
          'SELECT DISTINCT file_name FROM documentation_files '
          'WHERE deleted_at IS NULL',
        ).get())
            .map((r) => r.read<String>('file_name'))
            .toList();
        assetCount += await _addAssetsToArchive(archive, baseDir.path, paths);
      }
      if (includeRasterMaps) {
        final paths = (await _db.customSelect(
          'SELECT DISTINCT file_name FROM raster_maps '
          'WHERE deleted_at IS NULL',
        ).get())
            .map((r) => r.read<String>('file_name'))
            .toList();
        assetCount += await _addAssetsToArchive(archive, baseDir.path, paths);
      }
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final manifest = <String, dynamic>{
      'format': 'speleo_loc_sync',
      'format_version': kSyncArchiveVersion,
      'schema_version': kSyncArchiveDbSchemaVersion,
      'exported_at': nowMs,
      'tables': tables.map((t) => t.name).toList(),
      'includes_documentation_files': includeDocumentationFiles,
      'includes_raster_maps': includeRasterMaps,
      'asset_count': assetCount,
    };
    archive.addFile(
      ArchiveFile.string(
        'manifest.json',
        const JsonEncoder.withIndent('  ').convert(manifest),
      ),
    );

    final dir = Directory(outputDir);
    if (!await dir.exists()) await dir.create(recursive: true);
    final name = filenameHint ?? 'speleo_loc_sync_$nowMs.zip';
    final out = File('${dir.path}${Platform.pathSeparator}$name');
    final encoded = ZipEncoder().encode(archive)!;
    await out.writeAsBytes(encoded, flush: true);
    _log.info('Sync archive exported: ${out.path} '
        '(${encoded.length} bytes, ${tables.length} tables, '
        '${changeLogRows.length} change-log entries, '
        '$assetCount asset files)');
    return out;
  }

  // ---------------------------------------------------------------------------
  //  IMPORT
  // ---------------------------------------------------------------------------

  /// Replays an archive produced by [exportToZip] into the local database
  /// using last-writer-wins semantics.
  Future<SyncImportReport> importFromZip(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      throw const FormatException('Archive missing manifest.json');
    }
    final manifest = jsonDecode(
      utf8.decode(manifestFile.content as List<int>),
    ) as Map<String, dynamic>;
    if (manifest['format'] != 'speleo_loc_sync') {
      throw FormatException('Unrecognized archive format: ${manifest['format']}');
    }
    final archiveSchema = manifest['schema_version'];
    if (archiveSchema != kSyncArchiveDbSchemaVersion) {
      throw FormatException(
        'Schema version mismatch: archive=$archiveSchema, '
        'local=$kSyncArchiveDbSchemaVersion',
      );
    }

    var inserted = 0;
    var updated = 0;
    var skipped = 0;
    var deletesApplied = 0;
    var changeLogMerged = 0;
    var filesCopied = 0;
    var filesSkipped = 0;
    final warnings = <String>[];

    await _logger.runSuspended(() async {
      await _db.transaction(() async {
        // Defer FK checks to the end of the transaction so we can insert
        // in any order without hitting transient constraint violations.
        await _db.customStatement('PRAGMA defer_foreign_keys = ON');

        for (final t in _syncedTables()) {
          final entry = archive.findFile('tables/${t.name}.jsonl');
          if (entry == null) {
            warnings.add('archive missing tables/${t.name}.jsonl');
            continue;
          }
          final rows = _readJsonl(entry);
          final result = await t.upsert(rows);
          inserted += result.inserted;
          updated += result.updated;
          skipped += result.skipped;
        }

        // Merge change_log headers first (FK parent) then fields.
        final logEntry = archive.findFile('change_log.jsonl');
        final existingLogUuids = <String>{};
        for (final r in await _db.select(_db.changeLog).get()) {
          existingLogUuids.add(r.uuid.toString());
        }
        final deleteTargets = <String, int>{}; // uuid-string -> changed_at

        if (logEntry != null) {
          final logRows = _readJsonl(logEntry);
          for (final row in logRows) {
            final uuidStr = row['uuid'] as String;
            if (existingLogUuids.contains(uuidStr)) continue;
            final data =
                ChangeLogData.fromJson(row, serializer: _serializer);
            await _db.into(_db.changeLog).insert(data);
            existingLogUuids.add(uuidStr);
            changeLogMerged++;
            if (data.changeType == ChangeType.delete) {
              deleteTargets[data.entityUuid.toString()] = data.changedAt;
            }
          }
        }

        final fieldEntry = archive.findFile('change_log_field.jsonl');
        if (fieldEntry != null) {
          final rows = _readJsonl(fieldEntry);
          for (final row in rows) {
            try {
              final data =
                  ChangeLogFieldData.fromJson(row, serializer: _serializer);
              await _db.into(_db.changeLogField).insert(
                    data,
                    mode: InsertMode.insertOrIgnore,
                  );
            } catch (e) {
              warnings.add('change_log_field: $e');
            }
          }
        }

        // Apply delete tombstones: for every delete entry in the archive,
        // remove the corresponding row from its table locally if the
        // delete was more recent than the local row's updated_at.
        if (deleteTargets.isNotEmpty) {
          deletesApplied +=
              await _applyDeletes(deleteTargets, warnings);
        }
      });
    });

    // Extract asset files outside the DB transaction (filesystem IO
    // shouldn't be tied to the transaction's lifetime).
    final assetResult = await _extractAssets(archive, warnings);
    filesCopied = assetResult.copied;
    filesSkipped = assetResult.skipped;

    return SyncImportReport(
      rowsInserted: inserted,
      rowsUpdated: updated,
      rowsSkipped: skipped,
      deletesApplied: deletesApplied,
      changeLogMerged: changeLogMerged,
      filesCopied: filesCopied,
      filesSkipped: filesSkipped,
      warnings: warnings,
    );
  }

  /// For each (entityUuid -> deleteTs) mapping, delete the row from whichever
  /// synced table still holds it iff its updated_at/created_at is older than
  /// the tombstone. Returns the number of rows physically removed.
  Future<int> _applyDeletes(
    Map<String, int> deleteTargets,
    List<String> warnings,
  ) async {
    var n = 0;
    // Brute-force scan each synced table. The dataset is small enough
    // that this is simpler than tracking entity_table per tombstone.
    // We rely on the caller holding a transaction.
    final tables = <(String, Future<int> Function(Uuid, int))>[
      (
        'users',
        (u, ts) async => _deleteIfOlder(_db.users, u, ts),
      ),
      (
        'cave_place_to_raster_map_definitions',
        (u, ts) async => _deleteIfOlder(
          _db.cavePlaceToRasterMapDefinitions,
          u,
          ts,
        ),
      ),
      (
        'documentation_files_to_geofeatures',
        (u, ts) async =>
            _deleteIfOlder(_db.documentationFilesToGeofeatures, u, ts),
      ),
      (
        'documentation_files_to_cave_trips',
        (u, ts) async =>
            _deleteIfOlder(_db.documentationFilesToCaveTrips, u, ts),
      ),
      (
        'cave_trip_points',
        (u, ts) async => _deleteIfOlder(_db.caveTripPoints, u, ts),
      ),
      (
        'cave_trips',
        (u, ts) async => _deleteIfOlder(_db.caveTrips, u, ts),
      ),
      (
        'documentation_files',
        (u, ts) async => _deleteIfOlder(_db.documentationFiles, u, ts),
      ),
      (
        'trip_report_templates',
        (u, ts) async => _deleteIfOlder(_db.tripReportTemplates, u, ts),
      ),
      (
        'raster_maps',
        (u, ts) async => _deleteIfOlder(_db.rasterMaps, u, ts),
      ),
      (
        'cave_places',
        (u, ts) async => _deleteIfOlder(_db.cavePlaces, u, ts),
      ),
      (
        'cave_areas',
        (u, ts) async => _deleteIfOlder(_db.caveAreas, u, ts),
      ),
      (
        'caves',
        (u, ts) async => _deleteIfOlder(_db.caves, u, ts),
      ),
      (
        'surface_areas',
        (u, ts) async => _deleteIfOlder(_db.surfaceAreas, u, ts),
      ),
    ];

    for (final entry in deleteTargets.entries) {
      final uuid = Uuid.parse(entry.key);
      final ts = entry.value;
      for (final (_, delete) in tables) {
        try {
          n += await delete(uuid, ts);
        } catch (e) {
          warnings.add('delete ${entry.key}: $e');
        }
      }
    }
    return n;
  }

  Future<int> _deleteIfOlder(
    TableInfo table,
    Uuid entityUuid,
    int tombstoneTs,
  ) async {
    // We can't read `updated_at` generically, so use a custom statement.
    final countRows = await _db.customSelect(
      'SELECT COALESCE(updated_at, created_at, 0) AS ts '
      'FROM ${table.actualTableName} WHERE uuid = ?',
      variables: [Variable<Uint8List>(entityUuid.bytes)],
    ).get();
    if (countRows.isEmpty) return 0;
    final localTs = countRows.first.read<int>('ts');
    if (tombstoneTs < localTs) return 0; // local is newer
    await _db.customStatement(
      'DELETE FROM ${table.actualTableName} WHERE uuid = ?',
      [entityUuid.bytes],
    );
    return 1;
  }

  // ---------------------------------------------------------------------------
  //  helpers
  // ---------------------------------------------------------------------------

  /// Upserts incoming rows with LWW semantics. Returns per-row counters.
  Future<_UpsertCounters> _upsertRows<D extends Insertable<D>>(
    List<Map<String, dynamic>> rows,
    D Function(Map<String, dynamic>) fromJson,
    Uuid Function(D) uuidOf,
    int? Function(D) tsOf,
    TableInfo<Table, D> table,
  ) async {
    var inserted = 0;
    var updated = 0;
    var skipped = 0;

    for (final raw in rows) {
      final D incoming;
      try {
        incoming = fromJson(raw);
      } catch (e) {
        _log.warning('skipping malformed ${table.actualTableName} row: $e');
        continue;
      }
      final uuid = uuidOf(incoming);
      final incomingTs = tsOf(incoming) ?? 0;

      final localTsRows = await _db.customSelect(
        'SELECT COALESCE(updated_at, created_at, 0) AS ts '
        'FROM ${table.actualTableName} WHERE uuid = ?',
        variables: [Variable<Uint8List>(uuid.bytes)],
      ).get();

      if (localTsRows.isEmpty) {
        await _db.into(table).insert(incoming);
        inserted++;
      } else {
        final localTs = localTsRows.first.read<int>('ts');
        if (incomingTs > localTs) {
          await _db.into(table).insert(
                incoming,
                mode: InsertMode.insertOrReplace,
              );
          updated++;
        } else {
          skipped++;
        }
      }
    }

    return _UpsertCounters(
      inserted: inserted,
      updated: updated,
      skipped: skipped,
    );
  }

  ArchiveFile _jsonlFile(String name, List<Map<String, dynamic>> rows) {
    final buf = StringBuffer();
    for (final r in rows) {
      buf.writeln(jsonEncode(r));
    }
    final bytes = utf8.encode(buf.toString());
    return ArchiveFile(name, bytes.length, bytes);
  }

  List<Map<String, dynamic>> _readJsonl(ArchiveFile file) {
    final content = utf8.decode(file.content as List<int>);
    final out = <Map<String, dynamic>>[];
    for (final line in const LineSplitter().convert(content)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      out.add(jsonDecode(trimmed) as Map<String, dynamic>);
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  //  Asset file helpers
  // ---------------------------------------------------------------------------

  /// Add [relativePaths] (relative to [baseDir]) into [archive] under the
  /// `assets/` prefix. Returns the number of files actually added.
  Future<int> _addAssetsToArchive(
    Archive archive,
    String baseDir,
    List<String> relativePaths,
  ) async {
    var added = 0;
    final seen = <String>{};
    for (final relPath in relativePaths) {
      if (relPath.isEmpty) continue;
      if (!seen.add(relPath)) continue;
      final file = File('$baseDir${Platform.pathSeparator}$relPath');
      if (!await file.exists()) {
        _log.fine('asset missing on disk, skipping: $relPath');
        continue;
      }
      final bytes = await file.readAsBytes();
      final normalized = relPath.replaceAll('\\', '/');
      archive.addFile(
        ArchiveFile('$_assetsPrefix$normalized', bytes.length, bytes),
      );
      added++;
    }
    return added;
  }

  /// Walk every `assets/*` entry in [archive] and copy it into the local
  /// documents directory. Existing local files are preserved (LWW on
  /// content: assume last export wins only for DB rows; filesystem assets
  /// are treated as immutable-per-name).
  Future<_AssetResult> _extractAssets(
    Archive archive,
    List<String> warnings,
  ) async {
    Directory baseDir;
    try {
      baseDir = await _assetsBaseDirResolver();
    } catch (e) {
      warnings.add('assets base dir unavailable: $e');
      return const _AssetResult(copied: 0, skipped: 0);
    }
    var copied = 0;
    var skipped = 0;
    for (final entry in archive) {
      if (!entry.isFile) continue;
      if (!entry.name.startsWith(_assetsPrefix)) continue;
      final relPath = entry.name
          .substring(_assetsPrefix.length)
          .replaceAll('/', Platform.pathSeparator);
      if (relPath.isEmpty) continue;
      final dest = File('${baseDir.path}${Platform.pathSeparator}$relPath');
      try {
        if (await dest.exists()) {
          skipped++;
          continue;
        }
        await dest.parent.create(recursive: true);
        await dest.writeAsBytes(entry.content as List<int>, flush: true);
        copied++;
      } catch (e) {
        warnings.add('copy ${entry.name}: $e');
      }
    }
    return _AssetResult(copied: copied, skipped: skipped);
  }
}

class _AssetResult {
  final int copied;
  final int skipped;
  const _AssetResult({required this.copied, required this.skipped});
}

class _UpsertCounters {
  final int inserted;
  final int updated;
  final int skipped;
  const _UpsertCounters({
    required this.inserted,
    required this.updated,
    required this.skipped,
  });
}

class _SyncTable {
  final String name;
  final Future<List<Map<String, dynamic>>> Function() dump;
  final Future<_UpsertCounters> Function(List<Map<String, dynamic>>) upsert;
  _SyncTable({required this.name, required this.dump, required this.upsert});
}
