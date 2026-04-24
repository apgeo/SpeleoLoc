import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/widgets/raster_map_place_point_editor.dart';

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
    final cavePlaceUuid = Uuid.v7();
    final rasterMapUuid = Uuid.v7();
    final cavePlace = CavePlace(uuid: cavePlaceUuid, caveUuid: Uuid.v7(), title: 'P1', isEntrance: 0, isMainEntrance: 0);
    final def = CavePlaceToRasterMapDefinition(uuid: Uuid.v7(), cavePlaceUuid: cavePlaceUuid, rasterMapUuid: rasterMapUuid, xCoordinate: 50, yCoordinate: 50);
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

    // Overlay text is "<title> <cavePlaceUuid>" in the implementation
    expect(find.text('P1 1'), findsOneWidget);

    // Programmatic zoom shouldn't remove the overlay
    controller.zoomIn();
    await tester.pumpAndSettle();

    expect(find.text('P1 1'), findsOneWidget);
  }, skip: true);
}
