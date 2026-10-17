import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/services/sync/sync_table_registry.dart';

/// The picture-to-track-point link is a synced table, so every path that can
/// remove one of its two parents has to remove the link *and* leave it a
/// tombstone of its own. Sync propagates deletes per uuid: a link without
/// one survives on the peer, pointing at a row that no longer exists, and
/// fails that peer's deferred-FK check on the next import.
void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late CaveTripService tripService;
  late Uuid caveUuid;
  late Uuid placeUuid;
  late Uuid authorUuid;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    initRootContainer(container);

    caveUuid = await container.read(caveRepositoryProvider).addCave('Cave');
    final placeRepo = container.read(cavePlaceRepositoryProvider);
    await placeRepo.addCavePlace(caveUuid, 'Chamber');
    placeUuid = (await placeRepo.findCavePlaceByTitle(
      caveUuid,
      'Chamber',
    ))!.uuid;
    tripService = container.read(caveTripServiceProvider);
    // created_by_user_uuid is a real FK, so the author has to be a row that
    // exists rather than any uuid.
    authorUuid = await container
        .read(currentUserServiceProvider)
        .currentOrSystem();
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<List<ChangeLogData>> tombstonesFor(String table) async =>
      (await db.select(db.changeLog).get())
          .where(
            (r) => r.entityTable == table && r.changeType == ChangeType.delete,
          )
          .toList();

  Future<Uuid> documentFile(String title) => db.insertDocumentationFile(
    companion: DocumentationFilesCompanion.insert(
      uuid: Uuid.v7(),
      title: title,
      fileName: '$title.jpg',
      fileSize: 10,
      fileType: 'photo',
    ),
  );

  /// A trip with one point that has one picture bound to it.
  Future<({Uuid trip, Uuid point, Uuid doc, Uuid link})> linkedPoint() async {
    final tripUuid = await tripService.startTrip(caveUuid, 'Trip');
    await tripService.stopTrip();
    final pointUuid = await tripService.addPointAt(
      tripUuid: tripUuid,
      cavePlaceUuid: placeUuid,
      at: DateTime(2026, 10, 13, 11, 0),
    );
    final docUuid = await documentFile('photo');
    final linkUuid = await db.linkDocumentToTripPoint(
      docUuid,
      pointUuid,
      authorUuid: authorUuid,
    );
    expect(await db.getTripPointDocumentLinks(pointUuid), hasLength(1));
    return (trip: tripUuid, point: pointUuid, doc: docUuid, link: linkUuid);
  }

  test('linking twice reuses the existing row', () async {
    final fixture = await linkedPoint();
    final again = await db.linkDocumentToTripPoint(
      fixture.doc,
      fixture.point,
      authorUuid: authorUuid,
    );
    expect(again, fixture.link);
    expect(await db.getTripPointDocumentLinks(fixture.point), hasLength(1));
  });

  test('deleting the point removes the link and tombstones it', () async {
    final fixture = await linkedPoint();

    await tripService.deletePoint(fixture.point);

    expect(
      await db.select(db.documentationFilesToCaveTripPoints).get(),
      isEmpty,
    );
    final tombstones = await tombstonesFor(
      'documentation_files_to_cave_trip_points',
    );
    expect(tombstones.map((t) => t.entityUuid), [fixture.link]);
    expect(
      await db.select(db.documentationFiles).get(),
      hasLength(1),
      reason: 'the picture itself outlives the point it was bound to',
    );
  });

  test('deleting the whole trip tombstones its point links too', () async {
    final fixture = await linkedPoint();

    await container
        .read(caveTripRepositoryProvider)
        .deleteCaveTrip(fixture.trip);

    expect(
      await db.select(db.documentationFilesToCaveTripPoints).get(),
      isEmpty,
    );
    expect(await db.getTripPoints(fixture.trip), isEmpty);
    expect(
      (await tombstonesFor(
        'documentation_files_to_cave_trip_points',
      )).map((t) => t.entityUuid),
      [fixture.link],
    );
    expect((await tombstonesFor('cave_trip_points')).map((t) => t.entityUuid), [
      fixture.point,
    ]);
  });

  test('deleting the document tombstones its point links too', () async {
    final fixture = await linkedPoint();

    await container
        .read(documentationRepositoryProvider)
        .deleteDocumentationFile(fixture.doc);

    expect(
      await db.select(db.documentationFilesToCaveTripPoints).get(),
      isEmpty,
    );
    expect(
      (await tombstonesFor(
        'documentation_files_to_cave_trip_points',
      )).map((t) => t.entityUuid),
      [fixture.link],
    );
    expect(
      await db.getTripPoints(fixture.trip),
      hasLength(1),
      reason: 'the point outlives the picture that was bound to it',
    );
  });

  group('reading a trip\'s point pictures', () {
    test('groups the documents by the point they are bound to', () async {
      final fixture = await linkedPoint();
      final second = await documentFile('second');
      await db.linkDocumentToTripPoint(
        second,
        fixture.point,
        authorUuid: authorUuid,
      );
      final otherPoint = await tripService.addPointAt(
        tripUuid: fixture.trip,
        cavePlaceUuid: placeUuid,
        at: DateTime(2026, 10, 13, 12, 0),
      );

      final byPoint = await container
          .read(caveTripRepositoryProvider)
          .getTripPointDocuments(fixture.trip);

      expect(byPoint.keys, [fixture.point]);
      expect(byPoint[fixture.point]!.map((d) => d.uuid), [fixture.doc, second]);
      expect(
        byPoint.containsKey(otherPoint),
        isFalse,
        reason: 'a point with no pictures is absent, not an empty list',
      );
    });

    test('leaves out the pictures of other trips', () async {
      final fixture = await linkedPoint();
      final otherTrip = await tripService.startTrip(caveUuid, 'Other');
      await tripService.stopTrip();

      final byPoint = await container
          .read(caveTripRepositoryProvider)
          .getTripPointDocuments(otherTrip);
      expect(byPoint, isEmpty);
      expect(fixture.link, isNotNull);
    });
  });

  test('the sync registry actually dumps a link row', () async {
    // A table missing from the registry never leaves the device, which for
    // a link table means peers keep the picture and the point but lose
    // which one belongs to which.
    final fixture = await linkedPoint();
    final handler = SyncTableRegistry(db).tables().firstWhere(
      (t) => t.name == 'documentation_files_to_cave_trip_points',
    );
    final rows = await handler.dump();
    expect(rows, hasLength(1));
    expect(rows.single['uuid'], isNotNull);
    expect(
      rows.single.keys,
      containsAll(<String>[
        'documentation_file_uuid',
        'cave_trip_point_uuid',
        'created_at',
      ]),
    );
    expect(fixture.link, isNotNull);
  });
}
