import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/data_export_import_repository.dart';

/// A diff export carries the documentation files that changed since the last
/// full export: added ones, and ones whose content was edited afterwards,
/// which an edit stores under a new name.
void main() {
  late AppDatabase db;
  late DataExportImportRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DataExportImportRepository(db);
  });
  tearDown(() => db.close());

  Future<void> document(String name, {required int created, int? updated}) => db
      .into(db.documentationFiles)
      .insert(
        DocumentationFilesCompanion.insert(
          uuid: Uuid.v7(),
          title: name,
          fileName: 'documentation_files/$name',
          fileSize: 1,
          fileType: 'text_document',
        ).copyWith(createdAt: Value(created), updatedAt: Value(updated)),
      );

  test('files added or edited after the baseline are in the diff', () async {
    await document('old.txt', created: 100);
    await document('added.txt', created: 300);
    await document('edited.txt', created: 100, updated: 300);

    final paths = await repo.getDocumentationFilePaths(afterTimestamp: 200);

    expect(
      paths,
      unorderedEquals(<String>[
        'documentation_files/added.txt',
        'documentation_files/edited.txt',
      ]),
    );
  });
}
