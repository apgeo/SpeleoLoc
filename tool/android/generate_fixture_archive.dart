// Builds an invented DataArchive the app can import as its whole database.
//
// Exists so automated UI runs never touch the real cave register. Every name,
// code and coordinate below is made up; the shapes are realistic (several
// caves, areas, entrances, places with place codes, trips with recorded
// points) so screens have something worth rendering, but nothing here
// describes a real cave or a real person.
//
// The output is the archive format the app already imports: a zip holding
// `speleo_loc.sqlite` plus a `manifest.json`. Drop a curated archive at the
// same path and the automation build picks it up instead, with no code
// change — that is the intended route for a real dataset later.
//
// Run through `flutter test`, not `dart run`: it builds the database with
// the app's own AppDatabase so the schema — including its version stamp and
// the indexes the migrations add — is correct by construction rather than
// by a hand-written copy that drifts. That pulls in the Flutter framework,
// which only the Flutter toolchain can compile.
//
// Usage:
//   flutter test tool/android/generate_fixture_archive.dart
//   FIXTURE_OUT=/tmp/x.zip FIXTURE_PLACE_CODES=a1,a2 \
//     flutter test tool/android/generate_fixture_archive.dart
//
// Default output: assets/test_archive/automation_fixture.zip, which is what
// build_settings.automation.json points at. That directory is git-ignored,
// and whatever sits in it is bundled into every build — see
// docs/workflows/local-test-archive.md.
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

const _defaultOut = 'assets/test_archive/automation_fixture.zip';

/// Invented caves. Names are deliberately not Romanian cave names, so a
/// fixture can never be mistaken for a register entry.
const _caves = [
  (
    title: 'Test Cave Alpha',
    index: 'TCA-001',
    areas: ['Upper Series', 'Lower Series'],
  ),
  (title: 'Test Cave Bravo', index: 'TCB-002', areas: ['Main Gallery']),
  (title: 'Test Cave Charlie', index: 'TCC-003', areas: <String>[]),
];

/// Place codes the photo fixtures encode as QR labels, so the two
/// generators line up and the automatic detection path has something to
/// resolve. Keep in step with generate_test_media.dart.
const _defaultPlaceCodes = ['a1', 'a2', 'a3'];

void main() {
  test(
    'build the invented automation fixture archive',
    _build,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Future<void> _build() async {
  final out = Platform.environment['FIXTURE_OUT'] ?? _defaultOut;
  final codesEnv = Platform.environment['FIXTURE_PLACE_CODES'];
  final placeCodes = (codesEnv == null || codesEnv.isEmpty)
      ? _defaultPlaceCodes
      : codesEnv.split(',').where((c) => c.isNotEmpty).toList();

  final tempDir = await Directory.systemTemp.createTemp('speleoloc_fixture_');
  final dbFile = File('${tempDir.path}/speleo_loc.sqlite');

  final db = AppDatabase.forTesting(NativeDatabase(dbFile));
  try {
    await _seed(db, placeCodes);
  } finally {
    await db.close();
  }

  final bytes = await dbFile.readAsBytes();
  final archive = Archive()
    ..addFile(ArchiveFile('speleo_loc.sqlite', bytes.length, bytes));
  final manifest = utf8.encode(
    jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'isDiff': false,
      'includesDocumentationFiles': false,
      'includesRasterMaps': false,
      'caveIds': <String>[],
      'includesFtpPasswords': false,
      // Not read by the importer; here so anyone opening the zip can tell at
      // a glance that it is not somebody's data.
      'fixture': 'invented automation fixture — contains no real data',
    }),
  );
  archive.addFile(ArchiveFile('manifest.json', manifest.length, manifest));

  final zip = ZipEncoder().encode(archive)!;
  final outFile = File(out);
  await outFile.parent.create(recursive: true);
  await outFile.writeAsBytes(zip);
  await tempDir.delete(recursive: true);

  stdout.writeln('wrote ${outFile.path} (${zip.length} bytes)');
  stdout.writeln('place codes: ${placeCodes.join(", ")}');
}

