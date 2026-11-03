import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/services/storage/document_import_source.dart';
import 'package:speleoloc/services/storage/saf_storage_service.dart';

/// The names a document provider reports are chosen by whichever app backs
/// the picked folder, so one must never decide where an imported file is
/// written.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('speleoloc_saf_import_');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('lists only children whose name is one plain file name', () async {
    final saf = _FakeSaf([
      'Hall.jpg',
      '/../../../shared_prefs/FlutterSecureStorage.xml',
      '/../../../app_flutter/speleo_loc.sqlite',
      'sub/../../escape.jpg',
      r'..\escape.jpg',
      '..',
      '',
      '.hidden.jpg',
      'Entrance.jpg',
    ]);
    final dir = SafImportDirectory(
      saf,
      'content://tree',
      const SafEntry(
        documentId: 'cave',
        name: 'Test Cave',
        isDirectory: true,
        size: 0,
      ),
    );

    final files = await dir.listFiles();

    expect(files.map((f) => f.name), ['Entrance.jpg', 'Hall.jpg']);
    for (final file in files) {
      await file.materialize(tempDir);
    }
    expect(saf.copiedTo, hasLength(2));
    for (final dest in saf.copiedTo) {
      expect(p.isWithin(tempDir.path, dest), isTrue, reason: dest);
    }
  });
}

class _FakeSaf implements SafStorageService {
  _FakeSaf(this.names);

  final List<String> names;
  final List<String> copiedTo = [];

  @override
  Future<List<SafEntry>> listChildren(
    String treeUri, {
    String? documentId,
  }) async => [
    for (final (i, name) in names.indexed)
      SafEntry(documentId: 'doc-$i', name: name, isDirectory: false, size: 1),
  ];

  @override
  Future<void> copyToFile({
    required String treeUri,
    required String documentId,
    required String destPath,
  }) async => copiedTo.add(destPath);

  @override
  Future<SafPickedDirectory?> pickDirectory() => throw UnimplementedError();

  @override
  Future<String?> saveDocument({
    required String fileName,
    required String mimeType,
    required String sourcePath,
  }) => throw UnimplementedError();
}
