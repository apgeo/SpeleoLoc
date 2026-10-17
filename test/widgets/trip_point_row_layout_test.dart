import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_trip/trip_point_pictures_sheet.dart';
import 'package:speleoloc/screens/cave_trip/trip_point_row.dart';

import '../support/device_profiles.dart';
import '../support/layout_harness.dart';

/// A point's row now carries a picture count beside the depth and the
/// menu, all next to the place's name — the shape that runs out of width
/// first on a narrow phone or at a large font. These lay it out, and the
/// sheet the count opens, at every profile.
void main() {
  useLayoutHarness();

  final caveUuid = Uuid.v7();
  final placeUuid = Uuid.v7();

  CaveTripPoint point() => CaveTripPoint(
    uuid: Uuid.v7(),
    caveTripUuid: Uuid.v7(),
    cavePlaceUuid: placeUuid,
    scannedAt: DateTime(2026, 10, 13, 11, 42).millisecondsSinceEpoch,
  );

  CavePlace place(String title, {double? depth}) => CavePlace(
    uuid: placeUuid,
    title: title,
    caveUuid: caveUuid,
    depthInCave: depth,
    isEntrance: 0,
    isMainEntrance: 0,
  );

  Widget row({required String title, double? depth, int pictures = 0}) =>
      Scaffold(
        body: ListView(
          children: [
            TripPointRow(
              ordinal: 12,
              point: point(),
              place: place(title, depth: depth),
              timeLabel: '2026/10/13 11:42',
              pictureCount: pictures,
              onOpenPlace: () {},
              onShowPictures: () {},
              onEditTime: () {},
              onDelete: () {},
            ),
          ],
        ),
      );

  testLaysOutEverywhere('a plain point row', () => row(title: 'Sala Mare'));

  testLaysOutEverywhere(
    'a row with pictures, a depth and a long place name',
    () => row(
      title: 'Galeria Mare cu Stalactite din Sectorul Nord-Vestic',
      depth: -124.5,
      pictures: 12,
    ),
  );

  testLaysOutEverywhere(
    'the sheet of a point\'s pictures',
    () => const Scaffold(
      body: TripPointPicturesSheet(
        title: 'Galeria Mare cu Stalactite din Sectorul Nord-Vestic',
        subtitle: '2026/10/13 11:42',
        docs: [],
      ),
    ),
  );

  testWidgets('the picture count and the menu are full-size tap targets', (
    tester,
  ) async {
    const narrow = DeviceProfile(
      name: 'phone_small',
      size: Size(360, 640),
      devicePixelRatio: 2.0,
    );
    await LayoutHarness.renderAndCatch(
      tester,
      narrow,
      () => row(title: 'Sala Mare', depth: -12, pictures: 3),
    );
    for (final icon in [Icons.photo_library_outlined, Icons.more_vert]) {
      final target = tester.getSize(
        find.ancestor(of: find.byIcon(icon), matching: find.byType(IconButton)),
      );
      expect(target.width, greaterThanOrEqualTo(48), reason: '$icon width');
      expect(target.height, greaterThanOrEqualTo(48), reason: '$icon height');
    }
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });
}
