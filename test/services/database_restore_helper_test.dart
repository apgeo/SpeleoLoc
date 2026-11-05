import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/data/source/database/test_database_loader.dart';
import 'package:speleoloc/services/database_restore_helper.dart';
import 'package:speleoloc/services/database_swap/live_database_swap.dart';
import 'package:speleoloc/utils/constants.dart';

import '../support/database_file_fixtures.dart';

/// Reinitializing never costs the caver their data when it cannot finish.
/// Every database here is invented; the bundled test database is never read.
void main() {
  late Directory tmp;
  late File liveFile;
  late LiveDatabaseSwap swap;

  Future<String?> config(String key) =>
      ConfigurationRepository(appDatabase).readString(key);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('database_restore_helper_');
    final docs = await Directory(p.join(tmp.path, 'docs')).create();
    liveFile = File(p.join(docs.path, 'speleo_loc.sqlite'));
    await appDatabaseFile(liveFile.path, marker: 'live');
    appDatabase = AppDatabase.file(liveFile);
    await ConfigurationRepository(
      appDatabase,
    ).writeString(appLanguageKey, 'ro');
    swap = LiveDatabaseSwap(
      documentsDirectory: () async => docs,
      openLiveDatabase: () => AppDatabase.file(liveFile),
      install: (db) => appDatabase = db,
    );
  });

  tearDown(() async {
    await appDatabase.close();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('test data a build does not carry is refused before anything is '
      'deleted', () async {
    final live = appDatabase;

    await expectLater(
      DatabaseRestoreHelper.reinitializeDatabase(
        populateTestData: true,
        swap: swap,
        loadTestDatabaseBytes: () async => null,
      ),
      throwsA(isA<TestDatabaseUnavailableException>()),
    );

    expect(appDatabase, same(live));
    expect(await config('invented_key'), 'live');
  });

  test(
    'test data loads in place of the database, keeping the language',
    () async {
      final seed = await appDatabaseFile(
        p.join(tmp.path, 'seed.sqlite'),
        marker: 'sample',
      );
      var copied = 0;

      await DatabaseRestoreHelper.reinitializeDatabase(
        populateTestData: true,
        swap: swap,
        loadTestDatabaseBytes: seed.readAsBytes,
        copyTestResources: (db) async => copied++,
      );

      expect(await config('invented_key'), 'sample');
      expect(await config(appLanguageKey), 'ro');
      expect(copied, 1);
    },
  );

  test('a failure while loading test data puts the database back', () async {
    final seed = await appDatabaseFile(
      p.join(tmp.path, 'seed.sqlite'),
      marker: 'sample',
    );

    await expectLater(
      DatabaseRestoreHelper.reinitializeDatabase(
        populateTestData: true,
        swap: swap,
        loadTestDatabaseBytes: seed.readAsBytes,
        copyTestResources: (db) async =>
            throw const FileSystemException('invented: disk full'),
      ),
      throwsA(isA<FileSystemException>()),
    );

    expect(await config('invented_key'), 'live');
  });

  test('reinitializing empty keeps only the device settings', () async {
    await DatabaseRestoreHelper.reinitializeDatabase(
      populateTestData: false,
      swap: swap,
    );

    expect(await config('invented_key'), isNull);
    expect(await config(appLanguageKey), 'ro');
  });

  test('nothing is reinitialized while a sync run is in progress', () async {
    final live = appDatabase;
    final busy = LiveDatabaseSwap(
      documentsDirectory: () async => liveFile.parent,
      openLiveDatabase: () => AppDatabase.file(liveFile),
      install: (db) => appDatabase = db,
      isSyncRunning: () => true,
    );

    await expectLater(
      DatabaseRestoreHelper.reinitializeDatabase(
        populateTestData: false,
        swap: busy,
      ),
      throwsA(isA<SyncRunActiveException>()),
    );

    expect(appDatabase, same(live));
    expect(await config('invented_key'), 'live');
  });
}
