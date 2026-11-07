import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/user_repository.dart';

/// A document deleted here stops leaving the device: its file is not packed
/// into the next sync archive, though its row's deletion still travels.
void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('speleoloc_sync_deleted_');
  });
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('a soft-deleted document\'s file is not exported', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    late ChangeLogger logger;
    final users = UserRepository(db, () => logger);
    final currentUser = CurrentUserService(
      db,
      users,
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    logger = ChangeLogger(db, currentUser);
    final docs = Directory(p.join(root.path, 'app_flutter'));
    final sync = SyncArchiveService(
      db,
      logger,
      assetsBaseDirResolver: () async => docs,
    );

    for (final (name, deleted) in <(String, bool)>[
      ('kept.txt', false),
      ('deleted.txt', true),
    ]) {
      final file = File(p.join(docs.path, 'documentation_files', name));
      await file.parent.create(recursive: true);
      await file.writeAsString('invented $name');
      await db
          .into(db.documentationFiles)
          .insert(
            DocumentationFilesCompanion.insert(
              uuid: Uuid.v7(),
              title: name,
              fileName: 'documentation_files/$name',
              fileSize: 1,
              fileType: 'txt',
            ).copyWith(deletedAt: Value(deleted ? 1761000000000 : null)),
          );
    }

    final exported = await sync.exportToZip(root.path, filenameHint: 'a.zip');

    final archive = ZipDecoder().decodeBytes(
      await File(exported.path).readAsBytes(),
    );
    expect(
      <String>[
        for (final f in archive.files)
          if (f.name.startsWith('assets/')) f.name,
      ],
      <String>['assets/documentation_files/kept.txt'],
    );
  });
}
