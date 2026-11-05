import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/services/database_swap/live_database_swap.dart';
import 'package:speleoloc/services/startup/startup_recovery.dart';
import 'package:speleoloc/services/storage/database_file_export_service.dart';

/// The way out of a failed start keeps the caver's data. Every file here is
/// invented; nothing opens them.
void main() {
  late Directory docs;
  late File liveFile;
  late _RecordingExporter exporter;
  late DatabaseStartupRecovery recovery;

  setUp(() async {
    docs = await Directory.systemTemp.createTemp('startup_recovery_');
    liveFile = File(p.join(docs.path, 'speleo_loc.sqlite'))
      ..writeAsStringSync('invented half-installed database');
    exporter = _RecordingExporter();
    recovery = DatabaseStartupRecovery(
      LiveDatabaseSwap(
        documentsDirectory: () async => docs,
        openLiveDatabase: () => throw UnimplementedError(),
        currentDatabase: () => throw UnimplementedError(),
        install: (_) => throw UnimplementedError(),
      ),
      exporter: exporter,
    );
  });

  tearDown(() async {
    if (await docs.exists()) await docs.delete(recursive: true);
  });

  test('Export saves the live file when no swap was cut short', () async {
    await recovery.exportDatabase();

    expect(exporter.sources.single.path, liveFile.path);
  });

  test('Export saves the backup a cut-short swap left, not the half-installed '
      'live file', () async {
    final backup = File('${liveFile.path}${LiveDatabaseSwap.backupSuffix}')
      ..writeAsStringSync('invented previous database');

    await recovery.exportDatabase();

    expect(exporter.sources.single.path, backup.path);
  });
}

class _RecordingExporter implements DatabaseFileExportService {
  final sources = <File>[];

  @override
  Future<String?> export(
    File source, {
    required String folderDialogTitle,
    required String saveDialogTitle,
  }) async {
    sources.add(source);
    return '/invented/export.sqlite';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
