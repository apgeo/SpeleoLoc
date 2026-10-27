import 'dart:io';

import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_file_transfer.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_staged_upload_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_transfer_api.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/clock.dart';

/// One file whose bytes are to be staged.
class SilexgisStageRequest {
  const SilexgisStageRequest({
    required this.documentUuid,
    required this.file,
    required this.fileName,
    required this.sha256,
    required this.sizeBytes,
  });

  final Uuid documentUuid;
  final File file;

  /// The name the transfer opens with — at most 255 characters.
  final String fileName;

  /// The phone's own hash of the file, lower-case hex.
  final String sha256;
  final int sizeBytes;
}

/// What staging one file came to.
enum SilexgisStageOutcome {
  /// The bytes wait under [SilexgisStageResult.transferId].
  staged,

  /// Larger than the installation accepts.
  tooLarge,

  /// A type the installation refuses.
  typeRefused,

  /// Not enough room left for this account, or for the installation.
  quotaExceeded,

  /// This account may not add documents at all.
  forbidden,

  /// The file changed while it was read, or the server holds other bytes
  /// than were sent.
  hashMismatch,

  /// The transfer stopped — usually the connection. What arrived stays, and
  /// the next run resumes from there.
  interrupted,
}

class SilexgisStageResult {
  const SilexgisStageResult(this.outcome, {this.transferId, this.detail});

  final SilexgisStageOutcome outcome;

  /// The staged upload a document row names, when [outcome] is staged.
  final String? transferId;
  final String? detail;

  bool get isStaged => outcome == SilexgisStageOutcome.staged;
}

/// Sends a documentation file's bytes ahead of the upload that names them.
///
/// The bytes travel through the installation's ordinary resumable transfer:
/// opened with `stageForSync`, sent in order a piece at a time, completed, and
/// the server's hash compared with the phone's own. Where a transfer got to is
/// kept locally after every piece, so a dropped run resumes from what the
/// server says it holds rather than starting again; bytes already staged and
/// still waiting are named again rather than sent again. A transfer the
/// server no longer knows — withdrawn, or past its retention — is opened anew.
///
/// The installation's limits are read once, before the first transfer opens,
/// so a file that cannot fit is not started; after a refusal for room, no
/// further transfer opens in this run.
class SilexgisFileStager {
  SilexgisFileStager({
    required SilexgisTransferApi api,
    required SilexgisStagedUploadRepository staged,
    required String profileUuid,
    Clock clock = const SystemClock(),
  }) : _api = api,
       _staged = staged,
       _profileUuid = profileUuid,
       _clock = clock;

  final SilexgisTransferApi _api;
  final SilexgisStagedUploadRepository _staged;
  final String _profileUuid;
  final Clock _clock;
  final _log = AppLogger.of('SilexgisFileStager');

  /// How often one file is sent from the start again in one call — after its
  /// transfer vanished, or its bytes came out different.
  static const int maxRestarts = 1;

  /// How often in a row the server may say a piece is out of place before the
  /// transfer is given up for this run.
  static const int maxRealignments = 3;

  /// The piece size when the server names none.
  static const int defaultChunkBytes = 8 * 1024 * 1024;

  SilexgisFilesConfig? _config;
  int? _room;
  bool _roomExhausted = false;

  /// Stages [request], reusing or resuming what an earlier run left.
  Future<SilexgisStageResult> stage(SilexgisStageRequest request) async {
    try {
      return await _stage(request, restarts: 0);
    } on SilexgisException catch (e) {
      // What arrived stays recorded; the next run resumes from the server's
      // own count. A refusal no step above answers is this file's alone, and
      // the rows that need no file still go.
      return SilexgisStageResult(
        SilexgisStageOutcome.interrupted,
        detail: e.message,
      );
    }
  }

  /// Forgets the staged bytes of [documentUuid], so the next [stage] sends
  /// them again — the answer to a row refused for bytes the server no longer
  /// holds.
  Future<void> forget(Uuid documentUuid) =>
      _staged.delete(_profileUuid, documentUuid);

