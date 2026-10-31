import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/providers/model_viewer_providers.dart';
import 'package:speleoloc/screens/cave_model/cave_model_viewer_page.dart';
import 'package:speleoloc/services/cave_model/model_viewer_asset_server.dart';
import 'package:speleoloc/services/cave_model/model_viewer_command.dart';
import 'package:speleoloc/services/cave_model/model_viewer_event.dart';
import 'package:speleoloc/widgets/model_viewer/model_viewer_controller.dart';
import 'package:speleoloc/widgets/model_viewer/model_viewer_host.dart';
import 'package:speleoloc/widgets/model_viewer/model_viewer_unavailable.dart';

/// The screen around the viewer, with the WebView replaced by a stand-in that
/// records what it is asked and reports what the test says the page reported.
class _FakeViewer implements ModelViewerHost {
  Uri? pageUri;
  ValueChanged<ModelViewerEvent>? report;
  final sent = <ModelViewerCommand>[];

  Widget build({
    required Uri pageUri,
    required ModelViewerController controller,
    required ValueChanged<ModelViewerEvent> onEvent,
  }) {
    this.pageUri = pageUri;
    report = onEvent;
    controller.attach(this);
    return const SizedBox.expand(key: Key('fake-viewer'));
  }

  @override
  Future<void> send(ModelViewerCommand command) async => sent.add(command);
}

void main() {
  late _FakeViewer viewer;

  setUp(() => viewer = _FakeViewer());

  Future<void> open(
    WidgetTester tester,
    String fixture, {
    bool supported = true,
  }) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            modelViewerBuilderProvider.overrideWithValue(
              supported ? viewer.build : null,
            ),
            modelViewerAssetServerFactoryProvider.overrideWithValue(
              (file, format) => ModelViewerAssetServer(
                loadAsset: (_) async => null,
                modelFile: file,
                format: format,
              ),
            ),
          ],
          child: MaterialApp(
            home: CaveModelViewerPage(file: File(fixture), title: 'Test Cave'),
          ),
        ),
      );
      // The format is read from the file and a loopback port opened: real
      // I/O, which only completes outside the test's fake clock.
      for (var i = 0; i < 20 && viewer.pageUri == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
        await tester.pump();
      }
    });
    await tester.pump();
  }

  testWidgets('opens the page for a .lox, shows progress until it is drawn', (
    tester,
  ) async {
    await open(tester, 'test_data/cave_models/test_cave.lox');
    expect(viewer.pageUri?.queryParameters['model'], 'model.lox');
    expect(find.byKey(const Key('fake-viewer')), findsOneWidget);
    expect(find.text('model_viewer_loading'), findsOneWidget);

    viewer.report!(const ModelViewerLoaded(stations: 11));
    await tester.pump();
    expect(find.text('model_viewer_loading'), findsNothing);
    expect(find.byTooltip('model_viewer_views'), findsOneWidget);
  });

  testWidgets('names a .3d by its format whatever the file is called', (
    tester,
  ) async {
    await open(tester, 'test_data/cave_models/test_cave.3d');
    expect(viewer.pageUri?.queryParameters['model'], 'model.3d');
  });

  testWidgets('turns the view from the app bar', (tester) async {
    await open(tester, 'test_data/cave_models/test_cave.lox');
    viewer.report!(const ModelViewerLoaded(stations: 11));
    await tester.pump();

    await tester.tap(find.byTooltip('model_viewer_views'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('model_view_east'));
    await tester.pumpAndSettle();
    expect(viewer.sent.whereType<SetModelView>().single.view, ModelView.east);
  });

  testWidgets('a tapped station opens a sheet that centres the view on it', (
    tester,
  ) async {
    await open(tester, 'test_data/cave_models/test_cave.lox');
    viewer.report!(const ModelViewerLoaded(stations: 11));
    viewer.report!(
      const ModelViewerStationTapped(
        station: 'test_cave.main.3',
        x: 15.54,
        y: -7.83,
        z: -4.73,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('test_cave.main.3'), findsOneWidget);

    await tester.tap(find.text('model_station_centre'));
    await tester.pumpAndSettle();
    final focus = viewer.sent.whereType<FocusModelStation>().single;
    expect(focus.station, 'test_cave.main.3');
    expect(find.text('test_cave.main.3'), findsNothing);
  });

  testWidgets('a file the viewer cannot read shows why', (tester) async {
    await open(tester, 'test_data/cave_models/test_cave.lox');
    viewer.report!(
      const ModelViewerFailed(code: 'load', message: 'unsupported version'),
    );
    await tester.pump();
    expect(find.text('model_viewer_failed'), findsOneWidget);
    expect(find.text('unsupported version'), findsOneWidget);
    expect(find.byKey(const Key('fake-viewer')), findsNothing);
  });

  testWidgets('a file that is no survey model never reaches the viewer', (
    tester,
  ) async {
    await open(tester, 'pubspec.yaml');
    expect(viewer.pageUri, isNull);
    expect(find.text('model_viewer_not_a_model'), findsOneWidget);
  });

  testWidgets('says so where the platform has no WebView', (tester) async {
    await open(tester, 'test_data/cave_models/test_cave.lox', supported: false);
    expect(find.byType(ModelViewerUnavailable), findsOneWidget);
    expect(viewer.pageUri, isNull);
  });
}
