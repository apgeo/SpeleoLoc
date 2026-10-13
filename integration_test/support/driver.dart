import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speleoloc/main.dart' as app;

/// Shared plumbing for the on-device tests.
///
/// Keeps the two things every such test needs out of the tests themselves:
/// starting the real `main()` and waiting out its asynchronous startup, and
/// taking a screenshot in the one way that works on Android.
class AppDriver {
  AppDriver(this.binding, this.tester);

  final IntegrationTestWidgetsFlutterBinding binding;
  final WidgetTester tester;

  static IntegrationTestWidgetsFlutterBinding ensureInitialized() =>
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Boots the real application and waits for its first screen.
  ///
  /// Polling rather than `pumpAndSettle`: startup awaits the database, the
  /// i18n bundle, the current user and the active-trip lookup before
  /// `runApp`, so the first frame can arrive long after the test begins.
  Future<void> launch({Duration timeout = const Duration(seconds: 90)}) async {
    app.main();
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.byType(MaterialApp).evaluate().isNotEmpty) break;
    }
    expect(
      find.byType(MaterialApp),
      findsOneWidget,
      reason: 'the app did not reach its first frame within $timeout',
    );
    await settle();
  }

  /// Pumps until the UI is idle, tolerating what a real screen leaves
  /// running — the product tour's timers, a progress indicator — which
  /// would make a bare `pumpAndSettle` time out and fail the flow.
  Future<void> settle({Duration timeout = const Duration(seconds: 20)}) async {
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        timeout,
      );
    } catch (e) {
      stdout.writeln('still animating after $timeout ($e); continuing');
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }
  }

  /// Captures the current screen under [name].
  ///
  /// On Android the surface must be converted before it can be read back.
  /// A platform without that call still runs the flow — the screenshot is
  /// the part that is optional, not the assertions.
  Future<void> shoot(String name) async {
    try {
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
    } catch (e) {
      stdout.writeln('surface conversion unavailable ($e)');
    }
    await binding.takeScreenshot(name);
  }

  /// Taps the first match for [finder] when it is present, returning
  /// whether it was. Lets a flow walk past a screen that may or may not be
  /// showing (a first-run tour, a permission prompt) without branching in
  /// the test body.
  Future<bool> tapIfPresent(Finder finder) async {
    if (finder.evaluate().isEmpty) return false;
    await tester.tap(finder.first);
    await settle();
    return true;
  }
}
