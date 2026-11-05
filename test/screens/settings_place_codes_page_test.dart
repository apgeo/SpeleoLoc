import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/settings/settings_place_codes_page.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/service_locator.dart';

/// The place-code settings feed every label that is printed afterwards, so
/// what the page shows has to be what it stored.
void main() {
  late AppDatabase db;
  late _HeldHashWrites repo;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = _HeldHashWrites(db);
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        configurationRepositoryProvider.overrideWithValue(repo),
      ],
    );
    initRootContainer(container);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> openPage(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsPlaceCodesPage(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<Map<String, dynamic>> stored(String key) =>
      configurationRepository.readJson(key);

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('a separator the scanner would cut at is not stored', (
    tester,
  ) async {
    await openPage(tester);

    await tester.enterText(field('segment_separator'), '/');
    await tester.pumpAndSettle();

    expect(find.text('segment_separator_unscannable'), findsOneWidget);
    final blob = await tester.runAsync(
      () => stored(ConfigKey.placeCodeStrategyConfig),
    );
    expect(blob, isEmpty);
  });

  testWidgets('a usable separator is stored', (tester) async {
    await openPage(tester);

    await tester.enterText(field('segment_separator'), '-');
    await tester.pumpAndSettle();

    final blob = await tester.runAsync(
      () => stored(ConfigKey.placeCodeStrategyConfig),
    );
    final strategy = blob!.values.single as Map;
    expect(strategy['segment_separator'], '-');
  });

  testWidgets('a salt typed before leaving by Back is stored, trimmed', (
    tester,
  ) async {
    await configurationRepository.writeString(ConfigKey.qcriMode, 'hash');
    await openPage(tester);

    await tester.tap(find.text('place_code_tab_qcri'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '  pepper ');
    await tester.pumpAndSettle();

    // The system Back gesture is not a pointer event, so nothing taps
    // outside the field first.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPlaceCodesPage), findsNothing);

    final hash = await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return stored(ConfigKey.qcriHashConfig);
    });
    expect(hash!['salt'], 'pepper');
  });

  testWidgets('a salt being saved by tapping outside is not written again '
      'on Back', (tester) async {
    await configurationRepository.writeString(ConfigKey.qcriMode, 'hash');
    await openPage(tester);
    await tester.tap(find.text('place_code_tab_qcri'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'pepper');
    await tester.pump();

    repo.hold = Completer<void>();
    await tester.tapAt(const Offset(5, 300));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPlaceCodesPage), findsNothing);

    expect(repo.hashWrites.map((w) => w['salt']), ['pepper']);
    repo.hold!.complete();
    await tester.pump();
  });

  testWidgets('a switch whose save finishes after Back leaves the closed page '
      'alone', (tester) async {
    await openPage(tester);
    await tester.tap(find.text('place_code_tab_qcri'));
    await tester.pumpAndSettle();

    repo.hold = Completer<void>();
    await tester.tap(find.text('qcri_entrance_hash_in_mirror_mode'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPlaceCodesPage), findsNothing);

    repo.hold!.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(repo.hashWrites.single['entrance_hash'], isTrue);
  });
}

/// Records the QCRI hash config writes and, while [hold] is set, keeps them
/// in flight until the test completes it.
class _HeldHashWrites extends ConfigurationRepository {
  _HeldHashWrites(super.db);

  Completer<void>? hold;
  final hashWrites = <Map<String, dynamic>>[];

  @override
  Future<void> writeJson(
    String key,
    Map<String, dynamic> value, {
    bool isSynced = false,
  }) async {
    if (key == ConfigKey.qcriHashConfig) {
      hashWrites.add(Map.of(value));
      await hold?.future;
    }
    await super.writeJson(key, value, isSynced: isSynced);
  }
}
