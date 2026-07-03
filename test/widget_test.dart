import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:speleoloc/app.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/constants.dart';

void main() {
  testWidgets('App boots and shows home shell', (WidgetTester tester) async {
    // Mirror main()'s composition root: a ProviderContainer shared with the
    // widget tree AND registered as the legacy rootContainer (HomePage still
    // reaches repositories through service_locator.dart during the DI
    // migration). Back it with an in-memory database so the test is
    // hermetic — no path_provider platform channel involved.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    initRootContainer(container);

    // The home screen's product tour schedules a delayed auto-start timer
    // that would trip flutter_test's pending-timer guard; disable it the
    // same way the settings screen does.
    await SettingsHelper.saveStringConfig('tour_auto_disabled', 'true');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SpeleoLocApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(appName), findsOneWidget);

    // Unmount the app and flush drift's zero-duration stream-close timers
    // (created in HomePage.dispose) before the pending-timer guard runs.
    // The pump needs an explicit duration: pump() without one only flushes
    // microtasks and never elapses the fake clock, leaving those timers
    // pending.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
