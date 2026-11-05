import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/utils/clock.dart';
import 'package:speleoloc/utils/contained_path.dart';

/// Says whether a documentation file is a copy that must never take new
/// content in place.
abstract interface class DocumentationCopyRegister {
  /// True for a copy a server handed down that is not the file itself — a
  /// picture without its location, or one the server drew smaller.
  Future<bool> isServerOnlyCopy(Uuid documentUuid);
}

/// Saves new content an editor made of a documentation file.
///
/// The caver's own file, or the server's stored one, takes the content as a
/// new revision of the same document. A copy that is not the file itself
/// becomes the starting point of a **new** document instead, hung wherever
/// the copy hangs, and the copy is left as it was: a 480 px picture, or one
/// stripped of its position, edited and sent up as the next revision of the
/// document would replace a full-size original on the server for every
/// reader.
///
/// A revision is written under a fresh storage name and the row is pointed
/// at it, never written over the old name. Archive sync treats a stored file
/// as fixed for its name and only copies names a phone does not have yet, so
/// new bytes under the old name would never reach a phone holding the
/// earlier version, while its row took the new hash.
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

  /// Saves [bytes] as the new content of [document], and [title] as its
  /// title when given. Returns the identifier of the documentation file that
  /// now holds them.
  Future<Uuid> save(
    DocumentationFile document,
    Uint8List bytes, {
    String? title,
  }) async {
    if (await _copies.isServerOnlyCopy(document.uuid)) {
      return _saveAsNew(document, bytes, title: title);
    }
    await _saveRevision(document, bytes, title: title);
    return document.uuid;
  }

  Future<void> _saveRevision(
    DocumentationFile document,
    Uint8List bytes, {
    String? title,
  }) async {
    final base = await _baseDir();
    final oldPath = containedDocumentsPath(base.path, document.fileName);
    if (oldPath == null) {
      throw FileSystemException(
        'documentation file name leaves the documents folder',
        document.fileName,
      );
    }
    final fileName = await _writeUnderFreshName(base, document, bytes);
    final hash = sha256.convert(bytes).toString();
    final author = await _currentUser.currentOrSystem();
    final retitled = title != null && title != document.title;
    var committed = false;
    try {
      await _db.transaction(() async {
        await (_db.update(
          _db.documentationFiles,
        )..where((t) => t.uuid.equalsValue(document.uuid))).write(
          DocumentationFilesCompanion(
            title: retitled ? Value(title) : const Value.absent(),
            fileName: Value(fileName),
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
            if (retitled) 'title': document.title,
            'file_name': document.fileName,
            'file_size': document.fileSize,
            'file_hash': document.fileHash,
          },
          newValues: <String, Object?>{
            if (retitled) 'title': title,
            'file_name': fileName,
            'file_size': bytes.length,
            'file_hash': hash,
          },
        );
      });
      committed = true;
    } finally {
      if (!committed) await _deleteQuietly(File('${base.path}/$fileName'));
    }
    await _deleteIfUnreferenced(File(oldPath), document.fileName);
  }

  /// Writes [bytes] into the storage folder under a name no file has yet,
  /// keeping the name the caver gave [document]. Returns the relative path.
  Future<String> _writeUnderFreshName(
    Directory base,
    DocumentationFile document,
    Uint8List bytes,
  ) async {
    final folder = Directory('${base.path}/$storageSubDir');
    await folder.create(recursive: true);
    final now = _clock.nowMs();
    final stem = document.fileName
        .split('/')
        .last
        .replaceFirst(RegExp(r'^(doc|srv)_\d+_(\d+_)?'), '');
    var name = 'doc_${now}_$stem';
    for (var n = 1; await File('${folder.path}/$name').exists(); n++) {
      name = 'doc_${now}_${n}_$stem';
    }
    await File('${folder.path}/$name').writeAsBytes(bytes, flush: true);
    return '$storageSubDir/$name';
  }

  /// Removes the file a revision replaced, unless another live row still
  /// names it (two records can share one stored file after a merge).
  Future<void> _deleteIfUnreferenced(File file, String fileName) async {
    final others = await (_db.select(
      _db.documentationFiles,
    )..where((t) => t.fileName.equals(fileName) & t.deletedAt.isNull())).get();
    if (others.isNotEmpty) return;
    await _deleteQuietly(file);
  }

  // The new content is already saved or abandoned; a file left behind only
  // takes space, so a failed delete is not worth failing the save over.
  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      return;
    }
  }

  Future<Uuid> _saveAsNew(
    DocumentationFile copy,
    Uint8List bytes, {
    String? title,
  }) async {
    final base = await _baseDir();
    final fileName = await _writeUnderFreshName(base, copy, bytes);
    final now = _clock.nowMs();

    final id = Uuid.v7();
    final author = await _currentUser.currentOrSystem();
    await _db.transaction(() async {
      await _db
          .into(_db.documentationFiles)
          .insert(
            DocumentationFilesCompanion.insert(
              uuid: id,
              title: title ?? copy.title,
              fileName: fileName,
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
