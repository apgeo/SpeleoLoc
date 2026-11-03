import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/settings/ftp_sync_settings_page.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile_repository.dart';

/// The profile editor shows what the connection checks: for FTPS a warning
/// instead of a certificate switch that would change nothing.
void main() {
  late AppDatabase db;

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
  });
  tearDown(() => db.close());

  Future<void> openEditor(WidgetTester tester, FtpProfile profile) async {
    final container = ProviderContainer(
      overrides: <Override>[appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await FtpProfileRepository(db).save(profile);

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
  });
}
