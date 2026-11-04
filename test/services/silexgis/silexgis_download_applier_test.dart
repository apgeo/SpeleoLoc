import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/model/sync_download_page.dart';
import 'package:speleoloc/services/silexgis/model/sync_feature_row.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_download_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_builder.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/utils/clock.dart';

/// Applying a downloaded page: an import, not a user edit.
void main() {
  const profile = 'profile-a';
  const setId = 'set-1';

  late AppDatabase db;
  late ChangeLogger logger;
  late SilexgisLocalStateRepository localState;
  late SilexgisHeldRowRepository heldRows;
  late SilexgisDownloadApplier applier;

  final clock = FakeClock(DateTime.utc(2026, 9, 1, 12));

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger loggerRef;
    final users = UserRepository(db, () => loggerRef);
    final currentUser = CurrentUserService(
      db,
      users,
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    logger = loggerRef = ChangeLogger(db, currentUser, clock: clock);
    localState = SilexgisLocalStateRepository(db, clock: clock);
    heldRows = SilexgisHeldRowRepository(db, clock: clock);
    applier = SilexgisDownloadApplier(
      db: db,
      logger: logger,
      localState: localState,
      heldRows: heldRows,
      caves: CaveRepository(db, currentUser, logger, clock: clock),
      places: CavePlaceRepository(db, currentUser, logger, clock: clock),
      profileUuid: profile,
    );
  });
  tearDown(() => db.close());

  // ---------------------------------------------------------------- fixtures

  var nextRevision = 0;
  Map<String, Object?> feature({
    required String id,
    required String kind,
    String? featureTypeCode,
    String? name,
    String? description,
    String? parentId,
    List<double>? point,
    Map<String, Object?> properties = const <String, Object?>{},
    String? updatedAt,
  }) => <String, Object?>{
    'id': id,
    'kind': kind,
    'featureTypeCode': featureTypeCode,
    'name': name,
    'description': description,
    'properties': properties,
    'createdAt': '2026-08-01T00:00:00.000Z',
    'updatedAt': updatedAt ?? '2026-08-2${(nextRevision++) % 10}T09:00:00.000Z',
    'geometry': point == null
        ? null
        : <String, Object?>{'type': 'Point', 'coordinates': point},
    'parents': parentId == null
        ? const <Object?>[]
        : <Object?>[
            <String, Object?>{'parentId': parentId, 'isPrimary': true},
          ],
  };

  SyncDownloadPage page(
    List<Map<String, Object?>> features, {
    List<Map<String, Object?>> tombstones = const <Map<String, Object?>>[],
    String? cursor = 'cursor-1',
    int setRevision = 1,
    bool hasMore = false,
  }) => SyncDownloadPage.fromJson(<String, Object?>{
    'setRevision': setRevision,
    'settings': const <String, Object?>{},
    'features': features,
    'tombstones': tombstones,
    'nextCursor': cursor,
    'hasMore': hasMore,
  });

  final caveId = Uuid.v7();
  final areaId = Uuid.v7();
  final placeId = Uuid.v7();

  Map<String, Object?> aCave({String? parent}) => feature(
    id: caveId.toString(),
    kind: 'cave',
    name: 'Peștera Mică',
    description: 'A short cave.',
    parentId: parent,
    properties: const <String, Object?>{'speleolocCaveLocalIndex': 'C7'},
  );
  Map<String, Object?> aPlace({String? parent}) => feature(
    id: placeId.toString(),
    kind: 'generic',
    featureTypeCode: 'cave_place',
    name: 'Sala Mare',
    parentId: parent ?? caveId.toString(),
    point: <double>[25.441, 45.531, 1240],
    properties: const <String, Object?>{
      'speleolocPci': 'AB-0007',
      'speleolocDepthInCave': 137.5,
    },
  );

  // ------------------------------------------------------------------- tests

  group('an import, not a user edit', () {
    test('writes nothing to the change log', () async {
      // Logged, every downloaded row would look like local work: the FTP
      // upload gate would see it and the same rows would travel back out in
      // the next archive, with no user action anywhere in the loop.
      await applier.applyPage(
        page(<Map<String, Object?>>[aCave(), aPlace()]),
        setId: setId,
      );

      expect(await db.select(db.changeLog).get(), isEmpty);
      expect(await db.select(db.changeLogField).get(), isEmpty);
    });

    test('leaves the logger armed for the caver\'s next edit', () async {
      await applier.applyPage(
        page(<Map<String, Object?>>[aCave()]),
        setId: setId,
      );
      expect(logger.isSuspended, isFalse);
    });
  });

  group('rows', () {
    test('land in the local shapes the mapping names', () async {
      final report = await applier.applyPage(
        page(<Map<String, Object?>>[aCave(), aPlace()]),
        setId: setId,
      );
      expect(report.inserted, 2);

      final cave = await (db.select(
        db.caves,
      )..where((t) => t.uuid.equalsValue(caveId))).getSingle();
      expect(cave.title, 'Peștera Mică');
      expect(cave.description, 'A short cave.');
      expect(cave.caveLocalIndex, 'C7');

      final place = await (db.select(
        db.cavePlaces,
      )..where((t) => t.uuid.equalsValue(placeId))).getSingle();
      expect(place.caveUuid, caveId);
      expect(place.caveAreaUuid, isNull);
      expect(place.latitude, 45.531);
      expect(place.longitude, 25.441);
      // The only place an altitude comes back is the point's third ordinate.
      expect(place.altitude, 1240);
      expect(place.placeCodeIdentifier, 'AB-0007');
      expect(place.depthInCave, 137.5);
      expect(place.isEntrance, 0);
    });

    test('carry the server\'s stamp, not the moment of the import', () async {
      // Device-to-device merges are still last-writer-wins on this column.
      // Stamping "now" would make every downloaded row beat a peer's newer
      // edit in the next archive merge.
      await applier.applyPage(
        page(<Map<String, Object?>>[
          feature(
            id: caveId.toString(),
            kind: 'cave',
            name: 'C',
            updatedAt: '2026-08-28T09:14:52.113Z',
          ),
        ]),
        setId: setId,
      );
      final cave = await (db.select(
        db.caves,
      )..where((t) => t.uuid.equalsValue(caveId))).getSingle();
      expect(
        cave.updatedAt,
        DateTime.utc(2026, 8, 28, 9, 14, 52, 113).millisecondsSinceEpoch,
      );
      expect(cave.updatedAt, isNot(clock.nowMs()));
    });

    test('an existing row keeps its local audit columns', () async {
      await applier.applyPage(
        page(<Map<String, Object?>>[aCave()]),
        setId: setId,
      );
      final user = await UserRepository(
        db,
        () => logger,
      ).addUser(username: 'caver');
      await (db.update(db.caves)..where((t) => t.uuid.equalsValue(caveId)))
          .write(CavesCompanion(createdByUserUuid: Value(user)));

      await applier.applyPage(
        page(<Map<String, Object?>>[
          feature(
            id: caveId.toString(),
            kind: 'cave',
            name: 'Renamed on the server',
            updatedAt: '2026-08-30T09:00:00.000Z',
          ),
        ]),
        setId: setId,
      );

      final cave = await (db.select(
        db.caves,
      )..where((t) => t.uuid.equalsValue(caveId))).getSingle();
      expect(cave.title, 'Renamed on the server');
      // A device's user identifiers are provenance and are never mapped to a
      // SilexGIS account, so the server has nothing to say about them.
      expect(cave.createdByUserUuid, user);
    });

    test('a second page updates rather than duplicating', () async {
      await applier.applyPage(
        page(<Map<String, Object?>>[aCave()]),
        setId: setId,
      );
      final report = await applier.applyPage(
        page(<Map<String, Object?>>[
          feature(
            id: caveId.toString(),
            kind: 'cave',
            name: 'Peștera Mică (resurveyed)',
            updatedAt: '2026-08-30T09:00:00.000Z',
          ),
        ]),
        setId: setId,
      );
      expect(report.inserted, 0);
      expect(report.updated, 1);
      expect(await db.select(db.caves).get(), hasLength(1));
    });
  });

  group('an unsent local edit is not written over', () {
    test('the download leaves it alone and says so', () async {
      // Overwriting would lose the caver's work silently. Sending it produces
      // an answer they can act on — a conflict, with the server's own row
      // beside it, when the two have genuinely diverged.
      await applier.applyPage(
        page(<Map<String, Object?>>[aCave()]),
        setId: setId,
      );
      await (db.update(
        db.caves,
      )..where((t) => t.uuid.equalsValue(caveId))).write(
        CavesCompanion(
          title: const Value('Renamed on this device'),
          updatedAt: Value(clock.nowMs() + 1000),
        ),
      );

      final report = await applier.applyPage(
        page(<Map<String, Object?>>[
          feature(
            id: caveId.toString(),
            kind: 'cave',
            name: 'Renamed on the server',
            updatedAt: '2026-08-31T09:00:00.000Z',
          ),
        ]),
        setId: setId,
      );

      expect(report.updated, 0);
      expect(report.skipped[SilexgisSkipReason.unsentLocalEdit], 1);
      final cave = await (db.select(
        db.caves,
      )..where((t) => t.uuid.equalsValue(caveId))).getSingle();
      expect(cave.title, 'Renamed on this device');
    });

    test(
      'a row this device has never exchanged has no agreement to break',
      () async {
        // The download is where it first arrives, so nothing holds it back.
        final report = await applier.applyPage(
          page(<Map<String, Object?>>[aCave()]),
          setId: setId,
        );
        expect(report.inserted, 1);
        expect(report.skipped[SilexgisSkipReason.unsentLocalEdit], isNull);
      },
    );

    test(
      'a row that only arrived is not mistaken for one the caver edited',
      () async {
        await applier.applyPage(
          page(<Map<String, Object?>>[aCave()]),
          setId: setId,
        );
        final report = await applier.applyPage(
          page(<Map<String, Object?>>[
            feature(
              id: caveId.toString(),
              kind: 'cave',
              name: 'Renamed on the server',
              updatedAt: '2026-08-31T09:00:00.000Z',
            ),
          ]),
          setId: setId,
        );
        expect(report.updated, 1);
      },
    );
  });

  test(
    'a row agreed while it had no stamp takes the server\'s version',
    () async {
      await applier.applyPage(
        page(<Map<String, Object?>>[aCave()]),
        setId: setId,
      );
      await (db.update(db.caves)..where((t) => t.uuid.equalsValue(caveId)))
          .write(const CavesCompanion(updatedAt: Value(null)));
      await localState.writeRevision(
        profile,
        caveId,
        entityTable: 'caves',
        revision: '2026-08-28T09:00:00.000Z',
      );

      final renamed = aCave()
        ..['name'] = 'Peștera Mică, renamed'
        ..['updatedAt'] = '2026-08-31T09:00:00.000Z';
      final report = await applier.applyPage(
        page(<Map<String, Object?>>[renamed]),
        setId: setId,
      );
      expect(report.updated, 1);
      final cave = await (db.select(
        db.caves,
      )..where((t) => t.uuid.equalsValue(caveId))).getSingle();
      expect(cave.title, 'Peștera Mică, renamed');
    },
  );

  group('a row held for a reviewer is not written over', () {
    Future<void> hold(Uuid uuid, {required int? sentAt}) =>
        heldRows.recordHeld(profile, <SilexgisHeldEntry>[
          SilexgisHeldEntry(
            section: SyncUploadSection.rows,
            entityUuid: uuid,
            entityTable: 'caves',
            wireKind: 'cave',
            reviewId: 'review-1',
            sentLocalUpdatedAt: sentAt,
          ),
        ]);

    test('even a new row the server never had a revision for', () async {
      // The caver keeps seeing their own version while it waits. Without the
      // hold, a row the device never exchanged would be overwritten by the
      // first version the server hands back.
      await db
          .into(db.caves)
          .insert(
            Cave(
              uuid: caveId,
              title: 'Proposed here',
              updatedAt: clock.nowMs(),
            ),
          );
      await hold(caveId, sentAt: clock.nowMs());

      final report = await applier.applyPage(
        page(<Map<String, Object?>>[aCave()]),
        setId: setId,
      );

      expect(report.updated, 0);
      expect(report.skipped[SilexgisSkipReason.unsentLocalEdit], 1);
      final cave = await (db.select(
        db.caves,
      )..where((t) => t.uuid.equalsValue(caveId))).getSingle();
      expect(cave.title, 'Proposed here');
    });

    test(
      'rows handed over beside a decision leave the position alone',
      () async {
        await localState.writeSetState(
          profile,
          setId,
          cursor: 'kept',
          setRevision: 3,
        );
        final report = await applier.applyRows(<SyncFeatureRow>[
          SyncFeatureRow.fromJson(aCave()),
        ]);

        expect(report.inserted, 1);
        expect((await localState.readSetState(profile, setId)).cursor, 'kept');
        expect(await db.select(db.changeLog).get(), isEmpty);
      },
    );
  });

  group('a removal made here is not undone by the download', () {
    // Both rows were exchanged earlier; the caver has since deleted the
    // place, and the removal has not been settled with the server.
    setUp(() async {
      await applier.applyPage(
        page(<Map<String, Object?>>[aCave(), aPlace()]),
        setId: setId,
      );
      await db.delete(db.cavePlaces).go();
    });

    Map<String, Object?> placeChangedOnServer() => feature(
      id: placeId.toString(),
      kind: 'generic',
      featureTypeCode: 'cave_place',
      name: 'Sala Mare, edited in the browser',
      parentId: caveId.toString(),
      updatedAt: '2026-08-31T09:00:00.000Z',
    );

    Future<bool> placeIsBack() async =>
        (await (db.select(
          db.cavePlaces,
        )..where((t) => t.uuid.equalsValue(placeId))).getSingleOrNull()) !=
        null;

    test('while it has not been sent', () async {
      // An installation that does not take uploads never hears of it, and
      // the row's next change on the server must not quietly bring it back.
      final report = await applier.applyPage(
        page(<Map<String, Object?>>[placeChangedOnServer()]),
        setId: setId,
      );
      expect(report.inserted, 0);
      expect(report.skipped[SilexgisSkipReason.unsentLocalEdit], 1);
      expect(await placeIsBack(), isFalse);
    });

    test('but gives way once the server refused it for good', () async {
      // The upload forgets the revision of a removal the account may not
      // make, and the read from the beginning brings the row back.
      await localState.forgetRevisions(profile, <Uuid>[placeId]);
      final report = await applier.applyPage(
        page(<Map<String, Object?>>[aPlace()]),
        setId: setId,
      );
      expect(report.inserted, 1);
      expect(await placeIsBack(), isTrue);
    });

    test('while it waits on a conflict the caver has to settle', () async {
      await heldRows.recordConflicts(profile, <SilexgisConflictEntry>[
        SilexgisConflictEntry(
          section: SyncUploadSection.rows,
          entityUuid: placeId,
          entityTable: 'cave_places',
          wireKind: 'generic',
          code: 'sync.conflict',
          isDelete: true,
        ),
      ]);
      // The server's version comes back only through the caver's choice.
      final report = await applier.applyPage(
        page(<Map<String, Object?>>[placeChangedOnServer()]),
        setId: setId,
      );
      expect(report.inserted, 0);
      expect(await placeIsBack(), isFalse);
      expect(
        (await localState.readRevision(profile, placeId)),
        isNot('2026-08-31T09:00:00.000Z'),
      );
    });

    test(
      'while it waits for a reviewer, nor once the reviewer accepts it',
      () async {
        await heldRows.recordHeld(profile, <SilexgisHeldEntry>[
          SilexgisHeldEntry(
            section: SyncUploadSection.rows,
            entityUuid: placeId,
            entityTable: 'cave_places',
            wireKind: 'generic',
            reviewId: 'review-1',
            isDelete: true,
          ),
        ]);
        // A full read, after a stale cursor, carries the row as it stands.
        await applier.applyPage(
          page(<Map<String, Object?>>[aPlace()]),
          setId: setId,
        );
        expect(await placeIsBack(), isFalse);

        // What the review runner does when the removal is accepted.
        await localState.forgetRevisions(profile, <Uuid>[placeId]);
        await heldRows.clear(profile, SyncUploadSection.rows, <Uuid>[placeId]);
        final pending = await SilexgisUploadBuilder(
          db: db,
          localState: localState,
          heldRows: heldRows,
          profileUuid: profile,
        ).build();
        // A row put back by the read would now go up as a new one, recreating
        // what the reviewer has just removed.
        expect(pending.where((p) => p.entityUuid == placeId), isEmpty);
      },
    );
  });

  group('a child can arrive before its parent', () {
    test('within one page', () async {
      // The order is the change order and has nothing to do with containment:
      // rename a cave after creating a place inside it and the place is the
      // older change, so it arrives first.
      final report = await applier.applyPage(
        page(<Map<String, Object?>>[aPlace(), aCave()]),
        setId: setId,
      );
      expect(report.inserted, 2);
      expect(report.deferred, 0);
      final place = await (db.select(
        db.cavePlaces,
      )..where((t) => t.uuid.equalsValue(placeId))).getSingle();
      expect(place.caveUuid, caveId);
    });

    test('a whole page earlier, at small page sizes', () async {
      final first = await applier.applyPage(
        page(<Map<String, Object?>>[aPlace()]),
        setId: setId,
      );
      expect(first.inserted, 0);
      expect(first.deferred, 1);
      expect(await db.select(db.cavePlaces).get(), isEmpty);

      final second = await applier.applyPage(
        page(<Map<String, Object?>>[aCave()]),
        setId: setId,
      );
      // Both: the cave from this page, and the place held over from the last.
      expect(second.inserted, 2);
      expect(second.deferred, 0);
      expect(applier.takeUnresolved(), isEmpty);
    });

    test('a place under an area needs the area, which needs the cave', () async {
      final report = await applier.applyPage(
        page(<Map<String, Object?>>[
          aPlace(parent: areaId.toString()),
          feature(
            id: areaId.toString(),
            kind: 'generic',
            featureTypeCode: 'cave_area',
            name: 'Galeria',
            parentId: caveId.toString(),
          ),
          aCave(),
        ]),
        setId: setId,
      );
      expect(report.inserted, 3);
      final place = await (db.select(
        db.cavePlaces,
      )..where((t) => t.uuid.equalsValue(placeId))).getSingle();
      expect(place.caveAreaUuid, areaId);
      // The place's cave comes from the area, because a local place names both.
      expect(place.caveUuid, caveId);
    });

    test('a row waiting for its container is kept with the position', () async {
      // The cursor stored with the page is already past it.
      await applier.applyPage(
        page(<Map<String, Object?>>[aPlace()], hasMore: true),
        setId: setId,
      );
      expect(
        (await localState.readDeferredRows(profile, setId)).single.id,
        placeId.toString(),
      );

      await applier.applyPage(
        page(<Map<String, Object?>>[aCave()], hasMore: true),
        setId: setId,
      );
      expect(await localState.readDeferredRows(profile, setId), isEmpty);
    });

    test('a waiting row read again is written as its later version', () async {
      await applier.applyPage(
        page(<Map<String, Object?>>[aPlace()], hasMore: true),
        setId: setId,
      );
      final renamed = aPlace()
        ..['name'] = 'Sala Mare, renamed'
        ..['updatedAt'] = '2026-08-31T09:00:00.000Z';
      await applier.applyPage(
        page(<Map<String, Object?>>[renamed], hasMore: true),
        setId: setId,
      );
      expect(await localState.readDeferredRows(profile, setId), hasLength(1));

      final report = await applier.applyPage(
        page(<Map<String, Object?>>[aCave()]),
        setId: setId,
      );
      expect(report.inserted, 2);
      final place = await (db.select(
        db.cavePlaces,
      )..where((t) => t.uuid.equalsValue(placeId))).getSingle();
      expect(place.title, 'Sala Mare, renamed');
      expect(
        await localState.readRevision(profile, placeId),
        '2026-08-31T09:00:00.000Z',
      );
    });

    test('a waiting row deleted on the server is never placed', () async {
      await applier.applyPage(
        page(<Map<String, Object?>>[aPlace()], hasMore: true),
        setId: setId,
      );
      final report = await applier.applyPage(
        page(
          <Map<String, Object?>>[aCave()],
          tombstones: <Map<String, Object?>>[
            <String, Object?>{
              'id': placeId.toString(),
              'deletedAt': '2026-08-30T09:00:00.000Z',
            },
          ],
        ),
        setId: setId,
      );
      expect(report.inserted, 1);
      expect(await db.select(db.cavePlaces).get(), isEmpty);
      expect(applier.takeUnresolved(), isEmpty);
    });

    test('a container that never arrives leaves the row unresolved', () async {
      // `parents` is filtered to parents this caller may read, so a row can
      // sit inside a cave the caller cannot see and arrive with no usable
      // container at all. A place with no cave is not a shape this
      // application has.
      final report = await applier.applyPage(
        page(<Map<String, Object?>>[aPlace(parent: Uuid.v7().toString())]),
        setId: setId,
      );
      expect(report.inserted, 0);
      expect(report.deferred, 1);

      final unresolved = applier.takeUnresolved();
      expect(unresolved, hasLength(1));
      expect(unresolved.single.id, placeId.toString());
      expect(applier.pendingCount, 0);
    });
  });

  group('a cave can arrive before its surface area', () {
    final surfaceId = Uuid.v7();
    Map<String, Object?> aSurfaceArea() => feature(
      id: surfaceId.toString(),
      kind: 'generic',
      featureTypeCode: 'surface_area',
      name: 'Munții Inventați',
      properties: const <String, Object?>{
        'speleolocGeneralAreaIdentifier': 'MI',
      },
    );
    Future<Cave> storedCave() => (db.select(
      db.caves,
    )..where((t) => t.uuid.equalsValue(caveId))).getSingle();

    test('within one page, and is stored inside it', () async {
      // Rename an area after creating a cave in it and the cave is the older
      // change, so it arrives first.
      await applier.applyPage(
        page(<Map<String, Object?>>[
          aCave(parent: surfaceId.toString()),
          aSurfaceArea(),
        ]),
        setId: setId,
      );
      expect((await storedCave()).surfaceAreaUuid, surfaceId);
    });

    test('a whole page earlier, and is stored inside it', () async {
      final first = await applier.applyPage(
        page(<Map<String, Object?>>[
          aCave(parent: surfaceId.toString()),
          aPlace(),
        ], hasMore: true),
        setId: setId,
      );
      expect(first.deferred, 2);

      await applier.applyPage(
        page(<Map<String, Object?>>[aSurfaceArea()]),
        setId: setId,
      );
      expect((await storedCave()).surfaceAreaUuid, surfaceId);
      expect(await db.select(db.cavePlaces).get(), hasLength(1));
      expect(applier.takeUnresolved(), isEmpty);
    });

    test(
      'an area that never comes leaves the cave stored without one',
      () async {
        // A cave is still a cave without its area, unlike a place without its
        // cave; so is what waited on it.
        final report = await applier.applyPage(
          page(<Map<String, Object?>>[
            aCave(parent: surfaceId.toString()),
            aPlace(),
          ]),
          setId: setId,
        );
        expect(report.inserted, 2);
        expect((await storedCave()).surfaceAreaUuid, isNull);
        expect(applier.takeUnresolved(), isEmpty);
      },
    );

    test('a cave stored without its area is put inside it later', () async {
      await applier.applyPage(
        page(<Map<String, Object?>>[aCave(parent: surfaceId.toString())]),
        setId: setId,
      );
      expect((await storedCave()).surfaceAreaUuid, isNull);

      await applier.applyPage(
        page(<Map<String, Object?>>[
          aSurfaceArea(),
          aCave(parent: surfaceId.toString()),
        ]),
        setId: setId,
      );
      expect((await storedCave()).surfaceAreaUuid, surfaceId);
    });
  });

  group('rows this build does not model', () {
    test('are skipped without an error', () async {
      final report = await applier.applyPage(
        page(<Map<String, Object?>>[
          feature(id: Uuid.v7().toString(), kind: 'centerline', name: 'Survey'),
          feature(
            id: Uuid.v7().toString(),
            kind: 'generic',
            featureTypeCode: 'karst_area',
            name: 'A massif',
          ),
          aCave(),
        ]),
        setId: setId,
      );
      expect(report.inserted, 1);
      expect(report.skipped[SilexgisSkipReason.unmodelledKind], 2);
      // And they hold nothing back: they are not deferred, they are ignored.
      expect(report.deferred, 0);
    });
  });

  group('tombstones', () {
    test(
      'remove the row and forget its revision on this installation',
      () async {
        await applier.applyPage(
          page(<Map<String, Object?>>[aCave(), aPlace()]),
          setId: setId,
        );
        expect(await localState.readRevision(profile, placeId), isNotNull);

        final report = await applier.applyPage(
          page(
            const <Map<String, Object?>>[],
            tombstones: <Map<String, Object?>>[
              <String, Object?>{
                'id': placeId.toString(),
                'deletedAt': '2026-08-30T09:00:00.000Z',
              },
            ],
          ),
          setId: setId,
        );

        expect(report.deleted, 1);
        expect(await db.select(db.cavePlaces).get(), isEmpty);
        // The identifier stays the row's identity for ever, but its revision
        // here is gone: if the caver recreates it, it is new to this server.
        expect(await localState.readRevision(profile, placeId), isNull);
        // Still an import: removing a row the club removed is not local work.
        expect(await db.select(db.changeLog).get(), isEmpty);
      },
    );

    test('for an identifier this device never held are a no-op', () async {
      // The withholding of a position applies to live rows only: a row this
      // account may not place is absent from `features`, and its deletion is
      // still reported.
      final report = await applier.applyPage(
        page(
          const <Map<String, Object?>>[],
          tombstones: <Map<String, Object?>>[
            <String, Object?>{
              'id': Uuid.v7().toString(),
              'deletedAt': '2026-08-30T09:00:00.000Z',
            },
          ],
        ),
        setId: setId,
      );
      expect(report.deleted, 0);
    });
  });

  group('a tombstone over work the server never had', () {
    // Both rows were exchanged; what the caver did here since is set up by
    // each test.
    setUp(() async {
      await applier.applyPage(
        page(<Map<String, Object?>>[aCave(), aPlace()]),
        setId: setId,
      );
    });

    Map<String, Object?> tombstone(Uuid id) => <String, Object?>{
      'id': id.toString(),
      'deletedAt': '2026-08-30T09:00:00.000Z',
    };

    Future<bool> holds<T extends Table, D>(
      TableInfo<T, D> table,
      Uuid id,
    ) async =>
        (await db
                .customSelect(
                  'SELECT 1 FROM ${table.actualTableName} WHERE uuid = ?',
                  variables: <Variable<Object>>[Variable<Uint8List>(id.bytes)],
                )
                .get())
            .isNotEmpty;

    Future<SilexgisHeldItem?> decisionFor(Uuid id) async =>
        (await heldRows.readSection(profile, SyncUploadSection.rows))[id];

    SilexgisUploadBuilder builder() => SilexgisUploadBuilder(
      db: db,
      localState: localState,
      heldRows: heldRows,
      profileUuid: profile,
    );

    test(
      'keeps a place edited here and not yet sent, and asks the caver',
      () async {
        await (db.update(
          db.cavePlaces,
        )..where((t) => t.uuid.equalsValue(placeId))).write(
          CavePlacesCompanion(
            title: const Value('Renamed on this device'),
            updatedAt: Value(clock.nowMs() + 1000),
          ),
        );

        final report = await applier.applyPage(
          page(
            const <Map<String, Object?>>[],
            tombstones: <Map<String, Object?>>[tombstone(placeId)],
          ),
          setId: setId,
        );

        expect(report.deleted, 0);
        expect(report.skipped[SilexgisSkipReason.unsentLocalEdit], 1);
        expect(await holds(db.cavePlaces, placeId), isTrue);
        final decision = (await decisionFor(placeId))!;
        expect(decision.isDeletedOnServer, isTrue);
        expect(decision.awaitsCaver, isTrue);
        expect(decision.entityTable, 'cave_places');
        // Nothing is left there to write to, so nothing of it goes up.
        expect(await localState.readRevision(profile, placeId), isNull);
        expect(await builder().build(), isEmpty);
      },
    );

    test(
      'does not ask again when a full read hands the tombstone over again',
      () async {
        await (db.update(db.cavePlaces)
              ..where((t) => t.uuid.equalsValue(placeId)))
            .write(CavePlacesCompanion(updatedAt: Value(clock.nowMs() + 1000)));
        final removal = page(
          const <Map<String, Object?>>[],
          tombstones: <Map<String, Object?>>[tombstone(placeId)],
        );
        await applier.applyPage(removal, setId: setId);
        await heldRows.markKept(profile, SyncUploadSection.rows, placeId);

        await applier.applyPage(removal, setId: setId);

        final decision = (await decisionFor(placeId))!;
        expect(decision.keptAt, isNotNull);
        expect(decision.awaitsCaver, isFalse);
        expect(await holds(db.cavePlaces, placeId), isTrue);
      },
    );

    test('keeps a cave holding a place surveyed here and never sent', () async {
      final newPlace = Uuid.v7();
      await db
          .into(db.cavePlaces)
          .insert(
            CavePlace(
              uuid: newPlace,
              title: 'Found today',
              caveUuid: caveId,
              isEntrance: 0,
              isMainEntrance: 0,
              updatedAt: clock.nowMs(),
            ),
          );

      final report = await applier.applyPage(
        page(
          const <Map<String, Object?>>[],
          tombstones: <Map<String, Object?>>[tombstone(caveId)],
        ),
        setId: setId,
      );

      expect(report.deleted, 0);
      expect(await holds(db.caves, caveId), isTrue);
      expect(await holds(db.cavePlaces, newPlace), isTrue);
      expect((await decisionFor(caveId))!.isDeletedOnServer, isTrue);
      // The new place is not sent under a cave the server no longer has.
      expect(await builder().build(), isEmpty);
    });

    test('keeps a place carrying a beacon registration', () async {
      // No server holds a registration; only the caver can let it go.
      await db
          .into(db.cavePlaceBeacons)
          .insert(
            CavePlaceBeaconsCompanion.insert(
              uuid: Uuid.v7(),
              cavePlaceUuid: placeId,
              caveUuid: caveId,
            ),
          );

      await applier.applyPage(
        page(
          const <Map<String, Object?>>[],
          tombstones: <Map<String, Object?>>[tombstone(placeId)],
        ),
        setId: setId,
      );

      expect(await holds(db.cavePlaces, placeId), isTrue);
      expect(await db.select(db.cavePlaceBeacons).get(), hasLength(1));
    });

    test('removes a cave as the server has it, with what is inside', () async {
      final report = await applier.applyPage(
        page(
          const <Map<String, Object?>>[],
          tombstones: <Map<String, Object?>>[tombstone(caveId)],
        ),
        setId: setId,
      );

      expect(report.deleted, 1);
      expect(await holds(db.caves, caveId), isFalse);
      expect(await holds(db.cavePlaces, placeId), isFalse);
      // A revision left for the place would read as a removal of the
      // caver's still to send.
      expect(await localState.readRevisions(profile), isEmpty);
      expect(await builder().build(), isEmpty);
    });

    test(
      'removes an area with its places before their own tombstones come',
      () async {
        // The places' tombstones may be a page later; left behind, they would
        // still name the area and the page could not be stored at all.
        final areaPlace = Uuid.v7();
        await applier.applyPage(
          page(<Map<String, Object?>>[
            feature(
              id: areaId.toString(),
              kind: 'generic',
              featureTypeCode: 'cave_area',
              name: 'Galeria',
              parentId: caveId.toString(),
            ),
            feature(
              id: areaPlace.toString(),
              kind: 'generic',
              featureTypeCode: 'cave_place',
              name: 'In the gallery',
              parentId: areaId.toString(),
            ),
          ]),
          setId: setId,
        );

        final report = await applier.applyPage(
          page(
            const <Map<String, Object?>>[],
            tombstones: <Map<String, Object?>>[tombstone(areaId)],
          ),
          setId: setId,
        );

        expect(report.deleted, 1);
        expect(await holds(db.caveAreas, areaId), isFalse);
        expect(await holds(db.cavePlaces, areaPlace), isFalse);
        expect(await holds(db.cavePlaces, placeId), isTrue);
        expect(await localState.readRevision(profile, areaPlace), isNull);
      },
    );

    test('removes a surface area with the caves inside it', () async {
      final surfaceId = Uuid.v7();
      await applier.applyPage(
        page(<Map<String, Object?>>[
          feature(
            id: surfaceId.toString(),
            kind: 'generic',
            featureTypeCode: 'surface_area',
            name: 'Invented massif',
          ),
        ]),
        setId: setId,
      );
      await (db.update(db.caves)..where((t) => t.uuid.equalsValue(caveId)))
          .write(CavesCompanion(surfaceAreaUuid: Value(surfaceId)));

      final report = await applier.applyPage(
        page(
          const <Map<String, Object?>>[],
          tombstones: <Map<String, Object?>>[tombstone(surfaceId)],
        ),
        setId: setId,
      );

      expect(report.deleted, 1);
      expect(await holds(db.surfaceAreas, surfaceId), isFalse);
      expect(await holds(db.caves, caveId), isFalse);
    });

    test(
      'settles a removal of the caver\'s that waited on a conflict',
      () async {
        await db.delete(db.cavePlaces).go();
        await heldRows.recordConflicts(profile, <SilexgisConflictEntry>[
          SilexgisConflictEntry(
            section: SyncUploadSection.rows,
            entityUuid: placeId,
            entityTable: 'cave_places',
            wireKind: 'generic',
            code: 'sync.conflict',
            isDelete: true,
          ),
        ]);

        await applier.applyPage(
          page(
            const <Map<String, Object?>>[],
            tombstones: <Map<String, Object?>>[tombstone(placeId)],
          ),
          setId: setId,
        );

        // What the caver asked for has happened there too.
        expect(await decisionFor(placeId), isNull);
        expect(await localState.readRevision(profile, placeId), isNull);
        expect(await builder().build(), isEmpty);
      },
    );
  });

  group('the position it leaves behind', () {
    test('is stored with the page, not after it', () async {
      await applier.applyPage(
        page(
          <Map<String, Object?>>[aCave()],
          cursor: 'MXwxNjM4',
          setRevision: 4,
        ),
        setId: setId,
      );
      final state = await localState.readSetState(profile, setId);
      expect(state.cursor, 'MXwxNjM4');
      expect(state.setRevision, 4);
    });

    test('is kept when a caught-up page names none', () async {
      // A cursor is null only when there was nothing at or after the position
      // asked from. Storing that null would start the next run from the
      // beginning, so every run after an idle one would be a full read.
      await localState.writeSetState(
        profile,
        setId,
        cursor: 'MXwxNjM4',
        setRevision: 4,
      );
      await applier.applyPage(
        page(const <Map<String, Object?>>[], cursor: null, setRevision: 4),
        setId: setId,
      );
      final state = await localState.readSetState(profile, setId);
      expect(state.cursor, 'MXwxNjM4');
      expect(state.setRevision, 4);
    });

    test(
      'records a revision for every row it wrote, and none it did not',
      () async {
        await applier.applyPage(
          page(<Map<String, Object?>>[
            aCave(),
            feature(
              id: Uuid.v7().toString(),
              kind: 'centerline',
              name: 'Survey',
            ),
          ]),
          setId: setId,
        );
        final revisions = await localState.readRevisions(profile);
        expect(revisions.keys, <Uuid>[caveId]);
      },
    );
  });

  test(
    'a unique-key collision keeps the local row rather than sinking the page',
    () async {
      // Two devices that named the same chamber before they ever met. One
      // collision must never cost the rest of the page.
      await applier.applyPage(
        page(<Map<String, Object?>>[aCave()]),
        setId: setId,
      );
      final localTwin = Uuid.v7();
      await db
          .into(db.cavePlaces)
          .insert(
            CavePlace(
              uuid: localTwin,
              title: 'Sala Mare',
              caveUuid: caveId,
              isEntrance: 0,
              isMainEntrance: 0,
            ),
          );

      final report = await applier.applyPage(
        page(<Map<String, Object?>>[
          aPlace(),
          feature(
            id: Uuid.v7().toString(),
            kind: 'generic',
            featureTypeCode: 'cave_place',
            name: 'Somewhere else',
            parentId: caveId.toString(),
          ),
        ]),
        setId: setId,
      );

      expect(report.skipped[SilexgisSkipReason.uniqueCollision], 1);
      // The other row on the same page still landed.
      expect(report.inserted, 1);
      final kept = await (db.select(
        db.cavePlaces,
      )..where((t) => t.uuid.equalsValue(localTwin))).getSingle();
      expect(kept.title, 'Sala Mare');
    },
  );
}
