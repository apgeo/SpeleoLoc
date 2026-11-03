import 'dart:convert';
import 'dart:typed_data';

import 'package:speleoloc/services/sync/ftp/ftp_host_key_store.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_transport.dart';
import 'package:speleoloc/services/sync/ftp/sftp_host_key.dart';

/// Asks the user whether to trust [presented], the key of a server this
/// profile has not trusted yet. [previous] is the key recorded for the
/// address the profile pointed at before its host or port was edited.
///
/// Implemented by the UI. Unattended syncs pass none and trust on first use
/// without asking; the recorded key is then shown in the sync log and the
/// profile editor.
typedef SftpHostKeyFirstUseConfirm =
    Future<bool> Function(
      FtpProfile profile,
      SftpHostKey presented,
      SftpHostKey? previous,
    );

/// Trust-on-first-use check of an SFTP server's host key, for one connection.
///
/// - No key recorded yet: record the presented one (after [confirmFirstUse]
///   agrees, when given) and connect.
/// - The recorded key is presented again: connect.
/// - Any other key: refuse. The one exception is an interactive connection
///   ([confirmFirstUse] given) after the user edited the profile's host or
///   port, which asks as on first use and replaces the record if trusted.
///   Without a prompt that case is refused too, so an address rewritten
///   behind the user's back cannot be trusted silently.
class SftpHostKeyVerifier {
  final FtpProfile profile;
  final FtpHostKeyStore _store;
  final SftpHostKeyFirstUseConfirm? _confirmFirstUse;
  final DateTime Function() _now;

  Exception? _rejection;

  SftpHostKeyVerifier({
    required this.profile,
    required FtpHostKeyStore store,
    SftpHostKeyFirstUseConfirm? confirmFirstUse,
    DateTime Function()? now,
  }) : _store = store,
       _confirmFirstUse = confirmFirstUse,
       _now = now ?? DateTime.now;

  /// Why the last [verify] refused the key. The SSH library reports only a
  /// generic handshake failure, so the transport rethrows this instead.
  Exception? get rejection => _rejection;

  /// Signature of dartssh2's `onVerifyHostKey`; [fingerprint] is the UTF-8
  /// text `SHA256:<base64>`.
  Future<bool> verify(String keyType, Uint8List fingerprint) async {
    _rejection = null;
    final presented = SftpHostKey(
      host: profile.host,
      port: profile.effectivePort,
      keyType: keyType,
      fingerprint: utf8.decode(fingerprint),
      recordedAt: _now(),
    );
    final confirm = _confirmFirstUse;
    try {
      final trusted = await _store.read(profile.profileUuid);
      if (trusted != null) {
        if (trusted.sameKeyAs(presented)) return true;
        final addressEdited = trusted.endpoint != presented.endpoint;
        if (!addressEdited || confirm == null) {
          _rejection = FtpHostKeyMismatchException(
            expected: trusted,
            received: presented,
          );
          return false;
        }
      }
      if (confirm != null && !await confirm(profile, presented, trusted)) {
        _rejection = FtpHostKeyNotTrustedException(presented);
        return false;
      }
      await _store.write(profile.profileUuid, presented);
      return true;
    } catch (e) {
      _rejection = FtpTransportException(
        'Could not check the server host key against the one this profile '
        'trusts. Forget host key in the profile editor resets it.',
        e,
      );
      return false;
    }
  }
}
