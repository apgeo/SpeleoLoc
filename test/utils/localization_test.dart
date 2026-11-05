import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/utils/material_locales.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final shipped =
      Directory('assets/i18n')
          .listSync()
          .map((e) => e.path.split('/').last)
          .where((name) => name.endsWith('.json'))
          .map((name) => name.substring(0, name.length - '.json'.length))
          .toList()
        ..sort();

  test('loading makes every shipped language selectable', () async {
    await LocServ.inst.load();
    expect(LocServ.inst.supportedLocales()..sort(), containsAll(shipped));
    expect(shipped, containsAll(['en', 'ro']));
    for (final code in shipped) {
      final bundle =
          jsonDecode(File('assets/i18n/$code.json').readAsStringSync())
              as Map<String, dynamic>;
      await LocServ.inst.setLocale(code);
      final anyKey = bundle.keys.first;
      expect(LocServ.inst.t(anyKey), bundle[anyKey].toString());
    }
    await LocServ.inst.setLocale('ro');
  });

  test('changing the language notifies listeners', () async {
    await LocServ.inst.load();
    var calls = 0;
    void listener() => calls++;
    LocServ.inst.addListener(listener);
    addTearDown(() => LocServ.inst.removeListener(listener));

    await LocServ.inst.setLocale('en');
    expect(calls, 1);
    await LocServ.inst.setLocale('ro');
    expect(calls, 2);
  });

  group('material locales', () {
    test('a bundle the framework knows keeps its own locale', () {
      expect(materialLocaleFor('ro'), const Locale('ro'));
      expect(materialLocaleFor('en'), const Locale('en'));
      expect(materialLocaleFor('pt_BR'), const Locale('pt', 'BR'));
    });

    test('a bundle without framework strings falls back to English', () {
      expect(materialLocaleFor('pseudo'), const Locale('en'));
    });

    test('supported locales cover every bundle and always include English', () {
      expect(materialSupportedLocales(const ['ro', 'pseudo']), const [
        Locale('en'),
        Locale('ro'),
      ]);
      expect(materialSupportedLocales(const []), const [Locale('en')]);
    });
  });
}
