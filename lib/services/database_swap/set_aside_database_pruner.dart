import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:speleoloc/services/database_swap/live_database_swap.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/clock.dart';

/// Deletes the database copies that failed swaps set aside beside the live
/// database, once they are old enough that nobody is coming back for them.
///
/// Each copy is a whole database and may hold the only trace of what a caver
/// wrote, so the rule is lenient: a copy goes only when it is older than
/// [keepFor] by the time stamped into its name and a newer copy exists. The
/// newest copy stays however old it is. A name that does not parse is kept.
/// The live file, the swap's backup and anything else in the folder are
/// never touched: only names carrying [LiveDatabaseSwap.discardedSuffix] are
/// considered, and the backup that recovery restores never carries it.
class SetAsideDatabasePruner {
  const SetAsideDatabasePruner({
    Clock clock = const SystemClock(),
    this.keepFor = const Duration(days: 30),
  }) : _clock = clock;

  final Clock _clock;
  final Duration keepFor;

  static final _log = AppLogger.of('SetAsideDatabasePruner');

  /// Prunes the copies set aside beside [live]. Never throws: a copy that
  /// cannot be deleted now is tried again at the next start.
  Future<void> prune(File live) async {
    try {
      final copies = await _setAsideCopies(live);
      if (copies.length < 2) return;
      final newest = copies.keys.reduce((a, b) => _compare(a, b) >= 0 ? a : b);
      final cutoff = _clock.now().subtract(keepFor).millisecondsSinceEpoch;
      for (final MapEntry(key: copy, value: files) in copies.entries) {
        if (copy == newest || copy.stamp >= cutoff) continue;
        for (final file in files) {
          try {
            await file.delete();
          } catch (e, st) {
            _log.fine('could not delete ${file.path}', e, st);
          }
        }
        _log.info(
          'Deleted a database set aside by a failed swap at ${copy.stamp}',
        );
      }
    } catch (e, st) {
      _log.warning('Set-aside databases could not be pruned', e, st);
    }
  }

  /// Every set-aside copy with its files: the copy and its SQLite sidecars.
  static Future<Map<_SetAsideCopy, List<File>>> _setAsideCopies(
    File live,
  ) async {
    final dir = live.parent;
    if (!await dir.exists()) return const {};
    final pattern = RegExp(
      '^${RegExp.escape(p.basename(live.path))}'
      '${RegExp.escape(LiveDatabaseSwap.discardedSuffix)}'
      r'-(\d+)(?:-(\d+))?(?:-journal|-wal|-shm)?$',
    );
    final copies = <_SetAsideCopy, List<File>>{};
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final match = pattern.firstMatch(p.basename(entity.path));
      if (match == null) continue;
      final stamp = int.tryParse(match.group(1)!);
      final n = match.group(2) == null ? 0 : int.tryParse(match.group(2)!);
      if (stamp == null || n == null) continue;
      final copy = (stamp: stamp, n: n);
      (copies[copy] ??= []).add(entity);
    }
    return copies;
  }

  static int _compare(_SetAsideCopy a, _SetAsideCopy b) {
    final byStamp = a.stamp.compareTo(b.stamp);
    return byStamp != 0 ? byStamp : a.n.compareTo(b.n);
  }
}

/// One set-aside copy: the millisecond it was set aside, and the counter
/// that keeps two copies of the same millisecond apart.
typedef _SetAsideCopy = ({int stamp, int n});
