import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/sync_download_page.dart';
import 'package:speleoloc/services/silexgis/model/sync_feature_row.dart';
import 'package:speleoloc/services/silexgis/silexgis_download_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_paged_stream_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';

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

/// Reads a sync set's feature rows, a page at a time, and hands each page to
/// the applier.
///
/// The paging and the answer to a refused position are the shared stream
/// runner's; what is particular here is where the position is kept — beside
/// the set, in `silexgis_sync_state` — and that the applier stores it in the
/// same transaction as the page.
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
    final pageSize = capabilities.pageSizeMax < preferredPageSize
        ? capabilities.pageSizeMax
        : preferredPageSize;

    var applied = const SilexgisApplyReport();
    final read = await SilexgisPagedStreamRunner<SyncDownloadPage>(
      name: 'download',
      cursors: _FeatureCursorStore(_localState, _profileUuid, setId),
      fetch: (cursor) =>
          _api.download(setId, cursor: cursor, pageSize: pageSize),
      apply: (page) async {
        applied = applied.plus(await _applier.applyPage(page, setId: setId));
      },
    ).run(fromBeginning: fromBeginning);

    return SilexgisDownloadReport(
      pages: read.pages,
      applied: applied,
      restarted: read.restarted,
      // A row still held when the read ends is one whose container never
      // arrived, which for this account means it never will.
      unresolved: _applier.takeUnresolved(),
      setRevision: read.setRevision,
    );
  }
}

/// The feature download's position, kept per set beside the set's revision.
class _FeatureCursorStore implements SilexgisCursorStore {
  const _FeatureCursorStore(this._localState, this._profileUuid, this._setId);

  final SilexgisLocalStateRepository _localState;
  final String _profileUuid;
  final String _setId;

  @override
  Future<String?> read() async =>
      (await _localState.readSetState(_profileUuid, _setId)).cursor;

  @override
  Future<void> drop() => _localState.dropCursor(_profileUuid, _setId);
}
