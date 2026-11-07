import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

import '../../support/schema_description.dart';
import '../../support/schema_snapshots.dart';

/// A database brought up through the migration ladder must end with the same
/// schema a fresh install gets from `createAll()`: the same columns with the
/// same types, nullability and defaults, the same indexes and the same
/// foreign keys. Code is written and tested against the fresh shape, so any
/// drift shows up on upgraded devices only.
///
/// Every starting point is built from the schema snapshot of that version;
/// the oldest ones go through the re-keying of the integer-keyed schema.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late int latest;
  late File freshFile;
  late Map<String, Set<String>> fresh;

  setUpAll(() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    latest = db.schemaVersion;
    await db.close();
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('schema_parity_');
    freshFile = File(p.join(tmp.path, 'fresh.sqlite'));
    await openThroughApp(freshFile);
    fresh = describeSchema(freshFile);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('schema snapshots', () {
    test('cover every version from the oldest to the current one', () {
      final versions = schemaSnapshotVersions();
      expect(versions, isNotEmpty);
      expect(
        versions,
        [for (var v = versions.first; v <= latest; v++) v],
        reason:
            'a schema version without a snapshot: after raising '
            'schemaVersion, run this test once with '
            '$writeSchemaSnapshotVariable=1 and commit the new file',
      );
    });

    test('the current one is what a fresh install creates', () {
      final snapshot = schemaSnapshotFile(latest);
      if (Platform.environment[writeSchemaSnapshotVariable] == '1') {
        snapshot.writeAsStringSync(
          '-- Schema v$latest as drift creates it on a fresh install.\n\n'
          '${schemaSql(freshFile)}',
        );
      }
      expect(
        snapshot.existsSync(),
        isTrue,
        reason: 'run with $writeSchemaSnapshotVariable=1 to write it',
      );
      expect(
        withoutComments(schemaSql(freshFile)),
        withoutComments(snapshot.readAsStringSync()),
        reason:
            'tables.drift changed without raising schemaVersion, or the '
            'snapshot was not rewritten after raising it',
      );
    });

    test('the describer sees the constraints it compares', () {
      // Otherwise an empty difference below would prove nothing.
      expect(
        fresh['raster_maps'],
        containsAll(<Matcher>[
          startsWith('check (map_type in'),
          startsWith('unique (title, map_type, cave_uuid) on conflict'),
          startsWith('fk cave_uuid -> caves(uuid)'),
          startsWith('index UNIQUE (u)'),
        ]),
      );
      expect(
        fresh['cave_place_beacons'],
        contains(
          startsWith(
            'index idx_cave_place_beacons_ibeacon UNIQUE (c) '
            '(proximity_uuid, major, minor, cave_uuid) WHERE',
          ),
        ),
      );
    });
  });

  // The last snapshot is the current schema, which has nothing to upgrade.
  final snapshots = schemaSnapshotVersions();
  for (final version in snapshots.take(snapshots.length - 1)) {
    test('a v$version database upgrades to the fresh schema', () async {
      final f = createDatabaseAtVersion(
        p.join(tmp.path, 'v$version.sqlite'),
        version,
      );

      await openThroughApp(f);

      expect(userVersionOf(f), latest);
      expect(schemaDifferences(fresh, describeSchema(f)), isEmpty);
      expect(foreignKeyViolations(f), isEmpty);
      final d = sqlite3.open(f.path, mode: OpenMode.readOnly);
      try {
        expect(d.select('PRAGMA integrity_check').single.values.single, 'ok');
      } finally {
        d.close();
      }
    });
  }
}
