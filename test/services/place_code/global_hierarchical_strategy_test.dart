import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/place_code/place_code_strategy.dart';
import 'package:speleoloc/services/place_code/strategies/global_hierarchical_strategy.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  Future<Uuid> addArea({String? identifier}) async {
    final id = Uuid.v7();
    await db.into(db.surfaceAreas).insert(
          SurfaceAreasCompanion.insert(
            uuid: id,
            title: 'A-$id',
            generalAreaIdentifier: Value(identifier),
          ),
        );
    return id;
  }

  Future<Uuid> addCave({Uuid? surfaceAreaUuid, String? localIndex}) async {
    final id = Uuid.v7();
    await db.into(db.caves).insert(
          CavesCompanion.insert(
            uuid: id,
            title: 'C-$id',
            surfaceAreaUuid: Value(surfaceAreaUuid),
            caveLocalIndex: Value(localIndex),
          ),
        );
    return id;
  }

  Future<Uuid> addPlace(Uuid caveUuid, {String? pci}) async {
    final id = Uuid.v7();
    await db.into(db.cavePlaces).insert(
          CavePlacesCompanion.insert(
            uuid: id,
            title: 'P-$id',
            caveUuid: caveUuid,
            placeCodeIdentifier: Value(pci),
          ),
        );
    return id;
  }

  Map<String, dynamic> goodConfig() => {
        GlobalHierarchicalStrategy.kCountryCode: '881',
        GlobalHierarchicalStrategy.kCountryCodeWidth: 3,
        GlobalHierarchicalStrategy.kOrganizationCode: '028',
        GlobalHierarchicalStrategy.kOrganizationCodeWidth: 3,
        GlobalHierarchicalStrategy.kAreaIdentifierWidth: 3,
        GlobalHierarchicalStrategy.kCaveLocalIndexWidth: 3,
        GlobalHierarchicalStrategy.kCavePlaceLocalIndexWidth: 4,
        GlobalHierarchicalStrategy.kAllowNonDigit: false,
        GlobalHierarchicalStrategy.kMainEntranceSuffix: '0001',
        GlobalHierarchicalStrategy.kSegmentSeparator: '',
      };

  test('aborts when country/organization code is missing', () async {
    final cave = await addCave();
    final p = await addPlace(cave);
    final strat = GlobalHierarchicalStrategy(db, const {});
    final r = await strat.generate(
      caveUuid: cave,
      cavePlaceUuid: p,
      isMainEntrance: false,
    );
    expect(r, isA<PlaceCodeGenerationAborted>());
    expect((r as PlaceCodeGenerationAborted).reason,
        PlaceCodeAbortReason.missingDatasetConfig);
  });

  test('uses zeros area segment (Fallback) when cave has no surface area',
      () async {
    final cave = await addCave();
    final p = await addPlace(cave);
    final strat = GlobalHierarchicalStrategy(db, goodConfig());
    final r = await strat.generate(
      caveUuid: cave,
      cavePlaceUuid: p,
      isMainEntrance: false,
    );
    expect(r, isA<PlaceCodeGenerationFallback>());
    final fb = r as PlaceCodeGenerationFallback;
    expect(fb.fallback, FallbackReason.noSurfaceArea);
    // PCI contains '000' as the area segment (default areaIdentifierWidth=3).
    expect(fb.pci, startsWith('881028000'));
  });

  test(
      'uses nines area segment (Fallback) when surface area has no general_area_identifier',
      () async {
    final area = await addArea();
    final cave = await addCave(surfaceAreaUuid: area);
    final p = await addPlace(cave);
    final strat = GlobalHierarchicalStrategy(db, goodConfig());
    final r = await strat.generate(
      caveUuid: cave,
      cavePlaceUuid: p,
      isMainEntrance: false,
    );
    expect(r, isA<PlaceCodeGenerationFallback>());
    final fb = r as PlaceCodeGenerationFallback;
    expect(fb.fallback, FallbackReason.noIdentifier);
    // PCI contains '999' as the area segment (default areaIdentifierWidth=3).
    expect(fb.pci, startsWith('881028999'));
  });

  test('first place gets baseline + main_entrance_suffix when is_main_entrance',
      () async {
    final area = await addArea(identifier: '2048');
    final cave = await addCave(surfaceAreaUuid: area);
    final p = await addPlace(cave);
    final strat = GlobalHierarchicalStrategy(db, goodConfig());
    final r = await strat.generate(
      caveUuid: cave,
      cavePlaceUuid: p,
      isMainEntrance: true,
    );
    expect((r as PlaceCodeGenerationOk).pci, '88102820480010001');
    // Cave local index was persisted.
    final caveRow = await (db.select(db.caves)
          ..where((c) => c.uuid.equalsValue(cave)))
        .getSingle();
    expect(caveRow.caveLocalIndex, '001');
  });

  test('non-main places skip the reserved main_entrance_suffix', () async {
    final area = await addArea(identifier: '2048');
    final cave = await addCave(surfaceAreaUuid: area, localIndex: '001');
    final p = await addPlace(cave);
    final strat = GlobalHierarchicalStrategy(db, goodConfig());
    final r = await strat.generate(
      caveUuid: cave,
      cavePlaceUuid: p,
      isMainEntrance: false,
    );
    // 0001 is reserved → first available is 0002.
    expect((r as PlaceCodeGenerationOk).pci, '88102820480010002');
  });

  test('allocates next cave_local_index per area scope', () async {
    final area = await addArea(identifier: '2048');
    final cave1 = await addCave(surfaceAreaUuid: area, localIndex: '001');
    final cave2 = await addCave(surfaceAreaUuid: area);
    final p = await addPlace(cave2);
    final strat = GlobalHierarchicalStrategy(db, goodConfig());
    final r = await strat.generate(
      caveUuid: cave2,
      cavePlaceUuid: p,
      isMainEntrance: false,
    );
    expect((r as PlaceCodeGenerationOk).pci.substring(10, 13), '002');
    final cave2Row = await (db.select(db.caves)
          ..where((c) => c.uuid.equalsValue(cave2)))
        .getSingle();
    expect(cave2Row.caveLocalIndex, '002');
    // cave1's index unchanged.
    final cave1Row = await (db.select(db.caves)
          ..where((c) => c.uuid.equalsValue(cave1)))
        .getSingle();
    expect(cave1Row.caveLocalIndex, '001');
  });

  test('validate rejects non-digit when allow_non_digit=false', () async {
    final area = await addArea(identifier: '2048');
    final cave = await addCave(surfaceAreaUuid: area, localIndex: '001');
    final p = await addPlace(cave);
    final strat = GlobalHierarchicalStrategy(db, goodConfig());
    expect(
      await strat.validate('8810282048001000A',
          cavePlaceUuid: p, caveUuid: cave),
      anyOf(
        'place_code_error_must_be_digits',
        'place_code_warning_baseline_mismatch',
      ),
    );
  });

  test('validate accepts a code matching layout+baseline+unique', () async {
    final area = await addArea(identifier: '2048');
    final cave = await addCave(surfaceAreaUuid: area, localIndex: '001');
    final p = await addPlace(cave);
    final strat = GlobalHierarchicalStrategy(db, goodConfig());
    expect(
      await strat.validate('88102820480010005',
          cavePlaceUuid: p, caveUuid: cave),
      isNull,
    );
  });

  test('validate rejects globally duplicate PCIs', () async {
    final area = await addArea(identifier: '2048');
    final cave = await addCave(surfaceAreaUuid: area, localIndex: '001');
    await addPlace(cave, pci: '88102820480010005');
    final p2 = await addPlace(cave);
    final strat = GlobalHierarchicalStrategy(db, goodConfig());
    expect(
      await strat.validate('88102820480010005',
          cavePlaceUuid: p2, caveUuid: cave),
      'place_code_error_not_unique',
    );
  });
}
