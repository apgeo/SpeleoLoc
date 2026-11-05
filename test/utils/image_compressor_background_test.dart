import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speleoloc/utils/image_compression_settings.dart';
import 'package:speleoloc/utils/image_compressor.dart';

import '../support/event_loop_stall.dart';

/// Compressing a phone photo takes seconds in pure Dart, so it runs on a
/// background isolate and the calling one keeps serving frames.
void main() {
  const settings = ImageCompressionSettings(
    enabled: true,
    maxResolution: 1280,
    quality: 70,
  );
  const allowedStall = Duration(milliseconds: 250);

  late Uint8List photo;

  setUpAll(() {
    // Invented, noisy enough that decoding and encoding take real work.
    final image = img.Image(width: 4000, height: 3000);
    for (final px in image) {
      final v = (px.x * 7 + px.y * 13 + (px.x * px.y) % 97) & 0xff;
      px
        ..r = v
        ..g = (v * 3) & 0xff
        ..b = 255 - v;
    }
    photo = Uint8List.fromList(img.encodeJpg(image, quality: 90));
  });

  test('gives the same bytes as compressing on the calling isolate', () async {
    final clock = Stopwatch()..start();
    final expected = ImageCompressor.compressBytes(photo, settings)!;
    // The stall checks below only mean something when the work itself takes
    // well over the stall they allow.
    expect(clock.elapsed, greaterThan(allowedStall * 3));

    final stall = await longestEventLoopStall(() async {
      final actual = await ImageCompressor.compressInBackground(
        photo,
        settings,
      );
      expect(actual, expected);
    });

    expect(stall, lessThan(allowedStall));
  });

  test('compresses a file in place without stalling the caller', () async {
    final dir = await Directory.systemTemp.createTemp('compress_bg_');
    addTearDown(() => dir.delete(recursive: true));
    final file = await File('${dir.path}/photo.jpg').writeAsBytes(photo);

    final stall = await longestEventLoopStall(
      () => ImageCompressor.compressFile(file, settings),
    );

    expect(stall, lessThan(allowedStall));
    final stored = img.decodeJpg(await file.readAsBytes())!;
    expect(stored.width, 1280);
    expect(stored.height, 960);
  });

  test('returns null without work when compression is off', () async {
    expect(
      await ImageCompressor.compressInBackground(
        photo,
        const ImageCompressionSettings(),
      ),
      isNull,
    );
  });
}
