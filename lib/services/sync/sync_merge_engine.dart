import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/data/source/database/legacy_timestamps.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/sync/sync_merge_state.dart';
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
/// unique name another record here already holds, with what hangs on it —
/// it leaves out (see [SyncRowMerger]), so the commit never fails over the
/// archive's content and the rest of the archive is always merged.
class SyncMergeEngine {
  SyncMergeEngine(this._db, this._logger) : _registry = SyncTableRegistry(_db);

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SyncTableRegistry _registry;

  static const _serializer = SyncValueSerializer();

  /// Merges [tableRows] (keyed by table name, in the JSON shape
  /// [SyncTableHandler.dump] produces), [logRows] and [fieldRows].
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

    state.tombstones.addAll(await _localDeletes());
    final (incomingDeletes, changeLogMerged) = await _mergeChangeLog(
      logRows,
      fieldRows,
      warnings,
    );
    incomingDeletes.removeWhere((uuid, _) => state.carried.contains(uuid));
    for (final MapEntry(key: uuid, value: (_, at)) in incomingDeletes.entries) {
      final known = state.tombstones[uuid];
      if (known == null || at > known) state.tombstones[uuid] = at;
    }
    for (final MapEntry(key: from, value: into)
        in (await _mergeTargets()).entries) {
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

    // Merges whose target the archive only brought in above.
    for (final MapEntry(key: from, value: (table, into)) in Map.of(
      tombstones.pendingMerges,
    ).entries) {
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

    for (final h in state.held.values) {
      if (h.isRoot) {
        warnings.add(
          'left out ${h.table} ${h.uuid}: ${h.collidesWith ?? 'another '
                  'record'} here already holds its unique name',
        );
      }
    }

    return SyncImportReport(
      rowsInserted: inserted,
      rowsUpdated: updated,
      rowsSkipped: skipped + state.skipped + state.held.length,
      deletesApplied: state.deletesApplied,
      changeLogMerged: changeLogMerged,
      filesCopied: 0,
      filesSkipped: 0,
      warnings: warnings,
    );
  }

  static int _stampOfJson(Map<String, dynamic> row) =>
      (row['updated_at'] as int?) ?? (row['created_at'] as int?) ?? 0;

  /// The newest deletion of each record in the local change log.
  Future<Map<Uuid, int>> _localDeletes() async => <Uuid, int>{
    for (final row
        in await _db
            .customSelect(
              'SELECT entity_uuid, MAX(changed_at) AS at FROM change_log '
              'WHERE change_type = ? GROUP BY entity_uuid',
              variables: const [Variable<int>(ChangeType.delete)],
            )
            .get())
      Uuid.fromBytes(row.read<Uint8List>('entity_uuid')): row.read<int>('at'),
  };

  /// Records merged into another, with that record, from every merge entry
  /// in the change log; a later merge of the same record wins.
  Future<Map<Uuid, Uuid>> _mergeTargets() async {
    final rows = await _db
        .customSelect(
          'SELECT l.entity_uuid AS entity, f.old_value_short AS target '
          'FROM change_log l JOIN change_log_field f ON f.change_uuid = l.uuid '
          'WHERE l.change_type = ? AND f.field_name = ? '
          'ORDER BY l.changed_at',
          variables: const [
            Variable<int>(ChangeType.delete),
            Variable<String>(kMergedIntoField),
          ],
        )
        .get();
    final targets = <Uuid, Uuid>{};
    for (final row in rows) {
      final target = row.read<Uint8List?>('target');
      if (target == null || target.length != 16) continue;
      targets[Uuid.fromBytes(row.read<Uint8List>('entity'))] = Uuid.fromBytes(
        target,
      );
    }
    return targets;
  }

  /// Stores the change-log rows this device does not have yet. Returns the
  /// deletions among them, by record with its table and newest time, and how
  /// many rows were stored.
  Future<(Map<Uuid, (String, int)>, int)> _mergeChangeLog(
    List<Map<String, dynamic>> logRows,
    List<Map<String, dynamic>> fieldRows,
    List<String> warnings,
  ) async {
    final existing = <Uuid>{
      for (final row
          in await _db.customSelect('SELECT uuid FROM change_log').get())
        Uuid.fromBytes(row.read<Uint8List>('uuid')),
    };
    final deletes = <Uuid, (String, int)>{};
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
        final known = deletes[data.entityUuid];
        if (known == null || data.changedAt > known.$2) {
          deletes[data.entityUuid] = (data.entityTable, data.changedAt);
        }
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
