import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:speleoloc/utils/raw_image_data.dart';

/// Longest side, in pixels, of the copy label colours are sampled from.
///
/// A label's colour depends on the tone around its point, not on single
/// pixels, so a reduced copy answers as well as the full picture. Survey
/// scans run to tens of megapixels: their full RGBA would be hundreds of MB
/// held for a handful of samples, while 1024 px keeps a copy under 4 MB.
const int labelSampleMaxSide = 1024;

/// Decodes the picture at [path] through the engine at no more than
/// [labelSampleMaxSide] px on its longest side, as straight RGBA.
///
/// The engine decodes every format the map itself is shown from, in the same
/// orientation, and always hands back four 8-bit channels, whatever the
/// file's own layout (indexed, grey, 16-bit). The decode and the read-back
/// run off the UI isolate's event loop.
Future<RawImageData?> decodeImageForLabelSampling(String path) async {
  final buffer = await ui.ImmutableBuffer.fromFilePath(path);
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? image;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final width = descriptor.width;
    final height = descriptor.height;
    final reduce = math.min(1.0, labelSampleMaxSide / math.max(width, height));
    codec = await descriptor.instantiateCodec(
      targetWidth: math.max(1, (width * reduce).round()),
      targetHeight: math.max(1, (height * reduce).round()),
    );
    image = (await codec.getNextFrame()).image;
    final rgba = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    if (rgba == null) return null;
    return RawImageData(
      width,
      height,
      rgba.buffer.asUint8List(rgba.offsetInBytes, rgba.lengthInBytes),
      gridWidth: image.width,
      gridHeight: image.height,
    );
  } finally {
    image?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer.dispose();
  }
}

/// Persistent in-memory cache for decoded [RawImageData] keyed by absolute
/// file path. Storing the Future prevents duplicate isolate work when multiple
/// widgets request the same image concurrently.
///
/// Bounded by [maxCacheBytes] of decoded RGBA pixels rather than an entry
/// count, since small maps decode to far less than [labelSampleMaxSide]
/// allows. The most recent entry is always kept.
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

/// Returns a cached [RawImageData] for [path] or decodes it with
/// [decodeImageForLabelSampling] and caches the result; null when the picture
/// cannot be decoded.
Future<RawImageData?> decodeImageToRawCached(String path) {
  final existing = decodedImageCache[path];
  if (existing != null) return existing;

  final future = decodeImageForLabelSampling(
    path,
  ).then<RawImageData?>((raw) => raw, onError: (Object _) => null);

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
