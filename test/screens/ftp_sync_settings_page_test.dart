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
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// A repository whose writes fail on demand, as a locked database or a
/// refusing keystore would.
class _FlakyProfileRepository extends FtpProfileRepository {
  _FlakyProfileRepository(super.db, {super.hostKeys});

  bool failSave = false;
  bool failDelete = false;

  @override
  Future<void> save(FtpProfile profile, {String? password}) async {
    if (failSave) throw StateError('keystore refused the write');
    return super.save(profile, password: password);
  }

  @override
  Future<void> delete(String profileUuid) async {
    if (failDelete) throw StateError('database is locked');
    return super.delete(profileUuid);
  }
}

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
/// trusts, with a way to forget it, and for an FTPS profile, which no longer
/// connects, how to move it to SFTP.
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

  Future<void> openEditor(
    WidgetTester tester,
    FtpProfile profile, {
    bool withToasts = false,
    String? password,
    FtpProfileRepository? repository,
  }) async {
    final container = ProviderContainer(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(db),
        ftpHostKeyStoreProvider.overrideWithValue(hostKeys),
        if (repository != null)
          ftpProfileRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await FtpProfileRepository(
      db,
      hostKeys: hostKeys,
    ).save(profile, password: password);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: const FtpSyncSettingsPage(),
          builder: withToasts
              ? (context, child) => Stack(
                  children: [
                    SizedBox.expand(child: child),
                    const AppToastHost(),
                  ],
                )
              : null,
        ),
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

  const ftps = FtpProfile(
    profileUuid: 'ftps-1',
    displayName: 'Test FTPS',
    protocol: FtpProtocol.ftps,
    host: 'ftps.example.test',
    port: null,
    username: 'caver',
    remoteFolder: '/',
  );

  testWidgets('a new profile is not offered FTPS', (tester) async {
    final container = ProviderContainer(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(db),
        ftpHostKeyStoreProvider.overrideWithValue(hostKeys),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FtpSyncSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<FtpProtocol>));
    await tester.pumpAndSettle();

    expect(find.text('ftp_protocol_sftp'), findsOneWidget);
    expect(find.text('ftp_protocol_ftps'), findsNothing);
    expect(find.text('ftp_ftps_unsupported'), findsNothing);
  });

  testWidgets('an FTPS profile says FTPS is no longer supported and can be '
      'switched to SFTP', (tester) async {
    await openEditor(tester, ftps);

    expect(find.text('ftp_ftps_unsupported'), findsOneWidget);
    expect(find.text('ftp_ftps_unsupported_desc'), findsOneWidget);
    // No FTP-only switch for a protocol that no longer connects.
    expect(find.byType(SwitchListTile), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<FtpProtocol>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ftp_protocol_sftp').last);
    await tester.pumpAndSettle();

    expect(find.text('ftp_ftps_unsupported'), findsNothing);
    await scrollTo(tester, find.text('ftp_host_key_none'));
    expect(find.text('ftp_host_key_none'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.save).first);
    await tester.pumpAndSettle();

    final saved = await FtpProfileRepository(db, hostKeys: hostKeys).list();
    expect(saved.single.profileUuid, 'ftps-1');
    expect(saved.single.protocol, FtpProtocol.sftp);
    expect(saved.single.effectivePort, 22);
  });

  testWidgets('switching an FTPS profile to SFTP drops its FTPS port', (
    tester,
  ) async {
    await openEditor(tester, ftps.copyWith(port: 990));

    await tester.tap(find.byType(DropdownButtonFormField<FtpProtocol>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ftp_protocol_sftp').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save).first);
    await tester.pumpAndSettle();

    final saved = await FtpProfileRepository(db, hostKeys: hostKeys).list();
    expect(saved.single.port, isNull);
    expect(saved.single.effectivePort, 22);
  });

  testWidgets('an FTPS profile lists FTPS only as its current, unselectable '
      'value', (tester) async {
    await openEditor(tester, ftps);
    await tester.tap(find.byType(DropdownButtonFormField<FtpProtocol>));
    await tester.pumpAndSettle();

    final items = tester
        .widgetList<DropdownMenuItem<FtpProtocol>>(
          find.byType(DropdownMenuItem<FtpProtocol>),
        )
        .toList();
    final ftpsItems = items.where((i) => i.value == FtpProtocol.ftps);
    expect(ftpsItems, isNotEmpty);
    expect(ftpsItems.every((i) => !i.enabled), isTrue);
    expect(items.where((i) => i.enabled).map((i) => i.value).toSet(), {
      FtpProtocol.ftp,
      FtpProtocol.sftp,
    });
  });

  testWidgets('testing an FTPS profile reports it unsupported', (tester) async {
    await openEditor(tester, ftps, withToasts: true, password: 'pw');

    final test = find.text('ftp_test_connection');
    await tester.ensureVisible(test);
    await tester.pumpAndSettle();
    await tester.tap(test);
    await tester.pumpAndSettle();

    // Once in the notice, once in the toast.
    expect(find.text('ftp_ftps_unsupported'), findsNWidgets(2));
    // Let the toast expire so no timer outlives the test.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('a save that fails says so and leaves the editor usable', (
    tester,
  ) async {
    final repository = _FlakyProfileRepository(db, hostKeys: hostKeys);
    await openEditor(
      tester,
      sftp,
      withToasts: true,
      password: 'pw',
      repository: repository,
    );
    repository.failSave = true;

    await tester.tap(find.byIcon(Icons.save).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('keystore refused the write'), findsOneWidget);
    expect(find.text('ftp_edit_profile'), findsOneWidget);
    final saveButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.save),
    );
    expect(saveButton.onPressed, isNotNull);

    // The edits are still there, so trying again once the cause is gone works.
    repository.failSave = false;
    await tester.pump(const Duration(seconds: 10));
    await tester.tap(find.byIcon(Icons.save).first);
    await tester.pumpAndSettle();
    expect(find.text('ftp_edit_profile'), findsNothing);
  });

  testWidgets('a delete that fails says so and the profile stays listed', (
    tester,
  ) async {
    final repository = _FlakyProfileRepository(db, hostKeys: hostKeys)
      ..failDelete = true;
    await repository.save(sftp, password: 'pw');
    final container = ProviderContainer(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(db),
        ftpHostKeyStoreProvider.overrideWithValue(hostKeys),
        ftpProfileRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: const FtpSyncSettingsPage(),
          builder: (context, child) => Stack(
            children: [
              SizedBox.expand(child: child),
              const AppToastHost(),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('delete'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('delete'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('database is locked'), findsOneWidget);
    expect(find.text(sftp.displayName), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });
}
