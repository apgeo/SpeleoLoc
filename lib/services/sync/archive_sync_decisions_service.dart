import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/sync/archive_held_row_repository.dart';
import 'package:speleoloc/services/sync/archive_sync_decision.dart';
import 'package:speleoloc/services/sync/archive_sync_decision_errors.dart';
import 'package:speleoloc/services/sync/sync_merge_engine.dart';
import 'package:speleoloc/services/sync/sync_merge_state.dart';
import 'package:speleoloc/utils/clock.dart';

/// What a person can do about a record an archive merge held because a
/// different record here already has its unique name.
///
/// Each choice is an ordinary edit of this device's data, logged like any
/// other, so the other devices reach the same result at their next sync:
/// - merge into the local record: what hangs on the incoming record moves to
///   the local one, and the incoming record is removed everywhere;
/// - keep both: the incoming record is renamed and written;
/// - discard the incoming record: it is removed everywhere, with what hangs
///   on it, or, for an incoming edit, this device's version stands.
///
/// Afterwards the held rows are merged again, so what waited on the record
/// is written, or held again if it collides in turn.
class ArchiveSyncDecisionsService {
  ArchiveSyncDecisionsService({
    required AppDatabase db,
    required ChangeLogger logger,
    required CurrentUserService currentUser,
    required SyncMergeEngine engine,
    required ArchiveHeldRowRepository heldRows,
    Clock clock = const SystemClock(),
  }) : _db = db,
       _logger = logger,
       _currentUser = currentUser,
       _engine = engine,
       _heldRows = heldRows,
       _clock = clock;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final CurrentUserService _currentUser;
  final SyncMergeEngine _engine;
  final ArchiveHeldRowRepository _heldRows;
  final Clock _clock;

  /// The records waiting for a decision, each with what waits on it.
  Future<List<ArchiveSyncDecision>> decisions() async {
    final held = await _heldRows.readAll();
    final waiting = <Uuid, List<SyncHeldRow>>{};
    for (final h in held) {
      if (!h.isRoot) (waiting[h.group] ??= <SyncHeldRow>[]).add(h);
    }
    final decisions = <ArchiveSyncDecision>[];
    for (final root in held.where((h) => h.isRoot)) {
      final title = root.row['title'];
      final collidesWith = root.collidesWith;
      decisions.add(
        ArchiveSyncDecision(
          root: root,
          waiting: waiting[root.uuid] ?? const <SyncHeldRow>[],
          isEdit: await _exists(root.table, root.uuid),
          title: title is String ? title : null,
          localTitle: title is String && collidesWith != null
              ? await _titleOf(root.table, collidesWith)
              : null,
          caveTitle: switch (Uuid.tryParse(root.row['cave_uuid'] as String?)) {
            final cave? => await _titleOf('caves', cave),
            null => null,
          },
        ),
      );
    }
    return decisions;
  }

  /// Merges the held rows again on their own: a record renamed or removed
  /// here since it was held may no longer collide.
  Future<void> refresh() => _engine.merge();

  /// The incoming record becomes the local record it collides with.
  Future<void> mergeIntoLocal(ArchiveSyncDecision decision) =>
      _resolve(() async {
        final root = decision.root;
        final into = root.collidesWith;
        if (into == null) return;
        if (decision.isEdit &&
            !await _engine.mergeLocalRecord(root.table, root.uuid, into)) {
          throw const ArchiveSyncMergeBlockedException();
        }
        await _logger.logMerge(
          root.table,
          root.uuid,
          into: into,
          oldValues: _describing(root.row),
        );
        await _heldRows.remove(root.uuid);
      });

  /// Writes the incoming record under [newTitle], beside the local one.
  /// Throws [ArchiveSyncNameTakenException], changing nothing, when another
  /// record here holds that name too.
  Future<void> keepBoth(ArchiveSyncDecision decision, String newTitle) {
    final root = decision.root;
    return _resolve(() async {
      final before = decision.isEdit
          ? await _titleOf(root.table, root.uuid)
          : decision.title;
      final row = Map<String, dynamic>.of(root.row)
        ..['title'] = newTitle
        ..['updated_at'] = _clock.nowMs()
        ..['last_modified_by_user_uuid'] =
            (await _currentUser.currentOrSystem()).toString();
      await _heldRows.updateRow(root.uuid, row);
      await _logger.logUpdate(
        root.table,
        root.uuid,
        oldValues: {'title': before},
        newValues: {'title': newTitle},
      );
    }, mustWrite: root.uuid);
  }

  /// Drops the incoming record: a new one is removed, with what waits on it,
  /// on every device; for an edit, this device's version stands everywhere.
  Future<void> discard(ArchiveSyncDecision decision) => _resolve(() async {
    final root = decision.root;
    if (decision.isEdit) {
      // Stamped now, this device's version wins over the incoming edit on
      // every device, as a later edit would.
      await _db.customUpdate(
        'UPDATE ${root.table} SET updated_at = ?, '
        'last_modified_by_user_uuid = ? WHERE uuid = ?',
        variables: [
          Variable<int>(_clock.nowMs()),
          Variable<Uint8List>((await _currentUser.currentOrSystem()).bytes),
          Variable<Uint8List>(root.uuid.bytes),
        ],
        updates: {_tableInfo(root.table)},
        updateKind: UpdateKind.update,
      );
      await _logger.logUpdate(
        root.table,
        root.uuid,
        oldValues: _describing(root.row),
        newValues: {
          if (root.row.containsKey('title'))
            'title': await _titleOf(root.table, root.uuid),
        },
      );
      await _heldRows.remove(root.uuid);
      return;
    }
    for (final row in [root, ...decision.waiting]) {
      // A waiting edit of a record this device has drops only the edit:
      // the record itself was never part of what is discarded.
      if (!await _exists(row.table, row.uuid)) {
        await _logger.logDelete(
          row.table,
          row.uuid,
          oldValues: _describing(row.row),
        );
      }
      await _heldRows.remove(row.uuid);
    }
  });

  Future<void> _resolve(Future<void> Function() choice, {Uuid? mustWrite}) =>
      _db.transaction(() async {
        await _db.customStatement('PRAGMA defer_foreign_keys = ON');
        await choice();
        await _engine.merge();
        if (mustWrite != null &&
            (await _heldRows.readAll()).any((h) => h.uuid == mustWrite)) {
          throw const ArchiveSyncNameTakenException();
        }
      });

  /// The values a change-log entry keeps to say which record it was.
  static Map<String, Object?> _describing(Map<String, dynamic> row) => {
    for (final key in const ['title', 'cave_uuid', 'cave_area_uuid'])
      if (row.containsKey(key)) key: row[key],
  };

  Future<bool> _exists(String table, Uuid uuid) async =>
      (await _db
          .customSelect(
            'SELECT 1 FROM $table WHERE uuid = ?',
            variables: [Variable<Uint8List>(uuid.bytes)],
          )
          .getSingleOrNull()) !=
      null;

  Future<String?> _titleOf(String table, Uuid uuid) async {
    final row = await _db
        .customSelect(
          'SELECT title FROM $table WHERE uuid = ?',
          variables: [Variable<Uint8List>(uuid.bytes)],
        )
        .getSingleOrNull();
    return row?.read<String?>('title');
  }

  TableInfo _tableInfo(String table) =>
      _db.allTables.firstWhere((t) => t.actualTableName == table);
}
