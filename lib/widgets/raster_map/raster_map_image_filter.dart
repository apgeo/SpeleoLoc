import 'dart:ui';

// ---------------------------------------------------------------------------
// Raster-map image-filter data model
//
// Describes a composited image-processing configuration that can be applied
// to a raster-map image via [ColorFilter.matrix].  Supports two usage modes:
//
//  • Single preset  – a named mode (grayscale, sepia, invert …) with a single
//                     on/off flag, applied exclusively (other modes cleared).
//  • Custom additive – each flag / value is set independently so multiple
//                     effects stack on top of each other.
//
// When [mode] == [RasterMapFilterMode.custom], all individual flags apply.
// When [mode] is a single preset, only that preset matrix is used.
//
// Persistence: kept in a static map in the editor state; survives the current
// app instance but is NOT written to disk / DB.
// ---------------------------------------------------------------------------

/// Named single-preset image-processing modes.
enum RasterMapFilterMode {
  /// No processing — raw image.
  normal,

  /// Invert all RGB channels: classic dark-map-to-light inversion.
  invert,

  /// Desaturate to luminosity-weighted grayscale.
  grayscale,

  /// Classic warm sepia tone.
  sepia,

  /// Boost contrast sharply and reduce saturation — useful for faint lines.
  highContrast,

  /// Warm orange/red tint (night-vision / dark-adaptation friendly).
  nightRed,

  /// Additive: each individual flag is applied independently (stackable).
  custom,
}

/// Holds all parameters for the image-processing pipeline.
///
/// Immutable; use [copyWith] to produce modified copies.
class RasterMapImageFilter {
  const RasterMapImageFilter({
    this.mode = RasterMapFilterMode.normal,
    // custom additive flags
    this.invertEnabled = false,
    this.grayscaleEnabled = false,
    this.sepiaEnabled = false,
    this.highContrastEnabled = false,
    this.nightRedEnabled = false,
    // adjustable parameters (used in presets AND custom mode)
    this.brightness = 0.0,   // range –1.0 … +1.0
    this.contrast  = 1.0,    // range  0.2 … 3.0
  });

  final RasterMapFilterMode mode;

  // ── Custom additive flags ─────────────────────────────────────────────────
  final bool invertEnabled;
  final bool grayscaleEnabled;
  final bool sepiaEnabled;
  final bool highContrastEnabled;
  final bool nightRedEnabled;

  // ── Adjustable parameters ─────────────────────────────────────────────────
  /// Brightness offset in the range [-1, +1].  0 = no change.
  final double brightness;

  /// Contrast multiplier.  1.0 = no change.  Values > 1 increase contrast.
  final double contrast;

  bool get isNormal =>
      mode == RasterMapFilterMode.normal &&
      brightness == 0.0 &&
      contrast == 1.0;

  RasterMapImageFilter copyWith({
    RasterMapFilterMode? mode,
    bool? invertEnabled,
    bool? grayscaleEnabled,
    bool? sepiaEnabled,
    bool? highContrastEnabled,
    bool? nightRedEnabled,
    double? brightness,
    double? contrast,
  }) =>
      RasterMapImageFilter(
        mode: mode ?? this.mode,
        invertEnabled: invertEnabled ?? this.invertEnabled,
        grayscaleEnabled: grayscaleEnabled ?? this.grayscaleEnabled,
        sepiaEnabled: sepiaEnabled ?? this.sepiaEnabled,
        highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
        nightRedEnabled: nightRedEnabled ?? this.nightRedEnabled,
        brightness: brightness ?? this.brightness,
        contrast: contrast ?? this.contrast,
      );

