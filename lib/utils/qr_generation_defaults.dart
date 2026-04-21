/// Default values for QR code generation preferences.
///
/// Extracted from `cave_place_qr_generator.dart` and
/// `cave_place_qr_preview_dialog.dart` so preview and generator agree on
/// fallbacks when user config is absent (Phase 4.2 of refactoring roadmap).
class QrGenerationDefaults {
  const QrGenerationDefaults._();

  /// Default QR module size in pixels (square).
  static const int qrSizePx = 400;

  /// Default padding (pixels) around each generated QR image.
  static const int imagePaddingPx = 24;

  /// Default label font size (pixels for images / pt for PDF).
  static const double labelFontSize = 18.0;

  /// Default background color (ARGB int): opaque white.
  static const int backgroundColor = 0xFFFFFFFF;

  /// Default QR background color (ARGB int): opaque white.
  static const int qrBgColor = 0xFFFFFFFF;

  /// Default QR foreground (module) color (ARGB int): opaque black.
  static const int qrFgColor = 0xFF000000;

  /// Default DPI hint (used for future PDF scaling).
  static const int dpi = 300;

  /// Default error-correction level ('L','M','Q','H').
  static const String errorCorrectionLevel = 'M';

  /// Default image format hint.
  static const String imageFormat = 'png';

  /// Default PDF grid column count.
  static const int pdfGridColumns = 4;

  /// Default PDF grid row count.
  static const int pdfGridRows = 5;

  /// Default PDF cell padding (pt) — horizontal.
  static const double pdfQrPaddingH = 18.0;

  /// Default PDF cell padding (pt) — vertical.
  static const double pdfQrPaddingV = 18.0;

  /// Label font family used in generated PDFs.
  static const String labelFontFamily = 'Helvetica';
}
