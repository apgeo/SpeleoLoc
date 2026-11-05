import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photo_view/photo_view.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/widgets/raster_map/raster_map_viewport_layer.dart';
import 'package:speleoloc/widgets/raster_map_nav_bar.dart';
import 'package:speleoloc/widgets/raster_map_place_point_editor.dart';

/// Panning the map moves its markers frame by frame and rebuilds nothing
/// else: not the editor, not its nav bar. A pan runs at gesture rate, and
/// rebuilding the whole editor each frame is what made it stutter.
void main() {
  late Directory tmp;
  late File imageFile;
  late Uint8List png;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('speleoloc_pan_rebuild_');
    final picture = img.Image(width: 400, height: 400);
    img.fill(picture, color: img.ColorRgb8(240, 240, 240));
    png = img.encodePng(picture);
    imageFile = File('${tmp.path}/invented_map.png')..writeAsBytesSync(png);
  });
  tearDown(() async {
    debugOnRebuildDirtyWidget = null;
    await tmp.delete(recursive: true);
  });

  final caveUuid = Uuid.v7();
  final mapUuid = Uuid.v7();
  CavePlaceWithDefinition placeAt(String title, int x, int y) {
    final place = CavePlace(
      uuid: Uuid.v7(),
      caveUuid: caveUuid,
      title: title,
      isEntrance: 0,
      isMainEntrance: 0,
    );
    return CavePlaceWithDefinition(
      place,
      CavePlaceToRasterMapDefinition(
        uuid: Uuid.v7(),
        cavePlaceUuid: place.uuid,
        rasterMapUuid: mapUuid,
        xCoordinate: x,
        yCoordinate: y,
      ),
    );
  }

  final places = [
    placeAt('Invented hall', 60, 60),
    placeAt('Invented sump', 120, 90),
    placeAt('Invented shaft', 80, 140),
  ];

  Future<void> pumpEditor(
    WidgetTester tester,
    RasterMapPlacePointEditorController controller,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RasterMapPlacePointEditor(
              controller: controller,
              imageFile: imageFile,
              imageProvider: MemoryImage(png),
              cavePlacesWithDefinitions: places,
              selectedRasterMapUuid: mapUuid,
              caveUuid: caveUuid,
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('a pan rebuilds the marker layer only', (tester) async {
    final controller = RasterMapPlacePointEditorController(showNavBar: true);
    await pumpEditor(tester, controller);
    // Zoomed in, so the picture overflows the viewport and can be panned.
    controller.zoomToPoint(120, 90, zoomLevel: 4);
    await tester.pump(const Duration(milliseconds: 16));
    final label = find
        .descendant(
          of: find.byType(RasterMapViewportLayer),
          matching: find.text('Invented sump'),
        )
        .first;
    final labelBefore = tester.getTopLeft(label);

    var editorBuilds = 0;
    var navBarBuilds = 0;
    var markerLayerBuilds = 0;
    debugOnRebuildDirtyWidget = (element, _) {
      final widget = element.widget;
      if (widget is RasterMapPlacePointEditor) editorBuilds++;
      if (widget is RasterMapNavBar) navBarBuilds++;
      if (widget is ListenableBuilder &&
          element.findAncestorWidgetOfExactType<RasterMapViewportLayer>() !=
              null) {
        markerLayerBuilds++;
      }
    };

    final map = tester.getRect(find.byType(PhotoView));
    // Clear of the markers, which sit around the centre, and of the overlay
    // controls along the map's edges.
    final gesture = await tester.startGesture(
      map.center + const Offset(150, 150),
    );
    const frames = 12;
    for (var i = 0; i < frames; i++) {
      await gesture.moveBy(const Offset(-12, -8));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 16));
    debugOnRebuildDirtyWidget = null;

    final moved = tester.getTopLeft(label) - labelBefore;
    expect(moved.dx, lessThan(-60), reason: 'the markers follow the picture');
    expect(moved.dy, lessThan(-40), reason: 'the markers follow the picture');
    expect(markerLayerBuilds, greaterThanOrEqualTo(frames ~/ 2));
    expect(editorBuilds, 0);
    expect(navBarBuilds, 0);
  });
}
