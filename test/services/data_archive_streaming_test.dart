import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/data_archive_service.dart';
import 'package:speleoloc/services/data_export_import_repository.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/utils/file_digest.dart';

/// A data export carries every attached file, videos included, so neither
/// writing nor reading one may hold a file, or the archive, in memory.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory docs;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('speleoloc_streaming_');
    docs = await Directory(p.join(tempDir.path, 'docs')).create();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => docs.path,
        );
    appDatabase = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await appDatabase.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<File> docFile(String rel, List<int> bytes) async {
    final f = File(p.join(docs.path, rel));
    await f.parent.create(recursive: true);
    return f.writeAsBytes(bytes);
  }

  test('exports and merge-imports a video larger than the memory it may use, '
      'byte for byte', () async {
    final dbFile = File(p.join(docs.path, 'speleo_loc.sqlite'));
    final onDisk = AppDatabase.file(dbFile);
    await onDisk.customSelect('SELECT 1').get();
    await onDisk.close();

    final note = Uint8List.fromList('invented note'.codeUnits);
    final scan = Uint8List.fromList(List<int>.generate(4096, (i) => i & 0xff));
    await docFile('documentation_files/note.txt', note);
    await docFile('cave_1/raster_1.png', scan);
    // Sparse, so creating it costs neither memory nor disk.
    const videoSize = 256 << 20;
    final video = File(p.join(docs.path, 'documentation_files', 'video.mp4'));
    video.openSync(mode: FileMode.write)
      ..setPositionSync(videoSize - 1)
      ..writeByteSync(0x42)
      ..closeSync();
    final videoDigest = await FileDigest.of(video.path);

    final service = DataArchiveService(_FixedPaths(appDatabase));
    final outDir = await Directory(p.join(tempDir.path, 'out')).create();

    var peakBefore = ProcessInfo.maxRss;
    final zipPath = await service.exportArchive(
      settings: const ExportSettings(),
      outputDir: outDir.path,
    );
    expect(ProcessInfo.maxRss - peakBefore, lessThan(videoSize ~/ 2));

    final input = InputFileStream(zipPath);
    try {
      expect(ZipDecoder().decodeBuffer(input).files.map((f) => f.name), {
        'speleo_loc.sqlite',
        'documentation_files/note.txt',
        'documentation_files/video.mp4',
        'cave_1/raster_1.png',
        'manifest.json',
      });
    } finally {
      await input.close();
    }

    await Directory(
      p.join(docs.path, 'documentation_files'),
    ).delete(recursive: true);
    await Directory(p.join(docs.path, 'cave_1')).delete(recursive: true);

    late ChangeLogger logger;
    final configs = ConfigurationRepository(appDatabase);
    final currentUser = CurrentUserService(
      appDatabase,
      UserRepository(appDatabase, () => logger),
      configs,
    );
    await currentUser.initialize();
    logger = ChangeLogger(appDatabase, currentUser);

    peakBefore = ProcessInfo.maxRss;
    final report = await service.importArchiveMerge(
      zipPath: zipPath,
      merger: SyncArchiveService(appDatabase, logger),
    );
    expect(ProcessInfo.maxRss - peakBefore, lessThan(videoSize ~/ 2));

    expect(report.filesCopied, 3);
    expect(
      await File(
        p.join(docs.path, 'documentation_files', 'note.txt'),
      ).readAsBytes(),
      note,
    );
    expect(
      await File(p.join(docs.path, 'cave_1', 'raster_1.png')).readAsBytes(),
      scan,
    );
    final restored = await FileDigest.of(video.path);
    expect(restored.size, videoSize);
    expect(restored.sha256Hex, videoDigest.sha256Hex);
  });
}

class _FixedPaths extends DataExportImportRepository {
  _FixedPaths(super._db);

  @override
  Future<List<String>> getDocumentationFilePaths({
    List<int>? caveIds,
    int? afterTimestamp,
  }) async => ['documentation_files/note.txt', 'documentation_files/video.mp4'];

  @override
  Future<List<String>> getRasterMapFilePaths({
    List<int>? caveIds,
    int? afterTimestamp,
  }) async => ['cave_1/raster_1.png'];
}
