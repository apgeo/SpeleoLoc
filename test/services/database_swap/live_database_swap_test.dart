import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/data/source/database/database_file_version.dart';
import 'package:speleoloc/services/database_swap/database_file_validator.dart';
import 'package:speleoloc/services/database_swap/live_database_swap.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;

import '../../support/database_file_fixtures.dart';

/// Whatever replaces the live database leaves the caver's data and an open
/// database behind when it fails. Every database here is invented.
void main() {
  late Directory tmp;
  late Directory docs;
  late File liveFile;
  late AppDatabase current;
  late bool syncRunning;
  late int settled;
  late LiveDatabaseSwap swap;

  Future<String?> marker(AppDatabase db) =>
      ConfigurationRepository(db).readString('invented_key');

  List<String> docsEntries() =>
      docs.listSync().map((e) => p.basename(e.path)).toList()..sort();

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('live_database_swap_');
    docs = await Directory(p.join(tmp.path, 'docs')).create();
    liveFile = File(p.join(docs.path, 'speleo_loc.sqlite'));
    await appDatabaseFile(liveFile.path, marker: 'live');
    current = AppDatabase.file(liveFile);
    syncRunning = false;
    settled = 0;
    swap = LiveDatabaseSwap(
      documentsDirectory: () async => docs,
      openLiveDatabase: () => AppDatabase.file(liveFile),
      currentDatabase: () => current,
      install: (db) => current = db,
      isSyncRunning: () => syncRunning,
      onSettled: () async => settled++,
    );
  });

  tearDown(() async {
    await current.close();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('a file that cannot replace the database is refused before the live '
      'one is touched', () {
    Future<void> expectUntouched(AppDatabase before) async {
      expect(current, same(before));
      expect(await marker(current), 'live');
      expect(docsEntries(), ['speleo_loc.sqlite']);
      expect(settled, 0);
    }

    test('not an SQLite file', () async {
      final before = current;
      final picked = File(p.join(tmp.path, 'picked.db'))
        ..writeAsStringSync('invented text, not a database');

      await expectLater(
        swap.replaceWith(picked),
        throwsA(
          isA<InvalidDatabaseFileException>().having(
            (e) => e.reason,
            'reason',
            InvalidDatabaseFileReason.notADatabase,
          ),
        ),
      );
      await expectUntouched(before);
    });

    test('an SQLite file of another program', () async {
      final before = current;
      final picked = foreignSqliteFile(p.join(tmp.path, 'other.sqlite'));

      await expectLater(
        swap.replaceWith(picked),
        throwsA(
          isA<InvalidDatabaseFileException>().having(
            (e) => e.reason,
            'reason',
            InvalidDatabaseFileReason.notThisApp,
          ),
        ),
      );
      await expectUntouched(before);
    });

    test('a damaged database of this app', () async {
      final before = current;
      final picked = await damagedAppDatabaseFile(
        p.join(tmp.path, 'damaged.sqlite'),
      );

      await expectLater(
        swap.replaceWith(picked),
        throwsA(
          isA<InvalidDatabaseFileException>().having(
            (e) => e.reason,
            'reason',
            InvalidDatabaseFileReason.damaged,
          ),
        ),
      );
      await expectUntouched(before);
    });

    test('a database from a newer app', () async {
      final before = current;
      final picked = await appDatabaseFile(p.join(tmp.path, 'newer.sqlite'));
      final raw = sqlite3.open(picked.path);
      try {
        raw.userVersion = current.schemaVersion + 1;
      } finally {
        raw.close();
      }

      await expectLater(
        swap.replaceWith(picked),
        throwsA(isA<DatabaseTooNewException>()),
      );
      await expectUntouched(before);
    });

    test('any file while a sync run is in progress', () async {
      final before = current;
      final picked = await appDatabaseFile(p.join(tmp.path, 'good.sqlite'));
      syncRunning = true;

      await expectLater(
        swap.replaceWith(picked),
        throwsA(isA<SyncRunActiveException>()),
      );
      await expectLater(
        swap.replaceWith(null),
        throwsA(isA<SyncRunActiveException>()),
      );
      await expectUntouched(before);
    });
  });

  test('a good file replaces the database and leaves nothing behind', () async {
    final picked = await appDatabaseFile(p.join(tmp.path, 'good.sqlite'));
    AppDatabase? seenByAfterOpen;

    await swap.replaceWith(
      picked,
      afterOpen: (db) async => seenByAfterOpen = db,
    );

    expect(seenByAfterOpen, same(current));
    expect(await marker(current), 'incoming');
    expect(docsEntries(), ['speleo_loc.sqlite']);
    expect(settled, 1);
  });

  test('no file starts an empty database', () async {
    await swap.replaceWith(null);

    expect(await marker(current), isNull);
    expect(docsEntries(), ['speleo_loc.sqlite']);
    expect(settled, 1);
  });

  test('a failure after the new database opened puts the old one back, '
      'open', () async {
    final picked = await appDatabaseFile(p.join(tmp.path, 'good.sqlite'));
    final before = current;

    await expectLater(
      swap.replaceWith(
        picked,
        afterOpen: (db) async =>
            throw const FileSystemException('invented: disk full'),
      ),
      throwsA(isA<FileSystemException>()),
    );

    expect(current, isNot(same(before)));
    expect(await marker(current), 'live');
    expect(docsEntries(), ['speleo_loc.sqlite']);
    expect(settled, 1);
  });

  test('a failure while starting over empty puts the old one back', () async {
    await expectLater(
      swap.replaceWith(
        null,
        afterOpen: (db) async =>
            throw const FileSystemException('invented: no test data'),
      ),
      throwsA(isA<FileSystemException>()),
    );

    expect(await marker(current), 'live');
    expect(docsEntries(), ['speleo_loc.sqlite']);
  });

  test('a swap cut short is undone at the next start', () async {
    await current.close();
    // What a kill right after the live file was moved aside and the new one
    // moved in leaves on disk.
    await liveFile.rename('${liveFile.path}${LiveDatabaseSwap.backupSuffix}');
    await appDatabaseFile(liveFile.path, marker: 'half-done');
    File(
      '${liveFile.path}${LiveDatabaseSwap.incomingSuffix}',
    ).writeAsStringSync('invented leftovers');

    expect(await swap.recoverInterruptedSwap(), isTrue);

    expect(docsEntries(), ['speleo_loc.sqlite']);
    current = AppDatabase.file(liveFile);
    expect(await marker(current), 'live');
    expect(await swap.recoverInterruptedSwap(), isFalse);
  });

  test('starting over deletes the database and opens an empty one', () async {
    await swap.discardLiveDatabase();

    expect(await marker(current), isNull);
    expect(docsEntries(), ['speleo_loc.sqlite']);
  });
}
