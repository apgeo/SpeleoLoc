import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/data/source/database/legacy_timestamps.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/sync/archive_held_row_repository.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/sync/sync_merge_state.dart';
import 'package:speleoloc/services/sync/sync_merge_targets.dart';
import 'package:speleoloc/services/sync/sync_row_merger.dart';
import 'package:speleoloc/services/sync/sync_schema.dart';
import 'package:speleoloc/services/sync/sync_serializer.dart';
import 'package:speleoloc/services/sync/sync_table_handler.dart';
import 'package:speleoloc/services/sync/sync_table_registry.dart';
import 'package:speleoloc/services/sync/sync_tombstone_applier.dart';
import 'package:speleoloc/services/sync/sync_user_remap.dart';

/// Merges rows from another device into the local database: the change log
/// and the deletions it carries first, then every synced table, parents
/// before children, with last-writer-wins.
///
/// A merge commits completely or not at all. It runs in one transaction with
/// foreign-key checks deferred to its end, and whatever it cannot write
/// without breaking that check — a row whose parent is gone, a record whose
/// unique name another record here already holds — it leaves out or holds
/// for a person to decide (see [SyncRowMerger]), so the commit never fails
/// over the archive's content and the rest of the archive is always merged.
///
/// The rows held by earlier merges are merged again each time, beside the
/// archive: a newer version of one replaces it, one that no longer collides
/// is written, and what still collides stays held.
class SyncMergeEngine {
  SyncMergeEngine(this._db, this._logger, {ArchiveHeldRowRepository? heldRows})
    : _registry = SyncTableRegistry(_db),
      _heldRows = heldRows ?? ArchiveHeldRowRepository(_db);

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SyncTableRegistry _registry;
  final ArchiveHeldRowRepository _heldRows;

  static const _serializer = SyncValueSerializer();

  /// Merges [tableRows] (keyed by table name, in the JSON shape
  /// [SyncTableHandler.dump] produces), [logRows] and [fieldRows], together
  /// with every row held from earlier merges. Called with no rows, it merges
  /// the held rows alone.
  Future<SyncImportReport> merge({
    Map<String, List<Map<String, dynamic>>> tableRows =
        const <String, List<Map<String, dynamic>>>{},
    List<Map<String, dynamic>> logRows = const <Map<String, dynamic>>[],
    List<Map<String, dynamic>> fieldRows = const <Map<String, dynamic>>[],
    ConflictResolver? conflictResolver,
    List<String>? warnings,
  }) async {
    final warn = warnings ?? <String>[];

    // A device on an older app can still send timestamps in seconds; store
    // them the way this device now does.
    for (final rows in [...tableRows.values, logRows]) {
      for (final row in rows) {
        for (final key in legacyTimestampColumns) {
          final v = row[key];
          if (v is int) row[key] = timestampToMillis(v);
        }
      }
    }

    final users = await SyncUserRemap.build(
      _db,
      tableRows['users'] ?? const [],
      warn,
    );
    if (!users.isEmpty) {
      for (final entry in tableRows.entries) {
        for (final r in entry.value) {
          users.applyToRow(r, entry.key);
        }
      }
      for (final row in logRows) {
        users.applyToChangeLogRow(row);
      }
    }

    late SyncImportReport report;
    await _logger.runSuspended(() async {
      await _db.transaction(() async {
        // Defer FK checks to the end of the transaction so rows can be
        // written in any order without transient violations.
        await _db.customStatement('PRAGMA defer_foreign_keys = ON');
        report = await _mergeInTransaction(
          tableRows,
          logRows,
          fieldRows,
          conflictResolver,
          warn,
        );
      });
    });
    return report;
  }

  /// Moves what refers to the local record [from] over to [into] and removes
  /// [from]. Returns false, changing nothing, when a moved row would take a
  /// unique key a row of [into] already holds. Run inside the caller's
  /// transaction; the caller logs the merge.
  Future<bool> mergeLocalRecord(String table, Uuid from, Uuid into) async {
    final schema = await SyncSchema.read(_db, _uuidTables());
    final state = SyncMergeState(_db, <String>[]);
    return SyncTombstoneApplier(
      _db,
      schema,
      state,
    ).mergeInto(table, from, into);
  }

  List<String> _uuidTables() => <String>[
    for (final t in _registry.tables())
      if (t.name != SyncTableRegistry.configurationsTable) t.name,
  ];

