import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/widgets/system_bars_inset_guard.dart';

void main() {
  const navBarInset = 48.0;
  const bottomButtonKey = Key('bottom-button');

  Widget buildApp() {
    return MaterialApp(
      builder: (context, child) => SystemBarsInsetGuard(child: child!),
      home: Scaffold(
        body: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ElevatedButton(
                key: bottomButtonKey,
                onPressed: () {},
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('lifts bottom content above a 3-button navigation bar', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(bottom: navBarInset * 3);
    tester.view.viewPadding = const FakeViewPadding(bottom: navBarInset * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp());

    final screenHeight = tester.view.physicalSize.height / 3;
    final buttonBottom = tester.getBottomLeft(find.byKey(bottomButtonKey)).dy;
    expect(buttonBottom, lessThanOrEqualTo(screenHeight - navBarInset));
  });

  testWidgets('descendants see no leftover bottom padding', (tester) async {
    tester.view.padding = const FakeViewPadding(bottom: navBarInset * 3);
    tester.view.viewPadding = const FakeViewPadding(bottom: navBarInset * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp());

    final ctx = tester.element(find.byKey(bottomButtonKey));
    expect(MediaQuery.paddingOf(ctx).bottom, 0);
  });

  testWidgets('adds no inset when the system reserves none', (tester) async {
    tester.view.padding = FakeViewPadding.zero;
    tester.view.viewPadding = FakeViewPadding.zero;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp());

    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final buttonBottom = tester.getBottomLeft(find.byKey(bottomButtonKey)).dy;
    expect(buttonBottom, screenHeight);
  });
}
