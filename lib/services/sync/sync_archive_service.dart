import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/archive/archive_extraction.dart';
import 'package:speleoloc/services/archive/zip_file_writer.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_map_picture_copies.dart';
import 'package:speleoloc/services/sync/sync_merge_engine.dart';
import 'package:speleoloc/services/sync/sync_serializer.dart';
import 'package:speleoloc/services/sync/sync_table_handler.dart';
import 'package:speleoloc/services/sync/sync_table_registry.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/clock.dart';
import 'package:speleoloc/utils/contained_path.dart';
import 'package:sqlite3/sqlite3.dart' show OpenMode, sqlite3;

/// Current on-disk sync archive format version. Bump when the layout
/// changes in a non-backwards-compatible way.
///
/// v2: asset files (documentation_files, raster_maps) are shipped inside
///     the zip under `assets/<relative path>` mirroring the app's
///     documents directory layout.
/// v3: manifest gains `app_version`/`app_build_number` so import errors
///     can tell the user the minimum app version required.
/// v4: adds `tables/configurations.jsonl` (the is_synced=1 rows), stamps
///     the true DB schema version (15) with a backward-compatible import
///     range, and hardens delete/LWW merge semantics. Older archives lack
///     the configurations entry and its absence is tolerated on import, so
///     v3 archives still merge into a v4 reader.
const int kSyncArchiveVersion = 4;

/// The database schema version whose archived tables an exported archive
/// carries, written to the manifest as `schema_version`.
///
/// It is the schema version at which an archived table — one in
/// [SyncTableRegistry], or `change_log` / `change_log_field` — last changed
/// its columns, not [AppDatabase.schemaVersion]. A schema bump that touches
/// only local-only tables, indexes or stored values leaves it where it is, so
/// phones that have not updated yet keep importing this device's archives.
/// The change that alters an archived table's columns moves it to that
/// change's schema version; a guard test compares those columns with a
/// snapshot recorded for this value and fails until both move together.
///
/// History: frozen at 9 while the schema went to 15, then kept equal to the
/// schema version up to 34, so archives in the wild carry 9 to 34;
/// development builds also wrote 35 and 36 over the same archived tables.
const int kSyncArchiveDbSchemaVersion = 34;

/// Oldest archive `schema_version` this app still imports. The sync-v2
/// format has only ever emitted `schema_version >= 9`, and every archived
/// layout since 9 is additively compatible on read (columns added since are
/// nullable or defaulted when absent, and unknown tables are ignored), so
/// archives from there on merge safely.
///
/// The newest one it imports is its own [AppDatabase.schemaVersion]: an
/// archive is never stamped above the schema of the app that wrote it, so a
/// stamp up to ours names archived tables this app already knows — including
/// the stamps above [kSyncArchiveDbSchemaVersion] that development builds
/// wrote. A higher stamp comes from an app whose archived tables changed
/// after this one was built, and is refused as too new rather than
/// silently mis-merged.
const int kSyncArchiveMinImportSchemaVersion = 9;

/// Result of an import operation.
class SyncImportReport {
  final int rowsInserted;
  final int rowsUpdated;
  final int rowsSkipped; // local copy already newer, or not brought in
  final int deletesApplied;
  final int changeLogMerged;
  final int filesCopied;
  final int filesSkipped; // already present locally

  /// Asset files the archive carries that could not be written on this
  /// device (disk full, extraction failure). Their rows are imported, so a
  /// caller that wants the files must import the archive again.
  final int filesFailed;

  /// Records waiting, after this import, for a person to decide about: each
  /// a record whose unique name a different record here already holds.
  /// Counts those held by earlier imports too.
  final int decisionsPending;
  final List<String> warnings;

  const SyncImportReport({
    required this.rowsInserted,
    required this.rowsUpdated,
    required this.rowsSkipped,
    required this.deletesApplied,
    required this.changeLogMerged,
    required this.filesCopied,
    required this.filesSkipped,
    this.filesFailed = 0,
    required this.warnings,
    this.decisionsPending = 0,
  });

