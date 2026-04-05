import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

/// Configurable paths — override via `--dart-define-from-file=build_settings.json`
const String _defaultTestDbPath =
    'test_data/db/binaries/speleo_loc_export_20260301.sqlite';
const String _defaultTestMapsDir = 'test_data/maps';

const String testDbPath =
    String.fromEnvironment('test_db_path', defaultValue: _defaultTestDbPath);
const String testMapsDir =
    String.fromEnvironment('test_maps_dir', defaultValue: _defaultTestMapsDir);

/// Loads a pre-built SQLite database binary and copies referenced resource
/// files (raster map images, documentation files) into the app documents
/// folder so the database records point to valid local paths.
class TestDatabaseLoader {
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
    print('[TestDatabaseLoader] Starting loadTestDatabase ...');

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
    print(
        '[TestDatabaseLoader] Database binary copied (${dbBytes.length} bytes) → $dbTargetPath');

    // ---- 2. Open the database ----
    final db = AppDatabase();

    // ---- 3. Copy raster map images ----
    try {
      final rasterMaps = await db.select(db.rasterMaps).get();
      print(
          '[TestDatabaseLoader] Found ${rasterMaps.length} raster map records');
      for (final rm in rasterMaps) {
        await _copyResourceFile(
          sourceDir: testMapsDir,
          storedFileName: rm.fileName,
          title: rm.title,
          documentsDir: documentsDir,
        );
      }
    } catch (e) {
      print('[TestDatabaseLoader] Warning: could not load raster map files: $e');
    }

    // ---- 4. Copy documentation files ----
    try {
      final docFiles = await db.select(db.documentationFiles).get();
      print(
          '[TestDatabaseLoader] Found ${docFiles.length} documentation file records');
      for (final df in docFiles) {
        await _copyResourceFile(
          sourceDir: testMapsDir, // docs may share source folder or have their own
          storedFileName: df.fileName,
          title: df.title,
          documentsDir: documentsDir,
        );
      }
    } catch (e) {
      print(
          '[TestDatabaseLoader] Warning: could not load documentation files: $e');
    }

    stopwatch.stop();
    print(
        '[TestDatabaseLoader] loadTestDatabase completed in ${stopwatch.elapsedMilliseconds} ms');
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
  static Future<void> _copyResourceFile({
    required String sourceDir,
    required String storedFileName,
    required String? title,
    required Directory documentsDir,
  }) async {
    final targetPath = p.join(documentsDir.path, storedFileName);
    final targetFile = File(targetPath);

    // Skip if file already exists
    if (await targetFile.exists()) return;

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
      print('[TestDatabaseLoader] Copied resource → $storedFileName');
    } else {
      print(
          '[TestDatabaseLoader] Warning: source not found for "$storedFileName" (title: "$title")');
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
