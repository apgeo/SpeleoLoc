import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_upload_planner.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_upload_run.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_link_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_runner.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// The `documentLinks` section: where documents hang, and where they no
/// longer do.
///
/// Built after the `documents` part, from the same plan: a new link waits
/// with a document that waits. Answers come in the order the links were
/// sent, under the link's own identifier — which is what a later removal
/// names — so they are matched by position, not by identifier.
class SilexgisDocumentLinksUploadPart implements SilexgisUploadPart {
  SilexgisDocumentLinksUploadPart({
    required SilexgisDocumentUploadRun run,
    required SilexgisServerLinkRepository serverLinks,
    required SilexgisHeldRowRepository heldRows,
    required String profileUuid,
  }) : _run = run,
       _serverLinks = serverLinks,
       _heldRows = heldRows,
       _profileUuid = profileUuid;

  final SilexgisDocumentUploadRun _run;
  final SilexgisServerLinkRepository _serverLinks;
  final SilexgisHeldRowRepository _heldRows;
  final String _profileUuid;
  final _log = AppLogger.of('SilexgisDocumentLinksUploadPart');

  final Map<SyncUploadDocumentLink, SilexgisPlannedLink> _planned =
      Map<SyncUploadDocumentLink, SilexgisPlannedLink>.identity();

  @override
  SyncUploadSection get section => SyncUploadSection.documentLinks;

  @override
  Future<List<SyncUploadItem>> build(SilexgisUploadContext context) async {
    final items = <SyncUploadItem>[];
    for (final link in _run.plan.links) {
      // A removal goes whatever became of the document; a new link only
      // with a document that is there or goes now.
      if (!link.isDelete && _run.keptBack.contains(link.documentId)) continue;
      final item = _itemOf(link);
      _planned[item] = link;
      items.add(item);
    }
    return items;
  }

  @override
  Future<SilexgisPartAnswers> apply(
    List<SyncUploadItem> sent,
    List<SyncRowResult> answers, {
    required bool resent,
  }) async {
    if (answers.length != sent.length) {
      _log.warning(
        'the links were answered ${answers.length} times for ${sent.length}',
      );
    }
    final refusals = <SilexgisRefusal>[];
    final resend = <SyncUploadItem>[];
    final heldNow = <SilexgisHeldEntry>[];
    final conflicts = <SilexgisConflictEntry>[];
    final answeredOtherwise = <Uuid>[];
    var held = 0;

    for (var i = 0; i < sent.length && i < answers.length; i++) {
      final item = sent[i];
      final link = item is SyncUploadDocumentLink ? _planned[item] : null;
      if (link == null) continue;
      final answer = answers[i];
      final local = link.local;
      if (local != null && answer.status != SyncRowStatus.held) {
        answeredOtherwise.add(local.uuid);
      }

      switch (answer.status) {
        case SyncRowStatus.created:
        case SyncRowStatus.updated:
        case SyncRowStatus.unchanged:
        case SyncRowStatus.deleted:
          await _settle(link, answer.id);
        case SyncRowStatus.held:
          held++;
          final reviewId = answer.reviewId;
          // A removal held for review is simply sent again until decided:
          // the same proposal is answered with the same review.
          if (local == null || reviewId == null) break;
          heldNow.add(
            SilexgisHeldEntry(
              section: section,
              entityUuid: local.uuid,
              entityTable: local.table,
              reviewId: reviewId,
              sentLocalUpdatedAt: local.updatedAt,
            ),
          );
        case SyncRowStatus.rejected
            when link.isDelete &&
                (answer.code == SilexgisCodes.documentUnavailable ||
                    answer.code == SilexgisCodes.targetNotFound):
          // The document or the target went, and the link with it.
          await _serverLinks.forget(_profileUuid, <SilexgisLinkKey>[link.key]);
        case SyncRowStatus.rejected
            when !resent &&
                answer.code == SilexgisCodes.documentUnavailable &&
                _run.resent.contains(link.documentId):
          // Its document goes once more in this run; so does the link.
          resend.add(item);
        case SyncRowStatus.conflict when local != null:
          conflicts.add(
            SilexgisConflictEntry(
              section: section,
              entityUuid: local.uuid,
              entityTable: local.table,
              code: answer.code ?? SilexgisCodes.conflict,
              sentLocalUpdatedAt: local.updatedAt,
            ),
          );
          refusals.add(
            SilexgisRefusal(
              entityUuid: local.uuid,
              entityTable: local.table,
              result: answer,
            ),
          );
        case SyncRowStatus.rejected:
        case SyncRowStatus.conflict:
        case null:
          refusals.add(
            SilexgisRefusal(
              entityUuid: local?.uuid ?? link.documentId,
              entityTable:
                  local?.table ?? SilexgisDocumentUploadPlanner.linkTable,
              result: answer,
            ),
          );
      }
    }

    await _heldRows.clear(_profileUuid, section, answeredOtherwise);
    await _heldRows.recordHeld(_profileUuid, heldNow);
    await _heldRows.recordConflicts(_profileUuid, conflicts);
    return SilexgisPartAnswers(refusals: refusals, resend: resend, held: held);
  }

  /// Records what the installation now holds: the link under the identifier
  /// it answered with, or nothing once it is down.
  Future<void> _settle(SilexgisPlannedLink link, String linkId) async {
    if (link.isDelete) {
      await _serverLinks.forget(_profileUuid, <SilexgisLinkKey>[link.key]);
      return;
    }
    await _serverLinks.record(
      _profileUuid,
      SilexgisServerLinkEntry(
        documentUuid: link.documentId,
        targetKind: link.targetKind,
        targetId: link.targetId,
        linkId: linkId,
      ),
    );
  }

  static SyncUploadDocumentLink _itemOf(SilexgisPlannedLink link) =>
      SyncUploadDocumentLink(
        documentId: link.documentId.toString(),
        targetKind: link.targetKind,
        targetId: link.targetId.toString(),
        deleted: link.isDelete,
      );
}
