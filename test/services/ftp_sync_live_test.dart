@Tags(['live'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile_repository.dart';
import 'package:speleoloc/services/sync/ftp/ftp_sync_controller.dart';
import 'package:speleoloc/services/sync/ftp/ftp_sync_progress.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/user_repository.dart';

/// **Opt-in live integration test.** Talks to a real FTP server. Disabled by
/// default because it has external preconditions (network, credentials, a
/// shared remote folder) and is therefore not suitable for the regular test
/// matrix.
///
/// To run it:
///
/// 1. Drop credentials into `test_data/ftp_test.json` (gitignored). See
///    [_LiveConfig.fromJsonFile] for the expected shape.
/// 2. Set the environment variable `SPELEO_LOC_FTP_LIVE=1`.
/// 3. Run with `flutter test --tags live test/services/ftp_sync_live_test.dart`.
///
/// What it asserts (the upload-skipping decision matrix):
///   * First run on a fresh device → upload happens (lastUploadAt was null).
///   * Second run, no local changes → upload is skipped.
///   * Third run after a fresh local mutation → upload happens again.
///
/// The test uses a unique remote subfolder derived from a generated UUID so
/// concurrent runs / leftover artefacts don't pollute the assertions.
void main() {
  if (Platform.environment['SPELEO_LOC_FTP_LIVE'] != '1') {
    test('FTP live test skipped (set SPELEO_LOC_FTP_LIVE=1 to enable)', () {});
    return;
  }

  final configFile = File(p.join(
    Directory.current.path,
    'test_data',
    'ftp_test.json',
  ));
  if (!configFile.existsSync()) {
    test('FTP live test skipped (missing test_data/ftp_test.json)', () {});
    return;
  }

  late _LiveConfig cfg;
  late Directory tempRoot;
  late String remoteFolder;

  setUpAll(() async {
    cfg = _LiveConfig.fromJsonFile(configFile);
    tempRoot = await Directory.systemTemp.createTemp('speleoloc_ftp_live_');
    // Carve out a unique remote folder so the test is hermetic against
    // concurrent runs and previous failures. We assume the parent folder
    // exists and is writable; subfolder creation is handled by upload.
    final stamp = DateTime.now().millisecondsSinceEpoch;
    remoteFolder = p.posix.join(cfg.remoteFolder, 'auto_test_$stamp');

    // Stub PathProvider so [getTemporaryDirectory] returns a sandbox dir
    // (the controller writes its workspace there).
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getTemporaryDirectory') {
        final d = await Directory.systemTemp
            .createTemp('speleoloc_ftp_live_pp_');
        return d.path;
      }
      return null;
    });
  });

  tearDownAll(() async {
    try {
      await tempRoot.delete(recursive: true);
    } catch (_) {}
  });

  test(
    'live FTP sync respects the upload-skipping decision matrix',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      late ChangeLogger loggerRef;
      final userRepo = UserRepository(db, () => loggerRef);
      final currentUser = CurrentUserService(db, userRepo);
      await currentUser.initialize();
      loggerRef = ChangeLogger(db, currentUser);
      final caveRepo = CaveRepository(db, currentUser, loggerRef);
      final assetsDir = await Directory.systemTemp
          .createTemp('speleoloc_ftp_live_assets_');
      final sync = SyncArchiveService(
        db,
        loggerRef,
        assetsBaseDirResolver: () async => assetsDir,
      );

      final profileRepo = FtpProfileRepository(db);
      final profile = FtpProfile(
        profileUuid: 'live-test-${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Live test',
        protocol: cfg.protocol,
        host: cfg.host,
        port: cfg.port,
        username: cfg.username,
        remoteFolder: remoteFolder,
      );
      await profileRepo.save(profile, password: cfg.password);
      await profileRepo.setDefaultUuid(profile.profileUuid);

      final controller = FtpSyncController(
        db: db,
        profileRepository: profileRepo,
        archiveService: sync,
        currentUserService: currentUser,
      );

      // Need at least one local entity so the export carries data.
      await caveRepo.addCave('LiveTestCave');

      // Run #1 — first time on this device → should upload.
      await controller.startDefault();
      await _waitForTerminal(controller);
      expect(controller.progress.phase, FtpSyncPhase.completed,
          reason: _formatLog(controller));
      expect(controller.progress.statusMessage, 'ftp_phase_completed',
          reason: 'Run #1 must upload');

      // Run #2 — no local mutations → must NOT re-upload.
      await controller.startDefault();
      await _waitForTerminal(controller);
      expect(controller.progress.phase, FtpSyncPhase.completed,
          reason: _formatLog(controller));
      expect(controller.progress.statusMessage,
          anyOf('ftp_phase_completed_nothing',
              'ftp_phase_completed_download_only'),
          reason: 'Run #2 must skip the upload');

      // Run #3 — fresh local change → upload again.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await caveRepo.addCave('LiveTestCave2');
      await controller.startDefault();
      await _waitForTerminal(controller);
      expect(controller.progress.phase, FtpSyncPhase.completed,
          reason: _formatLog(controller));
      expect(controller.progress.statusMessage, 'ftp_phase_completed',
          reason: 'Run #3 must upload');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

class _LiveConfig {
  final String host;
  final int port;
  final FtpProtocol protocol;
  final String username;
  final String password;
  final String remoteFolder;

  _LiveConfig({
    required this.host,
    required this.port,
    required this.protocol,
    required this.username,
    required this.password,
    required this.remoteFolder,
  });

  factory _LiveConfig.fromJsonFile(File f) {
    final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    final protoStr = (json['protocol'] as String? ?? 'ftp').toLowerCase();
    final protocol = FtpProtocol.values.firstWhere(
      (p) => p.name == protoStr,
      orElse: () => FtpProtocol.ftp,
    );
    return _LiveConfig(
      host: json['host'] as String,
      port: json['port'] as int? ?? 21,
      protocol: protocol,
      username: json['username'] as String,
      password: json['password'] as String,
      remoteFolder: json['remoteFolder'] as String? ?? '/',
    );
  }
}

Future<FtpSyncProgress> _waitForTerminal(FtpSyncController c) async {
  while (c.progress.isRunning || c.progress.isPaused) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  return c.progress;
}

String _formatLog(FtpSyncController c) =>
    c.progress.log.map((e) => '${e.level.name}: ${e.message}').join('\n');
