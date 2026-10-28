import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/documentation_byte_edit_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/user_repository.dart';

/// An edit of a file's content lands in place for the caver's own file, and
/// as a new document for a copy the server handed down that is not the file
/// itself — so a picture drawn at 480 px can never become the next revision
/// of a full-size original.
void main() {
  late Directory base;
  late AppDatabase db;
  late SilexgisFileCopyRepository copies;
  late DocumentationByteEditService service;

  final caveId = Uuid.v7();
  final edited = Uint8List.fromList(utf8.encode('invented edited picture'));

  setUp(() async {
    base = await Directory.systemTemp.createTemp('speleoloc_byte_edit_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger loggerRef;
    final users = UserRepository(db, () => loggerRef);
    final currentUser = CurrentUserService(
      db,
      users,
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    loggerRef = ChangeLogger(db, currentUser);
    copies = SilexgisFileCopyRepository(db);
    service = DocumentationByteEditService(
      db: db,
      logger: loggerRef,
      currentUser: currentUser,
      copies: copies,
      baseDir: () async => base,
    );
    await db.into(db.caves).insert(Cave(uuid: caveId, title: 'Invented'));
  });
  tearDown(() async {
    await db.close();
    await base.delete(recursive: true);
  });

  Future<DocumentationFile> picture({SilexgisHeldAs? heldAs}) async {
    final id = Uuid.v7();
    const relPath = 'documentation_files/srv_1_picture_480.jpg';
    final bytes = utf8.encode('invented picture');
    final file = File('${base.path}/$relPath');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    await db
        .into(db.documentationFiles)
        .insert(
          DocumentationFilesCompanion.insert(
            uuid: id,
            title: 'Picture',
            fileName: relPath,
            fileSize: bytes.length,
            fileType: 'photo',
          ).copyWith(
            description: const Value('Looking down'),
            fileHash: Value(sha256.convert(bytes).toString()),
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
          ),
        );
    if (heldAs != null) {
      await copies.register(
        SilexgisFileCopyEntry(
          documentUuid: id,
          heldAs: heldAs,
          origin: SilexgisCopyOrigin.server,
          versionId: 'version-1',
          rendition: heldAs == SilexgisHeldAs.rendition ? 480 : null,
        ),
      );
    }
    return (db.select(
      db.documentationFiles,
    )..where((t) => t.uuid.equalsValue(id))).getSingle();
  }

  for (final heldAs in <SilexgisHeldAs>[
    SilexgisHeldAs.rendition,
    SilexgisHeldAs.locationFree,
  ]) {
    test('a ${heldAs.wireName} copy edited becomes a new document', () async {
      final copy = await picture(heldAs: heldAs);

      final id = await service.save(copy, edited);

      expect(id, isNot(copy.uuid));
      // The copy is left exactly as it was, bytes and all.
      final kept = await (db.select(
        db.documentationFiles,
      )..where((t) => t.uuid.equalsValue(copy.uuid))).getSingle();
      expect(kept, copy);
      expect(
        await File('${base.path}/${copy.fileName}').readAsString(),
        'invented picture',
      );
      expect((await copies.read(copy.uuid))!.heldAs, heldAs);

      final made = await (db.select(
        db.documentationFiles,
      )..where((t) => t.uuid.equalsValue(id))).getSingle();
      expect(made.title, 'Picture');
      expect(made.description, 'Looking down');
      expect(made.fileHash, sha256.convert(edited).toString());
      expect(made.fileName, isNot(copy.fileName));
      expect(await File('${base.path}/${made.fileName}').readAsBytes(), edited);
      // The caver's own file: nothing in the register.
      expect(await copies.read(id), isNull);
      // Hung where the copy hangs, and logged as the caver's own act.
      final links = await (db.select(
        db.documentationFilesToGeofeatures,
      )..where((t) => t.documentationFileUuid.equalsValue(id))).get();
      expect(links.single.geofeatureUuid, caveId);
      final logged = (await db.select(db.changeLog).get())
          .map((c) => c.entityTable)
          .toList();
      expect(
        logged,
        containsAll(<String>[
          'documentation_files',
          'documentation_files_to_geofeatures',
        ]),
      );
    });
  }

  test('the caver\'s own file takes the edit in place', () async {
    final own = await picture();

    final id = await service.save(own, edited);

    expect(id, own.uuid);
    expect(await db.select(db.documentationFiles).get(), hasLength(1));
    final row = await (db.select(
      db.documentationFiles,
    )..where((t) => t.uuid.equalsValue(own.uuid))).getSingle();
    expect(row.fileHash, sha256.convert(edited).toString());
    expect(row.fileSize, edited.length);
    expect(await File('${base.path}/${own.fileName}').readAsBytes(), edited);
  });

  test('so does the server\'s stored file', () async {
    final original = await picture(heldAs: SilexgisHeldAs.original);

    expect(await service.save(original, edited), original.uuid);
  });
}
