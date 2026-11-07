import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/documentation_byte_edit_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';

import '../support/sync_device.dart';

/// A document edited on one phone reaches another phone that already holds
/// the earlier version: the row update and the new content both arrive, so
/// the second phone never shows old bytes under the new hash.
void main() {
  late SyncTestDevice a;
  late SyncTestDevice b;
  late Directory exchange;

  setUp(() async {
    a = await SyncTestDevice.create();
    b = await SyncTestDevice.create();
    exchange = await Directory.systemTemp.createTemp('speleoloc_doc_edit_');
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
    await exchange.delete(recursive: true);
    await a.assetsDir.delete(recursive: true);
    await b.assetsDir.delete(recursive: true);
  });

  DocumentationByteEditService editorOn(SyncTestDevice device) =>
      DocumentationByteEditService(
        db: device.db,
        logger: device.logger,
        currentUser: device.currentUser,
        copies: SilexgisFileCopyRepository(device.db),
        baseDir: () async => device.assetsDir,
      );

  Future<void> send(SyncTestDevice from, SyncTestDevice to, String name) async {
    final zip = await from.sync.exportToZip(
      exchange.path,
      filenameHint: name,
      includeDocumentationFiles: true,
      includeRasterMaps: false,
    );
    await to.sync.importFromZip(zip.path);
  }

  Future<DocumentationFile> row(SyncTestDevice device, Uuid id) =>
      (device.db.select(
        device.db.documentationFiles,
      )..where((t) => t.uuid.equalsValue(id))).getSingle();

  Future<Uuid> seed(String relPath, List<int> bytes, String fileType) async {
    final id = Uuid.v7();
    final file = File('${a.assetsDir.path}/$relPath');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    await a.db
        .into(a.db.documentationFiles)
        .insert(
          DocumentationFilesCompanion.insert(
            uuid: id,
            title: 'Invented $fileType',
            fileName: relPath,
            fileSize: bytes.length,
            fileType: fileType,
          ).copyWith(
            fileHash: Value(sha256.convert(bytes).toString()),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
    await a.logger.logInsert('documentation_files', id);
    return id;
  }

  // The editors of every kind save through the same service; what differs
  // is the bytes, text or not.
  for (final (kind, fileType, ext, first, second) in [
    (
      'note',
      'text_document',
      'txt',
      utf8.encode('invented first draft'),
      utf8.encode('invented second draft'),
    ),
    (
      'recording',
      'audio',
      'wav',
      List<int>.generate(512, (i) => i * 7 % 256),
      List<int>.generate(640, (i) => i * 13 % 256),
    ),
    (
      'picture',
      'image',
      'png',
      [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2, 3],
      [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 4, 5, 6, 7],
    ),
  ]) {
    test('an edited $kind reaches a phone that has the old version', () async {
      final relPath = 'documentation_files/doc_1_invented_$kind.$ext';
      final id = await seed(relPath, first, fileType);

      await send(a, b, 'first');
      expect(
        await File('${b.assetsDir.path}/$relPath').readAsBytes(),
        first,
        reason: 'the peer starts with the first version',
      );

      await tick();
      await editorOn(
        a,
      ).save(await row(a, id), Uint8List.fromList(second), title: 'Edited');
      await send(a, b, 'second');

      final onA = await row(a, id);
      final onB = await row(b, id);
      expect(onB.title, 'Edited');
      expect(onB.fileName, onA.fileName);
      expect(onB.fileHash, sha256.convert(second).toString());
      final bytesOnB = await File(
        '${b.assetsDir.path}/${onB.fileName}',
      ).readAsBytes();
      expect(bytesOnB, second);
      expect(sha256.convert(bytesOnB).toString(), onB.fileHash);
    });
  }

  test('a document left unchanged is not copied again', () async {
    final kept = await seed(
      'documentation_files/doc_1_invented_kept.txt',
      utf8.encode('invented, never edited'),
      'text_document',
    );
    final edited = await seed(
      'documentation_files/doc_2_invented_edited.txt',
      utf8.encode('invented first draft'),
      'text_document',
    );
    await send(a, b, 'first');
    await tick();
    await editorOn(a).save(
      await row(a, edited),
      Uint8List.fromList(utf8.encode('invented second draft')),
    );

    final zip = await a.sync.exportToZip(
      exchange.path,
      filenameHint: 'second',
      includeDocumentationFiles: true,
      includeRasterMaps: false,
    );
    final report = await b.sync.importFromZip(zip.path);

    expect(report.filesCopied, 1);
    expect(report.filesSkipped, greaterThanOrEqualTo(1));
    expect((await row(b, kept)).fileHash, (await row(a, kept)).fileHash);
  });
}
