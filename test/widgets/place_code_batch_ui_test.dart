import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/place_code/batch/place_code_batch_runner.dart';
import 'package:speleoloc/widgets/place_code_batch_ui.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// A runner that fails the way a locked or full database would.
class _FailingRunner implements PlaceCodeBatchRunner {
  @override
  Future<PlaceCodeBatchSummary> run({
    required PlaceCodeBatchScope scope,
    required OverwritePromptCallback onPrompt,
    BatchProgressCallback? onProgress,
    BatchCancellationToken? cancellationToken,
  }) async {
    throw StateError('database is locked');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('a batch that throws closes its dialog and says why', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Stack(
          children: [
            SizedBox.expand(child: child),
            const AppToastHost(),
          ],
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => PlaceCodeBatchUi.run(
                context,
                runner: _FailingRunner(),
                scope: const GlobalScope(),
                confirmTitle: 'confirm title',
                confirmBody: 'confirm body',
              ),
              child: const Text('start'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('generate_codes'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('database is locked'), findsOneWidget);
    // Let the toast expire so no timer outlives the test.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });
}
