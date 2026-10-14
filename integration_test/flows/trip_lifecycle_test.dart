import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/cave_trip_list_page.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/localization.dart';

import '../support/fixture.dart';
import '../support/flow.dart';

const _title = 'Flow trip Foxtrot';

/// A trip started and stopped from a cave's trip list, the way a caver does
/// it at the entrance and again on the way out: the toolbar offers Start,
/// a name is given, the trip becomes the active one and the toolbar offers
/// Stop; stopping asks first, then the trip is closed with an end time.
///
/// Runs after the flows that only read data: it adds a trip.
void main() {
  flow('deep_trip_lifecycle', (driver) async {
    final tester = driver.tester;
    String t(String key) => LocServ.inst.t(key);
    await driver.launch();
    final fx = await Fx.load();
    expect(fx.cave, isNotNull, reason: 'needs a cave to start a trip in');

    driver.push(CaveTripListPage(caveUuid: fx.cave!.uuid));
    await driver.settle();

    await tester.tap(find.text(t('trip_start')).first);
    await driver.settle();
    await tester.enterText(find.byType(TextField).last, _title);
    await tester.tap(find.widgetWithText(TextButton, t('ok')));
    await driver.pumpUntil(
      () => find.text(t('trip_stop')).evaluate().isNotEmpty,
      reason: 'the toolbar to offer Stop once the trip has started',
      timeout: const Duration(seconds: 20),
    );
    await driver.shoot('40_trip_started');

    final db = rootContainer.read(appDatabaseProvider);
    final service = rootContainer.read(caveTripServiceProvider);
    final started = await (db.select(
      db.caveTrips,
    )..where((trip) => trip.title.equals(_title))).getSingle();
    expect(started.tripEndedAt, isNull);
    expect(service.activeTripIdNotifier.value, started.uuid);

    await tester.tap(find.text(t('trip_stop')).first);
    await driver.settle();
    await tester.tap(find.widgetWithText(TextButton, t('yes')));
    await driver.pumpUntil(
      () => find.text(t('trip_start')).evaluate().isNotEmpty,
      reason: 'the toolbar to offer Start again once the trip has stopped',
      timeout: const Duration(seconds: 20),
    );
    final ended = await (db.select(
      db.caveTrips,
    )..where((trip) => trip.uuid.equalsValue(started.uuid))).getSingle();
    expect(ended.tripEndedAt, isNotNull, reason: 'a stopped trip has an end');
    expect(service.activeTripIdNotifier.value, isNull);
    await driver.shoot('41_trip_stopped');
    expect(tester.takeException(), isNull);
  });
}
