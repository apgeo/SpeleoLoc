import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/documents/viewers/documentation_file_viewer.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/utils/text_file_preview.dart';
import 'package:speleoloc/widgets/product_tour.dart';

/// A text or CSV document is read once, off the build, and only its
/// beginning when it is large; a file that is not UTF-8 or no longer exists
/// shows a message instead of the red error screen.
void main() {
  late Directory dir;
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('speleoloc_text_viewer_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    initRootContainer(container);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    await dir.delete(recursive: true);
  });

  DocumentationFile document(String name) => DocumentationFile(
    uuid: Uuid.v7(),
    title: 'Invented survey export',
    fileName: 'documentation_files/$name',
    fileSize: 1,
    fileType: 'text_document',
  );

  Future<File> store(WidgetTester tester, String name, List<int> bytes) async =>
      (await tester.runAsync(
        () => File('${dir.path}/$name').writeAsBytes(bytes),
      ))!;

  Future<void> open(WidgetTester tester, File file) async {
    await tester.runAsync(() => setAutoToursDisabled(true));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: DocumentationFileViewer(
            file: file,
            doc: document(file.uri.pathSegments.last),
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  String shown(WidgetTester tester) =>
      tester.widget<SelectableText>(find.byType(SelectableText)).data!;

  testWidgets('shows a small CSV whole', (tester) async {
    const csv = 'station,depth\nA1,-12\nA2,-14\n';
    await open(tester, await store(tester, 'small.csv', csv.codeUnits));

    expect(shown(tester), csv);
    expect(find.textContaining('KB'), findsNothing);
  });

  testWidgets('shows only the beginning of a large CSV, and says so', (
    tester,
  ) async {
    final line = 'A,${'9' * 60}\n'.codeUnits;
    final bytes = [
      for (var i = 0; i < TextFilePreview.defaultMaxBytes ~/ 8; i++) ...line,
    ];
    await open(tester, await store(tester, 'large.csv', bytes));

    expect(shown(tester).length, TextFilePreview.defaultMaxBytes);
    expect(
      find.text(
        LocServ.inst.t('text_file_preview_truncated', {
          'shown': '${TextFilePreview.defaultMaxBytes ~/ 1024}',
          'total': '${(bytes.length / 1024).ceil()}',
        }),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows a file in a legacy code page instead of failing', (
    tester,
  ) async {
    // "Peștera" with the s-comma written as a single Windows-1250 byte.
    final bytes = [...'Pe'.codeUnits, 0xBA, ...'tera,-30\n'.codeUnits];
    await open(tester, await store(tester, 'legacy.csv', bytes));

    expect(tester.takeException(), isNull);
    expect(shown(tester), 'Pe�tera,-30\n');
  });

  testWidgets('says so when the file is gone', (tester) async {
    await open(tester, File('${dir.path}/gone.txt'));

    expect(tester.takeException(), isNull);
    expect(find.text(LocServ.inst.t('text_file_preview_failed')), findsOne);
  });
}
