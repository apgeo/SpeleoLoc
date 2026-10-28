import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_trip/cave_trip_history_list.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_origin_service.dart';

import '../support/layout_harness.dart';

/// Another phone's recordings, read from an installation, are kept on the
/// device but out of the trips list: counted, hidden until the caver turns
/// them on, and marked once shown.
void main() {
  useLayoutHarness();

  final caveId = Uuid.v7();
  CaveTrip trip(String title) => CaveTrip(
    uuid: Uuid.v7(),
    caveUuid: caveId,
    title: title,
    tripStartedAt: DateTime(2026, 10, 27, 8).millisecondsSinceEpoch,
    tripEndedAt: DateTime(2026, 10, 27, 12).millisecondsSinceEpoch,
  );

  final mine = trip('My own trip');
  final theirsA = trip('Club trip A');
  final theirsB = trip('Club trip B');
  final received = SilexgisReceivedTrips(
    installation: 'Club server',
    recordings: <Uuid>{theirsA.uuid, theirsB.uuid},
  );

  Future<List<CaveTrip>> pump(
    WidgetTester tester, {
    SilexgisReceivedTrips? from,
  }) async {
    final opened = <CaveTrip>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CaveTripHistoryList(
            trips: <CaveTrip>[mine, theirsA, theirsB],
            pointCounts: <Uuid, int>{mine.uuid: 3},
            received: from,
            onOpen: opened.add,
          ),
        ),
      ),
    );
    return opened;
  }

  testWidgets('hides the installation\'s recordings and says how many', (
    tester,
  ) async {
    await pump(tester, from: received);

    expect(find.text('My own trip'), findsOneWidget);
    expect(find.text('Club trip A'), findsNothing);
    expect(find.text('Club trip B'), findsNothing);
    expect(find.text('2 from Club server hidden'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.byIcon(Icons.cloud_download_outlined), findsOneWidget);
  });

  testWidgets('the switch shows them, each with a badge', (tester) async {
    final opened = await pump(tester, from: received);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Club trip A'), findsOneWidget);
    expect(find.text('Club trip B'), findsOneWidget);
    expect(find.text('2 from Club server hidden'), findsNothing);
    // One on the switch, one badge on each recording from the installation.
    expect(find.byIcon(Icons.cloud_download_outlined), findsNWidgets(3));
    expect(
      find.byTooltip('Recorded on another phone, read from Club server'),
      findsNWidgets(2),
    );

    await tester.tap(find.text('Club trip A'));
    expect(opened, <CaveTrip>[theirsA]);
  });

  testWidgets('says who recorded one the installation names a caver for', (
    tester,
  ) async {
    await pump(
      tester,
      from: SilexgisReceivedTrips(
        installation: 'Club server',
        recordings: <Uuid>{theirsA.uuid, theirsB.uuid},
        recordedBy: <Uuid, String>{theirsA.uuid: 'Invented Caver'},
      ),
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.textContaining('recorded by Invented Caver'), findsOneWidget);
  });

  group('another phone\'s open recording', () {
    final open = CaveTrip(
      uuid: Uuid.v7(),
      caveUuid: caveId,
      title: 'Club trip underway',
      tripStartedAt: DateTime(2026, 10, 28, 8).millisecondsSinceEpoch,
    );
    final mineOpen = CaveTrip(
      uuid: Uuid.v7(),
      caveUuid: caveId,
      title: 'My trip underway',
      tripStartedAt: DateTime(2026, 10, 28, 9).millisecondsSinceEpoch,
    );
    final withOpen = SilexgisReceivedTrips(
      installation: 'Club server',
      recordings: <Uuid>{theirsA.uuid, open.uuid},
    );

    test('is listed with the ended trips; this device\'s own is not', () {
      expect(
        CaveTripHistoryList.listed(<CaveTrip>[
          mine,
          open,
          mineOpen,
          theirsA,
        ], withOpen),
        <CaveTrip>[mine, open, theirsA],
      );
      expect(
        CaveTripHistoryList.listed(<CaveTrip>[mine, open, mineOpen], null),
        <CaveTrip>[mine],
      );
    });

    testWidgets('behind the same switch, marked as open and as the '
        'installation\'s', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CaveTripHistoryList(
              trips: CaveTripHistoryList.listed(<CaveTrip>[
                mine,
                open,
                theirsA,
              ], withOpen),
              pointCounts: const <Uuid, int>{},
              received: withOpen,
              onOpen: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Club trip underway'), findsNothing);
      expect(find.text('2 from Club server hidden'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Club trip underway'), findsOneWidget);
      expect(find.textContaining('still open'), findsOneWidget);
      expect(
        find.byTooltip('Recorded on another phone, read from Club server'),
        findsNWidgets(2),
      );
    });
  });

  testWidgets('without an installation every trip is listed as before', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('My own trip'), findsOneWidget);
    expect(find.text('Club trip A'), findsOneWidget);
    expect(find.text('Club trip B'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    expect(find.byIcon(Icons.cloud_download_outlined), findsNothing);
  });
}
