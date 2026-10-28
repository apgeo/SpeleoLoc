import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_map_picture_copies.dart';
import 'package:speleoloc/services/silexgis/silexgis_picture_frame.dart';
import 'package:speleoloc/widgets/raster_map/raster_map_picture_size.dart';
import 'package:speleoloc/widgets/raster_map/raster_map_pins_gate.dart';

import '../support/layout_harness.dart';

/// On a server's reduced picture a map's pins are carried into its pixels
/// when the rule can place them, and left off when it cannot, with a note
/// either way; such a map takes no new pins. Every other map is shown as it
/// always was. The places are listed throughout.
void main() {
  useLayoutHarness();

  final caveId = Uuid.v7();
  final mapId = Uuid.v7();
  final place = CavePlace(
    uuid: Uuid.v7(),
    title: 'Sump',
    caveUuid: caveId,
    isEntrance: 0,
    isMainEntrance: 0,
  );
  final places = <CavePlaceWithDefinition>[
    CavePlaceWithDefinition(
      place,
      CavePlaceToRasterMapDefinition(
        uuid: Uuid.v7(),
        cavePlaceUuid: place.uuid,
        rasterMapUuid: mapId,
        xCoordinate: 120,
        yCoordinate: 80,
      ),
    ),
  ];
  // An invented picture as this device holds it: 200 × 150 pixels.
  final held = MemoryImage(img.encodePng(img.Image(width: 200, height: 150)));

  Future<(List<CavePlaceWithDefinition>, bool)> pump(
    WidgetTester tester, {
    required SilexgisMapPicture? picture,
  }) async {
    // Decoding runs outside the fake clock; once cached, the gate sizes the
    // picture at once.
    await tester.runAsync(() => rasterMapPictureSize(held));
    late List<CavePlaceWithDefinition> shown;
    late bool editable;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rasterMapPictureProvider(mapId).overrideWith((ref) async => picture),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RasterMapPinsGate(
              rasterMapUuid: mapId,
              picture: held,
              places: places,
              builder: (context, given, pinsEditable) {
                shown = given;
                editable = pinsEditable;
                return const Placeholder();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (shown, editable);
  }

  SilexgisMapPicture rendition(SilexgisPictureFrame frame) =>
      SilexgisMapPicture(SilexgisHeldAs.rendition, frame);

  final readOnlyNote = find.textContaining('shown on it');
  final hiddenNote = find.textContaining('cannot be shown');

  testWidgets('a reduced picture with the stored axes shows the pins scaled', (
    tester,
  ) async {
    final (shown, editable) = await pump(
      tester,
      picture: rendition(const SilexgisPictureFrame(width: 400, height: 300)),
    );

    expect(editable, isFalse);
    expect(shown.single.definition?.xCoordinate, 60);
    expect(shown.single.definition?.yCoordinate, 40);
    expect(readOnlyNote, findsOneWidget);
    expect(hiddenNote, findsNothing);
  });

  testWidgets('a reduced picture turned as the server states carries the '
      'pins through the turn', (tester) async {
    final (shown, editable) = await pump(
      tester,
      picture: rendition(
        const SilexgisPictureFrame(
          width: 300,
          height: 400,
          mirrored: false,
          turn: 90,
        ),
      ),
    );

    expect(editable, isFalse);
    // (H − 1 − y, x) = (319, 120), at half size.
    expect(shown.single.definition?.xCoordinate, 160);
    expect(shown.single.definition?.yCoordinate, 60);
    expect(readOnlyNote, findsOneWidget);
  });

  testWidgets('a reduced picture with its axes swapped and no turn stated '
      'shows no pins', (tester) async {
    final (shown, editable) = await pump(
      tester,
      picture: rendition(const SilexgisPictureFrame(width: 300, height: 400)),
    );

    expect(editable, isFalse);
    expect(shown.single.cavePlace.uuid, place.uuid);
    expect(shown.single.definition, isNull);
    expect(hiddenNote, findsOneWidget);
    expect(readOnlyNote, findsNothing);
  });

  testWidgets('a reduced picture of unknown stored size shows no pins', (
    tester,
  ) async {
    final (shown, _) = await pump(
      tester,
      picture: rendition(const SilexgisPictureFrame()),
    );

    expect(shown.single.definition, isNull);
    expect(hiddenNote, findsOneWidget);
  });

  testWidgets('otherwise the map is shown as it always was', (tester) async {
    final (shown, editable) = await pump(tester, picture: null);

    expect(editable, isTrue);
    expect(shown.single.definition?.xCoordinate, 120);
    expect(shown.single.definition?.yCoordinate, 80);
    expect(find.textContaining('reduced picture'), findsNothing);
  });
}
