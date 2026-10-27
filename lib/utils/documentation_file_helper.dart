import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/image_compression_settings.dart';
import 'package:speleoloc/utils/image_compressor.dart';

/// Shared helper for documentation file storage, hashing, and DB insertion.
///
/// Used by [EditDocumentationFilePage], [TextDocumentEditorPage], and any
/// future editor screens that need to persist documentation files.
class DocumentationFileHelper {
  DocumentationFileHelper._();

  /// Sub-directory inside the app documents folder where documentation files
  /// are stored.
  static const String storageSubDir = 'documentation_files';

  // -----------------------------------------------------------------------
  //  File type detection
  // -----------------------------------------------------------------------

  /// Extensions stored as `video`, without the dot.
  ///
  /// The one list: the type detection, the video viewer's registration and
  /// the media import's picker all read it. They used to keep their own,
  /// and a phone's `.3gp` or an exported `.m4v` was recognised as a video
  /// by the picker and then stored as `unknown`.
  static const Set<String> videoExtensions = {
    'mp4',
    'mov',
    'm4v',
    '3gp',
    'avi',
    'mkv',
    'webm',
  };

  /// Returns a canonical file-type string (used in `documentation_files.file_type`)
  /// based on the file extension.
  static String detectFileType(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final ext = dot >= 0 ? fileName.substring(dot + 1).toLowerCase() : '';
    if (['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp', 'heic'].contains(ext)) {
      return 'photo';
    }
    if (videoExtensions.contains(ext)) return 'video';
    if (['mp3', 'wav', 'ogg', 'm4a', 'flac'].contains(ext)) return 'audio';
    if (['txt', 'rtf', 'doc', 'docx', 'odt', 'pdf', 'md'].contains(ext)) {
      return 'text_document';
    }
    return 'unknown';
  }

  // -----------------------------------------------------------------------
  //  SHA-256
  // -----------------------------------------------------------------------

  /// Compute SHA-256 hex string from raw bytes.
  static String computeSha256(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  // -----------------------------------------------------------------------
  //  Storage folder
  // -----------------------------------------------------------------------

  /// Returns the absolute path to the documentation-files storage folder,
  /// creating it if it doesn't yet exist.
  static Future<Directory> getStorageFolder() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/$storageSubDir');
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder;
  }

  /// Builds a storage file name inside [folder] that does not yet exist.
  ///
  /// The millisecond timestamp is not unique on its own when many files are
  /// saved back-to-back (e.g. bulk import): two identically-named sources in
  /// the same millisecond would map to one path and clobber each other. A
  /// numeric suffix disambiguates that collision. Callers must save the file
  /// synchronously (relative to the event loop) after this returns so the
  /// reserved name isn't reused.
  static String _uniqueStorageName(Directory folder, String baseName) {
    final ms = DateTime.now().millisecondsSinceEpoch;
    var candidate = 'doc_${ms}_$baseName';
    var n = 1;
    while (File('${folder.path}/$candidate').existsSync()) {
      candidate = 'doc_${ms}_${n}_$baseName';
      n++;
    }
    return candidate;
  }

  // -----------------------------------------------------------------------
  //  Save a picked / external file  (copy into app storage)
  // -----------------------------------------------------------------------

  /// Copies [sourceFile] into the documentation storage folder and returns a
  /// [SavedFileInfo] with everything needed for DB insertion.
  static Future<SavedFileInfo> saveExternalFile(File sourceFile) async {
    final folder = await getStorageFolder();
    final baseName = sourceFile.path.split(Platform.pathSeparator).last;
    final outName = _uniqueStorageName(folder, baseName);
    final outPath = '${folder.path}/$outName';
    await sourceFile.copy(outPath);

    final outFile = File(outPath);
    final bytes = await outFile.readAsBytes();
    final fileSize = bytes.length;
    final fileHash = computeSha256(bytes);
    final relativePath = '$storageSubDir/$outName';

    return SavedFileInfo(
      relativePath: relativePath,
      absolutePath: outPath,
      fileSize: fileSize,
      fileHash: fileHash,
    );
  }

