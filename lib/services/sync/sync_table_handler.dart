import 'sync_archive_service.dart' show ConflictResolver;

/// Insert/update/skip counters returned by a single per-table upsert pass.
///
/// Used by [SyncTableHandler.upsert] to tally what happened so the
/// aggregate [SyncImportReport] in `sync_archive_service.dart` can roll
/// the numbers up across every table.
class UpsertCounters {
  const UpsertCounters({
    required this.inserted,
    required this.updated,
    required this.skipped,
  });
  final int inserted;
  final int updated;
  final int skipped;
}

/// One entry in the sync-archive table registry.
///
/// Each handler binds a logical table name to two operations:
/// - [dump] reads every row from the live DB and returns it as a list
///   of JSON-shaped maps ready to be serialised into the archive.
/// - [upsert] takes a list of JSON-shaped rows (as read back from an
///   archive) and merges them into the live DB using the LWW policy in
///   `SyncArchiveService._upsertRows`. An optional [ConflictResolver]
///   from the caller (the import workflow) is forwarded so the UI can
///   prompt the user before applying ambiguous merges.
///
/// All instances are produced from the per-table registry inside
/// `SyncArchiveService`; the class itself is intentionally
/// behaviour-free — it's a transport for two closures plus a name.
class SyncTableHandler {
  const SyncTableHandler({
    required this.name,
    required this.dump,
    required this.upsert,
  });

  /// Stable table name used both as the archive entry filename
  /// (`<name>.jsonl`) and as the key in tally/warning maps.
  final String name;

  /// Reads every row from the live table and returns it as JSON maps.
  final Future<List<Map<String, dynamic>>> Function() dump;

  /// Merges archive rows into the live table. When [resolver] is not
  /// null and a conflict is detected, it is consulted before applying
  /// the default LWW (last-write-wins) policy.
  final Future<UpsertCounters> Function(
    List<Map<String, dynamic>> rows,
    ConflictResolver? resolver,
  ) upsert;
}
