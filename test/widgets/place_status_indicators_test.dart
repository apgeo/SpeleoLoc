import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/place_status_indicators.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => LocServ.inst.load());

  Future<void> show(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );

  String t(String key, [Map<String, String>? params]) =>
      LocServ.inst.t(key, params);

  group('map status chip', () {
    testWidgets('a place on no map has its own glyph, count and sentence', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await show(
        tester,
        PlaceMapStatusChip(count: 0, totalMaps: 3, onTap: () {}),
      );

      expect(find.byIcon(Icons.location_off), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      final node = tester.getSemantics(
        find.bySemanticsLabel(t('place_status_maps_none')),
      );
      expect(node.label, t('place_status_maps_none'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });

    testWidgets('partly placed and fully placed differ by glyph and wording', (
      tester,
    ) async {
      await show(
        tester,
        PlaceMapStatusChip(count: 1, totalMaps: 3, onTap: () {}),
      );
      expect(find.byIcon(Icons.place), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          t('place_status_maps_some', {'count': '1', 'total': '3'}),
        ),
        findsOneWidget,
      );

      await show(
        tester,
        PlaceMapStatusChip(count: 3, totalMaps: 3, onTap: () {}),
      );
      expect(find.byIcon(Icons.where_to_vote), findsOneWidget);
      expect(
        find.bySemanticsLabel(t('place_status_maps_all', {'total': '3'})),
        findsOneWidget,
      );
    });

    testWidgets('is a full-size touch target and reports taps', (tester) async {
      var taps = 0;
      await show(
        tester,
        PlaceMapStatusChip(count: 2, totalMaps: 3, onTap: () => taps++),
      );

      final size = tester.getSize(find.byType(PlaceMapStatusChip));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      await tester.tap(find.byType(PlaceMapStatusChip));
      expect(taps, 1);
    });
  });

  group('QR status icon', () {
    testWidgets('names the state in words, not only by colour', (tester) async {
      await show(tester, const PlaceQrStatusIcon(hasCode: true));
      expect(find.byTooltip(t('place_status_qr_yes')), findsOneWidget);
      expect(find.byIcon(Icons.qr_code), findsOneWidget);

      await show(tester, const PlaceQrStatusIcon(hasCode: false));
      expect(find.byTooltip(t('place_status_qr_no')), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_outlined), findsOneWidget);
    });
  });
}
