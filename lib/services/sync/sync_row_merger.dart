import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/sync/sync_merge_state.dart';
import 'package:speleoloc/services/sync/sync_schema.dart';
import 'package:speleoloc/services/sync/sync_table_handler.dart';
import 'package:speleoloc/services/sync/sync_tombstone_applier.dart';

/// Writes one table's incoming rows with last-writer-wins, within a merge
/// whose deletions have already been applied.
///
/// A row is written only when the result is a database every device can
/// agree on and SQLite will commit:
/// - a row whose parent this merge removed, or never had, is not written;
///   one that merely refers to a removed record is detached from it;
/// - a record this device deleted after the archive's copy (and everything
///   in it) was last touched stays deleted;
/// - a new record whose unique key a different local record already holds,
///   or an edit that would give a record such a key, is held for a person to
///   decide, and every incoming row that hangs on a held new record waits
///   with it.
///
/// Every write states its own conflict clause. The schema's UNIQUE
/// constraints say ON CONFLICT ROLLBACK, which would end the whole import
/// transaction on a collision and leave the rest of the merge writing outside
/// it; a statement's own clause overrides the table's. Collisions are looked
/// for before writing, so the clause is only a guard.
class SyncRowMerger {
  SyncRowMerger(this._db, this._schema, this._state, this._tombstones);

  final AppDatabase _db;
  final SyncSchema _schema;
  final SyncMergeState _state;
  final SyncTombstoneApplier _tombstones;

  /// Metadata columns excluded from conflict diff (audit/bookkeeping).
  /// The last_* and firmware_version entries are cave_place_beacons health
  /// telemetry — devices legitimately observe different values, so they
  /// must not raise conflicts (LWW still propagates them).
  static const _metaColumnsForDiff = <String>{
    'created_at',
    'updated_at',
    'deleted_at',
    'created_by_user_uuid',
    'last_modified_by_user_uuid',
    'last_seen_at',
    'last_battery_mv',
    'last_temperature_c',
    'last_humidity_pct',
    'last_pressure_hpa',
    'last_movement_counter',
    'firmware_version',
    // Two devices that each edit a trip's points mark its log stale at
    // different moments. That is the same fact, not a conflict to ask about;
    // last-write-wins still carries it.
    'log_stale_since',
  };

  /// Users are matched by name before the merge; one still colliding is
  /// skipped, never held, since every row names its author.
  static const _neverHeld = <String>{'users'};

