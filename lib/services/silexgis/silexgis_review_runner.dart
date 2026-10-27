import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/sync_review.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_paged_stream_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// What reading the reviews stream did.
class SilexgisReviewReport {
  const SilexgisReviewReport({
    required this.pages,
    required this.restarted,
    this.accepted = 0,
    this.decided = 0,
  });

  final int pages;
  final bool restarted;

  /// Held rows a reviewer accepted: their revision is now the base revision.
  final int accepted;

  /// Held rows turned down or failed, now waiting for the caver.
  final int decided;
}

/// Reads the reviewers' decisions on this account's held rows, on the reviews
/// stream's own cursor, and records them against the rows still waiting.
///
/// A decision is matched to a held row by its review, never by the row alone:
/// a row sent again with other content waits under a new review, and every
/// decision about the earlier one — `superseded` among them — no longer
/// concerns it. A reviewer may also change their mind, so the same review can
/// arrive twice; the decision read last is the one that stands.
class SilexgisReviewRunner {
  SilexgisReviewRunner({
    required AppDatabase db,
    required SilexgisSyncApi api,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required String profileUuid,
  }) : _db = db,
       _api = api,
       _localState = localState,
       _heldRows = heldRows,
       _profileUuid = profileUuid;

  final AppDatabase _db;
  final SilexgisSyncApi _api;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final String _profileUuid;
  final _log = AppLogger.of('SilexgisReviewRunner');

  static const int preferredPageSize = 100;

  Future<SilexgisReviewReport> run(
    String setId, {
    required SilexgisCapabilities capabilities,
    bool fromBeginning = false,
  }) async {
    final pageSize = capabilities.pageSizeMax < preferredPageSize
        ? capabilities.pageSizeMax
        : preferredPageSize;
    final cursors = SilexgisStreamCursorStore(
      localState: _localState,
      profileUuid: _profileUuid,
      setId: setId,
      stream: SyncStream.reviews,
    );

    var accepted = 0;
    var decided = 0;
    final read = await SilexgisPagedStreamRunner<SyncReviewsPage>(
      name: 'reviews',
      cursors: cursors,
      fetch: (cursor) => _api.reviews(
        setId,
        cursor: cursor,
        pageSize: pageSize > 0 ? pageSize : null,
      ),
      apply: (page) => _db.transaction(() async {
        for (final review in page.reviews) {
          switch (await _apply(setId, review)) {
            case SyncReviewOutcome.accepted:
              accepted++;
            case SyncReviewOutcome.rejected:
            case SyncReviewOutcome.failed:
              decided++;
            case SyncReviewOutcome.superseded:
            case null:
              break;
          }
        }
        await cursors.write(page);
      }),
    ).run(fromBeginning: fromBeginning);

    return SilexgisReviewReport(
      pages: read.pages,
      restarted: read.restarted,
      accepted: accepted,
      decided: decided,
    );
  }

  /// Records one decision. Returns the outcome when it changed something.
  Future<SyncReviewOutcome?> _apply(String setId, SyncReview review) async {
    final held = await _heldRows.byReviewId(_profileUuid, review.reviewId);
    if (held == null) return null;

    switch (review.outcome) {
      case SyncReviewOutcome.accepted:
        final revision = review.revision;
        // A reviewer may accept part of a feature edit, field by field, and
        // the answer cannot say which part yet. The server's row is then
        // neither the device's nor what it held before, and an incremental
        // read would never bring it: the feature stream is read again from
        // the beginning. A create is accepted whole, and a removal has no row
        // left to differ.
        final wasEdit =
            held.section == SyncUploadSection.rows &&
            !held.isDelete &&
            await _localState.readRevision(_profileUuid, held.entityUuid) !=
                null;
        if (wasEdit) await _localState.dropCursor(_profileUuid, setId);
        if (held.isDelete) {
          await _localState.forgetRevisions(_profileUuid, <Uuid>[
            held.entityUuid,
          ]);
        } else if (revision != null) {
          // The row as written is the version the device sent, so the stamp
          // it was sent at is the one the two sides now agree on: an edit
          // made since is still due to go up.
          await _localState.writeRevision(
            _profileUuid,
            held.entityUuid,
            entityTable: held.entityTable,
            wireKind: held.wireKind,
            revision: revision,
            localUpdatedAt: held.sentLocalUpdatedAt,
          );
        }
        await _heldRows.clear(_profileUuid, held.section, <Uuid>[
          held.entityUuid,
        ]);
        return SyncReviewOutcome.accepted;

      case SyncReviewOutcome.rejected:
      case SyncReviewOutcome.failed:
        // The local row is left as it is: what happens to it is the caver's
        // choice, made on the review outcomes page.
        await _heldRows.recordDecision(
          _profileUuid,
          reviewId: review.reviewId,
          outcome: review.outcome!,
          note: review.note,
          code: review.code,
          decidedAt: review.decidedAt,
          current: review.current,
        );
        return review.outcome;

      case SyncReviewOutcome.superseded:
        // The later review will be decided in its turn.
        return null;

      case null:
        _log.warning(
          'a review named an outcome this build does not know: '
          '${review.rawOutcome}',
        );
        return null;
    }
  }
}
