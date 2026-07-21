import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

/// The v15 -> v16 migration recreates cave_place_beacons (beacon_type
/// discriminator, nullable iBeacon triple, new telemetry columns). It must
/// PRESERVE existing registrations, back-fill beacon_type = 'ibeacon', and
/// install the partial UNIQUE index that guards Ruuvi identities.
///
/// A minimal v15-shaped database is built at the raw sqlite level (only
/// the tables the beacon FKs point at), then opened as [AppDatabase] so
/// the ladder runs exactly the v15 -> v16 step.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('v15 -> v16 keeps beacon registrations and adds ruuvi support', () async {
    final tmpDir = await Directory.systemTemp.createTemp('v15_beacon_test_');
    final tmpFile = File(p.join(tmpDir.path, 'v15.sqlite'));

    final caveUuid = List<int>.generate(16, (i) => i + 1);
    final placeUuid = List<int>.generate(16, (i) => i + 101);
    final beaconUuid = List<int>.generate(16, (i) => i + 201);

    final raw = sqlite3.open(tmpFile.path);
    try {
      // Minimal FK parents (shape only, as far as the beacon table needs).
      raw.execute('CREATE TABLE users (uuid BLOB PRIMARY KEY NOT NULL)');
      raw.execute('CREATE TABLE caves (uuid BLOB PRIMARY KEY NOT NULL)');
      // Stub carries the columns V16ToV17's twin-rename pass reads, so the
      // full ladder can run over this fixture.
      raw.execute(
        'CREATE TABLE cave_places (uuid BLOB PRIMARY KEY NOT NULL, '
        "title TEXT NOT NULL DEFAULT '', cave_uuid BLOB, "
        'cave_area_uuid BLOB, created_at INTEGER, updated_at INTEGER)',
      );
      raw.execute('INSERT INTO caves (uuid) VALUES (?)', [caveUuid]);
      raw.execute('INSERT INTO cave_places (uuid) VALUES (?)', [placeUuid]);

      // The beacon table exactly as V14ToV15Migration created it.
      raw.execute('''
        CREATE TABLE cave_place_beacons (
          uuid BLOB PRIMARY KEY NOT NULL,
          cave_place_uuid BLOB NOT NULL REFERENCES cave_places(uuid),
          cave_uuid BLOB NOT NULL REFERENCES caves(uuid),
          proximity_uuid TEXT NOT NULL,
          major INTEGER NOT NULL,
          minor INTEGER NOT NULL,
          mac_address TEXT,
          local_name TEXT,
          model TEXT,
          measured_power INTEGER,
          notes TEXT,
          last_seen_at INTEGER,
          last_battery_mv INTEGER,
          last_temperature_c REAL,
          last_humidity_pct REAL,
          created_at INTEGER,
          updated_at INTEGER,
          deleted_at INTEGER,
          created_by_user_uuid BLOB REFERENCES users(uuid),
          last_modified_by_user_uuid BLOB REFERENCES users(uuid),
          UNIQUE(proximity_uuid, major, minor, cave_uuid) ON CONFLICT ROLLBACK
        )
      ''');
      raw.execute(
        'INSERT INTO cave_place_beacons '
        '(uuid, cave_place_uuid, cave_uuid, proximity_uuid, major, minor, '
        'mac_address, last_battery_mv, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          beaconUuid,
          placeUuid,
          caveUuid,
          'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
          10816,
          1,
          'F0:C8:90:02:10:9B',
          3287,
          1000,
        ],
      );
      raw.execute('PRAGMA user_version = 15');
    } finally {
      raw.close();
    }

    // Opening as AppDatabase runs the ladder (only v15 -> v16 applies).
    final db = AppDatabase.forTesting(NativeDatabase(tmpFile));
    try {
      final beacons = await db.select(db.cavePlaceBeacons).get();
      expect(beacons, hasLength(1));
      final b = beacons.single;
      expect(b.beaconType, 'ibeacon');
      expect(b.proximityUuid, 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825');
      expect(b.major, 10816);
      expect(b.minor, 1);
      expect(b.macAddress, 'F0:C8:90:02:10:9B');
      expect(b.lastBatteryMv, 3287);
      expect(b.firmwareVersion, isNull);
      expect(b.lastPressureHpa, isNull);

      // Ruuvi rows carry a NULL triple and are unique per (mac, cave).
      Future<void> insertRuuvi(List<int> uuid, String mac) => db
          .into(db.cavePlaceBeacons)
          .insert(
            CavePlaceBeaconsCompanion.insert(
              uuid: Uuid.fromBytes(uuid),
              cavePlaceUuid: Uuid.fromBytes(placeUuid),
              caveUuid: Uuid.fromBytes(caveUuid),
              beaconType: const Value('ruuvi'),
              macAddress: Value(mac),
            ),
          );
      await insertRuuvi(
        List<int>.generate(16, (i) => i + 301),
        'CB:B8:33:4C:88:4F',
      );
      await expectLater(
        insertRuuvi(
          List<int>.generate(16, (i) => i + 401),
          'CB:B8:33:4C:88:4F',
        ),
        throwsA(anything),
        reason: 'partial UNIQUE index must reject a duplicate ruuvi MAC',
      );

      // The iBeacon triple constraint must still hold after the recreate.
      await expectLater(
        db
            .into(db.cavePlaceBeacons)
            .insert(
              CavePlaceBeaconsCompanion.insert(
                uuid: Uuid.fromBytes(List<int>.generate(16, (i) => i + 501)),
                cavePlaceUuid: Uuid.fromBytes(placeUuid),
                caveUuid: Uuid.fromBytes(caveUuid),
                proximityUuid: const Value(
                  'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
                ),
                major: const Value(10816),
                minor: const Value(1),
              ),
            ),
        throwsA(anything),
        reason: 'triple UNIQUE must survive the table recreation',
      );

      // The new history table is usable.
      await db
          .into(db.ruuviSensorHistory)
          .insert(
            RuuviSensorHistoryCompanion.insert(
              macAddress: 'CB:B8:33:4C:88:4F',
              measuredAt: 1600000000,
              temperatureC: const Value(4.2),
            ),
          );
      final history = await db.select(db.ruuviSensorHistory).get();
      expect(history.single.temperatureC, 4.2);
    } finally {
      await db.close();
      await tmpDir.delete(recursive: true);
    }
  });
}
