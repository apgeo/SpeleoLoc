import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';

void main() {
  late AppDatabase db;
  late SilexgisProfileRepository repo;
  late InMemoryRefreshTokenStore tokens;
  late SilexgisLocalStateRepository localState;

  const profile = SilexgisProfile(
    profileUuid: 'p-1',
    displayName: 'Clubul Speo Example',
    baseUrl: 'https://speo.example.org',
    accountEmail: 'caver@example.org',
  );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tokens = InMemoryRefreshTokenStore();
    localState = SilexgisLocalStateRepository(db);
    repo = SilexgisProfileRepository(
      ConfigurationRepository(db),
      tokens,
      localState,
    );
  });
  tearDown(() => db.close());

  group('a server profile stays out of the FTP machinery', () {
    test('the FTP protocol enum has exactly its three wire protocols', () {
      // **Never add a `silexgis` member here.** An older build reading a
      // profile with a protocol it does not recognise falls back to plain FTP.
      // It would then try to speak FTP to an HTTPS server, with the caver's
      // stored credential, on whatever host the profile names — and the best
      // case is that it fails confusingly.
      expect(FtpProtocol.values.map((p) => p.name), <String>[
        'ftp',
        'ftps',
        'sftp',
      ]);
    });

    test('it is stored under its own configuration key', () async {
      await repo.save(profile);
      final configs = ConfigurationRepository(db);
      expect(
        await configs.readString(ConfigKey.silexgisProfiles),
        contains('speo.example.org'),
      );
      // The FTP profile list is untouched by anything here.
      expect(await configs.readString(ConfigKey.ftpProfiles), isNull);
      expect(ConfigKey.silexgisProfiles, isNot(ConfigKey.ftpProfiles));
    });

    test('it carries no credential of its own', () {
      // The refresh token — 45 days of access to the club's registry — goes to
      // the platform keystore, not to a database a plaintext export carries
      // off. `accountEmail` is for the re-sign-in prompt and is not one.
      expect(profile.toJson().keys, <String>[
        'profileUuid',
        'displayName',
        'baseUrl',
        'accountEmail',
        'syncSetId',
      ]);
    });
  });

  group('the absence of a profile fails soft', () {
    test('no profile configured is the ordinary case, not an error', () async {
      expect(await repo.list(), isEmpty);
      expect(await repo.getDefaultProfile(), isNull);
      expect(await repo.getDefaultUuid(), isNull);
    });

    test('a corrupt stored list reads as none rather than throwing', () async {
      // A build that could not start because a configuration row was mangled
      // would be the one failure this whole design exists to avoid, and it
      // would be discovered in a cave.
      await ConfigurationRepository(
        db,
      ).writeString(ConfigKey.silexgisProfiles, '{not json at all');
      expect(await repo.list(), isEmpty);
    });

    test('a profile with no sync set chosen is configured, not broken', () {
      expect(profile.isReadyToSync, isFalse);
      expect(profile.copyWith(syncSetId: 'set-1').isReadyToSync, isTrue);
    });
  });

  group('storage', () {
    test('round-trips through JSON without losing a field', () {
      final decoded = SilexgisProfile.decode(
        profile.copyWith(syncSetId: 'set-1').encode(),
      );
      expect(decoded.profileUuid, 'p-1');
      expect(decoded.displayName, 'Clubul Speo Example');
      expect(decoded.baseUrl, 'https://speo.example.org');
      expect(decoded.accountEmail, 'caver@example.org');
      expect(decoded.syncSetId, 'set-1');
    });

    test('keeps a base address that carries a path prefix', () {
      // An installation may sit behind a reverse proxy under a subdirectory.
      const behindProxy = SilexgisProfile(
        profileUuid: 'p-2',
        displayName: 'Behind a proxy',
        baseUrl: 'https://example.org/silexgis',
      );
      expect(behindProxy.baseUri.path, '/silexgis');
    });

    test('the first profile saved becomes the default', () async {
      await repo.save(profile);
      expect(await repo.getDefaultUuid(), 'p-1');
    });

    test('saving the same uuid replaces rather than duplicates', () async {
      await repo.save(profile);
      await repo.save(profile.copyWith(displayName: 'Renamed'));
      final all = await repo.list();
      expect(all, hasLength(1));
      expect(all.single.displayName, 'Renamed');
    });

    test('deleting takes the credential and the conversation with it', () async {
      await repo.save(profile);
      await tokens.write('p-1', 'refresh-token');
      await localState.writeSetState(
        'p-1',
        'set-1',
        cursor: 'MXwxNjM4',
        setRevision: 4,
      );
      final rowId = Uuid.v7();
      await localState.writeRevision(
        'p-1',
        rowId,
        entityTable: 'caves',
        revision: 'r1',
      );

      await repo.delete('p-1');

      expect(await repo.list(), isEmpty);
      expect(await repo.getDefaultUuid(), isNull);
      expect(await tokens.read('p-1'), isNull);
      // A resume position issued by a server this device no longer talks to is
      // at best dead weight, and at worst something to be sent back after the
      // account changed.
      expect((await localState.readSetState('p-1', 'set-1')).cursor, isNull);
      expect(await localState.readRevision('p-1', rowId), isNull);
    });

    test(
      'deleting the default promotes another rather than leaving none',
      () async {
        await repo.save(profile);
        const second = SilexgisProfile(
          profileUuid: 'p-2',
          displayName: 'Second',
          baseUrl: 'https://two.example.org',
        );
        await repo.save(second);

        await repo.delete('p-1');
        expect(await repo.getDefaultUuid(), 'p-2');
      },
    );
  });
}
