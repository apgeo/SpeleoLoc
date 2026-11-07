import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

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
    Isolate.run(
      () => _withZip(
        zipPath,
        (archive) => extractArchiveInto(archive, Directory(destDir)),
      ),
    );

/// What [extractZipEntriesTo] did with the entries it was given.
class ZipEntriesExtraction {
  const ZipEntriesExtraction({
    required this.written,
    required this.failures,
    required this.missing,
  });

  /// How many entries were written.
  final int written;

  /// Why each entry that could not be written failed, by entry name.
  final Map<String, String> failures;

  /// Entries the zip does not hold.
  final List<String> missing;
}

/// Writes each entry of the zip at [zipPath] that [destinations] names to
/// the path it maps to, on a background isolate, copied or inflated in
/// chunks as [extractArchiveInto] does, so memory stays flat however large
/// an entry is. An existing file at a destination is replaced.
///
/// The destinations are written as given: the caller confines them, and
/// creates their folders. One entry that cannot be written does not stop
/// the others.
Future<ZipEntriesExtraction> extractZipEntriesTo(
  String zipPath,
  Map<String, String> destinations,
) => Isolate.run(
  () => _withZip(zipPath, (archive) {
    var written = 0;
    final failures = <String, String>{};
    final missing = <String>[];
    for (final MapEntry(key: name, value: destPath) in destinations.entries) {
      final entry = archive.findFile(name);
      final raw = entry?.rawContent;
      if (entry == null || raw == null) {
        missing.add(name);
        continue;
      }
      final dest = File(destPath);
      final existed = dest.existsSync();
      try {
        _writeEntry(entry, raw, dest);
        written++;
      } catch (e) {
        failures[name] = '$e';
        // A half-written new file would pass for the whole one later.
        if (!existed) _deleteQuietly(dest);
      }
    }
    return ZipEntriesExtraction(
      written: written,
      failures: failures,
      missing: missing,
    );
  }),
);

/// The names of every file entry of the zip at [zipPath], and the content
/// of those named in [wanted] that it holds, read on a background isolate.
///
/// Only for small entries such as a manifest or table dumps: each wanted
/// entry is held whole. The rest of the zip is never read.
Future<({List<String> fileNames, Map<String, Uint8List> contents})>
readZipEntries(String zipPath, Set<String> wanted) => Isolate.run(
  () => _withZip(zipPath, (archive) {
    final fileNames = <String>[];
    final contents = <String, Uint8List>{};
    for (final entry in archive) {
      if (!entry.isFile) continue;
      fileNames.add(entry.name);
      if (wanted.contains(entry.name)) {
        final content = entry.content as List<int>;
        contents[entry.name] = content is Uint8List
            ? content
            : Uint8List.fromList(content);
      }
    }
    return (fileNames: fileNames, contents: contents);
  }),
);

void _deleteQuietly(File file) {
  try {
    if (file.existsSync()) file.deleteSync();
  } on FileSystemException {
    // Left for the next import to report again.
  }
}

/// Runs [read] on the zip at [zipPath], opened through a file stream so
/// entries are read from disk as they are needed.
T _withZip<T>(String zipPath, T Function(Archive archive) read) {
  final input = InputFileStream(zipPath);
  try {
    return read(ZipDecoder().decodeBuffer(input));
  } finally {
    input.closeSync();
  }
}

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
