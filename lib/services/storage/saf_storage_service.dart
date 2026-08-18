import 'package:flutter/services.dart';

/// A document-tree grant returned by the system folder picker.
class SafPickedDirectory {
  const SafPickedDirectory({required this.treeUri, required this.name});

  final String treeUri;

  /// User-facing folder name (for display; the [treeUri] is a content URI).
  final String name;
}

/// One entry inside a picked document tree.
class SafEntry {
  const SafEntry({
    required this.documentId,
    required this.name,
    required this.isDirectory,
    required this.size,
  });

  final String documentId;
  final String name;
  final bool isDirectory;
  final int size;
}

/// Android Storage Access Framework access for reading and writing
/// user-picked shared-storage locations without any storage permission.
///
/// The picker dialogs themselves carry the access grant (scoped storage), so
/// callers need no permission_handler involvement. Android-only: callers
/// branch on `Platform.isAndroid` and keep using `dart:io`/`file_picker`
/// paths elsewhere.
class SafStorageService {
  const SafStorageService();

  static const MethodChannel _channel = MethodChannel('speleoloc/saf');

  /// Shows the system folder picker. Returns `null` when the user cancels.
  Future<SafPickedDirectory?> pickDirectory() async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'pickDirectory',
    );
    if (result == null) return null;
    return SafPickedDirectory(
      treeUri: result['treeUri']! as String,
      name: result['name']! as String,
    );
  }

  /// Lists the immediate children of [documentId] inside the tree granted as
  /// [treeUri]; `null` lists the tree root itself.
  Future<List<SafEntry>> listChildren(
    String treeUri, {
    String? documentId,
  }) async {
    final result = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'listChildren',
      {'treeUri': treeUri, 'documentId': documentId},
    );
    return [
      for (final entry in result ?? const <Map<Object?, Object?>>[])
        SafEntry(
          documentId: entry['documentId']! as String,
          name: entry['name']! as String,
          isDirectory: entry['isDirectory']! as bool,
          size: (entry['size']! as num).toInt(),
        ),
    ];
  }

  /// Streams the document [documentId] of [treeUri] into the local file at
  /// [destPath].
  Future<void> copyToFile({
    required String treeUri,
    required String documentId,
    required String destPath,
  }) {
    return _channel.invokeMethod<void>('copyToFile', {
      'treeUri': treeUri,
      'documentId': documentId,
      'destPath': destPath,
    });
  }

  /// Shows the system create-document ("save as") dialog and streams the
  /// local file at [sourcePath] into the chosen destination. Returns the
  /// saved document's display name, or `null` when the user cancels.
  Future<String?> saveDocument({
    required String fileName,
    required String mimeType,
    required String sourcePath,
  }) {
    return _channel.invokeMethod<String>('createDocument', {
      'fileName': fileName,
      'mimeType': mimeType,
      'sourcePath': sourcePath,
    });
  }
}
