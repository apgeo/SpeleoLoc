import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:barcode/barcode.dart' show BarcodeQRCorrectionLevel;

import 'package:speleo_loc/data/source/database/app_database.dart';
import 'package:speleo_loc/utils/qr_label_template_engine.dart';

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

/// All user-configurable QR generation settings.
class GenerationPreferences {
  /// Output kind: true -> PDF, false -> images.
  final bool asPdf;

  /// Include place title as label below the QR code.
  final bool includeTitle;

  /// DPI hint (future use / PDF scaling).
  final int dpi;

  /// Background color (ARGB int).
  final int backgroundColor;

  /// Image format hint: "png".
  final String imageFormat;

  /// QR module size in pixels (width = height of the QR square).
  final int qrSizePx;

  /// Padding around each individual QR image (pixels).
  final int imagePaddingPx;

  /// Label font size (pixels for images, pt for PDF).
  final double labelFontSize;

  /// Label font family (used in PDF only).
  final String labelFontFamily;

  /// QR background color (ARGB int).
  final int qrBgColor;

  /// QR foreground (module) color (ARGB int).
  final int qrFgColor;

  /// Pack all generated images into a single ZIP archive.
  final bool exportImagesAsZip;

  /// QR error correction level: 'L','M','Q','H'.
  final String qrErrorCorrectionLevel;

  /// Number of QR code columns per PDF page.
  final int pdfGridColumns;

  /// Number of QR code rows per PDF page.
  final int pdfGridRows;

  /// Label template string with @variables and optional #fz/#fc formatting.
  final String labelTemplate;

  /// Horizontal padding around each QR cell in the PDF grid (pt).
  final double pdfQrPaddingH;

  /// Vertical padding around each QR cell in the PDF grid (pt).
  final double pdfQrPaddingV;

  /// Cave title for template resolution.
  final String? caveTitle;

  /// Area title for template resolution.
  final String? areaTitle;

  const GenerationPreferences({
    this.asPdf = true,
    this.includeTitle = true,
    this.dpi = 300,
    this.backgroundColor = 0xFFFFFFFF,
    this.imageFormat = 'png',
    this.qrSizePx = 400,
    this.imagePaddingPx = 24,
    this.labelFontSize = 18.0,
    this.labelFontFamily = 'Helvetica',
    this.qrBgColor = 0xFFFFFFFF,
    this.qrFgColor = 0xFF000000,
    this.exportImagesAsZip = true,
    this.qrErrorCorrectionLevel = 'M',
    this.pdfGridColumns = 4,
    this.pdfGridRows = 5,
    this.labelTemplate = '@place_title, @depth',
    this.pdfQrPaddingH = 2.0,
    this.pdfQrPaddingV = 2.0,
    this.caveTitle,
    this.areaTitle,
  });
}

/// A single generated output file (image or PDF), stored in memory.
class GeneratedFile {
  final String name;
  final Uint8List bytes;
  final String mimeType;

  GeneratedFile({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });
}

/// Container for the full generation output: individual files plus an
/// optional ZIP archive containing all of them.
class GenerationResult {
  final List<GeneratedFile> files;
  final Uint8List? zipBytes;

  GenerationResult({required this.files, this.zipBytes});
}

// ---------------------------------------------------------------------------
// QR Image Renderer (helper module)
// ---------------------------------------------------------------------------

