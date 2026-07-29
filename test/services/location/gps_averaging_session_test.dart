import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speleoloc/services/location/gps_averaging_session.dart';
import 'package:speleoloc/services/location/gps_quality.dart';
import 'package:speleoloc/services/location/location_service.dart';

Position _fix({
  required double lat,
  required double lng,
  double accuracy = 8,
  double altitude = 100,
}) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    accuracy: accuracy,
    altitude: altitude,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

/// Fake device location under full test control.
class _FakeLocationService implements LocationService {
  LocationReadiness readiness = LocationReadiness.ready;
  final StreamController<Position> controller =
      StreamController<Position>.broadcast();
  int streamRequests = 0;
  int openLocationSettingsCalls = 0;
  int openAppSettingsCalls = 0;

  @override
  Future<LocationReadiness> ensureReady() async => readiness;

  @override
  Future<Position?> currentPosition({
    LocationAccuracy accuracy = LocationAccuracy.best,
  }) async => null;

  @override
  Stream<Position> positionStream({
    LocationAccuracy accuracy = LocationAccuracy.bestForNavigation,
    int distanceFilterMeters = 0,
  }) {
    streamRequests++;
    return controller.stream;
  }

  @override
  Future<void> openLocationSettings() async => openLocationSettingsCalls++;

  @override
  Future<void> openAppSettings() async => openAppSettingsCalls++;
}

