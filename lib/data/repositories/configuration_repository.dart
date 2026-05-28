import 'dart:convert';

import 'package:speleoloc/data/source/database/app_database.dart';

/// Read/write API for the `configurations` table — the app-wide key/value
/// store keyed by `title` (UNIQUE).
///
/// Rationale: prior to this repository, five separate files
/// (`main.dart`, `SettingsHelper`, `DeepLinkHandler.saveLastOpenCave`,
/// `CurrentUserService`, `CaveTripService._saveConfig`) each rolled their
/// own read-then-insert-or-replace logic against the `configurations`
/// table. That duplication is exactly the kind of thing PR 1 of the
/// refactor plan (see `docs/REFACTORING_PLAN.md`) eliminates.
///
/// Concurrency: writes use a single SQL `INSERT … ON CONFLICT(title) DO
/// UPDATE` so they are atomic at the SQLite level and cannot lose the
/// row in a race with another writer.
abstract class IConfigurationRepository {
  /// Returns the value stored under [key], or `null` when no row exists.
  Future<String?> readString(String key);

  /// Upserts [value] under [key].
  ///
  /// [isSynced] is honoured **only when inserting a new row**; on conflict
  /// the existing row's `is_synced` flag is preserved. This matches the
  /// historical behaviour of `CurrentUserService._writeConfig`.
  Future<void> writeString(
    String key,
    String value, {
    bool isSynced = false,
  });

  /// Decodes the value stored under [key] as JSON.
  ///
  /// Returns the result of [defaults] (or an empty map when [defaults] is
  /// null) when the row is missing or the value cannot be parsed.
  Future<Map<String, dynamic>> readJson(
    String key, {
    Map<String, dynamic> Function()? defaults,
  });

  /// JSON-encodes [value] and upserts it under [key]. See [writeString] for
  /// [isSynced] semantics.
  Future<void> writeJson(
    String key,
    Map<String, dynamic> value, {
    bool isSynced = false,
  });

  /// Removes the row stored under [key]. No-op when the row does not exist.
  Future<void> delete(String key);
}

class ConfigurationRepository implements IConfigurationRepository {
  ConfigurationRepository(this._db);

  final AppDatabase _db;

  @override
  Future<String?> readString(String key) async {
    final row = await (_db.select(_db.configurations)
          ..where((c) => c.title.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> writeString(
    String key,
    String value, {
    bool isSynced = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customStatement(
      'INSERT INTO configurations '
      '(title, value, is_synced, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?) '
      'ON CONFLICT(title) DO UPDATE SET '
      'value = excluded.value, updated_at = excluded.updated_at',
      [key, value, isSynced ? 1 : 0, now, now],
    );
  }

  @override
  Future<Map<String, dynamic>> readJson(
    String key, {
    Map<String, dynamic> Function()? defaults,
  }) async {
    final raw = await readString(key);
    if (raw == null) return defaults?.call() ?? <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return defaults?.call() ?? <String, dynamic>{};
    } catch (_) {
      // Corrupt payload — surface the caller's default rather than crashing.
      return defaults?.call() ?? <String, dynamic>{};
    }
  }

  @override
  Future<void> writeJson(
    String key,
    Map<String, dynamic> value, {
    bool isSynced = false,
  }) =>
      writeString(key, jsonEncode(value), isSynced: isSynced);

  @override
  Future<void> delete(String key) async {
    await (_db.delete(_db.configurations)
          ..where((c) => c.title.equals(key)))
        .go();
  }
}
