import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/map/tile_layer_sources.dart';

void main() {
  group('builtInTileSources', () {
    test('ids are unique', () {
      final ids = builtInTileSources.map((s) => s.id).toSet();
      expect(ids.length, builtInTileSources.length);
    });

    test('every template contains x/y/z placeholders', () {
      for (final source in builtInTileSources) {
        expect(source.urlTemplate, contains('{x}'), reason: source.id);
        expect(source.urlTemplate, contains('{y}'), reason: source.id);
        expect(source.urlTemplate, contains('{z}'), reason: source.id);
      }
    });

    test('templates using {s} declare subdomains and vice versa', () {
      for (final source in builtInTileSources) {
        expect(
          source.urlTemplate.contains('{s}'),
          source.subdomains.isNotEmpty,
          reason: source.id,
        );
      }
    });

    test('the default source exists and lookup falls back to null', () {
      expect(findTileSourceById(builtInTileSourcesDefaultId), isNotNull);
      expect(findTileSourceById('no_such_source'), isNull);
    });
  });
}
