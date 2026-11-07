import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/widgets/raster_map_place_point_editor.dart';

/// A point tapped on the map and not yet saved: declining the save prompt
/// that an action raises keeps it unsaved and stops the action, and nothing
/// the editor does on its own saves it through the save-and-close handler.
void main() {
  late Directory tmp;
  late File imageFile;
  late Uint8List png;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('speleoloc_pending_point_');
    final picture = img.Image(width: 200, height: 200);
    img.fill(picture, color: img.ColorRgb8(240, 240, 240));
    png = img.encodePng(picture);
    imageFile = File('${tmp.path}/invented_map.png')..writeAsBytesSync(png);
  });
  tearDown(() => tmp.delete(recursive: true));

  final place = CavePlace(
    uuid: Uuid.v7(),
    caveUuid: Uuid.v7(),
    title: 'Invented chamber',
    isEntrance: 0,
    isMainEntrance: 0,
  );
  final mapUuid = Uuid.v7();

  Future<void> pumpEditor(
    WidgetTester tester, {
    required Future<bool> Function(Uuid, Uuid, double, double) onAutoSave,
    required VoidCallback onSaveAndClose,
    Future<void> Function(Uuid, Uuid, double, double)? onSavePoint,
  }) async {
    final controller = RasterMapPlacePointEditorController(
      cavePlaceUuid: place.uuid,
      initialTapDefinesNewPoint: true,
    );
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
              cavePlacesWithDefinitions: [CavePlaceWithDefinition(place, null)],
              selectedRasterMapUuid: mapUuid,
              caveUuid: place.caveUuid,
              onAutoSaveRequested: onAutoSave,
              onSaveDefinitionRequested: onSaveAndClose,
              onSavePointRequested: onSavePoint,
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

  Future<void> tapThePicture(WidgetTester tester) async {
    await tester.tapAt(
      tester.getCenter(find.byType(RasterMapPlacePointEditor)),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  for (final (label, icon) in const [
    ('open place', Icons.open_in_new),
    ('documents', Icons.description),
  ]) {
    testWidgets('declining the prompt before "$label" saves nothing and '
        'stays on the map', (tester) async {
      var prompts = 0;
      var saveAndClose = 0;
      await pumpEditor(
        tester,
        onAutoSave: (_, _, _, _) async {
          prompts++;
          return false;
        },
        onSaveAndClose: () => saveAndClose++,
      );
      await tapThePicture(tester);

      await tester.tap(find.byIcon(icon));
      await settle(tester);

      expect(prompts, 1);
      expect(saveAndClose, 0);
      expect(find.byType(RasterMapPlacePointEditor), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
    });
  }

  testWidgets('accepting the prompt saves once and keeps the map open', (
    tester,
  ) async {
    var prompts = 0;
    var saveAndClose = 0;
    await pumpEditor(
      tester,
      onAutoSave: (_, _, _, _) async {
        prompts++;
        return true;
      },
      onSaveAndClose: () => saveAndClose++,
    );
    await tapThePicture(tester);

    await tester.tap(find.byIcon(Icons.info_outline));
    await settle(tester);

    expect(prompts, 1);
    expect(saveAndClose, 0);
    expect(find.byType(RasterMapPlacePointEditor), findsOneWidget);
  });

  testWidgets('leaving the editor saves the point without closing anything', (
    tester,
  ) async {
    var saveAndClose = 0;
    var savePoint = 0;
    await pumpEditor(
      tester,
      onAutoSave: (_, _, _, _) async => true,
      onSaveAndClose: () => saveAndClose++,
      onSavePoint: (_, _, _, _) async => savePoint++,
    );
    await tapThePicture(tester);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();

    expect(savePoint, 1);
    expect(saveAndClose, 0);
  });
}
