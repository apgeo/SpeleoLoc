import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// On-disk cache of online XYZ tiles under
/// `<root>/<sourceId>/<z>/<x>_<y>.png`, so any previously viewed area
/// keeps rendering without connectivity. MBTiles layers have their own
/// files and never touch this cache.
class TileDiskCache {
  TileDiskCache(this.root);

  final Directory root;

  /// Tiles younger than this are served without hitting the network.
  static const Duration freshFor = Duration(days: 7);

  File fileFor(String sourceId, int z, int x, int y) =>
      File(p.join(root.path, sourceId, '$z', '${x}_$y.png'));

  Future<({Uint8List bytes, DateTime modified})?> read(
    String sourceId,
    int z,
    int x,
    int y,
  ) async {
    final file = fileFor(sourceId, z, x, y);
    try {
      if (!file.existsSync()) return null;
      return (
        bytes: await file.readAsBytes(),
        modified: file.lastModifiedSync(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    String sourceId,
    int z,
    int x,
    int y,
    List<int> bytes,
  ) async {
    // Cache write failures (full disk, races) must never break rendering.
    // Write-then-rename so an interrupted write can't leave a truncated
    // tile that read() would happily serve as fresh.
    try {
      final file = fileFor(sourceId, z, x, y);
      file.parent.createSync(recursive: true);
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsBytes(bytes);
      await tmp.rename(file.path);
    } catch (_) {}
  }

  Future<int> totalSizeBytes() async {
    if (!root.existsSync()) return 0;
    var total = 0;
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += entity.lengthSync();
        } catch (_) {}
      }
    }
    return total;
  }

  Future<void> clear() async {
    if (root.existsSync()) {
      await root.delete(recursive: true);
    }
  }
}

/// True when [bytes] start like one of the raster formats tile servers
/// serve (PNG/JPEG/GIF/WebP). Guards the cache against HTTP-200 error
/// pages — captive portals and CDN error bodies — which would otherwise
/// be served as "fresh" tiles for a week.
bool looksLikeImageBytes(List<int> bytes) {
  if (bytes.length < 12) return false;
  if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E) return true;
  if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
  if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return true;
  return bytes[0] == 0x52 && // RIFF....WEBP
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50;
}

/// The cache-then-network fetch policy used per tile: a fresh cached tile
/// skips the network entirely; anything else is fetched, sniffed to be a
/// real image and cached; on fetch failure (including a non-image body) a
/// stale cached tile beats an error tile. Throws only when there is
/// neither a usable response nor a cached copy.
Future<Uint8List> loadTileBytes({
  required TileDiskCache cache,
  required String sourceId,
  required int z,
  required int x,
  required int y,
  required Uri url,
  required http.Client client,
  Map<String, String> headers = const {},
  DateTime Function() now = DateTime.now,
}) async {
  final cached = await cache.read(sourceId, z, x, y);
  if (cached != null &&
      now().difference(cached.modified) < TileDiskCache.freshFor) {
    return cached.bytes;
  }
  try {
    final response = await client.get(url, headers: headers);
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}', uri: url);
    }
    if (!looksLikeImageBytes(response.bodyBytes)) {
      throw HttpException('Non-image tile response', uri: url);
    }
    await cache.write(sourceId, z, x, y, response.bodyBytes);
    return response.bodyBytes;
  } catch (_) {
    if (cached != null) return cached.bytes;
    rethrow;
  }
}
