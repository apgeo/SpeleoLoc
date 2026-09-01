import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Keeps a server profile's refresh token in the OS keystore.
///
/// The same split the FTP profiles use, for the same reason: profile metadata
/// is fine in the local database, which already holds the entire caving
/// dataset, but a credential is not — a plaintext export of that database
/// would carry it off. On a device without a hardware keystore the plugin
/// falls back to an encrypted file, which is still substantially better.
class SilexgisSecureTokenStore implements SilexgisRefreshTokenStore {
  SilexgisSecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _keyPrefix = 'silexgis_refresh_';

  final FlutterSecureStorage _storage;
  final _log = AppLogger.of('SilexgisSecureTokenStore');

  String _key(String profileUuid) => '$_keyPrefix$profileUuid';

  @override
  Future<String?> read(String profileUuid) async {
    try {
      return await _storage.read(key: _key(profileUuid));
    } on Exception catch (e) {
      _log.warning('Secure-storage read failed for $profileUuid: $e');
      return null;
    }
  }

  @override
  Future<void> write(String profileUuid, String refreshToken) =>
      _storage.write(key: _key(profileUuid), value: refreshToken);

  @override
  Future<void> delete(String profileUuid) async {
    try {
      await _storage.delete(key: _key(profileUuid));
    } on Exception catch (e) {
      _log.warning('Secure-storage delete failed for $profileUuid: $e');
    }
  }
}

/// A store that keeps nothing between runs. Used by tests, and by a profile a
/// caver asked not to be remembered.
class InMemoryRefreshTokenStore implements SilexgisRefreshTokenStore {
  final Map<String, String> _tokens = <String, String>{};

  @override
  Future<String?> read(String profileUuid) async => _tokens[profileUuid];

  @override
  Future<void> write(String profileUuid, String refreshToken) async =>
      _tokens[profileUuid] = refreshToken;

  @override
  Future<void> delete(String profileUuid) async => _tokens.remove(profileUuid);
}
