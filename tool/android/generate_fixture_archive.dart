// Builds invented DataArchives the app can import as its whole database.
//
// Exists so automated UI runs never touch the real cave register. Every name,
// code and coordinate below is made up; the shapes are realistic (several
// caves, areas, entrances, places with place codes, survey drawings with
// points on them, documents, beacon tags, trips with recorded points) so
// screens have something worth rendering, but nothing here describes a real
// cave or a real person. Coordinates sit in the open sea off the Gulf of
// Guinea, where no cave can be.
//
// The output is the archive format the app already imports: a zip holding
// `speleo_loc.sqlite`, the files its rows name, and a `manifest.json`.
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
//   FIXTURE_VARIANTS_DIR=build/fixtures \
//     flutter test tool/android/generate_fixture_archive.dart
//
// Default output: assets/test_archive/automation_fixture.zip, which is what
// build_settings.automation.json points at. That directory is git-ignored,
// and whatever sits in it is bundled into every build — see
// docs/workflows/local-test-archive.md.
//
// With FIXTURE_VARIANTS_DIR set it also writes one archive per settings
// profile and language there, named `<settings>-<language>.zip`. The app
// keeps its settings in the same database, so a profile is nothing more
// than different rows: the test matrix seeds the variant it wants and the
// app starts up already configured, with no test-only switch in the app.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/documentation_file_helper.dart';

const _defaultOut = 'assets/test_archive/automation_fixture.zip';

/// Invented caves. Names are deliberately not Romanian cave names, so a
/// fixture can never be mistaken for a register entry. The last one is long
/// on purpose: a title that fits everywhere proves nothing about the rows
/// that have to hold it.
const _caves = [
  (
    title: 'Test Cave Alpha',
    index: 'TCA-001',
    areas: ['Upper Series', 'Lower Series'],
  ),
  (title: 'Test Cave Bravo', index: 'TCB-002', areas: ['Main Gallery']),
  (title: 'Test Cave Charlie', index: 'TCC-003', areas: <String>[]),
  (
    title: 'Test Cave Delta with a deliberately long name that must wrap',
    index: 'TCD-004',
    areas: ['The Very Long Area Name Of The Northern Extension'],
  ),
];

/// Place codes the photo fixtures encode as QR labels, so the two
/// generators line up and the automatic detection path has something to
/// resolve. Keep in step with generate_test_media.dart.
const _defaultPlaceCodes = ['a1', 'a2', 'a3'];

/// What each settings profile writes into the configuration table.
///
/// `default` is what a new user sees, minus the first-run tour: it starts
/// itself on a timer and covers the screen, and an automated run needs the
/// screen it asked for, every time. `busy` switches on every optional piece
/// of chrome and the widest coordinate format, which is where rows run out
/// of room. `tours` leaves the tour on, for the one run that checks the
/// tour itself.
const settingsProfiles = <String, Map<String, String>>{
  'default': {'tour_auto_disabled': 'true'},
  'busy': {
    'tour_auto_disabled': 'true',
    'show_home_toolbar': 'true',
    'show_docs_toolbar': 'true',
    'compact_nav_bar': 'true',
    'coordinate_display_format': 'dms',
  },
  'tours': {},
};

/// `pseudo` is not a language the app ships: the UI tests install it at run
/// time as lengthened, accented English, to find layouts that will not
/// survive a longer translation. See integration_test/support/pseudo_locale.dart.
const fixtureLanguages = ['ro', 'en', 'pseudo'];

