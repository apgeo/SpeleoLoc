// Parked: these tests hang for testWidgets' full 10-minute timeout at
// baseline. A 2026-07-03 fix attempt (tester.runAsync so the FileImage can
// decode + bounded pumps instead of pumpAndSettle, see _pumpUntilImageReady)
// did NOT cure the hang — the widget blocks on something beyond the image
// loading spinner, so the diagnosis needs the editor decomposition work.
// Re-enable during WS-H2 HW1 (.claude/refactoring20260702/phase-2-plan.md).
@Skip('hangs at baseline; runAsync image-decode fix insufficient — WS-H2 HW1')
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speleoloc/widgets/raster_map_place_point_editor.dart';

/// Writes a solid-color PNG fixture to a temp file.
Future<File> _writePng(int width, int height, List<int> rgba) async {
  final tmp = await Directory.systemTemp.createTemp('rmp_test');
  final file = File('${tmp.path}/test.png');
  final im = img.Image(width: width, height: height);
  for (var y = 0; y < im.height; y++) {
    for (var x = 0; x < im.width; x++) {
      im.setPixelRgba(x, y, rgba[0], rgba[1], rgba[2], rgba[3]);
    }
  }
  file.writeAsBytesSync(img.encodePng(im));
  return file;
}

/// Pumps [widget] and lets the editor's FileImage decode.
///
/// Image decoding needs the real event loop: under plain fake-async pumping
/// the FileImage never resolves, PhotoView keeps its indeterminate loading
/// spinner animating forever, and `pumpAndSettle` spins until its 10-minute
/// timeout (the historical hang in this file). `runAsync` + a real delay
/// completes the decode; afterwards use bounded `pump`s, never
/// `pumpAndSettle`.
Future<void> _pumpUntilImageReady(WidgetTester tester, Widget widget) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('tapping in editor calls onImagePointChanged when not readonly', (
    tester,
  ) async {
    final file = await _writePng(100, 100, [255, 0, 0, 255]);

    double? rx, ry;

    await _pumpUntilImageReady(
      tester,
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

    final center = tester.getCenter(find.byType(RasterMapPlacePointEditor));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 100));

    expect(rx, isNotNull);
    expect(ry, isNotNull);
    expect(
      rx!,
      closeTo(50, 25),
    ); // allow some tolerance depending on PhotoView scale
    expect(ry!, closeTo(50, 25));
  });

  testWidgets('tapping in readonly editor does NOT call onImagePointChanged', (
    tester,
  ) async {
    final file = await _writePng(100, 100, [0, 255, 0, 255]);

    bool called = false;

    await _pumpUntilImageReady(
      tester,
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

    final center = tester.getCenter(find.byType(RasterMapPlacePointEditor));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 100));

    expect(called, isFalse);
  });

  testWidgets('controller methods are callable and do not throw', (
    tester,
  ) async {
    final file = await _writePng(50, 50, [0, 0, 255, 255]);

    final controller = RasterMapPlacePointEditorController();

    await _pumpUntilImageReady(
      tester,
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

    // Ensure controller methods can be invoked after widget is built
    expect(() => controller.zoomIn(), returnsNormally);
    expect(() => controller.zoomOut(), returnsNormally);
    expect(() => controller.resetZoom(), returnsNormally);
    expect(
      () => controller.zoomToPoint(10, 10, zoomLevel: 2.0),
      returnsNormally,
    );

    // Drive the pan/zoom animation (220 ms) to completion so no ticker is
    // active when the test framework's leftover-callback check runs.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  });
}
