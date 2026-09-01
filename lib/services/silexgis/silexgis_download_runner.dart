import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_download_page.dart';
import 'package:speleoloc/services/silexgis/model/sync_feature_row.dart';
import 'package:speleoloc/services/silexgis/silexgis_download_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// What a whole read did.
class SilexgisDownloadReport {
  const SilexgisDownloadReport({
    required this.pages,
    required this.applied,
    required this.restarted,
    required this.unresolved,
    required this.setRevision,
  });

  final int pages;
  final SilexgisApplyReport applied;

  /// True when a stored position was refused and the set was read from the
  /// beginning instead. Not a fault: it is the ordinary consequence of editing
  /// a selection from the settings page.
  final bool restarted;

  /// Rows carried but not stored, because the container they name is one this
  /// account may not read. Told to the caver rather than left to be noticed.
  final List<SyncFeatureRow> unresolved;

  final int setRevision;
}

/// Reads a sync set, a page at a time, and hands each page to the applier.
///
/// The cursor is the whole of the device's position and the server keeps
/// nothing between requests, so a lost connection costs the page in flight
/// rather than the whole read: the position is stored with each page, and the
/// next run resumes from it.
class SilexgisDownloadRunner {
  SilexgisDownloadRunner({
    required SilexgisSyncApi api,
    required SilexgisDownloadApplier applier,
    required SilexgisLocalStateRepository localState,
    required String profileUuid,
  }) : _api = api,
       _applier = applier,
       _localState = localState,
       _profileUuid = profileUuid;

  final SilexgisSyncApi _api;
  final SilexgisDownloadApplier _applier;
  final SilexgisLocalStateRepository _localState;
  final String _profileUuid;
  final _log = AppLogger.of('SilexgisDownloadRunner');

  /// A page smaller than the installation's ceiling, because `pageSize` counts
  /// rows and not bytes: a centerline's geometry is a cave's whole survey and
  /// one row of it can be far bigger than the other ninety-nine.
  static const int preferredPageSize = 100;

  /// Reads [setId] to the end.
  ///
  /// Pass [fromBeginning] to drop the stored position first. A full read is
  /// always correct, and it is the only way to pick up a row that became
  /// readable: being granted the right to place a cave writes nothing to that
  /// cave's row, so its change key does not move and no incremental read will
  /// ever carry it.
  Future<SilexgisDownloadReport> run(
    String setId, {
    required SilexgisCapabilities capabilities,
    bool fromBeginning = false,
  }) async {
    if (fromBeginning) {
      await _localState.dropCursor(_profileUuid, setId);
    }

    final pageSize = capabilities.pageSizeMax < preferredPageSize
        ? capabilities.pageSizeMax
        : preferredPageSize;

    var report = const SilexgisApplyReport();
    var pages = 0;
    var restarted = false;
    var setRevision = 0;
    var cursor = (await _localState.readSetState(_profileUuid, setId)).cursor;

    var more = true;
    while (more) {
      final page = await _readPage(
        setId,
        cursor: cursor,
        pageSize: pageSize,
        onRestart: () {
          // Two different statuses and codes for one decision on the device:
          // throw the position away and read the set from the beginning.
          restarted = true;
          cursor = null;
        },
      );
      if (page == null) continue; // the cursor was dropped; go round again.

      report = report.plus(await _applier.applyPage(page, setId: setId));
      pages++;
      setRevision = page.setRevision;
      cursor = page.nextCursor;
      more = page.hasMore;
    }

    return SilexgisDownloadReport(
      pages: pages,
      applied: report,
      restarted: restarted,
      // A row still held when the read ends is one whose container never
      // arrived, which for this account means it never will.
      unresolved: _applier.takeUnresolved(),
      setRevision: setRevision,
    );
  }

  /// One page, or null when the stored position was refused and dropped.
  ///
  /// A refused cursor is answered once. Retrying the same one never succeeds,
  /// and the restart that follows starts from no position at all, so there is
  /// no second refusal to loop on.
  Future<SyncDownloadPage?> _readPage(
    String setId, {
    required String? cursor,
    required int pageSize,
    required void Function() onRestart,
  }) async {
    try {
      return await _api.download(setId, cursor: cursor, pageSize: pageSize);
    } on SilexgisProblemException catch (e) {
      final refusedPosition =
          e.code == SilexgisCodes.cursorInvalid ||
          e.code == SilexgisCodes.cursorStale;
      if (!refusedPosition || cursor == null) rethrow;

      _log.info(
        'the stored resume position was refused (${e.code}); reading the set '
        'from the beginning',
      );
      await _localState.dropCursor(_profileUuid, setId);
      onRestart();
      return null;
    }
  }
}
