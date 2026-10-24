import 'dart:io';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/qr_code_lookup_service.dart';
import 'package:speleoloc/services/qr_scan_service.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// What reading one still for a QR label came to.
class QrRead {
  const QrRead.found(String this.payload) : readable = true;
  const QrRead.none() : payload = null, readable = true;
  const QrRead.failed() : payload = null, readable = false;

  /// The label's whole raw text, or null when there was none.
  final String? payload;

  /// False when the picture could not be read at all, which says nothing
  /// about whether it holds a label.
  final bool readable;
}

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

  /// Reads [file] for a QR label and returns its whole raw text.
  ///
  /// Separate from matching it to a place, so the text can be remembered
  /// and matched again later without decoding the picture again.
  Future<QrRead> readPayload(File file) async {
    if (_unsupported) return const QrRead.failed();
    try {
      final capture = await _controller.analyzeImage(
        file.path,
        formats: const [BarcodeFormat.qrCode],
      );
      for (final barcode in capture?.barcodes ?? const <Barcode>[]) {
        final value = barcode.rawValue;
        if (value != null && value.trim().isNotEmpty)
          return QrRead.found(value);
      }
      return const QrRead.none();
    } catch (e, st) {
      // The plugin documents an UnsupportedError where it has no file
      // analyzer (desktop, iOS Simulator). Tested by type rather than
      // caught by an `on Error` clause, which the lints rightly forbid.
      if (e is UnsupportedError) {
        _unsupported = true;
        _log.info('image analysis is unsupported on this platform', e, st);
        return const QrRead.failed();
      }
      // A decoder failure is not a verdict on the picture, and must not be
      // remembered as one.
      _log.fine('could not read ${file.path} for a QR code', e, st);
      return const QrRead.failed();
    }
  }

  /// The cave place [payload] names in the cave [caveUuid], or null.
  ///
  /// Uses the live-scan payload rules and the current places, so a payload
  /// read long ago is matched against the cave as it is now.
  Future<CavePlace?> placeForPayload(
    String payload, {
    required Uuid caveUuid,
  }) async {
    final qcri = _scanner.process(payload, config: _config).qcri;
    if (qcri.isEmpty) return null;
    // Cave-scoped: a photograph can only have been taken in the cave the
    // trip belongs to, and scoping also removes the cross-cave ambiguity
    // that the live scanner has to ask the user about.
    final matches = await _lookup.lookup(qcri, currentCaveId: caveUuid);
    return matches.isEmpty ? null : matches.first.cavePlace;
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
