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

  test('drops the exporter\'s language when this device chose none', () async {
    await (await DevicePreferencesCarryOver.capture(before)).applyTo(after);
    expect(
      await ConfigurationRepository(after).readString(appLanguageKey),
      isNull,
    );
  });
}
