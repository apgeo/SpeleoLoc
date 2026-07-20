import 'package:geolocator/geolocator.dart';

/// Whether the device can currently provide a location, and if not, why.
/// Maps the geolocator permission/service checks onto a small set the UI
/// can act on (prompt, open location settings, open app settings).
enum LocationReadiness {
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

/// Generic device-location access, wrapping `geolocator`.
///
/// This is the reusable GPS primitive; the surface map builds its specific
/// use cases on top (show my position, use my position as a point). Kept as
/// an injectable instance (not static calls) so it can be faked in tests.
abstract class LocationService {
  /// Ensures location services are on and permission is granted, requesting
  /// permission once if it has not yet been decided.
  Future<LocationReadiness> ensureReady();

  /// A single current fix. Returns null if a fix cannot be obtained.
  Future<Position?> currentPosition({
    LocationAccuracy accuracy = LocationAccuracy.best,
  });

  /// A continuous stream of positions. Callers are responsible for
  /// cancelling their subscription.
  Stream<Position> positionStream({
    LocationAccuracy accuracy = LocationAccuracy.bestForNavigation,
    int distanceFilterMeters = 0,
  });

  /// Opens the OS location-services settings (for [serviceDisabled]).
  Future<void> openLocationSettings();

  /// Opens this app's settings page (for [permissionDeniedForever]).
  Future<void> openAppSettings();
}

/// [LocationService] backed by the `geolocator` plugin.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationReadiness> ensureReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationReadiness.serviceDisabled;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.denied:
        return LocationReadiness.permissionDenied;
      case LocationPermission.deniedForever:
        return LocationReadiness.permissionDeniedForever;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationReadiness.ready;
      case LocationPermission.unableToDetermine:
        return LocationReadiness.permissionDenied;
    }
  }

  @override
  Future<Position?> currentPosition({
    LocationAccuracy accuracy = LocationAccuracy.best,
  }) async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: accuracy),
      );
    } catch (_) {
      // Fall back to the last known fix rather than failing outright.
      return Geolocator.getLastKnownPosition();
    }
  }

  @override
  Stream<Position> positionStream({
    LocationAccuracy accuracy = LocationAccuracy.bestForNavigation,
    int distanceFilterMeters = 0,
  }) => Geolocator.getPositionStream(
    locationSettings: LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilterMeters,
    ),
  );

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();
}
