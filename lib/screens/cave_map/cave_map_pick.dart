/// Request to open the surface map as a coordinate picker for one cave
/// place (from the cave-place form). When [initialLatitude]/[initialLongitude]
/// are set the picker starts on the current position; otherwise the first
/// tap defines it.
class CaveMapPickRequest {
  final String placeTitle;
  final String caveTitle;
  final double? initialLatitude;
  final double? initialLongitude;

  const CaveMapPickRequest({
    required this.placeTitle,
    required this.caveTitle,
    this.initialLatitude,
    this.initialLongitude,
  });

  bool get hasInitialPosition =>
      initialLatitude != null && initialLongitude != null;
}

/// Coordinates confirmed in pick mode, returned via `Navigator.pop`.
class CaveMapPickResult {
  final double latitude;
  final double longitude;

  const CaveMapPickResult({required this.latitude, required this.longitude});
}
