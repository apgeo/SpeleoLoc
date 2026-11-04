import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/map/tile_security_context.dart';

/// The map tile client trusts Let's Encrypt's two roots on top of the
/// system's, for phones whose trust store predates them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundles both ISRG roots as assets', () async {
    expect(TileSecurityContext.rootCertificateAssets, hasLength(2));
    for (final path in TileSecurityContext.rootCertificateAssets) {
      final pem = await rootBundle.loadString(path);
      expect(pem, startsWith('-----BEGIN CERTIFICATE-----'), reason: path);
      // One certificate per file, so each root is counted on its own.
      expect(
        RegExp('BEGIN CERTIFICATE').allMatches(pem),
        hasLength(1),
        reason: path,
      );
      // Each one alone parses, so neither is carried along by the other.
      expect(
        () => SecurityContext(
          withTrustedRoots: false,
        ).setTrustedCertificatesBytes(utf8.encode(pem)),
        returnsNormally,
        reason: path,
      );
    }
  });

  test('loads both certificates into one context', () async {
    final context = await TileSecurityContext.load();
    expect(context, isA<SecurityContext>());
  });

  test('a certificate that does not parse is refused, not skipped', () {
    expect(
      () => TileSecurityContext.fromPems([
        utf8.encode('-----BEGIN CERTIFICATE-----\nnot a certificate\n'),
      ]),
      throwsA(isA<TlsException>()),
    );
  });
}
