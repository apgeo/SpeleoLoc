import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_place/cave_place_area_row.dart';
import 'package:speleoloc/screens/cave_place/cave_place_form_controller.dart';

/// The area dropdown shows what the form holds: cancelling the confirmation
/// of "clear area" must not leave "none" on screen while the stored area
/// would still be saved.
void main() {
  final caveUuid = Uuid.v7();
  final hall = CaveArea(
    uuid: Uuid.v7(),
    title: 'Invented hall',
    caveUuid: caveUuid,
  );
  final gallery = CaveArea(
    uuid: Uuid.v7(),
    title: 'Invented gallery',
    caveUuid: caveUuid,
  );

  late CavePlaceFormController form;
  late List<Uuid?> changes;

  setUp(() {
    form = CavePlaceFormController()..selectedCaveAreaId = hall.uuid;
    changes = [];
  });

  tearDown(() => form.dispose());

  Future<void> pumpRow(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => CavePlaceAreaRow(
            form: form,
            caveAreas: [hall, gallery],
            depthFieldKey: const ValueKey('depth'),
            pciRowHidden: false,
            onAreaChanged: (v) => setState(() {
              form.selectedCaveAreaId = v;
              changes.add(v);
            }),
            onManageAreas: () async {},
            onShowPciRow: () {},
          ),
        ),
      ),
    ),
  );

  Future<void> choose(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButtonFormField<Uuid?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('cancelling the clear keeps the chosen area on screen', (
    tester,
  ) async {
    await pumpRow(tester);
    expect(find.text('Invented hall'), findsOneWidget);

    await choose(tester, 'none');
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('cancel'));
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
    expect(form.selectedCaveAreaId, hall.uuid);
    expect(find.text('Invented hall'), findsOneWidget);
    expect(find.text('none'), findsNothing);
  });

  testWidgets('confirming the clear shows none', (tester) async {
    await pumpRow(tester);

    await choose(tester, 'none');
    await tester.tap(find.text('yes'));
    await tester.pumpAndSettle();

    expect(changes, [null]);
    expect(find.text('Invented hall'), findsNothing);
    expect(find.text('none'), findsOneWidget);
  });

  testWidgets('choosing another area needs no confirmation', (tester) async {
    await pumpRow(tester);

    await choose(tester, 'Invented gallery');

    expect(find.byType(AlertDialog), findsNothing);
    expect(changes, [gallery.uuid]);
    expect(find.text('Invented gallery'), findsOneWidget);
  });
}