  Future<SyncImportReport> _mergeInTransaction(
    Map<String, List<Map<String, dynamic>>> tableRows,
    List<Map<String, dynamic>> logRows,
    List<Map<String, dynamic>> fieldRows,
    ConflictResolver? conflictResolver,
    List<String> warnings,
  ) async {
    final handlers = _registry.tables();
    final schema = await SyncSchema.read(_db, _uuidTables());
    final state = SyncMergeState(_db, warnings);
    final tombstones = SyncTombstoneApplier(_db, schema, state);
    final merger = SyncRowMerger(_db, schema, state, tombstones);
    await state.loadPresence(_uuidTables());

    // An archive is a full snapshot of its source device, so a row it still
    // carries, and has not soft-deleted, is alive there whatever its change
    // log says. Such a tombstone is stale — the row was deleted and later
    // restored with the same uuid — and applying it would delete on this
    // device what the source still shows.
    for (final rows in tableRows.values) {
      for (final r in rows) {
        if (r['deleted_at'] != null) continue;
        if (state.uuidOf(r['uuid']) case final uuid?) {
          state.carried.add(uuid);
        }
      }
    }

    final rowsByTable = <String, List<Map<String, dynamic>>>{
      for (final MapEntry(:key, :value) in tableRows.entries)
        key: <Map<String, dynamic>>[...value],
    };
    _addHeldRows(rowsByTable, await _heldRows.readAll());

    final localDeletes = await _localDeletes();
    final (newDeletes, changeLogMerged) = await _mergeChangeLog(
      logRows,
      fieldRows,
      warnings,
    );
    final merges = await SyncMergeTargets.read(_db);
    state.tombstones.addAll(
      _newest(localDeletes, merges.overruled).map((r, d) => MapEntry(r, d.$2)),
    );
    final incomingDeletes = _newest(newDeletes, merges.overruled)
      ..removeWhere((uuid, _) => state.carried.contains(uuid));
    for (final MapEntry(key: uuid, value: (_, at)) in incomingDeletes.entries) {
      final known = state.tombstones[uuid];
      if (known == null || at > known) state.tombstones[uuid] = at;
    }
    for (final MapEntry(key: from, value: into) in merges.targets.entries) {
      if (!state.carried.contains(from)) state.mergedInto[from] = into;
    }
    _stampSubtrees(handlers, schema, state, rowsByTable);

    // Deletions first: a record the archive removes frees its unique name
    // for the archive's own records, and its children are dealt with before
    // any incoming row is checked against them.
    await tombstones.applyAll(<Uuid, SyncTombstone>{
      for (final MapEntry(key: uuid, value: (table, at))
          in incomingDeletes.entries)
        uuid: SyncTombstone(
          table: table,
          at: at,
          mergedInto: state.mergedInto[uuid],
        ),
    });

    var inserted = 0;
    var updated = 0;
    var skipped = 0;
    for (final t in handlers) {
      final rows = rowsByTable[t.name];
      if (rows == null) continue;
      final result = await t.upsert(rows, conflictResolver, merger);
      inserted += result.inserted;
      updated += result.updated;
      skipped += result.skipped;
    }

    // Merges whose target the archive only brought in above, the records
    // furthest down first: a record merged along with the one it hangs on
    // — a cave given new identifiers with its places — has moved out of the
    // way before that one's own move is checked against what the target
    // already holds.
    final depth = <String, int>{
      for (final (i, t) in handlers.indexed) t.name: i,
    };
    final pending = tombstones.pendingMerges.entries.toList()
      ..sort(
        (a, b) => (depth[b.value.$1] ?? 0).compareTo(depth[a.value.$1] ?? 0),
      );
    for (final MapEntry(key: from, value: (table, into)) in pending) {
      if (state.isPresent(table, into) &&
          await tombstones.mergeInto(table, from, into)) {
        continue;
      }
      state.skipped++;
      warnings.add(
        'kept $table $from: the record it was merged into could not be '
        'merged here',
      );
    }

    // A server copy the archive's row replaced now holds another device's
    // file, and has to stop being recorded as the copy.
    await SilexgisFileCopyRepository(_db).adoptArchiveFiles(<Uuid, String>{
      for (final r in tableRows['documentation_files'] ?? const [])
        if (Uuid.tryParse(r['uuid'] as String? ?? '') case final id?)
          if (r['file_name'] case final String name) id: name,
    });

    await _heldRows.replaceAll(state.held.values);

    return SyncImportReport(
      rowsInserted: inserted,
      rowsUpdated: updated,
      rowsSkipped: skipped + state.skipped,
      deletesApplied: state.deletesApplied,
      changeLogMerged: changeLogMerged,
      filesCopied: 0,
      filesSkipped: 0,
      warnings: warnings,
      decisionsPending: state.held.values.where((h) => h.isRoot).length,
    );
  }

