import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speleoloc/services/location/gps_quality.dart';
import 'package:speleoloc/services/location/gps_running_average.dart';
import 'package:speleoloc/services/location/location_service.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// State of a [GpsAveragingSession].
enum GpsAveragingStatus {
  /// Not started (or stopped before any fix arrived).
  idle,

  /// Started and waiting for the first fix.
  waitingForFix,

  /// Streaming fixes into the running mean.
  averaging,

  /// Stopped, keeping the mean accumulated so far.
  stopped,

  /// Location services are switched off on the device.
  serviceDisabled,

  /// Location permission was denied.
  permissionDenied,

  /// The position stream failed; see [errorMessage].
  error,
}

/// A precision point-recording session: streams GPS fixes and folds them
/// into a [GpsRunningAverage], so a stationary capture converges far tighter
/// than any single fix.
///
/// This is the reusable core of the GPS-precision feature, shared by the
/// standalone recorder screen and the map's point placement flow. It owns the
/// readiness check, the subscription and the mean, and notifies listeners on
/// every sample and state change; presentation (cards, bars, pins) is left
/// entirely to the caller.
class GpsAveragingSession extends ChangeNotifier {
  GpsAveragingSession(this._location);

  final LocationService _location;
  final _log = AppLogger.of('GpsAveragingSession');

  StreamSubscription<Position>? _sub;
  GpsRunningAverage _average = GpsRunningAverage();
  GpsAveragingStatus _status = GpsAveragingStatus.idle;
  String? _errorMessage;
  bool _disposed = false;

  GpsAveragingStatus get status => _status;
  String? get errorMessage => _errorMessage;

  /// Whether fixes are currently being collected.
  bool get isRunning => _sub != null;

  int get sampleCount => _average.sampleCount;

  /// Whether at least one fix has been folded into the mean.
  bool get hasFix => _average.sampleCount > 0;

  double? get latitude => _average.latitude;
  double? get longitude => _average.longitude;
  double? get altitude => _average.altitude;
  double? get accuracyMeters => _average.accuracyMeters;
  Position? get lastPosition => _average.lastPosition;

  /// Rating of the best accuracy seen so far, for a quality indicator.
  GpsQuality get quality => GpsQuality.fromAccuracy(_average.accuracyMeters);

  /// Checks readiness, then starts folding fixes into a **fresh** mean.
  ///
  /// Restarting discards the previous mean so two separate captures never
  /// blend. Returns `true` when the stream was started; on a readiness
  /// failure it returns `false` and reports the reason through [status].
  Future<bool> start() async {
    if (isRunning) return true;
    _errorMessage = null;
    _average = GpsRunningAverage();

    try {
      final readiness = await _location.ensureReady();
      if (_disposed) return false;
      switch (readiness) {
        case LocationReadiness.serviceDisabled:
          _setStatus(GpsAveragingStatus.serviceDisabled);
          return false;
        case LocationReadiness.permissionDenied:
        case LocationReadiness.permissionDeniedForever:
          _setStatus(GpsAveragingStatus.permissionDenied);
          return false;
        case LocationReadiness.ready:
          break;
      }

      // Unfiltered stream on purpose: a distance filter would starve a
      // stationary averaging session of the very samples it averages.
      _sub = _location.positionStream().listen(
        _onPosition,
        onError: (Object e, StackTrace st) {
          _log.warning('Position stream error', e, st);
          if (_disposed) return;
          _errorMessage = e.toString();
          _setStatus(GpsAveragingStatus.error);
        },
      );
      _setStatus(GpsAveragingStatus.waitingForFix);
      return true;
    } catch (e, st) {
      _log.warning('Failed to start GPS averaging', e, st);
      if (_disposed) return false;
      _errorMessage = e.toString();
      _setStatus(GpsAveragingStatus.error);
      return false;
    }
  }

  /// Stops collecting fixes but keeps the mean accumulated so far.
  Future<void> stop() async {
    if (_sub == null) return;
    final sub = _sub;
    _sub = null;
    await sub?.cancel();
    if (_disposed) return;
    _setStatus(
      hasFix ? GpsAveragingStatus.stopped : GpsAveragingStatus.idle,
    );
  }

  /// Stops and clears the mean, returning to [GpsAveragingStatus.idle].
  Future<void> reset() async {
    await stop();
    if (_disposed) return;
    _average = GpsRunningAverage();
    _errorMessage = null;
    _setStatus(GpsAveragingStatus.idle);
  }

  void _onPosition(Position position) {
    if (_disposed) return;
    _average.add(position);
    _status = GpsAveragingStatus.averaging;
    notifyListeners();
  }

  void _setStatus(GpsAveragingStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_sub?.cancel());
    _sub = null;
    super.dispose();
  }
}
