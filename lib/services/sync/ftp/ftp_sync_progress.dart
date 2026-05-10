/// Lifecycle phases of a running FTP sync pass.
///
/// The numeric ordering matches the typical execution order so the drawer
/// progress card can derive an overall "step i of N" indicator.
enum FtpSyncPhase {
  /// No sync in flight.
  idle,

  /// Opening TCP/TLS/SSH connection and authenticating.
  connecting,

  /// Listing the remote folder to discover peer archives.
  listing,

  /// Downloading one of the unseen peer archives.
  downloading,

  /// Importing a downloaded archive into the local database.
  importing,

  /// Generating a fresh local archive reflecting the merged state.
  generatingArchive,

  /// Uploading the fresh local archive back to the remote.
  uploading,

  /// Cleanup (disconnect, persist seen-archive state, delete temp files).
  finalizing,

  /// Last sync finished successfully. Next [start] resets to [idle].
  completed,

  /// Last sync aborted due to an error. See `errorMessage` for details.
  failed,

  /// Last sync was cancelled by the user.
  cancelled,

  /// Run is paused between steps. The current file/step was rolled back and
  /// will be restarted from the beginning on resume. Set by
  /// `FtpSyncController.pause()`.
  paused,
}

/// Severity of a log line emitted during sync. Used by the detail screen's
/// log tab (phase C) and for the drawer's last-message line.
enum FtpSyncLogLevel { debug, info, warning, error }

/// A single timestamped event on the sync timeline.
class FtpSyncLogEntry {
  final DateTime timestamp;
  final FtpSyncLogLevel level;
  final String message;

  /// When true this entry is a visual separator between two sync sessions,
  /// not a real log message. The [level] and [message] fields are ignored
  /// by the UI for separator entries.
  final bool isSeparator;

  const FtpSyncLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.isSeparator = false,
  });
}

/// Immutable snapshot of in-flight progress. A new instance is emitted by
/// `FtpSyncController` on every meaningful change.
///
/// Keep this class cheap to construct — it is produced many times per second
/// during large transfers.
class FtpSyncProgress {
  final FtpSyncPhase phase;

  /// Progress within the *current* step, 0.0..1.0. When the step has no
  /// measurable progress (e.g. listing), this stays at 0.
  final double stepProgress;

  /// Cumulative bytes transferred for the current file, when applicable.
  final int bytesTransferred;

  /// File size in bytes, when known.
  final int? totalBytes;

  /// Filename currently being uploaded/downloaded, when applicable.
  final String? currentFileName;

  /// How many peer archives have been fully downloaded+imported so far.
  final int archivesProcessed;

  /// Total peer archives discovered to process in this pass.
  final int archivesTotal;

  /// Last user-visible status message; shown on the drawer's mini card.
  final String statusMessage;

  /// Set when [phase] is [FtpSyncPhase.failed].
  final String? errorMessage;

  /// Wall-clock of the [FtpSyncPhase.connecting] transition. Null while
  /// [phase] is [FtpSyncPhase.idle].
  final DateTime? startedAt;

  /// Last update timestamp — used to compute instantaneous transfer speed.
  final DateTime updatedAt;

  /// In-memory log ring (phase B keeps last 200 entries; phase C will add
  /// a real log tab).
  final List<FtpSyncLogEntry> log;

  /// Name of the profile currently syncing; useful for the drawer title.
  final String? profileName;

  /// Instantaneous transfer speed for the current file, bytes per second.
  /// Null while no byte-based step is active (connecting, listing, etc.) or
  /// before enough samples have accumulated.
  final double? bytesPerSecond;

  /// Estimated remaining time for the *current* step (current file). Null
  /// when not computable (no total, paused, idle, etc.).
  final Duration? stepEta;

  const FtpSyncProgress({
    required this.phase,
    required this.stepProgress,
    required this.bytesTransferred,
    required this.totalBytes,
    required this.currentFileName,
    required this.archivesProcessed,
    required this.archivesTotal,
    required this.statusMessage,
    required this.errorMessage,
    required this.startedAt,
    required this.updatedAt,
    required this.log,
    required this.profileName,
    this.bytesPerSecond,
    this.stepEta,
  });

