import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/flow.dart';

/// Proves the harness end to end: the app boots, reaches its first screen
/// without a layout error, and can be photographed.
///
/// Deliberately shallow and deliberately blind to content. Its job is to
/// fail loudly when the app stops starting at all — the regression no unit
/// test can see — and it asserts nothing about what the data says, so it is
/// safe to run against any dataset, including a real one.
void main() {
  flow('smoke', (driver) async {
    await driver.launch();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
    // A rendering error during the first frames — an overflow on this
    // device's width, say — surfaces here as the test's failure.
    expect(driver.tester.takeException(), isNull);
    await driver.shoot('01_home');
  });
}
