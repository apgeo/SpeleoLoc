import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Computes QR code resource identifiers (QCRIs) from place code
/// identifiers (PCIs) under the `hash` QCRI mode.
///
/// Algorithm (per docs/features/place-code-identifiers.md §5.2):
///
///   QCRI = base36_lowercase( sha256( salt || utf8(pci) ) ) [: length]
///
/// The salt is a hardcoded 16-byte constant baked into the app: it is
/// **not** stored, **not** synced, and **not** user-rotatable. This is
/// intentional so that two independent datasets / processes that hold
/// the same PCI compute the same QCRI ("cross-dataset reproducibility").
///
/// Output alphabet: `[0-9a-z]` (lowercase base36). Default length 8;
/// callers may pass 4..16. If the requested length collides with an
/// existing QCRI for a different cave place, callers should retry with
/// `length+1` up to the hard cap of 16; the hasher itself is pure and
/// does not perform retries.
class QcriHasher {
  /// Hardcoded 16-byte salt. Do not change without coordinating a
  /// dataset-wide QCRI recompute.
  static const List<int> _salt = <int>[
    0x9c, 0x42, 0xa1, 0x6f, 0x3b, 0xd7, 0x55, 0x18,
    0x0e, 0xb6, 0x7a, 0xc3, 0xe9, 0x21, 0x84, 0x5d,
  ];

  /// Hard upper bound for the QCRI length (§5.2 collision-retry cap).
  static const int maxLength = 16;

  /// Lower bound for the QCRI length (§6.1 UI slider min).
  static const int minLength = 4;

  const QcriHasher();

  /// Returns the QCRI for [pci] truncated to [length] base36-lowercase
  /// characters.
  ///
  /// If [userSalt] is non-null and non-empty its UTF-8 bytes are appended
  /// after the hardcoded [_salt] and before the PCI bytes, so different
  /// datasets that use the same PCI can produce distinct QCRIs.
  ///
  /// Throws [ArgumentError] if [length] is outside `[minLength, maxLength]`.
  String hash(String pci, {int length = 8, String? userSalt}) {
    if (length < minLength || length > maxLength) {
      throw ArgumentError.value(
        length,
        'length',
        'QCRI length must be in [$minLength, $maxLength]',
      );
    }
    final bytes = <int>[
      ..._salt,
      if (userSalt != null && userSalt.isNotEmpty) ...utf8.encode(userSalt),
      ...utf8.encode(pci),
    ];
    final digest = sha256.convert(bytes);
    final encoded = _base36LowerFromBytes(digest.bytes);
    if (encoded.length >= length) return encoded.substring(0, length);
    // sha256 digest is 32 bytes ≈ 50 base36 chars; this branch is
    // defensive only.
    return encoded.padLeft(length, '0');
  }

  /// Encodes [bytes] as a lowercase base36 number ([0-9a-z]).
  ///
  /// The bytes are interpreted big-endian as an unsigned integer.
  String _base36LowerFromBytes(List<int> bytes) {
    if (bytes.isEmpty) return '0';
    // Build the BigInt manually to avoid hex round-trips.
    var n = BigInt.zero;
    for (final b in bytes) {
      n = (n << 8) | BigInt.from(b & 0xff);
    }
    if (n == BigInt.zero) return '0';
    final buf = StringBuffer();
    final base = BigInt.from(36);
    while (n > BigInt.zero) {
      final rem = (n % base).toInt();
      buf.write(_alphabet[rem]);
      n = n ~/ base;
    }
    // Digits were emitted least-significant first; reverse for big-endian.
    return buf.toString().split('').reversed.join();
  }

  static const String _alphabet = '0123456789abcdefghijklmnopqrstuvwxyz';
}
