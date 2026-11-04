import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';

/// Which records were merged into which, from every merge entry in the
/// change log.
///
/// Two phones can each merge the same two records the opposite way before
/// either hears of the other, each keeping its own. Every device ends up
/// with both entries, so every device settles it the same way: the later
/// merge stands (on equal times, the entry whose identifier sorts last),
/// and the earlier one is overruled — read as made the same way, it neither
/// deletes the record that stays nor sends anything back to the one that
/// goes.
class SyncMergeTargets {
  const SyncMergeTargets._(this.targets, this.overruled);

  /// Each record merged into another, with that record. A later merge of
  /// the same record wins.
  final Map<Uuid, Uuid> targets;

  /// The change-log entries of the overruled merges.
  final Set<Uuid> overruled;

  static Future<SyncMergeTargets> read(AppDatabase db) async {
    final rows = await db
        .customSelect(
          'SELECT l.uuid AS entry, l.entity_uuid AS entity, '
          'f.old_value_short AS target '
          'FROM change_log l JOIN change_log_field f ON f.change_uuid = l.uuid '
          'WHERE l.change_type = ? AND f.field_name = ? '
          'ORDER BY l.changed_at, l.uuid',
          variables: const [
            Variable<int>(ChangeType.delete),
            Variable<String>(kMergedIntoField),
          ],
        )
        .get();
    final targets = <Uuid, Uuid>{};
    final entryOf = <Uuid, Uuid>{};
    final overruled = <Uuid>{};
    for (final row in rows) {
      final target = row.read<Uint8List?>('target');
      if (target == null || target.length != 16) continue;
      final from = Uuid.fromBytes(row.read<Uint8List>('entity'));
      final into = Uuid.fromBytes(target);
      if (targets[into] == from) {
        targets.remove(into);
        overruled.add(entryOf.remove(into)!);
      }
      targets[from] = into;
      entryOf[from] = Uuid.fromBytes(row.read<Uint8List>('entry'));
    }
    return SyncMergeTargets._(targets, overruled);
  }
}
