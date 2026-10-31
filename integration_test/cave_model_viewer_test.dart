import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speleoloc/providers/model_viewer_providers.dart';
import 'package:speleoloc/screens/cave_model/cave_model_viewer_page.dart';
import 'package:speleoloc/services/cave_model/model_viewer_command.dart';
import 'package:speleoloc/services/cave_model/model_viewer_event.dart';
import 'package:speleoloc/widgets/model_viewer/caveview_web_view.dart';
import 'package:speleoloc/widgets/model_viewer/model_viewer_controller.dart';

import 'support/cave_model_fixtures.dart';

/// The 3D viewer on a device: WebView, loopback server and vendored CaveView
/// together, which no host test can run. Android or iOS only.
///
/// `--dart-define=CAVE_MODEL_PATH=<file on the device>` also opens a model
/// supplied by hand. Of that one only counts and timings are printed, so a
/// real survey can be checked without its contents leaving the device.
const _extraModel = String.fromEnvironment('CAVE_MODEL_PATH');

/// `--dart-define=CAVE_MODEL_HOLD_SECONDS=<n>` keeps the drawn fixture on
/// screen that long, for a look at the device.
const _holdSeconds = int.fromEnvironment('CAVE_MODEL_HOLD_SECONDS');

class _Seen {
  ModelViewerController? controller;
  final events = <ModelViewerEvent>[];

  T? first<T extends ModelViewerEvent>() => events.whereType<T>().firstOrNull;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<File> fixture(String name, String base64) async {
    final dir = await Directory.systemTemp.createTemp('cave_model');
    return File('${dir.path}/$name')..writeAsBytesSync(base64Decode(base64));
  }

  Future<_Seen> open(WidgetTester tester, File file) async {
    final seen = _Seen();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          modelViewerBuilderProvider.overrideWithValue(({
            required pageUri,
            required controller,
            required onEvent,
          }) {
            seen.controller = controller;
            return CaveViewWebView(
              pageUri: pageUri,
              controller: controller,
              onEvent: (event) {
                seen.events.add(event);
                onEvent(event);
              },
            );
          }),
        ],
        child: MaterialApp(
          home: CaveModelViewerPage(file: file, title: 'model'),
        ),
      ),
    );
    return seen;
  }

  Future<bool> waitUntil(
    WidgetTester tester,
    bool Function() done, {
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final until = DateTime.now().add(timeout);
    while (!done()) {
      if (DateTime.now().isAfter(until)) return false;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await tester.pump();
    }
    return true;
  }

  bool settled(_Seen seen) =>
      seen.first<ModelViewerLoaded>() != null ||
      seen.events.any((e) => e is ModelViewerFailed && e.code == 'load');

  testWidgets('draws a .lox, and a tap on a station comes back as it', (
    tester,
  ) async {
    final file = await fixture('test_cave.lox', testCaveLoxBase64);
    final started = DateTime.now();
    final seen = await open(tester, file);
    expect(await waitUntil(tester, () => settled(seen)), isTrue);
    final loaded = seen.first<ModelViewerLoaded>();
    expect(loaded?.stations, 11);
    if (_holdSeconds > 0) {
      debugPrint('holding the drawn fixture for $_holdSeconds s');
      await Future<void>.delayed(Duration(seconds: _holdSeconds));
    }
    debugPrint(
      'lox fixture: drawn in ${DateTime.now().difference(started).inMilliseconds} ms',
    );

    await seen.controller!.send(
      const FocusModelStation('test_cave.main.3', spanMetres: 20),
    );
    await Future<void>.delayed(const Duration(seconds: 3));
    await tester.pump();
    await tester.tapAt(tester.getCenter(find.byType(CaveViewWebView)));
    expect(
      await waitUntil(
        tester,
        () => seen.first<ModelViewerStationTapped>() != null,
        timeout: const Duration(seconds: 10),
      ),
      isTrue,
    );
    expect(seen.first<ModelViewerStationTapped>()!.station, 'test_cave.main.3');
    await tester.pumpAndSettle();
    expect(find.text('test_cave.main.3'), findsOneWidget);
  });

  testWidgets('draws a .3d', (tester) async {
    final file = await fixture('test_cave.3d', testCave3dBase64);
    final seen = await open(tester, file);
    expect(await waitUntil(tester, () => settled(seen)), isTrue);
    expect(seen.first<ModelViewerLoaded>()?.stations, 10);
  });

  testWidgets('draws a model supplied by hand', (tester) async {
    final started = DateTime.now();
    final seen = await open(tester, File(_extraModel));
    final done = await waitUntil(
      tester,
      () => settled(seen),
      timeout: const Duration(minutes: 3),
    );
    final ms = DateTime.now().difference(started).inMilliseconds;
    final loaded = seen.first<ModelViewerLoaded>();
    final failures = seen.events.whereType<ModelViewerFailed>().length;
    debugPrint(
      'supplied model: ${loaded != null
          ? 'drawn, ${loaded.stations} stations'
          : done
          ? 'not drawn'
          : 'no answer'}'
      ' after $ms ms; failures reported: $failures',
    );
    expect(loaded?.stations, greaterThan(0));
  }, skip: _extraModel.isEmpty);
}
