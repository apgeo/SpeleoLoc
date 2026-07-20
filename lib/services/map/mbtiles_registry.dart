import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/services/map/mbtiles_reader.dart';
import 'package:speleoloc/utils/app_logger.dart';

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
}