  /// Adds the rows held by earlier merges to [rowsByTable]. Where the archive
  /// carries the same row, the newer of the two is merged.
  void _addHeldRows(
    Map<String, List<Map<String, dynamic>>> rowsByTable,
    List<SyncHeldRow> held,
  ) {
    for (final h in held) {
      final rows = rowsByTable.putIfAbsent(h.table, () => []);
      final at = rows.indexWhere((r) => r['uuid'] == h.uuid.toString());
      if (at < 0) {
        rows.add(h.row);
      } else if (_stampOfJson(h.row) > _stampOfJson(rows[at])) {
        rows[at] = h.row;
      }
    }
  }

  static int _stampOfJson(Map<String, dynamic> row) =>
      (row['updated_at'] as int?) ?? (row['created_at'] as int?) ?? 0;

  /// Every deletion in the local change log, merges among them.
  Future<List<_Deletion>> _localDeletes() async => <_Deletion>[
    for (final row
        in await _db
            .customSelect(
              'SELECT uuid, entity_table, entity_uuid, changed_at '
              'FROM change_log WHERE change_type = ?',
              variables: const [Variable<int>(ChangeType.delete)],
            )
            .get())
      (
        entry: Uuid.fromBytes(row.read<Uint8List>('uuid')),
        table: row.read<String>('entity_table'),
        record: Uuid.fromBytes(row.read<Uint8List>('entity_uuid')),
        at: row.read<int>('changed_at'),
      ),
  ];

  /// The newest of [deletions] for each record, by record with its table and
  /// time, leaving out the [overruled] merges.
  static Map<Uuid, (String, int)> _newest(
    Iterable<_Deletion> deletions,
    Set<Uuid> overruled,
  ) {
    final newest = <Uuid, (String, int)>{};
    for (final d in deletions) {
      if (overruled.contains(d.entry)) continue;
      final known = newest[d.record];
      if (known == null || d.at > known.$2) newest[d.record] = (d.table, d.at);
    }
    return newest;
  }

  /// Stores the change-log rows this device does not have yet. Returns the
  /// deletions among them and how many rows were stored.
  Future<(List<_Deletion>, int)> _mergeChangeLog(
    List<Map<String, dynamic>> logRows,
    List<Map<String, dynamic>> fieldRows,
    List<String> warnings,
  ) async {
    final existing = <Uuid>{
      for (final row
          in await _db.customSelect('SELECT uuid FROM change_log').get())
        Uuid.fromBytes(row.read<Uint8List>('uuid')),
    };
    final deletes = <_Deletion>[];
    var merged = 0;
    for (final row in logRows) {
      final ChangeLogData data;
      try {
        data = ChangeLogData.fromJson(row, serializer: _serializer);
      } catch (e) {
        warnings.add('change_log: $e');
        continue;
      }
      if (!existing.add(data.uuid)) continue;
      await _db.into(_db.changeLog).insert(data);
      merged++;
      if (data.changeType == ChangeType.delete) {
        deletes.add((
          entry: data.uuid,
          table: data.entityTable,
          record: data.entityUuid,
          at: data.changedAt,
        ));
      }
    }
    for (final row in fieldRows) {
      try {
        final data = ChangeLogFieldData.fromJson(row, serializer: _serializer);
        await _db
            .into(_db.changeLogField)
            .insert(data, mode: InsertMode.insertOrIgnore);
      } catch (e) {
        warnings.add('change_log_field: $e');
      }
    }
    return (deletes, merged);
  }

  /// For each incoming record, the newest stamp among it and the incoming
  /// rows that hang on it, directly or further down. Children come after
  /// their parents in the table order, so walking it backwards sees every
  /// child before its parent.
  void _stampSubtrees(
    List<SyncTableHandler> handlers,
    SyncSchema schema,
    SyncMergeState state,
    Map<String, List<Map<String, dynamic>>> rowsByTable,
  ) {
    for (final t in handlers.reversed) {
      if (!schema.has(t.name)) continue;
      for (final row in rowsByTable[t.name] ?? const <Map<String, dynamic>>[]) {
        final uuid = state.uuidOf(row['uuid']);
        if (uuid == null) continue;
        final own = _stampOfJson(row);
        final below = state.subtreeStamp[uuid] ?? 0;
        final stamp = own > below ? own : below;
        state.subtreeStamp[uuid] = stamp;
        for (final fk in schema.parentsOf(t.name)) {
          final ref = state.uuidOf(row[fk.column]);
          if (ref == null) continue;
          final parent = state.resolve(ref);
          final known = state.subtreeStamp[parent] ?? 0;
          if (stamp > known) state.subtreeStamp[parent] = stamp;
        }
      }
    }
  }
}

/// One deletion entry of the change log: the entry itself, and the record
/// it deleted, with its table and time.
typedef _Deletion = ({Uuid entry, String table, Uuid record, int at});
