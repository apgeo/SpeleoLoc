import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/clock.dart';

/// Where this device is in its conversation with one installation's sync set.
class SilexgisSetState {
  const SilexgisSetState({this.cursor, this.setRevision, this.lastSyncedAt});

  /// The resume position the last page returned, opaque and stored verbatim.
  /// Null means the next read starts the set from the beginning, which is
  /// always correct.
  final String? cursor;

  /// The `setRevision` the last page carried. When the server's has moved, the
  /// selection or its settings were edited and every cursor issued before that
  /// is retired.
  final int? setRevision;

  final DateTime? lastSyncedAt;

  static const SilexgisSetState fresh = SilexgisSetState();
}

/// The device's local-only record of its conversations with SilexGIS
/// installations: the download cursor per sync set, and the server revision of
/// every row it has seen.
///
/// **None of this ever leaves the device except back to the server that issued
/// it.** It is not a column on any synced row, it is not in the change log, it
/// is not in a device-to-device archive. A cursor that travelled to a second
/// device would have that device ask for everything after a position it never
/// read: the server answers "nothing after this" and the rows in between are
/// never downloaded — silently, with nothing to retry. A base revision that
/// travelled would lose that device every upload to a conflict it cannot
/// explain.
///
/// The identifier is the same on both sides. The device mints it and the
/// server adopts it verbatim; for a row the device first meets by download it
/// adopts the server's the same way. There is no mapping table here and there
/// must never be one.
class SilexgisLocalStateRepository {
  SilexgisLocalStateRepository(this._db, {Clock clock = const SystemClock()})
    : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  // ------------------------------------------------------------- set position

