import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_transport.dart';
import 'package:speleoloc/services/sync/ftp/ftp_transport_ftp.dart';
import 'package:speleoloc/services/sync/ftp/ftp_transport_sftp.dart';

/// Builds the right [IFtpTransport] implementation for a given profile.
///
/// Separated so tests and the engine can inject a fake transport via the
/// `buildTransport` parameter of `FtpSyncService`.
IFtpTransport defaultTransportBuilder(FtpProfile profile) {
  switch (profile.protocol) {
    case FtpProtocol.ftp:
    case FtpProtocol.ftps:
      return FtpTransportFtp(profile);
    case FtpProtocol.sftp:
      return FtpTransportSftp(profile);
  }
}

/// Injection point used by the settings screen and sync engine.
typedef FtpTransportBuilder = IFtpTransport Function(FtpProfile profile);
