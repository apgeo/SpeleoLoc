import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_feature_row.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_batch.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_builder.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_part.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// One row the server would not take, kept for the caver to look at.
class SilexgisRefusal {
  const SilexgisRefusal({
    required this.entityUuid,
    required this.entityTable,
    required this.result,
    this.serverRow,
  });

  final Uuid entityUuid;
  final String entityTable;
  final SyncRowResult result;

  /// The server's own version of a row that lost a conflict.
  ///
  /// **Null on a row whose position this account may not have** — the same
  /// answer the download gives, absence rather than a blurred stand-in. It
  /// means "re-read this row", not "something went wrong".
  final SyncFeatureRow? serverRow;

  SilexgisAction get action => result.action;
  bool get isConflict => result.status == SyncRowStatus.conflict;

  /// True when the row lost a conflict and the server did not echo it back.
  /// A full read is what resolves it.
  bool get needsReread => isConflict && serverRow == null;
}

/// What a whole write did.
class SilexgisUploadReport {
  const SilexgisUploadReport({
    required this.batches,
    required this.written,
    required this.refused,
    required this.refusals,
    required this.duplicates,
    required this.replayed,
    this.held = 0,
  });

  const SilexgisUploadReport.nothingToSend()
    : batches = 0,
      written = 0,
      refused = 0,
      refusals = const <SilexgisRefusal>[],
      duplicates = const <SyncDuplicateReport>[],
      replayed = 0,
      held = 0;

  final int batches;
  final int written;
  final int refused;
  final List<SilexgisRefusal> refusals;

  /// What was already on the server near a row this run **created**. Never a
  /// verdict: every row listed was written. Whether two are the same cave is
  /// the caver's decision, not the server's and not this client's.
  final List<SyncDuplicateReport> duplicates;

  /// Batches answered from a stored result rather than applied again — the
  /// answer to the first attempt was lost on the way back.
  final int replayed;

  /// Items this run's upload left waiting for a reviewer. Nothing of them was
  /// written.
  final int held;

  bool get isEmpty => batches == 0;
}

/// Sends what the builder chose, and applies what comes back.
class SilexgisUploadRunner {
  SilexgisUploadRunner({
    required SilexgisSyncApi api,
    required SilexgisUploadBuilder builder,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required String profileUuid,
    List<SilexgisUploadPart> parts = const <SilexgisUploadPart>[],
  }) : _api = api,
       _builder = builder,
       _localState = localState,
       _heldRows = heldRows,
       _profileUuid = profileUuid,
       _parts = parts;

  final SilexgisSyncApi _api;
  final SilexgisUploadBuilder _builder;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final String _profileUuid;

  /// The sections beside the feature rows, each built and answered by its
  /// own part. Only the parts the installation serves this run are passed.
  final List<SilexgisUploadPart> _parts;
  final _log = AppLogger.of('SilexgisUploadRunner');

  Future<SilexgisUploadReport> run(
    String setId, {
    required SilexgisCapabilities capabilities,
  }) async {
    final pending = await _builder.build();
    final items = <SyncUploadSection, List<Object>>{
      SyncUploadSection.rows: pending,
      for (final part in _parts) part.section: await part.build(),
    };
    if (items.values.every((i) => i.isEmpty)) {
      return const SilexgisUploadReport.nothingToSend();
    }

    var batches = 0;
    var written = 0;
    var refused = 0;
    var replayed = 0;
    var held = 0;
    final refusals = <SilexgisRefusal>[];
    final duplicates = <SyncDuplicateReport>[];

    Future<Map<SyncUploadSection, List<SyncUploadItem>>> send(
      Map<SyncUploadSection, List<Object>> items, {
      required bool resent,
    }) async {
      final again = <SyncUploadSection, List<SyncUploadItem>>{};
      // A batch above the installation's ceiling is refused whole, before a
      // single item is looked at, so the split happens here rather than being
      // discovered from a refusal. Sections are taken in the server's apply
      // order, so an item never lands in an earlier batch than one it names.
      final chunks = chunkUploadSections<Object>(
        items,
        capabilities.uploadRowsMax,
      );
      for (final chunk in chunks) {
        final rows =
            chunk[SyncUploadSection.rows]?.cast<PendingUploadRow>() ??
            const <PendingUploadRow>[];
        // Each part is its own attempt and gets its own identifier: a batch
        // identifier stands for one attempt, and reusing one for different
        // items would have the server answer with the wrong stored result.
        final batch = SyncUploadBatch(
          batchId: Uuid.v7().toString(),
          clientFeatures: SilexgisContract.clientFeatures,
          rows: rows.map((p) => p.row).toList(growable: false),
          sections: <SyncUploadSection, List<SyncUploadItem>>{
            for (final part in _parts)
              if (chunk[part.section] case final sent?)
                part.section: sent.cast<SyncUploadItem>(),
          },
        );
        final result = await _api.upload(setId, batch);
        batches++;
        if (result.replayed) replayed++;

        written += result.written;
        refused += result.refused;
        duplicates.addAll(result.duplicates);
        if (rows.isNotEmpty) {
          held += result.rows
              .where((r) => r.status == SyncRowStatus.held)
              .length;
          refusals.addAll(await _applyAnswers(rows, result));
        }
        for (final part in _parts) {
          final sent = batch.sections[part.section];
          if (sent == null) continue;
          final answers = await part.apply(
            sent,
            result.answersFor(part.section) ?? const <SyncRowResult>[],
            resent: resent,
          );
          held += answers.held;
          refusals.addAll(answers.refusals);
          if (answers.resend.isNotEmpty) {
            (again[part.section] ??= <SyncUploadItem>[]).addAll(answers.resend);
          }
        }
      }
      return again;
    }

    final again = await send(items, resent: false);
    // An item answered with what to change goes once more, changed, in this
    // run. Once: a second refusal is reported rather than looped on.
    if (again.isNotEmpty) await send(again, resent: true);

    return SilexgisUploadReport(
      batches: batches,
      written: written,
      refused: refused,
      refusals: refusals,
      duplicates: duplicates,
      replayed: replayed,
      held: held,
    );
  }

