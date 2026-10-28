import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/utils/clock.dart';

/// Says whether a documentation file is a copy that must never take new
/// content in place.
abstract interface class DocumentationCopyRegister {
  /// True for a copy a server handed down that is not the file itself — a
  /// picture without its location, or one the server drew smaller.
  Future<bool> isServerOnlyCopy(Uuid documentUuid);
}

/// Saves new content an editor made of a documentation file.
///
/// The caver's own file, or the server's stored one, takes the content in
/// place, as it always has. A copy that is not the file itself becomes the
/// starting point of a **new** document instead, hung wherever the copy hangs,
/// and the copy is left as it was: a 480 px picture, or one stripped of its
/// position, edited and sent up as the next revision of the document would
/// replace a full-size original on the server for every reader.
class DocumentationByteEditService {
  DocumentationByteEditService({
    required AppDatabase db,
    required ChangeLogger logger,
    required CurrentUserService currentUser,
    required DocumentationCopyRegister copies,
    required Future<Directory> Function() baseDir,
    Clock clock = const SystemClock(),
  }) : _db = db,
       _logger = logger,
       _currentUser = currentUser,
       _copies = copies,
       _baseDir = baseDir,
       _clock = clock;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final CurrentUserService _currentUser;
  final DocumentationCopyRegister _copies;
  final Future<Directory> Function() _baseDir;
  final Clock _clock;

  static const String storageSubDir = 'documentation_files';

  /// Saves [bytes] as the new content of [document]. Returns the identifier
  /// of the documentation file that now holds them.
  Future<Uuid> save(DocumentationFile document, Uint8List bytes) async {
    if (await _copies.isServerOnlyCopy(document.uuid)) {
      return _saveAsNew(document, bytes);
    }
    await _overwrite(document, bytes);
    return document.uuid;
  }

  Future<void> _overwrite(DocumentationFile document, Uint8List bytes) async {
    final base = await _baseDir();
    await File(
      '${base.path}/${document.fileName}',
    ).writeAsBytes(bytes, flush: true);
    final hash = sha256.convert(bytes).toString();
    final author = await _currentUser.currentOrSystem();
    await _db.transaction(() async {
      await (_db.update(
        _db.documentationFiles,
      )..where((t) => t.uuid.equalsValue(document.uuid))).write(
        DocumentationFilesCompanion(
          fileSize: Value(bytes.length),
          fileHash: Value(hash),
          updatedAt: Value(_clock.nowMs()),
          lastModifiedByUserUuid: Value(author),
        ),
      );
      await _logger.logUpdate(
        'documentation_files',
        document.uuid,
        oldValues: <String, Object?>{
          'file_size': document.fileSize,
          'file_hash': document.fileHash,
        },
        newValues: <String, Object?>{
          'file_size': bytes.length,
          'file_hash': hash,
        },
      );
    });
  }

  Future<Uuid> _saveAsNew(DocumentationFile copy, Uint8List bytes) async {
    final base = await _baseDir();
    final folder = Directory('${base.path}/$storageSubDir');
    await folder.create(recursive: true);
    final now = _clock.nowMs();
    final stem = copy.fileName
        .split('/')
        .last
        .replaceFirst(RegExp(r'^(doc|srv)_\d+_(\d+_)?'), '');
    var name = 'doc_${now}_$stem';
    for (var n = 1; await File('${folder.path}/$name').exists(); n++) {
      name = 'doc_${now}_${n}_$stem';
    }
    await File('${folder.path}/$name').writeAsBytes(bytes, flush: true);

    final id = Uuid.v7();
    final author = await _currentUser.currentOrSystem();
    await _db.transaction(() async {
      await _db
          .into(_db.documentationFiles)
          .insert(
            DocumentationFilesCompanion.insert(
              uuid: id,
              title: copy.title,
              fileName: '$storageSubDir/$name',
              fileSize: bytes.length,
              fileType: copy.fileType,
            ).copyWith(
              description: Value(copy.description),
              fileHash: Value(sha256.convert(bytes).toString()),
              createdAt: Value(now),
              updatedAt: Value(now),
              createdByUserUuid: Value(author),
            ),
          );
      await _logger.logInsert('documentation_files', id);

      final features =
          await (_db.select(_db.documentationFilesToGeofeatures)..where(
                (t) =>
                    t.documentationFileUuid.equalsValue(copy.uuid) &
                    t.deletedAt.isNull(),
              ))
              .get();
      for (final link in features) {
        final linkId = Uuid.v7();
        await _db
            .into(_db.documentationFilesToGeofeatures)
            .insert(
              DocumentationFilesToGeofeaturesCompanion.insert(
                uuid: linkId,
                geofeatureType: link.geofeatureType,
                documentationFileUuid: id,
                geofeatureUuid: Value(link.geofeatureUuid),
                createdAt: Value(now),
                updatedAt: Value(now),
                createdByUserUuid: Value(author),
              ),
            );
        await _logger.logInsert('documentation_files_to_geofeatures', linkId);
      }

      final trips =
          await (_db.select(_db.documentationFilesToCaveTrips)..where(
                (t) =>
                    t.documentationFileUuid.equalsValue(copy.uuid) &
                    t.deletedAt.isNull(),
              ))
              .get();
      for (final link in trips) {
        final linkId = Uuid.v7();
        await _db
            .into(_db.documentationFilesToCaveTrips)
            .insert(
              DocumentationFilesToCaveTripsCompanion.insert(
                uuid: linkId,
                documentationFileUuid: id,
                caveTripUuid: link.caveTripUuid,
                createdAt: Value(now),
                createdByUserUuid: Value(author),
              ),
            );
        await _logger.logInsert('documentation_files_to_cave_trips', linkId);
      }
    });
    return id;
  }
}
