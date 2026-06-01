import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/place_code/batch/place_code_batch_runner.dart';
import 'package:speleoloc/services/place_code/batch/place_code_overwrite_policy.dart';
import 'package:speleoloc/services/place_code/place_code_service.dart';
import 'package:speleoloc/services/place_code/strategies/per_cave_sequential_strategy.dart';
import 'package:speleoloc/services/user_repository.dart';

/// A scripted prompt callback used by tests: pops one decision from
/// [answers] per invocation and records the prompts seen.
class _ScriptedPrompts {
  final List<OverwriteDecision> answers;
  final List<Map<String, Object?>> seen = [];

  _ScriptedPrompts(this.answers);

  OverwritePromptCallback get callback => ({
        required cavePlaceUuid,
        required field,
        required existing,
        required computed,
      }) async {
        seen.add({
          'place': cavePlaceUuid,
          'field': field,
          'existing': existing,
          'computed': computed,
        });
        if (answers.isEmpty) {
          throw StateError('Unexpected prompt for $field on $cavePlaceUuid');
        }
        return answers.removeAt(0);
      };
}

OverwritePromptCallback _failOnPrompt = ({
  required cavePlaceUuid,
  required field,
  required existing,
  required computed,
}) async {
  throw StateError('Unexpected prompt: $field $existing -> $computed');
};

