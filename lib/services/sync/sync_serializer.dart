import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:speleoloc/utils/uuid.dart';

/// A [ValueSerializer] that knows how to encode/decode the project's custom
/// value types into plain JSON-compatible primitives.
///
/// - [Uuid] <-> canonical 36-char lowercase string.
/// - [Uint8List] <-> base64 string (used e.g. for
///   `change_log_field.old_value_short`).
///
/// Everything else falls through to the default serializer behaviour.
class SyncValueSerializer extends ValueSerializer {
  const SyncValueSerializer();

  @override
  T fromJson<T>(dynamic json) {
    if (json == null) {
      return null as T;
    }
    if (T == Uuid) {
      return Uuid.parse(json as String) as T;
    }
    // T may be `Uuid?` — handled by the null short-circuit above.
    if (_isUuidType<T>()) {
      return Uuid.parse(json as String) as T;
    }
    if (T == Uint8List || _isBytesType<T>()) {
      return base64Decode(json as String) as T;
    }
    return json as T;
  }

  @override
  dynamic toJson<T>(T value) {
    if (value == null) return null;
    if (value is Uuid) return value.toString();
    if (value is Uint8List) return base64Encode(value);
    return value;
  }

  static bool _isUuidType<T>() => T == Uuid || <Uuid?>[] is List<T>;
  static bool _isBytesType<T>() =>
      T == Uint8List || <Uint8List?>[] is List<T>;
}
