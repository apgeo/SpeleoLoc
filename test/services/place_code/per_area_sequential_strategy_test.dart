import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/place_code/place_code_strategy.dart';
import 'package:speleoloc/services/place_code/strategies/per_area_sequential_strategy.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  Future<Uuid> addArea() async {
    final id = Uuid.v7();
    await db.into(db.surfaceAreas).insert(
          SurfaceAreasCompanion.insert(uuid: id, title: 'A-$id'),
        );
    return id;
  }

  Future<Uuid> addCave({Uuid? surfaceAreaUuid, String title = 'C'}) async {
    final id = Uuid.v7();
    await db.into(db.caves).insert(
          CavesCompanion.insert(
            uuid: id,
            title: '$title-$id',
            surfaceAreaUuid: Value(surfaceAreaUuid),
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

  test('generate increments across all caves in the same area', () async {
    final area = await addArea();
    final c1 = await addCave(surfaceAreaUuid: area);
    final c2 = await addCave(surfaceAreaUuid: area);
    await addPlace(c1, pci: '1');
    await addPlace(c2, pci: '2');

    final p = await addPlace(c2);
    final strat = PerAreaSequentialStrategy(db, const {});
    final r = await strat.generate(
      caveUuid: c2,
      cavePlaceUuid: p,
      isMainEntrance: false,
    );
    expect((r as PlaceCodeGenerationOk).pci, '3');
  });

  test('skips cave with no surface area on generate', () async {
    final c = await addCave();
    final p = await addPlace(c);
    final strat = PerAreaSequentialStrategy(db, const {});
    final r = await strat.generate(
      caveUuid: c,
      cavePlaceUuid: p,
      isMainEntrance: false,
    );
    expect(r, isA<PlaceCodeGenerationSkipped>());
    expect((r as PlaceCodeGenerationSkipped).reason,
        PlaceCodeSkipReason.caveMissingSurfaceArea);
  });

  test('validate detects duplicates across area but not across areas',
      () async {
    final area1 = await addArea();
    final area2 = await addArea();
    final c1 = await addCave(surfaceAreaUuid: area1);
    final c2 = await addCave(surfaceAreaUuid: area1);
    final c3 = await addCave(surfaceAreaUuid: area2);
    await addPlace(c1, pci: '7');
    final p2 = await addPlace(c2);
    final p3 = await addPlace(c3);

    final strat = PerAreaSequentialStrategy(db, const {});
    expect(
      await strat.validate('7', cavePlaceUuid: p2, caveUuid: c2),
      'place_code_error_duplicate_in_area',
    );
    // Same value in a different area is fine.
    expect(
      await strat.validate('7', cavePlaceUuid: p3, caveUuid: c3),
      isNull,
    );
  });
}
