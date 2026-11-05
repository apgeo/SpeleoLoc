import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/storage/saf_storage_service.dart';

/// Thrown when there is no database file to export yet.
class DatabaseFileMissingException implements Exception {
  const DatabaseFileMissingException();

  @override
  String toString() => 'DatabaseFileMissingException: no database file';
}

/// Saves a copy of the raw database file wherever the caver picks — the
/// snapshot a restore expects back, and the way to keep data a start-up
/// failure has made unreachable.
class DatabaseFileExportService {
  const DatabaseFileExportService();

  static const String exportFileName = 'speleo_loc_export.sqlite';

  /// Saves a consistent copy of the open [database], like [export].
  ///
  /// Copying the file of a database in use can catch it between the pages
  /// of a transaction, and the copy then holds half of it or is damaged. A
  /// snapshot taken through the connection waits for the transaction and
  /// copies what it committed.
  Future<String?> exportSnapshot(
    AppDatabase database, {
    required String folderDialogTitle,
    required String saveDialogTitle,
  }) async {
    final dir = await Directory.systemTemp.createTemp('speleo_loc_export_');
    try {
      final snapshot = File(p.join(dir.path, exportFileName));
      await writeSnapshot(database, snapshot);
      return await export(
        snapshot,
        folderDialogTitle: folderDialogTitle,
        saveDialogTitle: saveDialogTitle,
      );
    } finally {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        // A leftover in the temporary directory is the system's to clear.
      }
    }
  }

  /// Writes a consistent copy of [database] to [target], replacing any file
  /// there.
  Future<void> writeSnapshot(AppDatabase database, File target) async {
    await target.parent.create(recursive: true);
    // VACUUM INTO refuses a target that already holds data.
    if (await target.exists()) await target.delete();
    await database.customStatement('VACUUM INTO ?', [target.path]);
  }

  /// Saves a copy of the file [source]. For a database nothing has open,
  /// such as after a failed start; an open one goes through
  /// [exportSnapshot].
  ///
  /// Returns where the copy went, or null when the caver cancelled. The
  /// dialog titles are for the folder picker (iOS) and the save dialog
  /// (desktop). Throws [DatabaseFileMissingException] when [source] does not
  /// exist.
  Future<String?> export(
    File source, {
    required String folderDialogTitle,
    required String saveDialogTitle,
  }) async {
    if (!await source.exists()) throw const DatabaseFileMissingException();

    if (Platform.isAndroid) {
      // Scoped storage: the create-document dialog carries the write grant,
      // so no storage permission is needed.
      return const SafStorageService().saveDocument(
        fileName: exportFileName,
        mimeType: 'application/octet-stream',
        sourcePath: source.path,
      );
    }

    final String? outputFile;
    if (Platform.isIOS) {
      final dir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: folderDialogTitle,
      );
      outputFile = dir == null ? null : '$dir/$exportFileName';
    } else {
      outputFile = await FilePicker.platform.saveFile(
        dialogTitle: saveDialogTitle,
        fileName: exportFileName,
      );
    }
    if (outputFile == null) return null;
    await source.copy(outputFile);
    return outputFile;
  }
}
