import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/user_repository.dart';

/// A sync archive comes from a shared folder anyone holding the account can
/// write to, so its entry names must never place a file outside the
/// documents folder, whatever form the name takes.
void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('speleoloc_sync_slip_');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  // The documents folder sits two levels below [root], so a `../` or
  // `../../` entry would still land inside [root] where the test can see it.
  Future<_Device> device(String name) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger logger;
    final users = UserRepository(db, () => logger);
    final currentUser = CurrentUserService(
      db,
      users,
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    logger = ChangeLogger(db, currentUser);
    final docs = Directory(p.join(root.path, name, 'files', 'app_flutter'));
    await docs.create(recursive: true);
    return _Device(
      db,
      CaveRepository(db, currentUser, logger),
      SyncArchiveService(db, logger, assetsBaseDirResolver: () async => docs),
      docs,
    );
  }

  test('asset entries that name a place outside the documents folder are '
      'skipped with a warning while the rest of the archive imports', () async {
    final a = await device('a');
    final b = await device('b');
    await a.caves.addCave('Test Cave');
    final exported = await a.sync.exportToZip(root.path, filenameHint: 'a.zip');

    final hostile = <String>[
      'assets/../escape_1.txt',
      'assets/../../escape_2.txt',
      'assets/documentation_files/../../escape_3.txt',
      'assets/..\\escape_4.txt',
      'assets//${p.join(root.path, 'escape_5.txt')}',
      'assets/.',
      'assets/documentation_files/..',
    ];
    final crafted = await _withExtraEntries(exported.path, root.path, {
      'assets/documentation_files/hall.txt': 'a legitimate nested asset',
      for (final name in hostile) name: 'payload',
    });

    final report = await b.sync.importFromZip(crafted);

    expect(
      (await b.caves.getCaves()).map((c) => c.title),
      contains('Test Cave'),
    );
    expect(report.filesCopied, 1);
    expect(
      await File(
        p.join(b.docs.path, 'documentation_files', 'hall.txt'),
      ).readAsString(),
      'a legitimate nested asset',
    );
    expect(
      _filesOutside(root, [a.docs, b.docs], ignore: {crafted, exported.path}),
      isEmpty,
    );
    for (var i = 1; i <= 5; i++) {
      expect(_existsAnywhere(root, 'escape_$i.txt'), isFalse, reason: '$i');
    }
    expect(
      report.warnings.where((w) => w.contains('outside the documents folder')),
      hasLength(hostile.length),
    );

    await a.db.close();
    await b.db.close();
  });
}

class _Device {
  _Device(this.db, this.caves, this.sync, this.docs);
  final AppDatabase db;
  final CaveRepository caves;
  final SyncArchiveService sync;
  final Directory docs;
}

/// Copies the archive at [srcZipPath] and adds [extra] text entries, keeping
/// every existing entry, and returns the new path.
Future<String> _withExtraEntries(
  String srcZipPath,
  String destDir,
  Map<String, String> extra,
) async {
  final src = ZipDecoder().decodeBytes(await File(srcZipPath).readAsBytes());
  final out = Archive();
  for (final f in src.files) {
    if (!f.isFile) continue;
    final content = f.content as List<int>;
    out.addFile(ArchiveFile(f.name, content.length, content));
  }
  for (final MapEntry(:key, :value) in extra.entries) {
    final bytes = utf8.encode(value);
    out.addFile(ArchiveFile(key, bytes.length, bytes));
  }
  final destPath = p.join(destDir, 'crafted.zip');
  await File(destPath).writeAsBytes(ZipEncoder().encode(out)!);
  return destPath;
}

/// Every file under [root] that is in none of [docs] and not in [ignore].
List<String> _filesOutside(
  Directory root,
  List<Directory> docs, {
  Set<String> ignore = const {},
}) => [
  for (final e in root.listSync(recursive: true, followLinks: false))
    if (e is File &&
        !ignore.contains(e.path) &&
        !docs.any((d) => p.isWithin(d.path, e.path)))
      e.path,
];

bool _existsAnywhere(Directory root, String baseName) => root
    .listSync(recursive: true, followLinks: false)
    .any((e) => p.basename(e.path) == baseName);
