import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/map/map_mbtiles_config.dart';

void main() {
  group('MapMbTilesConfig', () {
    test('defaults: auto-load on, unknown files are overlays', () {
      const config = MapMbTilesConfig();
      expect(config.autoLoad, isTrue);
      expect(config.roleOf('anything.mbtiles'), MbTilesRole.overlay);
    });

    test('fromJson(null) yields defaults', () {
      final config = MapMbTilesConfig.fromJson(null);
      expect(config.autoLoad, isTrue);
      expect(config.roles, isEmpty);
    });

    test('JSON round-trip preserves autoLoad and roles', () {
      const original = MapMbTilesConfig(
        autoLoad: false,
        roles: {
          'base.mbtiles': MbTilesRole.base,
          'over.mbtiles': MbTilesRole.overlay,
        },
      );
      final restored = MapMbTilesConfig.fromJson(original.toJson());
      expect(restored.autoLoad, isFalse);
      expect(restored.roleOf('base.mbtiles'), MbTilesRole.base);
      expect(restored.roleOf('over.mbtiles'), MbTilesRole.overlay);
    });

    test('unknown role strings decode as overlay', () {
      final config = MapMbTilesConfig.fromJson({
        'roles': {'weird.mbtiles': 'something-new'},
      });
      expect(config.roleOf('weird.mbtiles'), MbTilesRole.overlay);
    });

    test('withRole replaces a single file without touching the rest', () {
      const config = MapMbTilesConfig(
        roles: {'a.mbtiles': MbTilesRole.base},
      );
      final updated = config.withRole('b.mbtiles', MbTilesRole.base);
      expect(updated.roleOf('a.mbtiles'), MbTilesRole.base);
      expect(updated.roleOf('b.mbtiles'), MbTilesRole.base);
      expect(config.roleOf('b.mbtiles'), MbTilesRole.overlay);
    });
  });
}
