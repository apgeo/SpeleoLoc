import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speleoloc/widgets/raster_map/raster_map_thumbnail.dart';

/// A map's list tile decodes the picture at the tile's pixel width on the
/// screen it is shown on, never at the picture's own size, and shows a broken
/// picture instead of failing when the file is gone.
void main() {
  late Directory tmp;
  late File picture;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('speleoloc_thumbnail_');
    picture = File('${tmp.path}/invented_scan.png')
      ..writeAsBytesSync(img.encodePng(img.Image(width: 1200, height: 900)));
  });
  tearDown(() => tmp.delete(recursive: true));

  Future<void> pumpTile(WidgetTester tester, File file, double dpr) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(devicePixelRatio: dpr),
          child: MaterialApp(
            home: Center(child: RasterMapThumbnail(file: file)),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
  }

  for (final dpr in const [1.0, 2.75, 3.0]) {
    testWidgets('a 50 dp tile decodes at ${(50 * dpr).ceil()} px wide on a '
        '$dpr× screen', (tester) async {
      await pumpTile(tester, picture, dpr);

      final shown = tester.widget<Image>(find.byType(Image)).image;
      expect(shown, isA<ResizeImage>());
      expect((shown as ResizeImage).width, (50 * dpr).ceil());
      expect(shown.height, isNull, reason: 'the aspect ratio is kept');
      expect(shown.imageProvider, FileImage(picture));
    });
  }

  testWidgets('a missing picture shows as broken', (tester) async {
    await pumpTile(tester, File('${tmp.path}/gone.png'), 2.0);

    expect(find.byIcon(Icons.broken_image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
