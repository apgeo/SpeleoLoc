/// Qualitative rating of a GPS fix derived from its reported accuracy.
///
/// Carries a localization *key* rather than a localized string so the pure
/// location layer stays free of UI/localization concerns; callers resolve
/// [labelKey] through `LocServ`.
class GpsQuality {
  const GpsQuality(this.score, this.labelKey);

  /// 0..1, suitable for driving a progress/quality bar.
  final double score;

  /// i18n key of the human-readable label (e.g. `gps_quality_good`).
  final String labelKey;

  /// Rates a fix by its accuracy in meters (smaller is better). A null,
  /// zero/negative or NaN accuracy means the device reported nothing usable.
  ///
  /// Shared by the GPS recorder and the map placement readout so the same
  /// accuracy never shows two different ratings.
  factory GpsQuality.fromAccuracy(double? accuracyMeters) {
    final a = accuracyMeters;
    if (a == null || a <= 0 || a.isNaN) {
      return const GpsQuality(0.0, 'gps_quality_unknown');
    }
    if (a <= 5) return const GpsQuality(1.0, 'gps_quality_excellent');
    if (a <= 10) return const GpsQuality(0.8, 'gps_quality_good');
    if (a <= 20) return const GpsQuality(0.6, 'gps_quality_fair');
    if (a <= 50) return const GpsQuality(0.35, 'gps_quality_poor');
    return const GpsQuality(0.1, 'gps_quality_very_poor');
  }
}
