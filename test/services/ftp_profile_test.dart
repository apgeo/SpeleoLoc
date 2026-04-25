import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';

void main() {
  group('FtpProfile', () {
    test('round-trips through JSON without losing fields', () {
      final profile = const FtpProfile(
        profileUuid: '018f5b7a-0000-7abc-9000-000000000001',
        displayName: 'Team NAS',
        protocol: FtpProtocol.sftp,
        host: 'nas.example.org',
        port: 2222,
        username: 'caver',
        remoteFolder: '/speleo/sync/',
        passiveMode: false,
        allowInvalidCertificate: true,
      );
      final encoded = profile.encode();
      final decoded = FtpProfile.decode(encoded);
      expect(decoded.profileUuid, profile.profileUuid);
      expect(decoded.displayName, profile.displayName);
      expect(decoded.protocol, profile.protocol);
      expect(decoded.host, profile.host);
      expect(decoded.port, profile.port);
      expect(decoded.username, profile.username);
      expect(decoded.remoteFolder, profile.remoteFolder);
      expect(decoded.passiveMode, profile.passiveMode);
      expect(decoded.allowInvalidCertificate, profile.allowInvalidCertificate);
    });

    test('effectivePort falls back to the protocol default when port is null',
        () {
      final ftp = const FtpProfile(
        profileUuid: '1',
        displayName: 'a',
        protocol: FtpProtocol.ftp,
        host: 'h',
        port: null,
        username: 'u',
        remoteFolder: '/',
      );
      expect(ftp.effectivePort, 21);

      final ftps = ftp.copyWith(protocol: FtpProtocol.ftps);
      expect(ftps.effectivePort, 21);

      final sftp = ftp.copyWith(protocol: FtpProtocol.sftp);
      expect(sftp.effectivePort, 22);
    });

    test('copyWith(clearPort: true) resets the port to null', () {
      final p = const FtpProfile(
        profileUuid: '1',
        displayName: 'a',
        protocol: FtpProtocol.ftp,
        host: 'h',
        port: 2121,
        username: 'u',
        remoteFolder: '/',
      );
      expect(p.copyWith(clearPort: true).port, isNull);
    });

    test('decode tolerates missing optional fields and unknown protocol', () {
      final p = FtpProfile.fromJson({
        'profileUuid': '7',
        'displayName': 'x',
        'host': 'y',
        'username': 'z',
        'remoteFolder': '/',
        'protocol': 'bogus',
      });
      expect(p.protocol, FtpProtocol.ftp);
      expect(p.passiveMode, isTrue);
      expect(p.allowInvalidCertificate, isFalse);
      expect(p.port, isNull);
    });
  });
}
