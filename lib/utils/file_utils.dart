import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/utils/contained_path.dart';

/// Returns the absolute path for a file stored in the application documents directory.
///
/// Throws a [FileSystemException] when [fileName] would name a path outside
/// that directory: names come from synced rows, which another device wrote.
Future<String> getDocumentsFilePath(String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final path = containedPath(directory.path, fileName);
  if (path == null) {
    throw FileSystemException(
      'file name leaves the documents folder',
      fileName,
    );
  }
  return path;
}

/// Returns a [File] from the application documents directory for [fileName],
/// or null if the file does not exist on disk or the name would leave that
/// directory.
Future<File?> getDocumentsFile(String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final path = containedPath(directory.path, fileName);
  if (path == null) return null;
  final file = File(path);
  return file.existsSync() ? file : null;
}
