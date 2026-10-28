import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/screens/settings/silexgis_mobile_data_dialog.dart';
import 'package:speleoloc/services/silexgis/silexgis_files_network_gate.dart';

/// The question about mobile data comes from the screen that started the run,
/// and hands back the caver's answer with whether to keep it.
void main() {
  Future<SilexgisMobileDataAnswer?> ask(
    WidgetTester tester,
    Future<void> Function() choose,
  ) async {
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
    final answer = SilexgisMobileDataDialogDecider(
      () => context,
    ).askToSendOverMobileData(files: 3, bytes: 5 * 1024 * 1024);
    await tester.pumpAndSettle();
    expect(find.byType(SilexgisMobileDataDialog), findsOneWidget);
    await choose();
    await tester.pumpAndSettle();
    return answer;
  }

  testWidgets('"send now" sends, and is not kept unless asked', (tester) async {
    final answer = await ask(
      tester,
      () => tester.tap(find.byType(FilledButton)),
    );
    expect(answer!.send, isTrue);
    expect(answer.remember, isFalse);
  });

  testWidgets('"wait", remembered, is kept', (tester) async {
    final answer = await ask(tester, () async {
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.byType(TextButton));
    });
    expect(answer!.send, isFalse);
    expect(answer.remember, isTrue);
  });

  test('with the screen gone, nobody is asked', () async {
    expect(
      await SilexgisMobileDataDialogDecider(
        () => null,
      ).askToSendOverMobileData(files: 1, bytes: 1),
      isNull,
    );
  });
}
