import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/screens/cave_trip/trip_window_dialog.dart';
import 'package:speleoloc/utils/localization.dart';

import '../support/device_profiles.dart';
import '../support/layout_harness.dart';

void main() {
  useLayoutHarness();

  final start = DateTime(2025, 7, 4, 8, 30);
  final end = DateTime(2025, 7, 4, 16, 0);

  Widget dialog({DateTime? end, List<DateTime> points = const []}) => Scaffold(
    body: TripWindowDialog(start: start, end: end, pointTimes: points),
  );

  testLaysOutEverywhere('an ended trip\'s times', () => dialog(end: end));
  testLaysOutEverywhere(
    'with points outside the times',
    () => dialog(end: end, points: [DateTime(2025, 7, 4, 7)]),
  );

  testWidgets('a live trip offers only its start', (tester) async {
    await LayoutHarness.renderAndCatch(tester, deviceProfiles[1], dialog);
    expect(find.text(LocServ.inst.t('trip_ended')), findsNothing);
    expect(find.text(LocServ.inst.t('trip_window_live')), findsOneWidget);
  });

  testWidgets('points outside the times are counted', (tester) async {
    await LayoutHarness.renderAndCatch(
      tester,
      deviceProfiles[1],
      () => dialog(
        end: end,
        points: [
          DateTime(2025, 7, 4, 7), // before the start
          DateTime(2025, 7, 4, 12), // inside
          DateTime(2025, 7, 4, 18), // after the end
        ],
      ),
    );
    expect(
      find.text(LocServ.inst.t('trip_window_points_outside', {'n': '2'})),
      findsOneWidget,
    );
  });

  testWidgets('an end before the start cannot be saved', (tester) async {
    await LayoutHarness.renderAndCatch(
      tester,
      deviceProfiles[1],
      () => Scaffold(
        body: TripWindowDialog(start: end, end: start, pointTimes: const []),
      ),
    );
    expect(find.text(LocServ.inst.t('trip_window_inverted')), findsOneWidget);
    final ok = tester.widget<TextButton>(
      find.widgetWithText(TextButton, LocServ.inst.t('ok')),
    );
    expect(ok.onPressed, isNull);
  });
}
