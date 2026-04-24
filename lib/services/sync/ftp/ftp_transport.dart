import 'dart:io';
import 'dart:typed_data';

import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';

/// Minimal remote-entry description for listing archive folders.
class RemoteFileEntry {
  final String name;
  final int size;
  final DateTime? modifiedAt;

  const RemoteFileEntry({
    required this.name,
    required this.size,
    this.modifiedAt,
  });
}

/// Byte-progress callback for up/down transfers. [bytesTransferred] is
/// cumulative, [totalBytes] is the file size when known (otherwise null for
/// streaming sources).
typedef TransferProgressCallback = void Function(
    int bytesTransferred, int? totalBytes);

/// Transport-agnostic interface over an archive-exchange backend.
///
/// The sync engine speaks only this interface. Adding a new transport
/// (HTTPS, WebDAV, …) is just another implementation — the sync engine, the
/// archive format, and conflict resolution are unaffected.
abstract class IFtpTransport {
  FtpProfile get profile;

  /// Establish a connection using [password] for authentication. Implementations
  /// MUST NOT retain the password beyond the lifetime of the connection.
  Future<void> connect({required String password});

  /// Release the underlying connection. Safe to call after a failed connect.
  Future<void> disconnect();

  /// Verifies [profile.remoteFolder] is reachable and writable. Used by the
  /// "Test connection" button. Creates a tiny file, reads it back, deletes it.
  /// Throws on any failure so the caller can surface the message.
  Future<void> verifyReadWriteAccess();

  /// Lists files in [profile.remoteFolder]. Returned entries are NOT guaranteed
  /// to be sorted; callers should sort by filename-embedded timestamp.
  Future<List<RemoteFileEntry>> listFolder();

  /// Uploads [localFile] to [profile.remoteFolder] with the given [remoteName].
  ///
  /// [onProgress] is invoked with (bytesTransferred, totalBytes) as the upload
  /// proceeds. [cancelToken] is polled periodically; when [CancelToken.cancelled]
  /// flips to true, the upload aborts as soon as possible and throws
  /// [TransferCancelledException].
  Future<void> uploadFile(
    File localFile,
    String remoteName, {
    TransferProgressCallback? onProgress,
    CancelToken? cancelToken,
  });

  /// Downloads [remoteName] from [profile.remoteFolder] into [localFile],
  /// with the same progress/cancel semantics as [uploadFile].
  Future<void> downloadFile(
    String remoteName,
    File localFile, {
    TransferProgressCallback? onProgress,
    CancelToken? cancelToken,
  });
}

/// Flag passed through the transport to let long-running transfers abort
/// cooperatively. A single token may be checked across multiple steps.
class CancelToken {
  bool _cancelled = false;
  bool _paused = false;

  bool get cancelled => _cancelled;
  bool get paused => _paused;

  void cancel() => _cancelled = true;

  void pause() => _paused = true;
  void resume() => _paused = false;

  /// Utility used inside tight transfer loops.
  void throwIfCancelled() {
    if (_cancelled) {
      throw const TransferCancelledException();
    }
  }
}

class TransferCancelledException implements Exception {
  final String message;
  const TransferCancelledException([this.message = 'Transfer cancelled']);
  @override
  String toString() => 'TransferCancelledException: $message';
}

/// Thrown by transports when the remote rejects credentials.
class FtpAuthException implements Exception {
  final String message;
  const FtpAuthException(this.message);
  @override
  String toString() => 'FtpAuthException: $message';
}

/// Thrown when a transport-level IO error occurs (network, socket, etc.).
class FtpTransportException implements Exception {
  final String message;
  final Object? cause;
  const FtpTransportException(this.message, [this.cause]);
  @override
  String toString() => 'FtpTransportException: $message'
      '${cause != null ? ' (cause: $cause)' : ''}';
}

/// Convenience: generate a 16-byte random payload for a write-read-delete
/// probe in [IFtpTransport.verifyReadWriteAccess].
Uint8List makeProbeBytes() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final bytes = Uint8List(16);
  for (var i = 0; i < 8; i++) {
    bytes[i] = (now >> (i * 8)) & 0xff;
  }
  for (var i = 8; i < 16; i++) {
    bytes[i] = (i * 37 + (now & 0xff)) & 0xff;
  }
  return bytes;
}
