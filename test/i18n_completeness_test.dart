import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keys that appear in a `.t('…')`-shaped string but are not real lookups
/// (documentation examples and the like).
const _allowlist = {'greeting'};

/// Guards `assets/i18n/*.json` against code referencing keys that no locale
/// defines — `LocServ.t` falls back to the raw key string, so a missing key
/// leaks identifiers like `select_all` straight into the UI (this happened;
/// see review 2026-07-17 batch 6).
///
/// Only literal `.t('key')` / `.t('key', {...})` call sites are checkable;
/// keys passed indirectly (e.g. product-tour `titleLocKey` fields) are not
/// covered, which is also why the reverse check (orphaned keys) is not done.
void main() {
  test('every literal t(<key>) exists in every locale file', () {
    final keyPattern = RegExp(r"\.t\(\s*'([a-z0-9_]+)'");
    final usedKeys = <String, String>{}; // key → first file using it

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final match in keyPattern.allMatches(source)) {
        usedKeys.putIfAbsent(match.group(1)!, () => entity.path);
      }
    }
    usedKeys.removeWhere((k, _) => _allowlist.contains(k));
    expect(usedKeys, isNotEmpty, reason: 'key extraction found nothing — '
        'the regex or the working directory is broken');

    final localeFiles = Directory('assets/i18n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();
    expect(localeFiles, isNotEmpty);

    final failures = <String>[];
    for (final locale in localeFiles) {
      final defined =
          (jsonDecode(locale.readAsStringSync()) as Map<String, dynamic>).keys
              .toSet();
      for (final entry in usedKeys.entries) {
        if (!defined.contains(entry.key)) {
          failures.add(
            '${locale.path}: missing "${entry.key}" (used in ${entry.value})',
          );
        }
      }
    }

    expect(
      failures,
      isEmpty,
      reason:
          'Missing i18n keys — add them to the locale file(s):\n'
          '${failures.join('\n')}',
    );
  });
}
