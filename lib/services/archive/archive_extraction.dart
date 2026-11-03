import 'dart:io';

import 'package:archive/archive.dart';
import 'package:speleoloc/utils/contained_path.dart';

/// Writes every regular file entry of [archive] under [destDir], keeping its
/// relative path, and returns the names of the entries left out because they
/// would land outside [destDir].
///
/// The `archive` package does not check entry names, and an imported archive
/// can come from anyone, so each name is confined here. Folder and
/// symbolic-link entries are never materialised.
Future<List<String>> extractArchiveInto(
  Archive archive,
  Directory destDir,
) async {
  final rejected = <String>[];
  for (final file in archive) {
    if (!file.isFile || file.isSymbolicLink) continue;
    final destPath = containedPath(destDir.path, file.name);
    if (destPath == null) {
      rejected.add(file.name);
      continue;
    }
    final content = file.content;
    if (content == null) continue;
    final outFile = File(destPath);
    await outFile.parent.create(recursive: true);
    await outFile.writeAsBytes(content as List<int>);
  }
  return rejected;
}
