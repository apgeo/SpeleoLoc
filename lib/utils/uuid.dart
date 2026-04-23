import 'dart:typed_data';

import 'package:drift/drift.dart' show TypeConverter;
import 'package:uuid/data.dart' as pkg_uuid_data;
import 'package:uuid/uuid.dart' as pkg_uuid;
import 'package:uuid/uuid_value.dart' as pkg_uuid_value;

/// A 128-bit UUID stored as 16 raw bytes with value equality semantics.
///
/// All syncable primary keys and foreign keys across the database use this
/// type. It is intentionally a value object: two `Uuid` instances with the
/// same byte content are equal and produce the same `hashCode`, which is
/// required for `Set<Uuid>` / `Map<Uuid, T>` to behave correctly.
///
/// The default generator produces UUIDv7 (time-ordered, RFC 9562) values via
/// the `uuid` package, which gives good B-tree index locality for newly
/// inserted rows.
class Uuid implements Comparable<Uuid> {
  /// Raw 16 bytes. Never modified after construction.
  final Uint8List bytes;

  const Uuid._(this.bytes);

  /// The all-zero (nil) UUID. Used as a placeholder for uninitialized route
  /// arguments or invalid values. Do not persist this value.
  static final Uuid zero = Uuid._(Uint8List(16));

  /// Construct a Uuid from exactly 16 bytes. The input is defensively copied.
  factory Uuid.fromBytes(List<int> input) {
    if (input.length != 16) {
      throw ArgumentError('Uuid must be exactly 16 bytes, got ${input.length}');
    }
    return Uuid._(Uint8List.fromList(input));
  }

  /// Parse from the canonical 36-character string form
  /// `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`.
  factory Uuid.parse(String text) {
    final value = pkg_uuid_value.UuidValue.withValidation(text);
    return Uuid._(Uint8List.fromList(value.toBytes()));
  }

  /// Parse or return null if [text] is null or not a valid UUID.
  static Uuid? tryParse(String? text) {
    if (text == null) return null;
    try {
      return Uuid.parse(text);
    } catch (_) {
      return null;
    }
  }

  static const pkg_uuid.Uuid _generator = pkg_uuid.Uuid();

  /// Generate a new UUIDv7 (time-ordered, RFC 9562).
  factory Uuid.v7([DateTime? now]) {
    final str = _generator.v7(
      config: now == null
          ? null
          : pkg_uuid_data.V7Options(now.millisecondsSinceEpoch, null),
    );
    return Uuid.parse(str);
  }

  /// Canonical 36-char lowercase string representation.
  @override
  String toString() {
    final sb = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) sb.write('-');
      final v = bytes[i];
      if (v < 16) sb.write('0');
      sb.write(v.toRadixString(16));
    }
    return sb.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Uuid) return false;
    for (var i = 0; i < 16; i++) {
      if (bytes[i] != other.bytes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    // FNV-1a over the 16 bytes.
    var h = 0x811c9dc5;
    for (var i = 0; i < 16; i++) {
      h = (h ^ bytes[i]) & 0xffffffff;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h;
  }

  @override
  int compareTo(Uuid other) {
    for (var i = 0; i < 16; i++) {
      final c = bytes[i].compareTo(other.bytes[i]);
      if (c != 0) return c;
    }
    return 0;
  }
}

/// Drift `TypeConverter` that maps a `BLOB` column to a [Uuid] value object.
class UuidConverter extends TypeConverter<Uuid, Uint8List> {
  const UuidConverter();

  @override
  Uuid fromSql(Uint8List fromDb) => Uuid.fromBytes(fromDb);

  @override
  Uint8List toSql(Uuid value) => value.bytes;
}
