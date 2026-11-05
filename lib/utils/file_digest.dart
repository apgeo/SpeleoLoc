import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// The SHA-256 and size of a file's content, as stored with a document.
class FileDigest {
  const FileDigest({required this.sha256Hex, required this.size});

  /// Lowercase hex SHA-256 of the content.
  final String sha256Hex;

  /// Number of bytes hashed.
  final int size;

  /// Hashes the file at [path] on a background isolate, reading it in
  /// fixed-size chunks.
  ///
  /// Attached files include multi-gigabyte videos: read whole, one would
  /// claim its size in the heap and could get the app killed, and hashing it
  /// on the UI isolate freezes the screen for seconds. Memory stays at one
  /// chunk whatever the file's size.
  static Future<FileDigest> of(String path) => Isolate.run(() => ofSync(path));

  /// [of] on the calling isolate. Only for code already running off the UI
  /// isolate.
  static FileDigest ofSync(String path) {
    Digest? result;
    final input = sha256.startChunkedConversion(
      ChunkedConversionSink<Digest>.withCallback((d) => result = d.single),
    );
    final file = File(path).openSync();
    var size = 0;
    try {
      // The hash sink copies what it is given, so one buffer is reused.
      final buffer = Uint8List(_chunkBytes);
      while (true) {
        final read = file.readIntoSync(buffer);
        if (read == 0) break;
        input.add(
          read == buffer.length
              ? buffer
              : Uint8List.sublistView(buffer, 0, read),
        );
        size += read;
      }
    } finally {
      file.closeSync();
    }
    input.close();
    return FileDigest(sha256Hex: result!.toString(), size: size);
  }

  static const int _chunkBytes = 1 << 20;
}
