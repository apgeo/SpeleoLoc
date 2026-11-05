import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile_repository.dart';

void main() {
  late AppDatabase db;
  var keystoreRefuses = false;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async {
            if (call.method == 'write' && keystoreRefuses) {
              throw PlatformException(code: 'keystore');
            }
            return null;
          },
        );
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    keystoreRefuses = false;
  });
  tearDown(() => db.close());

  const profile = FtpProfile(
    profileUuid: 'sftp-1',
    displayName: 'Test SFTP',
    protocol: FtpProtocol.sftp,
    host: 'sftp.example.test',
    port: null,
    username: 'caver',
    remoteFolder: '/',
  );

  test(
    'a password the keystore refuses leaves no profile without one',
    () async {
      keystoreRefuses = true;
      final repository = FtpProfileRepository(db);

      await expectLater(
        repository.save(profile, password: 'pw'),
        throwsA(isA<PlatformException>()),
      );

      expect(await repository.list(), isEmpty);
    },
  );
}
