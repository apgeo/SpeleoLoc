import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/utils/clock.dart';

import '../support/sync_device.dart';

/// A phone whose clock ran years ahead stamps its edits with that date, and
/// last-writer-wins would let them beat every honest edit until then. The
/// import must not take such a stamp silently.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUp(() async => tmp = await Directory.systemTemp.createTemp('skew_'));
  tearDown(() => tmp.delete(recursive: true));

  test(
    'an edit stamped far ahead of this phone\'s clock is reported or '
    'brought back to now',
    () async {
      final wrong = FakeClock(
        DateTime.now().add(const Duration(days: 5 * 365)),
      );
      final a = await SyncTestDevice.create(clock: wrong);
      final b = await SyncTestDevice.create();
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      final cave = await a.caves.addCave('Invented Cave');
      await a.places.addCavePlace(cave, 'Junction');
      final place = await a.placeUuid(cave, 'Junction');

      final report = await a.sendTo(b, tmp, 'a1.zip');

      final stamp = (await (b.db.select(
        b.db.cavePlaces,
      )..where((p) => p.uuid.equalsValue(place))).getSingle()).updatedAt!;
      final tolerance = DateTime.now()
          .add(const Duration(days: 1))
          .millisecondsSinceEpoch;
      final reported = report.warnings.any((w) => w.contains('$place'));
      expect(
        reported || stamp <= tolerance,
        isTrue,
        reason: 'stamped ${DateTime.fromMillisecondsSinceEpoch(stamp)}',
      );
    },
    skip:
        'fix pending: an edit stamped years ahead by a wrong clock is taken '
        'without a word, and wins every later edit until that date',
  );
}