  Future<SilexgisSetState> readSetState(
    String profileUuid,
    String setId,
  ) async {
    final row =
        await (_db.select(_db.silexgisSyncState)..where(
              (t) => t.profileUuid.equals(profileUuid) & t.setId.equals(setId),
            ))
            .getSingleOrNull();
    if (row == null) return SilexgisSetState.fresh;
    return SilexgisSetState(
      cursor: row.cursor,
      setRevision: row.setRevision,
      lastSyncedAt: row.lastSyncedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.lastSyncedAt!, isUtc: true),
    );
  }

  /// Records the position a page handed back. Called once per page, so a lost
  /// connection costs the page in flight rather than the whole sync.
  Future<void> writeSetState(
    String profileUuid,
    String setId, {
    required String? cursor,
    required int setRevision,
  }) async {
    await _db
        .into(_db.silexgisSyncState)
        .insertOnConflictUpdate(
          SilexgisSyncStateCompanion.insert(
            profileUuid: profileUuid,
            setId: setId,
            cursor: Value(cursor),
            setRevision: Value(setRevision),
            lastSyncedAt: Value(_clock.nowMs()),
          ),
        );
  }

  /// Throws the resume position away, keeping everything else.
  ///
  /// The answer to `sync.cursor_invalid` and `sync.cursor_stale` alike: two
  /// different statuses and codes for one decision on the device. A full read
  /// is always correct, and is also how a device picks up a row that became
  /// readable — being granted the right to place a cave writes nothing to that
  /// cave's row, so no incremental read will ever carry it.
  Future<void> dropCursor(String profileUuid, String setId) async {
    await (_db.update(_db.silexgisSyncState)..where(
          (t) => t.profileUuid.equals(profileUuid) & t.setId.equals(setId),
        ))
        .write(const SilexgisSyncStateCompanion(cursor: Value(null)));
  }

  /// Forgets one installation entirely — the position and every revision.
  /// Signing a profile out, or deleting it, leaves no trace to be sent back to
  /// a server that no longer knows this device.
  Future<void> forgetProfile(String profileUuid) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.silexgisSyncState,
      )..where((t) => t.profileUuid.equals(profileUuid))).go();
      await (_db.delete(
        _db.silexgisRowRevision,
      )..where((t) => t.profileUuid.equals(profileUuid))).go();
    });
  }

  // ---------------------------------------------------------- row revisions

  /// The revision to send as this row's `baseRevision`, or null when the row
  /// is new to this installation.
  Future<String?> readRevision(String profileUuid, Uuid entityUuid) async {
    final row =
        await (_db.select(_db.silexgisRowRevision)..where(
              (t) =>
                  t.profileUuid.equals(profileUuid) &
                  t.entityUuid.equalsValue(entityUuid),
            ))
            .getSingleOrNull();
    return row?.revision;
  }

  /// Every stored revision for one installation, by row identifier. Read once
  /// per sync run rather than per row: a batch of forty edits would otherwise
  /// be forty queries.
  Future<Map<Uuid, StoredRevision>> readRevisions(String profileUuid) async {
    final rows = await (_db.select(
      _db.silexgisRowRevision,
    )..where((t) => t.profileUuid.equals(profileUuid))).get();
    return <Uuid, StoredRevision>{
      for (final row in rows)
        row.entityUuid: StoredRevision(
          revision: row.revision,
          entityTable: row.entityTable,
          wireKind: row.wireKind,
          localUpdatedAt: row.localUpdatedAt,
          recordedAt: row.updatedAt,
        ),
    };
  }

  Future<void> writeRevision(
    String profileUuid,
    Uuid entityUuid, {
    required String entityTable,
    required String revision,
    String? wireKind,
    int? localUpdatedAt,
  }) => writeRevisions(profileUuid, <SilexgisRevisionEntry>[
    SilexgisRevisionEntry(
      entityUuid: entityUuid,
      entityTable: entityTable,
      revision: revision,
      wireKind: wireKind,
      localUpdatedAt: localUpdatedAt,
    ),
  ]);

  /// Stores a page's or a batch's worth of revisions in one transaction.
  Future<void> writeRevisions(
    String profileUuid,
    Iterable<SilexgisRevisionEntry> entries,
  ) async {
    if (entries.isEmpty) return;
    final now = _clock.nowMs();
    await _db.batch((batch) {
      for (final entry in entries) {
        batch.insert(
          _db.silexgisRowRevision,
          SilexgisRowRevisionCompanion.insert(
            profileUuid: profileUuid,
            entityUuid: entry.entityUuid,
            entityTable: entry.entityTable,
            wireKind: Value(entry.wireKind),
            revision: entry.revision,
            localUpdatedAt: Value(entry.localUpdatedAt),
            updatedAt: Value(now),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Forgets a row's revision on this installation — after a tombstone was
  /// applied, or after an upload removed it. The next time the identifier is
  /// seen it is new there again, which is what a create-by-id needs.
  Future<void> forgetRevisions(
    String profileUuid,
    Iterable<Uuid> entityUuids,
  ) async {
    if (entityUuids.isEmpty) return;
    await (_db.delete(_db.silexgisRowRevision)..where(
          (t) =>
              t.profileUuid.equals(profileUuid) &
              t.entityUuid.isIn(entityUuids.map((u) => u.bytes)),
        ))
        .go();
  }
}

/// A revision as it is stored: the server's stamp, the local row's own stamp at
/// the moment the two sides last agreed, and when this device wrote the entry.
class StoredRevision {
  const StoredRevision({
    required this.revision,
    required this.entityTable,
    required this.recordedAt,
    this.wireKind,
    this.localUpdatedAt,
  });

  final String revision;
  final String entityTable;

  /// When this device wrote the entry. Diagnostic only — what decides whether
  /// a row is due to be sent again is [localUpdatedAt], because comparing a
  /// row's stamp against a clock reading leaves a window at both ends.
  final int? recordedAt;

  /// The local row's `updated_at` when the two sides last agreed about it. A
  /// row whose stamp no longer equals this one has been edited here since.
  final int? localUpdatedAt;

  /// The `kind` this row travels as, kept because a local delete is physical:
  /// once the row is gone the device can no longer tell whether it was an
  /// entrance or a place, and the tombstone still names one. Null for a
  /// revision stored before this was recorded.
  final String? wireKind;

  /// Whether a local row carrying [updatedAt] still says what the two sides
  /// last agreed it said.
  ///
  /// An exact comparison, and that is the point: comparing a row's stamp to
  /// *when* this entry was written leaves a window at each end — an edit made
  /// in the same millisecond as an upload is missed, and a server whose clock
  /// runs ahead makes a freshly downloaded row look edited for ever.
  ///
  /// A row that has never carried a stamp is treated as changed: there is
  /// nothing to compare, and one `unchanged` answer per run costs less than an
  /// edit that never leaves the device.
  bool agreesWith(int? updatedAt) {
    if (updatedAt == null && localUpdatedAt == null) return false;
    return updatedAt == localUpdatedAt;
  }
}

/// One row's revision on one installation.
class SilexgisRevisionEntry {
  const SilexgisRevisionEntry({
    required this.entityUuid,
    required this.entityTable,
    required this.revision,
    this.wireKind,
    this.localUpdatedAt,
  });

  final Uuid entityUuid;

  /// The local table holding the row. Not part of its identity — that is the
  /// uuid, which both sides share — but it tells the upload builder where to
  /// look and lets a table's revisions be cleared together.
  final String entityTable;

  /// The server's `updatedAt`, stored exactly as it was sent.
  final String revision;

  /// The wire `kind` — see [StoredRevision.wireKind].
  final String? wireKind;

  /// The local row's own stamp as exchanged — see
  /// [StoredRevision.localUpdatedAt].
  final int? localUpdatedAt;
}
