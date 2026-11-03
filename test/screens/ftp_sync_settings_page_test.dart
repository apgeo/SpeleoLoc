import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/settings/ftp_sync_settings_page.dart';
import 'package:speleoloc/services/sync/ftp/ftp_host_key_store.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile_repository.dart';
import 'package:speleoloc/services/sync/ftp/sftp_host_key.dart';

class _MemoryHostKeyStore implements FtpHostKeyStore {
  final Map<String, SftpHostKey> keys = {};

  @override
  Future<SftpHostKey?> read(String profileUuid) async => keys[profileUuid];

  @override
  Future<void> write(String profileUuid, SftpHostKey hostKey) async {
    keys[profileUuid] = hostKey;
  }

  @override
  Future<void> forget(String profileUuid) async {
    keys.remove(profileUuid);
  }
}

const _fingerprint = 'SHA256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

/// The profile editor shows what the connection checks: the SFTP host key it
/// trusts, with a way to forget it, and for FTPS a warning instead of a
/// certificate switch that would change nothing.
void main() {
  late AppDatabase db;
  late _MemoryHostKeyStore hostKeys;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    final secure = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async {
            final args = Map<String, dynamic>.from(call.arguments as Map);
            final key = args['key'] as String?;
            switch (call.method) {
              case 'write':
                secure[key!] = args['value'] as String;
              case 'read':
                return secure[key];
              case 'delete':
                secure.remove(key);
            }
            return null;
          },
        );
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    hostKeys = _MemoryHostKeyStore();
  });
  tearDown(() => db.close());

  Future<void> openEditor(WidgetTester tester, FtpProfile profile) async {
    final container = ProviderContainer(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(db),
        ftpHostKeyStoreProvider.overrideWithValue(hostKeys),
      ],
    );
    addTearDown(container.dispose);
    await FtpProfileRepository(db, hostKeys: hostKeys).save(profile);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FtpSyncSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(profile.displayName));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );

  const sftp = FtpProfile(
    profileUuid: 'sftp-1',
    displayName: 'Test SFTP',
    protocol: FtpProtocol.sftp,
    host: 'sftp.example.test',
    port: null,
    username: 'caver',
    remoteFolder: '/',
  );

  testWidgets('an SFTP profile shows its trusted key and can forget it', (
    tester,
  ) async {
    hostKeys.keys['sftp-1'] = SftpHostKey(
      host: 'sftp.example.test',
      port: 22,
      keyType: 'ssh-ed25519',
      fingerprint: _fingerprint,
      recordedAt: DateTime.utc(2026, 1, 2, 3, 4),
    );
    await openEditor(tester, sftp);

    final keyText = find.text('ssh-ed25519 $_fingerprint');
    await scrollTo(tester, keyText);
    expect(keyText, findsOneWidget);

    final forget = find.widgetWithText(TextButton, 'ftp_host_key_forget');
    await tester.ensureVisible(forget);
    await tester.pumpAndSettle();
    await tester.tap(forget);
    await tester.pumpAndSettle();
    // The confirmation dialog's own button carries the same label.
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'ftp_host_key_forget'),
      ),
    );
    await tester.pumpAndSettle();

    expect(hostKeys.keys, isEmpty);
    expect(find.text('ftp_host_key_none'), findsOneWidget);
    expect(find.text('ssh-ed25519 $_fingerprint'), findsNothing);
  });

  testWidgets('an SFTP profile with no key yet says it is not recorded', (
    tester,
  ) async {
    await openEditor(tester, sftp);

    await scrollTo(tester, find.text('ftp_host_key_none'));
    expect(find.text('ftp_host_key_none'), findsOneWidget);
    expect(
      find.widgetWithText(TextButton, 'ftp_host_key_forget'),
      findsNothing,
    );
  });

  testWidgets('an FTPS profile warns that certificates are not checked and '
      'offers no certificate switch', (tester) async {
    await openEditor(
      tester,
      const FtpProfile(
        profileUuid: 'ftps-1',
        displayName: 'Test FTPS',
        protocol: FtpProtocol.ftps,
        host: 'ftps.example.test',
        port: null,
        username: 'caver',
        remoteFolder: '/',
      ),
    );

    await scrollTo(tester, find.text('ftp_ftps_cert_not_verified'));
    expect(find.text('ftp_ftps_cert_not_verified'), findsOneWidget);
    expect(find.text('ftp_allow_invalid_cert'), findsNothing);
    // Passive mode is the only switch an FTPS profile has.
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(find.text('ftp_host_key_title'), findsNothing);
  });
}
