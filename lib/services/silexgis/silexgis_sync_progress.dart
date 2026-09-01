import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/silexgis_download_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_runner.dart';

/// Where a run has got to.
enum SilexgisSyncPhase {
  /// Nothing in flight. Also the state of a device with no server configured,
  /// which is the ordinary case and not a fault.
  idle,

  /// Restoring or renewing the stored credential.
  authenticating,

  /// Asking what this installation can do, and whether it still speaks the
  /// version this build is pinned to.
  askingCapabilities,

  /// Reading the set, a page at a time.
  downloading,

  /// Sending what changed here.
  uploading,

  completed,

  /// The run stopped. [SilexgisSyncProgress.action] says what, if anything,
  /// moves it forward.
  failed,
}

/// An immutable snapshot of a run, emitted on every meaningful change.
class SilexgisSyncProgress {
  const SilexgisSyncProgress({
    required this.phase,
    this.message = '',
    this.pagesRead = 0,
    this.rowsApplied = 0,
    this.rowsDeleted = 0,
    this.rowsSent = 0,
    this.download,
    this.upload,
    this.action,
    this.code,
  });

  const SilexgisSyncProgress.idle() : this(phase: SilexgisSyncPhase.idle);

  final SilexgisSyncPhase phase;

  /// What to show the caver. On a failure it is the server's own sentence
  /// where there is one — never a diagnosis this client invented.
  final String message;

  final int pagesRead;
  final int rowsApplied;
  final int rowsDeleted;
  final int rowsSent;

  /// Present once the read has finished.
  final SilexgisDownloadReport? download;

  /// Present once the write has finished.
  final SilexgisUploadReport? upload;

  /// The one action that moves a failure forward, from the closed set the
  /// contract defines. Null while a run is healthy.
  final SilexgisAction? action;

  /// The server's stable code, when it named one. A `401` and the QR route's
  /// `429` carry none, which is why [action] is the thing to branch on.
  final String? code;

  bool get isRunning =>
      phase != SilexgisSyncPhase.idle &&
      phase != SilexgisSyncPhase.completed &&
      phase != SilexgisSyncPhase.failed;

  /// Rows the server would not take, for the caver to look at.
  List<SilexgisRefusal> get refusals =>
      upload?.refusals ?? const <SilexgisRefusal>[];

  /// True when the caver has something to decide: a row was refused, a
  /// conflict needs merging, or something was carried and not stored.
  bool get needsAttention =>
      refusals.isNotEmpty ||
      (download?.unresolved.isNotEmpty ?? false) ||
      (upload?.duplicates.isNotEmpty ?? false);

  SilexgisSyncProgress copyWith({
    SilexgisSyncPhase? phase,
    String? message,
    int? pagesRead,
    int? rowsApplied,
    int? rowsDeleted,
    int? rowsSent,
    SilexgisDownloadReport? download,
    SilexgisUploadReport? upload,
    SilexgisAction? action,
    String? code,
  }) => SilexgisSyncProgress(
    phase: phase ?? this.phase,
    message: message ?? this.message,
    pagesRead: pagesRead ?? this.pagesRead,
    rowsApplied: rowsApplied ?? this.rowsApplied,
    rowsDeleted: rowsDeleted ?? this.rowsDeleted,
    rowsSent: rowsSent ?? this.rowsSent,
    download: download ?? this.download,
    upload: upload ?? this.upload,
    action: action ?? this.action,
    code: code ?? this.code,
  );
}
