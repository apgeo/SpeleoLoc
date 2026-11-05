import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/settings/silexgis_decisions_page.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';

/// Going back to the server's version gives up the caver's own, so it is
/// asked first.
void main() {
  late AppDatabase db;
  late ProviderContainer container;
  final caveId = Uuid.v7();

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pump(
    WidgetTester tester, {
    Map<String, Object?>? current,
    bool deletedOnServer = false,
  }) async {
    container = ProviderContainer(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(db),
        // The real one reaches for the platform keystore, which no test has.
        silexgisTokenStoreProvider.overrideWithValue(
          InMemoryRefreshTokenStore(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(silexgisProfileRepositoryProvider)
        .save(
          const SilexgisProfile(
            profileUuid: 'p-1',
            displayName: 'Invented club',
            baseUrl: 'https://club.example.org',
            syncSetId: 'set-1',
          ),
        );
    await db
        .into(db.caves)
        .insert(
          CavesCompanion.insert(uuid: caveId, title: 'Edited underground'),
        );
    await container
        .read(silexgisLocalStateProvider)
        .writeRevision(
          'p-1',
          caveId,
          entityTable: 'caves',
          wireKind: 'cave',
          revision: '2026-10-01T08:00:00Z',
        );
    if (deletedOnServer) {
      await container
          .read(silexgisHeldRowsProvider)
          .recordDeletedOnServer('p-1', caveId, entityTable: 'caves');
      await container.read(silexgisLocalStateProvider).forgetRevisions(
        'p-1',
        <Uuid>[caveId],
      );
    } else {
      await container
          .read(silexgisHeldRowsProvider)
          .recordConflicts('p-1', <SilexgisConflictEntry>[
            SilexgisConflictEntry(
              section: SyncUploadSection.rows,
              entityUuid: caveId,
              entityTable: 'caves',
              wireKind: 'cave',
              code: 'sync.conflict',
              current: current,
            ),
          ]);
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SilexgisDecisionsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<bool> stillToDecide() async =>
      (await container.read(silexgisHeldRowsProvider).readAll('p-1')).any(
        (held) => held.awaitsCaver,
      );

  testWidgets('cancelled, nothing changes', (tester) async {
    await pump(tester);

    await tester.tap(find.text('silexgis_decision_reread'));
    await tester.pumpAndSettle();
    expect(find.text('silexgis_review_use_server_title'), findsOneWidget);
    await tester.tap(find.text('cancel'));
    await tester.pumpAndSettle();

    expect(await tester.runAsync(stillToDecide), isTrue);
  });

  testWidgets('confirmed, the caver\'s version is given up', (tester) async {
    await pump(tester);

    await tester.tap(find.text('silexgis_decision_reread'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('silexgis_review_use_server'),
      ),
    );
    await tester.pumpAndSettle();

    expect(await tester.runAsync(stillToDecide), isFalse);
  });

  testWidgets('sending mine anyway says what it overwrites, and asks first', (
    tester,
  ) async {
    await pump(
      tester,
      current: <String, Object?>{
        'id': caveId.toString(),
        'name': 'Theirs',
        'updatedAt': '2026-10-28T07:30:00Z',
      },
    );

    await tester.tap(find.text('silexgis_review_send_mine'));
    await tester.pumpAndSettle();
    expect(find.text('silexgis_review_send_mine_title'), findsOneWidget);
    expect(find.text('silexgis_review_send_mine_body'), findsOneWidget);
    await tester.tap(find.text('cancel'));
    await tester.pumpAndSettle();
    expect(await tester.runAsync(stillToDecide), isTrue);

    await tester.tap(find.text('silexgis_review_send_mine'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('silexgis_review_send_mine'),
      ),
    );
    await tester.pumpAndSettle();
    expect(await tester.runAsync(stillToDecide), isFalse);
  });

  group('a cave deleted on the server', () {
    Future<void> confirm(WidgetTester tester, String action) async {
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(action),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('kept, after being told an edit sends it again as new', (
      tester,
    ) async {
      await pump(tester, deletedOnServer: true);

      await tester.tap(find.text('silexgis_review_keep_mine'));
      await tester.pumpAndSettle();
      expect(find.text('silexgis_decision_keep_title'), findsOneWidget);
      expect(find.text('silexgis_decision_keep_body'), findsOneWidget);
      await confirm(tester, 'silexgis_review_keep_mine');

      expect(await tester.runAsync(stillToDecide), isFalse);
      // Still listed, kept, and it can still be sent again.
      expect(
        find.textContaining('silexgis_decision_kept_here'),
        findsOneWidget,
      );
      expect(find.text('silexgis_review_keep_mine'), findsNothing);
      expect(find.text('silexgis_review_send_again'), findsOneWidget);
    });

    testWidgets('sent again as new, after saying what that does', (
      tester,
    ) async {
      await pump(tester, deletedOnServer: true);

      await tester.tap(find.text('silexgis_review_send_again'));
      await tester.pumpAndSettle();
      expect(find.text('silexgis_review_send_again_title'), findsOneWidget);
      expect(find.text('silexgis_review_send_again_body'), findsOneWidget);
      await confirm(tester, 'silexgis_review_send_again');

      final caves = await tester.runAsync(() => db.select(db.caves).get());
      expect(caves!.single.uuid, isNot(caveId));
      expect(find.text('silexgis_review_none'), findsOneWidget);
    });
  });
}