/// Renders a single cave-place QR code to a PNG [Uint8List].
///
/// Layout (top to bottom, centered):
///   padding
///   QR code (qrSizePx x qrSizePx)
///   gap (12 px)
///   Title text (if includeTitle, font size from prefs)
///   padding
///
/// The final image width = qrSizePx + 2 * imagePaddingPx.
/// The height is computed dynamically based on whether a title is included.
class QrImageRenderer {
  /// Render a single QR code image for [place] using [prefs].
  static Future<Uint8List> render(
    CavePlace place,
    GenerationPreferences prefs,
  ) async {
    final data = _qrDataForPlace(place);
    final qrSize = prefs.qrSizePx.toDouble();
    final padding = prefs.imagePaddingPx.toDouble();

    final ecLevel = _parseEcLevel(prefs.qrErrorCorrectionLevel);

    final qrPainter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      dataModuleStyle: QrDataModuleStyle(
        color: ui.Color(prefs.qrFgColor),
      ),
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: ui.Color(prefs.qrFgColor),
      ),
      errorCorrectionLevel: ecLevel,
    );

    // Measure title text (if any)
    TextPainter? titlePainter;
    if (prefs.includeTitle && place.title.isNotEmpty) {
      titlePainter = TextPainter(
        text: TextSpan(
          text: place.title,
          style: TextStyle(
            color: const Color(0xFF000000),
            fontSize: prefs.labelFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      titlePainter.layout(maxWidth: qrSize);
    }

    final titleGap = titlePainter != null ? 12.0 : 0.0;
    final titleHeight = titlePainter?.height ?? 0.0;

    final imgWidth = qrSize + 2 * padding;
    final imgHeight = padding + qrSize + titleGap + titleHeight + padding;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Background
    final bgPaint = Paint()..color = ui.Color(prefs.backgroundColor);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, imgWidth, imgHeight),
      bgPaint,
    );

    // QR code (drawn inside padded area)
    canvas.save();
    canvas.translate(padding, padding);
    qrPainter.paint(canvas, ui.Size(qrSize, qrSize));
    canvas.restore();

    // Title text
    if (titlePainter != null) {
      final textX = (imgWidth - titlePainter.width) / 2;
      final textY = padding + qrSize + titleGap;
      titlePainter.paint(canvas, Offset(textX, textY));
    }

    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(imgWidth.toInt(), imgHeight.toInt());
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to convert QR image to byte data');
    }
    return Uint8List.view(byteData.buffer);
  }

  static int _parseEcLevel(String level) {
    switch (level.toUpperCase()) {
      case 'L':
        return QrErrorCorrectLevel.L;
      case 'Q':
        return QrErrorCorrectLevel.Q;
      case 'H':
        return QrErrorCorrectLevel.H;
      case 'M':
      default:
        return QrErrorCorrectLevel.M;
    }
  }

  static String _qrDataForPlace(CavePlace place) {
    return '${place.placeQrCodeIdentifier}';
  }
}

// ---------------------------------------------------------------------------
// Main Generator
// ---------------------------------------------------------------------------

/// Generates QR code output for a list of cave places.
///
/// Depending on [GenerationPreferences.asPdf]:
/// - **PDF**: produces a single PDF with one QR per page.
/// - **Images**: produces one PNG per cave place, optionally zipped.
class CavePlaceQRCodePDFGenerator {
  Future<GenerationResult> generate(
    List<CavePlace> places,
    GenerationPreferences prefs, {
    bool returnZip = false,
  }) async {
    if (prefs.asPdf) {
      return _generatePdf(places, prefs);
    } else {
      return _generateImages(places, prefs, returnZip: returnZip);
    }
  }

  // ---- PDF generation ----

  /// Load a TrueType font from bundled assets that supports
  /// Unicode characters (including Romanian diacritics like ț, ș, ă).
  Future<pw.Font> _loadUnicodeFont() async {
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    return pw.Font.ttf(fontData);
  }

  Future<pw.Font> _loadUnicodeFontBold() async {
    try {
      final fontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      return pw.Font.ttf(fontData);
    } catch (_) {
      return _loadUnicodeFont();
    }
  }

