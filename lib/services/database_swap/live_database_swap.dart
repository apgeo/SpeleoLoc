import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/database_swap/database_file_validator.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/contained_path.dart';

/// Thrown when the live database would be replaced while an FTP or SilexGIS
/// sync run is writing to it.
class SyncRunActiveException implements Exception {
  const SyncRunActiveException();

  @override
  String toString() => 'SyncRunActiveException: a sync run is in progress';
}

/// Replaces the live database file — a restore, a replace-import, a
/// reinitialize — so that a failure at any step leaves the caver's data and
/// a working database in place.
///
/// The candidate is copied next to the live file and checked before the live
/// database is closed. The live file is then moved aside, not deleted, and
/// moved back when the new database does not open or [replaceWith]'s
/// `afterOpen` step fails; either way the app ends on an open database. A
/// backup still present at the next start means a swap was cut short, and
/// [recoverInterruptedSwap] puts the old file back.
///
/// The working names start with the database's own name and a dash, which
/// archive and sync file writes refuse, so no incoming file can pose as a
/// backup.
class LiveDatabaseSwap {
  LiveDatabaseSwap({
    Future<Directory> Function()? documentsDirectory,
    AppDatabase Function()? openLiveDatabase,
    AppDatabase Function()? currentDatabase,
    void Function(AppDatabase database)? install,
    bool Function()? isSyncRunning,
    Future<void> Function()? onSettled,
  }) : _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory,
       _openLiveDatabase = openLiveDatabase ?? AppDatabase.new,
       _currentDatabase = currentDatabase ?? (() => appDatabase),
       _install = install ?? replaceAppDatabase,
       _isSyncRunning = isSyncRunning ?? (() => false),
       _onSettled = onSettled;

  final Future<Directory> Function() _documentsDirectory;
  final AppDatabase Function() _openLiveDatabase;
  final AppDatabase Function() _currentDatabase;
  final void Function(AppDatabase database) _install;
  final bool Function() _isSyncRunning;

  /// Runs once the app is on its final database after a swap or a rollback,
  /// for state read from the database at start that the swap invalidates.
  final Future<void> Function()? _onSettled;

  static const String backupSuffix = '-swap-backup';
  static const String incomingSuffix = '-swap-incoming';
  static const List<String> _sidecars = ['-journal', '-wal', '-shm'];

  static final _log = AppLogger.of('LiveDatabaseSwap');

  bool get isSyncRunning => _isSyncRunning();

  /// Throws [SyncRunActiveException] while a sync run is in flight: the run
  /// holds the live database and would carry on against a closed handle.
  void ensureNoSyncRunning() {
    if (_isSyncRunning()) throw const SyncRunActiveException();
  }

  /// Replaces the live database with a copy of [candidate], or with a new
  /// empty database when [candidate] is null.
  ///
  /// [afterOpen] runs against the new database once it has opened and been
  /// installed — carrying device settings over, copying files that belong to
  /// it. When it throws, the swap is rolled back like a failed open.
  ///
  /// Throws [SyncRunActiveException], [InvalidDatabaseFileException] or
  /// `DatabaseTooNewException` before anything is touched, or the error of
  /// the step that failed after the old database had been put back.
  Future<void> replaceWith(
    File? candidate, {
    Future<void> Function(AppDatabase database)? afterOpen,
  }) async {
    ensureNoSyncRunning();
    final live = await _liveFile();
    final incoming = File('${live.path}$incomingSuffix');
    final backup = File('${live.path}$backupSuffix');

    if (candidate != null) {
      await _deleteWithSidecars(incoming);
      try {
        await candidate.copy(incoming.path);
        await validateDatabaseFile(
          incoming,
          supportedVersion: _currentDatabase().schemaVersion,
        );
      } catch (_) {
        await _bestEffortDelete(incoming);
        rethrow;
      }
    }

    if (_isSyncRunning()) {
      // A run started while the candidate was being checked.
      await _bestEffortDelete(incoming);
      throw const SyncRunActiveException();
    }
    if (await backup.exists()) {
      // Left by a rollback that failed earlier in this session: it may be
      // the only copy of the caver's data, so it is never overwritten here.
      await _bestEffortDelete(incoming);
      throw const FileSystemException(
        'A previous database is still waiting to be restored; '
        'restart the app first',
      );
    }

    await _closeQuietly(_currentDatabase());
    AppDatabase? opened;
    final hadLive = await live.exists();
    try {
      await _moveWithSidecars(live, backup);
      if (candidate != null) await incoming.rename(live.path);
      opened = _openLiveDatabase();
      // The first query opens the file and runs any upgrade, so a file that
      // passed the checks but cannot be brought up to date fails here.
      await opened.customSelect('SELECT 1').get();
      _install(opened);
      if (afterOpen != null) await afterOpen(opened);
    } catch (e, st) {
      _log.warning('Database swap failed; restoring the previous one', e, st);
      await _rollBack(live, incoming, backup, opened, hadLive: hadLive);
      await _settle();
      Error.throwWithStackTrace(e, st);
    }
    await _bestEffortDelete(backup);
    await _settle();
  }

