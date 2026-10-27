import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Where one stream keeps its resume position between runs.
abstract interface class SilexgisCursorStore {
  /// The stored position, or null to read from the beginning.
  Future<String?> read();

  /// Throws the position away, so the next read starts from the beginning.
  Future<void> drop();
}

/// One stream's position in the per-stream cursor table.
class SilexgisStreamCursorStore implements SilexgisCursorStore {
  const SilexgisStreamCursorStore({
    required SilexgisLocalStateRepository localState,
    required String profileUuid,
    required String setId,
    required SyncStream stream,
  }) : _localState = localState,
       _profileUuid = profileUuid,
       _setId = setId,
       _stream = stream;

  final SilexgisLocalStateRepository _localState;
  final String _profileUuid;
  final String _setId;
  final SyncStream _stream;

  @override
  Future<String?> read() async => (await _localState.readStreamCursor(
    _profileUuid,
    _setId,
    _stream,
  )).cursor;

  @override
  Future<void> drop() =>
      _localState.dropStreamCursor(_profileUuid, _setId, _stream);

  /// Records the position [page] handed back. Call it inside the transaction
  /// that stores the page's contents.
  Future<void> write(SyncStreamPage page) => _localState.writeStreamCursor(
    _profileUuid,
    _setId,
    _stream,
    cursor: page.nextCursor,
    setRevision: page.setRevision,
  );
}

/// What reading one stream to the end did.
class SilexgisPagedReadReport {
  const SilexgisPagedReadReport({
    required this.pages,
    required this.restarted,
    required this.setRevision,
  });

  final int pages;

  /// True when the stored position was refused and the stream was read from
  /// the beginning instead. Not a fault: it is the ordinary consequence of
  /// editing a selection from the settings page.
  final bool restarted;

  /// The set's revision as of the last page, or 0 when no page was read.
  final int setRevision;
}

/// Reads one paged stream to the end, a page at a time.
///
/// The cursor is the whole of the device's position and the server keeps
/// nothing between requests, so a lost connection costs the page in flight
/// rather than the whole read: [apply] stores the position with each page, and
/// the next run resumes from it.
class SilexgisPagedStreamRunner<P extends SyncStreamPage> {
  SilexgisPagedStreamRunner({
    required String name,
    required SilexgisCursorStore cursors,
    required Future<P> Function(String? cursor) fetch,
    required Future<void> Function(P page) apply,
  }) : _name = name,
       _cursors = cursors,
       _fetch = fetch,
       _apply = apply;

  final String _name;
  final SilexgisCursorStore _cursors;
  final Future<P> Function(String? cursor) _fetch;

  /// Stores one page and the position it hands back, together: a page written
  /// whose cursor is lost would be read again, and a cursor stored without its
  /// page would skip it.
  final Future<void> Function(P page) _apply;

  final _log = AppLogger.of('SilexgisPagedStreamRunner');

  /// Reads to the end. Pass [fromBeginning] to drop the stored position first;
  /// a full read is always correct.
  Future<SilexgisPagedReadReport> run({bool fromBeginning = false}) async {
    if (fromBeginning) await _cursors.drop();

    var pages = 0;
    var restarted = false;
    var setRevision = 0;
    var cursor = await _cursors.read();

    var more = true;
    while (more) {
      final page = await _readPage(cursor);
      if (page == null) {
        // The position was refused and dropped; go round again from none.
        restarted = true;
        cursor = null;
        continue;
      }

      await _apply(page);
      pages++;
      setRevision = page.setRevision;
      cursor = page.nextCursor;
      more = page.hasMore;
    }

    return SilexgisPagedReadReport(
      pages: pages,
      restarted: restarted,
      setRevision: setRevision,
    );
  }

  /// One page, or null when the stored position was refused and dropped.
  ///
  /// A refused cursor is answered once. Retrying the same one never succeeds,
  /// and the restart that follows starts from no position at all, so there is
  /// no second refusal to loop on.
  Future<P?> _readPage(String? cursor) async {
    try {
      return await _fetch(cursor);
    } on SilexgisProblemException catch (e) {
      // Two different statuses and codes for one decision on the device:
      // throw the position away and read the stream from the beginning.
      final refusedPosition =
          e.code == SilexgisCodes.cursorInvalid ||
          e.code == SilexgisCodes.cursorStale;
      if (!refusedPosition || cursor == null) rethrow;

      _log.info(
        'the stored $_name position was refused (${e.code}); reading it from '
        'the beginning',
      );
      await _cursors.drop();
      return null;
    }
  }
}
