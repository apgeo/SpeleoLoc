import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_trip/trip_media_assignment.dart';
import 'package:speleoloc/screens/cave_trip/trip_media_entrance_dialog.dart';
import 'package:speleoloc/screens/cave_trip/trip_media_tile.dart';
import 'package:speleoloc/services/trip_media/trip_media_entrance_plan.dart';
import 'package:speleoloc/services/trip_media/trip_media_item.dart';

import '../support/layout_harness.dart';

/// Reference images for the trip-media surfaces, at the narrowest phone and
/// at a 1.5x system font — the two cases that break first.
///
/// These complement the overflow checks rather than repeating them: an
/// overflow test says the pixels fit, a golden says they are still arranged
/// the way someone decided they should be. Regenerate deliberately with
/// `flutter test --update-goldens test/widgets/trip_media_golden_test.dart`
/// and look at the diff before committing it.
void main() {
  useLayoutHarness();

  final placeUuid = Uuid.v7();
  final caveUuid = Uuid.v7();

  CavePlace place(String title) => CavePlace(
    uuid: placeUuid,
    title: title,
    caveUuid: caveUuid,
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

  Widget rows() => Scaffold(
    body: ListView(
      children: [
        // Undecided.
        TripMediaTile(
          item: item(),
          assignment: null,
          thumbnail: null,
          localFile: null,
          onPickPlace: () {},
          onEditTime: () {},
          onToggleSelected: (_) {},
          onClear: () {},
        ),
        // Read off a QR label.
        TripMediaTile(
          item: item(),
          assignment: TripMediaAssignment(
            place: place('Sala Mare'),
            at: DateTime(2026, 10, 13, 11, 42),
            fromQrCode: true,
          ),
          thumbnail: null,
          localFile: null,
          onPickPlace: () {},
          onEditTime: () {},
          onToggleSelected: (_) {},
          onClear: () {},
        ),
        // A video whose time came from the file stamp, with a long title.
        TripMediaTile(
          item: item(
            kind: TripMediaKind.video,
            source: MediaTimeSource.fileModified,
          ),
          assignment: TripMediaAssignment(
            place: place('Galeria Mare cu Stalactite din Sectorul Nord-Vestic'),
            at: DateTime(2026, 10, 13, 12, 5),
            selected: false,
          ),
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

  Widget entranceDialog() => TripMediaEntranceDialog(
    plan: TripMediaEntrancePlan(
      supersededPoints: [
        CaveTripPoint(
          uuid: Uuid.v7(),
          caveTripUuid: Uuid.v7(),
          cavePlaceUuid: placeUuid,
          scannedAt: DateTime(2026, 10, 13, 9, 5).millisecondsSinceEpoch,
        ),
      ],
      proposedTripStart: DateTime(2026, 10, 13, 8, 40),
      proposedTripEnd: DateTime(2026, 10, 13, 17, 25),
    ),
    tripStart: DateTime(2026, 10, 13, 9, 0),
    tripEnd: DateTime(2026, 10, 13, 17, 0),
    placeTitles: {placeUuid: 'Intrarea Principala'},
  );

  testGoldenAcrossDevices('the media rows', 'trip_media_rows', rows);
  testGoldenAcrossDevices(
    'the entrance dialog',
    'trip_media_entrance_dialog',
    entranceDialog,
  );
}