void main() {
  late AppDatabase db;
  late CurrentUserService currentUser;
  late ChangeLogger logger;
  late CavePlaceRepository repo;
  late PlaceCodeService service;
  late PlaceCodeBatchRunner runner;
  late Uuid caveUuid;

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

  Future<Uuid> addPlace(
    String title, {
    String? pci,
    String? qcri,
    Uuid? cave,
    bool isMain = false,
  }) async {
    final id = Uuid.v7();
    await db.into(db.cavePlaces).insert(
          CavePlacesCompanion.insert(
            uuid: id,
            title: title,
            caveUuid: cave ?? caveUuid,
            placeCodeIdentifier: Value(pci),
            qrCodeResourceIdentifier: Value(qcri),
            isMainEntrance: Value(isMain ? 1 : 0),
          ),
        );
    return id;
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger loggerRef;
    final userRepo = UserRepository(db, () => loggerRef);
    currentUser = CurrentUserService(db, userRepo, ConfigurationRepository(db));
    await currentUser.initialize();
    loggerRef = ChangeLogger(db, currentUser);
    logger = loggerRef;
    repo = CavePlaceRepository(db, currentUser, logger);
    service = PlaceCodeService(db);
    runner = PlaceCodeBatchRunner(db, service, repo);

    // Use the simplest deterministic strategy for these tests.
    await writeConfig(
      ConfigKey.placeCodeStrategy,
      PerCaveSequentialStrategy.strategyId,
    );

    caveUuid = Uuid.v7();
    await db.into(db.caves).insert(
          CavesCompanion.insert(uuid: caveUuid, title: 'C'),
        );
  });

  tearDown(() async => db.close());

  Future<CavePlace> reload(Uuid id) async =>
      (db.select(db.cavePlaces)..where((cp) => cp.uuid.equalsValue(id)))
          .getSingle();

  test('per-cave scope writes PCI and QCRI to empty places (no prompts)',
      () async {
    final p1 = await addPlace('a');
    final p2 = await addPlace('b');

    final summary = await runner.run(
      scope: PerCaveScope(caveUuid),
      onPrompt: _failOnPrompt,
    );

    expect(summary.updated, 2);
    expect(summary.skipped, isEmpty);
    expect(summary.refused, isEmpty);
    expect(summary.aborted, isEmpty);
    expect(summary.cancelled, isFalse);

    final r1 = await reload(p1);
    final r2 = await reload(p2);
    expect(r1.placeCodeIdentifier, isNotNull);
    expect(r1.qrCodeResourceIdentifier, r1.placeCodeIdentifier); // mirror mode
    expect(r2.placeCodeIdentifier, isNotNull);
    expect(r2.placeCodeIdentifier, isNot(r1.placeCodeIdentifier));
  });

  test('"keep" decision on existing PCI does not overwrite', () async {
    final p1 = await addPlace('a', pci: 'KEEP-ME', qcri: 'KEEP-ME');

    final prompts = _ScriptedPrompts(
      [OverwriteDecision.keep, OverwriteDecision.keep],
    );
    final summary = await runner.run(
      scope: PerCaveScope(caveUuid),
      onPrompt: prompts.callback,
    );

    expect(prompts.seen.length, 2);
    expect(prompts.seen.first['field'], OverwriteField.pci);
    expect(prompts.seen.last['field'], OverwriteField.qcri);
    final r1 = await reload(p1);
    expect(r1.placeCodeIdentifier, 'KEEP-ME');
    expect(r1.qrCodeResourceIdentifier, 'KEEP-ME');
    expect(summary.refused, isNotEmpty);
    expect(summary.updated, 0);
  });

  test('"keepAll" decision applies to subsequent places of same field',
      () async {
    final p1 = await addPlace('a', pci: 'OLD1', qcri: 'OLD1');
    final p2 = await addPlace('b', pci: 'OLD2', qcri: 'OLD2');

    final prompts = _ScriptedPrompts([
      // First prompt: PCI on p1 → keepAll.
      OverwriteDecision.keepAll,
      // First prompt: QCRI on p1 → keepAll.
      OverwriteDecision.keepAll,
    ]);
    final summary = await runner.run(
      scope: PerCaveScope(caveUuid),
      onPrompt: prompts.callback,
    );

    // No further prompts for p2.
    expect(prompts.seen.length, 2);
    expect(summary.updated, 0);
    final r1 = await reload(p1);
    final r2 = await reload(p2);
    expect(r1.placeCodeIdentifier, 'OLD1');
    expect(r2.placeCodeIdentifier, 'OLD2');
    expect(r1.qrCodeResourceIdentifier, 'OLD1');
    expect(r2.qrCodeResourceIdentifier, 'OLD2');
  });

  test('"replaceAll" decision overwrites subsequent places without prompting',
      () async {
    final p1 = await addPlace('a', pci: 'OLD1', qcri: 'OLD1');
    final p2 = await addPlace('b', pci: 'OLD2', qcri: 'OLD2');

    final prompts = _ScriptedPrompts([
      // PCI prompt on p1 → replaceAll
      OverwriteDecision.replaceAll,
      // QCRI prompt on p1 → replaceAll
      OverwriteDecision.replaceAll,
    ]);
    final summary = await runner.run(
      scope: PerCaveScope(caveUuid),
      onPrompt: prompts.callback,
    );

    expect(prompts.seen.length, 2);
    expect(summary.updated, 2);
    final r1 = await reload(p1);
    final r2 = await reload(p2);
    expect(r1.placeCodeIdentifier, isNot('OLD1'));
    expect(r2.placeCodeIdentifier, isNot('OLD2'));
    // Mirror mode → QCRI follows PCI.
    expect(r1.qrCodeResourceIdentifier, r1.placeCodeIdentifier);
    expect(r2.qrCodeResourceIdentifier, r2.placeCodeIdentifier);
  });

  test('"cancelBatch" stops the run mid-way', () async {
    final p1 = await addPlace('a', pci: 'OLD1', qcri: 'OLD1');
    await addPlace('b', pci: 'OLD2', qcri: 'OLD2');

    final prompts = _ScriptedPrompts([OverwriteDecision.cancelBatch]);
    final summary = await runner.run(
      scope: PerCaveScope(caveUuid),
      onPrompt: prompts.callback,
    );

    expect(summary.cancelled, isTrue);
    expect(summary.updated, 0);
    final r1 = await reload(p1);
    expect(r1.placeCodeIdentifier, 'OLD1');
  });

  test('PerAreaScope only iterates caves of the surface area', () async {
    final areaA = Uuid.v7();
    final areaB = Uuid.v7();
    await db.into(db.surfaceAreas).insert(
          SurfaceAreasCompanion.insert(uuid: areaA, title: 'A'),
        );
    await db.into(db.surfaceAreas).insert(
          SurfaceAreasCompanion.insert(uuid: areaB, title: 'B'),
        );
    final caveA = Uuid.v7();
    final caveB = Uuid.v7();
    await db.into(db.caves).insert(CavesCompanion.insert(
        uuid: caveA, title: 'CA', surfaceAreaUuid: Value(areaA)));
    await db.into(db.caves).insert(CavesCompanion.insert(
        uuid: caveB, title: 'CB', surfaceAreaUuid: Value(areaB)));
    final pA = await addPlace('pa', cave: caveA);
    final pB = await addPlace('pb', cave: caveB);

    final summary = await runner.run(
      scope: PerAreaScope(areaA),
      onPrompt: _failOnPrompt,
    );

    expect(summary.updated, 1);
    final rA = await reload(pA);
    final rB = await reload(pB);
    expect(rA.placeCodeIdentifier, isNotNull);
    expect(rB.placeCodeIdentifier, isNull);
  });

  test('GlobalScope visits every cave place', () async {
    final cave2 = Uuid.v7();
    await db
        .into(db.caves)
        .insert(CavesCompanion.insert(uuid: cave2, title: 'C2'));
    await addPlace('a');
    await addPlace('b', cave: cave2);

    final summary = await runner.run(
      scope: const GlobalScope(),
      onPrompt: _failOnPrompt,
    );
    expect(summary.updated, 2);
  });

  test('strategy skip is recorded in summary.skipped', () async {
    // Switch to per_area_sequential — cave has no surface area, so the
    // strategy returns Skipped(caveMissingSurfaceArea).
    await writeConfig(
      ConfigKey.placeCodeStrategy,
      'per_area_sequential',
    );
    await addPlace('a');

    final summary = await runner.run(
      scope: PerCaveScope(caveUuid),
      onPrompt: _failOnPrompt,
    );
    expect(summary.updated, 0);
    expect(summary.skipped.length, 1);
    expect(summary.skipped.first.reason, 'caveMissingSurfaceArea');
  });

  test('writes update change_log for affected columns', () async {
    final p1 = await addPlace('a');
    await runner.run(
      scope: PerCaveScope(caveUuid),
      onPrompt: _failOnPrompt,
    );
    final logs = await (db.select(db.changeLog)
          ..where((c) => c.entityTable.equals('cave_places'))
          ..where((c) => c.entityUuid.equalsValue(p1)))
        .get();
    expect(logs, isNotEmpty);
    final fields = await (db.select(db.changeLogField)
          ..where((f) => f.changeUuid.isInValues(logs.map((l) => l.uuid))))
        .get();
    final names = fields.map((f) => f.fieldName).toSet();
    expect(
      names,
      containsAll(<String>{'place_code_identifier', 'qr_code_resource_identifier'}),
    );
  });
}
