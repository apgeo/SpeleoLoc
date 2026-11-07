import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/sync/ftp/ftp_sync_progress.dart';

import '../support/fake_ftp_folder.dart';
import '../support/ftp_sync_peer.dart';
import '../support/sync_assertions.dart';
import '../support/sync_device.dart';

/// Several phones syncing through one shared folder, each run as a caver's
/// tap on Sync.
void main() {
  setUpAll(installFtpSyncPlatformFakes);

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

  test('two phones that each recorded a cave end with both', () async {
    await a.device.caves.addCave('Invented Cave A');
    await b.device.caves.addCave('Invented Cave B');

    await syncRound([a, b]);
    await syncRound([a, b]);

    for (final peer in [a, b]) {
      expect(
        (await peer.device.caves.getCaves()).map((c) => c.title),
        unorderedEquals(['Invented Cave A', 'Invented Cave B']),
      );
      await expectNoOrphans(peer.device.db);
    }
    await expectConverged(a.device.db, b.device.db);
  });

  test('a run that both receives and sends merges, then uploads the '
      'merged state', () async {
    await a.device.caves.addCave('Invented Cave A');
    await syncRound([a]);
    await b.device.caves.addCave('Invented Cave B');

    final end = await b.sync();

    expect(end.phase, FtpSyncPhase.completed, reason: end.errorMessage);
    expect(
      (await b.device.caves.getCaves()).map((c) => c.title),
      unorderedEquals(['Invented Cave A', 'Invented Cave B']),
    );
    expect(folder.archives, hasLength(2), reason: 'one per phone');
    await syncRound([a]);
    await expectConverged(a.device.db, b.device.db);
  });
}
