import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_row_composer.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_upload_planner.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_upload_run.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_sending_gate.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_stager.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_document_updater.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_staged_upload_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_runner.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// The `documents` section: documentation files new to the installation,
/// edited here, or removed here.
///
/// A row that brings new content has its bytes staged first, and goes up only
/// once they wait on the server under the hash the row states. Whether bytes
/// may go at all in this run is the gate's to say; when they may not, the
/// documents that need them wait, and every row that needs none still goes.
class SilexgisDocumentsUploadPart implements SilexgisUploadPart {
  SilexgisDocumentsUploadPart({
    required SilexgisDocumentUploadPlanner planner,
    required SilexgisDocumentUploadRun run,
    required SilexgisFileStager stager,
    required SilexgisFileSendingGate gate,
    required SilexgisStagedUploadRepository staged,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required Future<Directory> Function() baseDir,
    required String profileUuid,
    SilexgisDocumentRowComposer composer = const SilexgisDocumentRowComposer(),
  }) : _planner = planner,
       _run = run,
       _stager = stager,
       _gate = gate,
       _staged = staged,
       _localState = localState,
       _heldRows = heldRows,
       _baseDir = baseDir,
       _profileUuid = profileUuid,
       _composer = composer;

  final SilexgisDocumentUploadPlanner _planner;
  final SilexgisDocumentUploadRun _run;
  final SilexgisFileStager _stager;
  final SilexgisFileSendingGate _gate;
  final SilexgisStagedUploadRepository _staged;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final Future<Directory> Function() _baseDir;
  final String _profileUuid;
  final SilexgisDocumentRowComposer _composer;
  final _log = AppLogger.of('SilexgisDocumentsUploadPart');

  /// What was planned and what was staged, per document sent this run.
  final Map<String, SilexgisPlannedDocument> _planned =
      <String, SilexgisPlannedDocument>{};
  final Map<String, SilexgisStageRequest> _requests =
      <String, SilexgisStageRequest>{};

  static const String entityTable = SilexgisHeldDocumentUpdater.entityTable;
  static const String wireKind = SilexgisHeldDocumentUpdater.wireKind;

  @override
  SyncUploadSection get section => SyncUploadSection.documents;

  @override
  Future<List<SyncUploadItem>> build(SilexgisUploadContext context) async {
    final plan = _run.plan = await _planner.plan(context);

    var missing = 0;
    final needBytes = <SilexgisPlannedDocument>[];
    Directory? base;
    for (final document in plan.documents.where((d) => d.sendsBytes)) {
      base ??= await _baseDir();
      final file = File('${base.path}/${document.row!.fileName}');
      if (!await file.exists()) {
        _log.warning('a file to send is no longer on this device');
        missing++;
        _run.keptBack.add(document.id);
        continue;
      }
      needBytes.add(document);
      _requests[document.id.toString()] = SilexgisStageRequest(
        documentUuid: document.id,
        file: file,
        fileName: SilexgisDocumentRowComposer.fileNameOf(
          document.row!.fileName,
        ),
        sha256: (await sha256.bind(file.openRead()).first).toString(),
        sizeBytes: await file.length(),
      );
    }

    var waiting = 0;
    if (needBytes.isNotEmpty &&
        !await _gate.mayFilesGo(
          files: needBytes.length,
          bytes: needBytes.fold(
            0,
            (sum, d) => sum + _requests[d.id.toString()]!.sizeBytes,
          ),
        )) {
      waiting = needBytes.length;
      for (final document in needBytes) {
        _run.keptBack.add(document.id);
        _requests.remove(document.id.toString());
      }
      needBytes.clear();
    }

    var stagedCount = 0;
    var quota = 0;
    var tooLarge = 0;
    var typeRefused = 0;
    var failed = 0;
    final contents = <Uuid, SilexgisStagedContent>{};
    for (final document in needBytes) {
      final request = _requests[document.id.toString()]!;
      final result = await _stager.stage(request);
      switch (result.outcome) {
        case SilexgisStageOutcome.staged:
          stagedCount++;
          contents[document.id] = SilexgisStagedContent(
            transferId: result.transferId!,
            sha256: request.sha256,
            sizeBytes: request.sizeBytes,
          );
          continue;
        case SilexgisStageOutcome.quotaExceeded:
          quota++;
        case SilexgisStageOutcome.tooLarge:
          tooLarge++;
        case SilexgisStageOutcome.typeRefused:
          typeRefused++;
        case SilexgisStageOutcome.forbidden:
        case SilexgisStageOutcome.hashMismatch:
        case SilexgisStageOutcome.interrupted:
          failed++;
      }
      _run.keptBack.add(document.id);
    }
    _run.files = SilexgisFilesReport(
      staged: stagedCount,
      waitingForNetwork: waiting,
      quotaExceeded: quota,
      tooLarge: tooLarge,
      typeRefused: typeRefused,
      missing: missing,
      failed: failed,
    );

    final items = <SyncUploadItem>[];
    for (final document in plan.documents) {
      if (_run.keptBack.contains(document.id)) continue;
      final row = _composer.compose(document, content: contents[document.id]);
      if (row == null) {
        _run.keptBack.add(document.id);
        continue;
      }
      _planned[row.id] = document;
      // Named as its author, so the people part describes them in this run.
      if (row.createdByDeviceUserId != null) {
        if (document.row?.createdByUserUuid case final author?) {
          context.authors.add(author);
        }
      }
      items.add(row);
    }
    return items;
  }

