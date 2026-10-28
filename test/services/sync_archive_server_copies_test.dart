import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/user_repository.dart';

/// A picture the server handed down without its location, or drew at a
/// smaller size, stays on the device that fetched it: it is left out of every
/// device-to-device archive, with its links and its history. The caver's own
/// files and the server's originals travel as before.
void main() {
  late Directory tempDir;
  late Directory assetsDir;
  late AppDatabase db;
  late ChangeLogger logger;
  late SyncArchiveService sync;
  late SilexgisFileCopyRepository copies;

  final caveId = Uuid.v7();
  final placeId = Uuid.v7();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('speleoloc_copies_');
    assetsDir = await Directory.systemTemp.createTemp('speleoloc_copies_a_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger loggerRef;
    final users = UserRepository(db, () => loggerRef);
    final currentUser = CurrentUserService(
      db,
      users,
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    logger = loggerRef = ChangeLogger(db, currentUser);
    sync = SyncArchiveService(
      db,
      logger,
      assetsBaseDirResolver: () async => assetsDir,
    );
    copies = SilexgisFileCopyRepository(db);
    await db.into(db.caves).insert(Cave(uuid: caveId, title: 'Invented'));
    await db
        .into(db.cavePlaces)
        .insert(
          CavePlace(
            uuid: placeId,
            title: 'Invented place',
            caveUuid: caveId,
            isEntrance: 0,
            isMainEntrance: 0,
          ),
        );
  });
  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
    await assetsDir.delete(recursive: true);
  });

  /// A documentation file on the cave, with its asset on disk, registered as
  /// [heldAs] from the server unless it is the caver's own.
  Future<Uuid> file(String name, {SilexgisHeldAs? heldAs}) async {
    final id = Uuid.v7();
    final relPath = 'documentation_files/$name';
    final bytes = utf8.encode('invented $name');
    final asset = File('${assetsDir.path}/$relPath');
    await asset.parent.create(recursive: true);
    await asset.writeAsBytes(bytes);
    final now = DateTime.now().millisecondsSinceEpoch;
    await db
        .into(db.documentationFiles)
        .insert(
          DocumentationFilesCompanion.insert(
            uuid: id,
            title: name,
            fileName: relPath,
            fileSize: bytes.length,
            fileType: 'photo',
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    await db
        .into(db.documentationFilesToGeofeatures)
        .insert(
          DocumentationFilesToGeofeaturesCompanion.insert(
            uuid: Uuid.v7(),
            geofeatureType: 'cave',
            documentationFileUuid: id,
            geofeatureUuid: Value(caveId),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    if (heldAs != null) {
      await copies.register(
        SilexgisFileCopyEntry(
          documentUuid: id,
          heldAs: heldAs,
          origin: SilexgisCopyOrigin.server,
          rendition: heldAs == SilexgisHeldAs.rendition ? 480 : null,
        ),
      );
    }
    return id;
  }

  /// A raster map of the cave with one pin and its picture on disk. With
  /// [heldAs], it came from an installation and its picture was fetched as
  /// that, under the name the fetch gives it; without, the caver made it.
  Future<(Uuid, Uuid)> map(String title, {SilexgisHeldAs? heldAs}) async {
    final id = Uuid.v7();
    final document = Uuid.v7();
    final relPath = heldAs == null
        ? 'cave_$caveId/raster_${title.toLowerCase()}.jpg'
        : 'cave_$caveId/raster_$document.jpg';
    final bytes = utf8.encode('invented picture $title');
    final asset = File('${assetsDir.path}/$relPath');
    await asset.parent.create(recursive: true);
    await asset.writeAsBytes(bytes);
    final now = DateTime.now().millisecondsSinceEpoch;
    await db
        .into(db.rasterMaps)
        .insert(
          RasterMapsCompanion.insert(
            uuid: id,
            title: title,
            mapType: 'plane view',
            fileName: relPath,
            caveUuid: caveId,
          ).copyWith(createdAt: Value(now), updatedAt: Value(now)),
        );
    final pin = Uuid.v7();
    await db
        .into(db.cavePlaceToRasterMapDefinitions)
        .insert(
          CavePlaceToRasterMapDefinitionsCompanion.insert(
            uuid: pin,
            cavePlaceUuid: placeId,
            rasterMapUuid: id,
          ).copyWith(
            xCoordinate: const Value(10),
            yCoordinate: const Value(20),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    if (heldAs != null) {
      await db
          .into(db.silexgisRasterEntry)
          .insert(
            SilexgisRasterEntryCompanion.insert(
              profileUuid: 'p-1',
              entityUuid: id,
              mapUuid: id,
              received: const Value(true),
              documentId: Value(document),
            ),
          );
      await copies.register(
        SilexgisFileCopyEntry(
          documentUuid: document,
          heldAs: heldAs,
          origin: SilexgisCopyOrigin.server,
          rendition: heldAs == SilexgisHeldAs.rendition ? 2400 : null,
        ),
      );
    }
    return (id, pin);
  }

  List<Map<String, Object?>> rowsOf(Archive zip, String entry) {
    final file = zip.findFile(entry);
    if (file == null) return const <Map<String, Object?>>[];
    return const LineSplitter()
        .convert(utf8.decode(file.content as List<int>))
        .where((l) => l.trim().isNotEmpty)
        .map((l) => jsonDecode(l) as Map<String, Object?>)
        .toList();
  }

  test(
    'server copies other than the file itself stay out of the archive',
    () async {
      final own = await file('own.jpg');
      await file('original.jpg', heldAs: SilexgisHeldAs.original);
      final locationFree = await file(
        'location_free.jpg',
        heldAs: SilexgisHeldAs.locationFree,
      );
      final rendition = await file(
        'rendition_480.jpg',
        heldAs: SilexgisHeldAs.rendition,
      );
      // The caver edits the copy without location, then removes the drawn one.
      await logger.logUpdate(
        'documentation_files',
        locationFree,
        oldValues: <String, Object?>{'title': 'location_free.jpg'},
        newValues: <String, Object?>{'title': 'Renamed'},
      );
      await logger.logDelete(
        'documentation_files',
        rendition,
        oldValues: <String, Object?>{'title': 'rendition_480.jpg'},
      );
      await logger.logInsert('documentation_files', own);

      final zip = ZipDecoder().decodeBytes(
        await (await sync.exportToZip(
          tempDir.path,
          filenameHint: 'copies.zip',
        )).readAsBytes(),
      );

      final files = rowsOf(zip, 'tables/documentation_files.jsonl');
      expect(
        files.map((r) => r['title']),
        unorderedEquals(<String>['own.jpg', 'original.jpg']),
      );

      final links = rowsOf(
        zip,
        'tables/documentation_files_to_geofeatures.jsonl',
      );
      expect(links, hasLength(2));

      final assets = zip.files
          .where((f) => f.isFile && f.name.startsWith('assets/'))
          .map((f) => f.name)
          .toList();
      expect(
        assets,
        unorderedEquals(<String>[
          'assets/documentation_files/own.jpg',
          'assets/documentation_files/original.jpg',
        ]),
      );

      // The copy's history stays too: a removal replayed on another device
      // would remove that device's own file of the same identifier.
      final log = rowsOf(zip, 'change_log.jsonl');
      expect(log, hasLength(1));
      final fields = rowsOf(zip, 'change_log_field.jsonl');
      final kept = log.single['uuid'];
      expect(fields.every((f) => f['changeUuid'] == kept), isTrue);

      // Nothing here was touched.
      expect(await db.select(db.documentationFiles).get(), hasLength(4));
    },
  );

  group('an archive that brings a copy\'s document', () {
    late Directory otherAssets;
    late AppDatabase other;
    late SyncArchiveService otherSync;

    setUp(() async {
      otherAssets = await Directory.systemTemp.createTemp('speleoloc_other_');
      other = AppDatabase.forTesting(NativeDatabase.memory());
      late ChangeLogger loggerRef;
      final users = UserRepository(other, () => loggerRef);
      final currentUser = CurrentUserService(
        other,
        users,
        ConfigurationRepository(other),
      );
      await currentUser.initialize();
      loggerRef = ChangeLogger(other, currentUser);
      otherSync = SyncArchiveService(
        other,
        loggerRef,
        assetsBaseDirResolver: () async => otherAssets,
      );
    });
    tearDown(() async {
      await other.close();
      await otherAssets.delete(recursive: true);
    });

    /// The other device's own file under [id], last written at [updatedAt],
    /// exported and imported here.
    Future<void> importOwnFileOf(Uuid id, {required int updatedAt}) async {
      const relPath = 'documentation_files/doc_1_their_own.jpg';
      final bytes = utf8.encode('invented original');
      final asset = File('${otherAssets.path}/$relPath');
      await asset.parent.create(recursive: true);
      await asset.writeAsBytes(bytes);
      await other
          .into(other.documentationFiles)
          .insert(
            DocumentationFilesCompanion.insert(
              uuid: id,
              title: 'their own',
              fileName: relPath,
              fileSize: bytes.length,
              fileType: 'photo',
              createdAt: Value(updatedAt),
              updatedAt: Value(updatedAt),
            ),
          );
      final zip = await otherSync.exportToZip(
        tempDir.path,
        filenameHint: 'other.zip',
      );
      await sync.importFromZip(zip.path);
    }

    Future<void> ageRow(Uuid id, int updatedAt) =>
        (db.update(db.documentationFiles)..where((t) => t.uuid.equalsValue(id)))
            .write(DocumentationFilesCompanion(updatedAt: Value(updatedAt)));

    test('and replaces it records the file as that device\'s own', () async {
      final id = await file(
        'location_free.jpg',
        heldAs: SilexgisHeldAs.locationFree,
      );
      await copies.register(
        SilexgisFileCopyEntry(
          documentUuid: id,
          heldAs: SilexgisHeldAs.locationFree,
          origin: SilexgisCopyOrigin.server,
          versionId: 'v-1',
        ),
      );
      await ageRow(id, _t0);

      await importOwnFileOf(id, updatedAt: _t0 + 2000);

      final row = await (db.select(
        db.documentationFiles,
      )..where((t) => t.uuid.equalsValue(id))).getSingle();
      expect(row.fileName, 'documentation_files/doc_1_their_own.jpg');
      final entry = (await copies.read(id))!;
      expect(entry.heldAs, SilexgisHeldAs.own);
      expect(entry.origin, SilexgisCopyOrigin.archive);
      // The server revision this device knew for the document stays.
      expect(entry.versionId, 'v-1');
      expect(await copies.serverOnlyCopies(), isNot(contains(id)));
    });

    test('and loses to the copy leaves the copy registered', () async {
      final id = await file('rendition.jpg', heldAs: SilexgisHeldAs.rendition);
      await ageRow(id, _t0 + 3000);

      await importOwnFileOf(id, updatedAt: _t0 + 2000);

      final row = await (db.select(
        db.documentationFiles,
      )..where((t) => t.uuid.equalsValue(id))).getSingle();
      expect(row.fileName, 'documentation_files/rendition.jpg');
      expect((await copies.read(id))!.heldAs, SilexgisHeldAs.rendition);
    });
  });

  test('a map showing a server copy of its picture stays out of the archive '
      'with its pins', () async {
    final (own, ownPin) = await map('Own');
    final (_, originalPin) = await map(
      'Original',
      heldAs: SilexgisHeldAs.original,
    );
    final (locationFree, locationFreePin) = await map(
      'Without location',
      heldAs: SilexgisHeldAs.locationFree,
    );
    final (_, renditionPin) = await map(
      'Drawn',
      heldAs: SilexgisHeldAs.rendition,
    );
    // The caver moved a pin on the drawn map, and renamed the other copy.
    await logger.logUpdate(
      'cave_place_to_raster_map_definitions',
      renditionPin,
      oldValues: <String, Object?>{'x_coordinate': 10},
      newValues: <String, Object?>{'x_coordinate': 11},
    );
    await logger.logUpdate(
      'raster_maps',
      locationFree,
      oldValues: <String, Object?>{'title': 'Without location'},
      newValues: <String, Object?>{'title': 'Renamed'},
    );
    await logger.logInsert('raster_maps', own);

    final zip = ZipDecoder().decodeBytes(
      await (await sync.exportToZip(
        tempDir.path,
        filenameHint: 'maps.zip',
      )).readAsBytes(),
    );

    expect(
      rowsOf(zip, 'tables/raster_maps.jsonl').map((r) => r['title']),
      unorderedEquals(<String>['Own', 'Original']),
    );
    expect(
      rowsOf(
        zip,
        'tables/cave_place_to_raster_map_definitions.jsonl',
      ).map((r) => r['uuid']),
      unorderedEquals(<String>[ownPin.toString(), originalPin.toString()]),
    );
    final assets = zip.files
        .where((f) => f.isFile && f.name.startsWith('assets/cave_'))
        .map((f) => f.name)
        .toList();
    expect(assets, hasLength(2));
    expect(assets, contains('assets/cave_$caveId/raster_own.jpg'));
    final log = rowsOf(zip, 'change_log.jsonl');
    expect(log.map((r) => r['entity_uuid']), <String>[own.toString()]);

    // Nothing here was touched, and the copies' pins stay on this device.
    expect(await db.select(db.rasterMaps).get(), hasLength(4));
    expect(
      (await db.select(db.cavePlaceToRasterMapDefinitions).get()).map(
        (d) => d.uuid,
      ),
      containsAll(<Uuid>[locationFreePin, renditionPin]),
    );
  });
}

/// A stamp in milliseconds, as stored; a small number would be read as
/// seconds from an older device.
const int _t0 = 1767225600000;
