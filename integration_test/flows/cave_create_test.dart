import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/localization.dart';

import '../support/flow.dart';

const _title = 'Flow Cave Echo';

/// A cave created the way a person creates one: the add button on the home
/// screen, the form, Save — and then what the app promised happens: the cave
/// is listed, it got its main entrance without being asked, and opening it
/// shows that entrance.
///
/// Runs last in a process: it adds a cave, and the sweep picks the first
/// cave it finds.
void main() {
  flow('deep_cave_create', (driver) async {
    final tester = driver.tester;
    String t(String key) => LocServ.inst.t(key);
    await driver.launch();

    await tester.tap(find.byTooltip(t('add_new_cave')).first);
    await driver.settle();
    await tester.enterText(
      find.widgetWithText(TextFormField, t('cave_title')),
      _title,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, t('add')));
    await driver.pumpUntil(
      () => find.text(_title).evaluate().isNotEmpty,
      reason: 'the new cave to be listed on the home screen',
      timeout: const Duration(seconds: 20),
    );
    await driver.settle();
    await driver.shoot('30_cave_created');

    final db = rootContainer.read(appDatabaseProvider);
    final cave = await (db.select(
      db.caves,
    )..where((c) => c.title.equals(_title))).getSingle();
    final places = await (db.select(
      db.cavePlaces,
    )..where((p) => p.caveUuid.equalsValue(cave.uuid))).get();
    expect(places, hasLength(1), reason: 'exactly the automatic entrance');
    expect(places.single.isMainEntrance, 1);

    await tester.tap(find.text(_title));
    await driver.settle();
    expect(find.text(places.single.title), findsWidgets);
    await driver.shoot('31_new_cave_opened');
    expect(tester.takeException(), isNull);
  });
}
