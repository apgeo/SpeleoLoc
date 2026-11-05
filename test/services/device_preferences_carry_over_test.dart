import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/device_preferences_carry_over.dart';
import 'package:speleoloc/utils/constants.dart';

void main() {
  late AppDatabase before;
  late AppDatabase after;
  setUp(() async {
    before = AppDatabase.forTesting(NativeDatabase.memory());
    after = AppDatabase.forTesting(NativeDatabase.memory());
    // The replacing data was exported by someone who chose Romanian.
    await ConfigurationRepository(after).writeString(appLanguageKey, 'ro');
  });
  tearDown(() async {
    await before.close();
    await after.close();
  });

  test('keeps the language this device chose', () async {
    await ConfigurationRepository(before).writeString(appLanguageKey, 'en');
    await (await DevicePreferencesCarryOver.capture(before)).applyTo(after);
    expect(
      await ConfigurationRepository(after).readString(appLanguageKey),
      'en',
    );
  });

  test('keeps this device\'s FTP endpoints, not the exporter\'s', () async {
    // Passwords live in the keystore keyed by profile uuid, so a profile
    // list taken from the replacing data would send this device's saved
    // password to whichever host that list names.
    const mine =
        '[{"profileUuid":"00000000-0000-7000-8000-000000000001",'
        '"host":"ftp.example.test"}]';
    await ConfigurationRepository(
      before,
    ).writeString(ConfigKey.ftpProfiles, mine);
    final theirs = ConfigurationRepository(after);
    await theirs.writeString(
      ConfigKey.ftpProfiles,
      '[{"profileUuid":"00000000-0000-7000-8000-000000000001",'
      '"host":"attacker.example.test"}]',
    );
    await theirs.writeString(
      ConfigKey.ftpDefaultProfileUuid,
      '00000000-0000-7000-8000-000000000001',
    );

    await (await DevicePreferencesCarryOver.capture(before)).applyTo(after);

    expect(await theirs.readString(ConfigKey.ftpProfiles), mine);
    expect(await theirs.readString(ConfigKey.ftpDefaultProfileUuid), isNull);
  });

  test(
    'keeps which trip this device records into, not the exporter\'s',
    () async {
      // A restored archive exported while the exporter's trip ran must not make
      // that trip this device's: the next scans would land in it.
      const mine = '00000000-0000-7000-8000-00000000000a';
      const theirs = '00000000-0000-7000-8000-00000000000b';
      final incoming = ConfigurationRepository(after);
      await incoming.writeString(activeTripConfigKey, theirs);

      await (await DevicePreferencesCarryOver.capture(before)).applyTo(after);
      expect(await incoming.readString(activeTripConfigKey), isNull);

      await incoming.writeString(activeTripConfigKey, theirs);
      await ConfigurationRepository(
        before,
      ).writeString(activeTripConfigKey, mine);
      await (await DevicePreferencesCarryOver.capture(before)).applyTo(after);
      expect(await incoming.readString(activeTripConfigKey), mine);
    },
  );

  test('keeps this device\'s beacon detection setting, not the '
      'exporter\'s', () async {
    // An imported archive must not switch detection on, or tune it, on a
    // device whose caver never chose to.
    const mine = '{"enabled":false,"rssiThresholdDbm":-75}';
    const theirs = '{"enabled":true,"rssiThresholdDbm":-90}';
    final incoming = ConfigurationRepository(after);
    await incoming.writeString(beaconDetectionConfigKey, theirs);

    await (await DevicePreferencesCarryOver.capture(before)).applyTo(after);
    expect(await incoming.readString(beaconDetectionConfigKey), isNull);

    await incoming.writeString(beaconDetectionConfigKey, theirs);
    await ConfigurationRepository(
      before,
    ).writeString(beaconDetectionConfigKey, mine);
    await (await DevicePreferencesCarryOver.capture(before)).applyTo(after);
    expect(await incoming.readString(beaconDetectionConfigKey), mine);
  });

  test('drops the exporter\'s language when this device chose none', () async {
    await (await DevicePreferencesCarryOver.capture(before)).applyTo(after);
    expect(
      await ConfigurationRepository(after).readString(appLanguageKey),
      isNull,
    );
  });

  group('a restore onto a device with no FTP profiles', () {
    const incoming = '00000000-0000-7000-8000-000000000002';
    const archiveProfiles =
        '[{"profileUuid":"$incoming","host":"ftp.example.test"}]';
    late List<String> forgotten;

    setUp(() async {
      forgotten = <String>[];
      final theirs = ConfigurationRepository(after);
      await theirs.writeString(ConfigKey.ftpProfiles, archiveProfiles);
      await theirs.writeString(ConfigKey.ftpDefaultProfileUuid, incoming);
    });

    Future<void> forget(String uuid) async => forgotten.add(uuid);

    test('takes the archive\'s profiles and clears any secret this device '
        'holds under their uuids', () async {
      await (await DevicePreferencesCarryOver.capture(
        before,
      )).applyTo(after, adoptFtpProfiles: forget);

      final theirs = ConfigurationRepository(after);
      expect(await theirs.readString(ConfigKey.ftpProfiles), archiveProfiles);
      expect(
        await theirs.readString(ConfigKey.ftpDefaultProfileUuid),
        incoming,
      );
      // A password or trusted host key left under that uuid would attach
      // itself to whichever host the incoming profile names.
      expect(forgotten, <String>[incoming]);
    });

    test('an empty list counts as none', () async {
      await ConfigurationRepository(
        before,
      ).writeString(ConfigKey.ftpProfiles, '[]');

      await (await DevicePreferencesCarryOver.capture(
        before,
      )).applyTo(after, adoptFtpProfiles: forget);

      expect(
        await ConfigurationRepository(after).readString(ConfigKey.ftpProfiles),
        archiveProfiles,
      );
    });

    test('keeps the device\'s profiles when it has some', () async {
      const mine =
          '[{"profileUuid":"00000000-0000-7000-8000-000000000001",'
          '"host":"mine.example.test"}]';
      await ConfigurationRepository(
        before,
      ).writeString(ConfigKey.ftpProfiles, mine);

      await (await DevicePreferencesCarryOver.capture(
        before,
      )).applyTo(after, adoptFtpProfiles: forget);

      final theirs = ConfigurationRepository(after);
      expect(await theirs.readString(ConfigKey.ftpProfiles), mine);
      expect(await theirs.readString(ConfigKey.ftpDefaultProfileUuid), isNull);
      expect(forgotten, isEmpty);
    });

    test(
      'drops the archive\'s profiles when a secret cannot be cleared',
      () async {
        await (await DevicePreferencesCarryOver.capture(before)).applyTo(
          after,
          adoptFtpProfiles: (_) async => throw Exception('keystore locked'),
        );

        final theirs = ConfigurationRepository(after);
        expect(await theirs.readString(ConfigKey.ftpProfiles), isNull);
        expect(
          await theirs.readString(ConfigKey.ftpDefaultProfileUuid),
          isNull,
        );
      },
    );

    test('a default naming no incoming profile is not kept', () async {
      await ConfigurationRepository(after).writeString(
        ConfigKey.ftpDefaultProfileUuid,
        '00000000-0000-7000-8000-000000000009',
      );

      await (await DevicePreferencesCarryOver.capture(
        before,
      )).applyTo(after, adoptFtpProfiles: forget);

      expect(
        await ConfigurationRepository(
          after,
        ).readString(ConfigKey.ftpDefaultProfileUuid),
        isNull,
      );
    });

    test('a sample dataset or a reinitialize never brings profiles', () async {
      await (await DevicePreferencesCarryOver.capture(before)).applyTo(after);

      final theirs = ConfigurationRepository(after);
      expect(await theirs.readString(ConfigKey.ftpProfiles), isNull);
      expect(await theirs.readString(ConfigKey.ftpDefaultProfileUuid), isNull);
    });
  });
}