Future<void> _seed(AppDatabase db, List<String> placeCodes) async {
  final now = DateTime(2026, 10, 13, 9, 0).millisecondsSinceEpoch;

  final userUuid = Uuid.v7();
  await db
      .into(db.users)
      .insert(
        UsersCompanion.insert(
          uuid: userUuid,
          username: 'fixture_user',
          firstName: const Value('Fixture'),
          lastName: const Value('User'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

  // The first-run product tour starts itself on a timer and covers the
  // screen. An automated run needs the screen it asked for, every time.
  await db
      .into(db.configurations)
      .insert(
        ConfigurationsCompanion.insert(
          title: 'tour_auto_disabled',
          value: const Value('true'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

  final areaUuid = Uuid.v7();
  await db
      .into(db.surfaceAreas)
      .insert(
        SurfaceAreasCompanion.insert(
          uuid: areaUuid,
          title: 'Test Karst Area',
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

  var codeIndex = 0;
  for (var c = 0; c < _caves.length; c++) {
    final cave = _caves[c];
    final caveUuid = Uuid.v7();
    await db
        .into(db.caves)
        .insert(
          CavesCompanion.insert(
            uuid: caveUuid,
            title: cave.title,
            surfaceAreaUuid: Value(areaUuid),
            caveLocalIndex: Value(cave.index),
            description: Value('Invented fixture cave ${c + 1}.'),
            createdAt: Value(now),
            updatedAt: Value(now),
            createdByUserUuid: Value(userUuid),
            lastModifiedByUserUuid: Value(userUuid),
          ),
        );

    final areaUuids = <Uuid>[];
    for (final areaTitle in cave.areas) {
      final uuid = Uuid.v7();
      areaUuids.add(uuid);
      await db
          .into(db.caveAreas)
          .insert(
            CaveAreasCompanion.insert(
              uuid: uuid,
              caveUuid: caveUuid,
              title: areaTitle,
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    }

    // One main entrance plus a handful of inner places. The entrance matters
    // for the media import: a picture taken at one is what the entrance
    // reconciliation reacts to.
    final placeUuids = <Uuid>[];
    for (var p = 0; p < 6; p++) {
      final isEntrance = p == 0;
      final uuid = Uuid.v7();
      placeUuids.add(uuid);
      // Only the first cave's places get the codes the photo fixtures
      // encode, so a QR hit resolves to exactly one place.
      final code = (c == 0 && codeIndex < placeCodes.length)
          ? placeCodes[codeIndex++]
          : 'f${c}p$p';
      await db
          .into(db.cavePlaces)
          .insert(
            CavePlacesCompanion.insert(
              uuid: uuid,
              title: isEntrance ? 'Entrance' : 'Chamber $p',
              caveUuid: caveUuid,
              caveAreaUuid: Value(
                areaUuids.isEmpty ? null : areaUuids[p % areaUuids.length],
              ),
              placeCodeIdentifier: Value(code),
              qrCodeResourceIdentifier: Value(code),
              depthInCave: Value(isEntrance ? 0 : -(p * 12).toDouble()),
              isEntrance: Value(isEntrance ? 1 : 0),
              isMainEntrance: Value(isEntrance ? 1 : 0),
              createdAt: Value(now),
              updatedAt: Value(now),
              createdByUserUuid: Value(userUuid),
              lastModifiedByUserUuid: Value(userUuid),
            ),
          );
    }

    // Two trips per cave: one already ended, one still open, so both the
    // "correct a past trip" and "add to the live trip" paths have a target.
    // The first cave's trips fall on the day the photo fixtures are dated
    // (see generate_test_media.dart), so those pictures land inside the
    // trip's window and the one dated two days earlier falls outside it.
    for (var t = 0; t < 2; t++) {
      final ended = t == 0;
      final start = DateTime(2026, 10, 13 - c, 9, 0).millisecondsSinceEpoch;
      final tripUuid = Uuid.v7();
      await db
          .into(db.caveTrips)
          .insert(
            CaveTripsCompanion.insert(
              uuid: tripUuid,
              caveUuid: caveUuid,
              title: ended
                  ? 'Fixture trip ${c + 1} (ended)'
                  : 'Fixture trip ${c + 1} (open)',
              tripStartedAt: start,
              tripEndedAt: Value(
                ended ? start + const Duration(hours: 6).inMilliseconds : null,
              ),
              createdAt: Value(now),
              updatedAt: Value(now),
              createdByUserUuid: Value(userUuid),
              lastModifiedByUserUuid: Value(userUuid),
            ),
          );
      if (!ended) continue;
      for (var s = 0; s < 4; s++) {
        await db
            .into(db.caveTripPoints)
            .insert(
              CaveTripPointsCompanion.insert(
                uuid: Uuid.v7(),
                caveTripUuid: tripUuid,
                cavePlaceUuid: Value(placeUuids[s]),
                scannedAt:
                    start + Duration(minutes: 25 * (s + 1)).inMilliseconds,
                notes: Value(s == 2 ? 'Fixture note on a stop.' : null),
                createdAt: Value(now),
                updatedAt: Value(now),
                createdByUserUuid: Value(userUuid),
                lastModifiedByUserUuid: Value(userUuid),
              ),
            );
      }
    }
  }
}
