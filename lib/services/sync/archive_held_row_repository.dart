import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/sync/sync_merge_state.dart';
import 'package:speleoloc/utils/clock.dart';

/// The archive rows waiting for a person to decide, kept across restarts and
/// further syncs until then.
class ArchiveHeldRowRepository {
  ArchiveHeldRowRepository(this._db, {Clock clock = const SystemClock()})
    : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  Future<List<SyncHeldRow>> readAll() async => <SyncHeldRow>[
    for (final r in await _db.select(_db.archiveHeldRow).get())
      SyncHeldRow(
        table: r.entityTable,
        uuid: r.entityUuid,
        group: r.groupUuid,
        collidesWith: r.collidesWithUuid,
        row: jsonDecode(r.rowJson) as Map<String, dynamic>,
      ),
  ];

  /// How many decisions wait: one per colliding record.
  Future<int> countDecisions() async {
    final rows = await _db
        .customSelect(
          'SELECT COUNT(*) AS n FROM archive_held_row '
          'WHERE entity_uuid = group_uuid',
          readsFrom: {_db.archiveHeldRow},
        )
        .getSingle();
    return rows.read<int>('n');
  }

  /// Watches [countDecisions].
  Stream<int> watchDecisionCount() => _db
      .customSelect(
        'SELECT COUNT(*) AS n FROM archive_held_row '
        'WHERE entity_uuid = group_uuid',
        readsFrom: {_db.archiveHeldRow},
      )
      .watchSingle()
      .map((r) => r.read<int>('n'));

  /// Replaces everything held with [rows]: each merge reads every held row
  /// back, so what it still holds is the whole set. Rows held before keep
  /// the time they were first held.
  Future<void> replaceAll(Iterable<SyncHeldRow> rows) async {
    await _db.transaction(() async {
      final since = <Uuid, int>{
        for (final r in await _db.select(_db.archiveHeldRow).get())
          r.entityUuid: r.heldAt,
      };
      await _db.delete(_db.archiveHeldRow).go();
      final now = _clock.nowMs();
      for (final r in rows) {
        await _db
            .into(_db.archiveHeldRow)
            .insert(
              ArchiveHeldRowCompanion.insert(
                entityUuid: r.uuid,
                entityTable: r.table,
                groupUuid: r.group,
                collidesWithUuid: Value(r.collidesWith),
                rowJson: jsonEncode(r.row),
                heldAt: since[r.uuid] ?? now,
              ),
            );
      }
    });
  }

  /// Replaces the stored copy of one held row.
  Future<void> updateRow(Uuid uuid, Map<String, dynamic> row) async {
    await (_db.update(_db.archiveHeldRow)
          ..where((r) => r.entityUuid.equalsValue(uuid)))
        .write(ArchiveHeldRowCompanion(rowJson: Value(jsonEncode(row))));
  }

  /// Forgets one held row.
  Future<void> remove(Uuid uuid) async {
    await (_db.delete(
      _db.archiveHeldRow,
    )..where((r) => r.entityUuid.equalsValue(uuid))).go();
  }
}