  /// Stores each row's verdict.
  ///
  /// A verdict rides a `200` and is per row: a device that edited forty caves
  /// offline and lost one to a conflict keeps the other thirty-nine.
  Future<List<SilexgisRefusal>> _applyAnswers(
    List<PendingUploadRow> sent,
    SyncUploadResult result,
  ) async {
    final byId = <String, PendingUploadRow>{
      for (final row in sent) row.row.id: row,
    };
    final revisions = <SilexgisRevisionEntry>[];
    final forgotten = <Uuid>[];
    final refusals = <SilexgisRefusal>[];
    final heldNow = <SilexgisHeldEntry>[];
    // Any other answer is the row's news now, whatever an earlier review said.
    final answeredOtherwise = <Uuid>[];

    for (final answer in result.rows) {
      final sentRow = byId[answer.id];
      if (sentRow == null) {
        _log.warning(
          'the answer names a row this batch did not send: '
          '${answer.id}',
        );
        continue;
      }

      if (answer.status != SyncRowStatus.held) {
        answeredOtherwise.add(sentRow.entityUuid);
      }
      switch (answer.status) {
        case SyncRowStatus.created:
        case SyncRowStatus.updated:
        case SyncRowStatus.unchanged:
          final revision = answer.revision;
          if (revision != null) {
            revisions.add(
              SilexgisRevisionEntry(
                entityUuid: sentRow.entityUuid,
                entityTable: sentRow.entityTable,
                wireKind: sentRow.row.kind.wireName,
                localUpdatedAt: sentRow.localUpdatedAt,
                revision: revision,
              ),
            );
          }
        case SyncRowStatus.deleted:
          // The row is gone there and gone here. Dropping the revision is what
          // stops the same tombstone going up again for ever, and makes the
          // identifier new to this installation if the caver recreates it.
          forgotten.add(sentRow.entityUuid);
        case SyncRowStatus.held:
          // Nothing was written, so the revision stays what it was and the
          // local edit stays unsent. What is recorded is the stamp it was sent
          // at, so it is not sent again until the caver edits it.
          final reviewId = answer.reviewId;
          if (reviewId == null) {
            _log.warning('a held answer named no review: ${answer.id}');
            break;
          }
          heldNow.add(
            SilexgisHeldEntry(
              section: SyncUploadSection.rows,
              entityUuid: sentRow.entityUuid,
              entityTable: sentRow.entityTable,
              wireKind: sentRow.row.kind.wireName,
              reviewId: reviewId,
              isDelete: sentRow.isDelete,
              sentLocalUpdatedAt: sentRow.localUpdatedAt,
            ),
          );
        case SyncRowStatus.conflict:
        case SyncRowStatus.rejected:
        case null:
          refusals.add(
            SilexgisRefusal(
              entityUuid: sentRow.entityUuid,
              entityTable: sentRow.entityTable,
              result: answer,
              serverRow: result.conflictFor(answer.id),
            ),
          );
      }
    }

    await _localState.writeRevisions(_profileUuid, revisions);
    await _localState.forgetRevisions(_profileUuid, forgotten);
    await _heldRows.clear(
      _profileUuid,
      SyncUploadSection.rows,
      answeredOtherwise,
    );
    await _heldRows.recordHeld(_profileUuid, heldNow);
    return refusals;
  }
}
