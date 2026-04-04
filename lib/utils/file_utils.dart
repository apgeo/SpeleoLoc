import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Returns the absolute path for a file stored in the application documents directory.
Future<String> getDocumentsFilePath(String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  return '${directory.path}/$fileName';
}

/// Returns a [File] from the application documents directory for [fileName],
/// or null if the file does not exist on disk.
Future<File?> getDocumentsFile(String fileName) async {
  final path = await getDocumentsFilePath(fileName);
  final file = File(path);
  return file.existsSync() ? file : null;
}
