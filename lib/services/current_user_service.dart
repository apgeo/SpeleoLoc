import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Well-known keys used in the `configurations` table.
///
/// Kept as string constants (not an enum) so callers can spell the key
/// exactly once and so new keys can be added without touching this file's
/// public API.
class ConfigKey {
  ConfigKey._();
  static const String deviceUuid = 'device_uuid';
  static const String currentUserUuid = 'current_user_uuid';
  static const String changeLogRetentionDays = 'change_log_retention_days';
  static const String tombstoneRetentionDays = 'tombstone_retention_days';
  // FTP sync (feat/sync-v2, Phase A).
  /// JSON array of [FtpProfile] — see `lib/services/sync/ftp/ftp_profile.dart`.
  static const String ftpProfiles = 'ftp_profiles';
  /// UUID of the profile selected as default for one-tap sync.
  static const String ftpDefaultProfileUuid = 'ftp_default_profile_uuid';
  /// JSON map `{ archiveFilename: iso8601Timestamp }` — filenames already
  /// imported from the remote (so future downloads skip them).
  static const String ftpSeenArchives = 'ftp_seen_archives';
}

/// Provides the identity used to populate `created_by_user_uuid` and
/// `last_modified_by_user_uuid` on every repository write, plus the
/// device's persistent UUID used on archive exports.
///
/// The current user is stored as a well-known row in the `configurations`
/// table (key = [ConfigKey.currentUserUuid]). Changing it emits a new
/// value on [currentUserUuid] so listeners (mostly the UI drawer) can
/// refresh.
///
/// The device UUID is seeded by the v9 migration. If the row is missing
/// (fresh install that started at v9) one is generated on first read.
class CurrentUserService {
  CurrentUserService(this._db, this._users);

  final AppDatabase _db;
  final IUserRepository _users;
  final _log = AppLogger.of('CurrentUserService');

  final ValueNotifier<Uuid?> currentUserUuid = ValueNotifier<Uuid?>(null);
  final ValueNotifier<Uuid?> deviceUuid = ValueNotifier<Uuid?>(null);

  bool _initialized = false;

  /// Loads `device_uuid` and `current_user_uuid` from `configurations` and
  /// publishes them on the notifiers. Safe to call multiple times.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    deviceUuid.value = await _readOrCreateDeviceUuid();
    currentUserUuid.value = await _readCurrentUserUuid();
    _log.info(
      'Initialized: device=${deviceUuid.value}, user=${currentUserUuid.value}',
    );
  }

  Future<Uuid?> _readCurrentUserUuid() async {
    final text = await _readConfig(ConfigKey.currentUserUuid);
    return Uuid.tryParse(text);
  }

  Future<Uuid> _readOrCreateDeviceUuid() async {
    final text = await _readConfig(ConfigKey.deviceUuid);
    final existing = Uuid.tryParse(text);
    if (existing != null) return existing;
    final fresh = Uuid.v7();
    await _writeConfig(ConfigKey.deviceUuid, fresh.toString());
    return fresh;
  }

  /// Returns the user UUID to stamp on writes. Throws if no current user is
  /// configured and no default can be created. Most call sites should use
  /// [currentOrSystem] instead.
  Future<Uuid> requireCurrent() async {
    final id = currentUserUuid.value;
    if (id == null) {
      throw StateError(
        'No current user is configured. Select one in Settings > Users.',
      );
    }
    return id;
  }

  /// Returns the currently selected user's UUID, or creates and selects a
  /// built-in "system" user if none exists. Used on first-run writes before
  /// the user has opened the Users settings page.
  Future<Uuid> currentOrSystem() async {
    final cur = currentUserUuid.value;
    if (cur != null) return cur;
    final existing = await _users.findByUsername('system');
    final id = existing?.uuid ??
        await _users.addUser(
          username: 'system',
          firstName: 'System',
          details: 'Auto-generated default user.',
        );
    await setCurrentUser(id);
    return id;
  }

  Future<void> setCurrentUser(Uuid uuid) async {
    await _writeConfig(ConfigKey.currentUserUuid, uuid.toString());
    currentUserUuid.value = uuid;
    _log.info('Current user changed to $uuid');
  }

  Future<void> clearCurrentUser() async {
    await _deleteConfig(ConfigKey.currentUserUuid);
    currentUserUuid.value = null;
  }

  Future<String?> _readConfig(String title) async {
    final rows = await _db.customSelect(
      'SELECT value FROM configurations WHERE title = ? LIMIT 1',
      variables: [Variable<String>(title)],
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.data['value'] as String?;
  }

  Future<void> _writeConfig(String title, String value) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customStatement(
      'INSERT INTO configurations (title, value, created_at, updated_at) '
      'VALUES (?, ?, ?, ?) '
      'ON CONFLICT(title) DO UPDATE SET value = excluded.value, '
      'updated_at = excluded.updated_at',
      [title, value, now, now],
    );
  }

  Future<void> _deleteConfig(String title) async {
    await _db.customStatement(
      'DELETE FROM configurations WHERE title = ?',
      [title],
    );
  }
}
