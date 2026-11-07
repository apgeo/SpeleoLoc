import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

import '../support/sync_assertions.dart';
import '../support/sync_device.dart';

/// A deletion holds whatever order two phones exchange archives in, stale
/// ones included: once both have seen everything, the record is gone on
/// both, unless the other phone edited it after the deletion, in which case
/// it stays on both.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUp(() async => tmp = await Directory.systemTemp.createTemp('orders_'));
  tearDown(() => tmp.delete(recursive: true));

  Future<void> playSeed(int seed) async {
    final random = Random(seed);
    final a = await SyncTestDevice.create();
    final b = await SyncTestDevice.create();
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    final cave = await a.caves.addCave('Invented Cave');
    await a.places.addCavePlace(cave, 'X');
    final x = await a.placeUuid(cave, 'X');
    await a.sendTo(b, tmp, 's${seed}_a0.zip');

    final fromA = <File>[];
    final fromB = <File>[];
    int? deletedAt;
    int? lastEditAt;
    final steps = <String>[];
    var n = 0;

    for (var step = 0; step < 10; step++) {
      await tick();
      switch (random.nextInt(6)) {
        case 0
            when deletedAt == null &&
                (await a.uuidsOf('cave_places')).contains(x):
          await a.places.deleteCavePlace(x);
          deletedAt = DateTime.now().millisecondsSinceEpoch;
          steps.add('A deletes');
        case 1:
          fromA.add(await a.export(tmp, 's${seed}_a${++n}.zip'));
          steps.add('A exports');
        case 2:
          fromB.add(await b.export(tmp, 's${seed}_b${++n}.zip'));
          steps.add('B exports');
        case 3 when fromB.isNotEmpty:
          final i = random.nextInt(fromB.length);
          await a.sync.importFromZip(fromB[i].path);
          steps.add('A imports B#$i');
        case 4 when fromA.isNotEmpty:
          final i = random.nextInt(fromA.length);
          await b.sync.importFromZip(fromA[i].path);
          steps.add('B imports A#$i');
        case 5 when (await b.uuidsOf('cave_places')).contains(x):
          await b.places.updateCavePlace(
            x,
            CavePlacesCompanion(description: Value('edit $step')),
          );
          lastEditAt = DateTime.now().millisecondsSinceEpoch;
          steps.add('B edits');
      }
    }
    await tick();
    for (final (from, to) in [(a, b), (b, a), (a, b)]) {
      await from.sendTo(to, tmp, 's${seed}_final_${++n}.zip');
    }

    final keptByEdit =
        deletedAt != null && lastEditAt != null && lastEditAt > deletedAt;
    final expected = deletedAt == null || keptByEdit ? {x} : <Uuid>{};
    final story = 'seed $seed: ${steps.join(', ')}';
    expect(await a.uuidsOf('cave_places'), expected, reason: story);
    expect(await b.uuidsOf('cave_places'), expected, reason: story);
    await expectConverged(a.db, b.db);
  }

  test('fifty random exchange orders end the same on both phones', () async {
    for (var seed = 0; seed < 50; seed++) {
      await playSeed(seed);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
