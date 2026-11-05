import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/raster_map_place_point_editor.dart';

/// The controls laid over the map stay clear of each other on a small phone:
/// the tap-mode hint in the bottom-left corner never covers the zoom buttons
/// in the bottom-right one.
void main() {
  late Directory tmp;
  late File imageFile;
  late Uint8List png;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('speleoloc_overlay_layout_');
    final picture = img.Image(width: 200, height: 100);
    img.fill(picture, color: img.ColorRgb8(240, 240, 240));
    png = img.encodePng(picture);
    imageFile = File('${tmp.path}/invented_map.png')..writeAsBytesSync(png);
  });
  tearDown(() => tmp.delete(recursive: true));
  tearDownAll(() => LocServ.inst.setLocale('en'));

  for (final locale in const ['en', 'ro']) {
    testWidgets('the tap-mode hint leaves the zoom buttons uncovered at '
        '360 dp ($locale)', (tester) async {
      await tester.runAsync(() async {
        await LocServ.inst.setLocale(locale);
        await LocServ.inst.load();
      });
      await tester.binding.setSurfaceSize(const Size(360, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RasterMapPlacePointEditor(
                controller: RasterMapPlacePointEditorController(
                  initialTapDefinesNewPoint: true,
                  showTapModeCheckbox: true,
                ),
                imageFile: imageFile,
                imageProvider: MemoryImage(png),
                cavePlacesWithDefinitions: const [],
              ),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final hint = find.ancestor(
        of: find.text(LocServ.inst.t('status_define_point')),
        matching: find.byType(Container),
      );
      expect(hint, findsWidgets);
      final hintRect = tester.getRect(hint.first);
      for (final icon in const [Icons.remove, Icons.refresh, Icons.add]) {
        final button = tester.getRect(find.widgetWithIcon(IconButton, icon));
        expect(
          hintRect.overlaps(button),
          isFalse,
          reason: 'hint $hintRect covers the $icon zoom button $button',
        );
      }
    });
  }
}