  /// Returns a copy with the asset-file counts filled in — used by
  /// `importFromZip`, which runs asset extraction after the DB merge.
  SyncImportReport copyWith({
    int? filesCopied,
    int? filesSkipped,
    int? filesFailed,
  }) => SyncImportReport(
    rowsInserted: rowsInserted,
    rowsUpdated: rowsUpdated,
    rowsSkipped: rowsSkipped,
    deletesApplied: deletesApplied,
    changeLogMerged: changeLogMerged,
    filesCopied: filesCopied ?? this.filesCopied,
    filesSkipped: filesSkipped ?? this.filesSkipped,
    filesFailed: filesFailed ?? this.filesFailed,
    warnings: warnings,
    decisionsPending: decisionsPending,
  );

  @override
  String toString() =>
      'SyncImportReport(inserted=$rowsInserted, updated=$rowsUpdated, '
      'skipped=$rowsSkipped, deletes=$deletesApplied, '
      'changeLog=$changeLogMerged, filesCopied=$filesCopied, '
      'filesSkipped=$filesSkipped, filesFailed=$filesFailed, '
      'decisionsPending=$decisionsPending, '
      'warnings=${warnings.length})';
}

/// User (or programmatic) decision when an incoming sync row would overwrite
/// a local row that has been independently modified.
enum SyncConflictAction {
  /// Drop the incoming change; the local row stays intact.
  keepLocal,

  /// Replace the local row with the incoming payload.
  useIncoming,

  /// Abort the whole import (throws [SyncImportCancelledException]).
  cancel,
}

/// Describes a conflict surfaced to a [ConflictResolver].
///
/// Both [localFields] and [incomingFields] are JSON-friendly maps produced
/// via [SyncValueSerializer] (so UUIDs are canonical strings, byte blobs are
/// base64-encoded, etc.). [differingFields] lists only the columns whose
/// values actually differ between the two rows — metadata columns that only
/// reflect who-last-touched the row are excluded so the UI can show the
/// truly meaningful differences first.
class SyncConflict {
  final String tableName;
  final Uuid entityUuid;
  final Map<String, dynamic> localFields;
  final Map<String, dynamic> incomingFields;
  final List<String> differingFields;
  final int? localUpdatedAt;
  final int? incomingUpdatedAt;

  const SyncConflict({
    required this.tableName,
    required this.entityUuid,
    required this.localFields,
    required this.incomingFields,
    required this.differingFields,
    required this.localUpdatedAt,
    required this.incomingUpdatedAt,
  });
}

/// Callback that decides how a single [SyncConflict] should be resolved.
///
/// Return `null` to fall back to the default last-writer-wins behaviour.
typedef ConflictResolver = Future<SyncConflictAction?> Function(SyncConflict);

/// Thrown when the user (or a resolver) cancels an in-progress import.
class SyncImportCancelledException implements Exception {
  final String message;
  const SyncImportCancelledException([this.message = 'Import cancelled']);
  @override
  String toString() => 'SyncImportCancelledException: $message';
}

/// Thrown by [SyncArchiveService.importFromZip] with `holdBackDeletions`
/// when the archive would delete rows on this device. Nothing was changed;
/// [preview] holds the counts the import would have produced.
class SyncImportHasDeletionsException implements Exception {
  const SyncImportHasDeletionsException(this.preview);
  final SyncImportReport preview;

  @override
  String toString() =>
      'SyncImportHasDeletionsException: the archive would delete '
      '${preview.deletesApplied} row(s)';
}

/// Rolls back the outer transaction of a held-back import.
class _DeletionsHeldBack implements Exception {
  const _DeletionsHeldBack();
}

/// Thrown by [SyncArchiveService.importFromZip] when the archive's database
/// schema version does not match the running app's. Carries enough metadata
/// to render an actionable message:
///
/// - [archiveSchemaVersion] / [localSchemaVersion]: numeric comparison.
/// - [archiveAppVersion] / [archiveAppBuildNumber]: the app version that
///   produced the archive (when available — older archives may be missing
///   this field, in which case it stays `null`).
/// - [tooNew]: `true` when the archive was made by a newer app/schema than
///   the running app; the user must update. `false` for the opposite case.
class SyncArchiveSchemaMismatchException implements Exception {
  final int archiveSchemaVersion;
  final int localSchemaVersion;
  final String? archiveAppVersion;
  final String? archiveAppBuildNumber;
  final bool tooNew;

  const SyncArchiveSchemaMismatchException({
    required this.archiveSchemaVersion,
    required this.localSchemaVersion,
    required this.archiveAppVersion,
    required this.archiveAppBuildNumber,
    required this.tooNew,
  });