  /// Puts back a live database a swap moved aside and never finished with,
  /// such as when the app was killed mid-swap. Call at start, before the
  /// database is first opened. Returns whether a backup was restored.
  Future<bool> recoverInterruptedSwap() async {
    final live = await _liveFile();
    final backup = File('${live.path}$backupSuffix');
    await _bestEffortDelete(File('${live.path}$incomingSuffix'));
    if (!await backup.exists()) return false;
    _log.warning('A database swap was interrupted; restoring the previous one');
    await _deleteWithSidecars(live);
    await _moveWithSidecars(backup, live);
    return true;
  }

  /// Deletes the live database and anything a swap left behind, then installs
  /// a new empty one. Only for a caver who has chosen to start over.
  Future<void> discardLiveDatabase() async {
    ensureNoSyncRunning();
    final live = await _liveFile();
    await _closeQuietly(_currentDatabase());
    await _deleteWithSidecars(live);
    await _deleteWithSidecars(File('${live.path}$backupSuffix'));
    await _deleteWithSidecars(File('${live.path}$incomingSuffix'));
    _install(_openLiveDatabase());
  }

  /// The live database file. It may not exist yet.
  Future<File> liveDatabaseFile() => _liveFile();

  Future<File> _liveFile() async {
    final docs = await _documentsDirectory();
    return File(p.join(docs.path, databaseFileName));
  }

  Future<void> _rollBack(
    File live,
    File incoming,
    File backup,
    AppDatabase? opened, {
    required bool hadLive,
  }) async {
    try {
      if (opened != null) await _closeQuietly(opened);
      await _bestEffortDelete(incoming);
      // Only what this swap put at the live name is removed: a live file
      // still in place because moving it aside failed is the caver's data.
      if (await backup.exists()) {
        await _deleteWithSidecars(live);
        await _moveWithSidecars(backup, live);
      } else if (!hadLive) {
        await _deleteWithSidecars(live);
      }
    } catch (e, st) {
      // The backup stays on disk, and the next start puts it back.
      _log.severe('Could not restore the database after a failed swap', e, st);
    }
    _install(_openLiveDatabase());
  }

  Future<void> _settle() async {
    final onSettled = _onSettled;
    if (onSettled == null) return;
    try {
      await onSettled();
    } catch (e, st) {
      _log.warning('Post-swap refresh failed', e, st);
    }
  }

  static Future<void> _closeQuietly(AppDatabase db) async {
    try {
      await db.close();
    } catch (e, st) {
      // A database that never opened, the case after a failed start, can
      // throw on close; the file is still free to move.
      _log.fine('closing the database failed', e, st);
    }
  }

  static Future<void> _moveWithSidecars(File from, File to) async {
    if (await from.exists()) await from.rename(to.path);
    for (final suffix in _sidecars) {
      final sidecar = File('${from.path}$suffix');
      if (await sidecar.exists()) await sidecar.rename('${to.path}$suffix');
    }
  }

  static Future<void> _deleteWithSidecars(File file) async {
    if (await file.exists()) await file.delete();
    for (final suffix in _sidecars) {
      final sidecar = File('${file.path}$suffix');
      if (await sidecar.exists()) await sidecar.delete();
    }
  }

  static Future<void> _bestEffortDelete(File file) async {
    try {
      await _deleteWithSidecars(file);
    } catch (e, st) {
      _log.fine('could not delete ${file.path}', e, st);
    }
  }
}