  /// Compresses the stored copy described by [info] and returns the info of
  /// what is on disk afterwards.
  ///
  /// Only ever pass a file already inside app storage (the result of
  /// [saveExternalFile]): the caver's original stays as picked. Compression
  /// writes JPEG, so a copy named `.png` or `.webp` is renamed to `.jpg`;
  /// otherwise its name would promise a format the bytes no longer have.
  /// A disabled setting or an undecodable file returns [info] unchanged.
  static Future<SavedFileInfo> compressStoredPhoto(
    SavedFileInfo info,
    ImageCompressionSettings settings,
  ) async {
    final file = File(info.absolutePath);
    final compressed = ImageCompressor.compressBytes(
      await file.readAsBytes(),
      settings,
    );
    if (compressed == null) return info;
    await file.writeAsBytes(compressed, flush: true);

    var absolutePath = info.absolutePath;
    var relativePath = info.relativePath;
    final dot = absolutePath.lastIndexOf('.');
    final ext = dot >= 0 ? absolutePath.substring(dot + 1).toLowerCase() : '';
    if (ext != 'jpg' && ext != 'jpeg') {
      final stem = dot >= 0 ? absolutePath.substring(0, dot) : absolutePath;
      var target = '$stem.jpg';
      var n = 1;
      while (File(target).existsSync()) {
        target = '${stem}_$n.jpg';
        n++;
      }
      await file.rename(target);
      absolutePath = target;
      relativePath =
          '$storageSubDir/${target.split(Platform.pathSeparator).last}';
    }
    return SavedFileInfo(
      relativePath: relativePath,
      absolutePath: absolutePath,
      fileSize: compressed.length,
      fileHash: computeSha256(compressed),
    );
  }

  // -----------------------------------------------------------------------
  //  Save in-memory content (e.g. from text editor)
  // -----------------------------------------------------------------------

  /// Writes [bytes] to a new file inside the documentation storage folder and
  /// returns a [SavedFileInfo].
  ///
  /// [baseName] is the display file name (e.g. `my_notes.txt`).
  static Future<SavedFileInfo> saveBytes({
    required String baseName,
    required Uint8List bytes,
  }) async {
    final folder = await getStorageFolder();
    final outName = _uniqueStorageName(folder, baseName);
    final outPath = '${folder.path}/$outName';
    await File(outPath).writeAsBytes(bytes, flush: true);

    return SavedFileInfo(
      relativePath: '$storageSubDir/$outName',
      absolutePath: outPath,
      fileSize: bytes.length,
      fileHash: computeSha256(bytes),
    );
  }

  /// Convenience wrapper around [saveBytes] for plain UTF-8 text content.
  static Future<SavedFileInfo> saveText({
    required String baseName,
    required String content,
  }) {
    return saveBytes(
      baseName: baseName,
      bytes: Uint8List.fromList(utf8.encode(content)),
    );
  }

