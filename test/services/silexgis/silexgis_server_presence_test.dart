import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_presence.dart';

/// A deletion of something the installation holds travels there, so a screen
/// can tell the caver before confirming it.
void main() {
  late AppDatabase db;
  late SilexgisLocalStateRepository localState;
  late SilexgisProfileRepository profiles;
  late SilexgisServerPresence presence;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localState = SilexgisLocalStateRepository(db);
    profiles = SilexgisProfileRepository(
      ConfigurationRepository(db),
      InMemoryRefreshTokenStore(),
      localState,
    );
    presence = SilexgisServerPresence(
      profiles: profiles,
      localState: localState,
    );
  });
  tearDown(() => db.close());

  test('with no installation configured, nothing is held there', () async {
    expect(await presence.holdingInstallation(Uuid.v7()), isNull);
  });

  test('an item the installation holds names it', () async {
    await profiles.save(
      const SilexgisProfile(
        profileUuid: 'p-1',
        displayName: 'Invented club',
        baseUrl: 'https://club.example.org',
      ),
    );
    final trip = Uuid.v7();
    await localState.writeRevision(
      'p-1',
      trip,
      entityTable: 'cave_trips',
      revision: '2026-10-01T08:00:00Z',
    );

    expect(await presence.holdingInstallation(trip), 'Invented club');
    // Made here and never sent: deleting it removes nothing there.
    expect(await presence.holdingInstallation(Uuid.v7()), isNull);
  });

  test('a deletion of several items counts the ones the installation '
      'holds', () async {
    await profiles.save(
      const SilexgisProfile(
        profileUuid: 'p-1',
        displayName: 'Invented club',
        baseUrl: 'https://club.example.org',
      ),
    );
    final held = <Uuid>[Uuid.v7(), Uuid.v7()];
    for (final uuid in held) {
      await localState.writeRevision(
        'p-1',
        uuid,
        entityTable: 'cave_places',
        revision: '2026-10-01T08:00:00Z',
      );
    }

    final found = await presence.holdingInstallationOfAny(<Uuid>[
      ...held,
      Uuid.v7(),
    ]);
    expect(found?.installation, 'Invented club');
    expect(found?.count, 2);
    expect(await presence.holdingInstallationOfAny(<Uuid>[Uuid.v7()]), isNull);
  });
}
