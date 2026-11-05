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

  test('the caver\'s own file takes the edit as a new revision', () async {
    final own = await picture();

    final id = await service.save(own, edited);

    expect(id, own.uuid);
    expect(await db.select(db.documentationFiles).get(), hasLength(1));
    final row = await (db.select(
      db.documentationFiles,
    )..where((t) => t.uuid.equalsValue(own.uuid))).getSingle();
    expect(row.fileHash, sha256.convert(edited).toString());
    expect(row.fileSize, edited.length);
    expect(row.title, own.title);
    // A fresh storage name, keeping the caver's name, so archive sync copies
    // the new bytes to phones that hold the old ones; the old file is gone.
    expect(row.fileName, isNot(own.fileName));
    expect(row.fileName, endsWith('_picture_480.jpg'));
    expect(await File('${base.path}/${row.fileName}').readAsBytes(), edited);
    expect(await File('${base.path}/${own.fileName}').exists(), isFalse);

    final change = (await db.select(db.changeLog).get()).single;
    expect(change.entityUuid, own.uuid);
    final fields = await (db.select(
      db.changeLogField,
    )..where((f) => f.changeUuid.equalsValue(change.uuid))).get();
    expect(
      fields.map((f) => f.fieldName),
      containsAll(<String>['file_name', 'file_hash']),
    );
  });

  test('a new title is saved and logged with the content', () async {
    final own = await picture();

    await service.save(own, edited, title: 'Looking up');

    final row = await (db.select(
      db.documentationFiles,
    )..where((t) => t.uuid.equalsValue(own.uuid))).getSingle();
    expect(row.title, 'Looking up');
    final fields = await db.select(db.changeLogField).get();
    expect(fields.map((f) => f.fieldName), contains('title'));
  });

  test('the old file stays while another record still names it', () async {
    final own = await picture();
    await db
        .into(db.documentationFiles)
        .insert(
          DocumentationFilesCompanion.insert(
            uuid: Uuid.v7(),
            title: 'Same file, other record',
            fileName: own.fileName,
            fileSize: own.fileSize,
            fileType: 'photo',
          ),
        );

    await service.save(own, edited);

    expect(
      await File('${base.path}/${own.fileName}').readAsString(),
      'invented picture',
    );
  });

  test('so does the server\'s stored file', () async {
    final original = await picture(heldAs: SilexgisHeldAs.original);

    expect(await service.save(original, edited), original.uuid);
  });

  test(
    'a file name that leaves the documents folder is never written',
    () async {
      final own = await picture();
      final escaping = own.copyWith(fileName: '../outside.jpg');

      await expectLater(
        service.save(escaping, edited),
        throwsA(isA<FileSystemException>()),
      );
      expect(await File('${base.parent.path}/outside.jpg').exists(), isFalse);
      final row = await (db.select(
        db.documentationFiles,
      )..where((t) => t.uuid.equalsValue(own.uuid))).getSingle();
      expect(row.fileHash, own.fileHash);
    },
  );
}
