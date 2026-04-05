import 'dart:io';
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
    final bytes = await sourceFile.readAsBytes();
    final result = compressBytes(bytes, settings);
    if (result == null) return;
    await sourceFile.writeAsBytes(result, flush: true);
  }

  /// Compresses raw image [bytes] according to [settings].
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

    // Encode as JPEG with the configured quality.
    return Uint8List.fromList(
      img.encodeJpg(processed, quality: settings.quality),
    );
  }
}
