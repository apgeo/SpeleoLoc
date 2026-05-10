import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
/// v3: manifest gains `app_version`/`app_build_number` so import errors
///     can tell the user the minimum app version required.
const int kSyncArchiveVersion = 3;

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
typedef ConflictResolver =
    Future<SyncConflictAction?> Function(SyncConflict);

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

/// Metadata columns that are excluded from "differing fields" computation:
/// they are bookkeeping, not meaningful user content.
const _metaColumnsForDiff = <String>{
  'created_at',
  'updated_at',
  'deleted_at',
  'created_by_user_uuid',
  'last_modified_by_user_uuid',
};

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
          upsert: (rows, resolver) async => _upsertRows<User>(
            rows,
            (j) => User.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.users,
            resolver,
          ),
        ),
        _SyncTable(
          name: 'surface_areas',
          dump: () async => (await _db.select(_db.surfaceAreas).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows, resolver) async => _upsertRows<SurfaceArea>(
            rows,
            (j) => SurfaceArea.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.surfaceAreas,
            resolver,
          ),
        ),
        _SyncTable(
          name: 'caves',
          dump: () async => (await _db.select(_db.caves).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows, resolver) async => _upsertRows<Cave>(
            rows,
            (j) => Cave.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.caves,
            resolver,
          ),
        ),
        _SyncTable(
          name: 'cave_areas',
          dump: () async => (await _db.select(_db.caveAreas).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows, resolver) async => _upsertRows<CaveArea>(
            rows,
            (j) => CaveArea.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.caveAreas,
            resolver,
          ),
        ),
        _SyncTable(
          name: 'cave_places',
          dump: () async => (await _db.select(_db.cavePlaces).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows, resolver) async => _upsertRows<CavePlace>(
            rows,
            (j) => CavePlace.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.cavePlaces,
            resolver,
          ),
        ),
        _SyncTable(
          name: 'raster_maps',
          dump: () async => (await _db.select(_db.rasterMaps).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows, resolver) async => _upsertRows<RasterMap>(
            rows,
            (j) => RasterMap.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.rasterMaps,
            resolver,
          ),
        ),
        _SyncTable(
          name: 'cave_place_to_raster_map_definitions',
          dump: () async =>
              (await _db.select(_db.cavePlaceToRasterMapDefinitions).get())
                  .map((r) => r.toJson(serializer: _serializer))
                  .toList(),
          upsert: (rows, resolver) async =>
              _upsertRows<CavePlaceToRasterMapDefinition>(
            rows,
            (j) => CavePlaceToRasterMapDefinition.fromJson(
              j,
              serializer: _serializer,
            ),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.cavePlaceToRasterMapDefinitions,
            resolver,
          ),
        ),
        _SyncTable(
          name: 'cave_trips',
          dump: () async => (await _db.select(_db.caveTrips).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows, resolver) async => _upsertRows<CaveTrip>(
            rows,
            (j) => CaveTrip.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.caveTrips,
            resolver,
          ),
        ),
        _SyncTable(
          name: 'cave_trip_points',
          dump: () async => (await _db.select(_db.caveTripPoints).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows, resolver) async => _upsertRows<CaveTripPoint>(
            rows,
            (j) => CaveTripPoint.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.caveTripPoints,
            resolver,
          ),
        ),
        _SyncTable(
          name: 'documentation_files',
          dump: () async => (await _db.select(_db.documentationFiles).get())
              .map((r) => r.toJson(serializer: _serializer))
              .toList(),
          upsert: (rows, resolver) async => _upsertRows<DocumentationFile>(
            rows,
            (j) => DocumentationFile.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.documentationFiles,
            resolver,
          ),
        ),
        _SyncTable(
          name: 'documentation_files_to_geofeatures',
          dump: () async =>
              (await _db.select(_db.documentationFilesToGeofeatures).get())
                  .map((r) => r.toJson(serializer: _serializer))
                  .toList(),
          upsert: (rows, resolver) async =>
              _upsertRows<DocumentationFilesToGeofeature>(
            rows,
            (j) => DocumentationFilesToGeofeature.fromJson(
              j,
              serializer: _serializer,
            ),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.documentationFilesToGeofeatures,
            resolver,
          ),
        ),
        _SyncTable(
          name: 'documentation_files_to_cave_trips',
          dump: () async =>
              (await _db.select(_db.documentationFilesToCaveTrips).get())
                  .map((r) => r.toJson(serializer: _serializer))
                  .toList(),
          upsert: (rows, resolver) async =>
              _upsertRows<DocumentationFilesToCaveTrip>(
            rows,
            (j) => DocumentationFilesToCaveTrip.fromJson(
              j,
              serializer: _serializer,
            ),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            // Link table has no updated_at; LWW falls back to created_at.
            (r) => r.createdAt,
            _db.documentationFilesToCaveTrips,
            resolver,
          ),
        ),
        _SyncTable(
          name: 'trip_report_templates',
          dump: () async =>
              (await _db.select(_db.tripReportTemplates).get())
                  .map((r) => r.toJson(serializer: _serializer))
                  .toList(),
          upsert: (rows, resolver) async => _upsertRows<TripReportTemplate>(
            rows,
            (j) => TripReportTemplate.fromJson(j, serializer: _serializer),
            (r) => r.toJson(serializer: _serializer),
            (r) => r.uuid,
            (r) => r.updatedAt ?? r.createdAt,
            _db.tripReportTemplates,
            resolver,
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
    final pkgInfo = await _safeReadPackageInfo();
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
    // Stream-encode to disk so very large archives (raster maps, etc.) do
    // not have to be held in memory all at once.
    final output = OutputFileStream(out.path);
    try {
      ZipEncoder().encode(archive, output: output);
    } finally {
      await output.close();
    }
    final size = await out.length();
    _log.info('Sync archive exported: ${out.path} '
        '($size bytes, ${tables.length} tables, '
        '${changeLogRows.length} change-log entries, '
        '$assetCount asset files)');
    return out;
  }

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
    // Stream-decode from disk to avoid materialising the whole zip in
    // memory (which has historically tripped RangeError boundary bugs in
    // package:archive when the decoded payload is large, e.g. for archives
    // carrying raster-map images).
    //
    // CRITICAL: ZipDecoder().decodeBuffer(input) returns a *lazy* archive
    // — entry payloads are inflated on-demand later by writeContent() in
    // _extractAssets. We therefore must NOT close `input` until the whole
    // import has finished, otherwise the inflater reads from a closed
    // file handle and throws "FormatException: Filter error, bad data"
    // (observed on Android Samsung devices, where the platform appears
    // to actually invalidate the underlying buffer on close, while on
    // some other platforms it lingers in cache).
    final input = InputFileStream(zipPath);
    try {
      Archive archive = ZipDecoder().decodeBuffer(input);
      // Forensic fallback: if the streaming decode produced an archive
      // without a manifest, retry once with the in-memory decoder which
      // sometimes finds the central directory when the streaming reader
      // landed on a false-positive EOCD signature. We log enough detail
      // for the user to compare the on-disk file with the source.
      if (archive.findFile('manifest.json') == null) {
        final f = File(zipPath);
        final size = await f.length();
        _log.warning(
          'streaming decode of $zipPath ($size bytes) yielded '
          '${archive.files.length} entries without manifest.json; '
          'retrying with in-memory decoder',
        );
        try {
          final bytes = await f.readAsBytes();
          final retry = ZipDecoder().decodeBytes(bytes);
          if (retry.findFile('manifest.json') != null) {
            _log.info(
              'in-memory decoder recovered manifest.json '
              '(${retry.files.length} entries)',
            );
            archive = retry;
          } else {
            // Still no manifest. Dump diagnostics: head/tail bytes plus
            // the byte offset of every End-Of-Central-Directory signature
            // we can find. A single match near the very end of the file
            // means the zip is well-formed and the manifest really is
            // absent (i.e. produced by an older or alien tool). Multiple
            // matches or a match far from the end strongly suggests a
            // truncated/corrupted download.
            final eocdOffsets = _findEocdOffsets(bytes);
            final headHex = _hexHead(bytes, 16);
            final tailHex = _hexTail(bytes, 32);
            _log.severe(
              'in-memory decoder also failed to find manifest.json. '
              'file_size=$size, eocd_offsets=$eocdOffsets, '
              'head=$headHex, tail=$tailHex, '
              'streaming_entries=${archive.files.length}, '
              'retry_entries=${retry.files.length}',
            );
          }
        } catch (e) {
          _log.warning('in-memory decode retry failed for $zipPath: $e');
        }
      }
      return await _importFromArchive(archive, conflictResolver, zipPath);
    } finally {
      await input.close();
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

  Future<SyncImportReport> _importFromArchive(
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
    final manifest = jsonDecode(
      utf8.decode(manifestFile.content as List<int>),
    ) as Map<String, dynamic>;
    if (manifest['format'] != 'speleo_loc_sync') {
      throw FormatException('Unrecognized archive format: ${manifest['format']}');
    }
    final archiveSchema = manifest['schema_version'];
    if (archiveSchema is! int) {
      throw const FormatException(
          'Archive manifest is missing or has an invalid schema_version');
    }
    if (archiveSchema != kSyncArchiveDbSchemaVersion) {
      throw SyncArchiveSchemaMismatchException(
        archiveSchemaVersion: archiveSchema,
        localSchemaVersion: kSyncArchiveDbSchemaVersion,
        archiveAppVersion: manifest['app_version'] as String?,
        archiveAppBuildNumber: manifest['app_build_number'] as String?,
        tooNew: archiveSchema > kSyncArchiveDbSchemaVersion,
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

    // Build a remap table for incoming user UUIDs that collide on
    // `username` with a different local user (e.g. the auto-generated
    // 'system' user, whose UUID is independently created on each device).
    // Without this remap the insert would trip the UNIQUE(username)
    // constraint and every FK from the archive that points at the
    // incoming user UUID would be orphaned.
    final userRemap = await _buildUserUuidRemap(archive, warnings);

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
          if (userRemap.isNotEmpty) {
            for (final r in rows) {
              _applyUserRemapToRow(r, userRemap, t.name);
            }
          }
          final result = await t.upsert(rows, conflictResolver);
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
            if (userRemap.isNotEmpty) {
              _applyUserRemapToChangeLogRow(row, userRemap);
            }
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
  ///
  /// If [resolver] is non-null, every conflicting update (same UUID, at least
  /// one differing column other than audit bookkeeping) is routed through it
  /// before applying a decision. When the resolver returns `null`, default
  /// LWW applies.
  Future<_UpsertCounters> _upsertRows<D extends Insertable<D>>(
    List<Map<String, dynamic>> rows,
    D Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic> Function(D) toJson,
    Uuid Function(D) uuidOf,
    int? Function(D) tsOf,
    TableInfo<Table, D> table,
    ConflictResolver? resolver,
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

      final local = await _loadLocal<D>(table, uuid);
      if (local == null) {
        await _db.into(table).insert(incoming);
        inserted++;
        continue;
      }

      final localTs = tsOf(local) ?? 0;
      final localJson = toJson(local);
      final incomingJson = toJson(incoming);
      final diff = _diffMeaningfulFields(localJson, incomingJson);

      if (diff.isEmpty) {
        // Identical payloads → count as skipped, no-op.
        skipped++;
        continue;
      }

      var action = incomingTs > localTs
          ? SyncConflictAction.useIncoming
          : SyncConflictAction.keepLocal;

      if (resolver != null) {
        final decision = await resolver(SyncConflict(
          tableName: table.actualTableName,
          entityUuid: uuid,
          localFields: localJson,
          incomingFields: incomingJson,
          differingFields: diff,
          localUpdatedAt: localTs == 0 ? null : localTs,
          incomingUpdatedAt: incomingTs == 0 ? null : incomingTs,
        ));
        if (decision == SyncConflictAction.cancel) {
          throw const SyncImportCancelledException();
        }
        if (decision != null) action = decision;
      }

      if (action == SyncConflictAction.useIncoming) {
        await _db.into(table).insert(
              incoming,
              mode: InsertMode.insertOrReplace,
            );
        updated++;
      } else {
        skipped++;
      }
    }

    return _UpsertCounters(
      inserted: inserted,
      updated: updated,
      skipped: skipped,
    );
  }

  /// Loads a single row from [table] by its [uuid] and returns it as the
  /// table's DataClass, or `null` if no such row exists.
  Future<D?> _loadLocal<D>(TableInfo<Table, D> table, Uuid uuid) async {
    final row = await _db.customSelect(
      'SELECT * FROM ${table.actualTableName} WHERE uuid = ? LIMIT 1',
      variables: [Variable<Uint8List>(uuid.bytes)],
    ).getSingleOrNull();
    if (row == null) return null;
    return await table.map(row.data);
  }

  /// Returns the list of columns whose JSON values differ between [a] and
  /// [b], excluding audit-bookkeeping columns that should not count as
  /// user-visible conflicts.
  List<String> _diffMeaningfulFields(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final keys = <String>{...a.keys, ...b.keys};
    final diff = <String>[];
    for (final k in keys) {
      if (_metaColumnsForDiff.contains(k)) continue;
      if (a[k] != b[k]) diff.add(k);
    }
    return diff;
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
        // Stream the entry directly to disk to avoid loading the whole
        // payload into memory — important for raster-map images that can
        // be tens or hundreds of MB.
        final out = OutputFileStream(dest.path);
        try {
          entry.writeContent(out);
        } finally {
          await out.close();
        }
        copied++;
      } catch (e) {
        warnings.add('copy ${entry.name}: $e');
      }
    }
    return _AssetResult(copied: copied, skipped: skipped);
  }

  // ---------------------------------------------------------------------------
  //  User-UUID remap (collision on username)
  // ---------------------------------------------------------------------------

  /// Inspects `tables/users.jsonl` against the local `users` table and
  /// returns a `{incomingUuidStr: localUuidStr}` map for every incoming
  /// user whose `username` already exists locally under a different UUID.
  ///
  /// This is what makes seed users (notably the auto-generated `system`
  /// user, whose UUID is independently allocated on every device)
  /// importable across devices: instead of inserting the incoming row
  /// (which would fail on the UNIQUE(username) constraint) and orphaning
  /// every FK that references the incoming UUID, we rewrite all those
  /// references to the local UUID and let normal LWW handle the row
  /// itself.
  Future<Map<String, String>> _buildUserUuidRemap(
    Archive archive,
    List<String> warnings,
  ) async {
    final entry = archive.findFile('tables/users.jsonl');
    if (entry == null) return const <String, String>{};
    final rows = _readJsonl(entry);
    if (rows.isEmpty) return const <String, String>{};

    final localByUsername = <String, String>{};
    final localUuids = <String>{};
    for (final u in await _db.select(_db.users).get()) {
      localUuids.add(u.uuid.toString());
      localByUsername[u.username] = u.uuid.toString();
    }

    final remap = <String, String>{};
    for (final row in rows) {
      final incomingUuid = row['uuid'];
      final incomingUsername = row['username'];
      if (incomingUuid is! String || incomingUsername is! String) continue;
      if (localUuids.contains(incomingUuid)) continue;
      final localUuid = localByUsername[incomingUsername];
      if (localUuid == null) continue; // brand-new user — insert as-is
      remap[incomingUuid] = localUuid;
      warnings.add(
        'remapped user "$incomingUsername" '
        '$incomingUuid -> $localUuid (matched by username)',
      );
    }
    return remap;
  }

  /// Rewrites user-FK columns of [row] using [remap]. For the `users`
  /// table the row's own `uuid` is also rewritten so the subsequent
  /// upsert resolves to the local row via LWW instead of attempting an
  /// insert that would violate the UNIQUE(username) constraint.
  void _applyUserRemapToRow(
    Map<String, dynamic> row,
    Map<String, String> remap,
    String tableName,
  ) {
    if (tableName == 'users') {
      final u = row['uuid'];
      if (u is String) {
        final mapped = remap[u];
        if (mapped != null) row['uuid'] = mapped;
      }
    }
    _remapField(row, 'created_by_user_uuid', remap);
    _remapField(row, 'last_modified_by_user_uuid', remap);
  }

  /// Rewrites user-FK columns of a single `change_log` row using [remap].
  /// `entity_uuid` is also rewritten when the row targets the `users`
  /// table so that delete tombstones and field-history entries follow the
  /// remapped user identity.
  void _applyUserRemapToChangeLogRow(
    Map<String, dynamic> row,
    Map<String, String> remap,
  ) {
    _remapField(row, 'changed_by_user_uuid', remap);
    if (row['entity_table'] == 'users') {
      _remapField(row, 'entity_uuid', remap);
    }
  }

  void _remapField(
    Map<String, dynamic> row,
    String key,
    Map<String, String> remap,
  ) {
    final v = row[key];
    if (v is! String) return;
    final mapped = remap[v];
    if (mapped != null) row[key] = mapped;
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
  final Future<_UpsertCounters> Function(
    List<Map<String, dynamic>> rows,
    ConflictResolver? resolver,
  ) upsert;
  _SyncTable({required this.name, required this.dump, required this.upsert});
}
