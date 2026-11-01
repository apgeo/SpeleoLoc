import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/model_viewer_providers.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/cave_model/cave_model_viewer_page.dart';
import 'package:speleoloc/services/cave_model/model_viewer_command.dart';
import 'package:speleoloc/services/cave_model/model_viewer_event.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/documentation_repository.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/widgets/model_viewer/caveview_web_view.dart';
import 'package:speleoloc/widgets/model_viewer/model_viewer_controller.dart';

import 'support/cave_model_fixtures.dart';

/// Mapping a place to a station on a device: a real tap on the WebView opens
/// the station's sheet, the place is mapped, and its mark comes back placed.
///
/// `--dart-define=CAVE_MODEL_HOLD_SECONDS=<n>` keeps the mapped model on
/// screen that long, for a look at the device.
const _holdSeconds = int.fromEnvironment('CAVE_MODEL_HOLD_SECONDS');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a tapped station is mapped and drawn with its mark', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger logger;
    final user = CurrentUserService(
      db,
      UserRepository(db, () => logger),
      ConfigurationRepository(db),
    );
    await user.initialize();
    logger = ChangeLogger(db, user);
    final places = CavePlaceRepository(db, user, logger);
    final cave = await CaveRepository(db, user, logger).addCave('Test Cave');
    await places.addCavePlace(cave, 'Chamber', isEntrance: false);
    await places.addCavePlace(cave, 'Entrance', isEntrance: true);
    final docs = DocumentationRepository(db, logger, user);
    final dir = await Directory.systemTemp.createTemp('cave_model');
    final file = File('${dir.path}/test_cave.lox')
      ..writeAsBytesSync(base64Decode(testCaveLoxBase64));
    final modelUuid = await docs.insertDocumentationFile(
      companion: DocumentationFilesCompanion.insert(
        uuid: Uuid.v7(),
        title: 'test_cave.lox',
        fileName: 'documentation_files/test_cave.lox',
        fileSize: file.lengthSync(),
        fileType: 'survey_model',
      ),
      parentLink: DocumentationGeofeatureLink(
        type: GeofeatureType.cave,
        geofeatureUuid: cave,
      ),
    );
    final model = (await docs.findById(modelUuid))!;

    ModelViewerController? viewerController;
    final events = <ModelViewerEvent>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          modelViewerBuilderProvider.overrideWithValue(({
            required pageUri,
            required controller,
            required onEvent,
          }) {
            viewerController = controller;
            return CaveViewWebView(
              pageUri: pageUri,
              controller: controller,
              onEvent: (e) {
                events.add(e);
                onEvent(e);
              },
            );
          }),
        ],
        child: MaterialApp(
          home: CaveModelViewerPage(
            file: file,
            title: 'Test Cave',
            model: model,
            caveUuid: cave,
          ),
        ),
      ),
    );

    Future<bool> waitFor(bool Function() done, {int seconds = 60}) async {
      final until = DateTime.now().add(Duration(seconds: seconds));
      while (!done()) {
        if (DateTime.now().isAfter(until)) return false;
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await tester.pump();
      }
      return true;
    }

    expect(
      await waitFor(() => events.any((e) => e is ModelViewerLoaded)),
      isTrue,
    );
    await viewerController!.send(
      const FocusModelStation('test_cave.main.3', spanMetres: 20),
    );
    await Future<void>.delayed(const Duration(seconds: 3));
    await tester.pump();
    await tester.tapAt(tester.getCenter(find.byType(CaveViewWebView)));
    expect(
      await waitFor(
        () => find.text('model_map_place_here').evaluate().isNotEmpty,
        seconds: 10,
      ),
      isTrue,
    );
    await tester.tap(find.text('model_map_place_here'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chamber'));
    await tester.pumpAndSettle();

    expect(
      await waitFor(
        () => events.whereType<ModelMarksResolved>().any(
          (e) => e.unresolved.isEmpty,
        ),
        seconds: 10,
      ),
      isTrue,
    );
    final mapped = await db.select(db.cavePlaceModelStations).getSingle();
    expect(mapped.station, 'test_cave.main.3');
    debugPrint('device mapping: mapped and marked');

    if (_holdSeconds > 0) {
      debugPrint('holding the mapped model for $_holdSeconds s');
      await Future<void>.delayed(const Duration(seconds: _holdSeconds));
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
    await db.close();
  });
}
