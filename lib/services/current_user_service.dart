import 'package:flutter/foundation.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/trip_log_method.dart';
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
  /// JSON map `{ profileUuid: timestampMs }` — the wall-clock time of the
  /// most recent successful upload to that profile. Used to decide whether
  /// a fresh upload is needed (local has unsynced changes when the latest
  /// `change_log.changed_at` is newer than this timestamp).
  static const String ftpLastUploadAt = 'ftp_last_upload_at';
  /// Active trip log generation method id (see [TripLogMethod]).
  static const String tripLogMethod = 'trip_log_method';

  // ----- Place-code identifier (PCI) configuration -----
  /// Selected PCI assignment strategy id (e.g. `global_hierarchical`,
  /// `per_cave_sequential`, `per_area_sequential`). Synced.
  static const String placeCodeStrategy = 'place_code_strategy';
  /// JSON-encoded strategy-specific configuration (width, separator, alphabet
  /// hint, etc.). Synced.
  static const String placeCodeStrategyConfig = 'place_code_strategy_config';
  /// QCRI mode (`plain` or `hash`). Synced.
  static const String qcriMode = 'qcri_mode';
  /// JSON-encoded QCRI hash configuration (length, retry settings). Synced.
  static const String qcriHashConfig = 'qcri_hash_config';

  // ----- Archive / sync import-export behaviour -----
  /// JSON object controlling archive import/export behaviour.
  /// Schema: `{ "copy_device_uuid_from_archive_on_import": bool }`.
  /// Default (absent key or absent field): all flags are `false`.
  ///
  /// `copy_device_uuid_from_archive_on_import` — when `true`, the
  /// device_uuid found inside the imported archive is written into
  /// `configurations` after a replace-import, overriding the local
  /// device identity.  When `false` (default) the local device_uuid
  /// is preserved across replace-imports.
  static const String archiveSyncImportExportConfig =
      'archive_sync_import_export_config';
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
  CurrentUserService(this._db, this._users, this._configs);

  // Reserved: PR 2 of the refactor plan (`docs/REFACTORING_PLAN.md`) will
  // route the remaining direct DB access here through `_db`. Until then it
  // is referenced only by the constructor so tests and the production
  // provider can pass a real DB without further plumbing churn.
  // ignore: unused_field
  final AppDatabase _db;
  final IUserRepository _users;
  final IConfigurationRepository _configs;
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

  /// Reads the active trip log generation method from `configurations`.
  /// Falls back to [TripLogMethod.classic] when unset or unrecognized.
  Future<TripLogMethod> getTripLogMethod() async {
    final id = await _readConfig(ConfigKey.tripLogMethod);
    return TripLogMethod.fromId(id);
  }

  /// Persists the active trip log generation method.
  Future<void> setTripLogMethod(TripLogMethod method) async {
    await _writeConfig(ConfigKey.tripLogMethod, method.id);
  }

  Future<String?> _readConfig(String title) => _configs.readString(title);

  Future<void> _writeConfig(String title, String value) =>
      _configs.writeString(title, value);

  Future<void> _deleteConfig(String title) => _configs.delete(title);
}