  /// Overwrites the content of an **existing** file identified by its
  /// [relativePath] (as stored in the DB) and returns updated [SavedFileInfo].
  static Future<SavedFileInfo> overwriteText({
    required String relativePath,
    required String content,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final absPath = '${dir.path}/$relativePath';
    final bytes = Uint8List.fromList(utf8.encode(content));
    await File(absPath).writeAsBytes(bytes, flush: true);
    return SavedFileInfo(
      relativePath: relativePath,
      absolutePath: absPath,
      fileSize: bytes.length,
      fileHash: computeSha256(bytes),
    );
  }

  /// Overwrites an existing file with raw [bytes] and returns updated
  /// [SavedFileInfo].  Used by image / audio editors that produce binary data.
  static Future<SavedFileInfo> overwriteBytes({
    required String relativePath,
    required Uint8List bytes,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final absPath = '${dir.path}/$relativePath';
    await File(absPath).writeAsBytes(bytes, flush: true);
    return SavedFileInfo(
      relativePath: relativePath,
      absolutePath: absPath,
      fileSize: bytes.length,
      fileHash: computeSha256(bytes),
    );
  }

  // -----------------------------------------------------------------------
  //  DB insertion (new record)
  // -----------------------------------------------------------------------

  /// Creates the DB record and optional geofeature link in a single
  /// transaction. Returns the newly inserted row id.
  ///
  /// [title] and [description] are the user-facing metadata.
  /// [savedFile] comes from one of the `save*` helpers above.
  /// [parentLink] connects the file to a cave / cave-place / cave-area.
  static Future<Uuid> insertRecord({
    required String title,
    String? description,
    required SavedFileInfo savedFile,
    String? fileType,
    DocumentationGeofeatureLink? parentLink,
    String? textContent,
  }) async {
    final effectiveType = fileType ?? detectFileType(savedFile.relativePath);

    AppLogger.of('DocumentationFileHelper').fine(
      'Inserting record: title="$title", file="${savedFile.relativePath}", size=${savedFile.fileSize}, hash=${savedFile.fileHash}, type=$effectiveType, parentLink=${parentLink != null ? 'geofeatureUuid=${parentLink.geofeatureUuid}' : 'none'}',
    );
    final companion =
        DocumentationFilesCompanion.insert(
          uuid: Uuid.v7(),
          title: title,
          fileName: savedFile.relativePath,
          fileSize: savedFile.fileSize,
          fileType: effectiveType,
        ).copyWith(
          description: drift.Value(description),
          fileHash: drift.Value(savedFile.fileHash),
          createdAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
        );

    final docId = await documentationRepository.insertDocumentationFile(
      companion: companion,
      parentLink: parentLink,
    );
    await changeLogger.logInsert('documentation_files', docId);
    await caveTripService.linkDocument(
      docId,
      documentTitle: title,
      textContent: textContent,
    );
    return docId;
  }

  // -----------------------------------------------------------------------
  //  DB update (existing record)
  // -----------------------------------------------------------------------

  /// Updates an existing documentation-file DB record with new file metadata
  /// and/or title. Used when editing a document in-place.
  static Future<void> updateRecord({
    required Uuid id,
    required String title,
    String? description,
    required SavedFileInfo savedFile,
  }) async {
    final old = await documentationRepository.findById(id);
    final author = await currentUserService.currentOrSystem();
    final companion = DocumentationFilesCompanion(
      uuid: drift.Value(id),
      title: drift.Value(title),
      description: drift.Value(description),
      fileName: drift.Value(savedFile.relativePath),
      fileSize: drift.Value(savedFile.fileSize),
      fileHash: drift.Value(savedFile.fileHash),
      updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
      lastModifiedByUserUuid: drift.Value(author),
    );

    await documentationRepository.updateDocumentationFile(
      uuid: id,
      companion: companion,
    );
    if (old != null) {
      await changeLogger.logUpdate(
        'documentation_files',
        id,
        oldValues: {
          'title': old.title,
          'description': old.description,
          'file_name': old.fileName,
          'file_size': old.fileSize,
          'file_hash': old.fileHash,
        },
        newValues: {
          'title': title,
          'description': description,
          'file_name': savedFile.relativePath,
          'file_size': savedFile.fileSize,
          'file_hash': savedFile.fileHash,
        },
      );
    }
  }

  // -----------------------------------------------------------------------
  //  Duplicate check
  // -----------------------------------------------------------------------

  /// Returns matching documentation files that share the same size+hash.
  static Future<List<DocumentationFile>> findDuplicates({
    required int fileSize,
    required String fileHash,
  }) async {
    return documentationRepository.findDuplicates(
      fileSize: fileSize,
      fileHash: fileHash,
    );
  }
}

// ---------------------------------------------------------------------------
//  SavedFileInfo  –  result of saving a file to the storage folder
// ---------------------------------------------------------------------------

/// Lightweight result object returned by [DocumentationFileHelper.saveExternalFile]
/// and [DocumentationFileHelper.saveBytes].
class SavedFileInfo {
  const SavedFileInfo({
    required this.relativePath,
    required this.absolutePath,
    required this.fileSize,
    required this.fileHash,
  });

  /// Path relative to the app documents directory (stored in DB).
  final String relativePath;

  /// Absolute path on disk.
  final String absolutePath;

  /// File size in bytes.
  final int fileSize;

  /// SHA-256 hex hash of the file content.
  final String fileHash;
}
