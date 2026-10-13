import 'dart:io';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/qr_code_lookup_service.dart';
import 'package:speleoloc/services/qr_scan_service.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Finds the cave place a photograph was taken at by reading a QR label out
/// of the picture itself.
///
/// Deliberately reuses the live-scan pipeline — [QrScanService] for the
/// payload rules (URL stripping, deep-link prefix) and
/// [QrCodeLookupService] for the identifier lookup — so a label that
/// resolves at the rock face resolves the same way from a photo of it.
class MediaQrDetector {
  MediaQrDetector(
    this._lookup, {
    MobileScannerController? controller,
    QrScanConfig config = const QrScanConfig(),
    QrScanService scanner = qrScanService,
  }) : _controller = controller ?? MobileScannerController(),
       _config = config,
       _scanner = scanner;

  final QrCodeLookupService _lookup;
  final MobileScannerController _controller;
  final QrScanConfig _config;
  final QrScanService _scanner;
  final _log = AppLogger.of('MediaQrDetector');

  /// Set once an analysis attempt proves the platform has no file analyzer,
  /// so a 200-picture run reports it once instead of per picture.
  bool _unsupported = false;

  /// True when this device cannot analyse image files at all (desktop, iOS
  /// Simulator). The screen uses it to say so instead of showing every
  /// picture as "no code found".
  bool get isUnsupported => _unsupported;

  /// Returns the cave place encoded in [file]'s QR label, or null when the
  /// picture holds no code, the code is not a known identifier, or the code
  /// belongs to a different cave than [caveUuid].
  Future<CavePlace?> detectCavePlace(
    File file, {
    required Uuid caveUuid,
  }) async {
    if (_unsupported) return null;
    final raw = await _readPayload(file);
    if (raw == null || raw.isEmpty) return null;

    final qcri = _scanner.process(raw, config: _config).qcri;
    if (qcri.isEmpty) return null;

    // Cave-scoped: a photograph can only have been taken in the cave the
    // trip belongs to, and scoping also removes the cross-cave ambiguity
    // that the live scanner has to ask the user about.
    final matches = await _lookup.lookup(qcri, currentCaveId: caveUuid);
    if (matches.isEmpty) return null;
    return matches.first.cavePlace;
  }

  Future<String?> _readPayload(File file) async {
    try {
      final capture = await _controller.analyzeImage(
        file.path,
        formats: const [BarcodeFormat.qrCode],
      );
      for (final barcode in capture?.barcodes ?? const <Barcode>[]) {
        final value = barcode.rawValue;
        if (value != null && value.trim().isNotEmpty) return value;
      }
      return null;
    } catch (e, st) {
      // The plugin documents an UnsupportedError where it has no file
      // analyzer (desktop, iOS Simulator). Tested by type rather than
      // caught by an `on Error` clause, which the lints rightly forbid.
      if (e is UnsupportedError) {
        _unsupported = true;
        _log.info('image analysis is unsupported on this platform', e, st);
        return null;
      }
      // A picture with no code, or one the decoder chokes on, is the normal
      // case in a camera roll — not something to surface per file.
      _log.fine('no QR code read from ${file.path}', e, st);
      return null;
    }
  }

  /// Releases the scanner's native resources. The controller is created
  /// lazily per screen, so the screen owns disposal.
  Future<void> dispose() async {
    try {
      await _controller.dispose();
    } catch (e, st) {
      _log.fine('scanner dispose failed', e, st);
    }
  }
}
