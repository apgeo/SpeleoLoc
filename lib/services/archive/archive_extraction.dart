import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart' hide ZLibDecoder;
import 'package:speleoloc/utils/contained_path.dart';

/// Writes every regular file entry of [archive] under [destDir], keeping its
/// relative path, and returns the names of the entries left out because they
/// would land outside [destDir].
///
/// The `archive` package does not check entry names, and an imported archive
/// can come from anyone, so each name is confined here. Folder and
/// symbolic-link entries are never materialised.
///
/// Each entry is copied or inflated to disk in chunks: the package's own
/// `content` holds a whole entry in memory, and an archive can carry a
/// multi-gigabyte video. Synchronous, so run it off the UI isolate; see
/// [extractZipFileInto].
List<String> extractArchiveInto(Archive archive, Directory destDir) {
  final rejected = <String>[];
  for (final entry in archive) {
    if (!entry.isFile || entry.isSymbolicLink) continue;
    final destPath = containedPath(destDir.path, entry.name);
    if (destPath == null) {
      rejected.add(entry.name);
      continue;
    }
    final raw = entry.rawContent;
    if (raw == null) continue;
    final outFile = File(destPath);
    outFile.parent.createSync(recursive: true);
    _writeEntry(entry, raw, outFile);
  }
  return rejected;
}

/// [extractArchiveInto] for the zip file at [zipPath], on a background
/// isolate so neither reading nor inflating blocks the UI.
Future<List<String>> extractZipFileInto(String zipPath, String destDir) =>
    Isolate.run(() {
      final input = InputFileStream(zipPath);
      try {
        return extractArchiveInto(
          ZipDecoder().decodeBuffer(input),
          Directory(destDir),
        );
      } finally {
        input.closeSync();
      }
    });

const int _chunkBytes = 1 << 20;

void _writeEntry(ArchiveFile entry, InputStreamBase raw, File dest) {
  final method = entry.compressionType;
  if (method != ArchiveFile.STORE && method != ArchiveFile.DEFLATE) {
    // Methods this app never writes (bzip2 from another tool) go through
    // the package, whole.
    dest.writeAsBytesSync(entry.content as List<int>);
    return;
  }
  final out = dest.openSync(mode: FileMode.write);
  try {
    final sink = _FileSink(out);
    final Sink<List<int>> target = method == ArchiveFile.DEFLATE
        ? ZLibDecoder(raw: true).startChunkedConversion(sink)
        : sink;
    raw.reset();
    while (!raw.isEOS) {
      target.add(raw.readBytes(_chunkBytes).toUint8List());
    }
    target.close();
  } finally {
    out.closeSync();
  }
}

class _FileSink implements Sink<List<int>> {
  _FileSink(this._file);

  final RandomAccessFile _file;

  @override
  void add(List<int> data) => _file.writeFromSync(data);

  @override
  void close() {}
}