void main() {
  test(
    'build the invented automation fixture archive',
    _build,
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

Future<void> _build() async {
  final out = Platform.environment['FIXTURE_OUT'] ?? _defaultOut;
  final codesEnv = Platform.environment['FIXTURE_PLACE_CODES'];
  final placeCodes = (codesEnv == null || codesEnv.isEmpty)
      ? _defaultPlaceCodes
      : codesEnv.split(',').where((c) => c.isNotEmpty).toList();

  // No language row: the app then starts in its own default, which is what
  // a fresh install does and what the existing flows were written against.
  final size = await _writeArchive(
    out,
    placeCodes,
    settings: settingsProfiles['default']!,
  );
  stdout.writeln('wrote $out ($size bytes)');
  stdout.writeln('place codes: ${placeCodes.join(", ")}');

  final variantsDir = Platform.environment['FIXTURE_VARIANTS_DIR'];
  if (variantsDir == null || variantsDir.isEmpty) return;
  for (final profile in settingsProfiles.entries) {
    for (final language in fixtureLanguages) {
      final path = '$variantsDir/${profile.key}-$language.zip';
      await _writeArchive(
        path,
        placeCodes,
        settings: {...profile.value, 'app_language': language},
      );
      stdout.writeln('wrote $path');
    }
  }
}

/// Builds one archive at [out] and returns its size in bytes.
Future<int> _writeArchive(
  String out,
  List<String> placeCodes, {
  required Map<String, String> settings,
}) async {
  final tempDir = await Directory.systemTemp.createTemp('speleoloc_fixture_');
  final dbFile = File('${tempDir.path}/speleo_loc.sqlite');
  final files = <String, Uint8List>{};

  final db = AppDatabase.forTesting(NativeDatabase(dbFile));
  try {
    await _seed(db, placeCodes, settings, files);
  } finally {
    await db.close();
  }

  final bytes = await dbFile.readAsBytes();
  final archive = Archive()
    ..addFile(ArchiveFile('speleo_loc.sqlite', bytes.length, bytes));
  for (final entry in files.entries) {
    archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
  }
  final manifest = utf8.encode(
    jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'isDiff': false,
      'includesDocumentationFiles': true,
      'includesRasterMaps': true,
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
  return zip.length;
}

Future<void> _seed(
  AppDatabase db,
  List<String> placeCodes,
  Map<String, String> settings,
  Map<String, Uint8List> files,
) async {
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

  for (final setting in settings.entries) {
    await db
        .into(db.configurations)
        .insert(
          ConfigurationsCompanion.insert(
            title: setting.key,
            value: Value(setting.value),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

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
      // Entrances and the place after them carry a position, so the surface
      // map has markers and the coordinate rows have something to format.
      final located = p < 2;
      await db
          .into(db.cavePlaces)
          .insert(
            CavePlacesCompanion.insert(
              uuid: uuid,
              title: _placeTitle(c, p),
              description: Value(p == 3 ? _longText : null),
              caveUuid: caveUuid,
              caveAreaUuid: Value(
                areaUuids.isEmpty ? null : areaUuids[p % areaUuids.length],
              ),
              placeCodeIdentifier: Value(code),
              qrCodeResourceIdentifier: Value(code),
              latitude: Value(located ? 0.02 + c * 0.011 + p * 0.0007 : null),
              longitude: Value(located ? 0.03 + c * 0.013 + p * 0.0009 : null),
              altitude: Value(located ? 412.5 + c * 37 - p * 6 : null),
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

    await _seedRasterMaps(
      db,
      files,
      caveIndex: c,
      caveUuid: caveUuid,
      placeUuids: placeUuids,
      userUuid: userUuid,
      now: now,
    );
    await _seedDocuments(
      db,
      files,
      caveIndex: c,
      caveUuid: caveUuid,
      placeUuid: placeUuids[1],
      areaUuid: areaUuids.isEmpty ? null : areaUuids.first,
      userUuid: userUuid,
      now: now,
    );
    if (c == 0) {
      await _seedBeacons(db, caveUuid, placeUuids, userUuid, now);
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

/// A paragraph long enough to need several lines on any phone.
const _longText =
    'Invented description. A low crawl opens into a chamber with a boulder '
    'floor; the way on is a climb at the far end. This text is long on '
    'purpose, so a field that shows it has to wrap, scroll or cut it off.';

/// Titles vary in length and script on purpose: one is as long as the
/// column allows and one carries every Romanian diacritic, because a font
/// that lacks a glyph shows it as an empty box and only a rendered screen
/// reveals that.
String _placeTitle(int cave, int place) {
  if (place == 0) return 'Entrance';
  if (cave == 0 && place == 4) return 'Sală de test ăâîșț ĂÂÎȘȚ';
  if (cave == 3 && place == 2) {
    return 'A chamber whose invented name runs to the full eighty characters '
        'allowed 1234567';
  }
  return 'Chamber $place';
}

/// Two survey drawings for the first cave and one for each of the others,
/// each with the cave's places marked on it, so the map viewer, the point
/// editor and the reorder list all have content.
Future<void> _seedRasterMaps(
  AppDatabase db,
  Map<String, Uint8List> files, {
  required int caveIndex,
  required Uuid caveUuid,
  required List<Uuid> placeUuids,
  required Uuid userUuid,
  required int now,
}) async {
  const types = ['plane view', 'extended profile'];
  final count = caveIndex == 0 ? 2 : 1;
  for (var m = 0; m < count; m++) {
    const width = 1600;
    const height = 1100;
    final stations = _stations(
      placeUuids.length,
      width,
      height,
      seed: caveIndex * 10 + m,
      profile: m == 1,
    );
    final png = _drawSurvey(width, height, stations, caveIndex * 10 + m);
    // Where the app itself puts a map it imports: a folder per cave inside
    // the documents directory, with that relative path as the file name.
    final fileName = 'cave_$caveUuid/fixture_map_${m + 1}.png';
    files[fileName] = png;

    final mapUuid = Uuid.v7();
    await db
        .into(db.rasterMaps)
        .insert(
          RasterMapsCompanion.insert(
            uuid: mapUuid,
            title: m == 0 ? 'Fixture plan' : 'Fixture extended profile',
            mapType: types[m],
            fileName: fileName,
            fileHash: Value(sha256.convert(png).toString()),
            fileSize: Value(png.length),
            orderIndex: Value(m),
            caveUuid: caveUuid,
            createdAt: Value(now),
            updatedAt: Value(now),
            createdByUserUuid: Value(userUuid),
            lastModifiedByUserUuid: Value(userUuid),
          ),
        );
    // The last place is left off every drawing, so "not yet placed on this
    // map" is a state the screens get to show.
    for (var p = 0; p < placeUuids.length - 1; p++) {
      await db
          .into(db.cavePlaceToRasterMapDefinitions)
          .insert(
            CavePlaceToRasterMapDefinitionsCompanion.insert(
              uuid: Uuid.v7(),
              xCoordinate: Value(stations[p].x),
              yCoordinate: Value(stations[p].y),
              cavePlaceUuid: placeUuids[p],
              rasterMapUuid: mapUuid,
              createdAt: Value(now),
              updatedAt: Value(now),
              createdByUserUuid: Value(userUuid),
              lastModifiedByUserUuid: Value(userUuid),
            ),
          );
    }
  }
}

/// Station positions along an invented passage: a wandering line for a
/// plan, a descending one for a profile.
List<Point<int>> _stations(
  int count,
  int width,
  int height, {
  required int seed,
  required bool profile,
}) {
  final rnd = Random(seed);
  final out = <Point<int>>[];
  for (var i = 0; i < count; i++) {
    final x = 160 + (width - 320) * i ~/ (count - 1);
    final y = profile
        ? 140 + (height - 280) * i ~/ (count - 1) + rnd.nextInt(60) - 30
        : height ~/ 2 + ((i.isEven ? -1 : 1) * (80 + rnd.nextInt(220)));
    out.add(Point(x, y));
  }
  return out;
}

/// Draws a line-art "survey": passage walls either side of the centre line
/// and a dot per station. Nothing in it is traced from a real drawing.
Uint8List _drawSurvey(
  int width,
  int height,
  List<Point<int>> stations,
  int seed,
) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(250, 248, 240));
  final wall = img.ColorRgb8(40, 40, 40);
  final centre = img.ColorRgb8(170, 60, 40);
  final rnd = Random(seed);
  for (var i = 0; i < stations.length - 1; i++) {
    final a = stations[i];
    final b = stations[i + 1];
    final half = 26 + rnd.nextInt(30);
    for (final side in const [-1, 1]) {
      img.drawLine(
        image,
        x1: a.x,
        y1: a.y + side * half,
        x2: b.x,
        y2: b.y + side * half,
        color: wall,
        thickness: 3,
      );
    }
    img.drawLine(image, x1: a.x, y1: a.y, x2: b.x, y2: b.y, color: centre);
  }
  for (final s in stations) {
    img.fillCircle(image, x: s.x, y: s.y, radius: 7, color: centre);
  }
  img.drawString(
    image,
    'INVENTED FIXTURE SURVEY',
    font: img.arial24,
    x: 40,
    y: height - 60,
    color: wall,
  );
  return Uint8List.fromList(img.encodePng(image, level: 6));
}

/// A text note on the cave, a photo on one of its places and, where the
/// cave has areas, a note on the first area — one document per kind of
/// thing a document can hang on.
Future<void> _seedDocuments(
  AppDatabase db,
  Map<String, Uint8List> files, {
  required int caveIndex,
  required Uuid caveUuid,
  required Uuid placeUuid,
  required Uuid? areaUuid,
  required Uuid userUuid,
  required int now,
}) async {
  Future<void> add(
    String title,
    String fileName,
    Uint8List bytes,
    GeofeatureType type,
    Uuid target, {
    String? description,
  }) async {
    files['${DocumentationFileHelper.storageSubDir}/$fileName'] = bytes;
    final docUuid = Uuid.v7();
    await db
        .into(db.documentationFiles)
        .insert(
          DocumentationFilesCompanion.insert(
            uuid: docUuid,
            title: title,
            description: Value(description),
            fileName: fileName,
            fileSize: bytes.length,
            fileHash: Value(sha256.convert(bytes).toString()),
            fileType: DocumentationFileHelper.detectFileType(fileName),
            createdAt: Value(now),
            updatedAt: Value(now),
            createdByUserUuid: Value(userUuid),
            lastModifiedByUserUuid: Value(userUuid),
          ),
        );
    await db
        .into(db.documentationFilesToGeofeatures)
        .insert(
          DocumentationFilesToGeofeaturesCompanion.insert(
            uuid: Uuid.v7(),
            geofeatureUuid: Value(target),
            geofeatureType: type.dbValue,
            documentationFileUuid: docUuid,
            createdAt: Value(now),
            updatedAt: Value(now),
            createdByUserUuid: Value(userUuid),
            lastModifiedByUserUuid: Value(userUuid),
          ),
        );
  }

  final n = caveIndex + 1;
  await add(
    'Fixture cave note $n',
    'fixture_cave_note_$n.txt',
    Uint8List.fromList(utf8.encode('Invented note for fixture cave $n.\n')),
    GeofeatureType.cave,
    caveUuid,
    description: 'An invented text note.',
  );
  await add(
    'Fixture place photo $n',
    'fixture_place_photo_$n.jpg',
    _fixturePhoto(seed: 300 + caveIndex),
    GeofeatureType.cavePlace,
    placeUuid,
  );
  if (areaUuid != null) {
    await add(
      'Fixture area note $n',
      'fixture_area_note_$n.md',
      Uint8List.fromList(
        utf8.encode('# Fixture area $n\n\nInvented markdown note.\n'),
      ),
      GeofeatureType.caveArea,
      areaUuid,
    );
  }
}

/// A small mottled JPEG, distinct per [seed] so no two share a hash.
Uint8List _fixturePhoto({required int seed}) {
  const w = 480;
  const h = 360;
  final image = img.Image(width: w, height: h);
  final rnd = Random(seed);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final base = 50 + ((x + y * 3 + seed) % 31) + rnd.nextInt(14);
      image.setPixelRgb(x, y, base, (base * 0.8).round(), (base * 0.6).round());
    }
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 88));
}

/// One tag of each family the app reads, on the first cave. The identifiers
/// are invented: the proximity UUID is not a vendor's and the hardware
/// address is in the locally-administered range no manufacturer is issued.
Future<void> _seedBeacons(
  AppDatabase db,
  Uuid caveUuid,
  List<Uuid> placeUuids,
  Uuid userUuid,
  int now,
) async {
  await db
      .into(db.cavePlaceBeacons)
      .insert(
        CavePlaceBeaconsCompanion.insert(
          uuid: Uuid.v7(),
          cavePlaceUuid: placeUuids[1],
          caveUuid: caveUuid,
          beaconType: const Value('ibeacon'),
          proximityUuid: const Value('00000000-F1C7-4000-8000-000000000001'),
          major: const Value(1),
          minor: const Value(101),
          localName: const Value('FIXTURE01'),
          model: const Value('Fixture tag'),
          measuredPower: const Value(-59),
          title: const Value('Fixture iBeacon'),
          createdAt: Value(now),
          updatedAt: Value(now),
          createdByUserUuid: Value(userUuid),
          lastModifiedByUserUuid: Value(userUuid),
        ),
      );
  await db
      .into(db.cavePlaceBeacons)
      .insert(
        CavePlaceBeaconsCompanion.insert(
          uuid: Uuid.v7(),
          cavePlaceUuid: placeUuids[2],
          caveUuid: caveUuid,
          beaconType: const Value('ruuvi'),
          macAddress: const Value('02:00:00:F1:C7:01'),
          localName: const Value('Ruuvi F1C7'),
          model: const Value('Fixture sensor tag'),
          title: const Value('Fixture Ruuvi'),
          lastBatteryMv: const Value(2950),
          lastTemperatureC: const Value(9.4),
          lastHumidityPct: const Value(98.5),
          lastPressureHpa: const Value(961.2),
          createdAt: Value(now),
          updatedAt: Value(now),
          createdByUserUuid: Value(userUuid),
          lastModifiedByUserUuid: Value(userUuid),
        ),
      );
}
