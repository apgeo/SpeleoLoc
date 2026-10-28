import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/model/sync_people.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_origin_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_state_repository.dart';

/// Another phone's recordings, as the trips list is told of them: which they
/// are, and who recorded them — named only through the people directory as
/// last read.
void main() {
  const profile = 'p-1';
  late AppDatabase db;
  late SilexgisProfileRepository profiles;
  late SilexgisTripStateRepository trips;
  late SilexgisPeopleRepository people;
  late SilexgisTripOriginService origin;

  final named = Uuid.v7();
  final unlisted = Uuid.v7();
  final unnamed = Uuid.v7();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    profiles = SilexgisProfileRepository(
      ConfigurationRepository(db),
      InMemoryRefreshTokenStore(),
      SilexgisLocalStateRepository(db),
    );
    trips = SilexgisTripStateRepository(db);
    people = SilexgisPeopleRepository(db);
    origin = SilexgisTripOriginService(
      profiles: profiles,
      trips: trips,
      people: people,
    );
    await profiles.save(
      const SilexgisProfile(
        profileUuid: profile,
        displayName: 'Club server',
        baseUrl: 'https://club.example.org',
        accountEmail: 'caver@example.org',
      ),
    );
    for (final (recording, caver) in <(Uuid, String?)>[
      (named, 'caver-1'),
      (unlisted, 'caver-gone'),
      (unnamed, null),
    ]) {
      await trips.recordDownloaded(
        profile,
        SilexgisTripState(
          entityUuid: recording,
          recordingUuid: recording,
          received: true,
          authorDeviceUserId: 'u-1',
          authorCaverId: caver,
        ),
      );
    }
  });
  tearDown(() => db.close());

  test('names the caver the directory lists, and no other', () async {
    await people.replaceDirectory(profile, const <SyncPerson>[
      SyncPerson(id: 'caver-1', fullName: 'Invented Caver'),
    ]);

    final received = (await origin.received())!;
    expect(received.recordings, <Uuid>{named, unlisted, unnamed});
    expect(received.recordedBy, <Uuid, String>{named: 'Invented Caver'});
  });

  test('names nobody once the directory is no longer offered', () async {
    await people.replaceDirectory(profile, const <SyncPerson>[
      SyncPerson(id: 'caver-1', fullName: 'Invented Caver'),
    ]);
    await people.clearDirectory(profile);

    final received = (await origin.received())!;
    expect(received.recordings, hasLength(3));
    expect(received.recordedBy, isEmpty);
  });
}
