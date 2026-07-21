import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/map/mbtiles_isolate_reader.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('mbtiles_isolate_test');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  String createMbTiles({
    Map<String, String> metadata = const {},
    List<(int, int, int, List<int>)> tiles = const [],
  }) {
    final path = '${tempDir.path}${Platform.pathSeparator}test.mbtiles';
    final db = sqlite3.open(path);
    db.execute('CREATE TABLE metadata (name TEXT, value TEXT)');
    db.execute(
      'CREATE TABLE tiles (zoom_level INTEGER, tile_column INTEGER, '
      'tile_row INTEGER, tile_data BLOB)',
    );
    for (final entry in metadata.entries) {
      db.execute('INSERT INTO metadata (name, value) VALUES (?, ?)', [
        entry.key,
        entry.value,
      ]);
    }
    for (final (z, col, row, data) in tiles) {
      db.execute(
        'INSERT INTO tiles (zoom_level, tile_column, tile_row, tile_data) '
        'VALUES (?, ?, ?, ?)',
        [z, col, row, Uint8List.fromList(data)],
      );
    }
    db.close();
    return path;
  }

  group('MbTilesIsolateReader', () {
    test('open surfaces the worker-parsed metadata', () async {
      final path = createMbTiles(
        metadata: {'name': 'Test Map', 'minzoom': '10', 'maxzoom': '12'},
      );
      final reader = await MbTilesIsolateReader.open(path);
      addTearDown(reader.dispose);

      expect(reader.metadata.name, 'Test Map');
      expect(reader.metadata.minZoom, 10);
      expect(reader.metadata.maxZoom, 12);
    });

    test('serves tiles with the TMS y-flip, null outside coverage', () async {
      // XYZ (10, 590, 368) == TMS row 2^10 - 1 - 368 = 655.
      final path = createMbTiles(
        tiles: [
          (10, 590, 655, [1, 2, 3]),
        ],
      );
      final reader = await MbTilesIsolateReader.open(path);
      addTearDown(reader.dispose);

      expect(await reader.tile(10, 590, 368), [1, 2, 3]);
      expect(await reader.tile(10, 591, 368), isNull);
    });

    test('handles many concurrent in-flight requests', () async {
      final path = createMbTiles(
        tiles: [
          for (var x = 0; x < 8; x++)
            for (var y = 0; y < 8; y++) (3, x, y, [x, y]),
        ],
      );
      final reader = await MbTilesIsolateReader.open(path);
      addTearDown(reader.dispose);

      final fetched = await Future.wait([
        for (var x = 0; x < 8; x++)
          for (var y = 0; y < 8; y++) reader.tile(3, x, y),
      ]);
      var i = 0;
      for (var x = 0; x < 8; x++) {
        for (var y = 0; y < 8; y++) {
          expect(fetched[i++], [x, (1 << 3) - 1 - y]);
        }
      }
    });

    test('open throws on a non-MBTiles file and the isolate exits', () async {
      final path = '${tempDir.path}${Platform.pathSeparator}plain.mbtiles';
      final db = sqlite3.open(path);
      db.execute('CREATE TABLE other (x INTEGER)');
      db.close();

      await expectLater(
        MbTilesIsolateReader.open(path),
        throwsA(isA<StateError>()),
      );
    });

    test('dispose resolves outstanding requests with null', () async {
      final path = createMbTiles(
        tiles: [
          (5, 1, 1, [9]),
        ],
      );
      final reader = await MbTilesIsolateReader.open(path);

      final pending = reader.tile(5, 1, (1 << 5) - 2);
      reader.dispose();
      expect(await pending, isNull);
      expect(await reader.tile(5, 1, (1 << 5) - 2), isNull);
      reader.dispose(); // idempotent
    });
  });
}
