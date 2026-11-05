import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';

import 'sync_test_device.dart';

/// An import that holds back its deletions counts every row the merge would
/// remove — the records the archive deletes, what their deletion reaches on
/// this device, and a record merged into another — and leaves the database
/// as it was until it is imported again without holding them back.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  late SyncTestDevice a;
  late SyncTestDevice b;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('hold_back_');
    a = await SyncTestDevice.create();
    b = await SyncTestDevice.create();
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
    await tmp.delete(recursive: true);
  });

  Future<SyncImportHasDeletionsException> heldBack(
    SyncTestDevice d,
    File zip,
  ) async {
    try {
      await d.sync.importFromZip(zip.path, holdBackDeletions: true);
    } on SyncImportHasDeletionsException catch (e) {
      return e;
    }
    fail('the import did not hold back its deletions');
  }

  Future<int> count(SyncTestDevice d, String table) async =>
      (await d.db.customSelect('SELECT uuid FROM $table').get()).length;

  test('counts what a deletion reaches here, and changes nothing', () async {
    final cave = await a.caves.addCave('Invented Cave');
    await a.places.addCavePlace(cave, 'X');
    await a.sendTo(b, tmp, 'a0.zip');
    await tick();
    // Added on B only, before the deletion: it goes with the cave.
    await b.places.addCavePlace(cave, 'Y');
    await tick();
    await a.caves.deleteCave(cave);
    await tick();
    final zip = await a.export(tmp, 'a1.zip');
    final log = await count(b, 'change_log');

    final held = await heldBack(b, zip);

    expect(held.preview.deletesApplied, 3);
    expect(await b.uuidsOf('caves'), {cave});
    expect(await count(b, 'cave_places'), 2);
    expect(await count(b, 'change_log'), log);
    expect(await b.held.readAll(), isEmpty);

    final report = await b.sync.importFromZip(zip.path);
    expect(report.deletesApplied, 3);
    expect(await b.uuidsOf('caves'), isEmpty);
    expect(await count(b, 'cave_places'), 0);
  });

  test('counts a record merged into another, and moves nothing', () async {
    final cave = await a.caves.addCave('Invented Cave');
    await a.sendTo(b, tmp, 'a0.zip');
    await tick();
    final bHall = await b.caves.addCaveArea(cave, 'Hall');
    final aHall = await a.caves.addCaveArea(cave, 'Hall');
    final pillar = Uuid.v7();
    final now = DateTime.now().millisecondsSinceEpoch;
    await a.db
        .into(a.db.cavePlaces)
        .insert(
          CavePlacesCompanion.insert(
            uuid: pillar,
            title: 'Pillar',
            caveUuid: cave,
            caveAreaUuid: Value(aHall),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    await tick();
    await a.sendTo(b, tmp, 'a1.zip');
    await tick();
    await b.decisions.mergeIntoLocal((await b.decisions.decisions()).single);
    await tick();
    final zip = await b.export(tmp, 'b1.zip');

    final log = await count(a, 'change_log');

    final held = await heldBack(a, zip);

    expect(held.preview.deletesApplied, 1);
    expect(await a.uuidsOf('cave_areas'), {aHall});
    expect(
      (await a.places.findById(pillar))!.caveAreaUuid,
      aHall,
      reason: 'nothing moved while the deletion waits',
    );
    expect(await count(a, 'change_log'), log);

    final report = await a.sync.importFromZip(zip.path);
    expect(report.deletesApplied, 1);
    expect(await a.uuidsOf('cave_areas'), {bHall});
    expect((await a.places.findById(pillar))!.caveAreaUuid, bHall);
  });
}
