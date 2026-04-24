import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile_repository.dart';
import 'package:speleoloc/services/sync/ftp/ftp_sync_progress.dart';
import 'package:speleoloc/services/sync/ftp/ftp_transport.dart';
import 'package:speleoloc/services/sync/ftp/ftp_transport_factory.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Archive filename prefix (see [SyncArchiveService.exportToZip]).
const String _archivePrefix = 'speleo_loc_sync_';
const String _archiveSuffix = '.zip';
final RegExp _archiveNameRe =
    RegExp(r'^speleo_loc_sync_(\d+)(?:_[a-fA-F0-9]+)?\.zip$');

/// Orchestrates one FTP sync pass and broadcasts live progress to the UI.
///
/// ### Flow (per design answers)
///   1. Connect to the configured default profile
///   2. List the remote folder, filter out archives already seen locally
///   3. For each unseen archive, oldest-first: download then import (silent
///      last-writer-wins — no UI prompts during FTP sync)
///   4. Generate a fresh local archive reflecting the merged state
///   5. Upload the fresh archive
///   6. Persist the seen-archive list (including our own upload so the next
///      run skips it) and disconnect
///
/// ### Pause semantics
/// Per the user's design decision, "pause" means *cancel the current step
/// while retaining progress state*; "resume" restarts the current step from
/// scratch. In Phase B we surface [cancel] only; [pause]/[resume] land in
/// the detail screen (Phase C) on top of the same [CancelToken] plumbing.
///
/// ### Threading
/// Runs on the main isolate. All heavy work is I/O-bound (network, zipped
/// file IO with stream sinks), so the UI thread stays responsive without
/// needing a separate isolate. Moving archive generation off-thread is a
/// future refinement — it is tracked in the dev log.
class FtpSyncController extends ChangeNotifier {
  final AppDatabase _db;
  final FtpProfileRepository _profileRepo;
  final SyncArchiveService _archiveService;
  final CurrentUserService _currentUser;
  final FtpTransportBuilder _transportBuilder;

  final _log = AppLogger.of('FtpSyncController');

  FtpSyncProgress _progress = FtpSyncProgress.idle();
  CancelToken? _cancelToken;
  Completer<void>? _runCompleter;

  // Rolling log buffer cap.
  static const int _maxLogEntries = 200;

  FtpSyncController({
    required AppDatabase db,
    required FtpProfileRepository profileRepository,
    required SyncArchiveService archiveService,
    required CurrentUserService currentUserService,
    FtpTransportBuilder? transportBuilder,
  })  : _db = db,
        _profileRepo = profileRepository,
        _archiveService = archiveService,
        _currentUser = currentUserService,
        _transportBuilder = transportBuilder ?? defaultTransportBuilder;

  /// Latest live progress snapshot. Listeners are notified via
  /// [ChangeNotifier.notifyListeners] on every change.
  FtpSyncProgress get progress => _progress;

  bool get isRunning => _progress.isRunning;

  /// Fires one end-to-end sync using the default profile. Resolves when the
  /// pass completes, fails or is cancelled.
  ///
  /// Safe to call when already running: the call is ignored and the existing
  /// run's completion future is returned.
  Future<void> startDefault() async {
    if (isRunning) {
      _log.info('startDefault(): already running — ignoring');
      return _runCompleter?.future;
    }
    final profile = await _profileRepo.getDefaultProfile();
    if (profile == null) {
      _fail('no_default_profile');
      return;
    }
    final password = await _profileRepo.readPassword(profile.profileUuid);
    if (password == null || password.isEmpty) {
      _fail('no_password_stored');
      return;
    }
    return _run(profile, password);
  }

  /// Requests cancellation of the in-flight run. Transfers abort as soon as
  /// they observe the token; the run resolves on the [FtpSyncPhase.cancelled]
  /// terminal state.
  void cancel() {
    final token = _cancelToken;
    if (token == null) return;
    _appendLog(FtpSyncLogLevel.warning, 'Cancellation requested');
    token.cancel();
  }

  // ---------------------------------------------------------------------
  // Internal flow
  // ---------------------------------------------------------------------

