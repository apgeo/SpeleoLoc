import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/model/sync_download_page.dart';
import 'package:speleoloc/services/silexgis/silexgis_download_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/utils/clock.dart';

/// Applying a downloaded page: an import, not a user edit.
void main() {
  const profile = 'profile-a';
  const setId = 'set-1';

  late AppDatabase db;
  late ChangeLogger logger;
  late SilexgisLocalStateRepository localState;
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
    applier = SilexgisDownloadApplier(
      db: db,
      logger: logger,
      localState: localState,
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
  }) => SyncDownloadPage.fromJson(<String, Object?>{
    'setRevision': setRevision,
    'settings': const <String, Object?>{},
    'features': features,
    'tombstones': tombstones,
    'nextCursor': cursor,
    'hasMore': false,
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
