import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speleo_loc/widgets/raster_map_place_point_editor.dart';

void main() {
  testWidgets('tapping in editor calls onImagePointChanged when not readonly', (
    tester,
  ) async {
    final tmp = await Directory.systemTemp.createTemp('rmp_test');
    final file = File('${tmp.path}/test.png');

    // create a simple 100x100 PNG
    final im = img.Image(width: 100, height: 100);
    for (var y = 0; y < im.height; y++) {
      for (var x = 0; x < im.width; x++) {
        im.setPixelRgba(x, y, 255, 0, 0, 255);
      }
    }
    file.writeAsBytesSync(img.encodePng(im));

    double? rx, ry;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 100,
            child: RasterMapPlacePointEditor(
              imageFile: file,
              cavePlacesWithDefinitions: [],
              onImagePointChanged: (x, y) {
                rx = x;
                ry = y;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final center = tester.getCenter(find.byType(RasterMapPlacePointEditor));
    await tester.tapAt(center);
    await tester.pumpAndSettle();

    expect(rx, isNotNull);
    expect(ry, isNotNull);
    expect(
      rx!,
      closeTo(50, 25),
    ); // allow some tolerance depending on PhotoView scale
    expect(ry!, closeTo(50, 25));
  }, skip: true);

  testWidgets('tapping in readonly editor does NOT call onImagePointChanged', (
    tester,
  ) async {
    final tmp = await Directory.systemTemp.createTemp('rmp_test');
    final file = File('${tmp.path}/test.png');
    final im = img.Image(width: 100, height: 100);
    for (var y = 0; y < im.height; y++) {
      for (var x = 0; x < im.width; x++) {
        im.setPixelRgba(x, y, 0, 255, 0, 255);
      }
    }
    file.writeAsBytesSync(img.encodePng(im));

    bool called = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 100,
            child: RasterMapPlacePointEditor(
              imageFile: file,
              cavePlacesWithDefinitions: [],
              isReadonly: true,
              onImagePointChanged: (_, __) {
                called = true;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final center = tester.getCenter(find.byType(RasterMapPlacePointEditor));
    await tester.tapAt(center);
    await tester.pumpAndSettle();

    expect(called, isFalse);
  });

  testWidgets('controller methods are callable and do not throw', (
    tester,
  ) async {
    final tmp = await Directory.systemTemp.createTemp('rmp_test');
    final file = File('${tmp.path}/test.png');
    final im = img.Image(width: 50, height: 50);
    for (var y = 0; y < im.height; y++) {
      for (var x = 0; x < im.width; x++) {
        im.setPixelRgba(x, y, 0, 0, 255, 255);
      }
    }
    file.writeAsBytesSync(img.encodePng(im));

    final controller = RasterMapPlacePointEditorController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 50,
            height: 50,
            child: RasterMapPlacePointEditor(
              controller: controller,
              imageFile: file,
              cavePlacesWithDefinitions: [],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Ensure controller methods can be invoked after widget is built
    expect(() => controller.zoomIn(), returnsNormally);
    expect(() => controller.zoomOut(), returnsNormally);
    expect(() => controller.resetZoom(), returnsNormally);
    expect(
      () => controller.zoomToPoint(10, 10, zoomLevel: 2.0),
      returnsNormally,
    );
  });
}
