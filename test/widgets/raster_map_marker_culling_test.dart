import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_view/photo_view.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/widgets/raster_map_marker_builder.dart';

/// On a zoomed-in map only the places whose dot or label can show in the
/// viewport get marker widgets; the rest are left out of the frame.
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

  Set<String> labelsShown(Rect? visibleArea) {
    final markers = RasterMapMarkerBuilder.buildDefinitionMarkers(
      definitions: [
        placeAt('Invented inside', 100, 100),
        // Its dot is left of the viewport, its label runs into it.
        placeAt('Invented label reaches in', -20, 100),
        placeAt('Invented far right', 2000, 100),
        placeAt('Invented far below', 100, 2000),
        placeAt('Invented far left', -2000, 100),
      ],
      controllerValue: const PhotoViewControllerValue(
        position: Offset.zero,
        scale: 1,
        rotation: 0,
        rotationFocusPoint: null,
      ),
      visibleArea: visibleArea,
      specialPointKeys: const {},
      useImageTextColor: false,
      img: null,
      defaultLabelColor: Colors.white,
      outlineEnabled: false,
      outlineWidth: 2,
      bgEnabled: false,
      onLongPress: (_) {},
    );
    final shown = <String>{};
    for (final marker in markers) {
      void visit(Widget w) {
        if (w is Text && w.data != null) shown.add(w.data!);
        if (w is Positioned) visit(w.child);
        if (w is Stack) w.children.forEach(visit);
        if (w is Container && w.child != null) visit(w.child!);
        if (w is Padding && w.child != null) visit(w.child!);
      }

      visit(marker);
    }
    return shown;
  }

  test('places that cannot reach the viewport get no markers', () {
    expect(labelsShown(const Rect.fromLTWH(0, 0, 400, 400)), {
      'Invented inside',
      'Invented label reaches in',
    });
  });

  test('without a viewport every place gets its marker', () {
    expect(labelsShown(null), hasLength(5));
  });
}
