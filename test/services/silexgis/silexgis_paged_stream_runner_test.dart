import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_paged_stream_runner.dart';

/// Reading any paged stream on its own cursor, and dropping only the cursor
/// that was refused.
void main() {
  const profile = 'profile-a';
  const setId = 'set-1';

  late AppDatabase db;
  late SilexgisLocalStateRepository localState;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localState = SilexgisLocalStateRepository(db);
  });
  tearDown(() => db.close());

  SilexgisStreamCursorStore storeFor(SyncStream stream) =>
      SilexgisStreamCursorStore(
        localState: localState,
        profileUuid: profile,
        setId: setId,
        stream: stream,
      );

  Future<String?> stored(SyncStream stream) async =>
      (await localState.readStreamCursor(profile, setId, stream)).cursor;

  /// An invented server for one stream: answers each request from [pages] in
  /// order, and records the cursor every request carried.
  ({SilexgisPagedStreamRunner<_Page> runner, List<String?> asked}) streamOf(
    SyncStream stream,
    List<Object> pages,
  ) {
    final asked = <String?>[];
    final store = storeFor(stream);
    final script = List<Object>.of(pages);
    final runner = SilexgisPagedStreamRunner<_Page>(
      name: stream.routeName,
      cursors: store,
      fetch: (cursor) async {
        asked.add(cursor);
        final next = script.removeAt(0);
        if (next is SilexgisProblem) throw SilexgisProblemException(next);
        return next as _Page;
      },
      apply: store.write,
    );
    return (runner: runner, asked: asked);
  }

  const stale = SilexgisProblem(status: 409, code: SilexgisCodes.cursorStale);
  const invalid = SilexgisProblem(
    status: 400,
    code: SilexgisCodes.cursorInvalid,
  );

  test('reads to the end and stores each page\'s position', () async {
    final read = streamOf(SyncStream.documents, <Object>[
      const _Page(cursor: 'd1', more: true),
      const _Page(cursor: 'd2', more: false, revision: 5),
    ]);

    final report = await read.runner.run();

    expect(read.asked, <String?>[null, 'd1']);
    expect(report.pages, 2);
    expect(report.restarted, isFalse);
    expect(report.setRevision, 5);
    expect(await stored(SyncStream.documents), 'd2');
  });

  for (final stream in SyncStream.values) {
    for (final refusal in <SilexgisProblem>[stale, invalid]) {
      test('${stream.routeName}: ${refusal.code} drops that cursor and reads '
          'from the beginning', () async {
        for (final each in SyncStream.values) {
          await localState.writeStreamCursor(
            profile,
            setId,
            each,
            cursor: 'old-${each.routeName}',
            setRevision: 1,
          );
        }
        final read = streamOf(stream, <Object>[
          refusal,
          const _Page(cursor: 'fresh', more: false),
        ]);

        final report = await read.runner.run();

        expect(report.restarted, isTrue);
        expect(read.asked, <String?>['old-${stream.routeName}', null]);
        expect(await stored(stream), 'fresh');
        // Each stream's cursor is refused by every other, so one refusal
        // says nothing about the rest.
        for (final each in SyncStream.values.where((s) => s != stream)) {
          expect(
            await stored(each),
            'old-${each.routeName}',
            reason: each.routeName,
          );
        }
      });
    }
  }

  test('a cursor from one stream is never sent to another', () async {
    final documents = streamOf(SyncStream.documents, <Object>[
      const _Page(cursor: 'documents-1', more: false),
    ]);
    final trips = streamOf(SyncStream.trips, <Object>[
      const _Page(cursor: 'trips-1', more: false),
    ]);
    await documents.runner.run();
    await trips.runner.run();

    final documentsAgain = streamOf(SyncStream.documents, <Object>[
      const _Page(cursor: 'documents-2', more: false),
    ]);
    final tripsAgain = streamOf(SyncStream.trips, <Object>[
      const _Page(cursor: 'trips-2', more: false),
    ]);
    await tripsAgain.runner.run();
    await documentsAgain.runner.run();

    expect(trips.asked, <String?>[null]);
    expect(tripsAgain.asked, <String?>['trips-1']);
    expect(documentsAgain.asked, <String?>['documents-1']);
  });

  test('a refusal of a fresh read is not retried for ever', () async {
    await localState.writeStreamCursor(
      profile,
      setId,
      SyncStream.rasters,
      cursor: 'old',
      setRevision: 1,
    );
    final read = streamOf(SyncStream.rasters, <Object>[stale, stale]);

    await expectLater(
      read.runner.run(),
      throwsA(isA<SilexgisProblemException>()),
    );
    expect(read.asked, <String?>['old', null]);
  });

  test('any other refusal reaches the caller and keeps the cursor', () async {
    await localState.writeStreamCursor(
      profile,
      setId,
      SyncStream.reviews,
      cursor: 'kept',
      setRevision: 1,
    );
    final read = streamOf(SyncStream.reviews, <Object>[
      const SilexgisProblem(status: 404, code: SilexgisCodes.setNotFound),
    ]);

    await expectLater(
      read.runner.run(),
      throwsA(
        isA<SilexgisProblemException>().having(
          (e) => e.code,
          'code',
          SilexgisCodes.setNotFound,
        ),
      ),
    );
    expect(await stored(SyncStream.reviews), 'kept');
  });

  test('a full read drops the stored position first', () async {
    await localState.writeStreamCursor(
      profile,
      setId,
      SyncStream.trips,
      cursor: 'somewhere',
      setRevision: 1,
    );
    final read = streamOf(SyncStream.trips, <Object>[
      const _Page(cursor: 't1', more: false),
    ]);

    final report = await read.runner.run(fromBeginning: true);

    expect(read.asked, <String?>[null]);
    expect(report.restarted, isFalse);
  });
}

/// An invented page: only what every stream's page has in common.
class _Page implements SyncStreamPage {
  const _Page({required this.cursor, required this.more, this.revision = 1});

  final String? cursor;
  final bool more;
  final int revision;

  @override
  String? get nextCursor => cursor;
  @override
  bool get hasMore => more;
  @override
  int get setRevision => revision;
}
