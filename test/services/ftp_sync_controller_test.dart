import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile_repository.dart';
import 'package:speleoloc/services/sync/ftp/ftp_sync_controller.dart';
import 'package:speleoloc/services/sync/ftp/ftp_sync_progress.dart';
import 'package:speleoloc/services/sync/ftp/ftp_transport.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/user_repository.dart';

/// In-memory transport used to exercise [FtpSyncController] without touching
/// an actual FTP server. The remote "filesystem" is just a map from filename
/// to bytes, seeded by tests via [seed].
class _FakeTransport implements IFtpTransport {
  _FakeTransport(this.profile);

  @override
  final FtpProfile profile;

  final Map<String, List<int>> store = {};
  bool connected = false;
  int connectCalls = 0;

  void seed(String name, List<int> bytes) {
    store[name] = bytes;
  }

  @override
  Future<void> connect({required String password}) async {
    connected = true;
    connectCalls++;
  }

  @override
  Future<void> disconnect() async {
    connected = false;
  }

  @override
  Future<void> verifyReadWriteAccess() async {}

  @override
  Future<List<RemoteFileEntry>> listFolder() async {
    return [
      for (final e in store.entries)
        RemoteFileEntry(name: e.key, size: e.value.length),
    ];
  }

  @override
  Future<void> uploadFile(
    File localFile,
    String remoteName, {
    TransferProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final bytes = await localFile.readAsBytes();
    store[remoteName] = bytes;
    onProgress?.call(bytes.length, bytes.length);
  }

  @override
  Future<void> downloadFile(
    String remoteName,
    File localFile, {
    TransferProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final bytes = store[remoteName];
    if (bytes == null) {
      throw FtpTransportException('missing $remoteName');
    }
    await localFile.writeAsBytes(bytes);
    onProgress?.call(bytes.length, bytes.length);
  }
}

/// Delegating transport that records the order in which files are
/// downloaded, used to validate the oldest-first scheduling.
class _OrderTrackingTransport implements IFtpTransport {
  _OrderTrackingTransport(this._inner, this._downloadOrder);
  final IFtpTransport _inner;
  final List<String> _downloadOrder;

  @override
  FtpProfile get profile => _inner.profile;

  @override
  Future<void> connect({required String password}) =>
      _inner.connect(password: password);

  @override
  Future<void> disconnect() => _inner.disconnect();

  @override
  Future<void> verifyReadWriteAccess() => _inner.verifyReadWriteAccess();

  @override
  Future<List<RemoteFileEntry>> listFolder() => _inner.listFolder();

  @override
  Future<void> uploadFile(
    File localFile,
    String remoteName, {
    TransferProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) =>
      _inner.uploadFile(localFile, remoteName,
          onProgress: onProgress, cancelToken: cancelToken);

  @override
  Future<void> downloadFile(
    String remoteName,
    File localFile, {
    TransferProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    _downloadOrder.add(remoteName);
    await _inner.downloadFile(remoteName, localFile,
        onProgress: onProgress, cancelToken: cancelToken);
  }
}

/// Transport that pauses inside downloadFile until [release] is called, and
/// fires [onDownloadStarted] as soon as the download begins. Lets tests drive
/// the controller's cancel/pause logic at a known mid-transfer point.
class _BlockingTransport implements IFtpTransport {
  _BlockingTransport(this._inner);
  final IFtpTransport _inner;
  final Completer<void> _gate = Completer<void>();

  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  FtpProfile get profile => _inner.profile;

  @override
  Future<void> connect({required String password}) =>
      _inner.connect(password: password);

  @override
  Future<void> disconnect() => _inner.disconnect();

  @override
  Future<void> verifyReadWriteAccess() => _inner.verifyReadWriteAccess();

  @override
  Future<List<RemoteFileEntry>> listFolder() => _inner.listFolder();

  @override
  Future<void> uploadFile(
    File localFile,
    String remoteName, {
    TransferProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) =>
      _inner.uploadFile(localFile, remoteName,
          onProgress: onProgress, cancelToken: cancelToken);

  @override
  Future<void> downloadFile(
    String remoteName,
    File localFile, {
    TransferProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    onProgress?.call(1, 100);
    // Wait for release *or* cancellation.
    while (!_gate.isCompleted) {
      if (cancelToken?.cancelled ?? false) {
        throw const TransferCancelledException();
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    await _inner.downloadFile(remoteName, localFile,
        onProgress: onProgress, cancelToken: cancelToken);
  }
}

class _Harness {
  _Harness(this.db, this.caveRepo, this.logger, this.sync, this.currentUser,
      this.assetsDir);
  final AppDatabase db;
  final CaveRepository caveRepo;
  final ChangeLogger logger;
  final SyncArchiveService sync;
  final CurrentUserService currentUser;
  final Directory assetsDir;
}

Future<_Harness> _buildHarness() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  late ChangeLogger loggerRef;
  final userRepo = UserRepository(db, () => loggerRef);
  final currentUser = CurrentUserService(db, userRepo);
  await currentUser.initialize();
  loggerRef = ChangeLogger(db, currentUser);
  final caveRepo = CaveRepository(db, currentUser, loggerRef);
  final assetsDir =
      await Directory.systemTemp.createTemp('speleoloc_ftp_ctrl_assets_');
  final sync = SyncArchiveService(
    db,
    loggerRef,
    assetsBaseDirResolver: () async => assetsDir,
  );
  return _Harness(db, caveRepo, loggerRef, sync, currentUser, assetsDir);
}

/// Drives the controller through [FtpSyncController.progress] and returns the
/// final progress once it reaches a terminal phase.
Future<FtpSyncProgress> _waitForTerminal(FtpSyncController c) async {
  while (c.progress.isRunning ||
      c.progress.phase == FtpSyncPhase.idle) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  return c.progress;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('speleoloc_ftp_ctrl_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  // Mock flutter_secure_storage's MethodChannel with an in-memory map so
  // profile-password read/write calls work in unit tests.
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    final store = <String, String>{};
    TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      switch (call.method) {
        case 'write':
          store[args['key'] as String] = args['value'] as String;
          return null;
        case 'read':
          return store[args['key'] as String];
        case 'delete':
          store.remove(args['key'] as String);
          return null;
        case 'readAll':
          return Map<String, String>.from(store);
        case 'deleteAll':
          store.clear();
          return null;
        case 'containsKey':
          return store.containsKey(args['key'] as String);
      }
      return null;
    });

    // Also mock path_provider so the controller's call to
    // getTemporaryDirectory() returns a sandboxed directory.
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (call) async {
      if (call.method == 'getTemporaryDirectory' ||
          call.method == 'getApplicationDocumentsDirectory' ||
          call.method == 'getApplicationSupportDirectory') {
        final d = await Directory.systemTemp
            .createTemp('speleoloc_ftp_ctrl_pp_');
        return d.path;
      }
      return null;
    });
  });

  // Convenience: build a controller wired to the given harness + transport.
  Future<(FtpSyncController, _FakeTransport)> makeController(
    _Harness h, {
    Map<String, List<int>>? seedFromHarnessExports,
  }) async {
    final profileRepo = FtpProfileRepository(h.db);
    const profile = FtpProfile(
      profileUuid: 'test-uuid',
      displayName: 'Test',
      protocol: FtpProtocol.ftp,
      host: 'example.com',
      port: 21,
      username: 'u',
      remoteFolder: '/',
    );
    await profileRepo.save(profile, password: 'pw');
    await profileRepo.setDefaultUuid(profile.profileUuid);

    final fake = _FakeTransport(profile);
    if (seedFromHarnessExports != null) {
      fake.store.addAll(seedFromHarnessExports);
    }
    final controller = FtpSyncController(
      db: h.db,
      profileRepository: profileRepo,
      archiveService: h.sync,
      currentUserService: h.currentUser,
      transportBuilder: (_) => fake,
    );
    return (controller, fake);
  }

  test('fails cleanly when no default profile is set', () async {
    final h = await _buildHarness();
    final profileRepo = FtpProfileRepository(h.db);
    final controller = FtpSyncController(
      db: h.db,
      profileRepository: profileRepo,
      archiveService: h.sync,
      currentUserService: h.currentUser,
      transportBuilder: (p) => _FakeTransport(p),
    );
    await controller.startDefault();
    expect(controller.progress.phase, FtpSyncPhase.failed);
    expect(controller.progress.errorMessage, 'no_default_profile');
  });

  test('uploads a fresh archive when the remote is empty', () async {
    final h = await _buildHarness();
    await h.caveRepo.addCave('Alpha');
    final (controller, fake) = await makeController(h);

    await controller.startDefault();
    await _waitForTerminal(controller);

    expect(controller.progress.phase, FtpSyncPhase.completed);
    // Exactly one archive should be on the remote — the one we just uploaded.
    final archives =
        fake.store.keys.where((k) => k.startsWith('speleo_loc_sync_')).toList();
    expect(archives, hasLength(1));
  });

  test('downloads unseen remote archives and imports them', () async {
    // Peer A produces an archive carrying two caves.
    final a = await _buildHarness();
    await a.caveRepo.addCave('FromPeerA1');
    await a.caveRepo.addCave('FromPeerA2');
    final zipA = await a.sync.exportToZip(
      tempDir.path,
      filenameHint: 'speleo_loc_sync_1000.zip',
    );

    // Peer B starts empty and pulls it.
    final b = await _buildHarness();
    final (controller, fake) = await makeController(
      b,
      seedFromHarnessExports: {
        'speleo_loc_sync_1000.zip': await zipA.readAsBytes(),
        'unrelated.txt': [1, 2, 3],
      },
    );

    await controller.startDefault();
    await _waitForTerminal(controller);

    expect(controller.progress.phase, FtpSyncPhase.completed,
        reason: controller.progress.log.map((e) => e.message).join('\n'));
    // Both peer caves should now exist locally on B.
    final caves = await b.db.select(b.db.caves).get();
    final names = caves.map((c) => c.title).toList();
    expect(names, containsAll(<String>['FromPeerA1', 'FromPeerA2']),
        reason: controller.progress.log.map((e) => e.message).join('\n'));
    // B must have uploaded its own archive too, and the non-archive file must
    // still be on the server untouched.
    final bArchives = fake.store.keys
        .where((k) =>
            RegExp(r'^speleo_loc_sync_\d+(?:_[a-f0-9]+)?\.zip$').hasMatch(k))
        .toList();
    expect(bArchives.length, greaterThanOrEqualTo(2));
    expect(fake.store.containsKey('unrelated.txt'), isTrue);
  });

  test('processes archives oldest-first by embedded timestamp', () async {
    // Two valid archives from the same peer, different timestamps.
    final a = await _buildHarness();
    await a.caveRepo.addCave('Cave1');
    final zip1 = await a.sync.exportToZip(
      tempDir.path,
      filenameHint: 'speleo_loc_sync_2000.zip',
    );
    final zip2 = await a.sync.exportToZip(
      tempDir.path,
      filenameHint: 'speleo_loc_sync_1000.zip',
    );

    final b = await _buildHarness();
    final downloadOrder = <String>[];
    final profileRepo = FtpProfileRepository(b.db);
    const profile = FtpProfile(
      profileUuid: 'test-uuid',
      displayName: 'Test',
      protocol: FtpProtocol.ftp,
      host: 'example.com',
      port: 21,
      username: 'u',
      remoteFolder: '/',
    );
    await profileRepo.save(profile, password: 'pw');
    await profileRepo.setDefaultUuid(profile.profileUuid);
    final fake = _FakeTransport(profile);
    fake.store['speleo_loc_sync_2000.zip'] = await zip1.readAsBytes();
    fake.store['speleo_loc_sync_1000.zip'] = await zip2.readAsBytes();

    // Wrap the fake to record download order.
    final tracking = _OrderTrackingTransport(fake, downloadOrder);

    final controller = FtpSyncController(
      db: b.db,
      profileRepository: profileRepo,
      archiveService: b.sync,
      currentUserService: b.currentUser,
      transportBuilder: (_) => tracking,
    );
    await controller.startDefault();
    await _waitForTerminal(controller);

    expect(controller.progress.phase, FtpSyncPhase.completed);
    expect(downloadOrder,
        ['speleo_loc_sync_1000.zip', 'speleo_loc_sync_2000.zip']);
  });

  test('skips archives previously seen so repeat syncs are idempotent',
      () async {
    final a = await _buildHarness();
    await a.caveRepo.addCave('FromPeer');
    final zip = await a.sync.exportToZip(
      tempDir.path,
      filenameHint: 'speleo_loc_sync_5000.zip',
    );

    final b = await _buildHarness();
    final (c1, fake) = await makeController(
      b,
      seedFromHarnessExports: {
        'speleo_loc_sync_5000.zip': await zip.readAsBytes(),
      },
    );
    await c1.startDefault();
    await _waitForTerminal(c1);
    expect(c1.progress.phase, FtpSyncPhase.completed);

    // Second pass: same remote, but the archive is now in "seen".
    final beforeCaveCount = (await b.db.select(b.db.caves).get()).length;
    // Spin up a second controller sharing the same DB (and therefore the
    // persisted seen set) but a fresh fake that still has the archive.
    final profileRepo = FtpProfileRepository(b.db);
    final c2 = FtpSyncController(
      db: b.db,
      profileRepository: profileRepo,
      archiveService: b.sync,
      currentUserService: b.currentUser,
      transportBuilder: (_) => fake,
    );
    await c2.startDefault();
    await _waitForTerminal(c2);
    expect(c2.progress.phase, FtpSyncPhase.completed);
    // No rows should have been re-imported.
    final afterCaveCount = (await b.db.select(b.db.caves).get()).length;
    expect(afterCaveCount, beforeCaveCount);
  });

  test('pause leaves the run in paused phase; resume reruns to completion',
      () async {
    final a = await _buildHarness();
    await a.caveRepo.addCave('Peer');
    final zip = await a.sync.exportToZip(
      tempDir.path,
      filenameHint: 'speleo_loc_sync_7000.zip',
    );

    final b = await _buildHarness();
    final profileRepo = FtpProfileRepository(b.db);
    const profile = FtpProfile(
      profileUuid: 'test-uuid',
      displayName: 'Test',
      protocol: FtpProtocol.ftp,
      host: 'example.com',
      port: 21,
      username: 'u',
      remoteFolder: '/',
    );
    await profileRepo.save(profile, password: 'pw');
    await profileRepo.setDefaultUuid(profile.profileUuid);

    final inner = _FakeTransport(profile);
    inner.store['speleo_loc_sync_7000.zip'] = await zip.readAsBytes();

    // First run: blocking transport that waits inside downloadFile until we
    // release it. We pause while the transport is stuck → controller should
    // surface phase=paused and the blocking download should abort.
    _BlockingTransport? currentBlocking;
    var blockingBuilt = 0;
    late final FtpSyncController controller;
    controller = FtpSyncController(
      db: b.db,
      profileRepository: profileRepo,
      archiveService: b.sync,
      currentUserService: b.currentUser,
      transportBuilder: (_) {
        blockingBuilt++;
        if (blockingBuilt == 1) {
          currentBlocking = _BlockingTransport(inner);
          return currentBlocking!;
        }
        // Second call (resume) uses the plain fake so the run can finish.
        return inner;
      },
    );

    // Kick off the run and wait until the blocking transport is actually
    // sitting inside downloadFile.
    final runFuture = controller.startDefault();
    while (controller.progress.phase != FtpSyncPhase.downloading) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    controller.pause();
    await runFuture;
    expect(controller.progress.phase, FtpSyncPhase.paused,
        reason: controller.progress.log.map((e) => e.message).join('\n'));

    // Resume: second run uses the non-blocking fake and completes normally.
    await controller.resume();
    await _waitForTerminal(controller);
    expect(controller.progress.phase, FtpSyncPhase.completed,
        reason: controller.progress.log.map((e) => e.message).join('\n'));
    final caves = await b.db.select(b.db.caves).get();
    expect(caves.map((c) => c.title), contains('Peer'));
  });
}
