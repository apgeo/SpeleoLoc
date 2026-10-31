import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:speleoloc/app.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/screens/user_setup/user_setup_page.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/constants.dart';

void main() {
  Future<ProviderContainer> bootContainer() async {
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
    return container;
  }

  Future<void> unmount(WidgetTester tester) async {
    // Unmount the app and flush drift's zero-duration stream-close timers
    // (created in HomePage.dispose) before the pending-timer guard runs.
    // The pump needs an explicit duration: pump() without one only flushes
    // microtasks and never elapses the fake clock, leaving those timers
    // pending.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('App boots and shows home shell', (WidgetTester tester) async {
    final container = await bootContainer();
    // With a user chosen, start-up has nothing to ask.
    await container
        .read(currentUserResolverProvider)
        .createAndChoose(username: 'tester');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SpeleoLocApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(appName), findsOneWidget);
    expect(find.byType(UserSetupPage), findsNothing);
    await unmount(tester);
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('a fresh install asks who is using the app', (
    WidgetTester tester,
  ) async {
    final container = await bootContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SpeleoLocApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(UserSetupPage), findsOneWidget);
    await unmount(tester);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
