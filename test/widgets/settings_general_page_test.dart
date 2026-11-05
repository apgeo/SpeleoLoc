import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/settings/settings_general_page.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    initRootContainer(container);
    await SettingsHelper.saveStringConfig('tour_auto_disabled', 'true');
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> openPage(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsGeneralPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool toolbarSwitchValue(WidgetTester tester) => tester
      .widget<SwitchListTile>(
        find.widgetWithText(
          SwitchListTile,
          LocServ.inst.t('show_home_toolbar'),
        ),
      )
      .value;

  testWidgets('on a fresh install the home toolbar switch reads on, as the '
      'home screen shows it', (tester) async {
    await openPage(tester);

    expect(showHomeToolbarDefault, 'true');
    expect(toolbarSwitchValue(tester), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('a stored choice of off still reads off', (tester) async {
    await SettingsHelper.saveStringConfig(showHomeToolbarKey, 'false');
    await openPage(tester);

    expect(toolbarSwitchValue(tester), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
