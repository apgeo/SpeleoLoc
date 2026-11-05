import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/general_data/cave_areas_page.dart';
import 'package:speleoloc/screens/general_data/surface_areas_page.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/widgets/product_tour.dart';

/// The add/edit dialogs of the area pages save once however often Save is
/// tapped, report a failed write instead of dying silently, and read their
/// text fields only while they are alive.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    initRootContainer(container);
    await setAutoToursDisabled(true);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> open(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: page),
      ),
    );
    await settle(tester);
  }

  Future<void> openAddDialog(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.add));
    await settle(tester);
  }

  /// The Save button of the open dialog (the labels are the i18n keys while
  /// no language is loaded).
  Finder save() => find.widgetWithText(TextButton, 'save');

  testWidgets('surface area: a double tap on Save stores one area', (
    tester,
  ) async {
    await open(tester, const SurfaceAreasPage());
    await openAddDialog(tester);

    await tester.enterText(find.byType(TextField).first, 'Invented plateau');
    final onPressed = tester.widget<TextButton>(save()).onPressed!;
    onPressed();
    onPressed();
    await settle(tester);

    final stored = await tester.runAsync(
      () => container.read(caveRepositoryProvider).getSurfaceAreas(),
    );
    expect(stored!.map((a) => a.title), ['Invented plateau']);
    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Invented plateau'), findsOneWidget);
  });

  testWidgets('surface area: a refused title keeps the dialog open', (
    tester,
  ) async {
    await tester.runAsync(
      () => container
          .read(caveRepositoryProvider)
          .addSurfaceArea(title: 'Invented plateau'),
    );
    await open(tester, const SurfaceAreasPage());
    await openAddDialog(tester);

    await tester.enterText(find.byType(TextField).first, 'Invented plateau');
    await tester.tap(save());
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsOneWidget);
    // Save is available again for another try.
    expect(tester.widget<TextButton>(save()).onPressed, isNotNull);
  });

  testWidgets('surface area: the fields survive closing the dialog', (
    tester,
  ) async {
    await open(tester, const SurfaceAreasPage());
    await openAddDialog(tester);
    await tester.enterText(find.byType(TextField).first, 'Invented plateau');

    await tester.tap(find.widgetWithText(TextButton, 'cancel'));
    // Pump through the exit transition, where a controller disposed too
    // early is read once more.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('cave area: a double tap on Save stores one area', (
    tester,
  ) async {
    final cave = await tester.runAsync(
      () => container.read(caveRepositoryProvider).addCave('Invented cave'),
    );
    await open(tester, CaveAreasPage(caveUuid: cave!));
    await openAddDialog(tester);

    await tester.enterText(find.byType(TextField).first, 'Invented gallery');
    final onPressed = tester.widget<TextButton>(save()).onPressed!;
    onPressed();
    onPressed();
    await settle(tester);

    final stored = await tester.runAsync(
      () => container.read(caveRepositoryProvider).getCaveAreas(cave),
    );
    expect(stored!.map((a) => a.title), ['Invented gallery']);
    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('cave area: a refused title keeps the dialog open', (
    tester,
  ) async {
    final cave = await tester.runAsync(
      () => container.read(caveRepositoryProvider).addCave('Invented cave'),
    );
    await tester.runAsync(
      () => container
          .read(caveRepositoryProvider)
          .addCaveArea(cave!, 'Invented gallery'),
    );
    await open(tester, CaveAreasPage(caveUuid: cave!));
    await openAddDialog(tester);

    await tester.enterText(find.byType(TextField).first, 'Invented gallery');
    await tester.tap(save());
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.widget<TextButton>(save()).onPressed, isNotNull);
  });
}
