import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/sync/sync_serializer.dart';
import 'package:speleoloc/utils/uuid.dart';

void main() {
  const s = SyncValueSerializer();

  group('SyncValueSerializer.toJson', () {
    test('Uuid encodes to canonical 36-char lowercase string', () {
      final u = Uuid.v7();
      final encoded = s.toJson<Uuid>(u);
      expect(encoded, isA<String>());
      expect((encoded as String).length, 36);
      expect(encoded, u.toString());
    });

    test('Uint8List encodes to base64 string', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      expect(s.toJson<Uint8List>(bytes), base64Encode(bytes));
    });

    test('null passes through as null', () {
      expect(s.toJson<Uuid?>(null), isNull);
      expect(s.toJson<Uint8List?>(null), isNull);
      expect(s.toJson<String?>(null), isNull);
    });

    test('primitive values pass through unchanged', () {
      expect(s.toJson<int>(42), 42);
      expect(s.toJson<String>('hello'), 'hello');
      expect(s.toJson<bool>(true), true);
      expect(s.toJson<double>(1.5), 1.5);
    });
  });

  group('SyncValueSerializer.fromJson', () {
    test('Uuid decodes from canonical string', () {
      final u = Uuid.v7();
      final decoded = s.fromJson<Uuid>(u.toString());
      expect(decoded, u);
    });

    test('Uuid? decodes a non-null string into a Uuid', () {
      final u = Uuid.v7();
      final decoded = s.fromJson<Uuid?>(u.toString());
      expect(decoded, u);
    });

    test('Uint8List decodes from base64', () {
      final original = Uint8List.fromList(List.generate(32, (i) => i));
      final encoded = base64Encode(original);
      expect(s.fromJson<Uint8List>(encoded), original);
    });

    test('null is preserved across nullable type parameters', () {
      expect(s.fromJson<Uuid?>(null), isNull);
      expect(s.fromJson<Uint8List?>(null), isNull);
      expect(s.fromJson<String?>(null), isNull);
      expect(s.fromJson<int?>(null), isNull);
    });

    test('primitive values pass through unchanged', () {
      expect(s.fromJson<int>(7), 7);
      expect(s.fromJson<String>('x'), 'x');
      expect(s.fromJson<bool>(false), false);
    });
  });

  group('SyncValueSerializer round-trips', () {
    test('Uuid -> json -> Uuid is lossless', () {
      final u = Uuid.v7();
      expect(s.fromJson<Uuid>(s.toJson<Uuid>(u)), u);
    });

    test('Uint8List -> json -> Uint8List is lossless', () {
      final bytes = Uint8List.fromList(List.generate(256, (i) => i));
      expect(s.fromJson<Uint8List>(s.toJson<Uint8List>(bytes)), bytes);
    });
  });
}
