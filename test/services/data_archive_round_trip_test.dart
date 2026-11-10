import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/data_archive_service.dart';
import 'package:speleoloc/services/data_export_import_repository.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile_repository.dart';
import 'package:speleoloc/utils/contained_path.dart';

import '../support/populated_cave.dart';
import '../support/sync_assertions.dart';
import '../support/sync_device.dart';

/// A whole-database export taken back in: replacing the database brings
/// every record back as it was, merging brings each record once, and FTP
/// passwords travel only when the export was asked to carry them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory docs;
  late Directory out;
  final secrets = <String, String>{};

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('data_archive_trip_');
    docs = await Directory(p.join(tempDir.path, 'docs')).create();
    out = await Directory(p.join(tempDir.path, 'out')).create();
    secrets.clear();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final key = args['key'] as String?;
        return switch (call.method) {
          'write' => secrets[key!] = args['value'] as String,
          'read' => secrets[key!],
          'delete' => secrets.remove(key!),
          _ => null,
        };
      },
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => docs.path,
    );
  });

  tearDown(() async {
    await appDatabase.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  /// The phone that exports: its database is the app's live database file,
  /// holding a cave with one of everything.
  Future<SyncTestDevice> source() async {
    final d = await SyncTestDevice.create(
      executor: NativeDatabase(File(p.join(docs.path, databaseFileName))),
    );
    addTearDown(d.dispose);
    appDatabase = d.db;
    await PopulatedCave.build(d);
    return d;
  }

  Future<String> export(
    SyncTestDevice d, {
    bool passwords = false,
    FtpProfileRepository? profiles,
  }) => DataArchiveService(DataExportImportRepository(d.db)).exportArchive(
    settings: ExportSettings(
      includeDocumentationFiles: false,
      includeRasterMaps: false,
      includeFtpPasswords: passwords,
    ),
    outputDir: out.path,
    profileRepository: profiles,
  );

  test('a replace import brings every record back, and keeps this phone\'s '
      'device id', () async {
    final a = await source();
    final expected = await syncedContent(a.db);
    final zip = await export(a);
    await a.db.close();
    for (final suffix in ['', '-wal', '-shm']) {
      final f = File(p.join(docs.path, '$databaseFileName$suffix'));
      if (await f.exists()) await f.delete();
    }
    appDatabase = AppDatabase();
    const here = '00000000-0000-7000-8000-00000000d001';
    await ConfigurationRepository(
      appDatabase,
    ).writeString(ConfigKey.deviceUuid, here);

    await DataArchiveService(
      DataExportImportRepository(appDatabase),
    ).importArchiveReplace(zipPath: zip, silexgisTokens: _NoTokens());

    expect(await syncedContent(appDatabase), expected);
    expect(
      await ConfigurationRepository(
        appDatabase,
      ).readString(ConfigKey.deviceUuid),
      here,
    );
    await expectNoOrphans(appDatabase);
  });

  test('a merge into a phone with its own cave brings each record once, and '
      'merging the same archive again changes nothing', () async {
    final a = await source();
    final zip = await export(a);
    final aCaves = await a.uuidsOf('caves');
    await a.db.close();
    final b = await SyncTestDevice.create();
    addTearDown(b.dispose);
    appDatabase = b.db;
    final own = await b.caves.addCave('Invented Own Cave');
    final service = DataArchiveService(DataExportImportRepository(b.db));

    await service.importArchiveMerge(zipPath: zip, merger: b.sync);

    expect(await b.uuidsOf('caves'), {own, ...aCaves});
    expect(
      (await b.caves.getCaves()).map((c) => c.title),
      unorderedEquals(['Invented Own Cave', 'Invented Cave']),
    );
    await expectNoOrphans(b.db);

    final before = await syncedContent(b.db);
    final again = await service.importArchiveMerge(
      zipPath: zip,
      merger: b.sync,
    );
    expect(again.rowsInserted, 0);
    expect(again.rowsUpdated, 0);
    expect(again.deletesApplied, 0);
    expect(await syncedContent(b.db), before);
  });

  group('FTP passwords', () {
    const withPassword = FtpProfile(
      profileUuid: '00000000-0000-7000-8000-0000000f7001',
      displayName: 'Invented club',
      protocol: FtpProtocol.sftp,
      host: 'sftp.example.test',
      port: null,
      username: 'caver',
      remoteFolder: '/',
    );
    const withoutPassword = FtpProfile(
      profileUuid: '00000000-0000-7000-8000-0000000f7002',
      displayName: 'Invented spare',
      protocol: FtpProtocol.sftp,
      host: 'spare.example.test',
      port: null,
      username: 'caver',
      remoteFolder: '/',
    );

    Future<List<Map<String, dynamic>>?> credentialsIn(String zip) async {
      final entry = ZipDecoder()
          .decodeBytes(await File(zip).readAsBytes())
          .findFile('ftp_credentials.json');
      if (entry == null) return null;
      return [
        for (final e
            in jsonDecode(utf8.decode(entry.content as List<int>)) as List)
          e as Map<String, dynamic>,
      ];
    }

    late SyncTestDevice a;
    late FtpProfileRepository profiles;
    setUp(() async {
      a = await source();
      profiles = FtpProfileRepository(a.db);
      await profiles.save(withPassword, password: 'invented-secret');
      await profiles.save(withoutPassword);
    });

    test('stay out of an export that was not asked to carry them', () async {
      final zip = await export(a, profiles: profiles);

      expect(await credentialsIn(zip), isNull);
    });

    test('travel, when asked, only for a profile that has one', () async {
      final zip = await export(a, passwords: true, profiles: profiles);

      final byProfile = {
        for (final c in (await credentialsIn(zip))!) c['profileUuid']: c,
      };
      expect(byProfile.keys, {
        withPassword.profileUuid,
        withoutPassword.profileUuid,
      });
      expect(
        byProfile[withPassword.profileUuid]!['password'],
        'invented-secret',
      );
      expect(byProfile[withoutPassword.profileUuid]!['password'] ?? '', '');
    });
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
