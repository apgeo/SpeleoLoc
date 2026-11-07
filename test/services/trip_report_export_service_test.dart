import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/services/trip_report_export_service.dart';
import 'package:xml/xml.dart';

/// Report-template rows sync between devices, so the file name a row carries
/// must only ever reach a file inside the templates folder; and the report
/// built from a template must be a document a word processor opens as it is.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory docs;
  final service = TripReportExportService.instance;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('speleoloc_templates_');
    docs = Directory(p.join(root.path, 'app_flutter'));
    await docs.create();
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return docs.path;
          }
          return null;
        });
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  /// A minimal ODT whose body takes appended paragraphs.
  List<int> odt() {
    final xml = utf8.encode('<office:text></office:text>');
    final archive = Archive()
      ..addFile(ArchiveFile('content.xml', xml.length, xml));
    return ZipEncoder().encode(archive)!;
  }

  test('deletes a template that sits in the templates folder', () async {
    final template = File(p.join(await service.getTemplatesDir(), 'a.odt'));
    await template.writeAsBytes(odt());

    await service.deleteTemplateFile('a.odt');

    expect(await template.exists(), isFalse);
  });

  test('never deletes a file a template name points outside the folder '
      'at', () async {
    final database = File(p.join(docs.path, 'speleo_loc.sqlite'));
    await database.writeAsString('database');
    final elsewhere = File(p.join(root.path, 'elsewhere.odt'));
    await elsewhere.writeAsString('other');

    for (final name in [
      '../speleo_loc.sqlite',
      r'..\speleo_loc.sqlite',
      elsewhere.path,
      '../../elsewhere.odt',
    ]) {
      await service.deleteTemplateFile(name);
    }

    expect(await database.exists(), isTrue);
    expect(await elsewhere.exists(), isTrue);
  });

  test('builds a report only from a template inside the folder', () async {
    await File(
      p.join(await service.getTemplatesDir(), 'a.odt'),
    ).writeAsBytes(odt());
    final outside = File(p.join(docs.path, 'outside.odt'));
    await outside.writeAsBytes(odt());

    expect(
      await service.buildReportBytes(templateFileName: 'a.odt', text: 'Hall'),
      isNotEmpty,
    );
    for (final name in ['../outside.odt', outside.path]) {
      await expectLater(
        service.buildReportBytes(templateFileName: name, text: 'Hall'),
        throwsStateError,
        reason: name,
      );
    }
  });

  group('saving at the path the save dialog returned', () {
    test('on a desktop an older report under the full name is replaced, '
        'also when the name was typed without its extension', () async {
      final stale = File(p.join(root.path, 'report.docx'));
      await stale.writeAsBytes([1, 1, 1]);

      final written = await service.savePickedReport(
        pickedPath: p.join(root.path, 'report'),
        format: 'docx',
        bytes: [2, 2],
        desktop: true,
      );

      expect(written, stale.path);
      expect(await stale.readAsBytes(), [2, 2]);
    });

    test('on a phone what the dialog already wrote is kept', () async {
      final saved = File(p.join(root.path, 'report.odt'));
      await saved.writeAsBytes([3]);

      final written = await service.savePickedReport(
        pickedPath: saved.path,
        format: 'odt',
        bytes: [4],
        desktop: false,
      );

      expect(written, saved.path);
      expect(await saved.readAsBytes(), [3]);
    });
  });

  group('a DOCX report', () {
    const w = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

    /// A DOCX whose body ends, as every Word-saved one does, with the
    /// section properties; its first paragraph closes a section of its own.
    List<int> docx({
      String tail =
          '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/>'
          '<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/>'
          '</w:sectPr>',
    }) {
      final xml = utf8.encode(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="$w"><w:body>'
        '<w:p><w:pPr><w:sectPr><w:pgSz w:w="11906" w:h="16838"/></w:sectPr>'
        '</w:pPr><w:r><w:t>Cover</w:t></w:r></w:p>'
        '<w:p><w:r><w:t>Template text</w:t></w:r></w:p>'
        '$tail</w:body></w:document>',
      );
      final archive = Archive()
        ..addFile(ArchiveFile('word/document.xml', xml.length, xml));
      return ZipEncoder().encode(archive)!;
    }

    Future<XmlElement> builtBody(String text, {String? tail}) async {
      await File(
        p.join(await service.getTemplatesDir(), 'a.docx'),
      ).writeAsBytes(tail == null ? docx() : docx(tail: tail));
      final bytes = await service.buildReportBytes(
        templateFileName: 'a.docx',
        text: text,
      );
      final document = ZipDecoder()
          .decodeBytes(bytes)
          .findFile('word/document.xml')!;
      return XmlDocument.parse(
        utf8.decode(document.content as List<int>),
      ).findAllElements('body', namespace: w).single;
    }

    test('keeps the section properties as the body\'s last child', () async {
      final body = await builtBody('Hall\nSump');

      final children = body.childElements.toList();
      expect(children.last.name.local, 'sectPr');
      final texts = [
        for (final para in children.where((e) => e.name.local == 'p'))
          para
              .findAllElements('t', namespace: w)
              .map((t) => t.innerText)
              .join(),
      ];
      expect(texts, ['Cover', 'Template text', 'Hall', 'Sump']);
    });

    test('an empty section properties element stays last', () async {
      final body = await builtBody('Hall', tail: '<w:sectPr/>');

      final children = body.childElements.toList();
      expect(children.last.name.local, 'sectPr');
      expect(children[children.length - 2].innerText, 'Hall');
    });

    test(
      'a template without section properties gets the lines at the end',
      () async {
        final body = await builtBody('Hall\nSump', tail: '');

        final texts = [
          for (final para in body.childElements)
            para
                .findAllElements('t', namespace: w)
                .map((t) => t.innerText)
                .join(),
        ];
        expect(texts, ['Cover', 'Template text', 'Hall', 'Sump']);
      },
    );

    test('keeps the spaces a log line starts with', () async {
      final body = await builtBody('  indented line');

      final appended = body
          .findAllElements('t', namespace: w)
          .singleWhere((t) => t.innerText.contains('indented'));
      expect(appended.innerText, '  indented line');
      expect(appended.getAttribute('xml:space'), 'preserve');
    });
  });
}
