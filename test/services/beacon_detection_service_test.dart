import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/beacon/beacon_detection_service.dart';
import 'package:speleoloc/services/beacon/beacon_enabled_notice.dart';
import 'package:speleoloc/services/beacon/beacon_match_engine.dart';
import 'package:speleoloc/services/service_locator.dart';

void main() {
  group('in a build with beacons hidden', () {
    late int configReads;
    late BeaconDetectionService detection;

    setUp(() {
      configReads = 0;
      detection = BeaconDetectionService.forTesting(
        featureEnabled: false,
        // An archive or an earlier install left detection on, with
        // background scanning.
        loadConfig: () async {
          configReads++;
          return const BeaconDetectionConfig(
            enabled: true,
            backgroundEnabled: true,
          );
        },
      );
    });

    tearDown(() => detection.stop());

    test('start never begins', () async {
      await detection.start();

      expect(configReads, 0);
      expect(detection.isRunning, isFalse);
    });

    test('coming back to the app does not start detection', () async {
      detection.onLifecycle(AppLifecycleState.paused);
      detection.onLifecycle(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(configReads, 0);
      expect(detection.isRunning, isFalse);
    });

    test('a database swap does not start detection', () async {
      final previous = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(previous.close);
      appDatabase = previous;
      final restored = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(restored.close);

      replaceAppDatabase(restored);
      await pumpEventQueue();

      expect(configReads, 0);
      expect(detection.isRunning, isFalse);
    });
  });

  group('notice after switching detection on', () {
    BeaconEnabledNotice notice({
      bool running = true,
      bool background = false,
      bool android = true,
    }) => BeaconDetectionService.enabledNoticeFor(
      running: running,
      backgroundEnabled: background,
      backgroundSupported: android,
    );

    test('says detection stops when the screen locks, and how to keep it '
        'going', () {
      expect(notice(), BeaconEnabledNotice.stopsWhenLockedUnlessBackground);
    });

    test('says it stops when locked where there is no background mode', () {
      expect(notice(android: false), BeaconEnabledNotice.stopsWhenLocked);
      expect(
        notice(android: false, background: true),
        BeaconEnabledNotice.stopsWhenLocked,
      );
    });

    test('says nothing when background mode keeps it going', () {
      expect(notice(background: true), BeaconEnabledNotice.none);
    });

    test('warns when detection could not start', () {
      expect(notice(running: false), BeaconEnabledNotice.notRunning);
    });
  });

  test('a build with beacons reads the switch on start', () async {
    var configReads = 0;
    final detection = BeaconDetectionService.forTesting(
      featureEnabled: true,
      loadConfig: () async {
        configReads++;
        return const BeaconDetectionConfig();
      },
    );
    addTearDown(detection.stop);

    await detection.start();

    expect(configReads, 1);
    expect(detection.enabledListenable.value, isFalse);
    expect(detection.isRunning, isFalse);
  });
}
