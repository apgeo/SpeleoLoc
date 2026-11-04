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
  /// extension its type implies, and the size for a picture the server drew.
  ///
  /// A title's own suffix is kept only when it looks like an extension and
  /// agrees with the type: the viewer is chosen by the name's extension alone,
  /// and a title such as "Topo v2.3" or "Plan 1.500" ends in a version or a
  /// scale, not in one.
  static String fileNameFor({
    required String title,
    required String? mimeType,
    required SyncRendition rendition,
  }) {
    final extension = extensionFor(mimeType);
    var stem = title.trim();
    var ext = '';
    final suffix = _titleExtension(stem);
    if (suffix != null &&
        (extension == null ||
            !rendition.isOriginal ||
            _sameType(suffix, extension))) {
      ext = '.$suffix';
      stem = stem.substring(0, stem.length - ext.length);
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

  /// What follows a title's last dot when it could be an extension: a few
  /// letters or digits, at least one of them a letter.
  static String? _titleExtension(String title) {
    final dot = title.lastIndexOf('.');
    if (dot <= 0) return null;
    final suffix = title.substring(dot + 1);
    final shaped = RegExp(r'^[A-Za-z0-9]{1,5}$').hasMatch(suffix);
    final named = RegExp('[A-Za-z]').hasMatch(suffix);
    return shaped && named ? suffix : null;
  }

  /// Whether [suffix] names the same type as the usual [extension].
  static bool _sameType(String suffix, String extension) {
    final lower = suffix.toLowerCase();
    return lower == extension ||
        (_spellings[extension]?.contains(lower) ?? false);
  }

  static const Map<String, Set<String>> _spellings = <String, Set<String>>{
    'jpg': <String>{'jpeg', 'jpe'},
    'heic': <String>{'heif'},
    'mov': <String>{'qt'},
    'mp4': <String>{'m4v'},
    'txt': <String>{'text'},
  };

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
