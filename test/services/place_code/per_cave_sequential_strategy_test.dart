import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/place_code/place_code_strategy.dart';
import 'package:speleoloc/services/place_code/strategies/per_cave_sequential_strategy.dart';

void main() {
  late AppDatabase db;
  late Uuid caveUuid;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    caveUuid = Uuid.v7();
    await db.into(db.caves).insert(
          CavesCompanion.insert(uuid: caveUuid, title: 'C'),
        );
  });

  tearDown(() async => db.close());

  Future<Uuid> addPlace(String title, {String? pci}) async {
    final id = Uuid.v7();
    await db.into(db.cavePlaces).insert(
          CavePlacesCompanion.insert(
            uuid: id,
            title: title,
            caveUuid: caveUuid,
            placeCodeIdentifier: Value(pci),
          ),
        );
    return id;
  }

  test('generate starts at start_at and increments', () async {
    final strat = PerCaveSequentialStrategy(db, const {});
    final p1 = await addPlace('a');
    final r1 = await strat.generate(
      caveUuid: caveUuid,
      cavePlaceUuid: p1,
      isMainEntrance: false,
    );
    expect(r1, isA<PlaceCodeGenerationOk>());
    expect((r1 as PlaceCodeGenerationOk).pci, '1');

    await db.update(db.cavePlaces).replace(
          (await db.select(db.cavePlaces).get())
              .first
              .copyWith(placeCodeIdentifier: const Value('1')),
        );
    final p2 = await addPlace('b');
    final r2 = await strat.generate(
      caveUuid: caveUuid,
      cavePlaceUuid: p2,
      isMainEntrance: false,
    );
    expect((r2 as PlaceCodeGenerationOk).pci, '2');
  });

  test('zero_pad_width is honoured', () async {
    final strat = PerCaveSequentialStrategy(db, const {
      PerCaveSequentialStrategy.kZeroPadWidth: 4,
    });
    final p = await addPlace('x');
    final r = await strat.generate(
      caveUuid: caveUuid,
      cavePlaceUuid: p,
      isMainEntrance: false,
    );
    expect((r as PlaceCodeGenerationOk).pci, '0001');
  });

  test('main entrance reserves start_at when free', () async {
    final strat = PerCaveSequentialStrategy(db, const {});
    // Pre-populate a non-main place at 2 to ensure entrance still gets 1.
    await addPlace('other', pci: '2');
    final p = await addPlace('entrance');
    final r = await strat.generate(
      caveUuid: caveUuid,
      cavePlaceUuid: p,
      isMainEntrance: true,
    );
    expect((r as PlaceCodeGenerationOk).pci, '1');
  });

  test('validate rejects non-integer and duplicates', () async {
    final strat = PerCaveSequentialStrategy(db, const {});
    final p1 = await addPlace('a', pci: '5');
    final p2 = await addPlace('b');
    expect(
      await strat.validate('abc',
          cavePlaceUuid: p2, caveUuid: caveUuid),
      'place_code_error_must_be_integer',
    );
    expect(
      await strat.validate('5', cavePlaceUuid: p2, caveUuid: caveUuid),
      'place_code_error_duplicate_in_cave',
    );
    expect(
      await strat.validate('5', cavePlaceUuid: p1, caveUuid: caveUuid),
      isNull,
    );
    expect(
      await strat.validate('6', cavePlaceUuid: p2, caveUuid: caveUuid),
      isNull,
    );
  });
}
