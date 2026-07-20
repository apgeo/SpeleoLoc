import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/map/place_label_resolver.dart';

void main() {
  group('resolvePlaceLabel', () {
    test('sole entrance of a single-entrance cave shows the cave title', () {
      expect(
        resolvePlaceLabel(
          caveTitle: 'Pestera Mare',
          placeTitle: 'Intrare',
          isEntrance: true,
          caveEntranceCount: 1,
        ),
        'Pestera Mare',
      );
    });

    test('entrance of a multi-entrance cave shows cave - place', () {
      expect(
        resolvePlaceLabel(
          caveTitle: 'Pestera Mare',
          placeTitle: 'Intrare Est',
          isEntrance: true,
          caveEntranceCount: 3,
        ),
        'Pestera Mare - Intrare Est',
      );
    });

    test('non-entrance place shows cave - place even when the cave has a '
        'single entrance', () {
      expect(
        resolvePlaceLabel(
          caveTitle: 'Pestera Mare',
          placeTitle: 'Sala Alba',
          isEntrance: false,
          caveEntranceCount: 1,
        ),
        'Pestera Mare - Sala Alba',
      );
    });

    test('entrance with zero recorded entrances falls back to cave - place',
        () {
      expect(
        resolvePlaceLabel(
          caveTitle: 'C',
          placeTitle: 'P',
          isEntrance: true,
          caveEntranceCount: 0,
        ),
        'C - P',
      );
    });
  });
}
