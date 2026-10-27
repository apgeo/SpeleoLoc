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
}