  /// Generic last-writer-wins upsert with optional [resolver] callback for
  /// surfacing conflicts to the user.
  Future<UpsertCounters> upsertRows<D extends Insertable<D>>(
    List<Map<String, dynamic>> rows,
    D Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic> Function(D) toJson,
    int? Function(D) tsOf,
    TableInfo<Table, D> table,
    ConflictResolver? resolver,
  ) async {
    final name = table.actualTableName;
    var inserted = 0;
    var updated = 0;
    var skipped = 0;

    // Edits of records already here go first: a rename can free the name a
    // new record of the same archive takes.
    final edits = <Map<String, dynamic>>[];
    final additions = <Map<String, dynamic>>[];
    for (final raw in rows) {
      final uuid = _state.uuidOf(raw['uuid']);
      final here = uuid != null && _state.isPresent(name, uuid);
      (here ? edits : additions).add(raw);
    }

    for (final raw in [...edits, ...additions]) {
      final row = Map<String, dynamic>.of(raw);
      // A reference to a record merged into another means that record now.
      if (_state.mergedInto.isNotEmpty) {
        for (final fk in _schema.parentsOf(name)) {
          final ref = _state.uuidOf(row[fk.column]);
          if (ref == null) continue;
          final into = _state.resolve(ref);
          if (into != ref) row[fk.column] = into.toString();
        }
      }

      final uuid = _state.uuidOf(row['uuid']);
      if (uuid == null) {
        skipped++;
        _state.warnings.add('skipped a $name row without a valid uuid');
        continue;
      }
      if (_state.mergedInto.containsKey(uuid)) {
        skipped++;
        continue;
      }

      final here = _state.isPresent(name, uuid);
      final parents = _checkParents(name, uuid, row);
      if (parents == _Parents.missing) {
        // A local row keeps its own version; a new one is not brought in.
        skipped++;
        if (!here) _state.dropped.add(uuid);
        continue;
      }
      if (parents case _Waits(:final group)) {
        _hold(name, uuid, row, group: group, blocks: !here);
        continue;
      }

      D incoming;
      try {
        incoming = fromJson(row);
      } catch (e) {
        skipped++;
        _state.warnings.add('skipped a malformed $name row: $e');
        continue;
      }
      final incomingTs = tsOf(incoming) ?? 0;

      if (here) {
        final local = await _loadLocal<D>(table, uuid);
        if (local == null) continue;
        final localTs = tsOf(local) ?? 0;
        final localJson = toJson(local);
        final incomingJson = toJson(incoming);
        final diff = _diffMeaningfulFields(localJson, incomingJson);
        if (diff.isEmpty) {
          skipped++;
          continue;
        }

        var action = incomingTs > localTs
            ? SyncConflictAction.useIncoming
            : SyncConflictAction.keepLocal;
        if (resolver != null) {
          final decision = await resolver(
            SyncConflict(
              tableName: name,
              entityUuid: uuid,
              localFields: localJson,
              incomingFields: incomingJson,
              differingFields: diff,
              localUpdatedAt: localTs == 0 ? null : localTs,
              incomingUpdatedAt: incomingTs == 0 ? null : incomingTs,
            ),
          );
          if (decision == SyncConflictAction.cancel) {
            throw const SyncImportCancelledException();
          }
          if (decision != null) action = decision;
        }
        if (action != SyncConflictAction.useIncoming) {
          skipped++;
          continue;
        }

        // Matched by primary key, never REPLACE: REPLACE deletes every row
        // conflicting on any unique index before re-inserting, which would
        // silently destroy an unrelated local row and orphan its children.
        final values = sqlValuesOf(incoming);
        final clash = await _schema.findCollision(name, values, uuid);
        if (clash != null) {
          if (_neverHeld.contains(name)) {
            skipped++;
            continue;
          }
          _hold(name, uuid, row, group: uuid, collidesWith: clash.$1);
          continue;
        }
        if (await _update(table, uuid, values)) {
          updated++;
        } else {
          skipped++;
        }
        continue;
      }

      // A record this device deleted after the archive's copy, and every
      // incoming row inside it, was last touched stays deleted: the archive
      // was made before its source heard of the deletion.
      final deletedAt = _state.tombstones[uuid];
      final touched = _max(incomingTs, _state.subtreeStamp[uuid]);
      if (deletedAt != null && deletedAt >= touched) {
        skipped++;
        _state.dropped.add(uuid);
        continue;
      }
      // Brought back by work done inside it after the deletion: stamped with
      // that work, it reaches every device that applied the deletion too,
      // even once that work is gone.
      if (deletedAt != null &&
          incomingTs <= deletedAt &&
          row.containsKey('updated_at')) {
        incoming = fromJson(row..['updated_at'] = touched);
      }

      final values = sqlValuesOf(incoming);
      var clash = await _schema.findCollision(name, values, uuid);
      if (clash != null && await _mergedAway(name, clash.$1, uuid, values)) {
        clash = null;
      }
      if (clash != null) {
        if (_neverHeld.contains(name)) {
          skipped++;
          _state.dropped.add(uuid);
          continue;
        }
        _hold(
          name,
          uuid,
          row,
          group: uuid,
          collidesWith: clash.$1,
          blocks: true,
        );
        continue;
      }
      try {
        await _db.into(table).insert(incoming, mode: InsertMode.insertOrAbort);
        inserted++;
        _state.markPresent(name, uuid);
      } on Exception catch (e) {
        skipped++;
        _state.dropped.add(uuid);
        _state.warnings.add('could not insert $name $uuid: $e');
      }
    }

    return UpsertCounters(
      inserted: inserted,
      updated: updated,
      skipped: skipped,
    );
  }

