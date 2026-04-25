import 'dart:io';

import 'package:ftpconnect/ftpconnect.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_transport.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// [IFtpTransport] over plain FTP or FTPES using the `ftpconnect` package.
///
/// `ftpconnect`'s upload/download APIs already take a progress callback; we
/// wrap them so the sync engine can speak a transport-agnostic progress
/// vocabulary. Pause semantics: the transport cannot actually pause an
/// in-flight FTP transfer — per the design decision (pause = cancel current
/// step, keep progress state; resume restarts the step), pause is mapped to
/// cancel at the transport layer and the engine restarts the step on resume.
class FtpTransportFtp implements IFtpTransport {
  @override
  final FtpProfile profile;

  final _log = AppLogger.of('FtpTransportFtp');
  FTPConnect? _client;

  FtpTransportFtp(this.profile);

  @override
  Future<void> connect({required String password}) async {
    if (profile.protocol == FtpProtocol.sftp) {
      throw const FtpTransportException(
          'SFTP profiles must use FtpTransportSftp, not FtpTransportFtp');
    }
    final security = profile.protocol == FtpProtocol.ftps
        ? SecurityType.ftpes
        : SecurityType.ftp;
    final client = FTPConnect(
      profile.host,
      port: profile.effectivePort,
      user: profile.username,
      pass: password,
      securityType: security,
      timeout: 30,
    );
    if (profile.passiveMode) {
      client.transferMode = TransferMode.passive;
    } else {
      client.transferMode = TransferMode.active;
    }
    try {
      final ok = await client.connect();
      if (!ok) {
        throw const FtpAuthException('FTP server rejected the connection');
      }
      _client = client;
      await client.setTransferType(TransferType.binary);
      // Navigate to remote folder; create if missing.
      await client.createFolderIfNotExist(profile.remoteFolder);
      await client.changeDirectory(profile.remoteFolder);
    } catch (e) {
      // Map known auth-ish phrases.
      final msg = e.toString().toLowerCase();
      if (msg.contains('530') ||
          msg.contains('login') ||
          msg.contains('password')) {
        throw FtpAuthException(e.toString());
      }
      throw FtpTransportException('FTP connect failed', e);
    }
  }

  @override
  Future<void> disconnect() async {
    final c = _client;
    _client = null;
    if (c == null) return;
    try {
      await c.disconnect();
    } catch (e) {
      _log.warning('FTP disconnect error ignored: $e');
    }
  }

  @override
  Future<void> verifyReadWriteAccess() async {
    _requireConnected();
    final probeName = 'speleo_loc_probe_'
        '${DateTime.now().millisecondsSinceEpoch}.tmp';
    final tmpDir = Directory.systemTemp;
    final localProbe =
        File(p.join(tmpDir.path, probeName))..writeAsBytesSync(makeProbeBytes());
    try {
      final uploaded = await _client!
          .uploadFile(localProbe, sRemoteName: probeName);
      if (!uploaded) {
        throw const FtpTransportException('Probe upload returned false');
      }
      try {
        await _client!.deleteFile(probeName);
      } catch (e) {
        _log.warning('Probe cleanup failed (will leave $probeName): $e');
      }
    } finally {
      try {
        if (localProbe.existsSync()) localProbe.deleteSync();
      } catch (_) {}
    }
  }

  @override
  Future<List<RemoteFileEntry>> listFolder() async {
    _requireConnected();
    try {
      final entries = await _client!.listDirectoryContent();
      return entries
          .where((e) => e.type != FTPEntryType.dir)
          .map((e) => RemoteFileEntry(
                name: e.name,
                size: e.size ?? 0,
                modifiedAt: e.modifyTime,
              ))
          .toList();
    } catch (e) {
      throw FtpTransportException('FTP list failed', e);
    }
  }

  @override
  Future<void> uploadFile(
    File localFile,
    String remoteName, {
    TransferProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    _requireConnected();
    cancelToken?.throwIfCancelled();
    final total = await localFile.length();
    try {
      final ok = await _client!.uploadFile(
        localFile,
        sRemoteName: remoteName,
        onProgress: (progressInPercent, totalReceived, fileSize) {
          cancelToken?.throwIfCancelled();
          if (onProgress != null) {
            onProgress(totalReceived, total);
          }
        },
      );
      if (!ok) {
        throw const FtpTransportException('FTP upload returned false');
      }
    } on TransferCancelledException {
      rethrow;
    } catch (e) {
      throw FtpTransportException('FTP upload failed', e);
    }
  }

  @override
  Future<void> downloadFile(
    String remoteName,
    File localFile, {
    TransferProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    _requireConnected();
    cancelToken?.throwIfCancelled();
    int? total;
    try {
      total = await _client!.sizeFile(remoteName);
    } catch (_) {
      total = null;
    }
    try {
      final ok = await _client!.downloadFile(
        remoteName,
        localFile,
        onProgress: (progressInPercent, totalReceived, fileSize) {
          cancelToken?.throwIfCancelled();
          if (onProgress != null) {
            onProgress(totalReceived, total);
          }
        },
      );
      if (!ok) {
        throw const FtpTransportException('FTP download returned false');
      }
    } on TransferCancelledException {
      rethrow;
    } catch (e) {
      throw FtpTransportException('FTP download failed', e);
    }
  }

  void _requireConnected() {
    if (_client == null) {
      throw const FtpTransportException('FTP transport not connected');
    }
  }
}
