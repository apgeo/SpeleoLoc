import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/constants.dart';

/// Configuration controlling how [QrScanService.process] handles raw payloads.
///
/// Saved as JSON under [qrScanConfigKey] in the `configurations` table.
class QrScanConfig {
  /// When true (default), HTTP/HTTPS payloads are stripped to the portion
  /// after the last occurrence of any character in [urlStripDelimiters].
  ///
  /// Example with delimiters `['/', '=']`:
  ///   `https://mysite.com/scan?id=CAVE001`  → `CAVE001`
  ///   `https://mysite.com/cave/CAVE001`     → `CAVE001`
  final bool stripUrlToLastDelimiter;

  /// Single characters used to locate the split point inside an HTTP/HTTPS
  /// URL. The rightmost occurrence of any listed character is used.
  /// Default: `['/', '=']`.
  final List<String> urlStripDelimiters;

  const QrScanConfig({
    this.stripUrlToLastDelimiter = true,
    this.urlStripDelimiters = const ['/', '='],
  });

  /// Loads the persisted config from the database.
  /// Falls back to [QrScanConfig()] on any error or if not yet saved.
  static Future<QrScanConfig> load() async {
    try {
      final decoded =
          await configurationRepository.readJson(qrScanConfigKey);
      if (decoded.isEmpty) return const QrScanConfig();
      final rawDelimiters = decoded['urlStripDelimiters'];
      final delimiters = (rawDelimiters is List)
          ? rawDelimiters
              .whereType<String>()
              .where((s) => s.length == 1)
              .toList()
          : const <String>['/', '='];
      return QrScanConfig(
        stripUrlToLastDelimiter:
            decoded['stripUrlToLastDelimiter'] as bool? ?? true,
        urlStripDelimiters:
            delimiters.isEmpty ? const ['/', '='] : delimiters,
      );
    } catch (e, st) {
      AppLogger.of('QrScanConfig')
          .warning('QR scan config decode failed; using defaults', e, st);
      return const QrScanConfig();
    }
  }

  Map<String, dynamic> toJson() => {
        'stripUrlToLastDelimiter': stripUrlToLastDelimiter,
        'urlStripDelimiters': urlStripDelimiters,
      };
}

/// Result of processing a raw scanned QR payload.
///
/// [qcri] is the application-meaningful identifier extracted from the
/// payload — the value that should be stored as
/// `qr_code_resource_identifier`. [rawPayload] is the original scanned
/// string (kept for diagnostics / advanced parsing).
class QrScanResult {
  final String qcri;
  final String rawPayload;
  final bool hadDeepLinkPrefix;

  /// True when the payload was an HTTP/HTTPS URL and was stripped to the
  /// segment after the last configured delimiter.
  final bool hadUrlStrip;

  const QrScanResult({
    required this.qcri,
    required this.rawPayload,
    required this.hadDeepLinkPrefix,
    this.hadUrlStrip = false,
  });
}

/// Service that processes raw scanned QR payloads.
///
/// Processing steps (in order):
/// 1. Trim whitespace.
/// 2. If the payload is an HTTP/HTTPS URL and
///    [QrScanConfig.stripUrlToLastDelimiter] is enabled, strip everything
///    up to and including the last occurrence of any character in
///    [QrScanConfig.urlStripDelimiters].
/// 3. Strip the deep-link prefix (e.g. `sp://`) if present.
class QrScanService {
  const QrScanService();

  /// Process a raw scanned [payload].
  ///
  /// [config] defaults to [QrScanConfig()] (URL stripping enabled, using
  /// `/` and `=` as delimiters). Pass a loaded config to respect user
  /// settings.
  QrScanResult process(String payload,
      {QrScanConfig config = const QrScanConfig()}) {
    final trimmed = payload.trim();
    if (trimmed.isEmpty) {
      return QrScanResult(
        qcri: '',
        rawPayload: payload,
        hadDeepLinkPrefix: false,
      );
    }

    String working = trimmed;
    bool hadUrlStrip = false;

    // Step 1: URL stripping — applies only to http:// or https:// payloads.
    if (config.stripUrlToLastDelimiter &&
        (working.startsWith('http://') || working.startsWith('https://')) &&
        config.urlStripDelimiters.isNotEmpty) {
      int lastIdx = -1;
      for (final ch in config.urlStripDelimiters) {
        if (ch.length == 1) {
          final idx = working.lastIndexOf(ch);
          if (idx > lastIdx) lastIdx = idx;
        }
      }
      if (lastIdx >= 0 && lastIdx < working.length - 1) {
        working = working.substring(lastIdx + 1).trim();
        hadUrlStrip = true;
      }
    }

    // Step 2: Deep-link prefix stripping.
    if (working.startsWith(deepLinkPrefix)) {
      return QrScanResult(
        qcri: working.substring(deepLinkPrefix.length).trim(),
        rawPayload: payload,
        hadDeepLinkPrefix: true,
        hadUrlStrip: hadUrlStrip,
      );
    }

    return QrScanResult(
      qcri: working,
      rawPayload: payload,
      hadDeepLinkPrefix: false,
      hadUrlStrip: hadUrlStrip,
    );
  }
}

/// Global instance for convenience access from UI code.
const QrScanService qrScanService = QrScanService();
