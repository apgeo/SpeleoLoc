import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile_repository.dart';
import 'package:speleoloc/services/sync/ftp/ftp_sync_controller.dart';
import 'package:speleoloc/services/sync/ftp/ftp_sync_progress.dart';

import 'fake_ftp_folder.dart';
import 'sync_device.dart';

/// The profile every device in a test syncs with; the host is invented and
/// never dialled, the transport being a [FakeFtpFolder].
const FtpProfile fakeFtpProfile = FtpProfile(
  profileUuid: '00000000-0000-7000-8000-0000000f7f00',
  displayName: 'Invented folder',
  protocol: FtpProtocol.ftp,
  host: 'ftp.example.test',
  port: 21,
  username: 'caver',
  remoteFolder: '/',
);

/// Stands in for the keystore and the temporary-files folder an FTP sync
/// run needs. Call it from `setUpAll`; it removes what it created in
/// `tearDownAll`. [workspaces] is where the runs make their scratch
/// folders.
Future<Directory> installFtpSyncPlatformFakes() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final workspaces = await Directory.systemTemp.createTemp('ftp_sync_tmp_');
  addTearDown(() async {
    if (await workspaces.exists()) await workspaces.delete(recursive: true);
  });
  final secrets = <String, String>{};
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
        'containsKey' => secrets.containsKey(key!),
        'readAll' => Map<String, String>.of(secrets),
        _ => null,
      };
    },
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async =>
        call.method == 'getTemporaryDirectory' ? workspaces.path : null,
  );
  return workspaces;
}

/// A [SyncTestDevice] with an FTP sync set up against a shared
/// [FakeFtpFolder], as a caver would after entering the folder's profile.
class FtpSyncPeer {
  FtpSyncPeer._(this.device, this.controller);

  final SyncTestDevice device;
  final FtpSyncController controller;

  static Future<FtpSyncPeer> join(
    SyncTestDevice device,
    FakeFtpFolder folder,
  ) async {
    final profiles = FtpProfileRepository(device.db);
    await profiles.save(fakeFtpProfile, password: 'invented');
    await profiles.setDefaultUuid(fakeFtpProfile.profileUuid);
    final controller = FtpSyncController(
      db: device.db,
      profileRepository: profiles,
      archiveService: device.sync,
      currentUserService: device.currentUser,
      transportBuilder: folder.transport,
      appVersionReader: () async => '1.0.0+1',
    );
    addTearDown(controller.dispose);
    return FtpSyncPeer._(device, controller);
  }

  /// One tap on Sync, run to its end. Deletions the run asks about are
  /// accepted when [acceptDeletions] is true and declined otherwise.
  Future<FtpSyncProgress> sync({bool acceptDeletions = true}) async {
    void answer() {
      if (controller.progress.pendingDeletions == null) return;
      if (acceptDeletions) {
        controller.applyPendingDeletions();
      } else {
        controller.skipPendingDeletions();
      }
    }

    controller.addListener(answer);
    try {
      await controller.startDefault();
    } finally {
      controller.removeListener(answer);
    }
    return controller.progress;
  }
}

/// Every peer syncs once, in order. Fails the test when a run does not
/// complete, so a broken round is not mistaken for converged data.
Future<void> syncRound(List<FtpSyncPeer> peers) async {
  for (final peer in peers) {
    final end = await peer.sync();
    expect(
      end.phase,
      FtpSyncPhase.completed,
      reason: end.errorMessage ?? end.warningMessage,
    );
  }
}
