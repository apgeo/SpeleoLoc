import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/model_viewer_providers.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/cave_model/cave_model_viewer_page.dart';
import 'package:speleoloc/services/cave_model/model_viewer_asset_server.dart';
import 'package:speleoloc/services/cave_model/model_viewer_command.dart';
import 'package:speleoloc/services/cave_model/model_viewer_event.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/documentation_repository.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/widgets/model_viewer/model_viewer_controller.dart';
import 'package:speleoloc/widgets/model_viewer/model_viewer_host.dart';

/// Mapping a cave's places to stations on the 3D screen, with the WebView
/// replaced by a stand-in and the real repositories on a memory database.
class _FakeViewer implements ModelViewerHost {
  ValueChanged<ModelViewerEvent>? report;
  final sent = <ModelViewerCommand>[];

  Widget build({
    required Uri pageUri,
    required ModelViewerController controller,
    required ValueChanged<ModelViewerEvent> onEvent,
  }) {
    report = onEvent;
    controller.attach(this);
    return const SizedBox.expand();
  }

  @override
  Future<void> send(ModelViewerCommand command) async => sent.add(command);

  List<ModelMark>? get lastMarks =>
      sent.whereType<SetModelMarks>().lastOrNull?.marks;
}

void main() {
  late _FakeViewer viewer;
  late AppDatabase db;
  late Uuid cave;
  late CavePlace chamber;
  late DocumentationFile model;

  setUp(() async {
    viewer = _FakeViewer();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger logger;
    final user = CurrentUserService(
      db,
      UserRepository(db, () => logger),
      ConfigurationRepository(db),
    );
    await user.initialize();
    logger = ChangeLogger(db, user);
    final places = CavePlaceRepository(db, user, logger);
    cave = await CaveRepository(db, user, logger).addCave('Test Cave');
    await places.addCavePlace(cave, 'Chamber');
    await places.addCavePlace(cave, 'Sump');
    chamber = (await places.getCavePlaces(
      cave,
    )).firstWhere((p) => p.title == 'Chamber');
    final docs = DocumentationRepository(db, logger, user);
    final uuid = await docs.insertDocumentationFile(
      companion: DocumentationFilesCompanion.insert(
        uuid: Uuid.v7(),
        title: 'test_cave.lox',
        fileName: 'documentation_files/test_cave.lox',
        fileSize: 1,
        fileType: 'survey_model',
      ),
      parentLink: DocumentationGeofeatureLink(
        type: GeofeatureType.cave,
        geofeatureUuid: cave,
      ),
    );
    model = (await docs.findById(uuid))!;
  });

  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, {Uuid? focusPlaceUuid}) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            modelViewerBuilderProvider.overrideWithValue(viewer.build),
            modelViewerAssetServerFactoryProvider.overrideWithValue(
              (file, format) => ModelViewerAssetServer(
                loadAsset: (_) async => null,
                modelFile: file,
                format: format,
              ),
            ),
          ],
          child: MaterialApp(
            home: CaveModelViewerPage(
              file: File('test_data/cave_models/test_cave.lox'),
              title: 'Test Cave',
              model: model,
              caveUuid: cave,
              focusPlaceUuid: focusPlaceUuid,
            ),
          ),
        ),
      );
      for (var i = 0; i < 40 && viewer.report == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
        await tester.pump();
      }
      viewer.report!(const ModelViewerLoaded(stations: 11));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await settle(tester);
  }

  /// Drift closes a watched query on a zero-length timer once the screen
  /// lets go of it; the screen is taken down inside the test so that timer
  /// runs before the test ends.
  void flowTest(String name, Future<void> Function(WidgetTester) body) =>
      testWidgets(name, (tester) async {
        await body(tester);
        await tester.pumpWidget(const SizedBox());
        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 10));
        }
      });

  Future<List<CavePlaceModelStation>> mappings() =>
      db.select(db.cavePlaceModelStations).get();

  flowTest('a tapped station is mapped to a place picked from the cave', (
    tester,
  ) async {
    await open(tester);
    expect(viewer.lastMarks, isEmpty);

    viewer.report!(const ModelViewerStationTapped(station: 'test_cave.main.3'));
    await settle(tester);
    await tester.tap(find.text('model_map_place_here'));
    await settle(tester);
    await tester.tap(find.text('Chamber'));
    await settle(tester);

    final saved = await tester.runAsync(mappings);
    expect(saved!.single.station, 'test_cave.main.3');
    expect(saved.single.cavePlaceUuid, chamber.uuid);
    await settle(tester);
    expect(viewer.lastMarks?.single.label, 'Chamber');
  });

  flowTest('an unmapped place opens asking for its station', (tester) async {
    await open(tester, focusPlaceUuid: chamber.uuid);
    expect(find.text('model_pick_station_for'), findsOneWidget);

    viewer.report!(const ModelViewerStationTapped(station: 'test_cave.side.3'));
    await settle(tester);
    final saved = await tester.runAsync(mappings);
    expect(saved!.single.station, 'test_cave.side.3');
    expect(find.text('model_pick_station_for'), findsNothing);
  });

  flowTest('a mapped place opens on its station', (tester) async {
    await tester.runAsync(
      () => db
          .into(db.cavePlaceModelStations)
          .insert(
            CavePlaceModelStationsCompanion.insert(
              uuid: Uuid.v7(),
              cavePlaceUuid: chamber.uuid,
              caveUuid: cave,
              documentationFileUuid: model.uuid,
              station: 'test_cave.main.6',
            ),
          ),
    );
    await open(tester, focusPlaceUuid: chamber.uuid);
    final focus = viewer.sent.whereType<FocusModelStation>().last;
    expect(focus.station, 'test_cave.main.6');
    expect(viewer.lastMarks?.single.station, 'test_cave.main.6');
  });

  flowTest('a splay end picked on the model is mapped as needing review', (
    tester,
  ) async {
    await open(tester);
    viewer.report!(const ModelViewerStationTapped(station: 'test_cave.main.3'));
    await settle(tester);
    await tester.tap(find.text('model_map_splay_end'));
    await settle(tester);
    expect(
      viewer.sent.whereType<ShowSplayPicker>().single.station,
      'test_cave.main.3',
    );

    viewer.report!(
      ModelViewerEvent.decode(
        '{"v":1,"type":"splayPicked","station":"test_cave.main.3",'
        '"offset":[1.5,-0.5,2.25]}',
      )!,
    );
    await settle(tester);
    await tester.tap(find.text('Sump'));
    await settle(tester);

    final saved = (await tester.runAsync(mappings))!.single;
    expect(saved.needsReview, 1);
    expect(
      [saved.splayEast, saved.splayNorth, saved.splayUp],
      [1.5, -0.5, 2.25],
    );
  });
}
