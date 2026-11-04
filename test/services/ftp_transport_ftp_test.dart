import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/sync/ftp/ftp_host_key_store.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_transport.dart';
import 'package:speleoloc/services/sync/ftp/ftp_transport_factory.dart';

/// FTPS is refused before a socket is opened: ftpconnect cannot check the
/// server's certificate, so the password must never be sent over it.
void main() {
  late ServerSocket server;
  late List<Socket> accepted;

  setUp(() async {
    accepted = <Socket>[];
    server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    // Answers like a server turning clients away, so a client that does
    // dial gives up at once instead of waiting for its timeout.
    server.listen((s) {
      accepted.add(s);
      s.write('421 Service not available\r\n');
      s.close().ignore();
    });
  });
  tearDown(() => server.close());

  FtpProfile profileFor(FtpProtocol protocol) => FtpProfile(
    profileUuid: 'ftps-uuid',
    displayName: 'Old FTPS',
    protocol: protocol,
    host: InternetAddress.loopbackIPv4.address,
    port: server.port,
    username: 'caver',
    remoteFolder: '/',
  );

  test('an FTPS profile is refused without opening a connection', () async {
    final transport = ftpTransportBuilder(hostKeys: FtpHostKeyStore())(
      profileFor(FtpProtocol.ftps),
    );

    await expectLater(
      transport.connect(password: 'secret').timeout(const Duration(seconds: 5)),
      throwsA(isA<FtpsUnsupportedException>()),
    );
    await transport.disconnect();
    // Give a connection attempt, had one been made, time to be accepted.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(accepted, isEmpty);
  });

  test('a plain FTP profile still dials the server', () async {
    final transport = ftpTransportBuilder(hostKeys: FtpHostKeyStore())(
      profileFor(FtpProtocol.ftp),
    );

    await expectLater(
      transport
          .connect(password: 'secret')
          .timeout(const Duration(seconds: 10)),
      throwsA(isNot(isA<FtpsUnsupportedException>())),
    );
    await transport.disconnect();
    expect(accepted, isNotEmpty);
  });
}
