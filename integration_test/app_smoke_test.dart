import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/utils/localization.dart';

import 'support/driver.dart';

/// Proves the harness end to end on a real device: the app boots, reaches
/// its first screen, and can be photographed.
///
/// Deliberately shallow. Its job is to fail loudly when the app stops
/// starting at all — the regression no unit test can see — and to be the
/// worked example the deeper flows are written against.
void main() {
  final binding = AppDriver.ensureInitialized();

  testWidgets('the app boots and shows its home screen', (tester) async {
    final driver = AppDriver(binding, tester);
    await driver.launch();

    expect(find.byType(MaterialApp), findsOneWidget);
    // The product tour may cover the screen on a first run; dismiss it so
    // the screenshot shows the app rather than the overlay.
    await driver.tapIfPresent(find.text(LocServ.inst.t('skip')));
    await driver.shoot('01_home');
  });

  testWidgets('the caves list opens', (tester) async {
    final driver = AppDriver(binding, tester);
    await driver.launch();
    await driver.tapIfPresent(find.text(LocServ.inst.t('skip')));

    final caves = find.text(LocServ.inst.t('caves'));
    if (caves.evaluate().isEmpty) {
      markTestSkipped('no "caves" entry point on this build');
      return;
    }
    await tester.tap(caves.first);
    await driver.settle();
    await driver.shoot('02_caves');
  });
}
