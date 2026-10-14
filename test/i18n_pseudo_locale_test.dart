import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../integration_test/support/pseudo_locale.dart';

/// The pseudo-locale is only useful if the app can still use it: every
/// placeholder must survive for `LocServ.t` to substitute, and every
/// string must actually have grown.
void main() {
  final english =
      (jsonDecode(File('assets/i18n/en.json').readAsStringSync())
              as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, '$v'));
  final pseudo = pseudoLocalize(english);
  final placeholder = RegExp(r'\{\w+\}');

  test('keeps every placeholder of every string', () {
    final broken = [
      for (final key in english.keys)
        if (!_sameMultiset(
          placeholder.allMatches(english[key]!).map((m) => m[0]!),
          placeholder.allMatches(pseudo[key]!).map((m) => m[0]!),
        ))
          key,
    ];
    expect(broken, isEmpty);
  });

  test('makes every non-blank string longer and bracketed', () {
    for (final key in english.keys) {
      final source = english[key]!;
      if (source.trim().isEmpty) continue;
      expect(pseudo[key]!.length, greaterThan(source.length), reason: key);
      expect(pseudo[key], startsWith('['), reason: key);
      expect(pseudo[key], endsWith(']'), reason: key);
    }
  });
}

bool _sameMultiset(Iterable<String> a, Iterable<String> b) {
  final left = a.toList()..sort();
  final right = b.toList()..sort();
  return left.join('\u0000') == right.join('\u0000');
}
