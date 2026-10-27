import 'dart:io';

import 'package:speleoloc/services/silexgis/model/sync_file_links.dart';

/// Where fetched files are written: under the documentation storage folder,
/// always under a new name.
///
/// A fetch lands in a partial file first, named by the document, its revision
/// and the form asked for, so a dropped fetch resumes into the same file and
/// a new revision never resumes into an old one. Only a verified file is moved
/// into the folder, and never over a file already there.
class SilexgisDocumentFileStore {
  SilexgisDocumentFileStore({required Future<Directory> Function() baseDir})
    : _baseDir = baseDir;

  /// The app documents directory, which stored paths are relative to.
  final Future<Directory> Function() _baseDir;

  /// The folder every documentation file lives in, relative to the base.
  static const String storageSubDir = 'documentation_files';
  static const String _partialSubDir = '.silexgis_partial';

  Future<File> partialFile(
    String documentId,
    String? versionId,
    SyncRendition rendition,
  ) async {
    final base = await _baseDir();
    final name = _safe('${documentId}_${versionId ?? 'current'}_$rendition');
    return File('${base.path}/$storageSubDir/$_partialSubDir/$name.part');
  }

  /// Moves [partial] into the storage folder under a name made from
  /// [baseName], and returns its path relative to the base directory.
  Future<String> commit(File partial, String baseName) async {
    final base = await _baseDir();
    final folder = Directory('${base.path}/$storageSubDir');
    await folder.create(recursive: true);
    final ms = DateTime.now().millisecondsSinceEpoch;
    final stem = _safe(baseName);
    var name = 'srv_${ms}_$stem';
    var n = 1;
    while (await File('${folder.path}/$name').exists()) {
      name = 'srv_${ms}_${n}_$stem';
      n++;
    }
    await partial.rename('${folder.path}/$name');
    return '$storageSubDir/$name';
  }

  /// Removes what a failed fetch left behind.
  Future<void> discard(File partial) async {
    if (await partial.exists()) await partial.delete();
  }

  /// The file name a fetched document is stored under: its title, with the
  /// extension its type implies when the title has none, and the size for a
  /// picture the server drew.
  static String fileNameFor({
    required String title,
    required String? mimeType,
    required SyncRendition rendition,
  }) {
    final extension = extensionFor(mimeType);
    var stem = title.trim();
    var ext = '';
    final dot = stem.lastIndexOf('.');
    if (dot > 0 && stem.length - dot <= 6) {
      ext = stem.substring(dot);
      stem = stem.substring(0, dot);
    }
    if (ext.isEmpty && extension != null) ext = '.$extension';
    if (!rendition.isOriginal) {
      stem = '${stem}_${rendition.size}';
      // A drawn picture is an image whatever the original was.
      if (extension != null) ext = '.$extension';
    }
    if (stem.isEmpty) stem = 'document';
    if (stem.length > 80) stem = stem.substring(0, 80);
    return '$stem$ext';
  }

  /// The usual extension for [mimeType], or null for one not known here.
  static String? extensionFor(String? mimeType) {
    final type = mimeType?.split(';').first.trim().toLowerCase();
    return switch (type) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/gif' => 'gif',
      'image/heic' => 'heic',
      'video/mp4' => 'mp4',
      'video/quicktime' => 'mov',
      'audio/mpeg' => 'mp3',
      'audio/mp4' => 'm4a',
      'audio/wav' || 'audio/x-wav' || 'audio/wave' => 'wav',
      'audio/ogg' => 'ogg',
      'application/pdf' => 'pdf',
      'text/plain' => 'txt',
      'text/markdown' => 'md',
      _ => null,
    };
  }

  static String _safe(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
}
