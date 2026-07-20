import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/map/mbtiles_reader.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('mbtiles_test');
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
      db.execute(
        'INSERT INTO metadata (name, value) VALUES (?, ?)',
        [entry.key, entry.value],
      );
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

  group('MbTilesReader', () {
    test('parses metadata including bounds and zoom range', () {
      final path = createMbTiles(
        metadata: {
          'name': 'Test Map',
          'format': 'PNG',
          'minzoom': '10',
          'maxzoom': '12',
          'bounds': '22.5,45.1,22.9,45.4',
        },
      );
      final reader = MbTilesReader.open(path);
      addTearDown(reader.dispose);

      expect(reader.metadata.name, 'Test Map');
      expect(reader.metadata.format, 'png');
      expect(reader.metadata.isRaster, isTrue);
      expect(reader.metadata.minZoom, 10);
      expect(reader.metadata.maxZoom, 12);
      expect(reader.metadata.hasBounds, isTrue);
      expect(reader.metadata.west, 22.5);
      expect(reader.metadata.south, 45.1);
      expect(reader.metadata.east, 22.9);
      expect(reader.metadata.north, 45.4);
    });

    test('flags pbf files as non-raster', () {
      final path = createMbTiles(metadata: {'format': 'pbf'});
      final reader = MbTilesReader.open(path);
      addTearDown(reader.dispose);
      expect(reader.metadata.isRaster, isFalse);
    });

    test('sparse metadata falls back to permissive defaults', () {
      final path = createMbTiles();
      final reader = MbTilesReader.open(path);
      addTearDown(reader.dispose);
      expect(reader.metadata.format, 'png');
      expect(reader.metadata.minZoom, isNull);
      expect(reader.metadata.maxZoom, isNull);
      expect(reader.metadata.hasBounds, isFalse);
    });

    test('reads XYZ tiles with the TMS y-flip', () {
      // XYZ (10, 590, 368) == TMS row 2^10 - 1 - 368 = 655.
      final path = createMbTiles(
        tiles: [(10, 590, 655, [1, 2, 3])],
      );
      final reader = MbTilesReader.open(path);
      addTearDown(reader.dispose);

      expect(reader.tile(10, 590, 368), [1, 2, 3]);
      expect(reader.tile(10, 590, 655), isNull); // un-flipped row misses
      expect(reader.tile(10, 591, 368), isNull);
      expect(reader.tile(11, 590, 368), isNull);
    });

    test('open throws on a file without MBTiles tables', () {
      final path = '${tempDir.path}${Platform.pathSeparator}plain.mbtiles';
      final db = sqlite3.open(path);
      db.execute('CREATE TABLE other (x INTEGER)');
      db.close();

      expect(() => MbTilesReader.open(path), throwsA(anything));
    });
  });
}
