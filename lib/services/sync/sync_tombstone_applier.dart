import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/sync/sync_merge_state.dart';
import 'package:speleoloc/services/sync/sync_schema.dart';

/// A deletion the archive carries for one record.
class SyncTombstone {
  const SyncTombstone({required this.table, required this.at, this.mergedInto});

  final String table;

  /// When the record was deleted.
  final int at;

  /// Set when the record was not thrown away but merged into another: what
  /// hung on it moves to that record.
  final Uuid? mergedInto;
}

/// Applies an archive's deletions to the local database.
///
/// A deletion reaches what hangs on the record too, as the deleting device's
/// own delete did: rows that need the record go with it, rows that merely
/// refer to it are detached. The deleting device logged a deletion for every
/// row it knew of; the rest — rows made on this device, or by a third, that
/// it never saw — are reached here, so nothing is left pointing at a record
/// that is gone.
///
/// Work done after the deletion wins over it: when any row the deletion would
/// reach was added or changed after it, the record is kept, with everything
/// on it. Every device compares the same stamps, so they all keep it or all
/// let it go.
class SyncTombstoneApplier {
  SyncTombstoneApplier(this._db, this._schema, this._state);

  final AppDatabase _db;
  final SyncSchema _schema;
  final SyncMergeState _state;

  /// Merges whose target was not here yet when the deletions ran: by local
  /// record, its table and the record it was merged into.
  final Map<Uuid, (String, Uuid)> pendingMerges = <Uuid, (String, Uuid)>{};

  /// Users are matched by name across devices and every row names its
  /// author, so a merge never removes one.
  static const _neverRemoved = <String>{'users'};

  late final Map<String, TableInfo> _tableInfos = <String, TableInfo>{
    for (final t in _db.allTables) t.actualTableName: t,
  };

  Future<void> applyAll(Map<Uuid, SyncTombstone> tombstones) async {
    for (final MapEntry(key: uuid, value: tombstone) in tombstones.entries) {
      await _apply(uuid, tombstone);
    }
  }

  Future<void> _apply(Uuid uuid, SyncTombstone tombstone) async {
    final table = tombstone.table;
    // A deletion of a record kept only on this device has nothing to remove.
    if (!_schema.has(table) || _neverRemoved.contains(table)) return;
    final stamp = await _stampOf(table, uuid);
    if (stamp == null) {
      _state.dropped.add(uuid);
      return;
    }
    // Edited here strictly after the deletion: the edit wins. On a tie the
    // deletion wins, as it does against an equal-stamped incoming edit.
    if (stamp > tombstone.at) return;

    final target = tombstone.mergedInto;
    if (target != null) {
      final into = _state.resolve(target);
      if (_state.isPresent(table, into)) {
        if (!await mergeInto(table, uuid, into)) {
          _state.skipped++;
          _state.warnings.add(
            'kept $table $uuid: moving what it holds to $into would clash '
            'with what that record already holds',
          );
        }
      } else {
        pendingMerges[uuid] = (table, into);
      }
      return;
    }

    final plan = await _cascadeOf(table, uuid, tombstone.at);
    if (plan case _Kept(:final since)) {
      // Every device that applied the deletion compares the record's own
      // stamp with it; stamped with the work that kept it, the record
      // reaches them again, even once that work is gone.
      await _restamp(table, uuid, since);
      _state.skipped++;
      return;
    }
    if (plan is! _Cascade) {
      _state.skipped++;
      return;
    }
    for (final (childTable, child, column) in plan.detach) {
      await _db.customUpdate(
        'UPDATE OR ABORT $childTable SET $column = NULL WHERE uuid = ?',
        variables: [Variable<Uint8List>(child.bytes)],
        updates: {_tableInfos[childTable]!},
        updateKind: UpdateKind.update,
      );
    }
    for (final (rowTable, row) in [...plan.remove, (table, uuid)]) {
      await _remove(rowTable, row);
    }
  }

  /// Moves every row that refers to [from] over to [into], then removes
  /// [from]. Returns false, changing nothing, when a moved row would take a
  /// unique key a row of [into] already holds.
  Future<bool> mergeInto(String table, Uuid from, Uuid into) async {
    final moves = <(String, String)>[];
    for (final (childTable, fk) in _schema.childrenOf(table)) {
      final rows = await _db
          .customSelect(
            'SELECT * FROM $childTable WHERE ${fk.column} = ?',
            variables: [Variable<Uint8List>(from.bytes)],
          )
          .get();
      for (final row in rows) {
        final values = Map<String, Object?>.of(row.data)
          ..[fk.column] = into.bytes;
        final own = Uuid.fromBytes(row.read<Uint8List>('uuid'));
        if (await _schema.findCollision(childTable, values, own) != null) {
          return false;
        }
      }
      if (rows.isNotEmpty) moves.add((childTable, fk.column));
    }
    for (final (childTable, column) in moves) {
      await _db.customUpdate(
        'UPDATE OR ABORT $childTable SET $column = ? WHERE $column = ?',
        variables: [
          Variable<Uint8List>(into.bytes),
          Variable<Uint8List>(from.bytes),
        ],
        updates: {_tableInfos[childTable]!},
        updateKind: UpdateKind.update,
      );
    }
    await _remove(table, from);
    _state.mergedInto[from] = into;
    return true;
  }

