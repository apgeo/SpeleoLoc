import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:speleoloc/services/storage/saf_storage_service.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// A subdirectory of the user-picked bulk-import root, holding the files for
/// one cave.
abstract interface class ImportDirectory {
  String get name;

  /// Immediate, non-hidden regular files inside the directory, sorted by
  /// name. Errors degrade to an empty list so one unreadable subdirectory
  /// never aborts the whole scan.
  Future<List<ImportableFile>> listFiles();
}

/// A file inside an [ImportDirectory].
abstract interface class ImportableFile {
  String get name;

  /// Returns the content as a local `dart:io` file, copying into [tempDir]
  /// when the source is not directly path-addressable (SAF documents).
  Future<File> materialize(Directory tempDir);
}

/// The user-picked import root and its immediate subdirectories.
class ImportRoot {
  const ImportRoot({required this.name, required this.directories});

  /// User-facing location label (a path on desktop, a folder name on
  /// Android).
  final String name;
  final List<ImportDirectory> directories;
}

/// Lets the user pick the bulk-import root folder.
///
/// Android goes through SAF (the folder picker itself grants read access to
/// the whole tree — media and non-media files alike, no storage permission);
/// other platforms keep the plain `dart:io` directory walk.
class DocumentImportSourcePicker {
  const DocumentImportSourcePicker();

  Future<ImportRoot?> pick({String? dialogTitle}) async {
    if (Platform.isAndroid) {
      const saf = SafStorageService();
      final picked = await saf.pickDirectory();
      if (picked == null) return null;
      final children = await saf.listChildren(picked.treeUri);
      final dirs = [
        for (final entry in children)
          if (entry.isDirectory)
            _SafImportDirectory(saf, picked.treeUri, entry),
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return ImportRoot(name: picked.name, directories: dirs);
    }

    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: dialogTitle,
    );
    if (path == null) return null;
    final subdirs = Directory(path)
        .listSync(followLinks: false)
        .whereType<Directory>()
        .map(_IoImportDirectory.new)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return ImportRoot(name: path, directories: subdirs);
  }
}

// ---------------------------------------------------------------------------
//  dart:io implementation (desktop)
// ---------------------------------------------------------------------------

class _IoImportDirectory implements ImportDirectory {
  _IoImportDirectory(this._dir);

  final Directory _dir;
  static final _log = AppLogger.of('DocumentImportSource');

  @override
  String get name {
    final parts = _dir.path.split(Platform.pathSeparator)
      ..removeWhere((s) => s.isEmpty);
    return parts.isEmpty ? _dir.path : parts.last;
  }

  @override
  Future<List<ImportableFile>> listFiles() async {
    try {
      if (!_dir.existsSync()) return const [];
      final files = _dir
          .listSync(followLinks: false)
          .whereType<File>()
          .where((f) => !_baseName(f.path).startsWith('.'))
          .toList()
        ..sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
      return [for (final f in files) _IoImportableFile(f)];
    } catch (e, st) {
      _log.warning('Could not list ${_dir.path}', e, st);
      return const [];
    }
  }

  static String _baseName(String path) =>
      path.split(Platform.pathSeparator).last;
}

class _IoImportableFile implements ImportableFile {
  _IoImportableFile(this._file);

  final File _file;

  @override
  String get name => _IoImportDirectory._baseName(_file.path);

  @override
  Future<File> materialize(Directory tempDir) async => _file;
}

// ---------------------------------------------------------------------------
//  SAF implementation (Android)
// ---------------------------------------------------------------------------

class _SafImportDirectory implements ImportDirectory {
  _SafImportDirectory(this._saf, this._treeUri, this._entry);

  final SafStorageService _saf;
  final String _treeUri;
  final SafEntry _entry;
  static final _log = AppLogger.of('DocumentImportSource');

  @override
  String get name => _entry.name;

  @override
  Future<List<ImportableFile>> listFiles() async {
    try {
      final children = await _saf.listChildren(
        _treeUri,
        documentId: _entry.documentId,
      );
      final files = [
        for (final child in children)
          if (!child.isDirectory && !child.name.startsWith('.'))
            _SafImportableFile(_saf, _treeUri, child),
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return files;
    } catch (e, st) {
      _log.warning('Could not list SAF directory ${_entry.name}', e, st);
      return const [];
    }
  }
}

class _SafImportableFile implements ImportableFile {
  _SafImportableFile(this._saf, this._treeUri, this._entry);

  final SafStorageService _saf;
  final String _treeUri;
  final SafEntry _entry;

  @override
  String get name => _entry.name;

  @override
  Future<File> materialize(Directory tempDir) async {
    // Keep the original file name — the import derives document titles from
    // it; each row materializes into its own temp directory, so names from
    // the same source directory cannot collide.
    final dest = File('${tempDir.path}${Platform.pathSeparator}${_entry.name}');
    await _saf.copyToFile(
      treeUri: _treeUri,
      documentId: _entry.documentId,
      destPath: dest.path,
    );
    return dest;
  }
}
