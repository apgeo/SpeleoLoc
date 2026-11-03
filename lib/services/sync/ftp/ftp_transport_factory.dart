import 'package:speleoloc/services/sync/ftp/ftp_host_key_store.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_transport.dart';
import 'package:speleoloc/services/sync/ftp/ftp_transport_ftp.dart';
import 'package:speleoloc/services/sync/ftp/ftp_transport_sftp.dart';
import 'package:speleoloc/services/sync/ftp/sftp_host_key_verifier.dart';

/// Injection point used by the settings screen and sync engine, so tests can
/// substitute a fake transport.
typedef FtpTransportBuilder = IFtpTransport Function(FtpProfile profile);

/// Builds the real transports. SFTP connections check the server's host key
/// against [hostKeys]; pass [confirmFirstUse] when a user is present to be
/// asked before a new key is trusted.
FtpTransportBuilder ftpTransportBuilder({
  required FtpHostKeyStore hostKeys,
  SftpHostKeyFirstUseConfirm? confirmFirstUse,
}) {
  return (profile) {
    switch (profile.protocol) {
      case FtpProtocol.ftp:
      case FtpProtocol.ftps:
        return FtpTransportFtp(profile);
      case FtpProtocol.sftp:
        return FtpTransportSftp(
          profile,
          hostKeyVerifier: SftpHostKeyVerifier(
            profile: profile,
            store: hostKeys,
            confirmFirstUse: confirmFirstUse,
          ),
        );
    }
  };
}
