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

  test('an edited note reaches a phone that has the old version', () async {
    final id = Uuid.v7();
    const relPath = 'documentation_files/doc_1_invented_note.txt';
    final first = utf8.encode('invented first draft');
    final file = File('${a.assetsDir.path}/$relPath');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(first);
    await a.db
        .into(a.db.documentationFiles)
        .insert(
          DocumentationFilesCompanion.insert(
            uuid: id,
            title: 'Invented note',
            fileName: relPath,
            fileSize: first.length,
            fileType: 'text_document',
          ).copyWith(
            fileHash: Value(sha256.convert(first).toString()),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
    await a.logger.logInsert('documentation_files', id);

    await send(a, b, 'first');
    expect(
      await File('${b.assetsDir.path}/$relPath').readAsBytes(),
      first,
      reason: 'the peer starts with the first version',
    );

    await tick();
    final second = Uint8List.fromList(utf8.encode('invented second draft'));
    await editorOn(a).save(await row(a, id), second, title: 'Invented note 2');
    await send(a, b, 'second');

    final onA = await row(a, id);
    final onB = await row(b, id);
    expect(onB.title, 'Invented note 2');
    expect(onB.fileName, onA.fileName);
    expect(onB.fileHash, sha256.convert(second).toString());
    expect(
      await File('${b.assetsDir.path}/${onB.fileName}').readAsBytes(),
      second,
    );
  });
}
