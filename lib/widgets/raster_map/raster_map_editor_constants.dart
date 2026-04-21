/// Typed constants for the raster map place point editor.
///
/// Extracted from `raster_map_place_point_editor.dart` and
/// `raster_map_place_selector.dart` per Phase 4.2 of the refactoring roadmap.
/// Centralising these values makes the editor's tunable behaviour discoverable
/// in one place and avoids magic-number duplication across widgets.
class RasterMapEditorConstants {
  const RasterMapEditorConstants._();

  // --- Trip overlay defaults ------------------------------------------------

  /// Default line/arrow width for the trip route overlay.
  static const double defaultRouteLineWidth = 2.5;

  /// Default font size for incremental trip numbering labels.
  static const double defaultTripNumberFontSize = 12.0;

  // --- Marker label rendering ----------------------------------------------

  /// Default stroke width for outlined marker label text.
  static const double defaultTextOutlineWidth = 2.0;

  // --- Zoom defaults --------------------------------------------------------

  /// Default initial zoom level (1.0 = image contained in viewport).
  static const double defaultInitialZoomLevel = 1.0;

  /// Default target zoom level used when focusing on a single point.
  static const double defaultZoomToPointLevel = 2.5;

  /// Default padding (in image-space pixels) applied around a set of points
  /// when fitting them within the viewport.
  static const double defaultZoomToFitPadding = 40.0;

  /// Viewport-space hit-test radius (pixels) for marker tap detection.
  static const double markerHitThreshold = 30.0;

  // --- Animation durations --------------------------------------------------

  /// Duration of the selected-marker pulse animation.
  static const Duration pulseAnimationDuration = Duration(milliseconds: 420);

  /// Duration of the animated pan/zoom transition between points.
  static const Duration panZoomAnimationDuration = Duration(milliseconds: 220);

  // --- Snackbar durations ---------------------------------------------------

  /// Default duration of short status snackbars (e.g. auto-save toast).
  static const Duration shortSnackbarDuration = Duration(seconds: 1);

  /// Medium-length snackbar duration (e.g. informational prompts).
  static const Duration mediumSnackbarDuration = Duration(seconds: 2);

  /// Long snackbar duration (e.g. warnings the user should notice).
  static const Duration longSnackbarDuration = Duration(seconds: 3);
}
