import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleo_loc/data/source/database/app_database.dart';

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

  /// Returns a canonical file-type string (used in `documentation_files.file_type`)
  /// based on the file extension.
  static String detectFileType(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final ext = dot >= 0 ? fileName.substring(dot + 1).toLowerCase() : '';
    if (['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp', 'heic'].contains(ext)) {
      return 'photo';
    }
    if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) return 'video';
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

  // -----------------------------------------------------------------------
  //  Save a picked / external file  (copy into app storage)
  // -----------------------------------------------------------------------

  /// Copies [sourceFile] into the documentation storage folder and returns a
  /// [SavedFileInfo] with everything needed for DB insertion.
  static Future<SavedFileInfo> saveExternalFile(File sourceFile) async {
    final folder = await getStorageFolder();
    final baseName =
        sourceFile.path.split(Platform.pathSeparator).last;
    final outName = 'doc_${DateTime.now().millisecondsSinceEpoch}_$baseName';
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
    final outName = 'doc_${DateTime.now().millisecondsSinceEpoch}_$baseName';
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
    return saveBytes(baseName: baseName, bytes: Uint8List.fromList(utf8.encode(content)));
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
  static Future<int> insertRecord({
    required String title,
    String? description,
    required SavedFileInfo savedFile,
    String? fileType,
    DocumentationGeofeatureLink? parentLink,
  }) async {
    final effectiveType =
        fileType ?? detectFileType(savedFile.relativePath);

    print(  '[DocumentationFileHelper] Inserting record: title="$title", file="${savedFile.relativePath}", size=${savedFile.fileSize}, hash=${savedFile.fileHash}, type=$effectiveType, parentLink=${parentLink != null ? 'geofeatureId=${parentLink.geofeatureId}' : 'none'}');
    final companion = DocumentationFilesCompanion.insert(
      title: title,
      fileName: savedFile.relativePath,
      fileSize: savedFile.fileSize,
      fileType: effectiveType,
    ).copyWith(
      description: drift.Value(description),
      fileHash: drift.Value(savedFile.fileHash),
      createdAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
    );

    return appDatabase.insertDocumentationFile(
      companion: companion,
      parentLink: parentLink,
    );
  }

  // -----------------------------------------------------------------------
  //  DB update (existing record)
  // -----------------------------------------------------------------------

  /// Updates an existing documentation-file DB record with new file metadata
  /// and/or title. Used when editing a document in-place.
  static Future<void> updateRecord({
    required int id,
    required String title,
    String? description,
    required SavedFileInfo savedFile,
  }) async {
    final companion = DocumentationFilesCompanion(
      title: drift.Value(title),
      description: drift.Value(description),
      fileName: drift.Value(savedFile.relativePath),
      fileSize: drift.Value(savedFile.fileSize),
      fileHash: drift.Value(savedFile.fileHash),
      updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
    );

    await appDatabase.updateDocumentationFile(id: id, companion: companion);
  }

  // -----------------------------------------------------------------------
  //  Duplicate check
  // -----------------------------------------------------------------------

  /// Returns matching documentation files that share the same size+hash.
  static Future<List<DocumentationFile>> findDuplicates({
    required int fileSize,
    required String fileHash,
  }) async {
    return (appDatabase.select(appDatabase.documentationFiles)
          ..where((t) =>
              t.fileSize.equals(fileSize) & t.fileHash.equals(fileHash)))
        .get();
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
