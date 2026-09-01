import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile_repository.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile_seed.dart';

const _seed = FtpSeedConfig(
  displayName: 'congress',
  protocol: FtpProtocol.ftp,
  host: 'ftp.example.org',
  port: null,
  username: 'shared@example.org',
  password: 'sekrit',
  remoteFolder: '/',
);

void main() {
  late AppDatabase db;
  late FtpProfileRepository repo;
  late Map<String, String> keystore;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    keystore = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final args = Map<String, dynamic>.from(call.arguments as Map);
          switch (call.method) {
            case 'write':
              keystore[args['key'] as String] = args['value'] as String;
              return null;
            case 'read':
              return keystore[args['key'] as String];
            case 'delete':
              keystore.remove(args['key'] as String);
              return null;
          }
          return null;
        });
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = FtpProfileRepository(db);
    keystore.clear();
  });

  tearDown(() async => db.close());

  test('creates the seeded profile and makes it the default', () async {
    await ensureSeededFtpProfile(repo, config: _seed);

    final profiles = await repo.list();
    expect(profiles, hasLength(1));
    expect(profiles.single.profileUuid, seededFtpProfileUuid);
    expect(profiles.single.displayName, 'congress');
    expect(profiles.single.host, 'ftp.example.org');
    expect(profiles.single.username, 'shared@example.org');
    expect(profiles.single.effectivePort, 21);
    expect(await repo.getDefaultUuid(), seededFtpProfileUuid);
    expect(await repo.readPassword(seededFtpProfileUuid), 'sekrit');
  });

  test('is idempotent and never overwrites user edits', () async {
    await ensureSeededFtpProfile(repo, config: _seed);
    final edited = (await repo.list()).single.copyWith(host: 'moved.example');
    await repo.save(edited, password: 'user-typed');

    await ensureSeededFtpProfile(repo, config: _seed);

    final profiles = await repo.list();
    expect(profiles, hasLength(1));
    expect(profiles.single.host, 'moved.example');
    expect(await repo.readPassword(seededFtpProfileUuid), 'user-typed');
  });

  test('does nothing when the build configures no host', () async {
    await ensureSeededFtpProfile(
      repo,
      config: const FtpSeedConfig(
        displayName: '',
        protocol: FtpProtocol.ftp,
        host: '',
        port: null,
        username: '',
        password: '',
        remoteFolder: '/',
      ),
    );
    expect(await repo.list(), isEmpty);
    expect(await repo.getDefaultUuid(), isNull);
  });

  test('becomes the active profile even when another default exists', () async {
    const other = FtpProfile(
      profileUuid: 'other',
      displayName: 'My NAS',
      protocol: FtpProtocol.sftp,
      host: 'nas.local',
      port: null,
      username: 'me',
      remoteFolder: '/',
    );
    await repo.save(other, password: 'pw');
    await repo.setDefaultUuid('other');

    await ensureSeededFtpProfile(repo, config: _seed);

    expect(await repo.list(), hasLength(2));
    expect(await repo.getDefaultUuid(), seededFtpProfileUuid);
  });
}
