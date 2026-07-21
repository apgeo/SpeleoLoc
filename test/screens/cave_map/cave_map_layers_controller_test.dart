import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_map/cave_map_layers_controller.dart';
import 'package:speleoloc/services/map/mbtiles_reader.dart';
import 'package:speleoloc/services/map/mbtiles_registry.dart';
import 'package:speleoloc/services/map/tile_layer_sources.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  late AppDatabase db;
  late ConfigurationRepository config;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    config = ConfigurationRepository(db);
    tempDir = Directory.systemTemp.createTempSync('layers_ctrl_test');
  });

  tearDown(() async {
    await db.close();
    tempDir.deleteSync(recursive: true);
  });

  String createMbTiles(String fileName) {
    final path = '${tempDir.path}${Platform.pathSeparator}$fileName';
    final raw = sqlite.sqlite3.open(path);
    raw.execute('CREATE TABLE metadata (name TEXT, value TEXT)');
    raw.execute(
      'CREATE TABLE tiles (zoom_level INTEGER, tile_column INTEGER, '
      'tile_row INTEGER, tile_data BLOB)',
    );
    raw.close();
    return path;
  }

  MbTilesDescriptor descriptor(String fileName, {String? path}) =>
      MbTilesDescriptor(
        fileName: fileName,
        path: path ?? '${tempDir.path}${Platform.pathSeparator}$fileName',
        metadata: const MbTilesMetadata(format: 'png'),
      );

  CaveMapLayersController controller(List<MbTilesDescriptor> files) =>
      CaveMapLayersController(
        configRepository: config,
        scanMbTiles: () async => files,
      );

  test('load splits scanned files by configured role', () async {
    await config.writeJson(mapMbtilesConfigKey, {
      'autoLoad': true,
      'roles': {'base.mbtiles': 'base'},
    });
    final layers = controller([
      descriptor('base.mbtiles'),
      descriptor('overlay.mbtiles'),
    ]);
    await layers.load();

    expect(layers.baseDescriptors.map((d) => d.fileName), ['base.mbtiles']);
    expect(layers.overlayDescriptors.map((d) => d.fileName), [
      'overlay.mbtiles',
    ]);
  });

  test('autoLoad off skips the scan entirely', () async {
    await config.writeJson(mapMbtilesConfigKey, {'autoLoad': false});
    var scanned = false;
    final layers = CaveMapLayersController(
      configRepository: config,
      scanMbTiles: () async {
        scanned = true;
        return [descriptor('a.mbtiles')];
      },
    );
    await layers.load();

    expect(scanned, isFalse);
    expect(layers.overlayDescriptors, isEmpty);
  });

  test('prefs restore keeps only ids and overlays that still exist', () async {
    await config.writeJson(mapScreenPrefsKey, {
      'base': 'osm',
      'overlays': ['known.mbtiles', 'gone.mbtiles'],
    });
    final layers = controller([descriptor('known.mbtiles')]);
    await layers.load();

    expect(layers.baseId, 'osm');
    expect(layers.enabledOverlays, {'known.mbtiles'});

    await config.writeJson(mapScreenPrefsKey, {'base': 'mbtiles:gone.mbtiles'});
    final layers2 = controller([]);
    await layers2.load();
    expect(
      layers2.baseId,
      builtInTileSourcesDefaultId,
      reason: 'a vanished mbtiles base falls back to the default',
    );
  });

  test('selectBase persists the choice', () async {
    final layers = controller([]);
    await layers.load();
    layers.selectBase('google_hybrid');

    // savePrefs is fire-and-forget; wait for the write to land.
    await Future<void>.delayed(Duration.zero);
    final prefs = await config.readJson(
      mapScreenPrefsKey,
      defaults: () => <String, dynamic>{},
    );
    expect(prefs['base'], 'google_hybrid');
    expect(layers.attributionText, isNot(descriptor('x').displayName));
  });

  test('mbtiles base: blank while opening, layer + attribution after', () async {
    createMbTiles('real.mbtiles');
    await config.writeJson(mapMbtilesConfigKey, {
      'roles': {'real.mbtiles': 'base'},
    });
    await config.writeJson(mapScreenPrefsKey, {
      'base': 'mbtiles:real.mbtiles',
    });
    final layers = controller([descriptor('real.mbtiles')]);
    await layers.load();
    expect(layers.baseId, 'mbtiles:real.mbtiles');

    final opened = Completer<void>();
    layers.addListener(() {
      if (!opened.isCompleted) opened.complete();
    });

    // First build: the worker is still opening — no base layer, but the
    // attribution already names the file (never the online fallback).
    expect(layers.buildBaseLayer(), isNull);
    expect(layers.attributionText, 'real.mbtiles');

    await opened.future;
    expect(layers.buildBaseLayer(), isNotNull);
    expect(layers.attributionText, 'real.mbtiles');

    layers.dispose();
  });

  test('unreadable mbtiles base falls back to the online source', () async {
    final bogusPath = '${tempDir.path}${Platform.pathSeparator}bad.mbtiles';
    File(bogusPath).writeAsStringSync('not a database');
    await config.writeJson(mapMbtilesConfigKey, {
      'roles': {'bad.mbtiles': 'base'},
    });
    await config.writeJson(mapScreenPrefsKey, {'base': 'mbtiles:bad.mbtiles'});
    final layers = controller([descriptor('bad.mbtiles', path: bogusPath)]);
    await layers.load();

    final failed = Completer<void>();
    layers.addListener(() {
      if (!failed.isCompleted) failed.complete();
    });
    expect(layers.buildBaseLayer(), isNull);

    await failed.future;
    final fallback = layers.buildBaseLayer();
    expect(fallback, isNotNull);
    expect(fallback!.urlTemplate, isNotNull, reason: 'online fallback');
    expect(
      layers.attributionText,
      (findTileSourceById('mbtiles:bad.mbtiles') ?? builtInTileSources.first)
          .attribution,
    );

    layers.dispose();
  });
}
