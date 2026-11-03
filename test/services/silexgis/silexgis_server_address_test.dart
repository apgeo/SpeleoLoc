import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_address.dart';

/// The address is where the password and the long-lived credential are sent,
/// so what the box accepts is a security rule rather than a formatting one.
void main() {
  SilexgisAddressCheck release(String input) =>
      SilexgisServerAddress.check(input, allowLoopbackCleartext: false);
  SilexgisAddressCheck debug(String input) =>
      SilexgisServerAddress.check(input, allowLoopbackCleartext: true);

  group('check', () {
    test('accepts an https address and drops the trailing slash', () {
      final verdict = release('  https://speo.example.org/  ');
      expect(verdict.isAccepted, isTrue);
      expect(verdict.address, 'https://speo.example.org');
    });

    test('keeps a path prefix, without its trailing slashes', () {
      expect(
        release('https://club.example.org/silexgis//').address,
        'https://club.example.org/silexgis',
      );
    });

    test('keeps a port, and lower-cases the scheme and host', () {
      expect(
        release('HTTPS://Speo.Example.ORG:8443').address,
        'https://speo.example.org:8443',
      );
    });

    test('refuses plain http to a remote host, in every build', () {
      for (final check in <SilexgisAddressCheck Function(String)>[
        release,
        debug,
      ]) {
        expect(
          check('http://speo.example.org').problem,
          SilexgisAddressProblem.notHttps,
        );
      }
    });

    test('refuses an address with no scheme, or another scheme', () {
      expect(
        release('speo.example.org').problem,
        SilexgisAddressProblem.notHttps,
      );
      expect(
        release('ftp://speo.example.org').problem,
        SilexgisAddressProblem.notHttps,
      );
    });

    test('allows plain http to this machine only when the build allows it', () {
      for (final address in <String>[
        'http://127.0.0.1:5205',
        'http://localhost:5205/',
        'http://[::1]:5205',
      ]) {
        expect(debug(address).isAccepted, isTrue, reason: address);
        expect(
          release(address).problem,
          SilexgisAddressProblem.notHttps,
          reason: address,
        );
      }
      expect(debug('http://127.0.0.1:5205/').address, 'http://127.0.0.1:5205');
    });

    test('refuses a user name and password in the address', () {
      expect(
        release('https://caver:secret@speo.example.org').problem,
        SilexgisAddressProblem.extraParts,
      );
    });

    test('refuses a query or a fragment, even an empty one', () {
      for (final address in <String>[
        'https://speo.example.org?x=1',
        'https://speo.example.org?',
        'https://speo.example.org#top',
        'https://speo.example.org/#',
      ]) {
        expect(
          release(address).problem,
          SilexgisAddressProblem.extraParts,
          reason: address,
        );
      }
    });

    test('refuses an empty host, an empty box and a space in the host', () {
      for (final address in <String>[
        '',
        '   ',
        'https://',
        'https:///silexgis',
        'https:speo.example.org',
        'https://speo example.org',
      ]) {
        expect(
          release(address).problem,
          SilexgisAddressProblem.malformed,
          reason: address,
        );
      }
    });
  });

  group('sameServer', () {
    test('a trailing slash, letter case or the default port is the same', () {
      expect(
        SilexgisServerAddress.sameServer(
          'https://speo.example.org/',
          'HTTPS://Speo.Example.org:443',
        ),
        isTrue,
      );
      expect(
        SilexgisServerAddress.sameServer(
          'https://club.example.org/silexgis/',
          'https://club.example.org/silexgis',
        ),
        isTrue,
      );
    });

    test('another host, port, scheme or path prefix is another server', () {
      const base = 'https://speo.example.org';
      for (final other in <String>[
        'https://test.example.org',
        'https://speo.example.org:8443',
        'http://speo.example.org',
        'https://speo.example.org/other',
      ]) {
        expect(
          SilexgisServerAddress.sameServer(base, other),
          isFalse,
          reason: other,
        );
      }
    });
  });

  test('requireSecure refuses cleartext to a remote host before sending', () {
    expect(
      () => SilexgisServerAddress.requireSecure(
        Uri.parse('http://speo.example.org/connect/token'),
      ),
      throwsA(isA<SilexgisInsecureAddressException>()),
    );
    SilexgisServerAddress.requireSecure(
      Uri.parse('https://speo.example.org/connect/token'),
    );
  });
}
