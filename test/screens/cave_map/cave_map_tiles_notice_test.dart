import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/screens/cave_map/cave_map_tiles_notice.dart';
import 'package:speleoloc/utils/localization.dart';

void main() {
  testWidgets('says the tiles are unavailable and offers both ways out', (
    tester,
  ) async {
    var openedSettings = 0;
    var dismissed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CaveMapTilesNotice(
            onOpenMapSettings: () => openedSettings++,
            onDismiss: () => dismissed++,
          ),
        ),
      ),
    );

    expect(find.text(LocServ.inst.t('map_tiles_unavailable')), findsOneWidget);

    await tester.tap(find.text(LocServ.inst.t('map_tiles_open_settings')));
    await tester.tap(find.byTooltip(LocServ.inst.t('close')));

    expect(openedSettings, 1);
    expect(dismissed, 1);
  });
}