void main() {
  late _FakeLocationService location;
  late GpsAveragingSession session;

  setUp(() {
    location = _FakeLocationService();
    session = GpsAveragingSession(location);
  });

  tearDown(() async {
    session.dispose();
    await location.controller.close();
  });

  /// Pushes [positions] through the fake stream and lets the session's
  /// listener run for each.
  Future<void> emit(List<Position> positions) async {
    for (final p in positions) {
      location.controller.add(p);
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('start', () {
    test('is idle before starting', () {
      expect(session.status, GpsAveragingStatus.idle);
      expect(session.isRunning, isFalse);
      expect(session.hasFix, isFalse);
      expect(session.sampleCount, 0);
      expect(session.latitude, isNull);
    });

    test('waits for a fix once started', () async {
      final started = await session.start();
      expect(started, isTrue);
      expect(session.isRunning, isTrue);
      expect(session.status, GpsAveragingStatus.waitingForFix);
      expect(session.hasFix, isFalse);
    });

    test('reports serviceDisabled without subscribing', () async {
      location.readiness = LocationReadiness.serviceDisabled;
      final started = await session.start();
      expect(started, isFalse);
      expect(session.status, GpsAveragingStatus.serviceDisabled);
      expect(session.isRunning, isFalse);
      expect(location.streamRequests, 0);
    });

    test('reports permissionDenied without subscribing', () async {
      location.readiness = LocationReadiness.permissionDenied;
      expect(await session.start(), isFalse);
      expect(session.status, GpsAveragingStatus.permissionDenied);
      expect(location.streamRequests, 0);
    });

    test('maps permissionDeniedForever onto permissionDenied', () async {
      location.readiness = LocationReadiness.permissionDeniedForever;
      expect(await session.start(), isFalse);
      expect(session.status, GpsAveragingStatus.permissionDenied);
    });

    test('a second start does not open a second stream', () async {
      await session.start();
      await session.start();
      expect(location.streamRequests, 1);
    });
  });

  group('averaging', () {
    test('averages latitude and longitude over the samples', () async {
      await session.start();
      await emit([
        _fix(lat: 10.0, lng: 20.0),
        _fix(lat: 10.2, lng: 20.4),
      ]);

      expect(session.status, GpsAveragingStatus.averaging);
      expect(session.sampleCount, 2);
      expect(session.latitude, closeTo(10.1, 1e-9));
      expect(session.longitude, closeTo(20.2, 1e-9));
      expect(session.hasFix, isTrue);
    });

    test('keeps the best (smallest) accuracy, not the last', () async {
      await session.start();
      await emit([
        _fix(lat: 1, lng: 1, accuracy: 12),
        _fix(lat: 1, lng: 1, accuracy: 4),
        _fix(lat: 1, lng: 1, accuracy: 30),
      ]);

      expect(session.accuracyMeters, 4);
      expect(session.quality.labelKey, 'gps_quality_excellent');
    });

    test('notifies listeners once per sample', () async {
      var notifications = 0;
      session.addListener(() => notifications++);
      await session.start(); // one notification for waitingForFix
      final afterStart = notifications;

      await emit([_fix(lat: 1, lng: 1), _fix(lat: 2, lng: 2)]);
      expect(notifications - afterStart, 2);
    });

    test('averages altitude only over samples that report one', () async {
      await session.start();
      await emit([
        _fix(lat: 1, lng: 1, altitude: 100),
        _fix(lat: 1, lng: 1, altitude: double.nan),
        _fix(lat: 1, lng: 1, altitude: 200),
      ]);

      expect(session.sampleCount, 3);
      expect(session.altitude, closeTo(150, 1e-9));
    });

    test('surfaces a stream error', () async {
      await session.start();
      location.controller.addError(StateError('gps blew up'));
      await Future<void>.delayed(Duration.zero);

      expect(session.status, GpsAveragingStatus.error);
      expect(session.errorMessage, contains('gps blew up'));
    });
  });

  group('stop / reset / restart', () {
    test('stop keeps the mean and marks the session stopped', () async {
      await session.start();
      await emit([_fix(lat: 10, lng: 20), _fix(lat: 10.2, lng: 20.4)]);
      await session.stop();

      expect(session.isRunning, isFalse);
      expect(session.status, GpsAveragingStatus.stopped);
      expect(session.sampleCount, 2);
      expect(session.latitude, closeTo(10.1, 1e-9));
    });

    test('stop before any fix returns to idle', () async {
      await session.start();
      await session.stop();
      expect(session.status, GpsAveragingStatus.idle);
      expect(session.hasFix, isFalse);
    });

    test('stop ignores further fixes', () async {
      await session.start();
      await emit([_fix(lat: 10, lng: 20)]);
      await session.stop();
      await emit([_fix(lat: 90, lng: 90)]);

      expect(session.sampleCount, 1);
      expect(session.latitude, closeTo(10, 1e-9));
    });

    test('restarting discards the previous mean', () async {
      await session.start();
      await emit([_fix(lat: 10, lng: 10)]);
      await session.stop();

      await session.start();
      expect(session.sampleCount, 0);
      expect(session.latitude, isNull);

      await emit([_fix(lat: 40, lng: 40)]);
      expect(session.latitude, closeTo(40, 1e-9));
    });

    test('reset clears the mean and returns to idle', () async {
      await session.start();
      await emit([_fix(lat: 10, lng: 20)]);
      await session.reset();

      expect(session.status, GpsAveragingStatus.idle);
      expect(session.sampleCount, 0);
      expect(session.latitude, isNull);
      expect(session.errorMessage, isNull);
    });

    test('a fix arriving after dispose does not notify', () async {
      await session.start();
      var notifiedAfterDispose = false;
      session.addListener(() => notifiedAfterDispose = true);
      session.dispose();

      location.controller.add(_fix(lat: 1, lng: 1));
      await Future<void>.delayed(Duration.zero);
      expect(notifiedAfterDispose, isFalse);

      // tearDown disposes again; make that a no-op rather than a crash.
      session = GpsAveragingSession(location);
    });
  });

  group('GpsQuality', () {
    test('rates by accuracy bands', () {
      expect(GpsQuality.fromAccuracy(3).labelKey, 'gps_quality_excellent');
      expect(GpsQuality.fromAccuracy(5).labelKey, 'gps_quality_excellent');
      expect(GpsQuality.fromAccuracy(8).labelKey, 'gps_quality_good');
      expect(GpsQuality.fromAccuracy(15).labelKey, 'gps_quality_fair');
      expect(GpsQuality.fromAccuracy(40).labelKey, 'gps_quality_poor');
      expect(GpsQuality.fromAccuracy(80).labelKey, 'gps_quality_very_poor');
    });

    test('treats null, zero, negative and NaN as unknown', () {
      for (final a in <double?>[null, 0, -1, double.nan]) {
        final q = GpsQuality.fromAccuracy(a);
        expect(q.labelKey, 'gps_quality_unknown');
        expect(q.score, 0.0);
      }
    });

    test('score decreases as accuracy worsens', () {
      final scores = [3.0, 8.0, 15.0, 40.0, 80.0]
          .map((a) => GpsQuality.fromAccuracy(a).score)
          .toList();
      for (var i = 1; i < scores.length; i++) {
        expect(scores[i], lessThan(scores[i - 1]));
      }
    });
  });
}
