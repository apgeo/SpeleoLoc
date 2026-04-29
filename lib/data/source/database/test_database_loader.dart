import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/constants.dart';

/// Configurable paths — override via `--dart-define-from-file=build_settings.json`
const String _defaultTestDbPath =
    'test_data/db/binaries/speleo_loc_export_20260425.sqlite';
const String _defaultTestMapsDir = 'test_data/maps';
const String _defaultTestReportTemplatesDir = 'test_data/report_templates';

const String testDbPath =
    String.fromEnvironment('test_db_path', defaultValue: _defaultTestDbPath);
const String testMapsDir =
    String.fromEnvironment('test_maps_dir', defaultValue: _defaultTestMapsDir);
const String testReportTemplatesDir =
    String.fromEnvironment('test_report_templates_dir', defaultValue: _defaultTestReportTemplatesDir);

/// Loads a pre-built SQLite database binary and copies referenced resource
/// files (raster map images, documentation files) into the app documents
/// folder so the database records point to valid local paths.
class TestDatabaseLoader {
  static final _log = AppLogger.of('TestDatabaseLoader');

  /// When `true` (the default), individual "source not found" warnings and
  /// "Removed missing test doc record" info messages are suppressed.
  /// Instead, a single summary line is emitted at the end of each resource
  /// copy phase listing the count and names of missing resources.
  static bool suppressMissingResourceLogs = true;

  /// Main entry-point.
  ///
  /// 1. Copies the SQLite binary to the documents directory.
  /// 2. Creates a fresh [AppDatabase] backed by the copied file.
  /// 3. Iterates `raster_maps` and copies source images.
  /// 4. Iterates `documentation_files` and copies source docs.
  ///
  /// Returns the new [AppDatabase] instance.
  static Future<AppDatabase> loadTestDatabase() async {
    final stopwatch = Stopwatch()..start();
    _log.info('Starting loadTestDatabase ...');

    final documentsDir = await getApplicationDocumentsDirectory();
    final dbTargetPath = p.join(documentsDir.path, 'speleo_loc.sqlite');

    // ---- 1. Copy the SQLite binary ----
    final dbBytes = await _loadBinaryAsset(testDbPath);
    if (dbBytes == null) {
      throw Exception(
          '[TestDatabaseLoader] Could not load test database from "$testDbPath"');
    }
    final dbFile = File(dbTargetPath);
    await dbFile.writeAsBytes(dbBytes, flush: true);
    _log.info('Database binary copied (${dbBytes.length} bytes) → $dbTargetPath');

    // ---- 2. Open the database ----
    final db = AppDatabase();

    // ---- 3. Copy raster map images ----
    try {
      final rasterMaps = await db.select(db.rasterMaps).get();
      _log.info('Found ${rasterMaps.length} raster map records');
      final List<String> missingRasterMaps = [];
      for (final rm in rasterMaps) {
        final found = await _copyResourceFile(
          sourceDir: testMapsDir,
          storedFileName: rm.fileName,
          title: rm.title,
          documentsDir: documentsDir,
        );
        if (!found && suppressMissingResourceLogs) {
          missingRasterMaps.add('"${rm.title}" (${rm.fileName})');
        }
      }
      if (suppressMissingResourceLogs && missingRasterMaps.isNotEmpty) {
        _log.warning(
            '${missingRasterMaps.length} raster map source(s) not found: '
            '${missingRasterMaps.join(', ')}');
      }
    } catch (e) {
      _log.warning('could not load raster map files: $e');
    }

    // ---- 4. Copy documentation files ----
    try {
      final docFiles = await db.select(db.documentationFiles).get();
      _log.info('Found ${docFiles.length} documentation file records');
      final List<String> missingDocEntries = [];
      for (final df in docFiles) {
        final found = await _copyResourceFile(
          sourceDir: testMapsDir, // docs may share source folder or have their own
          storedFileName: df.fileName,
          title: df.title,
          documentsDir: documentsDir,
        );
        if (!found && skipMissingTestDocuments) {
          await db.deleteDocumentationFileByUuid(df.uuid);
          if (!suppressMissingResourceLogs) {
            _log.info('Removed missing test doc record: "${df.title}" (${df.uuid})');
          } else {
            missingDocEntries.add('"${df.title}" (${df.fileName})');
          }
        }
      }
      if (suppressMissingResourceLogs && missingDocEntries.isNotEmpty) {
        _log.info(
            '${missingDocEntries.length} missing test doc record(s) removed: '
            '${missingDocEntries.join(', ')}');
      }
    } catch (e) {
      _log.warning('could not load documentation files: $e');
    }

    // ---- 5. Copy template files ----
    try {
      final templateFiles = await db.select(db.tripReportTemplates).get();
      _log.info('Found ${templateFiles.length} template file records');
      for (final tf in templateFiles) {
        await _copyResourceFile(
          sourceDir: testReportTemplatesDir, // docs may share source folder or have their own
          storedFileName: tf.fileName,
          title: tf.title,
          documentsDir: documentsDir,
        );
      }
    } catch (e) {
      _log.warning('could not load template files: $e');
    }

    stopwatch.stop();
    _log.info('loadTestDatabase completed in ${stopwatch.elapsedMilliseconds} ms');
    return db;
  }

