import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/cave_places_list_page.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/place_status_indicators.dart';
import 'package:speleoloc/widgets/product_tour.dart';

import '../support/device_profiles.dart';
import '../support/layout_harness.dart';

/// The places list is driven by a strip of icon-only buttons and a status
/// pair on every row. None of them may rest on an icon or a colour alone.
void main() {
  useLayoutHarness();

  late AppDatabase db;
  late ProviderContainer container;
  late Uuid caveUuid;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    initRootContainer(container);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> open(WidgetTester tester) async {
    await tester.runAsync(() async {
      await setAutoToursDisabled(true);
      caveUuid = await container.read(caveRepositoryProvider).addCave('Cave');
      await container
          .read(cavePlaceRepositoryProvider)
          .addCavePlace(caveUuid, 'Place');
    });
    final error = await LayoutHarness.renderAndCatch(
      tester,
      deviceProfiles[1],
      () => UncontrolledProviderScope(
        container: container,
        child: CavePlacesListPage(caveUuid: caveUuid),
      ),
    );
    expect(error, isNull);
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  // Lets drift's stream-close timers run before the pending-timer check.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('every toolbar button has a tooltip, which is also its label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester);

    final toolbar = find.descendant(
      of: find.byType(SingleChildScrollView).first,
      matching: find.byType(IconButton),
    );
    expect(toolbar, findsWidgets);
    for (final button in tester.widgetList<IconButton>(toolbar)) {
      expect(button.tooltip, isNotEmpty);
      expect(find.byTooltip(button.tooltip!), findsWidgets);
    }
    await unmount(tester);
    handle.dispose();
  });

  testWidgets('a row says in words whether it has a QR code and a map', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester);

    expect(find.byType(PlaceQrStatusIcon), findsOneWidget);
    expect(
      find.byTooltip(LocServ.inst.t('place_status_qr_no')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(LocServ.inst.t('place_status_maps_none')),
      findsOneWidget,
    );
    await unmount(tester);
    handle.dispose();
  });
}
