import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart' hide ZLibEncoder;

/// One entry of a zip written by [writeZipFile]: the content of the file at
/// [path], or [bytes] already in memory. Plain data, so it can be sent to
/// the isolate that writes the zip.
class ZipEntrySource {
  const ZipEntrySource.file(this.name, String this.path) : bytes = null;

  const ZipEntrySource.bytes(this.name, Uint8List this.bytes) : path = null;

  /// The entry's name inside the zip, with `/` separators.
  final String name;
  final String? path;
  final Uint8List? bytes;
}

/// Files up to this size are deflated in memory; larger ones are stored as
/// they are, streamed from disk.
///
/// The `archive` package deflates an entry only whole, so a large file
/// would claim its size in memory twice over. The large files a caver
/// attaches are photos, videos and scans whose formats are compressed
/// already, so storing them costs little space.
const int zipDeflateLimitBytes = 32 << 20;

/// Writes [entries] as a zip at [outputPath] on a background isolate.
///
/// A file entry whose source no longer exists is left out. Memory stays
/// near [zipDeflateLimitBytes] whatever the files' total size, and neither
/// reading nor compressing blocks the UI.
Future<void> writeZipFile(String outputPath, List<ZipEntrySource> entries) =>
    Isolate.run(() => _writeZipFileSync(outputPath, entries));

void _writeZipFileSync(String outputPath, List<ZipEntrySource> entries) {
  final output = OutputFileStream(outputPath);
  try {
    final encoder = ZipEncoder()..startEncode(output);
    for (final entry in entries) {
      final archiveFile = _archiveFileFor(entry);
      if (archiveFile != null) encoder.addFile(archiveFile);
    }
    encoder.endEncode();
  } finally {
    output.closeSync();
  }
}

ArchiveFile? _archiveFileFor(ZipEntrySource entry) {
  final bytes = entry.bytes;
  if (bytes != null) return _deflated(entry.name, bytes);
  final file = File(entry.path!);
  if (!file.existsSync()) return null;
  final length = file.lengthSync();
  if (length <= zipDeflateLimitBytes) {
    return _deflated(entry.name, file.readAsBytesSync());
  }
  return ArchiveFile.stream(entry.name, length, InputFileStream(file.path))
    ..compress = false;
}

/// An entry deflated by the platform's zlib, which is many times faster than
/// the package's pure-Dart encoder; the encoder copies already-deflated data
/// through as it is.
ArchiveFile _deflated(String name, Uint8List bytes) {
  // The size argument falls back to the content's length when zero, which
  // for deflated content would be wrong; an empty entry is stored instead.
  if (bytes.isEmpty) return ArchiveFile.noCompress(name, 0, bytes);
  final compressed = _rawDeflate.convert(bytes);
  return ArchiveFile(
    name,
    bytes.length,
    InputStream(compressed),
    ArchiveFile.DEFLATE,
  )..crc32 = getCrc32(bytes);
}

final ZLibEncoder _rawDeflate = ZLibEncoder(raw: true);
