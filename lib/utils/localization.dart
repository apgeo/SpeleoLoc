import 'dart:convert';
import 'package:flutter/services.dart';

/// LocalizationService
///
/// Loads localization strings from JSON files in assets/i18n/.
/// Supports parameter substitution via `t('key', {'param': 'value'})`.
class LocServ {
  LocServ._private();
  static final LocServ inst = LocServ._private(); // instance

  String _locale = 'ro';
  final String _defaultLocale = 'ro';

  final Map<String, Map<String, String>> _strings = {};

  /// Whether strings have been loaded from JSON assets.
  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Load strings for a given locale from assets/i18n/<locale>.json.
  /// Only loads if not already cached.
  Future<void> _loadLocale(String locale) async {
    if (_strings.containsKey(locale)) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/i18n/$locale.json');
      final Map<String, dynamic> map = jsonDecode(jsonStr) as Map<String, dynamic>;
      _strings[locale] = map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      // locale file not found or parse error – leave empty
    }
  }

  /// Load default and fallback locales. Call once at app startup (e.g. in main).
  Future<void> load() async {
    await _loadLocale('en');
    await _loadLocale(_defaultLocale);
    if (_locale != _defaultLocale && _locale != 'en') {
      await _loadLocale(_locale);
    }
    _loaded = true;
  }

  /// The currently active locale code.
  String get locale => _locale;

  Future<void> setLocale(String locale) async {
    _locale = locale;
    await _loadLocale(locale);
  }

  /// Return list of supported locale codes.
  List<String> supportedLocales() => _strings.keys.toList();

  /// Translate [key] using the current locale.
  ///
  /// Supports parameter substitution: placeholders written as `{paramName}`
  /// in the JSON value are replaced with matching entries from [params].
  ///
  /// Example:
  ///   JSON: `"greeting": "Hello, {name}!"`
  ///   Dart: `LocServ.inst.t('greeting', {'name': 'World'})` → `"Hello, World!"`
  String t(String key, [Map<String, String>? params]) {
    String result = _strings[_locale]?[key] ?? _strings['en']?[key] ?? key;
    if (params != null && params.isNotEmpty) {
      params.forEach((k, v) {
        result = result.replaceAll('{$k}', v);
      });
    }
    return result;
  }
}
