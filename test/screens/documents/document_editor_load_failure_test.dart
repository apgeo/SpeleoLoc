import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/documents/editors/rich_text_editor_page.dart';
import 'package:speleoloc/screens/documents/editors/text_document_editor_page.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/documentation_file_helper.dart';
import 'package:speleoloc/utils/localization.dart';
import '../../support/pump_app.dart';

/// An editor whose document cannot be read says so and offers no Save: an
/// empty editor saved over the stored file would replace the real content.
void main() {
  late Directory docs;
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    docs = await Directory.systemTemp.createTemp('speleoloc_editor_load_');
    mockPathProvider(documents: docs);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    initRootContainer(container);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    await docs.delete(recursive: true);
  });

  DocumentationFile document(String name) => DocumentationFile(
    uuid: Uuid.v7(),
    title: 'Invented note',
    fileName: 'documentation_files/$name',
    fileSize: 1,
    fileType: 'text_document',
  );

  Future<void> store(WidgetTester tester, String name, String content) =>
      tester.runAsync(() async {
        final file = File('${docs.path}/documentation_files/$name');
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
      });

  Future<void> open(WidgetTester tester, Widget page) => pumpScreen(
    tester,
    container,
    page,
    delegates: const [
      FlutterQuillLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
  );

  final failed = LocServ.inst.t('document_load_failed_title');

  group('rich-text editor', () {
    testWidgets('a missing file shows the error and no Save', (tester) async {
      await open(
        tester,
        RichTextEditorPage(existingDoc: document('doc_1_gone.qldoc')),
      );

      expect(find.text(failed), findsOneWidget);
      expect(find.byIcon(Icons.save), findsNothing);
    });

    testWidgets('an unreadable file shows the error and no Save', (
      tester,
    ) async {
      await store(tester, 'doc_1_broken.qldoc', 'not a delta');
      await open(
        tester,
        RichTextEditorPage(existingDoc: document('doc_1_broken.qldoc')),
      );

      expect(find.text(failed), findsOneWidget);
      expect(find.byIcon(Icons.save), findsNothing);
    });

    testWidgets('a readable file opens for editing', (tester) async {
      await store(
        tester,
        'doc_1_ok.qldoc',
        jsonEncode([
          {'insert': 'Invented passage notes\n'},
        ]),
      );
      await open(
        tester,
        RichTextEditorPage(existingDoc: document('doc_1_ok.qldoc')),
      );

      expect(find.text(failed), findsNothing);
      expect(find.byIcon(Icons.save), findsOneWidget);
    });
  });

  group('plain-text editor', () {
    testWidgets('a missing file shows the error and no Save', (tester) async {
      await open(
        tester,
        TextDocumentEditorPage(existingDoc: document('doc_1_gone.txt')),
      );

      expect(find.text(failed), findsOneWidget);
      expect(find.byIcon(Icons.save), findsNothing);
    });

    testWidgets('a readable file opens for editing', (tester) async {
      await store(tester, 'doc_1_ok.txt', 'Invented passage notes');
      await open(
        tester,
        TextDocumentEditorPage(existingDoc: document('doc_1_ok.txt')),
      );

      expect(find.text(failed), findsNothing);
      expect(find.text('Invented passage notes'), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('a readable file saved after an edit stores the new text', (
      tester,
    ) async {
      await store(tester, 'doc_1_ok.txt', 'Invented passage notes');
      final stored = document('doc_1_ok.txt');
      await tester.runAsync(
        () => db.insertDocumentationFile(
          companion: DocumentationFilesCompanion.insert(
            uuid: stored.uuid,
            title: stored.title,
            fileName: stored.fileName,
            fileSize: stored.fileSize,
            fileType: stored.fileType,
          ),
        ),
      );
      await open(tester, TextDocumentEditorPage(existingDoc: stored));

      await tester.enterText(
        find.text('Invented passage notes'),
        'Invented passage notes, revised',
      );
      await tester.tap(find.byIcon(Icons.save));
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }

      final row = await tester.runAsync(
        () => (db.select(
          db.documentationFiles,
        )..where((d) => d.uuid.equalsValue(stored.uuid))).getSingle(),
      );
      final bytes = await tester.runAsync(
        () => File('${docs.path}/${row!.fileName}').readAsBytes(),
      );
      expect(utf8.decode(bytes!), 'Invented passage notes, revised');
      expect(row!.fileHash, DocumentationFileHelper.computeSha256(bytes));
    });
  });
}