  /// The rows a deletion of [uuid] at [at] reaches; [_Kept] with the newest
  /// stamp among them when one of them was added or changed after it; null
  /// when one could not be detached.
  Future<_Plan?> _cascadeOf(String table, Uuid uuid, int at) async {
    final remove = <(String, Uuid)>[];
    final detach = <(String, Uuid, String)>[];
    final removed = <Uuid>{uuid};
    final queue = <(String, Uuid)>[(table, uuid)];
    int? newest;
    while (queue.isNotEmpty) {
      final (parentTable, parent) = queue.removeLast();
      for (final (childTable, fk) in _schema.childrenOf(parentTable)) {
        final rows = await _db
            .customSelect(
              'SELECT uuid, ${_schema.stampOf(childTable)} AS ts '
              'FROM $childTable WHERE ${fk.column} = ?',
              variables: [Variable<Uint8List>(parent.bytes)],
            )
            .get();
        for (final row in rows) {
          final child = Uuid.fromBytes(row.read<Uint8List>('uuid'));
          final ts = row.read<int>('ts');
          if (ts > at) {
            if (newest == null) {
              _state.warnings.add(
                'kept $table $uuid: $childTable $child was added or changed '
                'after its deletion',
              );
            }
            if (newest == null || ts > newest) newest = ts;
          }
          if (fk.nullable) {
            detach.add((childTable, child, fk.column));
          } else if (removed.add(child)) {
            remove.add((childTable, child));
            queue.add((childTable, child));
          }
        }
      }
    }
    if (newest != null) return _Kept(newest);
    final kept = <(String, Uuid, String)>[];
    for (final d in detach) {
      final (childTable, child, column) = d;
      if (removed.contains(child)) continue;
      final row = await _db
          .customSelect(
            'SELECT * FROM $childTable WHERE uuid = ?',
            variables: [Variable<Uint8List>(child.bytes)],
          )
          .getSingle();
      final values = Map<String, Object?>.of(row.data)..[column] = null;
      if (await _schema.findCollision(childTable, values, child) != null) {
        _state.warnings.add(
          'kept $table $uuid: detaching $childTable $child from it would '
          'clash with another row',
        );
        return null;
      }
      kept.add(d);
    }
    return _Cascade(remove, kept);
  }

  Future<void> _remove(String table, Uuid uuid) async {
    // customUpdate rather than customStatement: it tells drift which table
    // changed, so screens watching it reload after the import.
    await _db.customUpdate(
      'DELETE FROM $table WHERE uuid = ?',
      variables: [Variable<Uint8List>(uuid.bytes)],
      updates: {_tableInfos[table]!},
      updateKind: UpdateKind.delete,
    );
    _state.markGone(table, uuid);
    _state.dropped.add(uuid);
    _state.deletesApplied++;
  }

  Future<void> _restamp(String table, Uuid uuid, int at) async {
    if (!_schema.columnsOf(table).contains('updated_at')) return;
    await _db.customUpdate(
      'UPDATE $table SET updated_at = ? WHERE uuid = ?',
      variables: [Variable<int>(at), Variable<Uint8List>(uuid.bytes)],
      updates: {_tableInfos[table]!},
      updateKind: UpdateKind.update,
    );
  }

  Future<int?> _stampOf(String table, Uuid uuid) async {
    final row = await _db
        .customSelect(
          'SELECT ${_schema.stampOf(table)} AS ts FROM $table WHERE uuid = ?',
          variables: [Variable<Uint8List>(uuid.bytes)],
        )
        .getSingleOrNull();
    return row?.read<int>('ts');
  }
}

sealed class _Plan {
  const _Plan();
}

class _Cascade extends _Plan {
  const _Cascade(this.remove, this.detach);

  final List<(String, Uuid)> remove;
  final List<(String, Uuid, String)> detach;
}

/// The record stays: something it holds was added or changed [since] after
/// the deletion.
class _Kept extends _Plan {
  const _Kept(this.since);

  final int since;
}
