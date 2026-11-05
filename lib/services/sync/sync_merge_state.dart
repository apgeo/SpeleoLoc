import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

/// An incoming row the merge did not write because a person has to decide
/// about it first.
class SyncHeldRow {
  const SyncHeldRow({
    required this.table,
    required this.uuid,
    required this.group,
    required this.row,
    this.collidesWith,
  });

  final String table;
  final Uuid uuid;

  /// The colliding record this row waits on; [uuid] itself for that record.
  final Uuid group;

  /// The local record already holding the unique key, for the colliding
  /// record only.
  final Uuid? collidesWith;

  /// The row as the archive carried it, in the archive's JSON shape.
  final Map<String, dynamic> row;

  bool get isRoot => group == uuid;
}

/// What one merge knows and has decided so far, shared by the steps that
/// apply its deletions and write its rows.
class SyncMergeState {
  SyncMergeState(this._db, this.warnings);

  final AppDatabase _db;
  final List<String> warnings;

  final Map<String, Set<Uuid>> _present = <String, Set<Uuid>>{};

  /// Rows held for a decision in this merge.
  final Map<Uuid, SyncHeldRow> held = <Uuid, SyncHeldRow>{};

  /// Held new records, each with the group it leads: an incoming row that
  /// hangs on one cannot be written either, and waits in the same group. A
  /// held edit of a record that exists here blocks nothing.
  final Map<Uuid, Uuid> blocking = <Uuid, Uuid>{};

  /// Records this merge removed or chose not to bring in. A row that needs
  /// one goes with it; a row that merely may refer to one is detached.
  final Set<Uuid> dropped = <Uuid>{};

  /// The newest deletion of each record that the merge must respect: this
  /// device's, and the archive's for records the archive does not carry.
  final Map<Uuid, int> tombstones = <Uuid, int>{};

  /// Records merged into another, with the record each now lives on as.
  final Map<Uuid, Uuid> mergedInto = <Uuid, Uuid>{};

  /// For each incoming record, the newest stamp among it and the incoming
  /// rows that hang on it: a deletion is undone by work done after it, on
  /// the record or inside it.
  final Map<Uuid, int> subtreeStamp = <Uuid, int>{};

  /// Records the archive carries alive.
  final Set<Uuid> carried = <Uuid>{};

  int skipped = 0;
  int deletesApplied = 0;

  final Map<String, Uuid?> _parsed = <String, Uuid?>{};

  /// [value] as a uuid, when it is one. Rows name the same records over and
  /// over, so each text is parsed once per merge.
  Uuid? uuidOf(Object? value) => value is String
      ? _parsed.putIfAbsent(value, () => Uuid.tryParse(value))
      : null;

  /// Reads which rows [tables] hold, once, so that every later presence
  /// check of the merge is answered without a query.
  Future<void> loadPresence(Iterable<String> tables) async {
    for (final table in tables) {
      _present[table] = <Uuid>{
        for (final row
            in await _db.customSelect('SELECT uuid FROM $table').get())
          Uuid.fromBytes(row.read<Uint8List>('uuid')),
      };
    }
  }

  /// Whether a row with [uuid] exists in [table] at this point of the merge.
  bool isPresent(String table, Uuid uuid) =>
      _present[table]?.contains(uuid) ?? false;

  void markPresent(String table, Uuid uuid) =>
      (_present[table] ??= <Uuid>{}).add(uuid);

  void markGone(String table, Uuid uuid) => _present[table]?.remove(uuid);

  /// Follows [mergedInto] to the record [uuid] now lives on as.
  Uuid resolve(Uuid uuid) {
    var current = uuid;
    final seen = <Uuid>{current};
    while (true) {
      final next = mergedInto[current];
      if (next == null || !seen.add(next)) return current;
      current = next;
    }
  }
}
