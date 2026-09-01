import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/qr_scan_service.dart';
import 'package:speleoloc/utils/qr_label_payload.dart';

/// What a printed square encodes, and the one condition on it that nothing
/// else enforces.
void main() {
  group('composing a payload', () {
    test('a deep link by default, which only this app resolves', () {
      expect(QrLabelPayload.compose('k3f9zq81'), 'sp://k3f9zq81');
    });

    test('the bare code when the prefix is turned off', () {
      expect(
        QrLabelPayload.compose('k3f9zq81', includeDeepLinkPrefix: false),
        'k3f9zq81',
      );
    });

    test('a landing address wins over the deep link', () {
      // A square carries one prefix, and the URL form is the one a stranger's
      // phone can open. No server can make a sp:// label resolve anywhere.
      expect(
        QrLabelPayload.compose(
          'k3f9zq81',
          urlPrefix: 'https://speo.example.org/q/',
          includeDeepLinkPrefix: true,
        ),
        'https://speo.example.org/q/k3f9zq81',
      );
    });

    test('a prefix without a trailing slash still separates the code', () {
      // The scanner takes the text after the last delimiter, so a prefix with
      // none would swallow the code.
      expect(
        QrLabelPayload.compose(
          'k3f9zq81',
          urlPrefix: 'https://speo.example.org/q',
        ),
        'https://speo.example.org/q/k3f9zq81',
      );
    });

    test('an empty code stays empty rather than becoming a bare prefix', () {
      expect(QrLabelPayload.compose(''), '');
      expect(
        QrLabelPayload.compose('', urlPrefix: 'https://speo.example.org/q/'),
        '',
      );
    });
  });

  group('a label printed as a URL still resolves in this application', () {
    const scanner = QrScanService();

    test('the scanner strips it back to the code', () {
      final result = scanner.process(
        QrLabelPayload.compose(
          'k3f9zq81',
          urlPrefix: 'https://speo.example.org/q/',
        ),
      );
      expect(result.qcri, 'k3f9zq81');
      expect(result.hadUrlStrip, isTrue);
    });

    test('and a trailing slash on the printed label changes nothing', () {
      expect(
        scanner.process('https://speo.example.org/q/k3f9zq81/').qcri,
        'k3f9zq81',
      );
    });

    test(
      'a deep-link label goes on working, so old labels are not orphaned',
      () {
        final result = scanner.process(QrLabelPayload.compose('k3f9zq81'));
        expect(result.qcri, 'k3f9zq81');
        expect(result.hadDeepLinkPrefix, isTrue);
      },
    );
  });

  group('the condition nothing else enforces', () {
    test('a code carrying a strip delimiter is truncated when scanned', () {
      const scanner = QrScanService();
      // The split is on the rightmost delimiter, so everything before it is
      // thrown away: `RO/BV/0001` comes back as `0001` and resolves to
      // nothing. A hash-mode reference cannot contain one — its alphabet is
      // [0-9a-z] — but a mirror-mode code is the place code verbatim.
      expect(QrLabelPayload.isScannable('RO/BV/0001'), isFalse);
      expect(QrLabelPayload.isScannable('RO=BV=0001'), isFalse);
      expect(QrLabelPayload.isScannable('RO-BV-0001'), isTrue);
      expect(QrLabelPayload.isScannable('k3f9zq81'), isTrue);

      final truncated = scanner.process(
        QrLabelPayload.compose(
          'RO/BV/0001',
          urlPrefix: 'https://speo.example.org/q/',
        ),
      );
      expect(truncated.qcri, '0001');
    });

    test('a separator is judged by the same rule', () {
      // It joins every segment of every code allocated afterwards, so one bad
      // character here breaks every label at once.
      expect(QrLabelPayload.isSeparatorScannable('-'), isTrue);
      expect(QrLabelPayload.isSeparatorScannable(''), isTrue);
      expect(QrLabelPayload.isSeparatorScannable('/'), isFalse);
      expect(QrLabelPayload.isSeparatorScannable('='), isFalse);
    });
  });
}
