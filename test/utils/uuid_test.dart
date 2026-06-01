import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/utils/uuid.dart';

void main() {
  group('Uuid.fromBytes', () {
    test('round-trips 16 bytes exactly', () {
      final input = List<int>.generate(16, (i) => i * 7 & 0xff);
      final u = Uuid.fromBytes(input);
      expect(u.bytes, equals(Uint8List.fromList(input)));
    });

    test('rejects wrong-length input', () {
      expect(() => Uuid.fromBytes(List<int>.filled(15, 0)),
          throwsA(isA<ArgumentError>()));
      expect(() => Uuid.fromBytes(List<int>.filled(17, 0)),
          throwsA(isA<ArgumentError>()));
      expect(() => Uuid.fromBytes(const <int>[]),
          throwsA(isA<ArgumentError>()));
    });

    test('defensively copies input so later mutations do not leak', () {
      final input = List<int>.filled(16, 0);
      final u = Uuid.fromBytes(input);
      input[0] = 0xff;
      expect(u.bytes[0], 0);
    });
  });

  group('Uuid.parse / tryParse / toString', () {
    // 9th group must start with 8/9/a/b (RFC 4122 variant bits).
    const canonical = '01234567-89ab-4def-8123-456789abcdef';

    test('parse accepts canonical 36-char form and round-trips toString', () {
      final u = Uuid.parse(canonical);
      expect(u.toString(), canonical);
    });

    test('parse throws on malformed input', () {
      expect(() => Uuid.parse('not-a-uuid'), throwsA(anything));
      expect(() => Uuid.parse(''), throwsA(anything));
    });

    test('tryParse returns null for null / invalid, value for valid', () {
      expect(Uuid.tryParse(null), isNull);
      expect(Uuid.tryParse('garbage'), isNull);
      expect(Uuid.tryParse(canonical), isNotNull);
      expect(Uuid.tryParse(canonical).toString(), canonical);
    });

    test('toString produces lowercase 36-char form with hyphens at 8/13/18/23',
        () {
      final s = Uuid.parse(canonical).toString();
      expect(s.length, 36);
      expect(s[8], '-');
      expect(s[13], '-');
      expect(s[18], '-');
      expect(s[23], '-');
      expect(s, s.toLowerCase());
    });
  });

  group('Uuid.v7', () {
    test('produces a valid 36-char uuid parseable back', () {
      final u = Uuid.v7();
      final s = u.toString();
      expect(s.length, 36);
      expect(Uuid.parse(s), equals(u));
    });

    test('two successive v7 values differ', () {
      final a = Uuid.v7();
      final b = Uuid.v7();
      expect(a, isNot(equals(b)));
    });

    test('honours explicit DateTime for time-ordering', () {
      final t1 = DateTime.utc(2020, 1, 1);
      final t2 = DateTime.utc(2026, 1, 1);
      final a = Uuid.v7(t1);
      final b = Uuid.v7(t2);
      // UUIDv7 is time-ordered: later timestamp must sort after earlier.
      expect(a.compareTo(b), lessThan(0));
    });
  });

  group('equality, hashCode, compareTo', () {
    test('equal by bytes regardless of identity', () {
      final bytes = List<int>.generate(16, (i) => i);
      final a = Uuid.fromBytes(bytes);
      final b = Uuid.fromBytes(bytes);
      expect(identical(a, b), isFalse);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('unequal when any byte differs', () {
      final a = Uuid.fromBytes(List<int>.filled(16, 0));
      final b = Uuid.fromBytes(List<int>.filled(16, 0)..[15] = 1);
      expect(a, isNot(equals(b)));
    });

    test('usable as Set / Map key', () {
      final a = Uuid.fromBytes(List<int>.filled(16, 1));
      final b = Uuid.fromBytes(List<int>.filled(16, 1));
      final set = <Uuid>{a, b};
      expect(set.length, 1);
      final map = <Uuid, String>{a: 'x'};
      expect(map[b], 'x');
    });

    test('compareTo is byte-wise lexicographic', () {
      final low = Uuid.fromBytes(List<int>.filled(16, 0));
      final mid = Uuid.fromBytes(List<int>.filled(16, 0)..[0] = 1);
      final high = Uuid.fromBytes(List<int>.filled(16, 0xff));
      expect(low.compareTo(mid), lessThan(0));
      expect(mid.compareTo(high), lessThan(0));
      expect(high.compareTo(low), greaterThan(0));
      expect(low.compareTo(Uuid.fromBytes(List<int>.filled(16, 0))), 0);
    });
  });

  group('Uuid.zero', () {
    test('is all zero bytes and stringifies as the nil uuid', () {
      expect(Uuid.zero.bytes, equals(Uint8List(16)));
      expect(Uuid.zero.toString(), '00000000-0000-0000-0000-000000000000');
    });

    test('equals a freshly-constructed zero uuid', () {
      expect(Uuid.zero, equals(Uuid.fromBytes(List<int>.filled(16, 0))));
    });
  });

  group('UuidConverter (Drift)', () {
    const conv = UuidConverter();

    test('toSql returns the underlying bytes', () {
      final u = Uuid.fromBytes(List<int>.generate(16, (i) => i + 1));
      expect(conv.toSql(u), equals(u.bytes));
    });

    test('fromSql reconstructs an equal Uuid', () {
      final u = Uuid.fromBytes(List<int>.generate(16, (i) => i + 1));
      final round = conv.fromSql(conv.toSql(u));
      expect(round, equals(u));
    });
  });
}
