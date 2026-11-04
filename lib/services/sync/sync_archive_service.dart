import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
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
/// schema version up to 36, so archives in the wild carry 9 to 36.
const int kSyncArchiveDbSchemaVersion = 35;

/// Oldest archive `schema_version` this app still imports. The sync-v2
/// format has only ever emitted `schema_version >= 9`, and every archived
/// layout since 9 is additively compatible on read (columns added since are
/// nullable or defaulted when absent, and unknown tables are ignored), so
/// archives from there on merge safely.
///
/// The newest one it imports is its own [AppDatabase.schemaVersion]: an
/// archive is never stamped above the schema of the app that wrote it, so a
/// stamp up to ours names archived tables this app already knows — including
/// the stamps above [kSyncArchiveDbSchemaVersion] written while the two were
/// kept equal. A higher stamp comes from an app whose archived tables changed
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
    required this.warnings,
    this.decisionsPending = 0,
  });

  /// Returns a copy with the asset-file counts filled in — used by
  /// `importFromZip`, which runs asset extraction after the DB merge.
  SyncImportReport copyWith({int? filesCopied, int? filesSkipped}) =>
      SyncImportReport(
        rowsInserted: rowsInserted,
        rowsUpdated: rowsUpdated,
        rowsSkipped: rowsSkipped,
        deletesApplied: deletesApplied,
        changeLogMerged: changeLogMerged,
        filesCopied: filesCopied ?? this.filesCopied,
        filesSkipped: filesSkipped ?? this.filesSkipped,
        warnings: warnings,
        decisionsPending: decisionsPending,
      );

  @override
  String toString() =>
      'SyncImportReport(inserted=$rowsInserted, updated=$rowsUpdated, '
      'skipped=$rowsSkipped, deletes=$deletesApplied, '
      'changeLog=$changeLogMerged, filesCopied=$filesCopied, '
      'filesSkipped=$filesSkipped, decisionsPending=$decisionsPending, '
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
    // asset file paths. The CPU-bound zip compression (and the asset file
    // reads) then run in a background isolate so a large export never blocks
    // the UI thread (Android ANR — see the class doc-comment).
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
    // asset_count is filled in by the isolate once it knows how many files
    // actually existed on disk.
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
    };

    final dir = Directory(outputDir);
    if (!await dir.exists()) await dir.create(recursive: true);
    final name = filenameHint ?? 'speleo_loc_sync_$nowMs.zip';
    final out = File('${dir.path}${Platform.pathSeparator}$name');

    final job = _EncodeArchiveJob(
      jsonlEntries: jsonlEntries,
      assetBaseDir: baseDir?.path,
      assetRelPaths: assetRelPaths,
      manifest: manifest,
      outputPath: out.path,
    );
    final assetCount = await _encodeInBackground(job);

    final size = await out.length();
    _log.info(
      'Sync archive exported: ${out.path} '
      '($size bytes, ${tables.length} tables, '
      '$changeLogCount change-log entries, '
      '$assetCount asset files)',
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

    // Resolve the asset relative paths (the isolate reads the files itself,
    // so no file bytes cross the isolate boundary).
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
      // A plain loop, not a closure: a closure here would capture `this` into
      // the context the isolate job in [exportToZip] is sent with.
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

  /// Static, so the closure sent to the isolate captures [job] alone: one
  /// built inside [exportToZip] would share that method's context, which
  /// also holds `this`, and the database cannot be sent to an isolate.
  static Future<int> _encodeInBackground(_EncodeArchiveJob job) =>
      Isolate.run(() => _encodeSyncArchive(job));

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
  Future<SyncImportReport> importFromZip(
    String zipPath, {
    ConflictResolver? conflictResolver,
  }) async {
    // Read the file asynchronously so the UI/main isolate is never blocked.
    //
    // Previous approach used InputFileStream (a forward-only sequential
    // reader). ZIP stores its central directory at the END of the file, so
    // ZipDecoder had to read the entire archive byte-by-byte to reach it.
    // On a Samsung Galaxy S20 FE (Exynos 990) this took >5 s for a 17.8 MB
    // archive, exceeding Android's 5 s input-dispatching deadline and
    // causing ANR even before the import logic ran.
    //
    // InputStream wraps an in-memory Uint8List and IS seekable: ZipDecoder
    // jumps straight to the last 22 bytes to locate the EOCD, reads the
    // central directory (a few KB), and returns in milliseconds regardless
    // of archive size.
    //
    // The historical RangeError from in-memory archives (which motivated the
    // InputFileStream approach) is no longer a risk: large asset entries
    // (raster maps) are never inflated via entry.content in this isolate —
    // _extractAssetsInBackground opens its own InputFileStream in a
    // background isolate and handles all binary extraction there.
    var bytes = await File(zipPath).readAsBytes();
    // InputStream is backed by the Uint8List above. Both are released (see
    // below) once the DB merge is done, before asset extraction runs.
    var archive = ZipDecoder().decodeBuffer(InputStream(bytes));

    if (archive.findFile('manifest.json') == null) {
      final size = bytes.length;
      // InputStream is seekable so a false-positive EOCD hit is extremely
      // unlikely here, but log diagnostics for forensics regardless.
      final eocdOffsets = _findEocdOffsets(bytes);
      final headHex = _hexHead(bytes, 16);
      final tailHex = _hexTail(bytes, 32);
      _log.severe(
        'in-memory decode of $zipPath ($size bytes) yielded '
        '${archive.files.length} entries without manifest.json. '
        'eocd_offsets=$eocdOffsets, head=$headHex, tail=$tailHex',
      );
    }

    // Phase 1+2: parse the JSONL and merge into the DB. Returns the report
    // (with file counts still zero) plus the names of the `assets/*` entries.
    final (partial, assetEntryNames) = await _mergeArchiveIntoDb(
      archive,
      conflictResolver,
      zipPath,
    );

    // Release the full in-memory archive and its backing byte buffer before
    // the file-backed asset extraction. The extractor re-opens the zip in a
    // background isolate, so holding this copy here would just double peak
    // memory for a large archive (finding 5.6).
    bytes = Uint8List(0);
    archive = Archive();

    final assetResult = await _extractAssets(
      assetEntryNames,
      zipPath,
      partial.warnings,
    );
    return partial.copyWith(
      filesCopied: assetResult.copied,
      filesSkipped: assetResult.skipped,
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

  /// Returns every byte offset in [bytes] where the 4-byte zip End-Of-
  /// Central-Directory signature (0x06054b50, little-endian "PK\x05\x06")
  /// appears. A healthy zip has exactly one near the end.
  List<int> _findEocdOffsets(List<int> bytes) {
    const sig = [0x50, 0x4b, 0x05, 0x06];
    final hits = <int>[];
    for (var i = 0; i + 3 < bytes.length; i++) {
      if (bytes[i] == sig[0] &&
          bytes[i + 1] == sig[1] &&
          bytes[i + 2] == sig[2] &&
          bytes[i + 3] == sig[3]) {
        hits.add(i);
        if (hits.length >= 8) break;
      }
    }
    return hits;
  }

  String _hexHead(List<int> bytes, int n) {
    final end = bytes.length < n ? bytes.length : n;
    return bytes
        .sublist(0, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(' ');
  }

  String _hexTail(List<int> bytes, int n) {
    final start = bytes.length < n ? 0 : bytes.length - n;
    return bytes
        .sublist(start)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(' ');
  }

  /// Validates the manifest, replays the JSONL into the DB (Phase 1 parse +
  /// Phase 2 transaction), and returns the report (with file counts still
  /// zero) alongside the names of the `assets/*` entries the caller should
  /// extract. Asset extraction is deliberately left to the caller so the
  /// in-memory archive can be released first (finding 5.6).
  Future<(SyncImportReport, List<String>)> _mergeArchiveIntoDb(
    Archive archive,
    ConflictResolver? conflictResolver,
    String zipPath,
  ) async {
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      final f = File(zipPath);
      final size = await f.length();
      final names = archive.files
          .map((f) => f.name)
          .take(10)
          .toList(growable: false);
      throw FormatException(
        'Archive missing manifest.json '
        '(file_size=$size bytes, ${archive.files.length} zip entries found'
        '${names.isEmpty ? '' : ', e.g. ${names.join(", ")}'}). '
        'See log for forensic details (EOCD offsets, head/tail bytes).',
      );
    }
    final manifest =
        jsonDecode(utf8.decode(manifestFile.content as List<int>))
            as Map<String, dynamic>;
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
      final entry = archive.findFile('tables/${t.name}.jsonl');
      if (entry == null) {
        warnings.add('archive missing tables/${t.name}.jsonl');
        continue;
      }
      tableRows[t.name] = _readJsonl(entry);
    }

    await Future.delayed(Duration.zero);
    final logEntry = archive.findFile('change_log.jsonl');
    final logRows = logEntry != null
        ? _readJsonl(logEntry)
        : <Map<String, dynamic>>[];

    await Future.delayed(Duration.zero);
    final fieldEntry = archive.findFile('change_log_field.jsonl');
    final fieldRows = fieldEntry != null
        ? _readJsonl(fieldEntry)
        : <Map<String, dynamic>>[];

    final report = await _engine.merge(
      tableRows: tableRows,
      logRows: logRows,
      fieldRows: fieldRows,
      conflictResolver: conflictResolver,
      warnings: warnings,
    );

    // Collect the asset entry names for the caller to extract after it has
    // released this archive; file counts are filled in there.
    final assetEntryNames = [
      for (final entry in archive.files)
        if (entry.isFile && entry.name.startsWith(_assetsPrefix)) entry.name,
    ];

    return (report, assetEntryNames);
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

  List<Map<String, dynamic>> _readJsonl(ArchiveFile file) {
    final content = utf8.decode(file.content as List<int>);
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
        _log.warning('skipping malformed JSONL line $lineNo in ${file.name}');
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
  /// Takes the entry names (not the [Archive]) so the caller can release the
  /// full in-memory archive first; the actual bytes are re-read from
  /// [zipPath] in a background isolate.
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
      return const _AssetResult(copied: 0, skipped: 0);
    }
    var skipped = 0;

    // Phase 1 (main isolate): determine which entries need extracting and
    // create output parent directories.  getApplicationDocumentsDirectory()
    // and Directory.create() use platform channels that must run on the main
    // isolate, so we resolve all paths here before spawning.
    final toExtract = <List<String>>[];
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
      toExtract.add([entryName, dest.path]);
    }

    if (toExtract.isEmpty) {
      return _AssetResult(copied: 0, skipped: skipped);
    }

    // Phase 2 (background isolate): inflate + write all asset files.
    // entry.writeContent() is fully synchronous, CPU-bound decompression
    // that can block the Dart UI thread for several seconds per large
    // raster-map file, triggering Android ANR.  Offloading to Isolate.run()
    // keeps the UI thread completely free during the entire extraction.
    try {
      final (copied, isolateWarnings) = await Isolate.run(
        () => _extractAssetsInBackground(zipPath, toExtract),
      );
      warnings.addAll(isolateWarnings);
      return _AssetResult(copied: copied, skipped: skipped);
    } catch (e) {
      warnings.add(
        'asset extraction failed: $e '
        '(— skipping ${toExtract.length} file(s))',
      );
      return _AssetResult(copied: 0, skipped: skipped);
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

/// Extracts archive entries to their pre-created output paths.
///
/// Runs in a background isolate spawned by [SyncArchiveService._extractAssets]
/// so that synchronous CPU-bound decompression (via [ArchiveFile.writeContent])
/// does not block the Flutter UI isolate and cause Android ANR.
///
/// [zipPath] is re-opened with a fresh [InputFileStream] so this function is
/// fully self-contained and can run in any isolate without sharing state.
/// [entries] is a list of `[entryName, outputPath]` pairs; output parent
/// directories must already exist (created by the caller on the main isolate).
///
/// Returns `(copied, warnings)` — number of files successfully written and
/// any per-file error messages.
Future<(int, List<String>)> _extractAssetsInBackground(
  String zipPath,
  List<List<String>> entries,
) async {
  var copied = 0;
  final warnings = <String>[];
  final input = InputFileStream(zipPath);
  try {
    final archive = ZipDecoder().decodeBuffer(input);
    for (final pair in entries) {
      final name = pair[0];
      final outputPath = pair[1];
      final entry = archive.findFile(name);
      if (entry == null) {
        warnings.add('entry not found in archive: $name');
        continue;
      }
      try {
        final out = OutputFileStream(outputPath);
        try {
          entry.writeContent(out);
        } finally {
          await out.close();
        }
        copied++;
      } catch (e) {
        warnings.add('$name → $outputPath: $e');
      }
    }
  } finally {
    await input.close();
  }
  return (copied, warnings);
}

class _AssetResult {
  final int copied;
  final int skipped;
  const _AssetResult({required this.copied, required this.skipped});
}

/// Payload for [_encodeSyncArchive] — everything the background isolate needs
/// to assemble and compress the archive without touching the database. All
/// fields are plain sendable data so the whole object can cross an
/// [Isolate.run] boundary.
class _EncodeArchiveJob {
  const _EncodeArchiveJob({
    required this.jsonlEntries,
    required this.assetBaseDir,
    required this.assetRelPaths,
    required this.manifest,
    required this.outputPath,
  });

  /// `(entryName, bytes)` for each `tables/*.jsonl` and change-log file.
  final List<(String, Uint8List)> jsonlEntries;

  /// Base directory the [assetRelPaths] are relative to, or null when no
  /// assets should be bundled. The isolate reads the files itself, so their
  /// bytes never cross the isolate boundary.
  final String? assetBaseDir;
  final List<String> assetRelPaths;

  /// Manifest fields WITHOUT `asset_count`; the isolate fills that in once it
  /// knows how many asset files actually existed on disk.
  final Map<String, dynamic> manifest;
  final String outputPath;
}

/// Assembles the sync archive and compresses it to
/// [_EncodeArchiveJob.outputPath], reading asset files itself. Runs in a
/// background isolate (spawned from [SyncArchiveService.exportToZip]) so the
/// CPU-bound zip compression never blocks the UI isolate. Returns the number
/// of asset files actually bundled.
Future<int> _encodeSyncArchive(_EncodeArchiveJob job) async {
  final archive = Archive();
  for (final (name, bytes) in job.jsonlEntries) {
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  var assetCount = 0;
  final baseDir = job.assetBaseDir;
  if (baseDir != null) {
    final seen = <String>{};
    for (final relPath in job.assetRelPaths) {
      if (relPath.isEmpty || !seen.add(relPath)) continue;
      final file = File('$baseDir${Platform.pathSeparator}$relPath');
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      final normalized = relPath.replaceAll('\\', '/');
      archive.addFile(ArchiveFile('assets/$normalized', bytes.length, bytes));
      assetCount++;
    }
  }

  final manifest = <String, dynamic>{
    ...job.manifest,
    'asset_count': assetCount,
  };
  archive.addFile(
    ArchiveFile.string(
      'manifest.json',
      const JsonEncoder.withIndent('  ').convert(manifest),
    ),
  );

  final output = OutputFileStream(job.outputPath);
  try {
    ZipEncoder().encode(archive, output: output);
  } finally {
    await output.close();
  }
  return assetCount;
}
