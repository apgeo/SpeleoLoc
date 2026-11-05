import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/general_data/raster_map_form.dart';
import 'package:speleoloc/services/raster_map_repository.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/app_exceptions.dart';
import 'package:speleoloc/widgets/product_tour.dart';

/// Writes that always fail, as a locked or full database would.
class _FailingRasterMaps extends RasterMapRepository {
  _FailingRasterMaps(super.db, super.currentUser, super.logger);

  int adds = 0;

  @override
  Future<void> addRasterMap(RasterMapsCompanion companion) async {
    adds++;
    throw const DbException('invented failure');
  }
}

/// The raster map form stores one map however often Save is tapped, says
/// when a write fails, and does not leave the pictures it copied behind
/// when they are replaced or the form is abandoned.
void main() {
  late Directory docs;
  late Directory source;
  late AppDatabase db;
  late ProviderContainer container;
  late Uuid caveUuid;
  late List<String> pickQueue;
  bool failWrites = false;
  _FailingRasterMaps? failing;

  setUp(() async {
    docs = await Directory.systemTemp.createTemp('speleoloc_rm_docs_');
    source = await Directory.systemTemp.createTemp('speleoloc_rm_picks_');
    pickQueue = [];
    failWrites = false;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async =>
          call.method == 'getApplicationDocumentsDirectory' ? docs.path : null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/image_picker'),
      (call) async => call.method == 'pickImage' ? pickQueue.removeAt(0) : null,
    );
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        rasterMapRepositoryProvider.overrideWith(
          (ref) => failWrites
              ? failing = _FailingRasterMaps(
                  db,
                  ref.read(currentUserServiceProvider),
                  ref.read(changeLoggerProvider),
                )
              : RasterMapRepository(
                  db,
                  ref.read(currentUserServiceProvider),
                  ref.read(changeLoggerProvider),
                ),
        ),
      ],
    );
    initRootContainer(container);
    await setAutoToursDisabled(true);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    await docs.delete(recursive: true);
    await source.delete(recursive: true);
  });

  /// Lets real I/O and isolates finish between pumps.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<String> pickable(String name, String content) async {
    final f = File('${source.path}/$name');
    await f.writeAsString(content);
    return f.path;
  }

  late GlobalKey<NavigatorState> navigator;
  late Future<bool?> result;

  Future<void> openForm(WidgetTester tester) async {
    caveUuid = (await tester.runAsync(
      () => container.read(caveRepositoryProvider).addCave('Invented cave'),
    ))!;
    navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(navigatorKey: navigator, home: const Scaffold()),
      ),
    );
    result = navigator.currentState!.push<bool>(
      MaterialPageRoute(builder: (_) => RasterMapForm(caveUuid: caveUuid)),
    );
    await settle(tester);
  }

  Future<void> pick(WidgetTester tester, String name) async {
    pickQueue.add(
      (await tester.runAsync(() => pickable(name, 'invented picture $name')))!,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'select_image'));
    await settle(tester);
  }

  List<File> storedImages() {
    final folder = Directory('${docs.path}/cave_$caveUuid');
    if (!folder.existsSync()) return [];
    return folder.listSync().whereType<File>().toList();
  }

  VoidCallback saveAction(WidgetTester tester) => tester
      .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'save'))
      .onPressed!;

  testWidgets('a double tap on Save stores one map', (tester) async {
    await openForm(tester);
    await pick(tester, 'a.png');

    final save = saveAction(tester);
    save();
    save();
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(await result, isTrue);
    final maps = await tester.runAsync(
      () => container.read(rasterMapRepositoryProvider).getRasterMaps(caveUuid),
    );
    expect(maps, hasLength(1));
    // The stored map keeps its picture.
    expect(storedImages(), hasLength(1));
  });

  testWidgets('a failed write is reported and Save works again', (
    tester,
  ) async {
    failWrites = true;
    await openForm(tester);
    await pick(tester, 'a.png');

    saveAction(tester)();
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(failing!.adds, 1);
    expect(find.byType(RasterMapForm), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'save'))
          .onPressed,
      isNotNull,
    );

    // Leave the form to finish the test's route.
    navigator.currentState!.pop();
    await settle(tester);
    expect(await result, isNull);
  });

  testWidgets('a replaced picture is removed, an abandoned one too', (
    tester,
  ) async {
    await openForm(tester);
    await pick(tester, 'a.png');
    expect(storedImages(), hasLength(1));

    await pick(tester, 'b.png');
    expect(storedImages(), hasLength(1), reason: 'the first pick is replaced');

    navigator.currentState!.pop();
    await settle(tester);

    expect(await result, isNull);
    expect(storedImages(), isEmpty, reason: 'nothing was saved');
  });

  testWidgets('a cancelled picker changes nothing', (tester) async {
    await openForm(tester);
    await pick(tester, 'a.png');

    pickQueue.add('');
    // The mock answers null for a cancelled pick.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/image_picker'),
          (call) async => null,
        );
    await tester.tap(find.widgetWithText(ElevatedButton, 'select_image'));
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(storedImages(), hasLength(1));
    navigator.currentState!.pop();
    await settle(tester);
  });
}
