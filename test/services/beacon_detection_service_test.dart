import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/beacon/beacon_detection_host.dart';
import 'package:speleoloc/services/beacon/beacon_detection_service.dart';
import 'package:speleoloc/services/beacon/beacon_enabled_notice.dart';
import 'package:speleoloc/services/beacon/beacon_match_engine.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/services/trip_record_outcome.dart';

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

    test('restarting after a settings save does not start detection', () async {
      await detection.restart();

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

  group('switching detection on tells the caver through the attached host', () {
    late AppDatabase db;
    late _RecordingHost host;

    void beaconPlatform(Future<Object?> Function(MethodCall call) handler) =>
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('flutter_beacon'),
              handler,
            );

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      db = AppDatabase.forTesting(NativeDatabase.memory());
      appDatabase = db;
      host = _RecordingHost();
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('flutter_beacon'),
            null,
          );
      await db.close();
    });

    BeaconDetectionService detection() {
      final service = BeaconDetectionService.forTesting(
        featureEnabled: true,
        // Detection then never gets as far as scanning in a test.
        loadConfig: () async => const BeaconDetectionConfig(),
        host: host,
      );
      addTearDown(service.stop);
      return service;
    }

    test('a platform that refuses to scan is reported with its own '
        'message', () async {
      beaconPlatform((call) async {
        if (call.method == 'initializeAndCheck') {
          throw PlatformException(code: 'denied', message: 'invented refusal');
        }
        return true;
      });

      expect(await detection().setEnabled(true), isFalse);

      expect(host.calls, ['scanningRefused: invented refusal']);
    });

    test('the notice after switching on is handed to the host', () async {
      beaconPlatform((call) async => true);

      expect(await detection().setEnabled(true), isTrue);

      expect(host.calls, ['switchedOn: ${BeaconEnabledNotice.notRunning}']);
    });

    test('switching off says nothing', () async {
      expect(await detection().setEnabled(false), isTrue);

      expect(host.calls, isEmpty);
    });
  });
}

class _RecordingHost implements BeaconDetectionHost {
  final calls = <String>[];

  @override
  void permissionsMissing() => calls.add('permissionsMissing');

  @override
  void scanningRefused(String reason) => calls.add('scanningRefused: $reason');

  @override
  void switchedOn(BeaconEnabledNotice notice) =>
      calls.add('switchedOn: $notice');

  @override
  void placeDetected(CavePlace place, TripRecordOutcome? tripOutcome) =>
      calls.add('placeDetected: ${place.title} $tripOutcome');

  @override
  Future<void> openPlace(CavePlace place) async =>
      calls.add('openPlace: ${place.title}');
}
