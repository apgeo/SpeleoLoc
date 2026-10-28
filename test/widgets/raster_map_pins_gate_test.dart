import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/widgets/raster_map/raster_map_pins_gate.dart';

import '../support/layout_harness.dart';

/// A map whose pins do not fit its picture is shown without them, with a note
/// saying why, and takes no new ones; the places are still listed.
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

  Future<(List<CavePlaceWithDefinition>, bool)> pump(
    WidgetTester tester, {
    required bool fit,
  }) async {
    late List<CavePlaceWithDefinition> shown;
    late bool pinsFit;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rasterMapPinsFitProvider(mapId).overrideWith((ref) async => fit),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RasterMapPinsGate(
              rasterMapUuid: mapId,
              places: places,
              builder: (context, given, fits) {
                shown = given;
                pinsFit = fits;
                return const Placeholder();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (shown, pinsFit);
  }

  testWidgets('on a reduced picture the pins are left off, with a note', (
    tester,
  ) async {
    final (shown, pinsFit) = await pump(tester, fit: false);

    expect(pinsFit, isFalse);
    expect(shown.single.cavePlace.uuid, place.uuid);
    expect(shown.single.definition, isNull);
    expect(find.textContaining('reduced picture'), findsOneWidget);
  });

  testWidgets('otherwise the map is shown as it always was', (tester) async {
    final (shown, pinsFit) = await pump(tester, fit: true);

    expect(pinsFit, isTrue);
    expect(shown.single.definition?.xCoordinate, 120);
    expect(find.textContaining('reduced picture'), findsNothing);
  });
}
