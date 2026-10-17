import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/settings/settings_trip_log_page.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/localization.dart';

import '../support/device_profiles.dart';
import '../support/layout_harness.dart';

/// The page the trip screens' log warnings link to. It has to store the
/// choice where the trip service reads it — a switch that only moves on
/// screen would leave every warning pointing at a setting that does nothing.
void main() {
  useLayoutHarness();

  late AppDatabase db;
  late ProviderContainer container;

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

  Widget page() => UncontrolledProviderScope(
    container: container,
    child: const SettingsTripLogPage(),
  );

  testLaysOutEverywhere('the trip log settings page', page);

  testWidgets('starts off, and turning it on is what the service reads', (
    tester,
  ) async {
    await LayoutHarness.renderAndCatch(tester, deviceProfiles.first, page);

    final toggle = find.byType(Switch);
    expect(tester.widget<Switch>(toggle).value, isFalse);
    expect(
      find.text(LocServ.inst.t('trip_log_regenerate_on_edit_off')),
      findsOneWidget,
    );

    await tester.tap(toggle);
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      await container.read(caveTripServiceProvider).regeneratesLogOnEdit(),
      isTrue,
    );
    expect(
      find.text(LocServ.inst.t('trip_log_regenerate_on_edit_on')),
      findsOneWidget,
    );
  });
}
