import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_view/photo_view.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/widgets/raster_map_marker_builder.dart';

/// Every marker is drawn centred on its point's viewport position, so a
/// stored point shows where it was tapped and a tap on a drawn dot lands on
/// the point it shows.
void main() {
  final mapUuid = Uuid.v7();
  CavePlaceWithDefinition placeAt(String title, int x, int y) {
    final place = CavePlace(
      uuid: Uuid.v7(),
      caveUuid: Uuid.v7(),
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

  // Panned and zoomed, so an offset in either would show.
  const view = PhotoViewControllerValue(
    position: Offset(30, 40),
    scale: 2,
    rotation: 0,
    rotationFocusPoint: null,
  );
  final pointInViewport = RasterMapMarkerBuilder.imageToViewport(50, 60, view);

  Future<void> pumpMarkers(WidgetTester tester, List<Widget> markers) =>
      tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              height: 400,
              child: Stack(children: markers),
            ),
          ),
        ),
      );

  Finder dot(Color color) => find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
        (w.decoration! as BoxDecoration).color == color,
  );

  List<Widget> storedMarkers({
    Set<String> specialPointKeys = const {},
    Set<Uuid>? visiblePlaceUuids,
  }) => RasterMapMarkerBuilder.buildDefinitionMarkers(
    definitions: [placeAt('Invented station', 50, 60)],
    controllerValue: view,
    specialPointKeys: specialPointKeys,
    visiblePlaceUuids: visiblePlaceUuids,
    useImageTextColor: false,
    img: null,
    defaultLabelColor: Colors.white,
    outlineEnabled: false,
    outlineWidth: 2,
    bgEnabled: false,
    onLongPress: (_) {},
  );

  testWidgets('a stored point\'s dot is centred on the point', (tester) async {
    await pumpMarkers(tester, storedMarkers());
    expect(tester.getCenter(dot(Colors.red)), pointInViewport);
    expect(tester.getCenter(find.byType(GestureDetector)), pointInViewport);
  });

  testWidgets('a filtered-out point\'s faded dot is centred on the point', (
    tester,
  ) async {
    await pumpMarkers(tester, storedMarkers(visiblePlaceUuids: const {}));
    expect(tester.getCenter(dot(Colors.red)), pointInViewport);
  });

  testWidgets('the hold area of a point drawn by its own marker is centred on '
      'the point', (tester) async {
    await pumpMarkers(tester, storedMarkers(specialPointKeys: const {'50,60'}));
    expect(tester.getCenter(find.byType(GestureDetector)), pointInViewport);
  });

  testWidgets('the selected place\'s marker is centred on its point', (
    tester,
  ) async {
    await pumpMarkers(
      tester,
      RasterMapMarkerBuilder.buildControllerPlaceMarker(
        imageX: 50,
        imageY: 60,
        controllerValue: view,
        definitions: const [],
        useImageTextColor: false,
        img: null,
        defaultLabelColor: Colors.white,
        outlineEnabled: false,
        outlineWidth: 2,
        bgEnabled: false,
        onLongPress: (_) {},
        cavePlaceTitle: 'Invented station',
      ),
    );
    expect(tester.getCenter(dot(Colors.blue)), pointInViewport);
    expect(tester.getCenter(find.byType(GestureDetector)), pointInViewport);
  });
}
