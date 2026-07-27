import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/documentation_file_helper.dart';
import 'package:speleoloc/utils/image_compression_settings.dart';
import 'package:speleoloc/utils/image_compressor.dart';

/// Per-directory outcome of a bulk cave-document import.
class CaveDirImportOutcome {
  int imported = 0;
  int skippedDuplicates = 0;
  int failed = 0;

  int get processed => imported + skippedDuplicates + failed;
}

/// Bulk-attaches files to a geofeature (cave / cave place / cave area), reusing
/// the same storage, hashing and compression rules as the interactive
/// single-file importer.
///
/// UI-free by design; callers ([CaveDocumentImportPage] for the per-cave
/// directory import, and the documents page for multi-file selection) resolve
/// the target link and this service performs the copy + insert.
class CaveDocumentImportService {
  CaveDocumentImportService(this._docRepo, this._changeLogger);

  final IDocumentationRepository _docRepo;
  final ChangeLogger _changeLogger;
  final _log = AppLogger.of('CaveDocumentImportService');

  /// Immediate, non-hidden regular files inside [dir], sorted by name.
  ///
  /// Non-recursive: only the files directly under the cave's subdirectory are
  /// imported, matching the "one subdirectory of files per cave" layout.
  List<File> listImportableFiles(Directory dir) {
    try {
      if (!dir.existsSync()) return const [];
      final files = dir
          .listSync(followLinks: false)
          .whereType<File>()
          .where((f) => !_baseName(f.path).startsWith('.'))
          .toList();
      files.sort(
        (a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()),
      );
      return files;
    } catch (e, st) {
      // A permission-denied on one subdirectory (Android scoped storage)
      // must degrade to an empty row, not abort the whole scan.
      _log.warning('Could not list ${dir.path}', e, st);
      return const [];
    }
  }

  /// Imports [files] into the geofeature identified by [link], attaching each
  /// via that link. Files whose stored size+hash already match a document
  /// linked to the same geofeature are skipped, so re-running is idempotent.
  ///
  /// [onFileDone] fires once per processed file (for progress reporting).
  Future<CaveDirImportOutcome> importFilesToGeofeature({
    required DocumentationGeofeatureLink link,
    required List<File> files,
    required bool compressImages,
    void Function()? onFileDone,
  }) async {
    final outcome = CaveDirImportOutcome();

    // Snapshot the (size, hash) of documents already attached to this
    // geofeature so repeated imports don't create duplicate rows.
    final existingKeys = <String>{};
    try {
      final existing = await _docRepo.getDocumentationFiles(parentLink: link);
      for (final d in existing) {
        if (d.fileHash != null) existingKeys.add('${d.fileSize}:${d.fileHash}');
      }
    } catch (e, st) {
      _log.warning(
        'Could not load existing docs for ${link.type.dbValue} '
        '${link.geofeatureUuid}',
        e,
        st,
      );
    }

    final compressionSettings = compressImages
        ? await ImageCompressionSettings.load()
        : null;

    for (final file in files) {
      try {
        // Always copy into app storage first; the user's original files are
        // never modified (compression happens on the stored copy only).
        var info = await DocumentationFileHelper.saveExternalFile(file);
        final fileType = DocumentationFileHelper.detectFileType(
          info.relativePath,
        );

        if (fileType == 'photo' &&
            compressionSettings != null &&
            compressionSettings.enabled) {
          await ImageCompressor.compressFile(
            File(info.absolutePath),
            compressionSettings,
          );
          info = await _refreshFileInfo(info);
        }

        final key = '${info.fileSize}:${info.fileHash}';
        if (existingKeys.contains(key)) {
          await _deleteQuietly(info.absolutePath);
          outcome.skippedDuplicates++;
          continue;
        }
        existingKeys.add(key);

        final companion =
            DocumentationFilesCompanion.insert(
              uuid: Uuid.v7(),
              title: _titleFromFileName(_baseName(file.path)),
              fileName: info.relativePath,
              fileSize: info.fileSize,
              fileType: fileType,
            ).copyWith(
              fileHash: drift.Value(info.fileHash),
              createdAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
            );

        final docUuid = await _docRepo.insertDocumentationFile(
          companion: companion,
          parentLink: link,
        );
        await _changeLogger.logInsert('documentation_files', docUuid);
        outcome.imported++;
      } catch (e, st) {
        _log.warning('Failed to import ${file.path}', e, st);
        outcome.failed++;
      } finally {
        onFileDone?.call();
      }
    }
    return outcome;
  }

  Future<SavedFileInfo> _refreshFileInfo(SavedFileInfo info) async {
    final bytes = await File(info.absolutePath).readAsBytes();
    return SavedFileInfo(
      relativePath: info.relativePath,
      absolutePath: info.absolutePath,
      fileSize: bytes.length,
      fileHash: DocumentationFileHelper.computeSha256(bytes),
    );
  }

  Future<void> _deleteQuietly(String absolutePath) async {
    try {
      final f = File(absolutePath);
      if (await f.exists()) await f.delete();
    } catch (e, st) {
      _log.warning('Could not remove duplicate copy $absolutePath', e, st);
    }
  }

  static String _baseName(String path) =>
      path.split(Platform.pathSeparator).last;

  static String _titleFromFileName(String baseName) {
    final dot = baseName.lastIndexOf('.');
    final stem = dot > 0 ? baseName.substring(0, dot) : baseName;
    return stem.isEmpty ? baseName : stem;
  }
}