  Future<GenerationResult> _generatePdf(
    List<CavePlace> places,
    GenerationPreferences prefs,
  ) async {
    // Load Unicode-capable font for PDF text rendering
    final font = await _loadUnicodeFont();
    final fontBold = await _loadUnicodeFontBold();

    final doc = pw.Document();

    final cols = prefs.pdfGridColumns.clamp(1, 10);
    final rows = prefs.pdfGridRows.clamp(1, 20);
    final perPage = cols * rows;

    // Split places into pages
    for (int pageStart = 0; pageStart < places.length; pageStart += perPage) {
      final pageEnd = (pageStart + perPage).clamp(0, places.length);
      final pagePlaces = places.sublist(pageStart, pageEnd);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(12),
          build: (pw.Context ctx) {
            return pw.Column(
              children: List.generate(rows, (row) {
                return pw.Expanded(
                  child: pw.Row(
                    children: List.generate(cols, (col) {
                      final idx = row * cols + col;
                      if (idx >= pagePlaces.length) {
                        return pw.Expanded(child: pw.SizedBox());
                      }
                      final place = pagePlaces[idx];
                      final data = _qrDataForPlace(place);
                      
                      // Parse segments for potential font size/color overrides
                      final segments = QrLabelTemplateEngine.parseSegments(
                        template: prefs.labelTemplate,
                        place: place,
                        caveTitle: prefs.caveTitle,
                        areaTitle: prefs.areaTitle,
                      );

                      return pw.Expanded(
                        child: pw.Container(
                          padding: pw.EdgeInsets.symmetric(
                            horizontal: prefs.pdfQrPaddingH,
                            vertical: prefs.pdfQrPaddingV,
                          ),
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Expanded(
                                child: pw.BarcodeWidget(
                                  barcode: pw.Barcode.qrCode(
                                    errorCorrectLevel: _pdfEcLevel(
                                      prefs.qrErrorCorrectionLevel,
                                    ),
                                  ),
                                  data: data,
                                  color: PdfColor.fromInt(prefs.qrFgColor),
                                  textStyle: pw.TextStyle(font: font, fontBold: fontBold),
                                ),
                              ),
                              if (prefs.includeTitle) pw.SizedBox(height: 2),
                              if (prefs.includeTitle)
                                pw.RichText(
                                  textAlign: pw.TextAlign.center,
                                  text: pw.TextSpan(
                                    children: segments.map((seg) {
                                      PdfColor? segColor;
                                      if (seg.fontColor != null) {
                                        try {
                                          final colorInt = int.parse('FF${seg.fontColor}', radix: 16);
                                          segColor = PdfColor.fromInt(colorInt);
                                        } catch (_) {}
                                      }
                                      return pw.TextSpan(
                                        text: seg.text,
                                        style: pw.TextStyle(
                                          font: font,
                                          fontBold: fontBold,
                                          fontSize: seg.fontSize ?? (prefs.labelFontSize * 0.5).clamp(6, 14),
                                          fontWeight: pw.FontWeight.bold,
                                          color: segColor,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            );
          },
        ),
      );
    }

    final pdfBytes = await doc.save();
    final files = [
      GeneratedFile(
        name: 'cave_places_qr.pdf',
        bytes: pdfBytes,
        mimeType: 'application/pdf',
      ),
    ];

    return GenerationResult(files: files);
  }

  // ---- Image generation (one QR per image) ----

  Future<GenerationResult> _generateImages(
    List<CavePlace> places,
    GenerationPreferences prefs, {
    bool returnZip = false,
  }) async {
    final files = <GeneratedFile>[];

    for (final place in places) {
      final imgBytes = await QrImageRenderer.render(place, prefs);
      final name = '${_sanitizeFilename(place.title)}.png';
      files.add(GeneratedFile(
        name: name,
        bytes: imgBytes,
        mimeType: 'image/png',
      ));
    }

    // Always create ZIP when requested or when preference says so
    Uint8List? zipBytes;
    if (returnZip || prefs.exportImagesAsZip) {
      zipBytes = _buildZip(files);
    }

    return GenerationResult(files: files, zipBytes: zipBytes);
  }

  // ---- Helpers ----

  Uint8List _buildZip(List<GeneratedFile> files) {
    final archive = Archive();
    for (final f in files) {
      archive.addFile(ArchiveFile(f.name, f.bytes.length, f.bytes));
    }
    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) throw StateError('Failed to encode ZIP archive');
    return Uint8List.fromList(encoded);
  }

  BarcodeQRCorrectionLevel _pdfEcLevel(String level) {
    switch (level.toUpperCase()) {
      case 'L':
        return BarcodeQRCorrectionLevel.low;
      case 'Q':
        return BarcodeQRCorrectionLevel.quartile;
      case 'H':
        return BarcodeQRCorrectionLevel.high;
      case 'M':
      default:
        return BarcodeQRCorrectionLevel.medium;
    }
  }

  String _qrDataForPlace(CavePlace place) {
    return '${place.placeQrCodeIdentifier}';
  }

  String _sanitizeFilename(String inName) =>
      inName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '_');
}
