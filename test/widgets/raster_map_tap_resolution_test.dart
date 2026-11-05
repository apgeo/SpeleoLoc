import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photo_view/photo_view.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/widgets/raster_map_place_point_editor.dart';

/// Where a tap on the map goes: in define mode it is a position on the
/// picture and nothing else, and only a tap on the picture, once its size
/// and zoom are known, defines a point; in select mode and in the read-only
/// viewer it picks the nearest point within reach.
void main() {
  late Directory tmp;
  late File imageFile;
  late Uint8List png;

  // Twice as wide as high, so contained across an upright viewport the
  // picture leaves blank space below it.
  const pictureW = 200.0;
  const pictureH = 100.0;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('speleoloc_tap_resolution_');
    final picture = img.Image(
      width: pictureW.toInt(),
      height: pictureH.toInt(),
    );
    img.fill(picture, color: img.ColorRgb8(240, 240, 240));
    png = img.encodePng(picture);
    imageFile = File('${tmp.path}/invented_map.png')..writeAsBytesSync(png);
  });
  tearDown(() => tmp.delete(recursive: true));

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

  Future<void> pumpEditor(
    WidgetTester tester, {
    required RasterMapPlacePointEditorController controller,
    required List<CavePlaceWithDefinition> places,
    ImageProvider? picture,
    bool isReadonly = false,
    void Function(double x, double y)? onPoint,
    Future<bool> Function(Uuid, Uuid, double, double)? onAutoSave,
    void Function(CavePlaceWithDefinition)? onPlaceSelected,
    void Function(CavePlaceWithDefinition)? onMarkerTap,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RasterMapPlacePointEditor(
              controller: controller,
              imageFile: imageFile,
              imageProvider: picture ?? MemoryImage(png),
              cavePlacesWithDefinitions: places,
              selectedRasterMapUuid: mapUuid,
              caveUuid: caveUuid,
              isReadonly: isReadonly,
              onImagePointChanged: onPoint,
              onAutoSaveRequested: onAutoSave,
              onCavePlaceSelected: onPlaceSelected,
              onMarkerTap: onMarkerTap,
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

  /// The contained scale: the picture fits the map's width.
  double scaleOf(WidgetTester tester) {
    final map = tester.getRect(find.byType(PhotoView));
    return math.min(map.width / pictureW, map.height / pictureH);
  }

  Offset onScreen(WidgetTester tester, double x, double y) =>
      tester.getRect(find.byType(PhotoView)).topLeft +
      Offset(x, y) * scaleOf(tester);

  Future<void> tapAt(WidgetTester tester, Offset at) async {
    await tester.tapAt(at);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('define mode', () {
    testWidgets('a tap beside another place\'s point defines the point there '
        'and neither saves nor switches place', (tester) async {
      final here = placeAt('Invented hall', 50, 50);
      final neighbour = placeAt('Invented sump', 100, 50);
      final points = <Offset>[];
      var saves = 0;
      final selected = <CavePlaceWithDefinition>[];
      await pumpEditor(
        tester,
        controller: RasterMapPlacePointEditorController(
          cavePlaceUuid: here.cavePlace.uuid,
          initialTapDefinesNewPoint: true,
        ),
        places: [here, neighbour],
        onPoint: (x, y) => points.add(Offset(x, y)),
        onAutoSave: (_, _, _, _) async {
          saves++;
          return true;
        },
        onPlaceSelected: selected.add,
      );

      await tapAt(tester, onScreen(tester, 150, 80));
      // Close beside the neighbour's dot, inside the area it can be held by.
      const beside = Offset(6, 6);
      await tapAt(tester, onScreen(tester, 100, 50) + beside);

      final scale = scaleOf(tester);
      expect(points, hasLength(2));
      expect(points.last.dx, closeTo(100 + beside.dx / scale, 0.01));
      expect(points.last.dy, closeTo(50 + beside.dy / scale, 0.01));
      expect(saves, 0);
      expect(selected, isEmpty);
    });

    testWidgets('a tap before the picture\'s size is known defines no point, '
        'and the zoom buttons wait for it', (tester) async {
      final points = <Offset>[];
      await pumpEditor(
        tester,
        controller: RasterMapPlacePointEditorController(
          initialTapDefinesNewPoint: true,
        ),
        places: const [],
        picture: _NeverLoads(),
        onPoint: (x, y) => points.add(Offset(x, y)),
      );
      expect(find.byType(PhotoView), findsNothing);

      await tapAt(
        tester,
        tester.getCenter(find.byType(RasterMapPlacePointEditor)),
      );
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(points, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a tap beside the picture defines no point', (tester) async {
      final points = <Offset>[];
      await pumpEditor(
        tester,
        controller: RasterMapPlacePointEditorController(
          initialTapDefinesNewPoint: true,
        ),
        places: const [],
        onPoint: (x, y) => points.add(Offset(x, y)),
      );

      await tapAt(tester, onScreen(tester, 120, 60));
      expect(points, hasLength(1));
      expect(points.single.dx, closeTo(120, 0.01));
      expect(points.single.dy, closeTo(60, 0.01));

      final map = tester.getRect(find.byType(PhotoView));
      final pictureBottom = onScreen(tester, 0, pictureH).dy;
      expect(map.bottom - pictureBottom, greaterThan(100));
      await tapAt(
        tester,
        Offset(map.center.dx, (pictureBottom + map.bottom) / 2),
      );

      expect(points, hasLength(1));
    });
  });

  group('select mode', () {
    testWidgets('a tap between two close points picks the nearer one', (
      tester,
    ) async {
      final near = placeAt('Invented hall', 100, 80);
      // Listed last, so drawn on top of the nearer one.
      final far = placeAt('Invented sump', 102, 80);
      final selected = <CavePlaceWithDefinition>[];
      await pumpEditor(
        tester,
        controller: RasterMapPlacePointEditorController(
          initialTapDefinesNewPoint: false,
        ),
        places: [near, far],
        onPlaceSelected: selected.add,
      );

      final nearAt = onScreen(tester, 100, 80);
      final farAt = onScreen(tester, 102, 80);
      await tapAt(tester, nearAt + (farAt - nearAt) * 0.4);

      expect(selected.map((p) => p.cavePlace.title), ['Invented hall']);
    });

    testWidgets('a tap beside a point picks it and defines nothing', (
      tester,
    ) async {
      final hall = placeAt('Invented hall', 50, 50);
      final points = <Offset>[];
      final selected = <CavePlaceWithDefinition>[];
      await pumpEditor(
        tester,
        controller: RasterMapPlacePointEditorController(
          initialTapDefinesNewPoint: false,
        ),
        places: [hall],
        onPoint: (x, y) => points.add(Offset(x, y)),
        onPlaceSelected: selected.add,
      );

      await tapAt(tester, onScreen(tester, 50, 50) + const Offset(-6, 4));

      expect(selected.map((p) => p.cavePlace.title), ['Invented hall']);
      expect(points, isEmpty);
    });
  });

  testWidgets('in the read-only viewer a tap beside a point picks it', (
    tester,
  ) async {
    final hall = placeAt('Invented hall', 50, 50);
    final tapped = <CavePlaceWithDefinition>[];
    await pumpEditor(
      tester,
      controller: RasterMapPlacePointEditorController(),
      places: [hall],
      isReadonly: true,
      onMarkerTap: tapped.add,
    );

    await tapAt(tester, onScreen(tester, 50, 50) + const Offset(5, -5));

    expect(tapped.map((p) => p.cavePlace.title), ['Invented hall']);
  });
}

/// A picture whose bytes never arrive, as a large scan still being read.
class _NeverLoads extends ImageProvider<_NeverLoads> {
  @override
  Future<_NeverLoads> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _NeverLoads key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
}
