import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/services/trip_report_export_service.dart';

/// Report-template rows sync between devices, so the file name a row carries
/// must only ever reach a file inside the templates folder.
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
}
