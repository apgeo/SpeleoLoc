import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:speleoloc/services/sync/ftp/sftp_host_key.dart';

/// Device-only record of the host key each SFTP profile trusts.
///
/// Kept in the OS keystore next to the profile passwords rather than in the
/// database: the database travels in full exports and its `configurations`
/// rows can be rewritten by imports, and a trusted key that an archive could
/// plant or replace would defeat the check it exists for.
///
/// Read failures are not swallowed. Treating an unreadable record as "no key
/// recorded yet" would silently trust whichever server answers next.
class FtpHostKeyStore {
  final FlutterSecureStorage _storage;

  static const String _keyPrefix = 'ftp_host_key_';

  FtpHostKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<SftpHostKey?> read(String profileUuid) async {
    final raw = await _storage.read(key: _key(profileUuid));
    if (raw == null) return null;
    return SftpHostKey.decode(raw);
  }

  Future<void> write(String profileUuid, SftpHostKey hostKey) =>
      _storage.write(key: _key(profileUuid), value: hostKey.encode());

  Future<void> forget(String profileUuid) =>
      _storage.delete(key: _key(profileUuid));

  String _key(String profileUuid) => '$_keyPrefix$profileUuid';
}
