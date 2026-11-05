import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Maps an app bundle code (`en`, `pt_BR`) to the locale handed to
/// MaterialApp, or English when the framework ships no strings for it.
///
/// A bundle without framework support (the UI tests' pseudo-locale) must
/// not become MaterialApp's locale: its delegates would be skipped and
/// every Material widget would fail to find its localizations.
Locale materialLocaleFor(String code) {
  final parts = code.split('_');
  final locale = parts.length == 2
      ? Locale(parts[0], parts[1])
      : Locale(parts[0]);
  return GlobalMaterialLocalizations.delegate.isSupported(locale)
      ? locale
      : const Locale('en');
}

/// The locales MaterialApp may resolve to for the given app bundle codes.
/// English is always present: it is the fallback of both the app strings
/// and the framework.
List<Locale> materialSupportedLocales(Iterable<String> bundleCodes) {
  final locales = <Locale>{
    const Locale('en'),
    for (final code in bundleCodes) materialLocaleFor(code),
  };
  return locales.toList(growable: false);
}
