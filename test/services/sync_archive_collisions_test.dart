import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/sync/archive_sync_decision.dart';
import 'package:speleoloc/services/sync/archive_sync_decision_errors.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/sync/sync_merge_engine.dart';

import 'sync_test_device.dart';

/// Two phones each create a record with the same unique name — cave area
/// "Hall" in a shared cave, place "Siphon" outside any area. The import
/// commits everything else, holds the incoming record with whatever hangs on
/// it, and waits for a person to merge it, keep both, or discard it; each
/// choice reaches the other phone as ordinary changes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  late SyncTestDevice a;
  late SyncTestDevice b;
  late Uuid cave;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('collisions_');
    a = await SyncTestDevice.create();
    b = await SyncTestDevice.create();
    cave = await a.caves.addCave('Shared Cave');
    await a.sendTo(b, tmp, 'a0.zip');
    await tick();
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
    await tmp.delete(recursive: true);
  });

  Future<Uuid> placeIn(SyncTestDevice d, String title, Uuid area) async {
    final id = Uuid.v7();
    final now = DateTime.now().millisecondsSinceEpoch;
    await d.db
        .into(d.db.cavePlaces)
        .insert(
          CavePlacesCompanion.insert(
            uuid: id,
            title: title,
            caveUuid: cave,
            caveAreaUuid: Value(area),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return id;
  }

  Future<String?> areaOf(SyncTestDevice d, Uuid place) async =>
      (await (d.db.select(
            d.db.cavePlaces,
          )..where((p) => p.uuid.equalsValue(place))).getSingleOrNull())
          ?.caveAreaUuid
          ?.toString();

  Future<ArchiveSyncDecision> onlyDecision(SyncTestDevice d) async =>
      (await d.decisions.decisions()).single;

  group('the import', () {
    test('commits all but the colliding area and what is inside it', () async {
      final bHall = await b.caves.addCaveArea(cave, 'Hall');
      final aHall = await a.caves.addCaveArea(cave, 'Hall');
      final before = await a.caves.addCave('Merged Before');
      await a.places.addCavePlace(cave, 'Merged After');
      final inside = await placeIn(a, 'Inside A Hall', aHall);
      await tick();

      final report = await a.sendTo(b, tmp, 'a1.zip');

      expect(await b.uuidsOf('caves'), containsAll(<Uuid>[cave, before]));
      expect(await b.uuidsOf('cave_areas'), {bHall});
      expect(await b.uuidsOf('cave_places'), {
        await a.placeUuid(cave, 'Merged After'),
      });
      expect(report.decisionsPending, 1);
      final decision = await onlyDecision(b);
      expect(decision.root.uuid, aHall);
      expect(decision.root.collidesWith, bHall);
      expect(decision.isEdit, isFalse);
      expect(decision.title, 'Hall');
      expect(decision.localTitle, 'Hall');
      expect(decision.caveTitle, 'Shared Cave');
      expect(decision.canKeepBoth, isTrue);
      expect(decision.waiting.map((w) => w.uuid), [inside]);
    });

    test('holds a place named like one here with the visit recorded at it, '
        'and brings the trip', () async {
      await a.places.addCavePlace(cave, 'Siphon');
      await b.places.addCavePlace(cave, 'Siphon');
      final pB = await b.placeUuid(cave, 'Siphon');
      final trip = await b.db.insertCaveTrip(
        caveUuid: cave,
        title: 'Invented trip B',
        startedAt: DateTime.now().millisecondsSinceEpoch,
        authorUuid: b.author,
      );
      final point = await b.db.insertTripPoint(
        tripUuid: trip,
        cavePlaceUuid: pB,
        authorUuid: b.author,
      );
      await tick();

      final report = await b.sendTo(a, tmp, 'b1.zip');

      expect(await a.uuidsOf('cave_trips'), {trip});
      expect(await a.uuidsOf('cave_trip_points'), isEmpty);
      expect(report.decisionsPending, 1);
      final decision = await onlyDecision(a);
      expect(decision.root.uuid, pB);
      expect(decision.waiting.map((w) => w.uuid), [point]);
    });

    test('keeps what it holds across a restart and further imports, and lets '
        'it go once the source renames it', () async {
      await b.caves.addCaveArea(cave, 'Hall');
      final aHall = await a.caves.addCaveArea(cave, 'Hall');
      final inside = await placeIn(a, 'Pillar', aHall);
      await tick();
      await a.sendTo(b, tmp, 'a1.zip');

      // A fresh service on the same database, as after a restart.
      final restarted = SyncArchiveService(
        b.db,
        b.logger,
        assetsBaseDirResolver: () async => tmp,
      );
      final again = await restarted.importFromZip(
        (await a.export(tmp, 'a2.zip')).path,
      );
      expect(again.decisionsPending, 1);
      expect(await b.held.countDecisions(), 1);

      await tick();
      await a.caves.updateCaveAreaTitle(
        uuid: aHall,
        newTitle: 'Hall East',
        oldTitle: 'Hall',
      );
      await tick();
      final released = await a.sendTo(b, tmp, 'a3.zip');
      expect(released.decisionsPending, 0);
      expect(await b.uuidsOf('cave_areas'), contains(aHall));
      expect(await areaOf(b, inside), aHall.toString());
    });

    test('forgets a held record its source deletes, and brings in what the '
        'deletion left outside it', () async {
      final bHall = await b.caves.addCaveArea(cave, 'Hall');
      final aHall = await a.caves.addCaveArea(cave, 'Hall');
      final pillar = await placeIn(a, 'Pillar', aHall);
      await tick();
      await a.sendTo(b, tmp, 'a1.zip');

      await tick();
      final row = (await a.caves.findCaveAreaById(aHall))!;
      await a.caves.deleteCaveArea(row);
      await tick();
      final report = await a.sendTo(b, tmp, 'a2.zip');

      expect(report.decisionsPending, 0);
      expect(await b.held.readAll(), isEmpty);
      expect(await b.uuidsOf('cave_areas'), {bHall});
      expect(await b.uuidsOf('cave_places'), {pillar});
      expect(await areaOf(b, pillar), isNull);
    });
  });

  group('a decision', () {
    late Uuid aHall;
    late Uuid bHall;
    late Uuid inside;

    setUp(() async {
      bHall = await b.caves.addCaveArea(cave, 'Hall');
      aHall = await a.caves.addCaveArea(cave, 'Hall');
      inside = await placeIn(a, 'Pillar', aHall);
      await tick();
      await a.sendTo(b, tmp, 'a1.zip');
      await tick();
    });

    test('to merge moves what was inside onto the local record, on both '
        'phones', () async {
      await b.decisions.mergeIntoLocal(await onlyDecision(b));

      expect(await b.held.readAll(), isEmpty);
      expect(await b.uuidsOf('cave_areas'), {bHall});
      expect(await areaOf(b, inside), bHall.toString());

      await tick();
      final onA = await b.sendTo(a, tmp, 'b1.zip');
      expect(onA.decisionsPending, 0);
      expect(await a.uuidsOf('cave_areas'), {bHall});
      expect(await areaOf(a, inside), bHall.toString());
    });

    test(
      'to merge also moves what the other phone added inside meanwhile',
      () async {
        // A keeps working in its Hall before B decides.
        final later = await placeIn(a, 'Column', aHall);
        await tick();
        await b.decisions.mergeIntoLocal(await onlyDecision(b));
        await tick();

        await b.sendTo(a, tmp, 'b1.zip');
        expect(await a.uuidsOf('cave_areas'), {bHall});
        expect(await areaOf(a, later), bHall.toString());

        await tick();
        await a.sendTo(b, tmp, 'a2.zip');
        expect(await areaOf(b, later), bHall.toString());
        expect(await b.held.readAll(), isEmpty);
      },
    );

    test(
      'to keep both writes the incoming record renamed, on both phones',
      () async {
        await b.decisions.keepBoth(await onlyDecision(b), 'Hall West');

        expect(await b.uuidsOf('cave_areas'), {aHall, bHall});
        expect((await b.caves.findCaveAreaById(aHall))!.title, 'Hall West');
        expect(await areaOf(b, inside), aHall.toString());

        await tick();
        await b.sendTo(a, tmp, 'b1.zip');
        expect((await a.caves.findCaveAreaById(aHall))!.title, 'Hall West');
        expect(await a.uuidsOf('cave_areas'), {aHall, bHall});
      },
    );

    test(
      'to keep both under a name that is taken too changes nothing',
      () async {
        await b.caves.addCaveArea(cave, 'Hall West');
        final decision = await onlyDecision(b);
        final logBefore = (await b.db.select(b.db.changeLog).get()).length;

        await expectLater(
          b.decisions.keepBoth(decision, 'Hall West'),
          throwsA(isA<ArchiveSyncNameTakenException>()),
        );
        expect((await b.held.readAll()).map((h) => h.uuid), {aHall, inside});
        expect(await b.db.select(b.db.changeLog).get(), hasLength(logBefore));
      },
    );

    test('to discard removes the incoming record and what was inside it, on '
        'both phones', () async {
      await b.decisions.discard(await onlyDecision(b));

      expect(await b.held.readAll(), isEmpty);
      expect(await b.uuidsOf('cave_areas'), {bHall});

      await tick();
      await b.sendTo(a, tmp, 'b1.zip');
      expect(await a.uuidsOf('cave_areas'), {bHall});
      expect(await a.uuidsOf('cave_places'), isEmpty);
    });
  });

  group('an edit that would take a name held here', () {
    late Uuid x;
    late Uuid y;

    setUp(() async {
      x = await a.caves.addCaveArea(cave, 'Alpha');
      await a.sendTo(b, tmp, 'a1.zip');
      y = await b.caves.addCaveArea(cave, 'Beta');
      await tick();
      await a.caves.updateCaveAreaTitle(
        uuid: x,
        newTitle: 'Beta',
        oldTitle: 'Alpha',
      );
      await tick();
      await a.sendTo(b, tmp, 'a2.zip');
      await tick();
    });

    test('is held, and the local record keeps its name meanwhile', () async {
      final decision = await onlyDecision(b);
      expect(decision.isEdit, isTrue);
      expect(decision.root.uuid, x);
      expect(decision.root.collidesWith, y);
      expect((await b.caves.findCaveAreaById(x))!.title, 'Alpha');
    });

    test('discarded, leaves this phone\'s version standing on both', () async {
      await b.decisions.discard(await onlyDecision(b));
      expect(await b.held.readAll(), isEmpty);

      await tick();
      await b.sendTo(a, tmp, 'b1.zip');
      expect((await a.caves.findCaveAreaById(x))!.title, 'Alpha');
      expect((await b.caves.findCaveAreaById(x))!.title, 'Alpha');
    });

    test('merged, makes the two one record on both phones', () async {
      final place = await placeIn(b, 'Pillar', x);
      await b.decisions.mergeIntoLocal(await onlyDecision(b));
      expect(await b.uuidsOf('cave_areas'), {y});
      expect(await areaOf(b, place), y.toString());

      await tick();
      await b.sendTo(a, tmp, 'b1.zip');
      expect(await a.uuidsOf('cave_areas'), {y});
      expect(await areaOf(a, place), y.toString());
    });
  });

  test('the held rows can be merged again on their own', () async {
    final bHall = await b.caves.addCaveArea(cave, 'Hall');
    final aHall = await a.caves.addCaveArea(cave, 'Hall');
    await tick();
    await a.sendTo(b, tmp, 'a1.zip');

    // The caver renames their own area through the app; nothing is synced.
    await b.caves.updateCaveAreaTitle(
      uuid: bHall,
      newTitle: 'Upper Hall',
      oldTitle: 'Hall',
    );
    await SyncMergeEngine(b.db, b.logger, heldRows: b.held).merge();

    expect(await b.held.readAll(), isEmpty);
    expect(await b.uuidsOf('cave_areas'), {aHall, bHall});
  });
}
