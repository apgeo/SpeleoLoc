import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/utils/text_file_preview.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('text_preview_');
  });

  tearDown(() => dir.delete(recursive: true));

  Future<String> store(String name, List<int> bytes) async {
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  test('reads a small file whole', () async {
    final path = await store('a.txt', utf8.encode('Invented note ș ț'));
    final preview = await TextFilePreview.load(path, maxBytes: 1024);

    expect(preview.truncated, isFalse);
    expect(preview.totalBytes, preview.shownBytes);
    expect(preview.text, 'Invented note ș ț');
  });

  test('reads no more than the cap of a large file', () async {
    final path = await store('b.csv', List<int>.filled(10000, 0x41));
    final preview = await TextFilePreview.load(path, maxBytes: 4096);

    expect(preview.truncated, isTrue);
    expect(preview.shownBytes, 4096);
    expect(preview.totalBytes, 10000);
    expect(preview.text, 'A' * 4096);
  });

  test('a character split by the cap shows as a replacement', () async {
    // "ș" is two bytes in UTF-8; the cap falls between them.
    final path = await store('c.txt', [0x61, 0xC8, 0x99]);
    final preview = await TextFilePreview.load(path, maxBytes: 2);

    expect(preview.text, 'a�');
  });

  test('a missing file fails', () async {
    await expectLater(
      TextFilePreview.load('${dir.path}/gone.txt'),
      throwsA(isA<FileSystemException>()),
    );
  });
}
