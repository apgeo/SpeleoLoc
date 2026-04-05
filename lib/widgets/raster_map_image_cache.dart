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
/// Limited to [maxCacheEntries] entries to avoid unbounded memory growth.
const int maxCacheEntries = 5;
final Map<String, Future<RawImageData?>?> decodedImageCache = {};
final List<String> _cacheInsertionOrder = [];

/// Returns a cached [RawImageData] for [path] or decodes it (in an isolate)
/// and caches the result. Safe to call from any file; callers get a
/// Future<RawImageData?>.
Future<RawImageData?> decodeImageToRawCached(String path) {
  final existing = decodedImageCache[path];
  if (existing != null) return existing;

  final future = compute(decodeImageToRawSync, path).then((result) {
    if (result == null) return null;
    final rawPixels = (result['pixels'] as List).cast<int>();
    final w = result['w'] as int;
    final h = result['h'] as int;
    final pixels = Uint8List.fromList(rawPixels);

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
  }).catchError((_) => null);

  decodedImageCache[path] = future;
  _cacheInsertionOrder.remove(path);
  _cacheInsertionOrder.add(path);
  while (_cacheInsertionOrder.length > maxCacheEntries) {
    final oldest = _cacheInsertionOrder.removeAt(0);
    decodedImageCache.remove(oldest);
  }
  return future;
}

/// Clears the decoded-image cache (useful for tests or low-memory scenarios).
void clearDecodedImageCache() {
  decodedImageCache.clear();
  _cacheInsertionOrder.clear();
}