  @override
  String toString() {
    final direction = tooNew ? 'newer' : 'older';
    final buildSuffix = archiveAppBuildNumber == null
        ? ''
        : '+$archiveAppBuildNumber';
    final ver = archiveAppVersion == null
        ? '(unknown app version)'
        : 'v$archiveAppVersion$buildSuffix';
    if (tooNew) {
      return 'SyncArchiveSchemaMismatchException: archive was produced by a '
          '$direction version of the app ($ver, schema '
          '$archiveSchemaVersion). Local schema is $localSchemaVersion. '
          'Update the application to $ver or newer to import this archive.';
    }
    return 'SyncArchiveSchemaMismatchException: archive schema '
        '$archiveSchemaVersion is older than local schema '
        '$localSchemaVersion. Cross-version migration is not implemented; '
        're-export from the source device with an up-to-date app.';
  }
}

/// Offline archive-based sync across devices.
///
/// Export produces a `.zip` containing, in addition to a small manifest,
/// one JSONL file per synced table plus the `change_log` / `change_log_field`
/// rows. Import hands those rows to [SyncMergeEngine], which replays them
/// with a last-writer-wins policy keyed on `updated_at` (falling back to
/// `created_at`), applies the deletions the change log carries, and holds for
/// a decision what it cannot merge on its own.
class SyncArchiveService {
  SyncArchiveService(
    this._db,
    ChangeLogger logger, {
    Future<Directory> Function()? assetsBaseDirResolver,
    Clock clock = const SystemClock(),
  }) : _assetsBaseDirResolver =
           assetsBaseDirResolver ?? getApplicationDocumentsDirectory,
       _clock = clock,
       _registry = SyncTableRegistry(_db),
       _engine = SyncMergeEngine(_db, logger);

  final AppDatabase _db;
  final Future<Directory> Function() _assetsBaseDirResolver;
  final Clock _clock;
  final SyncTableRegistry _registry;
  final SyncMergeEngine _engine;
  final _log = AppLogger.of('SyncArchiveService');

  static const _serializer = SyncValueSerializer();
  static const _assetsPrefix = 'assets/';
  static const _manifestEntry = 'manifest.json';
  static const _changeLogEntry = 'change_log.jsonl';
  static const _changeLogFieldEntry = 'change_log_field.jsonl';
  static String _tableEntry(String table) => 'tables/$table.jsonl';

  /// Ordered list of synced tables — delegates to [SyncTableRegistry] so
  /// the big table-handler list lives in one place.
  List<SyncTableHandler> _syncedTables() => _registry.tables();

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
    final tables = _syncedTables();

    // Everything that needs the database runs here on the main isolate: dump
    // each table and the change log to JSONL byte blobs, and resolve the
    // asset file paths. The zip is then written on a background isolate, each
    // asset streamed from its file, so a large export neither blocks the UI
    // nor holds a photo or video in memory.
    // The asset folder comes from a platform channel, so it is resolved
    // before the snapshot is opened rather than while it holds the database.
    Directory? baseDir;
    try {
      baseDir = await _assetsBaseDirResolver();
    } catch (e) {
      _log.warning('assets base dir unavailable, skipping asset files: $e');
    }

    // Every read below runs in one transaction, so the archive is a single
    // snapshot. Read table by table on the live database, an edit made while
    // the export runs could leave a row in the archive without the row it
    // hangs on, or a row alive beside its own delete entry; a peer then drops
    // that entry as stale and the deletion never reaches it.
    final (jsonlEntries, changeLogCount, assetRelPaths) = await _db.transaction(
      () => _readSnapshot(
        tables,
        baseDir,
        includeDocumentationFiles: includeDocumentationFiles,
        includeRasterMaps: includeRasterMaps,
      ),
    );

    final nowMs = _clock.nowMs();
    final pkgInfo = await _safeReadPackageInfo();
    final assets = await _assetEntries(baseDir, assetRelPaths);
    final manifest = <String, dynamic>{
      'format': 'speleo_loc_sync',
      'format_version': kSyncArchiveVersion,
      'schema_version': kSyncArchiveDbSchemaVersion,
      'app_version': pkgInfo?.version,
      'app_build_number': pkgInfo?.buildNumber,
      'exported_at': nowMs,
      'tables': tables.map((t) => t.name).toList(),
      'includes_documentation_files': includeDocumentationFiles,
      'includes_raster_maps': includeRasterMaps,
      'asset_count': assets.length,
    };

