import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_registry.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sign_in_carry_over.dart';

/// A database file replaced wholesale brings its own profile list while the
/// refresh tokens stay in this device's keystore, so a sign-in survives the
/// replace only for a profile that still names the same server.
void main() {
  late AppDatabase before;
  late AppDatabase after;
  late InMemoryRefreshTokenStore tokens;

  const mine = SilexgisProfile(
    profileUuid: 'p-1',
    displayName: 'Test Club',
    baseUrl: 'https://speo.example.test',
  );

  SilexgisProfileRepository profiles(AppDatabase db) =>
      SilexgisProfileRepository(
        ConfigurationRepository(db),
        tokens,
        SilexgisLocalStateRepository(db),
      );

  setUp(() async {
    before = AppDatabase.forTesting(NativeDatabase.memory());
    after = AppDatabase.forTesting(NativeDatabase.memory());
    tokens = InMemoryRefreshTokenStore();
    await profiles(before).save(mine);
    await tokens.write(mine.profileUuid, 'refresh-token');
  });
  tearDown(() async {
    await before.close();
    await after.close();
  });

  Future<void> replaceWith(
    List<SilexgisProfile> incoming, {
    InMemoryRefreshTokenStore? store,
    SilexgisAuthRegistry? signIns,
  }) async {
    final keystore = store ?? tokens;
    final carry = await SilexgisSignInCarryOver.capture(before, keystore);
    for (final p in incoming) {
      await profiles(after).save(p);
    }
    await carry.applyTo(after, keystore, signIns: signIns);
  }

  test(
    'restoring a database that names the same server keeps the sign-in',
    () async {
      await replaceWith([mine.copyWith(displayName: 'Renamed')]);

      expect(await tokens.read(mine.profileUuid), 'refresh-token');
    },
  );

  test(
    'a database naming another server under this profile drops the sign-in',
    () async {
      await replaceWith([
        const SilexgisProfile(
          profileUuid: 'p-1',
          displayName: 'Test Club',
          baseUrl: 'https://elsewhere.example.test',
        ),
      ]);

      expect(await tokens.read(mine.profileUuid), isNull);
    },
  );

  test('a dropped sign-in is retired while it is still live', () async {
    final signIns = SilexgisAuthRegistry(store: tokens);
    final live = signIns.forProfile(mine);

    await replaceWith(const [], signIns: signIns);

    expect(identical(signIns.forProfile(mine), live), isFalse);
  });

  test('a database without this profile drops its sign-in', () async {
    await replaceWith(const []);

    expect(await tokens.read(mine.profileUuid), isNull);
  });

  test(
    'a sign-in the keystore keeps takes the redirected profile with it',
    () async {
      final stuck = _UndeletableTokenStore();
      await stuck.write(mine.profileUuid, 'refresh-token');

      await replaceWith(const [
        SilexgisProfile(
          profileUuid: 'p-1',
          displayName: 'Test Club',
          baseUrl: 'https://elsewhere.example.test',
        ),
      ], store: stuck);

      expect(await profiles(after).find(mine.profileUuid), isNull);
    },
  );
}

/// A keystore whose delete fails the way the platform one does: quietly.
class _UndeletableTokenStore extends InMemoryRefreshTokenStore {
  @override
  Future<void> delete(String profileUuid) async {}
}