  /// Returns [null] when no filter should be applied (normal mode, no
  /// brightness/contrast adjustments), allowing the caller to skip wrapping
  /// the child in a [ColorFiltered] widget entirely.
  ColorFilter? toColorFilter() {
    if (isNormal) return null;

    // Build the 5×4 RGBA colour matrix for all enabled effects.
    //
    // We represent the pipeline as a composition of matrix multiplications:
    //   output = M_last × … × M_first × input
    //
    // Each step is a 5×5 augmented matrix (homogeneous); we multiply them
    // together then drop the last row to produce the final 4×5 matrix
    // expected by ColorFilter.matrix.

    List<double> compose(List<double> a, List<double> b) {
      // 4-row × 5-column matrix multiply (a is applied AFTER b).
      // Stored row-major: [r0c0, r0c1, … r0c4, r1c0, …].
      final out = List<double>.filled(20, 0);
      for (var r = 0; r < 4; r++) {
        for (var c = 0; c < 5; c++) {
          double v = 0;
          for (var k = 0; k < 4; k++) {
            v += a[r * 5 + k] * b[k * 5 + c];
          }
          // implicit last row of b: [0,0,0,0,1] for the const column
          if (c == 4) v += a[r * 5 + 4];
          out[r * 5 + c] = v;
        }
      }
      return out;
    }

    // Identity matrix
    List<double> m = [
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ];

    // ── Helper matrices ───────────────────────────────────────────────────────

    List<double> invertMatrix() => [
      -1,  0,  0, 0, 255,
       0, -1,  0, 0, 255,
       0,  0, -1, 0, 255,
       0,  0,  0, 1,   0,
    ];

    List<double> grayscaleMatrix() => const [
      // Rec. 709 luminance weights per channel
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0,      0,      0,      1, 0,
    ];

    List<double> sepiaMatrix() => const [
      0.393, 0.769, 0.189, 0, 0,
      0.349, 0.686, 0.168, 0, 0,
      0.272, 0.534, 0.131, 0, 0,
      0,     0,     0,     1, 0,
    ];

    // High contrast: multiply channels by 2 and offset so mid-grey stays grey.
    List<double> highContrastMatrix() => [
       2, 0, 0, 0, -128 / 255 * 255,  // equivalent to offset -0.5 in 0-255 range
       0, 2, 0, 0, -128 / 255 * 255,
       0, 0, 2, 0, -128 / 255 * 255,
       0, 0, 0, 1, 0,
    ];

    // Night-red: remove green and blue channels entirely.
    List<double> nightRedMatrix() => const [
      1, 0, 0, 0, 0,
      0, 0, 0, 0, 0,
      0, 0, 0, 0, 0,
      0, 0, 0, 1, 0,
    ];

    List<double> brightnessContrastMatrix(double b, double c) {
      // Contrast pivots around mid-grey (128/255 ≈ 0.502):
      //   out = c * in + (b + (1 - c) * 0.502) * 255
      final offset = (b + (1.0 - c) * 0.502) * 255;
      return [
        c, 0, 0, 0, offset,
        0, c, 0, 0, offset,
        0, 0, c, 0, offset,
        0, 0, 0, 1, 0,
      ];
    }

    // ── Apply chain ───────────────────────────────────────────────────────────

    switch (mode) {
      case RasterMapFilterMode.normal:
        // May still have brightness/contrast — handled after the switch.
        break;

      case RasterMapFilterMode.invert:
        m = compose(invertMatrix(), m);

      case RasterMapFilterMode.grayscale:
        m = compose(grayscaleMatrix(), m);

      case RasterMapFilterMode.sepia:
        m = compose(sepiaMatrix(), m);

      case RasterMapFilterMode.highContrast:
        m = compose(highContrastMatrix(), m);

      case RasterMapFilterMode.nightRed:
        m = compose(nightRedMatrix(), m);

      case RasterMapFilterMode.custom:
        // Apply each enabled flag in a deterministic order.
        if (grayscaleEnabled) m = compose(grayscaleMatrix(), m);
        if (sepiaEnabled)     m = compose(sepiaMatrix(), m);
        if (highContrastEnabled) m = compose(highContrastMatrix(), m);
        if (nightRedEnabled)  m = compose(nightRedMatrix(), m);
        if (invertEnabled)    m = compose(invertMatrix(), m);
    }

    // Always apply brightness/contrast as the final step when non-identity.
    if (brightness != 0.0 || contrast != 1.0) {
      m = compose(brightnessContrastMatrix(brightness, contrast), m);
    }

    return ColorFilter.matrix(m);
  }

  /// Preset filter for the given [mode] (brightness/contrast not pre-set).
  static RasterMapImageFilter preset(RasterMapFilterMode mode) =>
      RasterMapImageFilter(mode: mode);

  static const RasterMapImageFilter normal =
      RasterMapImageFilter(mode: RasterMapFilterMode.normal);
}
