import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/widgets/filterable_list.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

void main() {
  Future<void> pumpList(
    WidgetTester tester, {
    required Future<void> Function(List<String>) onBulkDelete,
    bool confirmBulkDelete = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Stack(
          children: [
            SizedBox.expand(child: child),
            const AppToastHost(),
          ],
        ),
        home: Scaffold(
          body: FilterableList<String>(
            items: const ['one', 'two'],
            keyOf: (s) => s,
            itemBuilder: (context, s, _) => Text(s),
            searchableText: (s) => s,
            onBulkDelete: onBulkDelete,
            confirmBulkDelete: confirmBulkDelete,
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.checklist));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.select_all));
    await tester.pumpAndSettle();
  }

  Future<void> pressDelete(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.delete_sweep));
    await tester.pumpAndSettle();
  }

  Future<void> answerYes(WidgetTester tester) async {
    await tester.tap(find.text('yes'));
    await tester.pumpAndSettle();
  }

  testWidgets('a deletion that fails says so and keeps the selection', (
    tester,
  ) async {
    await pumpList(
      tester,
      onBulkDelete: (_) async => throw StateError('database is locked'),
    );

    await pressDelete(tester);
    await answerYes(tester);

    expect(find.textContaining('database is locked'), findsOneWidget);
    // Still in selection mode with both rows selected, so the caver can retry.
    expect(find.byIcon(Icons.delete_sweep), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('a second tap while the deletion runs does not start another', (
    tester,
  ) async {
    final running = Completer<void>();
    var calls = 0;
    await pumpList(
      tester,
      onBulkDelete: (_) {
        calls++;
        return running.future;
      },
    );

    await pressDelete(tester);
    await answerYes(tester);
    await pressDelete(tester);

    expect(calls, 1);
    expect(find.text('yes'), findsNothing);
    running.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('a caller that asks for itself is not asked for twice', (
    tester,
  ) async {
    final deleted = <String>[];
    await pumpList(
      tester,
      confirmBulkDelete: false,
      onBulkDelete: (items) async => deleted.addAll(items),
    );

    await pressDelete(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(deleted, ['one', 'two']);
  });
}
