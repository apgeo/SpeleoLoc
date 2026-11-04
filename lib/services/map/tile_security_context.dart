import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// The TLS trust the online map tile client uses: the system's roots plus
/// Let's Encrypt's two public roots, bundled as assets.
///
/// Tile servers such as OpenTopoMap serve Let's Encrypt certificates, and
/// older Android trust stores do not hold the roots those chain to — ISRG
/// Root X1 is missing before Android 7.1.1 and ISRG Root X2 before Android
/// 14 — so on an Android 7 phone the map stayed blank. Only the tile client
/// gets this: every other connection keeps the platform's own trust.
class TileSecurityContext {
  TileSecurityContext._();

  static const List<String> rootCertificateAssets = [
    'assets/certs/isrg_root_x1.pem',
    'assets/certs/isrg_root_x2.pem',
  ];

  /// Builds the context from the bundled certificates. Throws when one of
  /// them is missing or unreadable.
  static Future<SecurityContext> load({AssetBundle? bundle}) async {
    final assets = bundle ?? rootBundle;
    return fromPems([
      for (final path in rootCertificateAssets)
        utf8.encode(await assets.loadString(path)),
    ]);
  }

  /// The system's roots plus each of [pems]. Throws a [TlsException] for a
  /// certificate that does not parse.
  static SecurityContext fromPems(Iterable<List<int>> pems) {
    final context = SecurityContext(withTrustedRoots: true);
    for (final pem in pems) {
      context.setTrustedCertificatesBytes(pem);
    }
    return context;
  }
}
