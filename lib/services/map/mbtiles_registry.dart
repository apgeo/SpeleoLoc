import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/services/map/mbtiles_reader.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Why an MBTiles import could not complete. Carried by
/// [MbTilesImportException] so the UI can show a specific message and, for
/// [alreadyExists], offer to overwrite.
enum MbTilesImportError { wrongExtension, notReadable, alreadyExists }

class MbTilesImportException implements Exception {
  final MbTilesImportError error;
  final String? fileName;

  const MbTilesImportException(this.error, {this.fileName});

  @override
  String toString() => 'MbTilesImportException($error, $fileName)';
}

/// Summary of one discovered `.mbtiles` file: enough to list it in the
/// layer picker and settings without keeping the SQLite handle open.
class MbTilesDescriptor {
  final String fileName;
  final String path;
  final MbTilesMetadata metadata;

  const MbTilesDescriptor({
    required this.fileName,
    required this.path,
    required this.metadata,
  });

  /// Display name: the metadata `name` when present, else the file name.
  String get displayName =>
      (metadata.name?.trim().isNotEmpty ?? false)
          ? metadata.name!.trim()
          : fileName;
}

/// Discovers MBTiles files dropped into the app-managed `mbtiles/` folder
/// inside the application documents directory (next to the app database).
/// See docs/workflows/mbtiles-layers.md for the user-facing workflow.
class MbTilesRegistry {
  static const String directoryName = 'mbtiles';

  final _log = AppLogger.of('MbTilesRegistry');

  /// Returns the scan folder, creating it on first use so users can find
  /// it via a file manager even before dropping any file in.
  Future<Directory> ensureDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}$directoryName');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Scans the folder for `*.mbtiles` files and reads each one's metadata.
  /// Unreadable/corrupt files are skipped with a warning rather than
  /// failing the whole scan.
  Future<List<MbTilesDescriptor>> scan() async {
    final dir = await ensureDirectory();
    final result = <MbTilesDescriptor>[];
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      if (!entity.path.toLowerCase().endsWith('.mbtiles')) continue;
      final fileName = entity.uri.pathSegments.last;
      try {
        final reader = MbTilesReader.open(entity.path);
        try {
          result.add(
            MbTilesDescriptor(
              fileName: fileName,
              path: entity.path,
              metadata: reader.metadata,
            ),
          );
        } finally {
          reader.dispose();
        }
      } catch (e, st) {
        _log.warning('Skipping unreadable MBTiles file $fileName', e, st);
      }
    }
    result.sort(
      (a, b) => a.displayName.toLowerCase().compareTo(
        b.displayName.toLowerCase(),
      ),
    );
    return result;
  }

  /// Copies the `.mbtiles` file at [sourcePath] into the scan folder.
  ///
  /// [sourcePath] is the cached copy handed back by the system document
  /// picker, so the copy needs no storage permission (the picker granted
  /// per-file access) and the destination is app-private storage. This is
  /// the supported way to add files on Android/iOS, where the scan folder
  /// itself is not reachable by a file manager — especially for
  /// debug/sideloaded installs.
  ///
  /// Throws [MbTilesImportException] when the file is not an `.mbtiles`
  /// file, is not a readable MBTiles database, or already exists and
  /// [overwrite] is false. Returns the imported file's descriptor.
  Future<MbTilesDescriptor> importFromPath(
    String sourcePath, {
    bool overwrite = false,
  }) async => importIntoDirectory(
    await ensureDirectory(),
    sourcePath,
    overwrite: overwrite,
  );

  /// Directory-explicit core of [importFromPath], separated so it can be
  /// exercised without the `path_provider` platform channel.
  @visibleForTesting
  Future<MbTilesDescriptor> importIntoDirectory(
    Directory dir,
    String sourcePath, {
    bool overwrite = false,
  }) async {
    final fileName = p.basename(sourcePath);
    if (!fileName.toLowerCase().endsWith('.mbtiles')) {
      throw MbTilesImportException(
        MbTilesImportError.wrongExtension,
        fileName: fileName,
      );
    }

    // Validate it is a readable MBTiles database before copying, so a bad
    // file never lands in the folder to be skipped on every later scan.
    final MbTilesMetadata metadata;
    try {
      final reader = MbTilesReader.open(sourcePath);
      try {
        metadata = reader.metadata;
      } finally {
        reader.dispose();
      }
    } catch (e, st) {
      _log.warning('Rejected unreadable MBTiles import $fileName', e, st);
      throw MbTilesImportException(
        MbTilesImportError.notReadable,
        fileName: fileName,
      );
    }

    final target = File(p.join(dir.path, fileName));
    if (target.existsSync() && !overwrite) {
      throw MbTilesImportException(
        MbTilesImportError.alreadyExists,
        fileName: fileName,
      );
    }

    await File(sourcePath).copy(target.path);
    return MbTilesDescriptor(
      fileName: fileName,
      path: target.path,
      metadata: metadata,
    );
  }
}
