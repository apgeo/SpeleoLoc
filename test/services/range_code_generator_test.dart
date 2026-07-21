import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/place_code/place_code_service.dart';
import 'package:speleoloc/services/range_code_generator.dart';

void main() {
  late AppDatabase db;
  late RangeCodeGenerator generator;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    generator = RangeCodeGenerator(db, PlaceCodeService(db));
  });

  tearDown(() => db.close());

  Future<void> writeConfig(String key, String value) async {
    await db.customStatement(
      'INSERT INTO configurations (title, value, created_at, updated_at) '
      'VALUES (?, ?, 0, 0) '
      'ON CONFLICT(title) DO UPDATE SET value = excluded.value',
      [key, value],
    );
  }

  /// Configure the hierarchical strategy with the given dataset codes.
  Future<void> configureHierarchical({
    String country = '04',
    String org = '15',
    Map<String, dynamic> extra = const {},
  }) async {
    await writeConfig('place_code_strategy', 'global_hierarchical');
    await writeConfig(
      'place_code_strategy_config',
      jsonEncode({
        'global_hierarchical': {
          'country_code': country,
          'organization_code': org,
          ...extra,
        },
      }),
    );
  }

  Future<SurfaceArea> insertArea({
    required String title,
    String? identifier,
  }) async {
    final id = Uuid.v7();
    await db
        .into(db.surfaceAreas)
        .insert(
          SurfaceAreasCompanion.insert(
            uuid: id,
            title: title,
            generalAreaIdentifier: Value(identifier),
          ),
        );
    return (db.select(db.surfaceAreas)
          ..where((a) => a.uuid.equalsValue(id)))
        .getSingle();
  }

  Future<Cave> insertCave({
    Uuid? areaUuid,
    String? localIndex,
    String title = 'Cave',
  }) async {
    final id = Uuid.v7();
    await db
        .into(db.caves)
        .insert(
          CavesCompanion.insert(
            uuid: id,
            title: '$title-${localIndex ?? id}',
            surfaceAreaUuid: Value(areaUuid),
            caveLocalIndex: Value(localIndex),
          ),
        );
    return (db.select(db.caves)..where((c) => c.uuid.equalsValue(id)))
        .getSingle();
  }

  Future<void> insertCavePlace({required Uuid caveUuid, String? pci}) async {
    await db
        .into(db.cavePlaces)
        .insert(
          CavePlacesCompanion.insert(
            uuid: Uuid.v7(),
            title: 'P-${Uuid.v7()}',
            caveUuid: caveUuid,
            placeCodeIdentifier: Value(pci),
          ),
        );
  }

  group('generateAreaEntranceCodes', () {
    test('composes main-entrance codes for the whole range when empty', () async {
      await configureHierarchical();
      final area = await insertArea(title: 'Padis', identifier: '015');

      final result = await generator.generateAreaEntranceCodes(
        area: area,
        start: 1,
        end: 3,
      );

      expect(result.status, RangeCodeStatus.ok);
      expect(result.skipped, 0);
      expect(
        result.places.map((p) => p.placeCodeIdentifier),
        ['04150150010001', '04150150020001', '04150150030001'],
      );
      // Mirror mode: QCRI == PCI, and rows are flagged as main entrances.
      for (final place in result.places) {
        expect(place.qrCodeResourceIdentifier, place.placeCodeIdentifier);
        expect(place.title, place.placeCodeIdentifier);
        expect(place.isEntrance, 1);
        expect(place.isMainEntrance, 1);
      }
    });

    test('skips cave local indices already used in the area', () async {
      await configureHierarchical();
      final area = await insertArea(title: 'Padis', identifier: '015');
      await insertCave(areaUuid: area.uuid, localIndex: '002');

      final result = await generator.generateAreaEntranceCodes(
        area: area,
        start: 1,
        end: 3,
      );

      expect(result.status, RangeCodeStatus.ok);
      expect(result.skipped, 1);
      expect(
        result.places.map((p) => p.placeCodeIdentifier),
        ['04150150010001', '04150150030001'],
      );
    });

    test('skips indices used in another area sharing the identifier', () async {
      await configureHierarchical();
      final areaA = await insertArea(title: 'Padis', identifier: '015');
      final areaB = await insertArea(title: 'Cetatile', identifier: '015');
      await insertCave(areaUuid: areaB.uuid, localIndex: '002');

      final result = await generator.generateAreaEntranceCodes(
        area: areaA,
        start: 1,
        end: 3,
      );

      // Same area segment '015' → shared code space → index 2 is taken.
      expect(result.skipped, 1);
      expect(
        result.places.map((p) => p.placeCodeIdentifier),
        ['04150150010001', '04150150030001'],
      );
    });

    test('returns empty when every index is already recorded', () async {
      await configureHierarchical();
      final area = await insertArea(title: 'Padis', identifier: '015');
      await insertCave(areaUuid: area.uuid, localIndex: '001');
      await insertCave(areaUuid: area.uuid, localIndex: '002');

      final result = await generator.generateAreaEntranceCodes(
        area: area,
        start: 1,
        end: 2,
      );

      expect(result.status, RangeCodeStatus.empty);
      expect(result.places, isEmpty);
      expect(result.skipped, 2);
    });

    test('empty main-entrance suffix falls back to the first place index', () async {
      // With no reserved suffix, generate() gives a main entrance the first
      // allocated place index; the pre-generated code must match that, not a
      // baseline with a missing/empty place segment.
      await configureHierarchical(extra: {'main_entrance_suffix': ''});
      final area = await insertArea(title: 'Padis', identifier: '015');

      final result = await generator.generateAreaEntranceCodes(
        area: area,
        start: 1,
        end: 1,
      );

      expect(result.places.single.placeCodeIdentifier, '04150150010001');
    });

    test('reports missing dataset config when country code is empty', () async {
      await configureHierarchical(country: '');
      final area = await insertArea(title: 'Padis', identifier: '015');

      final result = await generator.generateAreaEntranceCodes(
        area: area,
        start: 1,
        end: 3,
      );

      expect(result.status, RangeCodeStatus.missingDatasetConfig);
      expect(result.places, isEmpty);
    });

    test('reports unsupported strategy for a non-hierarchical strategy', () async {
      await configureHierarchical();
      await writeConfig('place_code_strategy', 'per_cave_sequential');
      final area = await insertArea(title: 'Padis', identifier: '015');

      final result = await generator.generateAreaEntranceCodes(
        area: area,
        start: 1,
        end: 3,
      );

      expect(result.status, RangeCodeStatus.unsupportedStrategy);
    });
  });

  group('generateCavePlaceCodes', () {
    test('composes place codes across the range', () async {
      await configureHierarchical();
      final area = await insertArea(title: 'Padis', identifier: '015');
      final cave = await insertCave(areaUuid: area.uuid, localIndex: '005');

      final result = await generator.generateCavePlaceCodes(
        cave: cave,
        start: 2,
        end: 4,
      );

      expect(result.status, RangeCodeStatus.ok);
      expect(
        result.places.map((p) => p.placeCodeIdentifier),
        ['04150150050002', '04150150050003', '04150150050004'],
      );
      for (final place in result.places) {
        expect(place.caveUuid, cave.uuid);
        expect(place.qrCodeResourceIdentifier, place.placeCodeIdentifier);
        expect(place.isEntrance, 0);
        expect(place.isMainEntrance, 0);
      }
    });

    test('skips the reserved main-entrance index', () async {
      await configureHierarchical();
      final area = await insertArea(title: 'Padis', identifier: '015');
      final cave = await insertCave(areaUuid: area.uuid, localIndex: '005');

      final result = await generator.generateCavePlaceCodes(
        cave: cave,
        start: 1,
        end: 3,
      );

      // Index 1 == int('0001') is reserved for the main entrance.
      expect(result.skipped, 1);
      expect(
        result.places.map((p) => p.placeCodeIdentifier),
        ['04150150050002', '04150150050003'],
      );
    });

    test('skips place codes already recorded on the cave', () async {
      await configureHierarchical();
      final area = await insertArea(title: 'Padis', identifier: '015');
      final cave = await insertCave(areaUuid: area.uuid, localIndex: '005');
      await insertCavePlace(caveUuid: cave.uuid, pci: '04150150050003');

      final result = await generator.generateCavePlaceCodes(
        cave: cave,
        start: 2,
        end: 4,
      );

      expect(result.skipped, 1);
      expect(
        result.places.map((p) => p.placeCodeIdentifier),
        ['04150150050002', '04150150050004'],
      );
    });

    test('reports missing cave index when the cave has none', () async {
      await configureHierarchical();
      final area = await insertArea(title: 'Padis', identifier: '015');
      final cave = await insertCave(areaUuid: area.uuid, localIndex: null);

      final result = await generator.generateCavePlaceCodes(
        cave: cave,
        start: 2,
        end: 4,
      );

      expect(result.status, RangeCodeStatus.missingCaveIndex);
      expect(result.places, isEmpty);
    });

    test('hash mode yields a QCRI distinct from the PCI', () async {
      await configureHierarchical();
      await writeConfig('qcri_mode', 'hash');
      final area = await insertArea(title: 'Padis', identifier: '015');
      final cave = await insertCave(areaUuid: area.uuid, localIndex: '005');

      final result = await generator.generateCavePlaceCodes(
        cave: cave,
        start: 2,
        end: 2,
      );

      final place = result.places.single;
      expect(place.placeCodeIdentifier, '04150150050002');
      expect(place.qrCodeResourceIdentifier, isNotNull);
      expect(place.qrCodeResourceIdentifier, isNot(place.placeCodeIdentifier));
    });
  });
}
