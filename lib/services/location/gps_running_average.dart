import 'package:geolocator/geolocator.dart';

/// Running arithmetic mean over a stream of GPS fixes: latitude and
/// longitude over every sample, altitude over the samples that report
/// one, plus the best (smallest) reported accuracy. Averaging a
/// stationary stream converges considerably tighter than any single fix,
/// which is why both the GPS recorder and the map placement flow capture
/// points through this instead of one-shot fixes.
class GpsRunningAverage {
  int _samples = 0;
  double _sumLatitude = 0;
  double _sumLongitude = 0;
  double _sumAltitude = 0;
  int _altitudeSamples = 0;
  double _bestAccuracy = double.infinity;
  Position? _last;

  void add(Position position) {
    _samples += 1;
    _sumLatitude += position.latitude;
    _sumLongitude += position.longitude;
    if (!position.altitude.isNaN) {
      _altitudeSamples += 1;
      _sumAltitude += position.altitude;
    }
    if (position.accuracy > 0 && position.accuracy < _bestAccuracy) {
      _bestAccuracy = position.accuracy;
    }
    _last = position;
  }

  int get sampleCount => _samples;

  double? get latitude => _samples == 0 ? null : _sumLatitude / _samples;

  double? get longitude => _samples == 0 ? null : _sumLongitude / _samples;

  double? get altitude =>
      _altitudeSamples == 0 ? null : _sumAltitude / _altitudeSamples;

  /// Best accuracy seen so far, falling back to the last fix's value when
  /// no sample reported a positive accuracy.
  double? get accuracyMeters =>
      _bestAccuracy.isFinite ? _bestAccuracy : _last?.accuracy;

  Position? get lastPosition => _last;
}
