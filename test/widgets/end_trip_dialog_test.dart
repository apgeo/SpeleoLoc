import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/end_trip_dialog.dart';

/// The question every one-tap way of ending a trip asks: it names the cave,
/// keeping the trip is the safe answer, and both answers are big enough for
/// gloved hands.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await LocServ.inst.setLocale('en');
    await LocServ.inst.load();
  });

  /// Opens the dialog for "Example Cave"; the answer is added to the returned
  /// list once the dialog closes.
  Future<List<bool>> ask(WidgetTester tester, {String? message}) async {
    final answers = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => answers.add(
              await showEndTripDialog(
                context,
                caveTitle: 'Example Cave',
                message: message,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return answers;
  }

  testWidgets('names the cave and the consequence', (tester) async {
    await ask(tester);

    expect(find.text('End the trip at Example Cave?'), findsOneWidget);
    expect(find.text(LocServ.inst.t('trip_end_dialog_body')), findsOneWidget);
    expect(find.text('End trip'), findsOneWidget);
    expect(find.text('Keep recording'), findsOneWidget);
  });

  testWidgets('both answers are at least 48 dp tall', (tester) async {
    await ask(tester);

    for (final key in ['end_trip_confirm', 'end_trip_keep']) {
      expect(
        tester.getSize(find.byKey(ValueKey(key))).height,
        greaterThanOrEqualTo(48),
        reason: key,
      );
    }
  });

  testWidgets('keeping, ending and dismissing answer as expected', (
    tester,
  ) async {
    Future<bool> answerBy(Future<void> Function() act) async {
      final answers = await ask(tester);
      await act();
      await tester.pumpAndSettle();
      return answers.single;
    }

    expect(
      await answerBy(
        () => tester.tap(find.byKey(const ValueKey('end_trip_keep'))),
      ),
      isFalse,
    );
    expect(
      await answerBy(
        () => tester.tap(find.byKey(const ValueKey('end_trip_confirm'))),
      ),
      isTrue,
    );
    expect(await answerBy(() => tester.tapAt(const Offset(5, 5))), isFalse);
  });

  testWidgets('a caller can explain why it asks', (tester) async {
    await ask(tester, message: LocServ.inst.t('trip_end_dialog_entrance_body'));

    expect(
      find.text(LocServ.inst.t('trip_end_dialog_entrance_body')),
      findsOneWidget,
    );
  });
}
