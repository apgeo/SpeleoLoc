import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photo_view/photo_view.dart';
import 'package:speleoloc/widgets/raster_map/raster_map_picture_size.dart';
import 'package:speleoloc/widgets/raster_map_place_point_editor.dart';

/// Points on a map are kept in the picture's own pixels, whatever size the
/// picture is decoded to. A scan wider than the display cap is decoded
/// reduced, and a device's GPU may shrink one it cannot hold; neither may
/// shift where a tap lands on the picture.
void main() {
  late Directory tmp;
  late File imageFile;
  late Uint8List wide;

  setUpAll(() {
    // An invented scan wider than the display cap.
    final picture = img.Image(width: 9000, height: 600);
    img.fill(picture, color: img.ColorRgb8(240, 240, 240));
    wide = img.encodePng(picture, level: 1);
  });
  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('speleoloc_picture_frame_');
    imageFile = File('${tmp.path}/invented_scan.png')..writeAsBytesSync(wide);
  });
  tearDown(() => tmp.delete(recursive: true));

  group('the picture size', () {
    testWidgets('is read from the file', (tester) async {
      final size = await tester.runAsync(
        () => rasterMapPictureSize(FileImage(imageFile)),
      );
      expect(size, (width: 9000, height: 600));
    });

    testWidgets('is the picture\'s own, not a reduction the provider asks '
        'for', (tester) async {
      final size = await tester.runAsync(
        () => rasterMapPictureSize(ResizeImage(MemoryImage(wide), width: 900)),
      );
      expect(size, (width: 9000, height: 600));
    });

    testWidgets('is null for a missing file', (tester) async {
      final size = await tester.runAsync(
        () => rasterMapPictureSize(FileImage(File('${tmp.path}/gone.png'))),
      );
      expect(size, isNull);
    });
  });

  testWidgets('a picture wider than the cap is decoded to fit it', (
    tester,
  ) async {
    final decoded = await tester.runAsync(() async {
      final stream = rasterMapDisplayPicture(
        MemoryImage(wide),
      ).resolve(ImageConfiguration.empty);
      final info = await () {
        final done = Completer<ImageInfo>();
        stream.addListener(ImageStreamListener((i, _) => done.complete(i)));
        return done.future;
      }();
      final size = (info.image.width, info.image.height);
      info.dispose();
      return size;
    });
    expect(decoded, (rasterMapDisplayMaxSide, 546));
  });

  testWidgets('a tap lands in the picture\'s own pixels when the picture is '
      'decoded reduced', (tester) async {
    double? tappedX;
    double? tappedY;
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RasterMapPlacePointEditor(
              controller: RasterMapPlacePointEditorController(
                initialTapDefinesNewPoint: true,
              ),
              imageFile: imageFile,
              // Stands in for a decoder that hands back half the picture's
              // pixels, as a GPU does with a picture it cannot hold.
              imageProvider: ResizeImage(MemoryImage(wide), width: 4500),
              cavePlacesWithDefinitions: const [],
              onImagePointChanged: (x, y) {
                tappedX = x;
                tappedY = y;
              },
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final map = tester.getRect(find.byType(PhotoView));
    // The picture is contained across the map's width, so 800 px show its
    // 9000: the map's horizontal middle is the picture's x = 4500.
    await tester.tapAt(map.topLeft + Offset(map.width / 2, 20));
    await tester.pump(const Duration(milliseconds: 400));

    expect(tappedX, closeTo(4500, 2));
    expect(tappedY, closeTo(20 * 9000 / map.width, 2));
  });
}
