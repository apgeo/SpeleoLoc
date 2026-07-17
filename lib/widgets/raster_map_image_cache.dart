import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:speleoloc/utils/raw_image_data.dart';
import 'package:image/image.dart' as img;

/// Top-level sync decoder used by `compute` in an isolate. Returns a simple
/// serializable map with width/height and raw RGBA bytes (List<int>).
Map<String, dynamic>? decodeImageToRawSync(String path) {
  try {
    final bytes = File(path).readAsBytesSync();
    final image = img.decodeImage(bytes);
    if (image == null) return null;
    final pix = image.getBytes();
    return {'w': image.width, 'h': image.height, 'pixels': pix};
  } catch (_) {
    return null;
  }
}

/// Persistent in-memory cache for decoded [RawImageData] keyed by absolute
/// file path. Storing the Future prevents duplicate isolate work when multiple
/// widgets request the same image concurrently.
///
/// Bounded by [maxCacheBytes] of decoded RGBA pixels rather than an entry
/// count: five 4000×3000 scans is ~240 MB while five small maps is a few MB,
/// so a fixed entry cap either wastes memory or evicts needlessly. The most
/// recent entry is always kept, even when it alone exceeds the budget.
const int maxCacheBytes = 128 * 1024 * 1024;
final Map<String, Future<RawImageData?>?> decodedImageCache = {};
final List<String> _cacheInsertionOrder = [];

/// Resolved pixel-buffer sizes; entries still decoding are absent (count 0).
final Map<String, int> _cacheSizeBytes = {};

void _evictOverBudget() {
  var total = 0;
  for (final size in _cacheSizeBytes.values) {
    total += size;
  }
  while (total > maxCacheBytes && _cacheInsertionOrder.length > 1) {
    final oldest = _cacheInsertionOrder.removeAt(0);
    decodedImageCache.remove(oldest);
    total -= _cacheSizeBytes.remove(oldest) ?? 0;
  }
}

/// Returns a cached [RawImageData] for [path] or decodes it (in an isolate)
/// and caches the result. Safe to call from any file; callers get a
/// Future<RawImageData?>.
Future<RawImageData?> decodeImageToRawCached(String path) {
  final existing = decodedImageCache[path];
  if (existing != null) return existing;

  final future = compute(decodeImageToRawSync, path)
      .then((result) {
        if (result == null) return null;
        final rawPixels = result['pixels'] as List;
        final w = result['w'] as int;
        final h = result['h'] as int;
        // The isolate hands back a Uint8List; use it directly — copying a
        // full-map RGBA buffer (tens of MB) on the UI isolate causes jank.
        final pixels = rawPixels is Uint8List
            ? rawPixels
            : Uint8List.fromList(rawPixels.cast<int>());

        final expectedRGBA = w * h * 4;

        // If the decoder returned RGB (3 bytes/pixel), convert to RGBA.
        if (pixels.length == w * h * 3) {
          final rgba = Uint8List(expectedRGBA);
          for (int src = 0, dst = 0; src < pixels.length; src += 3, dst += 4) {
            rgba[dst] = pixels[src];
            rgba[dst + 1] = pixels[src + 1];
            rgba[dst + 2] = pixels[src + 2];
            rgba[dst + 3] = 255;
          }
          return RawImageData(w, h, rgba);
        }

        if (pixels.length == expectedRGBA) {
          return RawImageData(w, h, pixels);
        }

        // Fallback: trim or pad the buffer to avoid later range errors.
        if (pixels.length > expectedRGBA) {
          final trimmed = pixels.sublist(0, expectedRGBA);
          return RawImageData(w, h, Uint8List.fromList(trimmed));
        } else {
          final padded = Uint8List(expectedRGBA);
          padded.setRange(0, pixels.length, pixels);
          return RawImageData(w, h, padded);
        }
      })
      .catchError((_) => null);

  decodedImageCache[path] = future;
  _cacheInsertionOrder.remove(path);
  _cacheInsertionOrder.add(path);
  // Size is known only once the decode resolves; record it then and evict.
  // The identity check skips entries invalidated (or re-decoded) meanwhile.
  unawaited(
    future.then((raw) {
      if (raw != null && identical(decodedImageCache[path], future)) {
        _cacheSizeBytes[path] = raw.pixels.length;
        _evictOverBudget();
      }
    }),
  );
  _evictOverBudget();
  return future;
}

/// Drops the cached decode for a single [path]. Call this whenever the file
/// at [path] is rewritten with different content, so a later
/// [decodeImageToRawCached] re-decodes it instead of serving stale pixels
/// (finding 4.8). A no-op when [path] isn't cached.
void invalidateDecodedImage(String path) {
  decodedImageCache.remove(path);
  _cacheInsertionOrder.remove(path);
  _cacheSizeBytes.remove(path);
}

/// Clears the decoded-image cache (useful for tests or low-memory scenarios).
void clearDecodedImageCache() {
  decodedImageCache.clear();
  _cacheInsertionOrder.clear();
  _cacheSizeBytes.clear();
}
