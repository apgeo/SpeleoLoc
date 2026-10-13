import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_trip/trip_media_assignment.dart';
import 'package:speleoloc/screens/cave_trip/trip_media_entrance_dialog.dart';
import 'package:speleoloc/screens/cave_trip/trip_media_tile.dart';
import 'package:speleoloc/services/trip_media/trip_media_entrance_plan.dart';
import 'package:speleoloc/services/trip_media/trip_media_item.dart';

import '../support/device_profiles.dart';
import '../support/layout_harness.dart';

/// The trip-media rows and dialogs carry a lot in a little space — a
/// thumbnail, a long place title, a timestamp, a QR badge and four buttons —
/// so they are exactly where a narrow phone or a large system font breaks
/// the layout. These render them at every profile and fail on overflow.
void main() {
  useLayoutHarness();

  final placeUuid = Uuid.v7();

  CavePlace place(String title) => CavePlace(
    uuid: placeUuid,
    title: title,
    caveUuid: Uuid.v7(),
    isEntrance: 1,
    isMainEntrance: 0,
  );

  TripMediaItem item({
    TripMediaKind kind = TripMediaKind.photo,
    MediaTimeSource source = MediaTimeSource.library,
  }) => TripMediaItem(
    id: 'asset-1',
    kind: kind,
    capturedAt: DateTime(2026, 10, 13, 11, 42, 7),
    capturedAtSource: source,
    displayName: 'IMG_20261013_114207.jpg',
  );

  Widget tile({
    TripMediaAssignment? assignment,
    TripMediaKind kind = TripMediaKind.photo,
    MediaTimeSource source = MediaTimeSource.library,
  }) {
    return Scaffold(
      body: ListView(
        children: [
          TripMediaTile(
            item: item(kind: kind, source: source),
            assignment: assignment,
            thumbnail: null,
            localFile: null,
            onPickPlace: () {},
            onEditTime: () {},
            onToggleSelected: (_) {},
            onClear: () {},
          ),
        ],
      ),
    );
  }

  testLaysOutEverywhere('an undecided row', () => tile());

  testLaysOutEverywhere(
    'a row with a long place title and a QR badge',
    () => tile(
      assignment: TripMediaAssignment(
        // Long enough to need eliding rather than to push the row wider.
        place: place('Galeria Mare cu Stalactite din Sectorul Nord-Vestic'),
        at: DateTime(2026, 10, 13, 11, 42),
        fromQrCode: true,
      ),
    ),
  );

  testLaysOutEverywhere(
    'a video row whose time came from the file stamp',
    () => tile(kind: TripMediaKind.video, source: MediaTimeSource.fileModified),
  );

  testLaysOutEverywhere(
    'the entrance dialog with every section showing',
    () => Builder(
      builder: (context) => TripMediaEntranceDialog(
        plan: TripMediaEntrancePlan(
          supersededPoints: [
            CaveTripPoint(
              uuid: Uuid.v7(),
              caveTripUuid: Uuid.v7(),
              cavePlaceUuid: placeUuid,
              scannedAt: DateTime(2026, 10, 13, 9, 5).millisecondsSinceEpoch,
            ),
            CaveTripPoint(
              uuid: Uuid.v7(),
              caveTripUuid: Uuid.v7(),
              cavePlaceUuid: placeUuid,
              scannedAt: DateTime(2026, 10, 13, 17, 5).millisecondsSinceEpoch,
            ),
          ],
          proposedTripStart: DateTime(2026, 10, 13, 8, 40),
          proposedTripEnd: DateTime(2026, 10, 13, 17, 25),
        ),
        tripStart: DateTime(2026, 10, 13, 9, 0),
        tripEnd: DateTime(2026, 10, 13, 17, 0),
        placeTitles: {placeUuid: 'Intrarea Principala'},
      ),
    ),
  );

  testWidgets('the tile elides a long title instead of widening the row', (
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
      () => tile(
        assignment: TripMediaAssignment(
          place: place('Galeria Mare cu Stalactite din Sectorul Nord-Vestic'),
          at: DateTime(2026, 10, 13, 11, 42),
        ),
      ),
    );
    final row = tester.getSize(find.byType(TripMediaTile));
    expect(
      row.width,
      lessThanOrEqualTo(narrow.size.width),
      reason: 'the row must stay inside the viewport, not scroll sideways',
    );
  });
}