    final dir = Directory(outputDir);
    if (!await dir.exists()) await dir.create(recursive: true);
    final name = filenameHint ?? 'speleo_loc_sync_$nowMs.zip';
    final out = File('${dir.path}${Platform.pathSeparator}$name');

    await writeZipFile(out.path, [
      for (final (entryName, bytes) in jsonlEntries)
        ZipEntrySource.bytes(entryName, bytes),
      ...assets,
      ZipEntrySource.bytes(
        _manifestEntry,
        utf8.encode(const JsonEncoder.withIndent('  ').convert(manifest)),
      ),
    ]);

    final size = await out.length();
    _log.info(
      'Sync archive exported: ${out.path} '
      '($size bytes, ${tables.length} tables, '
      '$changeLogCount change-log entries, '
      '${assets.length} asset files)',
    );
    return out;
  }

  /// Reads everything an archive carries: each table and the change log as
  /// JSONL bytes, how many change-log rows went in, and the relative paths of
  /// the asset files to bundle. Run inside one transaction by [exportToZip].
  Future<(List<(String, Uint8List)>, int, List<String>)> _readSnapshot(
    List<SyncTableHandler> tables,
    Directory? baseDir, {
    required bool includeDocumentationFiles,
    required bool includeRasterMaps,
  }) async {
    final jsonlEntries = <(String, Uint8List)>[];
    for (final t in tables) {
      jsonlEntries.add(('tables/${t.name}.jsonl', _jsonlBytes(await t.dump())));
    }

    // change_log + change_log_field (shipped verbatim; dedup by uuid on
    // import). A server copy that stays here keeps its history here too: its
    // removal, replayed on another device, would remove that device's own
    // file of the same identifier. So does a map showing such a copy, with
    // its pins.
    final serverOnly = await SilexgisFileCopyRepository(_db).serverOnlyCopies();
    final serverOnlyMaps = await SilexgisMapPictureCopies(
      _db,
    ).serverOnlyPictures();
    final serverOnlyPins = <Uuid>{
      for (final pin
          in await _db.select(_db.cavePlaceToRasterMapDefinitions).get())
        if (serverOnlyMaps.containsKey(pin.rasterMapUuid)) pin.uuid,
    };
    bool staysHere(ChangeLogData r) => switch (r.entityTable) {
      'documentation_files' => serverOnly.contains(r.entityUuid),
      'raster_maps' => serverOnlyMaps.containsKey(r.entityUuid),
      'cave_place_to_raster_map_definitions' => serverOnlyPins.contains(
        r.entityUuid,
      ),
      _ => false,
    };
    final keptLog = (await _db.select(_db.changeLog).get())
        .where((r) => !staysHere(r))
        .toList();
    final keptLogIds = <Uuid>{for (final r in keptLog) r.uuid};
    final changeLogRows = keptLog
        .map((r) => r.toJson(serializer: _serializer))
        .toList();
    jsonlEntries.add(('change_log.jsonl', _jsonlBytes(changeLogRows)));

    final fieldRows = (await _db.select(_db.changeLogField).get())
        .where((r) => keptLogIds.contains(r.changeUuid))
        .map((r) => r.toJson(serializer: _serializer))
        .toList();
    jsonlEntries.add(('change_log_field.jsonl', _jsonlBytes(fieldRows)));

    // Resolve the asset relative paths; the zip writer reads the files
    // itself.
    final assetRelPaths = <String>[];
    if (baseDir != null) {
      final serverOnlyKinds = <String>[
        for (final kind in SilexgisHeldAs.serverOnlyCopies) kind.wireName,
      ];
      if (includeDocumentationFiles) {
        assetRelPaths.addAll(
          (await _db
                  .customSelect(
                    // By file name as well as by row: another device's row
                    // naming a server copy's file must not carry it off.
                    'SELECT DISTINCT file_name FROM documentation_files '
                    'WHERE deleted_at IS NULL AND file_name NOT IN ('
                    'SELECT d.file_name FROM documentation_files d '
                    'JOIN silexgis_file_copy c ON c.document_uuid = d.uuid '
                    'WHERE c.held_as IN (${_placeholders(serverOnlyKinds)}))',
                    variables: <Variable<Object>>[
                      for (final kind in serverOnlyKinds) Variable(kind),
                    ],
                  )
                  .get())
              .map((r) => r.read<String>('file_name')),
        );
      }
      if (includeRasterMaps) {
        final local = <String>{
          for (final map
              in await (_db.select(_db.rasterMaps)..where(
                    (t) => t.uuid.isIn(serverOnlyMaps.keys.map((u) => u.bytes)),
                  ))
                  .get())
            map.fileName,
        };
        assetRelPaths.addAll(
          (await _db
                  .customSelect(
                    'SELECT DISTINCT file_name FROM raster_maps '
                    'WHERE deleted_at IS NULL',
                  )
                  .get())
              .map((r) => r.read<String>('file_name'))
              .where((name) => !local.contains(name)),
        );
      }
      // File names arrive in rows from other devices; one naming a place
      // outside the documents folder, or the database itself, would
      // otherwise be read and uploaded.
      final contained = <String>[];
      for (final relPath in assetRelPaths) {
        if (relPath.isEmpty ||
            containedDocumentsPath(baseDir.path, relPath) != null) {
          contained.add(relPath);
        } else {
          _log.warning(
            'not exporting a file named outside the documents folder or '
            'as the database: '
            '$relPath',
          );
        }
      }
      assetRelPaths
        ..clear()
        ..addAll(contained);
    }
    return (jsonlEntries, changeLogRows.length, assetRelPaths);
  }

  /// The zip entries of the asset files to bundle, each once, that are on
  /// disk now. Checked before the zip is written so the manifest can count
  /// them; a file removed in between is left out of the zip, still counted.
  static Future<List<ZipEntrySource>> _assetEntries(
    Directory? baseDir,
    List<String> relPaths,
  ) async {
    if (baseDir == null) return const [];
    final seen = <String>{};
    final entries = <ZipEntrySource>[];
    for (final relPath in relPaths) {
      if (relPath.isEmpty || !seen.add(relPath)) continue;
      final file = File('${baseDir.path}${Platform.pathSeparator}$relPath');
      if (!await file.exists()) continue;
      entries.add(
        ZipEntrySource.file(
          '$_assetsPrefix${relPath.replaceAll('\\', '/')}',
          file.path,
        ),
      );
    }
    return entries;
  }

  static String _placeholders(List<Object> values) =>
      List<String>.filled(values.length, '?').join(', ');

  // ---------------------------------------------------------------------------
  //  IMPORT
  // ---------------------------------------------------------------------------

  /// Replays an archive produced by [exportToZip] into the local database
  /// using last-writer-wins semantics.
  ///
  /// When a [conflictResolver] is provided, each incoming row that would
  /// overwrite a local row with at least one meaningfully-different field
  /// is routed through it. If the resolver returns
  /// [SyncConflictAction.cancel], the whole import is rolled back and
  /// [SyncImportCancelledException] is thrown. Returning `null` from the
  /// resolver falls back to the default LWW decision.
  ///
  /// With [holdBackDeletions], an import that would delete rows on this
  /// device is rolled back before any file is written and
  /// [SyncImportHasDeletionsException] is thrown with what it would have
  /// done, so the user can be asked first; importing again without it
  /// applies the deletions.
  Future<SyncImportReport> importFromZip(
    String zipPath, {
    ConflictResolver? conflictResolver,
    bool holdBackDeletions = false,
  }) async {
    // Read through a file stream on a background isolate: only the manifest
    // and the table dumps come into memory, and the asset entries are later
    // copied or inflated to disk in chunks, so an archive carrying large
    // photos or videos neither blocks the UI nor costs their size in memory.
    final (:fileNames, :contents) = await readZipEntries(zipPath, {
      _manifestEntry,
      _changeLogEntry,
      _changeLogFieldEntry,
      for (final t in _syncedTables()) _tableEntry(t.name),
    });
    if (!contents.containsKey(_manifestEntry)) {
      await _logMissingManifest(zipPath, fileNames.length);
    }

    // Phase 1+2: parse the JSONL and merge into the DB. Returns the report
    // (with file counts still zero) plus the names of the `assets/*` entries.
    final (partial, assetEntryNames) = await _mergeArchiveIntoDb(
      fileNames,
      contents,
      conflictResolver,
      zipPath,
      holdBackDeletions: holdBackDeletions,
    );

    final assetResult = await _extractAssets(
      assetEntryNames,
      zipPath,
      partial.warnings,
    );
    return partial.copyWith(
      filesCopied: assetResult.copied,
      filesSkipped: assetResult.skipped,
      filesFailed: assetResult.failed,
    );
  }

  /// Merges a whole database file — the `speleo_loc.sqlite` inside a full
  /// data export — into the local database with the same last-writer-wins
  /// rules as [importFromZip]. Asset files are not touched.
  ///
  /// The file is opened and migrated in place, so an export made by an older
  /// app is read in the current schema; pass a copy that may be modified.
  /// One made by a newer app is refused with
  /// [SyncArchiveSchemaMismatchException], since its rows cannot be read
  /// faithfully.
  Future<SyncImportReport> importFromDatabaseFile(
    File dbFile, {
    ConflictResolver? conflictResolver,
  }) async {
    final fileSchema = _readSchemaVersion(dbFile);
    if (fileSchema > _db.schemaVersion) {
      throw SyncArchiveSchemaMismatchException(
        archiveSchemaVersion: fileSchema,
        localSchemaVersion: _db.schemaVersion,
        archiveAppVersion: null,
        archiveAppBuildNumber: null,
        tooNew: true,
      );
    }

    final source = AppDatabase.file(dbFile);
    try {
      final tableRows = <String, List<Map<String, dynamic>>>{
        for (final t in SyncTableRegistry(source).tables())
          t.name: await t.dump(),
      };
      final logRows = (await source.select(source.changeLog).get())
          .map((r) => r.toJson(serializer: _serializer))
          .toList();
      final fieldRows = (await source.select(source.changeLogField).get())
          .map((r) => r.toJson(serializer: _serializer))
          .toList();
      return await _engine.merge(
        tableRows: tableRows,
        logRows: logRows,
        fieldRows: fieldRows,
        conflictResolver: conflictResolver,
        warnings: <String>[],
      );
    } finally {
      await source.close();
    }
  }

  int _readSchemaVersion(File dbFile) {
    final raw = sqlite3.open(dbFile.path, mode: OpenMode.readOnly);
    try {
      return raw.userVersion;
    } finally {
      raw.close();
    }
  }

  /// Logs what a zip without a manifest looks like, for telling a truncated
  /// or corrupted transfer from a file that is no archive at all: its size,
  /// where the end-of-central-directory signature appears, and its first and
  /// last bytes. Read in chunks, so even a large file costs no memory.
  Future<void> _logMissingManifest(String zipPath, int entryCount) async {
    try {
      final file = await File(zipPath).open();
      try {
        final size = await file.length();
        final head = await file.read(16);
        await file.setPosition(size < 32 ? 0 : size - 32);
        final tail = await file.read(32);
        final eocdOffsets = await _findEocdOffsets(file, size);
        _log.severe(
          'decode of $zipPath ($size bytes) yielded $entryCount entries '
          'without manifest.json. eocd_offsets=$eocdOffsets, '
          'head=${_hex(head)}, tail=${_hex(tail)}',
        );
      } finally {
        await file.close();
      }
    } catch (e, st) {
      _log.warning('could not inspect $zipPath', e, st);
    }
  }

  /// Every byte offset, up to eight, where the 4-byte zip End-Of-Central-
  /// Directory signature (0x06054b50, little-endian "PK\x05\x06") appears.
  /// A healthy zip has exactly one near the end.
  static Future<List<int>> _findEocdOffsets(
    RandomAccessFile file,
    int size,
  ) async {
    const sig = [0x50, 0x4b, 0x05, 0x06];
    const chunk = 1 << 20;
    final hits = <int>[];
    for (var start = 0; start < size && hits.length < 8; start += chunk) {
      await file.setPosition(start);
      // Three bytes past the chunk, so a signature across the boundary counts.
      final bytes = await file.read(chunk + sig.length - 1);
      for (var i = 0; i < chunk && i + 3 < bytes.length; i++) {
        if (bytes[i] == sig[0] &&
            bytes[i + 1] == sig[1] &&
            bytes[i + 2] == sig[2] &&
            bytes[i + 3] == sig[3]) {
          hits.add(start + i);
          if (hits.length >= 8) break;
        }
      }
    }
    return hits;
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

  /// Validates the manifest, replays the JSONL into the DB (Phase 1 parse +
  /// Phase 2 transaction), and returns the report (with file counts still
  /// zero) alongside the names of the `assets/*` entries the caller should
  /// extract. [fileNames] lists every file entry of the zip and [contents]
  /// holds the manifest and JSONL entries it carries; each is released once
  /// parsed.
  Future<(SyncImportReport, List<String>)> _mergeArchiveIntoDb(
    List<String> fileNames,
    Map<String, Uint8List> contents,
    ConflictResolver? conflictResolver,
    String zipPath, {
    bool holdBackDeletions = false,
  }) async {
    final manifestBytes = contents.remove(_manifestEntry);
    if (manifestBytes == null) {
      final size = await File(zipPath).length();
      final names = fileNames.take(10).toList(growable: false);
      throw FormatException(
        'Archive missing manifest.json '
        '(file_size=$size bytes, ${fileNames.length} zip entries found'
        '${names.isEmpty ? '' : ', e.g. ${names.join(", ")}'}). '
        'See log for forensic details (EOCD offsets, head/tail bytes).',
      );
    }
    final manifest =
        jsonDecode(utf8.decode(manifestBytes)) as Map<String, dynamic>;
    if (manifest['format'] != 'speleo_loc_sync') {
      throw FormatException(
        'Unrecognized archive format: ${manifest['format']}',
      );
    }
    final archiveSchema = manifest['schema_version'];
    if (archiveSchema is! int) {
      throw const FormatException(
        'Archive manifest is missing or has an invalid schema_version',
      );
    }
    // Accept any schema in the supported range; the JSONL format is
    // additively compatible across it. Refuse only archives from a newer
    // app (schema above ours) or implausibly old ones below the floor.
    final newestImportable = _db.schemaVersion;
    if (archiveSchema > newestImportable ||
        archiveSchema < kSyncArchiveMinImportSchemaVersion) {
      throw SyncArchiveSchemaMismatchException(
        archiveSchemaVersion: archiveSchema,
        localSchemaVersion: newestImportable,
        archiveAppVersion: manifest['app_version'] as String?,
        archiveAppBuildNumber: manifest['app_build_number'] as String?,
        tooNew: archiveSchema > newestImportable,
      );
    }

    final warnings = <String>[];

    // ── Phase 1: pre-parse all JSONL data outside the DB transaction ──────
    // Inflating lazy zip entries and decoding JSON are CPU-bound synchronous
    // operations.  Running them inside the DB transaction (as before) blocked
    // the Dart UI isolate long enough to trigger Android ANR on larger
    // archives.  We now inflate + parse each table file in turn, yielding to
    // the Flutter engine between tables so it can process frames and input
    // events.  The transaction itself then contains only async DB awaits.
    final tableRows = <String, List<Map<String, dynamic>>>{};
    for (final t in _syncedTables()) {
      // Yield to the event loop before inflating each (potentially large)
      // zip entry so the Flutter engine can process frames / input between
      // table parses.
      await Future.delayed(Duration.zero);
      final name = _tableEntry(t.name);
      final bytes = contents.remove(name);
      if (bytes == null) {
        warnings.add('archive missing $name');
        continue;
      }
      tableRows[t.name] = _readJsonl(name, bytes);
    }

    await Future.delayed(Duration.zero);
    final logBytes = contents.remove(_changeLogEntry);
    final logRows = logBytes != null
        ? _readJsonl(_changeLogEntry, logBytes)
        : <Map<String, dynamic>>[];

    await Future.delayed(Duration.zero);
    final fieldBytes = contents.remove(_changeLogFieldEntry);
    final fieldRows = fieldBytes != null
        ? _readJsonl(_changeLogFieldEntry, fieldBytes)
        : <Map<String, dynamic>>[];

    Future<SyncImportReport> merge() => _engine.merge(
      tableRows: tableRows,
      logRows: logRows,
      fieldRows: fieldRows,
      conflictResolver: conflictResolver,
      warnings: warnings,
    );
    final report = holdBackDeletions
        ? await _mergeUnlessDeleting(merge)
        : await merge();

    // The asset entries for the caller to extract; file counts are filled
    // in there.
    final assetEntryNames = [
      for (final name in fileNames)
        if (name.startsWith(_assetsPrefix)) name,
    ];

    return (report, assetEntryNames);
  }

  /// Runs [merge] inside an outer transaction, so that a merge that deleted
  /// rows can be undone whole: its own transaction becomes a savepoint, and
  /// throwing here rolls everything back.
  Future<SyncImportReport> _mergeUnlessDeleting(
    Future<SyncImportReport> Function() merge,
  ) async {
    SyncImportReport? report;
    try {
      await _db.transaction(() async {
        final r = report = await merge();
        if (r.deletesApplied > 0) throw const _DeletionsHeldBack();
      });
    } on _DeletionsHeldBack {
      throw SyncImportHasDeletionsException(report!);
    }
    return report!;
  }

  // ---------------------------------------------------------------------------
  //  helpers
  // ---------------------------------------------------------------------------

  Uint8List _jsonlBytes(List<Map<String, dynamic>> rows) {
    final buf = StringBuffer();
    for (final r in rows) {
      buf.writeln(jsonEncode(r));
    }
    return utf8.encode(buf.toString());
  }

  List<Map<String, dynamic>> _readJsonl(String name, Uint8List bytes) {
    final content = utf8.decode(bytes);
    final out = <Map<String, dynamic>>[];
    var lineNo = 0;
    for (final line in const LineSplitter().convert(content)) {
      lineNo++;
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // One malformed line must not sink the whole import: a truncated
      // download or a single corrupt row would otherwise throw straight out
      // of parsing and roll back every table. Skip the bad line, keep the
      // rest. (A sidecar SHA-256, when present, still rejects tampered
      // archives before we get here.)
      try {
        out.add(jsonDecode(trimmed) as Map<String, dynamic>);
      } catch (e) {
        _log.warning('skipping malformed JSONL line $lineNo in $name');
      }
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  //  Asset file helpers
  // ---------------------------------------------------------------------------

  /// Copies each `assets/*` archive entry (named in [assetEntryNames]) into
  /// the local documents directory. Existing local files are preserved (LWW
  /// on content: last export wins only for DB rows; filesystem assets are
  /// treated as immutable-per-name).
  ///
  /// Each entry is copied or inflated from [zipPath] to its file in chunks
  /// on a background isolate, so memory stays flat however large the file.
  Future<_AssetResult> _extractAssets(
    List<String> assetEntryNames,
    String zipPath,
    List<String> warnings,
  ) async {
    if (assetEntryNames.isEmpty) {
      return const _AssetResult(copied: 0, skipped: 0);
    }
    Directory baseDir;
    try {
      baseDir = await _assetsBaseDirResolver();
    } catch (e) {
      warnings.add('assets base dir unavailable: $e');
      return _AssetResult(
        copied: 0,
        skipped: 0,
        failed: assetEntryNames.length,
      );
    }
    var skipped = 0;

    // Which entries to write, and where; their folders are created here.
    final toExtract = <String, String>{};
    for (final entryName in assetEntryNames) {
      final destPath = containedDocumentsPath(
        baseDir.path,
        entryName.substring(_assetsPrefix.length),
      );
      if (destPath == null) {
        warnings.add(
          'skipping archive entry outside the documents folder or named as '
          'the database: $entryName',
        );
        continue;
      }
      final dest = File(destPath);
      if (await dest.exists()) {
        skipped++;
        continue;
      }
      await dest.parent.create(recursive: true);
      toExtract[entryName] = dest.path;
    }

    if (toExtract.isEmpty) {
      return _AssetResult(copied: 0, skipped: skipped);
    }

    try {
      final result = await extractZipEntriesTo(zipPath, toExtract);
      // An entry missing from the archive is a defect of the archive, not a
      // failure of this device, so it is only warned about.
      for (final name in result.missing) {
        warnings.add('entry not found in archive: $name');
      }
      for (final MapEntry(key: name, value: error) in result.failures.entries) {
        warnings.add('$name → ${toExtract[name]}: $error');
      }
      return _AssetResult(
        copied: result.written,
        skipped: skipped,
        failed: result.failures.length,
      );
    } catch (e) {
      warnings.add(
        'asset extraction failed: $e '
        '(— skipping ${toExtract.length} file(s))',
      );
      return _AssetResult(
        copied: 0,
        skipped: skipped,
        failed: toExtract.length,
      );
    }
  }

  /// Reads `PackageInfo.fromPlatform()` and swallows any failure so a
  /// missing platform binding (e.g. unit tests) does not block exports.
  Future<PackageInfo?> _safeReadPackageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (e) {
      _log.warning('PackageInfo.fromPlatform() failed: $e');
      return null;
    }
  }
}

class _AssetResult {
  final int copied;
  final int skipped;
  final int failed;
  const _AssetResult({
    required this.copied,
    required this.skipped,
    this.failed = 0,
  });
}