  /// Load binary bytes from either Flutter assets (rootBundle) or
  /// direct file system path (development fallback).
  static Future<List<int>?> _loadBinaryAsset(String assetPath) async {
    // Try rootBundle first (works when bundled as asset)
    try {
      final data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (_) {}

    // Fallback: direct file system (development mode)
    try {
      final repoPath = p.join(Directory.current.path, assetPath);
      final file = File(repoPath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (_) {}

    return null;
  }

  /// Copy a resource file from [sourceDir] to the documents directory.
  ///
  /// - [storedFileName] is the path stored in the DB (e.g. `cave_1/raster_123.jpg`)
  /// - [title] is the raster map title or doc title which may match a source filename
  /// - The method tries matching by basename of [storedFileName] first, then [title].
  /// - Returns `true` if the file was found (already existed or successfully copied),
  ///   `false` if the source could not be located.
  static Future<bool> _copyResourceFile({
    required String sourceDir,
    required String storedFileName,
    required String? title,
    required Directory documentsDir,
  }) async {
    final targetPath = p.join(documentsDir.path, storedFileName);
    final targetFile = File(targetPath);

    // Skip if file already exists
    if (await targetFile.exists()) return true;

    // Ensure target directory exists
    final targetDir = targetFile.parent;
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final basename = p.basename(storedFileName);

    // Strategy 1: Try loading storedFileName directly from sourceDir
    final bytes = await _tryLoadSource(sourceDir, basename) ??
        // Strategy 2: Try using the title as filename (TestDataHelper stores
        // original asset name in title)
        (title != null && title != basename
            ? await _tryLoadSource(sourceDir, title)
            : null) ??
        // Strategy 3: Try the storedFileName as a full asset path
        await _loadBinaryAsset(storedFileName);

    if (bytes != null) {
      await targetFile.writeAsBytes(bytes, flush: true);
      _log.info('Copied resource → $storedFileName');
      return true;
    } else {
      if (!suppressMissingResourceLogs) {
        _log.warning('source not found for "$storedFileName" (title: "$title")');
      }
      return false;
    }
  }

  /// Try loading a file from [dir]/[fileName] via rootBundle or filesystem.
  static Future<List<int>?> _tryLoadSource(
      String dir, String fileName) async {
    // Asset bundle
    try {
      final assetPath = '$dir/$fileName';
      final data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (_) {}

    // Direct file
    try {
      final filePath = p.join(Directory.current.path, dir, fileName);
      final f = File(filePath);
      if (await f.exists()) {
        return await f.readAsBytes();
      }
    } catch (_) {}

    return null;
  }
}