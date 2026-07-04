import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/test_archive_import_service.dart';

void main() {
  test('fetchArchiveBytes reads an existing local file directly', () async {
    // Mirrors the "local archive" run workflow: test_archive_url points at a
    // real file on disk (absolute path). It must be read from the filesystem,
    // not looked up as a bundled asset.
    final tmp = File(
      '${Directory.systemTemp.path}/spl_archive_'
      '${DateTime.now().microsecondsSinceEpoch}.zip',
    );
    final bytes = Uint8List.fromList([0x50, 0x4b, 0x03, 0x04, 1, 2, 3]);
    await tmp.writeAsBytes(bytes, flush: true);
    addTearDown(() async {
      if (await tmp.exists()) await tmp.delete();
    });

    final out = await TestArchiveImportService.fetchArchiveBytes(tmp.path);
    expect(out, equals(bytes));
  });

  test('fetchArchiveBytes throws when the value is empty/blank', () async {
    await expectLater(
      TestArchiveImportService.fetchArchiveBytes('   '),
      throwsA(isA<Exception>()),
    );
  });

  test('isRemoteUrl distinguishes URLs from local paths', () {
    expect(
      TestArchiveImportService.isRemoteUrl('https://example.com/a.zip'),
      isTrue,
    );
    expect(
      TestArchiveImportService.isRemoteUrl('http://example.com/a.zip'),
      isTrue,
    );
    expect(
      TestArchiveImportService.isRemoteUrl(r'C:\temp\test_data\a.zip'),
      isFalse,
    );
    expect(
      TestArchiveImportService.isRemoteUrl('assets/test_archive/a.zip'),
      isFalse,
    );
  });
}
