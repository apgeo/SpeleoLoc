import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/database_swap/live_database_swap.dart';
import 'package:speleoloc/services/database_swap/set_aside_database_pruner.dart';
import 'package:speleoloc/utils/clock.dart';

import '../../support/database_file_fixtures.dart';

/// Copies of the database that failed swaps set aside do not pile up
/// forever, and none that may still matter is deleted. Every file here is
/// invented.
void main() {
  late Directory docs;
  late File live;
  final now = DateTime.utc(2026, 11, 7, 12);
  final pruner = SetAsideDatabasePruner(clock: FakeClock(now));

  setUp(() async {
    docs = await Directory.systemTemp.createTemp('set_aside_pruner_');
    live = File(p.join(docs.path, 'speleo_loc.sqlite'))
      ..writeAsStringSync('invented live database');
  });

  tearDown(() async {
    if (await docs.exists()) await docs.delete(recursive: true);
  });

  List<String> entries() =>
      docs.listSync().map((e) => p.basename(e.path)).toList()..sort();

  String setAside(Duration age, {int? n, String sidecar = ''}) {
    final stamp = now.subtract(age).millisecondsSinceEpoch;
    final name =
        'speleo_loc.sqlite${LiveDatabaseSwap.discardedSuffix}-$stamp'
        '${n == null ? '' : '-$n'}$sidecar';
    File(p.join(docs.path, name)).writeAsStringSync('invented copy');
    return name;
  }

  test('deletes copies older than the retention with their sidecars, and '
      'keeps younger ones', () async {
    final old = setAside(const Duration(days: 45));
    final oldWal = setAside(const Duration(days: 45), sidecar: '-wal');
    final oldTwin = setAside(const Duration(days: 45), n: 1);
    final oldTwinShm = setAside(
      const Duration(days: 45),
      n: 1,
      sidecar: '-shm',
    );
    final recent = setAside(const Duration(days: 29));
    final recentJournal = setAside(
      const Duration(days: 29),
      sidecar: '-journal',
    );
    final newest = setAside(const Duration(days: 1));

    await pruner.prune(live);

    for (final gone in [old, oldWal, oldTwin, oldTwinShm]) {
      expect(entries(), isNot(contains(gone)));
    }
    expect(
      entries(),
      unorderedEquals(['speleo_loc.sqlite', recent, recentJournal, newest]),
    );
  });

  test('keeps the newest copy however old it is', () async {
    final older = setAside(const Duration(days: 400));
    final newest = setAside(const Duration(days: 300));
    final newestWal = setAside(const Duration(days: 300), sidecar: '-wal');
    final newestTwin = setAside(const Duration(days: 300), n: 2);

    await pruner.prune(live);

    expect(entries(), isNot(contains(older)));
    expect(entries(), isNot(contains(newest)));
    expect(entries(), isNot(contains(newestWal)));
    expect(entries(), ['speleo_loc.sqlite', newestTwin]);
  });

  test('a lone copy stays, however old', () async {
    final only = setAside(const Duration(days: 4000));

    await pruner.prune(live);

    expect(entries(), ['speleo_loc.sqlite', only]);
  });

  test('never touches the live database, the swap backup, the incoming copy, '
      'or a name it cannot read', () async {
    final untouched = [
      'speleo_loc.sqlite',
      'speleo_loc.sqlite-wal',
      'speleo_loc.sqlite${LiveDatabaseSwap.backupSuffix}',
      'speleo_loc.sqlite${LiveDatabaseSwap.backupSuffix}-wal',
      'speleo_loc.sqlite${LiveDatabaseSwap.incomingSuffix}',
      'speleo_loc.sqlite${LiveDatabaseSwap.discardedSuffix}-notastamp',
      'speleo_loc.sqlite${LiveDatabaseSwap.discardedSuffix}-1-2-3',
      'speleo_loc.sqlite${LiveDatabaseSwap.discardedSuffix}-1.bak',
      'other.sqlite${LiveDatabaseSwap.discardedSuffix}-1',
      'invented_note.txt',
    ];
    for (final name in untouched) {
      File(p.join(docs.path, name)).writeAsStringSync('invented');
    }
    final folder = Directory(
      p.join(
        docs.path,
        'speleo_loc.sqlite${LiveDatabaseSwap.discardedSuffix}-2',
      ),
    )..createSync();
    final old = setAside(const Duration(days: 90));
    final newest = setAside(const Duration(days: 60));

    await pruner.prune(live);

    expect(entries(), isNot(contains(old)));
    expect(
      entries(),
      unorderedEquals([...untouched, p.basename(folder.path), newest]),
    );
  });

  test('a copy the start-up recovery sets aside survives the prune that '
      'follows it', () async {
    await live.delete();
    final swap = LiveDatabaseSwap(
      documentsDirectory: () async => docs,
      openLiveDatabase: () => throw StateError('not opened here'),
      currentDatabase: () => throw StateError('not opened here'),
      install: (_) {},
    );
    // What a kill mid-swap leaves: the caver's data at the backup name and
    // the half-installed new database at the live name.
    await appDatabaseFile(
      '${live.path}${LiveDatabaseSwap.backupSuffix}',
      marker: 'live',
    );
    await appDatabaseFile(live.path, marker: 'half-done');
    // Real time, as the recovery stamps it.
    final realNow = DateTime.now();
    final older = File(
      p.join(
        docs.path,
        'speleo_loc.sqlite${LiveDatabaseSwap.discardedSuffix}-'
        '${realNow.subtract(const Duration(days: 90)).millisecondsSinceEpoch}',
      ),
    )..writeAsStringSync('invented copy');

    expect(await swap.recoverInterruptedSwap(), isTrue);
    await SetAsideDatabasePruner(clock: FakeClock(realNow)).prune(live);

    final left = entries();
    expect(left, isNot(contains(p.basename(older.path))));
    expect(left, hasLength(2));
    expect(left.first, 'speleo_loc.sqlite');
    expect(
      left.last,
      startsWith('speleo_loc.sqlite${LiveDatabaseSwap.discardedSuffix}-'),
    );
    final restored = AppDatabase.file(live);
    try {
      expect(
        await ConfigurationRepository(restored).readString('invented_key'),
        'live',
      );
    } finally {
      await restored.close();
    }
  });

  test('a missing folder is not an error', () async {
    await docs.delete(recursive: true);

    await pruner.prune(live);
  });
}
