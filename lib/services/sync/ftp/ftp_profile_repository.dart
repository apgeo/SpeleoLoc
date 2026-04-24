import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Persists the user's configured FTP/SFTP endpoints plus their passwords.
///
/// - Profile metadata lives in the `configurations` table as a JSON array
///   under [ConfigKey.ftpProfiles]. Plain text there is fine: the DB is local
///   to the device and already holds the entire caving dataset.
/// - Passwords live in the OS keystore (`flutter_secure_storage`) keyed by
///   `ftp_password_<profileUuid>`. On devices without a hardware keystore
///   (eg. older Linux desktops) the plugin falls back to an encrypted file;
///   still substantially better than dropping secrets in SQLite.
///
/// The repository is intentionally thin — no caching, no change streams.
/// Settings UI calls [list] on open and [save]/[delete]/[setDefaultUuid]
/// on explicit user actions.
class FtpProfileRepository {
  final AppDatabase _db;
  final FlutterSecureStorage _storage;
  final _log = AppLogger.of('FtpProfileRepository');

  static const String _passwordKeyPrefix = 'ftp_password_';

  FtpProfileRepository(this._db, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // ---- profile list ----

  Future<List<FtpProfile>> list() async {
    final raw = await _readConfig(ConfigKey.ftpProfiles);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, Object?>>()
          .map(FtpProfile.fromJson)
          .toList();
    } catch (e) {
      _log.warning('Failed to decode stored FTP profiles: $e');
      return const [];
    }
  }

  /// Upserts [profile] and (if non-null) updates its password in the keystore.
  /// Pass `password == null` when the user edits a profile without retyping
  /// the password — the existing password is preserved.
  Future<void> save(FtpProfile profile, {String? password}) async {
    final current = await list();
    final idx =
        current.indexWhere((p) => p.profileUuid == profile.profileUuid);
    final updated = List<FtpProfile>.from(current);
    if (idx >= 0) {
      updated[idx] = profile;
    } else {
      updated.add(profile);
    }
    await _writeConfig(
      ConfigKey.ftpProfiles,
      jsonEncode(updated.map((p) => p.toJson()).toList()),
    );
    if (password != null) {
      await _storage.write(
        key: _passwordKey(profile.profileUuid),
        value: password,
      );
    }
    // If this is the only profile, auto-default it for convenience.
    if (updated.length == 1) {
      await setDefaultUuid(profile.profileUuid);
    }
  }

  Future<void> delete(String profileUuid) async {
    final current = await list();
    final updated =
        current.where((p) => p.profileUuid != profileUuid).toList();
    await _writeConfig(
      ConfigKey.ftpProfiles,
      jsonEncode(updated.map((p) => p.toJson()).toList()),
    );
    try {
      await _storage.delete(key: _passwordKey(profileUuid));
    } catch (e) {
      _log.warning('Secure-storage delete failed for $profileUuid: $e');
    }
    final defaultUuid = await getDefaultUuid();
    if (defaultUuid == profileUuid) {
      if (updated.isNotEmpty) {
        await setDefaultUuid(updated.first.profileUuid);
      } else {
        await _deleteConfig(ConfigKey.ftpDefaultProfileUuid);
      }
    }
  }

  Future<String?> readPassword(String profileUuid) async {
    try {
      return await _storage.read(key: _passwordKey(profileUuid));
    } catch (e) {
      _log.warning('Secure-storage read failed for $profileUuid: $e');
      return null;
    }
  }

  // ---- default profile ----

  Future<String?> getDefaultUuid() async =>
      _readConfig(ConfigKey.ftpDefaultProfileUuid);

  Future<void> setDefaultUuid(String profileUuid) async {
    await _writeConfig(ConfigKey.ftpDefaultProfileUuid, profileUuid);
  }

  /// Convenience: the full [FtpProfile] marked as default, or null if none.
  Future<FtpProfile?> getDefaultProfile() async {
    final uuid = await getDefaultUuid();
    if (uuid == null) return null;
    final all = await list();
    for (final p in all) {
      if (p.profileUuid == uuid) return p;
    }
    return null;
  }

  // ---- private helpers: mirror CurrentUserService config access ----

  String _passwordKey(String profileUuid) => '$_passwordKeyPrefix$profileUuid';

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