  /// Whether every parent of [row] is here. Detaches [row] in place from a
  /// record this merge removed when the reference may be empty.
  _Parents _checkParents(String name, Uuid uuid, Map<String, dynamic> row) {
    Uuid? waitOn;
    for (final fk in _schema.parentsOf(name)) {
      final ref = _state.uuidOf(row[fk.column]);
      if (ref == null) continue;
      final group = _state.blocking[ref];
      if (group != null) {
        waitOn ??= group;
        continue;
      }
      if (_state.isPresent(fk.parentTable, ref)) continue;
      final gone =
          _state.dropped.contains(ref) || _state.tombstones.containsKey(ref);
      if (gone && fk.nullable) {
        row[fk.column] = null;
        continue;
      }
      if (!gone) {
        _state.warnings.add(
          'skipped $name $uuid: its ${fk.parentTable} $ref is neither here '
          'nor in the archive',
        );
      }
      return _Parents.missing;
    }
    return waitOn == null ? _Parents.here : _Waits(waitOn);
  }

  /// When the local record [local] holding [uuid]'s key was merged into
  /// [uuid] on the archive's side, carries that merge out here so [uuid] can
  /// be written. Only done when nothing else holds the key.
  Future<bool> _mergedAway(
    String name,
    Uuid local,
    Uuid uuid,
    Map<String, Object?> values,
  ) async {
    final pending = _tombstones.pendingMerges[local];
    if (pending == null || pending.$2 != uuid) return false;
    final other = await _schema.findCollision(
      name,
      values,
      uuid,
      ignore: <Uuid>{local},
    );
    if (other != null) return false;
    if (!await _tombstones.mergeInto(name, local, uuid)) return false;
    _tombstones.pendingMerges.remove(local);
    return true;
  }

  void _hold(
    String table,
    Uuid uuid,
    Map<String, dynamic> row, {
    required Uuid group,
    Uuid? collidesWith,
    bool blocks = false,
  }) {
    _state.held[uuid] = SyncHeldRow(
      table: table,
      uuid: uuid,
      group: group,
      collidesWith: collidesWith,
      row: row,
    );
    if (blocks) _state.blocking[uuid] = group;
  }

  Future<bool> _update<D>(
    TableInfo<Table, D> table,
    Uuid uuid,
    Map<String, Object?> values,
  ) async {
    final columns = values.keys.where((c) => c != 'uuid').toList();
    try {
      await _db.customUpdate(
        'UPDATE OR ABORT ${table.actualTableName} SET '
        '${columns.map((c) => '$c = ?').join(', ')} WHERE uuid = ?',
        variables: [
          for (final c in columns) SyncSchema.variable(values[c]),
          Variable<Uint8List>(uuid.bytes),
        ],
        updates: {table},
        updateKind: UpdateKind.update,
      );
      return true;
    } on Exception catch (e) {
      _state.warnings.add(
        'could not update ${table.actualTableName} $uuid: $e',
      );
      return false;
    }
  }

  Future<D?> _loadLocal<D>(TableInfo<Table, D> table, Uuid uuid) async {
    final row = await _db
        .customSelect(
          'SELECT * FROM ${table.actualTableName} WHERE uuid = ? LIMIT 1',
          variables: [Variable<Uint8List>(uuid.bytes)],
        )
        .getSingleOrNull();
    if (row == null) return null;
    return await table.map(row.data);
  }

  List<String> _diffMeaningfulFields(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final keys = <String>{...a.keys, ...b.keys};
    final diff = <String>[];
    for (final k in keys) {
      if (_metaColumnsForDiff.contains(k)) continue;
      if (a[k] != b[k]) diff.add(k);
    }
    return diff;
  }

  static int _max(int a, int? b) => b == null || a >= b ? a : b;

  /// The SQL values [row] writes, by column name.
  static Map<String, Object?> sqlValuesOf(Insertable<dynamic> row) => {
    for (final MapEntry(:key, :value) in row.toColumns(false).entries)
      key: switch (value) {
        final Variable<Object> v => v.value,
        final Constant<Object> c => c.value,
        _ => null,
      },
  };
}

sealed class _Parents {
  const _Parents();

  static const here = _Here();
  static const missing = _Missing();
}

class _Here extends _Parents {
  const _Here();
}

class _Missing extends _Parents {
  const _Missing();
}

class _Waits extends _Parents {
  const _Waits(this.group);

  final Uuid group;
}
