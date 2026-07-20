import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/cave_place_qr_generator.dart';

CavePlace _place(Uuid caveUuid, {String title = 'P'}) => CavePlace(
  uuid: Uuid.v7(),
  title: title,
  caveUuid: caveUuid,
  isEntrance: 0,
  isMainEntrance: 0,
);

void main() {
  group('GenerationPreferences.caveTitleFor', () {
    final caveA = Uuid.v7();
    final caveB = Uuid.v7();

    test('resolves each place to its own cave title from the map', () {
      // The multi-cave batch case: two places from different caves must
      // resolve @cave_title to their respective owning caves.
      final prefs = GenerationPreferences(
        caveTitle: 'Fallback',
        caveTitleByCaveUuid: {caveA: 'Cave A', caveB: 'Cave B'},
      );
      expect(prefs.caveTitleFor(_place(caveA)), 'Cave A');
      expect(prefs.caveTitleFor(_place(caveB)), 'Cave B');
    });

    test('falls back to the single caveTitle when the cave is absent', () {
      final prefs = GenerationPreferences(
        caveTitle: 'Fallback',
        caveTitleByCaveUuid: {caveA: 'Cave A'},
      );
      expect(prefs.caveTitleFor(_place(caveB)), 'Fallback');
    });

    test('falls back to the single caveTitle when no map is provided', () {
      const prefs = GenerationPreferences(caveTitle: 'Only');
      expect(prefs.caveTitleFor(_place(caveA)), 'Only');
    });
  });
}
