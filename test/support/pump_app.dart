import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/widgets/product_tour.dart';

/// Scaffolding for widget tests of screens that read files and the database.
///
/// A screen's file and database work runs on the real event loop, which the
/// widget tester's fake clock does not drive. These helpers alternate real
/// waits with frames, so a screen that loads on start-up has finished by the
/// time the test looks at it.

/// Answers `path_provider` with the given folders for as long as the test
/// runs. Without [temporary] the temporary folder is unknown to the screen.
void mockPathProvider({required Directory documents, Directory? temporary}) {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  messenger.setMockMethodCallHandler(channel, (call) async {
    switch (call.method) {
      case 'getApplicationDocumentsDirectory':
        return documents.path;
      case 'getTemporaryDirectory':
        return temporary?.path;
    }
    return null;
  });
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
}

/// Lets real file and database work run between frames: [rounds] real waits
/// of 20 ms, each followed by a 50 ms frame.
Future<void> settleWithRealTime(WidgetTester tester, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Shows [home] over [container] with the product tours switched off, and
/// waits for the screen's start-up work.
Future<void> pumpScreen(
  WidgetTester tester,
  ProviderContainer container,
  Widget home, {
  Iterable<LocalizationsDelegate<dynamic>> delegates = const [],
}) async {
  await tester.runAsync(() => setAutoToursDisabled(true));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(localizationsDelegates: delegates, home: home),
    ),
  );
  await settleWithRealTime(tester, rounds: 5);
}
