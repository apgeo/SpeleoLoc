import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/storage/database_file_export_service.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;

import '../../support/database_file_fixtures.dart';

/// The database export is a consistent copy taken through the open
/// connection, not a copy of a file that may be mid-write. Every database
/// here is invented.
void main() {
  late Directory tmp;
  late AppDatabase live;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('database_export_');
    final liveFile = await appDatabaseFile(
      p.join(tmp.path, 'speleo_loc.sqlite'),
      marker: 'live',
    );
    live = AppDatabase.file(liveFile);
  });

  tearDown(() async {
    await live.close();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('the bundled SQLite can write a snapshot', () {
    // VACUUM INTO arrived in SQLite 3.27.
    final version = sqlite3.version.libVersion.split('.').map(int.parse);
    expect(
      version.first > 3 || (version.first == 3 && version.elementAt(1) >= 27),
      isTrue,
    );
  });

  Future<String?> readMarker(File file, String key) async {
    final copy = AppDatabase.file(file);
    try {
      return await ConfigurationRepository(copy).readString(key);
    } finally {
      await copy.close();
    }
  }

  test('the snapshot opens, is intact and holds the data, including what '
      'was written just before', () async {
    await ConfigurationRepository(live).writeString('invented_late', 'yes');
    final target = File(p.join(tmp.path, 'out', 'export.sqlite'));

    await const DatabaseFileExportService().writeSnapshot(live, target);

    final raw = sqlite3.open(target.path);
    try {
      expect(raw.select('PRAGMA integrity_check').single.values.single, 'ok');
      expect(raw.userVersion, live.schemaVersion);
    } finally {
      raw.close();
    }
    expect(await readMarker(target, 'invented_key'), 'live');
    expect(await readMarker(target, 'invented_late'), 'yes');
  });

  test('a snapshot asked for in the middle of a large transaction holds all '
      'of it, never part', () async {
    // Large enough that SQLite writes uncommitted pages into the database
    // file before the commit, which a plain file copy would pick up.
    const rows = 12000;
    final configs = ConfigurationRepository(live);
    await live.transaction(() async {
      for (var i = 0; i < rows; i++) {
        await configs.writeString('invented_row_$i', 'old ${'x' * 500}');
      }
    });
    final halfway = Completer<void>();
    final finish = Completer<void>();
    final transaction = live.transaction(() async {
      for (var i = 0; i < rows; i++) {
        await configs.writeString('invented_row_$i', 'new ${'y' * 500}');
      }
      halfway.complete();
      await finish.future;
    });
    await halfway.future;
    final target = File(p.join(tmp.path, 'export.sqlite'));

    final snapshot = const DatabaseFileExportService().writeSnapshot(
      live,
      target,
    );
    // Time enough for a copy that does not wait for the transaction.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    finish.complete();
    await transaction;
    await snapshot;

    final raw = sqlite3.open(target.path);
    try {
      expect(raw.select('PRAGMA integrity_check').single.values.single, 'ok');
      final counts = raw.select(
        "SELECT sum(value LIKE 'new %'), sum(value LIKE 'old %') "
        "FROM configurations WHERE title LIKE 'invented_row_%'",
      );
      expect(counts.single.values, [rows, 0]);
    } finally {
      raw.close();
    }
  });

  test('a snapshot replaces a file already at the target', () async {
    final target = File(p.join(tmp.path, 'export.sqlite'))
      ..writeAsStringSync('invented stale export');

    await const DatabaseFileExportService().writeSnapshot(live, target);

    expect(await readMarker(target, 'invented_key'), 'live');
  });
}
