import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/archive/archive_table_configs.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/sync/sync_table_registry.dart';
import 'package:speleoloc/utils/clock.dart';

/// The state a device keeps about one installation, and the invariant that
/// makes it safe: none of it may leave the device except back to the server
/// that issued it.
void main() {
  late AppDatabase db;
  late SilexgisLocalStateRepository repo;
  final clock = FakeClock(DateTime.utc(2026, 9, 1, 12));

  const profile = 'profile-a';
  const other = 'profile-b';
  const setId = 'set-1';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SilexgisLocalStateRepository(db, clock: clock);
  });
  tearDown(() => db.close());

  group('neither table leaves the device', () {
    test('the sync archive does not carry them', () async {
      // Local-only in the same sense `configurations` and
      // `ruuvi_sensor_history` are: absent from the registry, so no exporter
      // has to remember to skip them.
      final exported = SyncTableRegistry(
        db,
      ).tables().map((t) => t.name).toSet();
      expect(exported, isNot(contains('silexgis_sync_state')));
      expect(exported, isNot(contains('silexgis_row_revision')));
    });

    test('the data archive does not carry them either', () {
      final configured = tableConfigs.map((c) => c.name).toSet();
      expect(configured, isNot(contains('silexgis_sync_state')));
      expect(configured, isNot(contains('silexgis_row_revision')));
    });

    test('writing to them logs no change', () async {
      // A change-log entry would put them in front of the FTP upload gate,
      // which is the other way they would travel.
      await repo.writeSetState(
        profile,
        setId,
        cursor: 'MXwxNjM4',
        setRevision: 4,
      );
      await repo.writeRevision(
        profile,
        Uuid.v7(),
        entityTable: 'cave_places',
        revision: '2026-08-28T09:14:52.113Z',
      );
      final logged = await db.select(db.changeLog).get();
      expect(logged, isEmpty);
    });
  });

  group('the set position', () {
    test('is a fresh read when nothing is stored', () async {
      final state = await repo.readSetState(profile, setId);
      expect(state.cursor, isNull);
      expect(state.setRevision, isNull);
    });

    test('round-trips the cursor as the opaque string it is', () async {
      await repo.writeSetState(
        profile,
        setId,
        cursor: 'MXwxNjM4NzQyNjQzMjEwfDAxYTA1',
        setRevision: 4,
      );
      final state = await repo.readSetState(profile, setId);
      expect(state.cursor, 'MXwxNjM4NzQyNjQzMjEwfDAxYTA1');
      expect(state.setRevision, 4);
      expect(state.lastSyncedAt, clock.now());
    });

    test('dropping the cursor keeps the revision it was read at', () async {
      await repo.writeSetState(profile, setId, cursor: 'c1', setRevision: 4);
      await repo.dropCursor(profile, setId);

      final state = await repo.readSetState(profile, setId);
      expect(state.cursor, isNull);
      expect(state.setRevision, 4);
    });

    test('is per installation and per set', () async {
      await repo.writeSetState(profile, setId, cursor: 'c1', setRevision: 1);
      await repo.writeSetState(other, setId, cursor: 'c2', setRevision: 9);
      await repo.writeSetState(profile, 'set-2', cursor: 'c3', setRevision: 3);

      expect((await repo.readSetState(profile, setId)).cursor, 'c1');
      expect((await repo.readSetState(other, setId)).cursor, 'c2');
      expect((await repo.readSetState(profile, 'set-2')).cursor, 'c3');
    });
  });

  group('row revisions', () {
    test('a row with none is new to that installation', () async {
      expect(await repo.readRevision(profile, Uuid.v7()), isNull);
    });

    test('are stored verbatim, offset form and all', () async {
      // The server compares them for equality; a parse-and-reformat round trip
      // is a way to lose that for no gain.
      const revision = '2026-08-31T23:32:15.300985+00:00';
      final id = Uuid.v7();
      await repo.writeRevision(
        profile,
        id,
        entityTable: 'cave_places',
        revision: revision,
      );
      expect(await repo.readRevision(profile, id), revision);
    });

    test('the newest write for a row wins', () async {
      final id = Uuid.v7();
      await repo.writeRevision(
        profile,
        id,
        entityTable: 'caves',
        revision: 'first',
      );
      await repo.writeRevision(
        profile,
        id,
        entityTable: 'caves',
        revision: 'second',
      );
      expect(await repo.readRevision(profile, id), 'second');
    });

    test(
      'the same identifier holds a different revision per installation',
      () async {
        // The identifier is the same everywhere — the device mints it and every
        // server adopts it verbatim — but a revision is one server's stamp and
        // means nothing on another.
        final id = Uuid.v7();
        await repo.writeRevisions(profile, <SilexgisRevisionEntry>[
          SilexgisRevisionEntry(
            entityUuid: id,
            entityTable: 'caves',
            revision: 'rev-a',
          ),
        ]);
        await repo.writeRevisions(other, <SilexgisRevisionEntry>[
          SilexgisRevisionEntry(
            entityUuid: id,
            entityTable: 'caves',
            revision: 'rev-b',
          ),
        ]);
        expect(await repo.readRevision(profile, id), 'rev-a');
        expect(await repo.readRevision(other, id), 'rev-b');
      },
    );

    test('are read in one query for a whole sync run', () async {
      final ids = List<Uuid>.generate(3, (_) => Uuid.v7());
      await repo.writeRevisions(profile, <SilexgisRevisionEntry>[
        for (final id in ids)
          SilexgisRevisionEntry(
            entityUuid: id,
            entityTable: 'cave_places',
            revision: 'rev-${ids.indexOf(id)}',
          ),
      ]);
      final all = await repo.readRevisions(profile);
      expect(all, hasLength(3));
      expect(all[ids.first], 'rev-0');
    });

    test('forgetting one makes the row new there again', () async {
      // What a tombstone leaves behind: the identifier stays the row's
      // identity for ever, and a later create-by-id under it is the correct
      // shape rather than a re-key.
      final kept = Uuid.v7();
      final gone = Uuid.v7();
      await repo.writeRevisions(profile, <SilexgisRevisionEntry>[
        SilexgisRevisionEntry(
          entityUuid: kept,
          entityTable: 'caves',
          revision: 'r1',
        ),
        SilexgisRevisionEntry(
          entityUuid: gone,
          entityTable: 'caves',
          revision: 'r2',
        ),
      ]);
      await repo.forgetRevisions(profile, <Uuid>[gone]);

      expect(await repo.readRevision(profile, kept), 'r1');
      expect(await repo.readRevision(profile, gone), isNull);
    });
  });

  test('forgetting a profile leaves nothing of that conversation', () async {
    final id = Uuid.v7();
    await repo.writeSetState(profile, setId, cursor: 'c1', setRevision: 1);
    await repo.writeRevision(profile, id, entityTable: 'caves', revision: 'r1');
    await repo.writeSetState(other, setId, cursor: 'c2', setRevision: 1);

    await repo.forgetProfile(profile);

    expect((await repo.readSetState(profile, setId)).cursor, isNull);
    expect(await repo.readRevision(profile, id), isNull);
    // And leaves the other installation's conversation alone.
    expect((await repo.readSetState(other, setId)).cursor, 'c2');
  });
}
