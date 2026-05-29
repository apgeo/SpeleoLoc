import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/qr_scan_service.dart';

void main() {
  const service = QrScanService();

  group('QrScanService.process — basic', () {
    test('empty payload returns empty qcri', () {
      final r = service.process('');
      expect(r.qcri, '');
      expect(r.hadDeepLinkPrefix, false);
      expect(r.hadUrlStrip, false);
    });

    test('whitespace-only payload returns empty qcri', () {
      final r = service.process('   \t  ');
      expect(r.qcri, '');
    });

    test('plain payload is trimmed and passed through unchanged', () {
      final r = service.process('  ABC-123  ');
      expect(r.qcri, 'ABC-123');
      expect(r.hadDeepLinkPrefix, false);
      expect(r.hadUrlStrip, false);
      expect(r.rawPayload, '  ABC-123  ');
    });
  });

  group('QrScanService.process — deep-link', () {
    test('strips deep-link prefix', () {
      final r = service.process('sp://CAVE-1');
      expect(r.qcri, 'CAVE-1');
      expect(r.hadDeepLinkPrefix, true);
    });

    test('non-deep-link payload reports hadDeepLinkPrefix=false', () {
      final r = service.process('plain-value');
      expect(r.hadDeepLinkPrefix, false);
    });
  });

  group('QrScanService.process — URL stripping', () {
    test('https URL is stripped to the segment after the last slash', () {
      final r = service.process('https://example.com/cave/p-42');
      expect(r.qcri, 'p-42');
      expect(r.hadUrlStrip, true);
      expect(r.hadDeepLinkPrefix, false);
    });

    test('= delimiter wins over / when it appears later', () {
      final r = service.process('https://example.com/x/y?q=p-99');
      expect(r.qcri, 'p-99');
      expect(r.hadUrlStrip, true);
    });

    test('non-http payload is not URL-stripped', () {
      final r = service.process('ftp://example.com/x');
      expect(r.qcri, 'ftp://example.com/x');
      expect(r.hadUrlStrip, false);
    });

    test('URL stripping disabled by config leaves URL intact', () {
      const cfg = QrScanConfig(stripUrlToLastDelimiter: false);
      final r = service.process('https://example.com/p-1', config: cfg);
      expect(r.qcri, 'https://example.com/p-1');
      expect(r.hadUrlStrip, false);
    });

    test('URL ending with a delimiter is not stripped (nothing after)', () {
      final r = service.process('https://example.com/cave/');
      // Last slash is final char → nothing to strip to.
      expect(r.hadUrlStrip, false);
      expect(r.qcri, 'https://example.com/cave/');
    });

    test('URL strip happens before deep-link strip', () {
      // Last '/' is inside the embedded 'sp://' — strip lands past it.
      final r = service.process('https://x/sp://INNER');
      expect(r.qcri, 'INNER');
      expect(r.hadUrlStrip, true);
      // After stripping, the remaining text starts with 'INNER', not
      // 'sp://', so no deep-link strip applies.
      expect(r.hadDeepLinkPrefix, false);
    });
  });
}
