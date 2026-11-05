import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speleoloc/utils/raw_image_data.dart';
import 'package:speleoloc/widgets/raster_map_image_cache.dart';

/// Label colours are sampled from a picture whatever its pixel layout, at the
/// picture's own coordinates, from a copy small enough to keep: scanned
/// line-art is often greyscale or indexed, and survey scans run to tens of
/// megapixels.
void main() {
  late Directory tmp;

  setUp(() async {
    clearDecodedImageCache();
    tmp = await Directory.systemTemp.createTemp('speleoloc_label_sampling_');
  });
  tearDown(() async {
    clearDecodedImageCache();
    await tmp.delete(recursive: true);
  });

  /// Left half dark, right half light, as an invented scan in [picture]'s
  /// layout.
  String write(String name, img.Image picture) {
    for (var y = 0; y < picture.height; y++) {
      for (var x = 0; x < picture.width; x++) {
        final v =
            (x < picture.width ~/ 2 ? 20 : 230) * picture.maxChannelValue / 255;
        picture.setPixelRgb(x, y, v, v, v);
      }
    }
    final file = File('${tmp.path}/$name.png')
      ..writeAsBytesSync(img.encodePng(picture));
    return file.path;
  }

  Future<RawImageData> decode(WidgetTester tester, String path) async {
    final raw = await tester.runAsync(() => decodeImageToRawCached(path));
    expect(raw, isNotNull);
    return raw!;
  }

  void expectHalves(RawImageData raw) {
    final dark = raw.getPixel(raw.width ~/ 4, raw.height ~/ 2);
    final light = raw.getPixel(raw.width * 3 ~/ 4, raw.height ~/ 2);
    expect([dark.r, dark.g, dark.b, dark.a], [20, 20, 20, 255]);
    expect([light.r, light.g, light.b, light.a], [230, 230, 230, 255]);
  }

  testWidgets('a greyscale picture samples its own tones', (tester) async {
    final path = write(
      'grey',
      img.Image(width: 64, height: 48, numChannels: 1),
    );
    final raw = await decode(tester, path);

    expect((raw.width, raw.height), (64, 48));
    expectHalves(raw);
  });

  testWidgets('a colour picture without alpha samples its own tones', (
    tester,
  ) async {
    final path = write('rgb', img.Image(width: 64, height: 48));
    final raw = await decode(tester, path);

    expect((raw.width, raw.height), (64, 48));
    expectHalves(raw);
  });

  testWidgets('a 16-bit picture samples its own tones', (tester) async {
    final path = write(
      'deep',
      img.Image(width: 64, height: 48, format: img.Format.uint16),
    );
    final raw = await decode(tester, path);

    expect((raw.width, raw.height), (64, 48));
    expectHalves(raw);
  });

  testWidgets('a large scan is sampled from a reduced copy, in its own '
      'coordinates', (tester) async {
    final path = write('large', img.Image(width: 3000, height: 1500));
    final raw = await decode(tester, path);

    expect((raw.width, raw.height), (3000, 1500));
    expect(raw.gridWidth, labelSampleMaxSide);
    expect(raw.gridHeight, labelSampleMaxSide ~/ 2);
    expect(raw.pixels.length, raw.gridWidth * raw.gridHeight * 4);
    expectHalves(raw);
  });
}
