import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/database_swap/database_file_restore.dart';
import 'package:speleoloc/services/database_swap/database_file_validator.dart';
import 'package:speleoloc/services/database_swap/live_database_swap.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';

import '../../support/database_file_fixtures.dart';

/// Restoring a picked database file keeps this device's identity, and a file
/// that cannot be restored leaves everything as it was. Invented data only.
void main() {
  late Directory tmp;
  late File liveFile;
  late DatabaseFileRestore restore;

  Future<String?> config(String key) =>
      ConfigurationRepository(appDatabase).readString(key);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('database_file_restore_');
    final docs = await Directory(p.join(tmp.path, 'docs')).create();
    liveFile = File(p.join(docs.path, 'speleo_loc.sqlite'));
    await appDatabaseFile(liveFile.path, marker: 'live');
    appDatabase = AppDatabase.file(liveFile);
    await ConfigurationRepository(
      appDatabase,
    ).writeString('device_uuid', 'invented-this-device');
    restore = DatabaseFileRestore(
      swap: LiveDatabaseSwap(
        documentsDirectory: () async => docs,
        openLiveDatabase: () => AppDatabase.file(liveFile),
        install: (db) => appDatabase = db,
      ),
      silexgisTokens: _NoTokens(),
    );
  });

  tearDown(() async {
    await appDatabase.close();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('a picked database replaces the data and the device keeps its '
      'identity', () async {
    final picked = await appDatabaseFile(p.join(tmp.path, 'picked.sqlite'));
    final other = AppDatabase.file(picked);
    await ConfigurationRepository(
      other,
    ).writeString('device_uuid', 'invented-other-device');
    await other.close();

    await restore.restoreFrom(picked);

    expect(await config('invented_key'), 'incoming');
    expect(await config('device_uuid'), 'invented-this-device');
  });

  test('a picked file that is not a database changes nothing', () async {
    final live = appDatabase;
    final picked = File(p.join(tmp.path, 'picked.db'))
      ..writeAsStringSync('invented text');

    await expectLater(
      restore.restoreFrom(picked),
      throwsA(isA<InvalidDatabaseFileException>()),
    );

    expect(appDatabase, same(live));
    expect(await config('invented_key'), 'live');
  });
}

class _NoTokens implements SilexgisRefreshTokenStore {
  @override
  Future<String?> read(String profileUuid) async => null;

  @override
  Future<void> write(String profileUuid, String refreshToken) async {}

  @override
  Future<void> delete(String profileUuid) async {}
}
