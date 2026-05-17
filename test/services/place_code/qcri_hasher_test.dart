import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/place_code/qcri_hasher.dart';

void main() {
  const hasher = QcriHasher();

  test('hash output uses only [0-9a-z] alphabet', () {
    const inputs = ['1', '12345', 'hello', '88102820480780005', 'abc-def'];
    final allowed = RegExp(r'^[0-9a-z]+$');
    for (final pci in inputs) {
      final q = hasher.hash(pci, length: 8);
      expect(allowed.hasMatch(q), isTrue,
          reason: 'QCRI "$q" for PCI "$pci" contains invalid characters');
    }
  });

  test('hash is deterministic for the same input', () {
    final a = hasher.hash('cave-place-1', length: 8);
    final b = hasher.hash('cave-place-1', length: 8);
    expect(a, equals(b));
  });

  test('hash for different inputs differs (overwhelmingly)', () {
    final a = hasher.hash('pci-a', length: 8);
    final b = hasher.hash('pci-b', length: 8);
    expect(a, isNot(equals(b)));
  });

  test('hash length is respected', () {
    for (var n = QcriHasher.minLength; n <= QcriHasher.maxLength; n++) {
      final q = hasher.hash('some-pci', length: n);
      expect(q.length, equals(n));
    }
  });

  test('extending length is a prefix-stable view of the hash', () {
    // §5.2: collision retry uses length+1. The longer string should
    // start with the shorter string (true for raw base36 truncation).
    final short = hasher.hash('pci-x', length: 8);
    final longer = hasher.hash('pci-x', length: 10);
    expect(longer.startsWith(short), isTrue);
  });

  test('hash rejects out-of-range lengths', () {
    expect(() => hasher.hash('x', length: 3), throwsArgumentError);
    expect(() => hasher.hash('x', length: 17), throwsArgumentError);
  });

  test('cross-instance reproducibility (salt is hardcoded)', () {
    // Two independently constructed hashers must agree — there is no
    // per-instance state and the salt is a compile-time constant.
    const a = QcriHasher();
    const b = QcriHasher();
    final pa = a.hash('reproducible', length: 8);
    final pb = b.hash('reproducible', length: 8);
    expect(pa, equals(pb));
  });
}
