import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/place_code/place_code_service.dart';
import 'package:speleoloc/services/place_code/qcri_hasher.dart';
import 'package:speleoloc/services/place_code/strategies/global_hierarchical_strategy.dart';
import 'package:speleoloc/services/place_code/strategies/per_cave_sequential_strategy.dart';

void main() {
  late AppDatabase db;
  late PlaceCodeService service;

  Future<void> writeConfig(String key, String value) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.customStatement(
      'INSERT INTO configurations (title, value, created_at, updated_at) '
      'VALUES (?, ?, ?, ?) '
      'ON CONFLICT(title) DO UPDATE SET value = excluded.value, '
      'updated_at = excluded.updated_at',
      [key, value, now, now],
    );
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = PlaceCodeService(db);
  });

  tearDown(() async => db.close());

  test('defaults to GlobalHierarchical strategy', () async {
    final s = await service.activeStrategy();
    expect(s, isA<GlobalHierarchicalStrategy>());
  });

  test('switches strategy from configuration', () async {
    await writeConfig(
        ConfigKey.placeCodeStrategy, PerCaveSequentialStrategy.strategyId);
    final s = await service.activeStrategy();
    expect(s, isA<PerCaveSequentialStrategy>());
  });

  test('reads per-strategy config blob keyed by strategy id', () async {
    await writeConfig(
        ConfigKey.placeCodeStrategy, PerCaveSequentialStrategy.strategyId);
    await writeConfig(
      ConfigKey.placeCodeStrategyConfig,
      jsonEncode({
        PerCaveSequentialStrategy.strategyId: {
          PerCaveSequentialStrategy.kZeroPadWidth: 4,
        },
      }),
    );
    // Set up a cave + place to exercise the strategy.
    final caveUuid = Uuid.v7();
    await db.into(db.caves).insert(
          CavesCompanion.insert(uuid: caveUuid, title: 'C'),
        );
    final placeUuid = Uuid.v7();
    await db.into(db.cavePlaces).insert(
          CavePlacesCompanion.insert(
            uuid: placeUuid,
            title: 'P',
            caveUuid: caveUuid,
          ),
        );
    final pair = await service.generatePair(
      caveUuid: caveUuid,
      cavePlaceUuid: placeUuid,
      isMainEntrance: false,
    );
    expect(pair!.pci, '0001');
    expect(pair.qcri, '0001'); // mirror by default
  });

  test('mirror mode QCRI equals PCI', () async {
    final q = await service.computeQcri('foo', cavePlaceUuid: Uuid.v7());
    expect(q, 'foo');
  });

  test('hash mode QCRI is a base36 string of configured length', () async {
    await writeConfig(ConfigKey.qcriMode, 'hash');
    await writeConfig(
      ConfigKey.qcriHashConfig,
      jsonEncode({'length': 8}),
    );
    final q = await service.computeQcri('foo', cavePlaceUuid: Uuid.v7());
    expect(q.length, 8);
    expect(RegExp(r'^[0-9a-z]+$').hasMatch(q), isTrue);
    // Matches the hasher directly.
    expect(q, const QcriHasher().hash('foo', length: 8));
  });

  test('hash mode retries length+1 on collision', () async {
    await writeConfig(ConfigKey.qcriMode, 'hash');
    await writeConfig(ConfigKey.qcriHashConfig, jsonEncode({'length': 8}));

    // Pre-occupy the 8-char hash of 'collide' on a different cave place.
    final occupied = const QcriHasher().hash('collide', length: 8);
    final caveUuid = Uuid.v7();
    await db.into(db.caves).insert(
          CavesCompanion.insert(uuid: caveUuid, title: 'C'),
        );
    final occupier = Uuid.v7();
    await db.into(db.cavePlaces).insert(
          CavePlacesCompanion.insert(
            uuid: occupier,
            title: 'occupier',
            caveUuid: caveUuid,
            qrCodeResourceIdentifier: Value(occupied),
          ),
        );
    // Self-lookup should NOT count as collision.
    final selfQ = await service.computeQcri('collide', cavePlaceUuid: occupier);
    expect(selfQ, occupied);
    // A different cave place asking for the same PCI should get length 9.
    final other = Uuid.v7();
    final q = await service.computeQcri('collide', cavePlaceUuid: other);
    expect(q.length, 9);
    expect(q.startsWith(occupied), isTrue);
  });

  group('applyPciToCompanion', () {
    test('passes companion through unchanged when PCI is absent', () async {
      const c = CavePlacesCompanion(title: Value('t'));
      final out =
          await service.applyPciToCompanion(c, cavePlaceUuid: Uuid.v7());
      expect(out.qrCodeResourceIdentifier.present, isFalse);
      expect(out.title.value, 't');
    });

    test('clears QCRI to null when PCI is explicitly null/empty', () async {
      const c1 = CavePlacesCompanion(placeCodeIdentifier: Value(null));
      final out1 =
          await service.applyPciToCompanion(c1, cavePlaceUuid: Uuid.v7());
      expect(out1.qrCodeResourceIdentifier.present, isTrue);
      expect(out1.qrCodeResourceIdentifier.value, isNull);

      const c2 = CavePlacesCompanion(placeCodeIdentifier: Value(''));
      final out2 =
          await service.applyPciToCompanion(c2, cavePlaceUuid: Uuid.v7());
      expect(out2.qrCodeResourceIdentifier.present, isTrue);
      expect(out2.qrCodeResourceIdentifier.value, isNull);
    });

    test('fills QCRI in mirror mode (default)', () async {
      const c = CavePlacesCompanion(placeCodeIdentifier: Value('ABC123'));
      final out =
          await service.applyPciToCompanion(c, cavePlaceUuid: Uuid.v7());
      expect(out.placeCodeIdentifier.value, 'ABC123');
      expect(out.qrCodeResourceIdentifier.value, 'ABC123');
    });

    test('fills QCRI in hash mode', () async {
      await writeConfig(ConfigKey.qcriMode, 'hash');
      await writeConfig(ConfigKey.qcriHashConfig, jsonEncode({'length': 8}));
      const c = CavePlacesCompanion(placeCodeIdentifier: Value('foo'));
      final out =
          await service.applyPciToCompanion(c, cavePlaceUuid: Uuid.v7());
      expect(out.qrCodeResourceIdentifier.value!.length, 8);
      expect(
        out.qrCodeResourceIdentifier.value,
        const QcriHasher().hash('foo', length: 8),
      );
    });
  });
}
