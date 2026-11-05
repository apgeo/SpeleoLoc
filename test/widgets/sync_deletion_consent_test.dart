import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/widgets/sync_deletion_consent.dart';

/// Before an import deletes records here, the user is asked, and only the
/// explicit "delete" answer lets the deletions through.
void main() {
  Future<bool> ask(WidgetTester tester, Future<void> Function() choose) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    final answer = showSyncDeletionConsentDialog(
      context,
      deletes: 3,
      inserts: 1,
      updates: 2,
    );
    await tester.pumpAndSettle();
    await choose();
    await tester.pumpAndSettle();
    return answer;
  }

  testWidgets('"delete and import" allows the deletions', (tester) async {
    expect(
      await ask(tester, () => tester.tap(find.byType(FilledButton))),
      true,
    );
  });

  testWidgets('"keep my records" refuses them', (tester) async {
    expect(await ask(tester, () => tester.tap(find.byType(TextButton))), false);
  });

  testWidgets('dismissing the dialog refuses them', (tester) async {
    expect(await ask(tester, () => tester.tapAt(const Offset(5, 5))), false);
  });

  testWidgets('the inline card reports each answer', (tester) async {
    final answers = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SyncDeletionConsentCard(
            archiveName: 'speleo_loc_sync_1000_deadbeef.zip',
            deletes: 3,
            inserts: 1,
            updates: 2,
            onApply: () => answers.add(true),
            onKeep: () => answers.add(false),
          ),
        ),
      ),
    );

    expect(find.text('speleo_loc_sync_1000_deadbeef.zip'), findsOneWidget);
    await tester.tap(find.byType(OutlinedButton));
    await tester.tap(find.byType(FilledButton));
    expect(answers, [false, true]);
  });
}
