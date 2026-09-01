import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_feature_row.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_batch.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_builder.dart';
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
  });

  const SilexgisUploadReport.nothingToSend()
    : batches = 0,
      written = 0,
      refused = 0,
      refusals = const <SilexgisRefusal>[],
      duplicates = const <SyncDuplicateReport>[],
      replayed = 0;

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

  bool get isEmpty => batches == 0;
}

/// Sends what the builder chose, and applies what comes back.
class SilexgisUploadRunner {
  SilexgisUploadRunner({
    required SilexgisSyncApi api,
    required SilexgisUploadBuilder builder,
    required SilexgisLocalStateRepository localState,
    required String profileUuid,
  }) : _api = api,
       _builder = builder,
       _localState = localState,
       _profileUuid = profileUuid;

  final SilexgisSyncApi _api;
  final SilexgisUploadBuilder _builder;
  final SilexgisLocalStateRepository _localState;
  final String _profileUuid;
  final _log = AppLogger.of('SilexgisUploadRunner');

  Future<SilexgisUploadReport> run(
    String setId, {
    required SilexgisCapabilities capabilities,
  }) async {
    final pending = await _builder.build();
    if (pending.isEmpty) return const SilexgisUploadReport.nothingToSend();

    var written = 0;
    var refused = 0;
    var replayed = 0;
    final refusals = <SilexgisRefusal>[];
    final duplicates = <SyncDuplicateReport>[];
    final chunks = _split(pending, capabilities.uploadRowsMax);

    for (final chunk in chunks) {
      // Each part is its own attempt and gets its own identifier: a batch
      // identifier stands for one attempt, and reusing one for different rows
      // would have the server answer with the wrong stored result.
      final batch = SyncUploadBatch(
        batchId: Uuid.v7().toString(),
        rows: chunk.map((p) => p.row).toList(growable: false),
      );
      final result = await _api.upload(setId, batch);
      if (result.replayed) replayed++;

      written += result.written;
      refused += result.refused;
      duplicates.addAll(result.duplicates);
      refusals.addAll(await _applyAnswers(chunk, result));
    }

    return SilexgisUploadReport(
      batches: chunks.length,
      written: written,
      refused: refused,
      refusals: refusals,
      duplicates: duplicates,
      replayed: replayed,
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

    for (final answer in result.rows) {
      final sentRow = byId[answer.id];
      if (sentRow == null) {
        _log.warning(
          'the answer names a row this batch did not send: '
          '${answer.id}',
        );
        continue;
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
    return refusals;
  }

  /// Splits into parts no larger than the installation's ceiling.
  ///
  /// A batch above it is refused whole, before a single row is looked at, so
  /// the split happens here rather than being discovered from a refusal.
  static List<List<PendingUploadRow>> _split(
    List<PendingUploadRow> rows,
    int max,
  ) {
    final limit = max > 0 ? max : rows.length;
    return <List<PendingUploadRow>>[
      for (var i = 0; i < rows.length; i += limit)
        rows.sublist(i, i + limit > rows.length ? rows.length : i + limit),
    ];
  }
}
