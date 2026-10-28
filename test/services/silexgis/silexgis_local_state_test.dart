import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
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

  group('no SilexGIS state table leaves the device', () {
    test('the sync archive does not carry them', () async {
      // Local-only in the same sense `configurations` and
      // `ruuvi_sensor_history` are: absent from the registry, so no exporter
      // has to remember to skip them.
      final exported = SyncTableRegistry(
        db,
      ).tables().map((t) => t.name).toSet();
      expect(exported, isNot(contains('silexgis_sync_state')));
      expect(exported, isNot(contains('silexgis_row_revision')));
      expect(exported, isNot(contains('silexgis_stream_cursor')));
      expect(exported, isNot(contains('silexgis_held_row')));
      expect(exported, isNot(contains('silexgis_person')));
      expect(exported, isNot(contains('silexgis_person_link')));
      expect(exported, isNot(contains('silexgis_document')));
      expect(exported, isNot(contains('silexgis_document_link')));
      expect(exported, isNot(contains('silexgis_file_copy')));
      expect(exported, isNot(contains('silexgis_staged_upload')));
      expect(exported, isNot(contains('silexgis_server_link')));
      expect(exported, isNot(contains('silexgis_trip_entry')));
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
      await repo.writeStreamCursor(
        profile,
        setId,
        SyncStream.documents,
        cursor: 'ZG9jczE=',
        setRevision: 4,
      );
      final logged = await db.select(db.changeLog).get();
      expect(logged, isEmpty);
    });
  });

  group('a stream position', () {
    test('is a fresh read when nothing is stored', () async {
      final state = await repo.readStreamCursor(
        profile,
        setId,
        SyncStream.trips,
      );
      expect(state.cursor, isNull);
      expect(state.setRevision, isNull);
    });

    test('is kept apart from the feature download\'s', () async {
      await repo.writeSetState(
        profile,
        setId,
        cursor: 'features',
        setRevision: 2,
      );
      await repo.writeStreamCursor(
        profile,
        setId,
        SyncStream.rasters,
        cursor: 'rasters',
        setRevision: 2,
      );
      expect((await repo.readSetState(profile, setId)).cursor, 'features');
      final rasters = await repo.readStreamCursor(
        profile,
        setId,
        SyncStream.rasters,
      );
      expect(rasters.cursor, 'rasters');
      expect(rasters.setRevision, 2);
      expect(rasters.lastSyncedAt, clock.now());
    });

    test('is one per stream, and dropping one drops no other', () async {
      for (final stream in SyncStream.values) {
        await repo.writeStreamCursor(
          profile,
          setId,
          stream,
          cursor: 'at-${stream.routeName}',
          setRevision: 3,
        );
      }
      await repo.dropStreamCursor(profile, setId, SyncStream.trips);

      for (final stream in SyncStream.values) {
        final state = await repo.readStreamCursor(profile, setId, stream);
        expect(
          state.cursor,
          stream == SyncStream.trips ? isNull : 'at-${stream.routeName}',
          reason: stream.routeName,
        );
        expect(state.setRevision, 3);
      }
    });

    test('is per installation and per set', () async {
      await repo.writeStreamCursor(
        profile,
        setId,
        SyncStream.reviews,
        cursor: 'c1',
        setRevision: 1,
      );
      await repo.writeStreamCursor(
        other,
        setId,
        SyncStream.reviews,
        cursor: 'c2',
        setRevision: 1,
      );
      await repo.writeStreamCursor(
        profile,
        'set-2',
        SyncStream.reviews,
        cursor: 'c3',
        setRevision: 1,
      );
      Future<String?> read(String p, String s) async =>
          (await repo.readStreamCursor(p, s, SyncStream.reviews)).cursor;
      expect(await read(profile, setId), 'c1');
      expect(await read(other, setId), 'c2');
      expect(await read(profile, 'set-2'), 'c3');
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
      expect(all[ids.first]!.revision, 'rev-0');
      expect(all[ids.first]!.entityTable, 'cave_places');
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
    await repo.writeStreamCursor(
      profile,
      setId,
      SyncStream.documents,
      cursor: 'd1',
      setRevision: 1,
    );
    await db
        .into(db.silexgisHeldRow)
        .insert(
          SilexgisHeldRowCompanion.insert(
            profileUuid: profile,
            section: 'rows',
            entityUuid: id,
            entityTable: 'caves',
            reviewId: 'review-1',
          ),
        );
    await db
        .into(db.silexgisPerson)
        .insert(
          SilexgisPersonCompanion.insert(
            profileUuid: profile,
            caverId: 'caver-1',
            fullName: 'Invented Caver',
          ),
        );
    await db
        .into(db.silexgisPersonLink)
        .insert(
          SilexgisPersonLinkCompanion.insert(
            profileUuid: profile,
            userUuid: Uuid.v7(),
          ),
        );

    final documentId = Uuid.v7();
    await db
        .into(db.silexgisDocument)
        .insert(
          SilexgisDocumentCompanion.insert(
            profileUuid: profile,
            documentId: documentId,
            title: 'invented.jpg',
            fileKind: 'photo',
            reach: 'original',
          ),
        );
    await db
        .into(db.silexgisDocumentLink)
        .insert(
          SilexgisDocumentLinkCompanion.insert(
            profileUuid: profile,
            linkId: 'link-1',
            documentId: documentId,
            targetKind: 'feature',
            targetId: id,
          ),
        );
    await db
        .into(db.silexgisStagedUpload)
        .insert(
          SilexgisStagedUploadCompanion.insert(
            profileUuid: profile,
            documentUuid: documentId,
            sha256: 'ab' * 32,
            sizeBytes: 3,
            state: 'staged',
          ),
        );
    await db
        .into(db.silexgisServerLink)
        .insert(
          SilexgisServerLinkCompanion.insert(
            profileUuid: profile,
            documentUuid: documentId,
            targetKind: 'feature',
            targetId: id,
          ),
        );
    await db
        .into(db.silexgisTripEntry)
        .insert(
          SilexgisTripEntryCompanion.insert(
            profileUuid: profile,
            entityUuid: id,
            recordingUuid: id,
          ),
        );

    await repo.forgetProfile(profile);

    expect((await repo.readSetState(profile, setId)).cursor, isNull);
    expect(await repo.readRevision(profile, id), isNull);
    expect(
      (await repo.readStreamCursor(
        profile,
        setId,
        SyncStream.documents,
      )).cursor,
      isNull,
    );
    expect(await db.select(db.silexgisHeldRow).get(), isEmpty);
    expect(await db.select(db.silexgisPerson).get(), isEmpty);
    expect(await db.select(db.silexgisPersonLink).get(), isEmpty);
    expect(await db.select(db.silexgisDocument).get(), isEmpty);
    expect(await db.select(db.silexgisDocumentLink).get(), isEmpty);
    expect(await db.select(db.silexgisStagedUpload).get(), isEmpty);
    expect(await db.select(db.silexgisServerLink).get(), isEmpty);
    expect(await db.select(db.silexgisTripEntry).get(), isEmpty);
    // And leaves the other installation's conversation alone.
    expect((await repo.readSetState(other, setId)).cursor, 'c2');
  });
}
