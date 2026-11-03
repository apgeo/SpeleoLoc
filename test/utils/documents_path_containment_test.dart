import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/utils/documentation_file_helper.dart';
import 'package:speleoloc/utils/file_utils.dart';

/// Documentation and raster-map rows sync between devices, so the file name
/// a row carries must only ever reach a file inside the documents folder.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory docs;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('speleoloc_docs_paths_');
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

  test('a nested name inside the documents folder resolves', () async {
    final file = File(p.join(docs.path, 'documentation_files', 'a.txt'));
    await file.create(recursive: true);

    expect(await getDocumentsFilePath('documentation_files/a.txt'), file.path);
    expect(
      (await getDocumentsFile('documentation_files/a.txt'))?.path,
      file.path,
    );
  });

  test('a name leaving the documents folder is never resolved', () async {
    final outside = File(p.join(root.path, 'outside.txt'));
    await outside.writeAsString('invented');

    expect(await getDocumentsFile('../outside.txt'), isNull);
    await expectLater(
      getDocumentsFilePath('../outside.txt'),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('an overwrite through a leaving name writes nothing', () async {
    await expectLater(
      DocumentationFileHelper.overwriteBytes(
        relativePath: '../outside.bin',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
      throwsA(isA<FileSystemException>()),
    );
    await expectLater(
      DocumentationFileHelper.overwriteText(
        relativePath: '../outside.txt',
        content: 'invented',
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(await File(p.join(root.path, 'outside.bin')).exists(), isFalse);
    expect(await File(p.join(root.path, 'outside.txt')).exists(), isFalse);
  });
}
