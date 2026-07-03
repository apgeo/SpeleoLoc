import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/data_export_import_repository.dart';

/// Guards finding 3.8: the imported-database path is bound as a parameter, so
/// a path containing a single quote can't break (or inject into) the ATTACH.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('attach_test_');
  });
  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('attachImportedDb binds the path and handles a single quote', () async {
    // A filename with a single quote would break an interpolated ATTACH.
    final importedPath = p.join(tempDir.path, "imp'ort.sqlite");
    final src = AppDatabase.forTesting(NativeDatabase(File(importedPath)));
    await src
        .into(src.caves)
        .insert(CavesCompanion.insert(uuid: Uuid.v7(), title: 'Imported Cave'));
    await src.close();

    final main = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(main.close);
    final repo = DataExportImportRepository(main);

    await repo.attachImportedDb(importedPath);
    final rows = await main
        .customSelect('SELECT title FROM imported.caves')
        .get();
    expect(rows.map((r) => r.read<String>('title')), contains('Imported Cave'));
    await repo.detachImportedDb();
  });
}
