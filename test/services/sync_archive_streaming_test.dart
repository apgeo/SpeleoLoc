import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
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
import 'package:speleoloc/utils/file_digest.dart';

/// A sync archive carries the photos and videos attached on every device,
/// so neither writing nor reading one may hold a file, or the archive, in
/// memory; and the format stays the one older app versions read and wrote.
/// Every file and row here is invented.
void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('speleoloc_sync_stream_');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<_Device> device(String name) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger logger;
    final currentUser = CurrentUserService(
      db,
      UserRepository(db, () => logger),
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    logger = ChangeLogger(db, currentUser);
    final docs = await Directory(
      p.join(root.path, name, 'docs'),
    ).create(recursive: true);
    addTearDown(db.close);
    return _Device(
      db,
      CaveRepository(db, currentUser, logger),
      SyncArchiveService(db, logger, assetsBaseDirResolver: () async => docs),
      docs,
    );
  }

  Future<void> attach(_Device d, String relPath, int size) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await d.db
        .into(d.db.documentationFiles)
        .insert(
          DocumentationFilesCompanion.insert(
            uuid: Uuid.v7(),
            title: p.basename(relPath),
            fileName: relPath,
            fileSize: size,
            fileType: p.extension(relPath).substring(1),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<File> docFile(_Device d, String relPath, List<int> bytes) async {
    final f = File(p.join(d.docs.path, relPath));
    await f.parent.create(recursive: true);
    return f.writeAsBytes(bytes);
  }

  final note = utf8.encode('invented cave note ' * 200);

  test('a video larger than the memory it may use goes through export and '
      'import byte for byte', () async {
    final a = await device('a');
    final b = await device('b');
    await a.caves.addCave('Invented Cave');
    await docFile(a, 'documentation_files/note.txt', note);
    await attach(a, 'documentation_files/note.txt', note.length);
    // Sparse, so creating it costs neither memory nor disk.
    const videoSize = 256 << 20;
    final video = File(p.join(a.docs.path, 'documentation_files', 'v.mp4'));
    video.openSync(mode: FileMode.write)
      ..setPositionSync(videoSize - 1)
      ..writeByteSync(0x42)
      ..closeSync();
    await attach(a, 'documentation_files/v.mp4', videoSize);
    final videoDigest = await FileDigest.of(video.path);

    // Growth is measured from the resident size at the start, not from the
    // peak: a peak left high by earlier work would hide any growth that
    // stays below it, and the check would pass whatever the code held.
    var rssBefore = ProcessInfo.currentRss;
    final zip = await a.sync.exportToZip(root.path, filenameHint: 'a.zip');
    expect(ProcessInfo.maxRss - rssBefore, lessThan(videoSize ~/ 2));

    rssBefore = ProcessInfo.currentRss;
    final report = await b.sync.importFromZip(zip.path);
    expect(ProcessInfo.maxRss - rssBefore, lessThan(videoSize ~/ 2));

    expect(report.warnings, isEmpty);
    expect(report.filesCopied, 2);
    expect(
      (await b.caves.getCaves()).map((c) => c.title),
      contains('Invented Cave'),
    );
    expect(
      await File(
        p.join(b.docs.path, 'documentation_files', 'note.txt'),
      ).readAsBytes(),
      note,
    );
    final copied = await FileDigest.of(
      p.join(b.docs.path, 'documentation_files', 'v.mp4'),
    );
    expect(copied.size, videoSize);
    expect(copied.sha256Hex, videoDigest.sha256Hex);
  });

  test('an archive keeps its entries and manifest, and reads with the '
      'in-memory decoder older app versions use', () async {
    final a = await device('a');
    await a.caves.addCave('Invented Cave');
    await docFile(a, 'documentation_files/note.txt', note);
    await attach(a, 'documentation_files/note.txt', note.length);
    // Named by a row but not on disk: neither bundled nor counted.
    await attach(a, 'documentation_files/gone.jpg', 1);

    final zip = await a.sync.exportToZip(root.path, filenameHint: 'a.zip');

    final decoded = ZipDecoder().decodeBuffer(
      InputStream(await zip.readAsBytes()),
      verify: true,
    );
    final names = decoded.files.map((f) => f.name).toList();
    expect(names.last, 'manifest.json');
    expect(names, contains('tables/caves.jsonl'));
    expect(names, contains('change_log.jsonl'));
    expect(names, contains('change_log_field.jsonl'));
    expect(names.where((n) => n.startsWith('assets/')), [
      'assets/documentation_files/note.txt',
    ]);
    expect(
      decoded.findFile('assets/documentation_files/note.txt')!.content,
      note,
    );
    final manifest =
        jsonDecode(
              utf8.decode(
                decoded.findFile('manifest.json')!.content as List<int>,
              ),
            )
            as Map<String, dynamic>;
    expect(manifest['format'], 'speleo_loc_sync');
    expect(manifest['format_version'], kSyncArchiveVersion);
    expect(manifest['schema_version'], 34);
    expect(manifest['asset_count'], 1);
    expect(
      utf8.decode(decoded.findFile('tables/caves.jsonl')!.content as List<int>),
      contains('Invented Cave'),
    );
  });

  test('an archive an older app version wrote whole in memory still imports, '
      'files included', () async {
    final a = await device('a');
    final b = await device('b');
    await a.caves.addCave('Invented Cave');
    final scan = Uint8List.fromList(
      List<int>.generate(3 << 20, (i) => (i * 131 + (i >> 9)) & 0xff),
    );
    await docFile(a, 'documentation_files/note.txt', note);
    await attach(a, 'documentation_files/note.txt', note.length);
    await docFile(a, 'documentation_files/scan.png', scan);
    await attach(a, 'documentation_files/scan.png', scan.length);
    final exported = await a.sync.exportToZip(root.path, filenameHint: 'a.zip');
    final old = await _asOlderAppsWroteIt(exported.path, root.path);

    final report = await b.sync.importFromZip(old);

    expect(report.warnings, isEmpty);
    expect(report.filesCopied, 2);
    expect(
      (await b.caves.getCaves()).map((c) => c.title),
      contains('Invented Cave'),
    );
    expect(
      await File(
        p.join(b.docs.path, 'documentation_files', 'note.txt'),
      ).readAsBytes(),
      note,
    );
    expect(
      await File(
        p.join(b.docs.path, 'documentation_files', 'scan.png'),
      ).readAsBytes(),
      scan,
    );
  });

  test('a file already on the device is kept, and one that cannot be '
      'written is counted as failed while the rest arrive', () async {
    final a = await device('a');
    final b = await device('b');
    for (final name in ['kept.txt', 'blocked.txt', 'new.txt']) {
      await docFile(a, 'documentation_files/$name', note);
      await attach(a, 'documentation_files/$name', note.length);
    }
    final zip = await a.sync.exportToZip(root.path, filenameHint: 'a.zip');
    await docFile(b, 'documentation_files/kept.txt', utf8.encode('mine'));
    // A folder where the file should go: writing it fails on B.
    await Directory(
      p.join(b.docs.path, 'documentation_files', 'blocked.txt'),
    ).create(recursive: true);

    final report = await b.sync.importFromZip(zip.path);

    expect(report.filesSkipped, 1);
    expect(report.filesFailed, 1);
    expect(report.filesCopied, 1);
    expect(
      report.warnings.where((w) => w.contains('blocked.txt')),
      hasLength(1),
    );
    expect(
      await File(
        p.join(b.docs.path, 'documentation_files', 'kept.txt'),
      ).readAsString(),
      'mine',
    );
    expect(
      await File(
        p.join(b.docs.path, 'documentation_files', 'new.txt'),
      ).readAsBytes(),
      note,
    );
  });
}

class _Device {
  _Device(this.db, this.caves, this.sync, this.docs);

  final AppDatabase db;
  final CaveRepository caves;
  final SyncArchiveService sync;
  final Directory docs;
}

/// Re-encodes the archive at [zipPath] the way earlier app versions wrote
/// sync archives: every entry deflated whole in memory by the package
/// encoder, the manifest last. Returns the new zip's path.
Future<String> _asOlderAppsWroteIt(String zipPath, String destDir) async {
  final src = ZipDecoder().decodeBytes(await File(zipPath).readAsBytes());
  final out = Archive();
  for (final f in src.files) {
    if (!f.isFile) continue;
    final content = f.content as List<int>;
    if (f.name == 'manifest.json') {
      out.addFile(ArchiveFile.string(f.name, utf8.decode(content)));
    } else {
      out.addFile(ArchiveFile(f.name, content.length, content));
    }
  }
  final path = p.join(destDir, 'older_app.zip');
  await File(path).writeAsBytes(ZipEncoder().encode(out)!);
  return path;
}
