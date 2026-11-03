import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/settings/silexgis_sync_settings_page.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';

/// The page renders in each of the states a caver can find it in — most of all
/// the one where no server is configured, which is the ordinary case and must
/// look like an invitation rather than a fault.
void main() {
  late AppDatabase db;
  late InMemoryRefreshTokenStore tokens;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tokens = InMemoryRefreshTokenStore();
  });
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, {SilexgisProfile? profile}) async {
    container = ProviderContainer(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(db),
        // The real one reaches for the platform keystore, which no test has.
        silexgisTokenStoreProvider.overrideWithValue(tokens),
      ],
    );
    addTearDown(container.dispose);

    if (profile != null) {
      await container.read(silexgisProfileRepositoryProvider).save(profile);
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SilexgisSyncSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The run card sits below the server's settings, past the first screen.
  Future<void> scrollToRun(WidgetTester tester) => tester.scrollUntilVisible(
    find.widgetWithText(FilledButton, 'silexgis_sync_now'),
    200,
    scrollable: find.byType(Scrollable).first,
  );

  testWidgets('with no server configured it invites rather than warns', (
    tester,
  ) async {
    await pump(tester);

    // A server profile is exactly as optional as an FTP one. Nothing here is a
    // failure, and nothing offers to sync.
    expect(find.text('silexgis_none_title'), findsOneWidget);
    expect(find.text('silexgis_add_server'), findsOneWidget);
    expect(find.text('silexgis_sync_now'), findsNothing);
  });

  testWidgets('a configured server with no selection cannot be synced yet', (
    tester,
  ) async {
    await pump(
      tester,
      profile: const SilexgisProfile(
        profileUuid: 'p-1',
        displayName: 'Clubul Speo Example',
        baseUrl: 'https://speo.example.org',
      ),
    );

    expect(find.text('Clubul Speo Example'), findsOneWidget);
    expect(find.text('silexgis_selection_none'), findsOneWidget);
    // Both run buttons are there and both are disabled: there is nothing to
    // sync until a caver chooses what this device carries.
    await scrollToRun(tester);
    final sync = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'silexgis_sync_now'),
    );
    expect(sync.onPressed, isNull);
    final fullRead = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'silexgis_full_read'),
    );
    expect(fullRead.onPressed, isNull);
  });

  testWidgets('with a selection chosen it offers to sync', (tester) async {
    await pump(
      tester,
      profile: const SilexgisProfile(
        profileUuid: 'p-1',
        displayName: 'Clubul Speo Example',
        baseUrl: 'https://speo.example.org',
        syncSetId: 'set-1',
      ),
    );

    // Off by default: a caver who picked the club's caves to carry would not
    // expect their own survey of an unrelated cave to be published.
    final toggle = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'silexgis_send_new_caves'),
    );
    await scrollToRun(tester);
    final sync = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'silexgis_sync_now'),
    );
    expect(sync.onPressed, isNotNull);
    expect(toggle.value, isFalse);
  });

  testWidgets('says what the installation offered on the last run', (
    tester,
  ) async {
    await pump(
      tester,
      profile: const SilexgisProfile(
        profileUuid: 'p-1',
        displayName: 'Clubul Speo Example',
        baseUrl: 'https://speo.example.org',
        syncSetId: 'set-1',
        servedFeatures: <String>['trips'],
      ),
    );

    await tester.scrollUntilVisible(
      find.text('silexgis_part_people'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('silexgis_parts_title'), findsOneWidget);
    expect(find.text('silexgis_part_trips'), findsOneWidget);
  });

  testWidgets('forgetting a server asks first, and says what it keeps', (
    tester,
  ) async {
    await pump(
      tester,
      profile: const SilexgisProfile(
        profileUuid: 'p-1',
        displayName: 'Clubul Speo Example',
        baseUrl: 'https://speo.example.org',
      ),
    );

    await tester.tap(find.text('silexgis_forget'));
    await tester.pumpAndSettle();

    expect(find.text('silexgis_forget_title'), findsOneWidget);
    // The caver's caves stay on the device; what goes is the stored sign-in
    // and this device's memory of the conversation.
    expect(find.text('silexgis_forget_body'), findsOneWidget);
  });

  group('editing the server', () {
    const signedIn = SilexgisProfile(
      profileUuid: 'p-1',
      displayName: 'Clubul Speo Example',
      baseUrl: 'https://speo.example.org',
      accountEmail: 'caver@example.org',
      syncSetId: 'set-1',
    );

    Future<void> pumpSignedIn(WidgetTester tester) async {
      await pump(tester, profile: signedIn);
      await tokens.write('p-1', 'refresh-token');
    }

    Future<void> edit(
      WidgetTester tester, {
      String? name,
      String? address,
    }) async {
      await tester.tap(find.byTooltip('edit'));
      await tester.pumpAndSettle();
      if (name != null) {
        await tester.enterText(
          find.widgetWithText(TextField, 'silexgis_server_name'),
          name,
        );
      }
      if (address != null) {
        await tester.enterText(
          find.widgetWithText(TextField, 'silexgis_server_url'),
          address,
        );
      }
      await tester.tap(find.widgetWithText(FilledButton, 'save'));
      await tester.pumpAndSettle();
    }

    Future<SilexgisProfile> stored() async =>
        (await container.read(silexgisProfileRepositoryProvider).find('p-1'))!;

    testWidgets('a plain http address is refused and the dialog stays open', (
      tester,
    ) async {
      await pumpSignedIn(tester);

      await edit(tester, address: 'http://speo.example.org');

      expect(find.text('silexgis_url_not_https'), findsOneWidget);
      expect(find.text('silexgis_server_change_title'), findsNothing);
      expect(await tokens.read('p-1'), 'refresh-token');
      expect((await stored()).baseUrl, 'https://speo.example.org');
    });
  });

  testWidgets('a stored plain http address says it has to be corrected', (
    tester,
  ) async {
    await pump(
      tester,
      profile: const SilexgisProfile(
        profileUuid: 'p-1',
        displayName: 'Clubul Speo Example',
        baseUrl: 'http://speo.example.org',
      ),
    );

    expect(find.text('silexgis_url_needs_fixing'), findsOneWidget);
  });
}
