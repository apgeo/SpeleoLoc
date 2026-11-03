import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/sync/ftp/ftp_host_key_store.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile_repository.dart';
import 'package:speleoloc/services/sync/ftp/sftp_host_key.dart';

void main() {
  final secure = <String, String>{};

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final args = Map<String, dynamic>.from(call.arguments as Map);
          switch (call.method) {
            case 'write':
              secure[args['key'] as String] = args['value'] as String;
              return null;
            case 'read':
              return secure[args['key'] as String];
            case 'delete':
              secure.remove(args['key'] as String);
              return null;
          }
          return null;
        });
  });

  setUp(secure.clear);

  final key = SftpHostKey(
    host: 'sftp.example.test',
    port: 2222,
    keyType: 'ssh-ed25519',
    fingerprint: 'SHA256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    recordedAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
  );

  test('round-trips a trusted key and forgets it', () async {
    final store = FtpHostKeyStore();
    expect(await store.read('p1'), isNull);

    await store.write('p1', key);
    final back = (await store.read('p1'))!;
    expect(back.host, key.host);
    expect(back.port, key.port);
    expect(back.keyType, key.keyType);
    expect(back.fingerprint, key.fingerprint);
    expect(back.recordedAt, key.recordedAt);

    await store.forget('p1');
    expect(await store.read('p1'), isNull);
  });

  test('keeps the key out of the database', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = FtpProfileRepository(db);
    const profile = FtpProfile(
      profileUuid: 'p1',
      displayName: 'Test Server',
      protocol: FtpProtocol.sftp,
      host: 'sftp.example.test',
      port: 2222,
      username: 'caver',
      remoteFolder: '/',
    );
    await repo.save(profile, password: 'pw');
    await FtpHostKeyStore().write('p1', key);

    final rows = await db
        .customSelect('SELECT title, value FROM configurations')
        .get();
    for (final row in rows) {
      expect(row.data['value'] as String? ?? '', isNot(contains('SHA256:')));
    }
  });

  test('deleting a profile forgets the key it trusted', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = FtpProfileRepository(db);
    const profile = FtpProfile(
      profileUuid: 'p1',
      displayName: 'Test Server',
      protocol: FtpProtocol.sftp,
      host: 'sftp.example.test',
      port: 2222,
      username: 'caver',
      remoteFolder: '/',
    );
    await repo.save(profile, password: 'pw');
    final store = FtpHostKeyStore();
    await store.write('p1', key);

    await repo.delete('p1');

    expect(await store.read('p1'), isNull);
  });

  test('an unreadable record raises instead of reading as absent', () async {
    secure['ftp_host_key_p1'] = 'not json';
    expect(FtpHostKeyStore().read('p1'), throwsFormatException);
  });
}