  /// Initial idle state; used when no sync has ever run in this session.
  factory FtpSyncProgress.idle() => FtpSyncProgress(
        phase: FtpSyncPhase.idle,
        stepProgress: 0,
        bytesTransferred: 0,
        totalBytes: null,
        currentFileName: null,
        archivesProcessed: 0,
        archivesTotal: 0,
        statusMessage: '',
        errorMessage: null,
        startedAt: null,
        updatedAt: DateTime.now(),
        log: const [],
        profileName: null,
      );

  bool get isRunning =>
      phase != FtpSyncPhase.idle &&
      phase != FtpSyncPhase.completed &&
      phase != FtpSyncPhase.failed &&
      phase != FtpSyncPhase.cancelled &&
      phase != FtpSyncPhase.paused;

  /// True when the run is suspended but resumable.
  bool get isPaused => phase == FtpSyncPhase.paused;

  /// Best-effort "X of N" overall position, 0.0..1.0, for the mini card's
  /// coarse progress bar. Not meant to be linear in time.
  double get overallProgress {
    // Weight: connect/list = 10%, download+import per archive = 40% total,
    // generate+upload = 40%, finalize = 10%.
    switch (phase) {
      case FtpSyncPhase.idle:
      case FtpSyncPhase.completed:
        return phase == FtpSyncPhase.completed ? 1.0 : 0.0;
      case FtpSyncPhase.connecting:
        return 0.05 * (stepProgress.clamp(0.0, 1.0));
      case FtpSyncPhase.listing:
        return 0.1;
      case FtpSyncPhase.downloading:
      case FtpSyncPhase.importing:
        final perArchive = archivesTotal == 0
            ? 0.0
            : (archivesProcessed +
                    (phase == FtpSyncPhase.importing
                        ? 0.8 + 0.2 * stepProgress.clamp(0.0, 1.0)
                        : 0.8 * stepProgress.clamp(0.0, 1.0))) /
                archivesTotal;
        return 0.1 + 0.4 * perArchive.clamp(0.0, 1.0);
      case FtpSyncPhase.generatingArchive:
        return 0.5 + 0.1 * stepProgress.clamp(0.0, 1.0);
      case FtpSyncPhase.uploading:
        return 0.6 + 0.3 * stepProgress.clamp(0.0, 1.0);
      case FtpSyncPhase.finalizing:
        return 0.95;
      case FtpSyncPhase.failed:
      case FtpSyncPhase.cancelled:
        return 0.0;
      case FtpSyncPhase.paused:
        // Freeze the bar at whatever overall position we had before pausing.
        return 0.0;
    }
  }

  FtpSyncProgress copyWith({
    FtpSyncPhase? phase,
    double? stepProgress,
    int? bytesTransferred,
    int? totalBytes,
    bool clearTotalBytes = false,
    String? currentFileName,
    bool clearCurrentFileName = false,
    int? archivesProcessed,
    int? archivesTotal,
    String? statusMessage,
    String? errorMessage,
    bool clearErrorMessage = false,
    DateTime? startedAt,
    DateTime? updatedAt,
    List<FtpSyncLogEntry>? log,
    String? profileName,
    double? bytesPerSecond,
    bool clearBytesPerSecond = false,
    Duration? stepEta,
    bool clearStepEta = false,
  }) {
    return FtpSyncProgress(
      phase: phase ?? this.phase,
      stepProgress: stepProgress ?? this.stepProgress,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes:
          clearTotalBytes ? null : (totalBytes ?? this.totalBytes),
      currentFileName: clearCurrentFileName
          ? null
          : (currentFileName ?? this.currentFileName),
      archivesProcessed: archivesProcessed ?? this.archivesProcessed,
      archivesTotal: archivesTotal ?? this.archivesTotal,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? DateTime.now(),
      log: log ?? this.log,
      profileName: profileName ?? this.profileName,
      bytesPerSecond: clearBytesPerSecond
          ? null
          : (bytesPerSecond ?? this.bytesPerSecond),
      stepEta: clearStepEta ? null : (stepEta ?? this.stepEta),
    );
  }
}
