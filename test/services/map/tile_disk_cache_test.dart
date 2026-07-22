import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:speleoloc/services/map/tile_disk_cache.dart';

void main() {
  late Directory tempDir;
  late TileDiskCache cache;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('tile_cache_test');
    cache = TileDiskCache(Directory('${tempDir.path}/tile_cache'));
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('TileDiskCache', () {
    test('write/read round trip under the per-source layout', () async {
      await cache.write('osm', 12, 2282, 1441, [1, 2, 3]);

      final cached = await cache.read('osm', 12, 2282, 1441);
      expect(cached, isNotNull);
      expect(cached!.bytes, [1, 2, 3]);
      expect(
        cache.fileFor('osm', 12, 2282, 1441).path.replaceAll('\\', '/'),
        endsWith('tile_cache/osm/12/2282_1441.png'),
      );
    });

    test('read misses return null', () async {
      expect(await cache.read('osm', 1, 2, 3), isNull);
    });

    test('totalSizeBytes sums every tile and clear removes them', () async {
      await cache.write('osm', 1, 0, 0, List.filled(100, 7));
      await cache.write('opentopomap', 2, 1, 1, List.filled(50, 7));

      expect(await cache.totalSizeBytes(), 150);
      await cache.clear();
      expect(await cache.totalSizeBytes(), 0);
      expect(await cache.read('osm', 1, 0, 0), isNull);
    });
  });

  group('loadTileBytes', () {
    final url = Uri.parse('https://tile.example/12/2282/1441.png');

    http.Client clientReturning(List<int> bytes, {int status = 200}) =>
        MockClient((request) async {
          return http.Response.bytes(bytes, status);
        });

    http.Client failingClient() =>
        MockClient((request) async => throw const SocketException('offline'));

    test('fetches, caches and returns network bytes on a miss', () async {
      final bytes = await loadTileBytes(
        cache: cache,
        sourceId: 'osm',
        z: 12,
        x: 2282,
        y: 1441,
        url: url,
        client: clientReturning([9, 9, 9]),
      );

      expect(bytes, [9, 9, 9]);
      expect((await cache.read('osm', 12, 2282, 1441))!.bytes, [9, 9, 9]);
    });

    test('a fresh cached tile skips the network entirely', () async {
      await cache.write('osm', 12, 2282, 1441, [1, 1, 1]);

      final bytes = await loadTileBytes(
        cache: cache,
        sourceId: 'osm',
        z: 12,
        x: 2282,
        y: 1441,
        url: url,
        client: MockClient((_) async => fail('network must not be hit')),
      );
      expect(bytes, [1, 1, 1]);
    });

    test('a stale tile is refetched when the network works', () async {
      await cache.write('osm', 12, 2282, 1441, [1, 1, 1]);

      final bytes = await loadTileBytes(
        cache: cache,
        sourceId: 'osm',
        z: 12,
        x: 2282,
        y: 1441,
        url: url,
        client: clientReturning([2, 2, 2]),
        now: () => DateTime.now().add(const Duration(days: 8)),
      );
      expect(bytes, [2, 2, 2]);
      expect((await cache.read('osm', 12, 2282, 1441))!.bytes, [2, 2, 2]);
    });

    test('a stale tile is served when the network fails', () async {
      await cache.write('osm', 12, 2282, 1441, [1, 1, 1]);

      final bytes = await loadTileBytes(
        cache: cache,
        sourceId: 'osm',
        z: 12,
        x: 2282,
        y: 1441,
        url: url,
        client: failingClient(),
        now: () => DateTime.now().add(const Duration(days: 8)),
      );
      expect(bytes, [1, 1, 1]);
    });

    test('non-200 responses fall back to the stale tile', () async {
      await cache.write('osm', 12, 2282, 1441, [1, 1, 1]);

      final bytes = await loadTileBytes(
        cache: cache,
        sourceId: 'osm',
        z: 12,
        x: 2282,
        y: 1441,
        url: url,
        client: clientReturning([0], status: 503),
        now: () => DateTime.now().add(const Duration(days: 8)),
      );
      expect(bytes, [1, 1, 1]);
    });

    test('throws only with neither network nor cache', () async {
      await expectLater(
        loadTileBytes(
          cache: cache,
          sourceId: 'osm',
          z: 12,
          x: 2282,
          y: 1441,
          url: url,
          client: failingClient(),
        ),
        throwsA(isA<SocketException>()),
      );
    });

    test('passes the provider headers through to the request', () async {
      Map<String, String>? seen;
      await loadTileBytes(
        cache: cache,
        sourceId: 'osm',
        z: 1,
        x: 1,
        y: 1,
        url: url,
        client: MockClient((request) async {
          seen = request.headers;
          return http.Response.bytes(Uint8List.fromList([1]), 200);
        }),
        headers: {'User-Agent': 'speleoloc-test'},
      );
      expect(seen?['User-Agent'], 'speleoloc-test');
    });
  });
}
