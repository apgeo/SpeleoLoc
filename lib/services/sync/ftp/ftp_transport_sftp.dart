import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_transport.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// [IFtpTransport] implementation over SFTP (SSH) using `dartssh2`.
///
/// Password authentication only for now; public-key auth is a sensible
/// follow-up but adds a key-management UI out of scope for Phase A.
class FtpTransportSftp implements IFtpTransport {
  @override
  final FtpProfile profile;

  final _log = AppLogger.of('FtpTransportSftp');
  SSHClient? _ssh;
  SftpClient? _sftp;

  FtpTransportSftp(this.profile);

  @override
  Future<void> connect({required String password}) async {
    if (profile.protocol != FtpProtocol.sftp) {
      throw const FtpTransportException(
          'FtpTransportSftp requires an SFTP profile');
    }
    try {
      final socket = await SSHSocket.connect(
        profile.host,
        profile.effectivePort,
        timeout: const Duration(seconds: 30),
      );
      final client = SSHClient(
        socket,
        username: profile.username,
        onPasswordRequest: () => password,
      );
      await client.authenticated;
      final sftp = await client.sftp();
      _ssh = client;
      _sftp = sftp;
      // Ensure remote folder exists.
      try {
        await sftp.stat(profile.remoteFolder);
      } on SftpStatusError {
        try {
          await sftp.mkdir(profile.remoteFolder);
        } catch (e) {
          _log.warning('SFTP mkdir failed for ${profile.remoteFolder}: $e');
        }
      }
    } on SSHAuthFailError catch (e) {
      throw FtpAuthException(e.toString());
    } catch (e) {
      throw FtpTransportException('SFTP connect failed', e);
    }
  }

  @override
  Future<void> disconnect() async {
    final sftp = _sftp;
    final ssh = _ssh;
    _sftp = null;
    _ssh = null;
    try {
      sftp?.close();
    } catch (_) {}
    try {
      ssh?.close();
    } catch (_) {}
  }

  @override
  Future<void> verifyReadWriteAccess() async {
    final sftp = _requireConnected();
    final probeName =
        'speleo_loc_probe_${DateTime.now().millisecondsSinceEpoch}.tmp';
    final remotePath = _joinRemote(probeName);
    final handle = await sftp.open(remotePath,
        mode: SftpFileOpenMode.create |
            SftpFileOpenMode.write |
            SftpFileOpenMode.truncate);
    try {
      await handle.writeBytes(makeProbeBytes());
    } finally {
      await handle.close();
    }
    try {
      await sftp.remove(remotePath);
    } catch (e) {
      _log.warning('SFTP probe cleanup failed for $remotePath: $e');
    }
  }

  @override
  Future<List<RemoteFileEntry>> listFolder() async {
    final sftp = _requireConnected();
    try {
      final names = await sftp.listdir(profile.remoteFolder);
      return names
          .where((n) => n.filename != '.' && n.filename != '..')
          // Exclude directories when attrs expose the type (size-only is fine
          // — directories commonly report null size, which is still acceptable
          // for filename-based filtering done upstream).
          .map((n) => RemoteFileEntry(
                name: n.filename,
                size: n.attr.size ?? 0,
                modifiedAt: n.attr.modifyTime != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        n.attr.modifyTime! * 1000,
                        isUtc: true)
                    : null,
              ))
          .toList();
    } catch (e) {
      throw FtpTransportException('SFTP list failed', e);
    }
  }

  @override
  Future<void> uploadFile(
    File localFile,
    String remoteName, {
    TransferProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final sftp = _requireConnected();
    cancelToken?.throwIfCancelled();
    final total = await localFile.length();
    final remotePath = _joinRemote(remoteName);
    final handle = await sftp.open(remotePath,
        mode: SftpFileOpenMode.create |
            SftpFileOpenMode.write |
            SftpFileOpenMode.truncate);
    try {
      final writer = handle.write(
        localFile.openRead().cast(),
        onProgress: (bytes) {
          if (cancelToken?.cancelled == true) {
            // Fire-and-forget abort; the Future chain below will observe.
            writerRefAbort(() => _abortIfStarted());
          } else if (onProgress != null) {
            onProgress(bytes, total);
          }
        },
      );
      _activeWriter = writer;
      await writer.done;
      if (cancelToken?.cancelled == true) {
        throw const TransferCancelledException();
      }
    } catch (e) {
      if (e is TransferCancelledException) rethrow;
      throw FtpTransportException('SFTP upload failed', e);
    } finally {
      _activeWriter = null;
      await handle.close();
    }
  }

  @override
  Future<void> downloadFile(
    String remoteName,
    File localFile, {
    TransferProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final sftp = _requireConnected();
    cancelToken?.throwIfCancelled();
    final remotePath = _joinRemote(remoteName);
    int? total;
    try {
      total = (await sftp.stat(remotePath)).size;
    } catch (_) {}
    final sink = localFile.openWrite();
    try {
      await sftp.download(
        remotePath,
        sink,
        onProgress: (bytesRead) {
          if (cancelToken?.cancelled == true) {
            // Cannot cleanly interrupt dartssh2 download mid-stream;
            // we let it complete but will throw after.
            return;
          }
          if (onProgress != null) {
            onProgress(bytesRead, total);
          }
        },
      );
      cancelToken?.throwIfCancelled();
    } on TransferCancelledException {
      rethrow;
    } catch (e) {
      throw FtpTransportException('SFTP download failed', e);
    } finally {
      await sink.close();
    }
  }

  // ---- internal helpers ----

  SftpFileWriter? _activeWriter;

  /// No-op wrapper to silence lints around async abort; kept explicit for
  /// readability of [uploadFile]'s cancellation path.
  void writerRefAbort(void Function() fn) => fn();

  void _abortIfStarted() {
    final w = _activeWriter;
    if (w == null) return;
    // Fire-and-forget — errors propagate through writer.done.
    // ignore: discarded_futures
    w.abort();
  }

  SftpClient _requireConnected() {
    final s = _sftp;
    if (s == null) {
      throw const FtpTransportException('SFTP transport not connected');
    }
    return s;
  }

  String _joinRemote(String name) {
    final folder = profile.remoteFolder.endsWith('/')
        ? profile.remoteFolder
        : '${profile.remoteFolder}/';
    return p.posix.join(folder, name);
  }
}
