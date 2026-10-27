import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speleoloc/utils/image_compression_settings.dart';
import 'package:speleoloc/utils/image_compressor.dart';

/// Compression keeps the picture's EXIF block, GPS position included: the
/// server decides who may see a location, so the device does not strip it.
void main() {
  test('GPS EXIF survives compression', () {
    final image = img.Image(width: 64, height: 48);
    img.fill(image, color: img.ColorRgb8(30, 120, 200));
    // Invented position, not taken from any real place.
    image.exif.gpsIfd['GPSLatitudeRef'] = img.IfdValueAscii('N');
    image.exif.gpsIfd['GPSLatitude'] = img.IfdValueRational(12345, 100);
    image.exif.gpsIfd['GPSLongitudeRef'] = img.IfdValueAscii('E');
    image.exif.gpsIfd['GPSLongitude'] = img.IfdValueRational(12345, 100);
    final source = Uint8List.fromList(img.encodeJpg(image));
    expect(img.decodeJpg(source)!.exif.gpsIfd.isEmpty, isFalse);

    final compressed = ImageCompressor.compressBytes(
      source,
      const ImageCompressionSettings(
        enabled: true,
        maxResolution: 32,
        quality: 50,
      ),
    )!;

    final decoded = img.decodeJpg(compressed)!;
    expect(decoded.width, 32);
    final gps = decoded.exif.gpsIfd;
    expect(gps['GPSLatitudeRef']?.toString(), 'N');
    expect(gps['GPSLongitudeRef']?.toString(), 'E');
    expect(gps['GPSLatitude'], isNotNull);
    expect(gps['GPSLongitude'], isNotNull);
  });
}