  Future<void> _run(FtpProfile profile, String password) async {
    final completer = Completer<void>();
    _runCompleter = completer;
    final token = CancelToken();
    _cancelToken = token;

    _emit((p0) => FtpSyncProgress(
          phase: FtpSyncPhase.connecting,
          stepProgress: 0,
          bytesTransferred: 0,
          totalBytes: null,
          currentFileName: null,
          archivesProcessed: 0,
          archivesTotal: 0,
          statusMessage: 'ftp_phase_connecting',
          errorMessage: null,
          startedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          log: [
            FtpSyncLogEntry(
              timestamp: DateTime.now(),
              level: FtpSyncLogLevel.info,
              message:
                  'Starting sync to ${profile.displayName} (${profile.host})',
            ),
          ],
          profileName: profile.displayName,
        ));

    final transport = _transportBuilder(profile);
    final tempDir = await _syncWorkspace();
    try {
      await transport.connect(password: password);
      token.throwIfCancelled();
      _appendLog(FtpSyncLogLevel.info, 'Connected');

      _emit((s) => s.copyWith(
            phase: FtpSyncPhase.listing,
            statusMessage: 'ftp_phase_listing',
            stepProgress: 0,
          ));
      final remoteEntries = await transport.listFolder();
      token.throwIfCancelled();

      final seen = await _loadSeenArchives();
      final unseen = remoteEntries
          .where((e) =>
              _archiveNameRe.hasMatch(e.name) && !seen.contains(e.name))
          // Oldest-first: sort ascending by embedded timestamp.
          .toList()
        ..sort((a, b) => _timestampOf(a.name).compareTo(_timestampOf(b.name)));
      _appendLog(FtpSyncLogLevel.info,
          '${unseen.length} new archive(s) to import of ${remoteEntries.length} on server');

      _emit((s) => s.copyWith(
            archivesTotal: unseen.length,
            archivesProcessed: 0,
          ));

      for (var i = 0; i < unseen.length; i++) {
        token.throwIfCancelled();
        final entry = unseen[i];
        final localPath = p.join(tempDir.path, entry.name);

        _emit((s) => s.copyWith(
              phase: FtpSyncPhase.downloading,
              statusMessage: 'ftp_phase_downloading',
              currentFileName: entry.name,
              bytesTransferred: 0,
              totalBytes: entry.size > 0 ? entry.size : null,
              stepProgress: 0,
            ));
        await transport.downloadFile(
          entry.name,
          File(localPath),
          onProgress: (bytes, total) {
            if (!isRunning) return;
            _emit((s) => s.copyWith(
                  bytesTransferred: bytes,
                  totalBytes: total,
                  stepProgress: total == null || total == 0
                      ? 0
                      : (bytes / total).clamp(0.0, 1.0),
                ));
          },
          cancelToken: token,
        );
        _appendLog(FtpSyncLogLevel.info,
            'Downloaded ${entry.name} (${_formatBytes(entry.size)})');

        _emit((s) => s.copyWith(
              phase: FtpSyncPhase.importing,
              statusMessage: 'ftp_phase_importing',
              stepProgress: 0,
            ));
        try {
          final report = await _archiveService.importFromZip(localPath);
          _appendLog(FtpSyncLogLevel.info,
              'Imported ${entry.name}: +${report.rowsInserted} / '
              '~${report.rowsUpdated} / =${report.rowsSkipped}');
        } catch (e) {
          _appendLog(FtpSyncLogLevel.error,
              'Import failed for ${entry.name}: $e — continuing with next');
        }
        seen.add(entry.name);
        _emit((s) => s.copyWith(
              archivesProcessed: i + 1,
              stepProgress: 1.0,
            ));
        // Best-effort cleanup of the local copy.
        try {
          await File(localPath).delete();
        } catch (_) {}
      }

      token.throwIfCancelled();

      // Generate our own archive reflecting the merged state.
      _emit((s) => s.copyWith(
            phase: FtpSyncPhase.generatingArchive,
            statusMessage: 'ftp_phase_generating',
            currentFileName: null,
            bytesTransferred: 0,
            clearTotalBytes: true,
            clearCurrentFileName: true,
            stepProgress: 0,
          ));
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final deviceUuid = _currentUser.deviceUuid.value?.toString();
      // Include the device uuid so peers can tell whose archive this is
      // (nice-to-have for debugging; not used for filtering).
      final archiveName = deviceUuid == null
          ? '$_archivePrefix$nowMs$_archiveSuffix'
          : '$_archivePrefix${nowMs}_${deviceUuid.substring(0, 8)}$_archiveSuffix';
      final archiveFile = await _archiveService.exportToZip(
        tempDir.path,
        filenameHint: archiveName,
      );
      _appendLog(FtpSyncLogLevel.info,
          'Generated ${archiveFile.uri.pathSegments.last} (${_formatBytes(await archiveFile.length())})');

      token.throwIfCancelled();

      final archiveSize = await archiveFile.length();
      _emit((s) => s.copyWith(
            phase: FtpSyncPhase.uploading,
            statusMessage: 'ftp_phase_uploading',
            currentFileName: archiveName,
            bytesTransferred: 0,
            totalBytes: archiveSize,
            stepProgress: 0,
          ));
      await transport.uploadFile(
        archiveFile,
        archiveName,
        onProgress: (bytes, total) {
          if (!isRunning) return;
          _emit((s) => s.copyWith(
                bytesTransferred: bytes,
                totalBytes: total,
                stepProgress: total == null || total == 0
                    ? 0
                    : (bytes / total).clamp(0.0, 1.0),
              ));
        },
        cancelToken: token,
      );
      seen.add(archiveName);
      _appendLog(FtpSyncLogLevel.info, 'Uploaded $archiveName');

      _emit((s) => s.copyWith(
            phase: FtpSyncPhase.finalizing,
            statusMessage: 'ftp_phase_finalizing',
            stepProgress: 0,
            clearCurrentFileName: true,
          ));
      await _saveSeenArchives(seen);
      try {
        await archiveFile.delete();
      } catch (_) {}
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}

      _emit((s) => s.copyWith(
            phase: FtpSyncPhase.completed,
            statusMessage: 'ftp_phase_completed',
            stepProgress: 1.0,
            clearErrorMessage: true,
          ));
      _appendLog(FtpSyncLogLevel.info, 'Sync complete');
    } on TransferCancelledException {
      _appendLog(FtpSyncLogLevel.warning, 'Sync cancelled');
      _emit((s) => s.copyWith(
            phase: FtpSyncPhase.cancelled,
            statusMessage: 'ftp_phase_cancelled',
          ));
    } on FtpAuthException catch (e) {
      _appendLog(FtpSyncLogLevel.error, 'Auth failed: ${e.message}');
      _emit((s) => s.copyWith(
            phase: FtpSyncPhase.failed,
            statusMessage: 'ftp_auth_failed',
            errorMessage: e.message,
          ));
    } on FtpTransportException catch (e) {
      _appendLog(FtpSyncLogLevel.error, 'Transport error: ${e.message}');
      _emit((s) => s.copyWith(
            phase: FtpSyncPhase.failed,
            statusMessage: 'ftp_connection_failed',
            errorMessage: e.message,
          ));
    } catch (e, st) {
      _log.warning('Unexpected sync failure: $e\n$st');
      _appendLog(FtpSyncLogLevel.error, 'Unexpected error: $e');
      _emit((s) => s.copyWith(
            phase: FtpSyncPhase.failed,
            statusMessage: 'ftp_sync_failed',
            errorMessage: e.toString(),
          ));
    } finally {
      try {
        await transport.disconnect();
      } catch (_) {}
      _cancelToken = null;
      _runCompleter = null;
      if (!completer.isCompleted) completer.complete();
    }
  }

  // ---------------------------------------------------------------------
  // Persistence of the "seen archives" set
  // ---------------------------------------------------------------------

  Future<Set<String>> _loadSeenArchives() async {
    final raw = await _readConfig(ConfigKey.ftpSeenArchives);
    if (raw == null || raw.isEmpty) return <String>{};
    return raw.split('\n').where((s) => s.isNotEmpty).toSet();
  }

  Future<void> _saveSeenArchives(Set<String> seen) async {
    // Keep only the most recent 500 entries to avoid unbounded growth.
    final sorted = seen.toList()
      ..sort((a, b) => _timestampOf(b).compareTo(_timestampOf(a)));
    final trimmed = sorted.take(500).toList();
    await _writeConfig(ConfigKey.ftpSeenArchives, trimmed.join('\n'));
  }

  Future<String?> _readConfig(String key) async {
    final rows = await _db.customSelect(
      'SELECT value FROM configurations WHERE title = ? LIMIT 1',
      variables: [Variable<String>(key)],
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.data['value'] as String?;
  }

  Future<void> _writeConfig(String key, String value) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customStatement(
      'INSERT INTO configurations (title, value, created_at, updated_at) '
      'VALUES (?, ?, ?, ?) '
      'ON CONFLICT(title) DO UPDATE SET value = excluded.value, '
      'updated_at = excluded.updated_at',
      [key, value, now, now],
    );
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  /// Parses the millisecond timestamp embedded in an archive filename. Unknown
  /// formats sort as 0 so they are treated as oldest (rare).
  int _timestampOf(String archiveName) {
    final m = _archiveNameRe.firstMatch(archiveName);
    if (m == null) return 0;
    return int.tryParse(m.group(1) ?? '0') ?? 0;
  }

  Future<Directory> _syncWorkspace() async {
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path,
        'speleo_loc_ftp_sync_${DateTime.now().millisecondsSinceEpoch}'));
    await dir.create(recursive: true);
    return dir;
  }

  void _emit(FtpSyncProgress Function(FtpSyncProgress previous) mutate) {
    _progress = mutate(_progress);
    notifyListeners();
  }

  void _appendLog(FtpSyncLogLevel level, String message) {
    final entry = FtpSyncLogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
    );
    final nextLog = [..._progress.log, entry];
    if (nextLog.length > _maxLogEntries) {
      nextLog.removeRange(0, nextLog.length - _maxLogEntries);
    }
    _emit((s) => s.copyWith(log: nextLog));
    _log.info('[sync] ${level.name}: $message');
  }

  void _fail(String messageKey) {
    _emit((s) => s.copyWith(
          phase: FtpSyncPhase.failed,
          statusMessage: messageKey,
          errorMessage: messageKey,
          startedAt: DateTime.now(),
          profileName: null,
        ));
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
