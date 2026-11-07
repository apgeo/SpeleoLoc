import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

import '../../support/invented_rows.dart';
import '../../support/schema_snapshots.dart';

/// Every upgrade keeps every row and every value it had: one invented row
/// in each table, each column filled, must come out of the ladder whole.
/// Several steps rebuild a table and copy its rows back column by column; a
/// column left out of such a copy silently empties it for every caver who
/// upgrades across that step, and sync then spreads the loss to the peers.
///
/// Only the uuid-keyed versions are covered here; the re-keying of the older
/// integer-keyed schema has its own tests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late int latest;

  setUpAll(() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    latest = db.schemaVersion;
    await db.close();
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('upgrade_rows_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  // The upgrade clears the synced flag of every key the devices do not share,
  // so the invented row carries one of the shared keys; and it turns a map
  // type v8 does not know into `other`, so the map has a known one.
  const overrides = {
    'configurations': {'title': 'qcri_mode'},
    'raster_maps': {'map_type': 'plane view'},
  };

  // The upgrade seeds configuration keys of its own.
  const mayGainRows = {'configurations'};

  // The last snapshot is the current schema, which has nothing to upgrade.
  final snapshots = schemaSnapshotVersions();
  final versions = [
    for (final v in snapshots.take(snapshots.length - 1))
      if (v >= 7) v,
  ];

  Map<String, Map<String, Map<String, Object?>>> rowsOf(File f) {
    final d = sqlite3.open(f.path, mode: OpenMode.readOnly);
    try {
      return rowsByKey(d);
    } finally {
      d.close();
    }
  }

  group('a database created at an older version', () {
    for (final version in versions) {
      test('v$version keeps every row and value', () async {
        final f = createDatabaseAtVersion(
          p.join(tmp.path, 'v$version.sqlite'),
          version,
          seed: (d) => seedOneRowPerTable(d, overrides: overrides),
        );
        final before = rowsOf(f);

        await openThroughApp(f);

        expect(userVersionOf(f), latest);
        expect(
          rowDifferences(before, rowsOf(f), mayGainRows: mayGainRows),
          isEmpty,
        );
        expect(foreignKeyViolations(f), isEmpty);
      });
    }
  });

  // Builds before the ladder ran in one transaction could stop part-way and
  // leave a file stamped with its old version whose first steps had already
  // run. Opening it runs those steps again, over a schema that already has
  // their columns and tables, still empty.
  group('a half-upgraded file whose steps run again', () {
    for (final version in versions) {
      test('stamped v$version keeps every row and value', () async {
        final f = File(p.join(tmp.path, 'rerun_v$version.sqlite'));
        await openThroughApp(f);
        final scratch = createDatabaseAtVersion(
          p.join(tmp.path, 'shape_v$version.sqlite'),
          version,
        );
        final atVersion = _columnsOf(scratch);
        final d = sqlite3.open(f.path);
        try {
          d.execute('DELETE FROM configurations');
          seedOneRowPerTable(d, onlyColumns: atVersion, overrides: overrides);
          d.userVersion = version;
        } finally {
          d.close();
        }
        final before = rowsOf(f);

        await openThroughApp(f);
        await openThroughApp(f);

        expect(userVersionOf(f), latest);
        expect(
          rowDifferences(before, rowsOf(f), mayGainRows: mayGainRows),
          isEmpty,
        );
        expect(foreignKeyViolations(f), isEmpty);
      });
    }
  });
}

Map<String, Set<String>> _columnsOf(File f) {
  final d = sqlite3.open(f.path, mode: OpenMode.readOnly);
  try {
    return columnsByTable(d);
  } finally {
    d.close();
  }
}
