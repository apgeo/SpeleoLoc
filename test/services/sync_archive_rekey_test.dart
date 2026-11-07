import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/silexgis_feature_rekeyer.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_link_repository.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';

import '../support/sync_device.dart';

/// A cave one phone sent to SilexGIS again as new reaches the other phone
/// under its new identifiers, and what only that phone held inside it moves
/// over to them rather than going with the old ones.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  late SyncTestDevice a;
  late SyncTestDevice b;
  late Uuid cave;
  late Uuid place;
  late Uuid trip;
  late Uuid point;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('rekey_');
    a = await SyncTestDevice.create();
    b = await SyncTestDevice.create();
    cave = await a.caves.addCave('Invented Cave');
    await a.places.addCavePlace(cave, 'P');
    place = await a.placeUuid(cave, 'P');
    await a.sendTo(b, tmp, 'a0.zip');

    // B records a trip in the cave, with a visit at P, and does not sync.
    await tick();
    trip = await b.db.insertCaveTrip(
      caveUuid: cave,
      title: 'Invented trip B',
      startedAt: DateTime.now().millisecondsSinceEpoch,
      authorUuid: b.author,
    );
    point = await b.db.insertTripPoint(
      tripUuid: trip,
      cavePlaceUuid: place,
      authorUuid: b.author,
    );
    await tick();
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
    await tmp.delete(recursive: true);
  });

  Future<Map<Uuid, Uuid>> sendAgainAsNew(SyncTestDevice d, Uuid cave) =>
      SilexgisFeatureRekeyer(
        db: d.db,
        logger: d.logger,
        localState: SilexgisLocalStateRepository(d.db),
        heldRows: SilexgisHeldRowRepository(d.db),
        serverLinks: SilexgisServerLinkRepository(d.db),
      ).rekey('profile-1', 'caves', cave);

  test('a trip only the other phone recorded moves to the new cave, with '
      'its visit at the new place', () async {
    final renamed = await sendAgainAsNew(a, cave);
    await tick();

    final report = await a.sendTo(b, tmp, 'a1.zip');

    expect(await b.uuidsOf('caves'), {renamed[cave]});
    expect(await b.uuidsOf('cave_places'), {renamed[place]});
    final kept = await (b.db.select(
      b.db.caveTrips,
    )..where((t) => t.uuid.equalsValue(trip))).getSingle();
    expect(kept.caveUuid, renamed[cave]);
    final visit = await (b.db.select(
      b.db.caveTripPoints,
    )..where((p) => p.uuid.equalsValue(point))).getSingle();
    expect(visit.cavePlaceUuid, renamed[place]);
    // One merge for each record that took a new identifier, as a merge the
    // caver decided counts.
    expect(report.deletesApplied, renamed.length);
    expect(report.decisionsPending, 0);
  });

  test('a held-back import counts the new identifiers as merges and moves '
      'nothing', () async {
    final renamed = await sendAgainAsNew(a, cave);
    await tick();
    final zip = await a.export(tmp, 'a1.zip');

    try {
      await b.sync.importFromZip(zip.path, holdBackDeletions: true);
      fail('the import did not hold back its merges');
    } on SyncImportHasDeletionsException catch (e) {
      expect(e.preview.deletesApplied, renamed.length);
    }
    expect(await b.uuidsOf('caves'), {cave});
    expect(await b.uuidsOf('cave_trips'), {trip});
  });
}