  @override
  Future<SilexgisPartAnswers> apply(
    List<SyncUploadItem> sent,
    List<SyncRowResult> answers, {
    required bool resent,
  }) async {
    final byId = <String, SyncUploadDocument>{
      for (final item in sent.whereType<SyncUploadDocument>()) item.id: item,
    };
    final revisions = <SilexgisRevisionEntry>[];
    final forgotten = <Uuid>[];
    final heldNow = <SilexgisHeldEntry>[];
    final conflicts = <SilexgisConflictEntry>[];
    final answeredOtherwise = <Uuid>[];
    final refusals = <SilexgisRefusal>[];
    final resend = <SyncUploadItem>[];
    var held = 0;

    for (final answer in answers) {
      final item = byId[answer.id];
      final document = _planned[answer.id];
      if (item == null || document == null) {
        _log.warning('the answer names a document this batch did not send');
        continue;
      }
      final stamp = document.row?.updatedAt;
      if (answer.status != SyncRowStatus.held) {
        answeredOtherwise.add(document.id);
      }

      switch (answer.status) {
        case SyncRowStatus.created:
        case SyncRowStatus.updated:
        case SyncRowStatus.unchanged:
          if (item.deleted) {
            forgotten.add(document.id);
            break;
          }
          if (answer.revision case final revision?) {
            revisions.add(
              SilexgisRevisionEntry(
                entityUuid: document.id,
                entityTable: entityTable,
                wireKind: wireKind,
                revision: revision,
                localUpdatedAt: stamp,
              ),
            );
          }
          if (item.stagedUploadId case final transferId?) {
            await _staged.markAdopted(_profileUuid, document.id, transferId);
          }
        case SyncRowStatus.deleted:
          forgotten.add(document.id);
        case SyncRowStatus.held:
          held++;
          final reviewId = answer.reviewId;
          if (reviewId == null) {
            _log.warning('a held answer named no review: ${answer.id}');
            break;
          }
          // The staged bytes wait on the server with the proposal.
          heldNow.add(
            SilexgisHeldEntry(
              section: section,
              entityUuid: document.id,
              entityTable: entityTable,
              wireKind: wireKind,
              reviewId: reviewId,
              isDelete: item.deleted,
              sentLocalUpdatedAt: stamp,
            ),
          );
        case SyncRowStatus.rejected
            when !resent &&
                (answer.code == SilexgisCodes.fileBytesMissing ||
                    answer.code == SilexgisCodes.fileHashMismatch):
          final again = await _restage(item);
          if (again != null) {
            _run.resent.add(document.id);
            resend.add(again);
            break;
          }
          refusals.add(_refusal(document, answer));
        case SyncRowStatus.rejected
            when answer.code == SilexgisCodes.rowNotFound:
          // Not there after all: forgotten, it goes as a new document next
          // time, bytes and all.
          forgotten.add(document.id);
          refusals.add(_refusal(document, answer));
        case SyncRowStatus.conflict:
          // Somebody wrote the document, or gave it new bytes, since: kept for
          // the caver to settle rather than sent against the same revision
          // again.
          conflicts.add(
            SilexgisConflictEntry(
              section: section,
              entityUuid: document.id,
              entityTable: entityTable,
              wireKind: wireKind,
              code: answer.code ?? SilexgisCodes.conflict,
              isDelete: item.deleted,
              sentLocalUpdatedAt: stamp,
            ),
          );
          refusals.add(_refusal(document, answer));
        case SyncRowStatus.rejected:
        case null:
          refusals.add(_refusal(document, answer));
      }
    }

    await _localState.writeRevisions(_profileUuid, revisions);
    await _localState.forgetRevisions(_profileUuid, forgotten);
    for (final id in forgotten) {
      await _staged.delete(_profileUuid, id);
    }
    await _heldRows.clear(_profileUuid, section, answeredOtherwise);
    await _heldRows.recordHeld(_profileUuid, heldNow);
    await _heldRows.recordConflicts(_profileUuid, conflicts);
    return SilexgisPartAnswers(refusals: refusals, resend: resend, held: held);
  }

  /// The row again, naming freshly staged bytes, or null when they could not
  /// be staged or the row brought none.
  Future<SyncUploadDocument?> _restage(SyncUploadDocument item) async {
    final request = _requests[item.id];
    if (request == null) return null;
    await _stager.forget(request.documentUuid);
    final result = await _stager.stage(request);
    if (!result.isStaged) return null;
    return item.withStagedUpload(result.transferId!);
  }

  SilexgisRefusal _refusal(
    SilexgisPlannedDocument document,
    SyncRowResult answer,
  ) => SilexgisRefusal(
    entityUuid: document.id,
    entityTable: entityTable,
    result: answer,
  );
}