  Future<SilexgisStageResult> _stage(
    SilexgisStageRequest request, {
    required int restarts,
  }) async {
    var upload = await _staged.read(_profileUuid, request.documentUuid);
    if (upload != null &&
        (upload.sha256 != request.sha256 ||
            upload.sizeBytes != request.sizeBytes ||
            upload.state == SilexgisStagedState.adopted)) {
      // Other bytes than these — the file changed since — or bytes already
      // spent on an earlier revision. Neither can be named for this one.
      if (upload.state != SilexgisStagedState.adopted) {
        await _withdraw(upload.transferId);
      }
      upload = null;
    }

    if (upload != null && upload.expiredAt(_clock.now())) {
      // Gone, or about to go, even before the server's sweep has run.
      upload = null;
    }

    SilexgisTransfer? transfer;
    if (upload?.transferId case final id?) {
      transfer = await _statusOrNull(id);
      if (transfer == null) upload = null;
    }

    if (upload != null && transfer != null && transfer.isStaged) {
      if ((transfer.sha256 ?? '').toLowerCase() == request.sha256) {
        return SilexgisStageResult(
          SilexgisStageOutcome.staged,
          transferId: transfer.id,
        );
      }
      await _withdraw(transfer.id);
      upload = null;
      transfer = null;
    }

    if (upload == null || transfer == null) {
      final refused = await _refuseBeforeOpening(request);
      if (refused != null) return refused;
      final SilexgisTransfer opened;
      try {
        opened = await _api.open(
          fileName: request.fileName,
          sizeBytes: request.sizeBytes,
        );
      } on SilexgisProblemException catch (e) {
        return _openRefused(e);
      }
      if (_room != null) _room = _room! - request.sizeBytes;
      transfer = opened;
      upload = SilexgisStagedFile(
        documentUuid: request.documentUuid,
        sha256: request.sha256,
        sizeBytes: request.sizeBytes,
        state: SilexgisStagedState.sending,
        transferId: opened.id,
        receivedBytes: opened.receivedBytes,
        expiresAt: opened.expiresAt,
      );
      await _staged.write(_profileUuid, upload);
    }

    final SilexgisStagedBytes completed;
    try {
      upload = await _sendPieces(request, upload, transfer);
      completed = await _complete(request, upload);
    } on SilexgisProblemException catch (e) {
      if (e.code == SilexgisCodes.sessionNotFound && restarts < maxRestarts) {
        await _staged.delete(_profileUuid, request.documentUuid);
        return _stage(request, restarts: restarts + 1);
      }
      if (e.code == SilexgisCodes.sessionNotFound) {
        await _staged.delete(_profileUuid, request.documentUuid);
      }
      return SilexgisStageResult(
        SilexgisStageOutcome.interrupted,
        detail: e.problem.detail ?? e.code,
      );
    } on _Misaligned catch (e) {
      return SilexgisStageResult(
        SilexgisStageOutcome.interrupted,
        detail: e.detail,
      );
    }

    if (completed.sha256 != request.sha256) {
      // The bytes on the server are not the file's: it changed while it was
      // read, or a piece went wrong. Never named by a row as they are.
      _log.warning('staged bytes do not match the file they were read from');
      await _withdraw(completed.id);
      await _staged.delete(_profileUuid, request.documentUuid);
      if (restarts < maxRestarts) {
        return _stage(request, restarts: restarts + 1);
      }
      return const SilexgisStageResult(SilexgisStageOutcome.hashMismatch);
    }

    await _staged.write(
      _profileUuid,
      upload.copyWith(
        state: SilexgisStagedState.staged,
        receivedBytes: request.sizeBytes,
        expiresAt: completed.expiresAt,
      ),
    );
    return SilexgisStageResult(
      SilexgisStageOutcome.staged,
      transferId: completed.id,
    );
  }

  /// The checks the installation's limits allow before a byte moves.
  Future<SilexgisStageResult?> _refuseBeforeOpening(
    SilexgisStageRequest request,
  ) async {
    if (_roomExhausted) {
      return const SilexgisStageResult(SilexgisStageOutcome.quotaExceeded);
    }
    final config = _config ??= await _api.config();
    _room ??= config.remainingBytes;
    if (config.maxUploadBytes > 0 &&
        request.sizeBytes > config.maxUploadBytes) {
      return const SilexgisStageResult(SilexgisStageOutcome.tooLarge);
    }
    if (_room != null && request.sizeBytes > _room!) {
      return const SilexgisStageResult(SilexgisStageOutcome.quotaExceeded);
    }
    return null;
  }

