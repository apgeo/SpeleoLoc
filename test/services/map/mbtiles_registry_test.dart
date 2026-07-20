import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/services/map/mbtiles_registry.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory tempDir;
  late Directory targetDir;
  final registry = MbTilesRegistry();

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('mbtiles_registry_test');
    targetDir = Directory(p.join(tempDir.path, 'mbtiles'))
      ..createSync(recursive: true);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  String createMbTiles(
    String name, {
    String format = 'png',
    List<int> tileData = const [1, 2, 3],
  }) {
    final path = p.join(tempDir.path, name);
    final db = sqlite3.open(path);
    db.execute('CREATE TABLE metadata (name TEXT, value TEXT)');
    db.execute(
      'CREATE TABLE tiles (zoom_level INTEGER, tile_column INTEGER, '
      'tile_row INTEGER, tile_data BLOB)',
    );
    db.execute('INSERT INTO metadata (name, value) VALUES (?, ?)', [
      'format',
      format,
    ]);
    db.execute(
      'INSERT INTO tiles VALUES (?, ?, ?, ?)',
      [0, 0, 0, Uint8List.fromList(tileData)],
    );
    db.close();
    return path;
  }

  group('MbTilesRegistry.importIntoDirectory', () {
    test('copies a valid raster file and returns its descriptor', () async {
      final source = createMbTiles('map.mbtiles');
      final descriptor = await registry.importIntoDirectory(targetDir, source);

      expect(descriptor.fileName, 'map.mbtiles');
      expect(descriptor.metadata.isRaster, isTrue);
      expect(File(p.join(targetDir.path, 'map.mbtiles')).existsSync(), isTrue);
    });

    test('rejects a non-.mbtiles file', () async {
      final source = p.join(tempDir.path, 'notes.txt');
      File(source).writeAsStringSync('hello');

      expect(
        () => registry.importIntoDirectory(targetDir, source),
        throwsA(
          isA<MbTilesImportException>().having(
            (e) => e.error,
            'error',
            MbTilesImportError.wrongExtension,
          ),
        ),
      );
      expect(targetDir.listSync(), isEmpty);
    });

    test('rejects an unreadable .mbtiles file', () async {
      final source = p.join(tempDir.path, 'broken.mbtiles');
      File(source).writeAsBytesSync([0, 1, 2, 3, 4]); // not a sqlite db

      await expectLater(
        registry.importIntoDirectory(targetDir, source),
        throwsA(
          isA<MbTilesImportException>().having(
            (e) => e.error,
            'error',
            MbTilesImportError.notReadable,
          ),
        ),
      );
      expect(targetDir.listSync(), isEmpty);
    });

    test('throws alreadyExists when the target is present', () async {
      final source = createMbTiles('map.mbtiles');
      await registry.importIntoDirectory(targetDir, source);

      await expectLater(
        registry.importIntoDirectory(targetDir, source),
        throwsA(
          isA<MbTilesImportException>().having(
            (e) => e.error,
            'error',
            MbTilesImportError.alreadyExists,
          ),
        ),
      );
    });

    test('overwrite replaces the existing file content', () async {
      final first = createMbTiles('map.mbtiles', tileData: [1, 1, 1]);
      await registry.importIntoDirectory(targetDir, first);

      // A different source file with the same base name.
      final secondDir = Directory(p.join(tempDir.path, 'v2'))..createSync();
      final secondSource = p.join(secondDir.path, 'map.mbtiles');
      File(createMbTiles('src2.mbtiles', tileData: [9, 9, 9]))
          .copySync(secondSource);

      final descriptor = await registry.importIntoDirectory(
        targetDir,
        secondSource,
        overwrite: true,
      );
      expect(descriptor.fileName, 'map.mbtiles');
      expect(targetDir.listSync().whereType<File>().length, 1);
    });

    test('imports a vector file but flags it as non-raster', () async {
      final source = createMbTiles('vec.mbtiles', format: 'pbf');
      final descriptor = await registry.importIntoDirectory(targetDir, source);
      expect(descriptor.metadata.isRaster, isFalse);
      expect(File(p.join(targetDir.path, 'vec.mbtiles')).existsSync(), isTrue);
    });
  });
}
