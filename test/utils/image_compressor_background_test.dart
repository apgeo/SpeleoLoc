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
  // Stalls are compared with the length of the work rather than a fixed
  // budget: the suite runs many files at once on a shared machine, which
  // stretches both alike, while blocking work stalls for all of its length.
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
    final blocking = clock.elapsed;

    final stall = await longestEventLoopStall(() async {
      final actual = await ImageCompressor.compressInBackground(
        photo,
        settings,
      );
      expect(actual, expected);
    });

    expect(stall, lessThan(blocking ~/ 3));
  });

  test('compresses a file in place without stalling the caller', () async {
    final dir = await Directory.systemTemp.createTemp('compress_bg_');
    addTearDown(() => dir.delete(recursive: true));
    final file = await File('${dir.path}/photo.jpg').writeAsBytes(photo);

    final clock = Stopwatch()..start();
    final stall = await longestEventLoopStall(
      () => ImageCompressor.compressFile(file, settings),
    );

    expect(stall, lessThan(clock.elapsed ~/ 3));
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