  SilexgisStageResult _openRefused(SilexgisProblemException e) {
    switch (e.code) {
      case SilexgisCodes.quotaExceeded:
        _roomExhausted = true;
        return const SilexgisStageResult(SilexgisStageOutcome.quotaExceeded);
      case SilexgisCodes.fileTooLarge:
        return const SilexgisStageResult(SilexgisStageOutcome.tooLarge);
      case SilexgisCodes.fileTypeNotAccepted:
        return const SilexgisStageResult(SilexgisStageOutcome.typeRefused);
      case SilexgisCodes.createForbidden:
        return const SilexgisStageResult(SilexgisStageOutcome.forbidden);
    }
    throw e;
  }

  /// Sends what the server does not hold yet, in order, recording progress
  /// after every piece.
  Future<SilexgisStagedFile> _sendPieces(
    SilexgisStageRequest request,
    SilexgisStagedFile upload,
    SilexgisTransfer transfer,
  ) async {
    final id = transfer.id;
    final chunk = _chunkBytes(transfer);
    var offset = transfer.receivedBytes;
    var realignments = 0;
    final file = await request.file.open();
    try {
      while (offset < request.sizeBytes) {
        final length = offset + chunk > request.sizeBytes
            ? request.sizeBytes - offset
            : chunk;
        await file.setPosition(offset);
        final bytes = await file.read(length);
        final SilexgisTransfer answer;
        try {
          answer = await _api.sendPiece(id, offset: offset, bytes: bytes);
        } on SilexgisProblemException catch (e) {
          if (e.code != SilexgisCodes.chunkOutOfOrder) rethrow;
          // Where to resume is asked for rather than read out of the
          // detail, which is a sentence for a human.
          if (++realignments > maxRealignments) {
            throw const _Misaligned('the transfer kept losing its place');
          }
          offset = (await _api.status(id)).receivedBytes;
          continue;
        }
        if (answer.receivedBytes <= offset) {
          throw const _Misaligned('the server did not take the piece');
        }
        realignments = 0;
        offset = answer.receivedBytes;
        upload = upload.copyWith(
          receivedBytes: offset,
          expiresAt: answer.expiresAt,
        );
        await _staged.write(_profileUuid, upload);
      }
    } finally {
      await file.close();
    }
    return upload;
  }

  /// Completes the transfer. Bytes still missing — a piece that did not
  /// survive — are sent first, once.
  Future<SilexgisStagedBytes> _complete(
    SilexgisStageRequest request,
    SilexgisStagedFile upload,
  ) async {
    final id = upload.transferId!;
    try {
      return await _api.complete(id);
    } on SilexgisProblemException catch (e) {
      if (e.code != SilexgisCodes.uploadIncomplete) rethrow;
      final status = await _api.status(id);
      await _sendPieces(request, upload, status);
      return _api.complete(id);
    }
  }

  int _chunkBytes(SilexgisTransfer transfer) {
    final named = transfer.chunkBytes > 0
        ? transfer.chunkBytes
        : (_config?.chunkBytes ?? 0);
    return named > 0 ? named : defaultChunkBytes;
  }

  /// The transfer's state, or null when the server no longer has it.
  Future<SilexgisTransfer?> _statusOrNull(String transferId) async {
    try {
      return await _api.status(transferId);
    } on SilexgisProblemException catch (e) {
      if (e.code == SilexgisCodes.sessionNotFound) return null;
      rethrow;
    }
  }

  /// Withdraws bytes nothing will adopt, so they stop counting against the
  /// account's room. Best effort: they are swept at their expiry anyway.
  Future<void> _withdraw(String? transferId) async {
    if (transferId == null) return;
    try {
      await _api.withdraw(transferId);
    } on SilexgisException catch (e) {
      _log.fine('a staged transfer could not be withdrawn: ${e.message}');
    }
  }
}

/// The server and the device could not agree where the file stands.
class _Misaligned implements Exception {
  const _Misaligned(this.detail);
  final String detail;
}
