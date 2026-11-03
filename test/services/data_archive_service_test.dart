import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
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
import 'package:speleoloc/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final keystoreWrites = <String>[];

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('speleoloc_data_archive_');
    keystoreWrites.clear();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        if (call.method == 'write') {
          keystoreWrites.add((call.arguments as Map)['key'] as String);
        }
        return null;
      },
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async {
        final docs = Directory(p.join(tempDir.path, 'docs'));
        await docs.create(recursive: true);
        return docs.path;
      },
    );
  });

  tearDown(() async {
    await appDatabase.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('a merge import ignores ftp_credentials.json when the build cannot '
      'export it', () async {
    // Tests run without EXPORT_FTP_PASSWORDS_ENABLED, like store builds.
    expect(exportFtpPasswordsEnabled, isFalse);

    appDatabase = AppDatabase.forTesting(NativeDatabase.memory());
    const localProfiles =
        '[{"profileUuid":"00000000-0000-7000-8000-000000000001",'
        '"displayName":"Club","protocol":"ftp","host":"ftp.example.test",'
        '"username":"caver","remoteFolder":"/"}]';
    final configs = ConfigurationRepository(appDatabase);
    await configs.writeString(ConfigKey.ftpProfiles, localProfiles);

    final sourceFile = File(p.join(tempDir.path, 'speleo_loc.sqlite'));
    final source = AppDatabase.file(sourceFile);
    await source.customSelect('SELECT 1').get();
    await source.close();
    final credentials = utf8.encode(
      jsonEncode([
        {
          'profileUuid': '00000000-0000-7000-8000-000000000001',
          'displayName': 'Club',
          'protocol': 'ftp',
          'host': 'attacker.example.test',
          'username': 'caver',
          'remoteFolder': '/',
          'password': 'from-archive',
        },
      ]),
    );
    final dbBytes = await sourceFile.readAsBytes();
    final zip = Archive()
      ..addFile(ArchiveFile('speleo_loc.sqlite', dbBytes.length, dbBytes))
      ..addFile(
        ArchiveFile('ftp_credentials.json', credentials.length, credentials),
      );
    final zipPath = p.join(tempDir.path, 'export.zip');
    await File(zipPath).writeAsBytes(ZipEncoder().encode(zip)!);

    late ChangeLogger logger;
    final currentUser = CurrentUserService(
      appDatabase,
      UserRepository(appDatabase, () => logger),
      configs,
    );
    await currentUser.initialize();
    logger = ChangeLogger(appDatabase, currentUser);

    await DataArchiveService(
      DataExportImportRepository(appDatabase),
    ).importArchiveMerge(
      zipPath: zipPath,
      merger: SyncArchiveService(appDatabase, logger),
    );

    expect(await configs.readString(ConfigKey.ftpProfiles), localProfiles);
    expect(keystoreWrites, isEmpty);
  });
}
