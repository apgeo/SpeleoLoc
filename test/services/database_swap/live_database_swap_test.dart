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
  late int installs;
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
    installs = 0;
    swap = LiveDatabaseSwap(
      documentsDirectory: () async => docs,
      openLiveDatabase: () => AppDatabase.file(liveFile),
      currentDatabase: () => current,
      install: (db) {
        installs++;
        current = db;
      },
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

  test('a failed rollback installs no empty database over the waiting '
      'backup', () async {
    final picked = await appDatabaseFile(p.join(tmp.path, 'good.sqlite'));
    final blocker = Directory(liveFile.path);

    await expectLater(
      swap.replaceWith(
        picked,
        afterOpen: (db) async {
          // Something at the live name the backup cannot be moved onto.
          await db.close();
          await liveFile.rename(p.join(tmp.path, 'moved-away.sqlite'));
          await blocker.create();
          File(p.join(blocker.path, 'invented')).writeAsStringSync('x');
          throw const FileSystemException('invented: disk full');
        },
      ),
      throwsA(isA<DatabaseRestorePendingException>()),
    );

    // Only the candidate was ever installed, and it is closed: nothing can
    // be written that the next start would throw away.
    expect(installs, 1);
    expect(
      docsEntries(),
      contains('speleo_loc.sqlite${LiveDatabaseSwap.backupSuffix}'),
    );
    await expectLater(
      swap.replaceWith(picked),
      throwsA(isA<DatabaseRestorePendingException>()),
    );

    await blocker.delete(recursive: true);
    expect(await swap.recoverInterruptedSwap(), isTrue);
    current = AppDatabase.file(liveFile);
    expect(await marker(current), 'live');
  });

  test('a swap cut short is undone at the next start, keeping what the '
      'half-done swap left at the live name', () async {
    await current.close();
    // What a kill right after the live file was moved aside and the new one
    // moved in leaves on disk.
    await liveFile.rename('${liveFile.path}${LiveDatabaseSwap.backupSuffix}');
    await appDatabaseFile(liveFile.path, marker: 'half-done');
    File(
      '${liveFile.path}${LiveDatabaseSwap.incomingSuffix}',
    ).writeAsStringSync('invented leftovers');

    expect(await swap.recoverInterruptedSwap(), isTrue);

    final entries = docsEntries();
    expect(entries, hasLength(2));
    expect(entries.first, 'speleo_loc.sqlite');
    expect(
      entries.last,
      startsWith('speleo_loc.sqlite${LiveDatabaseSwap.discardedSuffix}-'),
    );
    current = AppDatabase.file(liveFile);
    expect(await marker(current), 'live');
    final setAside = AppDatabase.file(File(p.join(docs.path, entries.last)));
    try {
      expect(await marker(setAside), 'half-done');
    } finally {
      await setAside.close();
    }
    expect(await swap.recoverInterruptedSwap(), isFalse);
  });

  test('starting over deletes the database and opens an empty one', () async {
    await swap.discardLiveDatabase();

    expect(await marker(current), isNull);
    expect(docsEntries(), ['speleo_loc.sqlite']);
  });

  group('after a swap was cut short', () {
    late File backup;

    setUp(() async {
      await current.close();
      backup = File('${liveFile.path}${LiveDatabaseSwap.backupSuffix}');
      await liveFile.rename(backup.path);
      await appDatabaseFile(liveFile.path, marker: 'half-done');
      current = AppDatabase.file(liveFile);
    });

    test('the file to export is the backup, which holds the caver\'s '
        'data', () async {
      expect((await swap.databaseFileToExport()).path, backup.path);

      await backup.delete();
      expect((await swap.databaseFileToExport()).path, liveFile.path);
    });

    test(
      'starting over sets the backup aside instead of deleting it',
      () async {
        await swap.discardLiveDatabase();

        expect(await marker(current), isNull);
        final entries = docsEntries();
        expect(entries, hasLength(2));
        expect(entries.first, 'speleo_loc.sqlite');
        expect(
          entries.last,
          startsWith('speleo_loc.sqlite${LiveDatabaseSwap.discardedSuffix}-'),
        );
        final setAside = AppDatabase.file(
          File(p.join(docs.path, entries.last)),
        );
        try {
          expect(await marker(setAside), 'live');
        } finally {
          await setAside.close();
        }
      },
    );
  });
}
