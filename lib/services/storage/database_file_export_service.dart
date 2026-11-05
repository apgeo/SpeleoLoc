import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
