import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/sync/ftp/ftp_sync_progress.dart';
import 'package:speleoloc/services/sync/ftp/ftp_transport.dart';

import '../support/fake_ftp_folder.dart';
import '../support/ftp_sync_peer.dart';
import '../support/sync_device.dart';

/// What a sync run does when the folder or the connection lets it down: a
/// damaged checksum file, a connection that drops at each step, and the
/// bookkeeping that decides what the next run downloads and uploads.
void main() {
  late Directory workspaces;
  setUpAll(() async => workspaces = await installFtpSyncPlatformFakes());

  late FakeFtpFolder folder;
  late FtpSyncPeer a;
  late FtpSyncPeer b;

  setUp(() async {
    folder = FakeFtpFolder();
    final deviceA = await SyncTestDevice.create();
    final deviceB = await SyncTestDevice.create();
    addTearDown(deviceA.dispose);
    addTearDown(deviceB.dispose);
    a = await FtpSyncPeer.join(deviceA, folder);
    b = await FtpSyncPeer.join(deviceB, folder);
  });

  Future<List<String>> caveTitles(FtpSyncPeer peer) async => [
    for (final c in await peer.device.caves.getCaves()) c.title,
  ];

  /// A publishes one archive holding a cave, and returns its name.
  Future<String> publishFromA() async {
    await a.device.caves.addCave('Invented Cave A');
    await syncRound([a]);
    return folder.archives.single;
  }

  Set<String> scratch() => {for (final e in workspaces.listSync()) e.path};

  int downloadsOf(String name) =>
      folder.downloads.where((n) => n == name).length;

  group('a checksum file that does not vouch for its archive', () {
    test('a mismatching one skips the archive with a warning, and it is not '
        'downloaded again while its size stays the same', () async {
      final archive = await publishFromA();
      folder.publish(archive, folder.files[archive]!, checksum: '0' * 64);

      final end = await b.sync();

      expect(end.phase, FtpSyncPhase.completed, reason: end.errorMessage);
      expect(end.warningMessage, contains(archive));
      expect(await caveTitles(b), isEmpty);

      await b.sync();
      expect(downloadsOf(archive), 1);
    });

    test('one of the wrong length is reported as malformed', () async {
      final archive = await publishFromA();
      folder.publish(archive, folder.files[archive]!, checksum: '0' * 63);

      final end = await b.sync();

      expect(end.phase, FtpSyncPhase.completed, reason: end.errorMessage);
      expect(end.warningMessage, contains('malformed'));
      expect(await caveTitles(b), isEmpty);
    });
  });

  group('a connection that fails', () {
    test('at connect fails the run, saying why', () async {
      folder.fault = (step, _) => step == FtpFolderStep.connect
          ? const FtpTransportException('connection refused by invented host')
          : null;

      final end = await b.sync();

      expect(end.phase, FtpSyncPhase.failed);
      expect(end.errorMessage, contains('connection refused'));
    });

    test('while the archive goes up publishes nothing, and the next run '
        'sends it', () async {
      await b.device.caves.addCave('Invented Cave B');
      folder.fault = (step, name) =>
          step == FtpFolderStep.upload && name.endsWith('.zip.part')
          ? const FtpTransportException('connection dropped')
          : null;

      final end = await b.sync();

      expect(end.phase, FtpSyncPhase.failed);
      expect(folder.archives, isEmpty);

      folder.fault = null;
      await syncRound([b]);
      expect(folder.archives, hasLength(1));
      await syncRound([a]);
      expect(await caveTitles(a), ['Invented Cave B']);
    });

    test('while the archive is renamed into place publishes nothing, and '
        'the next run sends it and clears the leftover', () async {
      await b.device.caves.addCave('Invented Cave B');
      folder.fault = (step, _) => step == FtpFolderStep.rename
          ? const FtpTransportException('connection dropped')
          : null;

      final end = await b.sync();

      expect(end.phase, FtpSyncPhase.failed);
      expect(folder.archives, isEmpty);
      expect(folder.files.keys.where((n) => n.endsWith('.part')), hasLength(1));

      folder.fault = null;
      await syncRound([b]);
      expect(folder.archives, hasLength(1));
      expect(folder.files.keys.where((n) => n.endsWith('.part')), isEmpty);
      await syncRound([a]);
      expect(await caveTitles(a), ['Invented Cave B']);
    });

    test(
      'after an import does not download that archive again',
      () async {
        final archive = await publishFromA();
        await b.device.caves.addCave('Invented Cave B');
        folder.fault = (step, _) => step == FtpFolderStep.upload
            ? const FtpTransportException('connection dropped')
            : null;

        final end = await b.sync();

        expect(end.phase, FtpSyncPhase.failed);
        expect(await caveTitles(b), contains('Invented Cave A'));

        folder.fault = null;
        await syncRound([b]);
        expect(downloadsOf(archive), 1);
      },
      skip:
          'fix pending: a run that fails after importing forgets which '
          'archives it imported',
    );

    test(
      'part-way leaves no scratch files behind',
      () async {
        await b.device.caves.addCave('Invented Cave B');
        final before = scratch();
        folder.fault = (step, _) => step == FtpFolderStep.upload
            ? const FtpTransportException('connection dropped')
            : null;

        final end = await b.sync();

        expect(end.phase, FtpSyncPhase.failed);
        expect(scratch(), before);
      },
      skip:
          'fix pending: a run that fails part-way leaves its scratch folder '
          'in the temporary files',
    );
  });

  test('a change made at the moment of the last upload does not upload '
      'again', () async {
    await b.device.caves.addCave('Invented Cave B');
    await syncRound([b]);
    final uploaded = folder.archives.single;
    final at = int.parse(uploaded.split('_')[3]);
    // The upload is dated when its archive is made; a change logged in that
    // same millisecond is already in it.
    await b.device.db.customStatement('UPDATE change_log SET changed_at = ?', [
      at,
    ]);

    await syncRound([b]);

    expect(folder.archives, [uploaded]);
  });

  test('an older archive without its checksum file goes unreported once a '
      'newer one from the same phone can be read', () async {
    final older = await publishFromA();
    folder.files.remove('$older.sha256');
    await a.device.caves.addCave('Invented Cave A2');
    await tick();
    await syncRound([a]);
    expect(folder.archives, hasLength(2));

    final end = await b.sync();

    expect(end.phase, FtpSyncPhase.completed, reason: end.errorMessage);
    expect(end.warningMessage, isNull);
    expect(
      await caveTitles(b),
      unorderedEquals(['Invented Cave A', 'Invented Cave A2']),
    );
  });
}
