import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:speleoloc/utils/image_compression_settings.dart';

/// Utility for compressing and resizing images on import.
class ImageCompressor {
  ImageCompressor._();

  /// Compresses [sourceFile] according to [settings] and writes the result
  /// back to [sourceFile] (in-place).
  ///
  /// If compression is disabled or the file is not a decodable image, the
  /// file is left untouched.
  static Future<void> compressFile(
    File sourceFile,
    ImageCompressionSettings settings,
  ) async {
    if (!settings.enabled) return;
    final path = sourceFile.path;
    await Isolate.run(() {
      final result = compressBytes(File(path).readAsBytesSync(), settings);
      if (result != null) File(path).writeAsBytesSync(result, flush: true);
    });
  }

  /// [compressBytes] on a background isolate.
  ///
  /// Decoding, resizing and re-encoding a phone photo in pure Dart takes
  /// seconds; on the UI isolate the screen would freeze for all of it, and a
  /// folder import would freeze it once per photo.
  static Future<Uint8List?> compressInBackground(
    Uint8List bytes,
    ImageCompressionSettings settings,
  ) async {
    if (!settings.enabled) return null;
    return Isolate.run(() => compressBytes(bytes, settings));
  }

  /// Compresses raw image [bytes] according to [settings], on the calling
  /// isolate; see [compressInBackground].
  ///
  /// Returns the compressed JPEG bytes, or `null` if the input could not be
  /// decoded (e.g. non-image file).
  static Uint8List? compressBytes(
    Uint8List bytes,
    ImageCompressionSettings settings,
  ) {
    if (!settings.enabled) return null;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    // Resize if either dimension exceeds maxResolution.
    final maxRes = settings.maxResolution;
    img.Image processed = decoded;
    if (decoded.width > maxRes || decoded.height > maxRes) {
      if (decoded.width >= decoded.height) {
        processed = img.copyResize(decoded, width: maxRes);
      } else {
        processed = img.copyResize(decoded, height: maxRes);
      }
    }

    // Encode as JPEG with the configured quality. The decoded image carries
    // its EXIF block, so the re-encode keeps it, GPS position included. That
    // is deliberate: the server decides who may see a location, and the
    // caver's own copy must not lose it. Do not strip it here.
    return Uint8List.fromList(
      img.encodeJpg(processed, quality: settings.quality),
    );
  }
}
