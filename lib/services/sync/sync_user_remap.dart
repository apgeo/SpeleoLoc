import 'package:speleoloc/data/source/database/app_database.dart';

/// Maps incoming users onto local users of the same `username`.
///
/// This is what makes seed users (notably the auto-generated `system` user,
/// whose UUID is independently allocated on every device) importable across
/// devices: instead of inserting the incoming row (which would fail on the
/// UNIQUE(username) constraint) and orphaning every FK that references the
/// incoming UUID, all those references are rewritten to the local UUID and
/// normal last-writer-wins handles the row itself.
class SyncUserRemap {
  const SyncUserRemap._(this._remap);

  /// Incoming user uuid string to local user uuid string.
  final Map<String, String> _remap;

  bool get isEmpty => _remap.isEmpty;

  /// Inspects the incoming `users` rows against the local `users` table and
  /// maps every incoming user whose `username` already exists locally under
  /// a different UUID.
  static Future<SyncUserRemap> build(
    AppDatabase db,
    List<Map<String, dynamic>> rows,
    List<String> warnings,
  ) async {
    if (rows.isEmpty) return const SyncUserRemap._(<String, String>{});

    final localByUsername = <String, String>{};
    final localUuids = <String>{};
    for (final u in await db.select(db.users).get()) {
      localUuids.add(u.uuid.toString());
      localByUsername[u.username] = u.uuid.toString();
    }

    final remap = <String, String>{};
    for (final row in rows) {
      final incomingUuid = row['uuid'];
      final incomingUsername = row['username'];
      if (incomingUuid is! String || incomingUsername is! String) continue;
      if (localUuids.contains(incomingUuid)) continue;
      final localUuid = localByUsername[incomingUsername];
      if (localUuid == null) continue; // brand-new user — insert as-is
      remap[incomingUuid] = localUuid;
      warnings.add(
        'remapped user "$incomingUsername" '
        '$incomingUuid -> $localUuid (matched by username)',
      );
    }
    return SyncUserRemap._(remap);
  }

  /// Rewrites user-FK columns of [row]. For the `users` table the row's own
  /// `uuid` is also rewritten so the subsequent upsert resolves to the local
  /// row via LWW instead of attempting an insert that would violate the
  /// UNIQUE(username) constraint.
  void applyToRow(Map<String, dynamic> row, String tableName) {
    if (tableName == 'users') _remapField(row, 'uuid');
    _remapField(row, 'created_by_user_uuid');
    _remapField(row, 'last_modified_by_user_uuid');
  }

  /// Rewrites user-FK columns of a single `change_log` row. `entity_uuid` is
  /// also rewritten when the row targets the `users` table so that delete
  /// tombstones and field-history entries follow the remapped user identity.
  void applyToChangeLogRow(Map<String, dynamic> row) {
    _remapField(row, 'changed_by_user_uuid');
    if (row['entity_table'] == 'users') _remapField(row, 'entity_uuid');
  }

  void _remapField(Map<String, dynamic> row, String key) {
    final v = row[key];
    if (v is! String) return;
    final mapped = _remap[v];
    if (mapped != null) row[key] = mapped;
  }
}
