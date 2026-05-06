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
const String _defaultTestDocsDir = 'test_data/pictures';
const String _defaultTestReportTemplatesDir = 'test_data/report_templates';

const String testDbPath =
    String.fromEnvironment('test_db_path', defaultValue: _defaultTestDbPath);
const String testMapsDir =
    String.fromEnvironment('test_maps_dir', defaultValue: _defaultTestMapsDir);
const String testDocsDir =
  String.fromEnvironment('test_docs_dir', defaultValue: _defaultTestDocsDir);
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
      final sw3 = Stopwatch()..start();
      final rasterMaps = await db.select(db.rasterMaps).get();
      _log.info('Found ${rasterMaps.length} raster map records');
      final missingRasterMaps = (await Future.wait(
        rasterMaps.map((rm) async {
          final found = await _copyResourceFile(
            sourceDirs: [testMapsDir],
            storedFileName: rm.fileName,
            title: rm.title,
            documentsDir: documentsDir,
          );
          return (!found && suppressMissingResourceLogs)
              ? '"${rm.title}" (${rm.fileName})'
              : null;
        }),
      )).whereType<String>().toList();
      if (suppressMissingResourceLogs && missingRasterMaps.isNotEmpty) {
        _log.warning(
            '${missingRasterMaps.length} raster map source(s) not found: '
            '${missingRasterMaps.join(', ')}');
      }
      _log.info('Step 3 (raster maps) completed in ${sw3.elapsedMilliseconds} ms');
    } catch (e) {
      _log.warning('could not load raster map files: $e');
    }

    // ---- 4. Copy documentation files ----
    try {
      final sw4 = Stopwatch()..start();
      final docFiles = await db.select(db.documentationFiles).get();
      _log.info('Found ${docFiles.length} documentation file records');
      final bench4 = _CopyBenchmark();
      final missingDocEntries = (await Future.wait(
        docFiles.map((df) async {
          final found = await _copyResourceFile(
            // Docs usually live under test_data/pictures, with maps as fallback .
            sourceDirs: [testDocsDir, testMapsDir],
            storedFileName: df.fileName,
            title: df.title,
            documentsDir: documentsDir,
            bench: bench4,
          );
          if (!found && skipMissingTestDocuments) {
            await db.deleteDocumentationFileByUuid(df.uuid);
            if (!suppressMissingResourceLogs) {
              _log.info('Removed missing test doc record: "${df.title}" (${df.uuid})');
            } else {
              return '"${df.title}" (${df.fileName})';
            }
          }
          return null;
        }),
      )).whereType<String>().toList();
      if (suppressMissingResourceLogs && missingDocEntries.isNotEmpty) {
        _log.info(
            '${missingDocEntries.length} missing test doc record(s) removed: '
            '${missingDocEntries.join(', ')}');
      }
      _log.info(
        'Step 4 benchmark — '
        'calls:${bench4.calls} skipped:${bench4.skipped} misses:${bench4.misses} | '
        'exists:${bench4.existsCheckMs}ms mkdir:${bench4.mkdirMs}ms | '
        'S1:${bench4.strategy1Ms}ms(${bench4.strategy1Hits}hits) '
        'S2:${bench4.strategy2Ms}ms(${bench4.strategy2Hits}hits) '
        'S3:${bench4.strategy3Ms}ms(${bench4.strategy3Hits}hits) | '
        'write:${bench4.writeMs}ms',
      );
      _log.info('Step 4 (documentation files) completed in ${sw4.elapsedMilliseconds} ms');
    } catch (e) {
      _log.warning('could not load documentation files: $e');
    }

    // ---- 5. Copy template files ----
    try {
      final sw5 = Stopwatch()..start();
      final templateFiles = await db.select(db.tripReportTemplates).get();
      _log.info('Found ${templateFiles.length} template file records');
      await Future.wait(
        templateFiles.map((tf) => _copyResourceFile(
          sourceDirs: [testReportTemplatesDir],
          storedFileName: tf.fileName,
          title: tf.title,
          documentsDir: documentsDir,
        )),
      );
      _log.info('Step 5 (templates) completed in ${sw5.elapsedMilliseconds} ms');
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
    required List<String> sourceDirs,
    required String storedFileName,
    required String? title,
    required Directory documentsDir,
    _CopyBenchmark? bench,
  }) async {
    bench?.calls++;
    final targetPath = p.join(documentsDir.path, storedFileName);
    final targetFile = File(targetPath);
    final sw = Stopwatch()..start();

    // Skip if file already exists
    if (await targetFile.exists()) {
      bench?.existsCheckMs += sw.elapsedMilliseconds;
      bench?.skipped++;
      return true;
    }
    bench?.existsCheckMs += sw.elapsedMilliseconds;

    // Ensure target directory exists
    final targetDir = targetFile.parent;
    sw.reset(); sw.start();
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    bench?.mkdirMs += sw.elapsedMilliseconds;

    final basename = p.basename(storedFileName);

    // Strategy 1: Try loading stored basename directly from candidate sources.
    sw.reset(); sw.start();
    List<int>? bytes;
    for (final sourceDir in sourceDirs) {
      bytes = await _tryLoadSource(sourceDir, basename);
      if (bytes != null) {
        break;
      }
    }
    bench?.strategy1Ms += sw.elapsedMilliseconds;
    if (bytes != null) bench?.strategy1Hits++;

    // Strategy 2: Try using the title as filename across all candidate sources.
    // TestDataHelper stores
    // original asset name in title)
    if (bytes == null && title != null && title != basename) {
      sw.reset(); sw.start();
      for (final sourceDir in sourceDirs) {
        bytes = await _tryLoadSource(sourceDir, title);
        if (bytes != null) {
          break;
        }
      }
      bench?.strategy2Ms += sw.elapsedMilliseconds;
      if (bytes != null) bench?.strategy2Hits++;
    }

    // Strategy 3: Try the storedFileName as a full asset path
    if (bytes == null) {
      sw.reset(); sw.start();
      bytes = await _loadBinaryAsset(storedFileName);
      bench?.strategy3Ms += sw.elapsedMilliseconds;
      if (bytes != null) bench?.strategy3Hits++;
    }

    if (bytes != null) {
      sw.reset(); sw.start();
      await targetFile.writeAsBytes(bytes, flush: true);
      bench?.writeMs += sw.elapsedMilliseconds;
      _log.info('Copied resource → $storedFileName');
      return true;
    } else {
      bench?.misses++;
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

/// Accumulates per-step timing totals across concurrent [_copyResourceFile] calls.
class _CopyBenchmark {
  int calls = 0;
  int skipped = 0; // file already existed at target
  int misses = 0; // source not found by any strategy
  int existsCheckMs = 0;
  int mkdirMs = 0;
  int strategy1Ms = 0;
  int strategy1Hits = 0;
  int strategy2Ms = 0;
  int strategy2Hits = 0;
  int strategy3Ms = 0;
  int strategy3Hits = 0;
  int writeMs = 0;
}