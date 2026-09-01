import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// A PKCE verifier and the `S256` challenge derived from it.
///
/// The server requires PKCE and accepts `S256` only. The verifier is what
/// proves at the token exchange that the code is being redeemed by whoever
/// asked for it, which is what stands in for the client secret this public
/// client does not have.
class PkcePair {
  const PkcePair({required this.verifier, required this.challenge});

  final String verifier;
  final String challenge;

  /// 43–128 random URL-safe characters, and the base64url of the SHA-256 of
  /// the verifier's ASCII bytes.
  factory PkcePair.generate([Random? random]) {
    final rng = random ?? Random.secure();
    final bytes = List<int>.generate(48, (_) => rng.nextInt(256));
    final verifier = _base64UrlNoPadding(bytes);
    final challenge = _base64UrlNoPadding(
      sha256.convert(ascii.encode(verifier)).bytes,
    );
    return PkcePair(verifier: verifier, challenge: challenge);
  }

  static String _base64UrlNoPadding(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
}
