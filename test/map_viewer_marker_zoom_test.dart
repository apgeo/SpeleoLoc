import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speleo_loc/data/source/database/app_database.dart';
import 'package:speleo_loc/widgets/raster_map_place_point_editor.dart';

void main() {
  testWidgets('markers remain visible after programmatic zoom', (
    tester,
  ) async {

    final tmp = await Directory.systemTemp.createTemp('rmp_test');
    final file = File('${tmp.path}/test.png');

    // create a simple 100x100 PNG
    final im = img.Image(width: 100, height: 100);
    for (var y = 0; y < im.height; y++) {
      for (var x = 0; x < im.width; x++) {
        im.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }
    file.writeAsBytesSync(img.encodePng(im));

    // Create a cave place + definition to show a marker at (50,50)
    final cavePlace = CavePlace(id: 1, caveId: 1, title: 'P1');
    final def = CavePlaceToRasterMapDefinition(id: 1, cavePlaceId: 1, rasterMapId: 1, xCoordinate: 50, yCoordinate: 50);
    final cpwd = CavePlaceWithDefinition(cavePlace, def);

    final controller = RasterMapPlacePointEditorController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: RasterMapPlacePointEditor(
              controller: controller,
              imageFile: file,
              cavePlacesWithDefinitions: [cpwd],
              useSimpleViewerForTests: true, // keep decoding sync for tests
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Overlay text is "<title> <cavePlaceId>" in the implementation
    expect(find.text('P1 1'), findsOneWidget);

    // Programmatic zoom shouldn't remove the overlay
    controller.zoomIn();
    await tester.pumpAndSettle();

    expect(find.text('P1 1'), findsOneWidget);
  }, skip: true);
}
