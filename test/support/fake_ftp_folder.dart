import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_transport.dart';

/// A step a transport takes against the shared folder.
enum FtpFolderStep { connect, list, upload, download, rename, delete }

/// The remote folder several devices sync through, held in memory: file
/// name to bytes. Each device gets its own [transport] over the same files.
///
/// [fault] decides, before every step, whether that step fails; returning
/// an exception makes the transport throw it, as a dropped connection or a
/// full disk would.
class FakeFtpFolder {
  final Map<String, List<int>> files = <String, List<int>>{};

  /// Every file name downloaded, in order, by any device.
  final List<String> downloads = <String>[];

  /// Every file name uploaded, in order, by any device, under the name it
  /// was uploaded with (an archive's temporary name, before its rename).
  final List<String> uploads = <String>[];

  Exception? Function(FtpFolderStep step, String name)? fault;

  IFtpTransport transport(FtpProfile profile) => _Transport(this, profile);

  /// Puts [name] in the folder as a device publishes it: with its `.sha256`
  /// checksum file beside it. [checksum] replaces the checksum file's text,
  /// to serve a wrong or malformed one.
  void publish(String name, List<int> bytes, {String? checksum}) {
    files[name] = bytes;
    files['$name.sha256'] = utf8.encode(
      checksum ?? '${sha256.convert(bytes)}\n',
    );
  }

  /// The archives in the folder, without their checksum files.
  Iterable<String> get archives => files.keys.where((n) => n.endsWith('.zip'));

  void _step(FtpFolderStep step, String name) {
    final failure = fault?.call(step, name);
    if (failure != null) throw failure;
  }
}

class _Transport implements IFtpTransport {
  _Transport(this._folder, this.profile);

  final FakeFtpFolder _folder;

  @override
  final FtpProfile profile;

  @override
  Future<void> connect({required String password}) async =>
      _folder._step(FtpFolderStep.connect, '');

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> verifyReadWriteAccess() async {}

  @override
  Future<List<RemoteFileEntry>> listFolder() async {
    _folder._step(FtpFolderStep.list, '');
    return [
      for (final e in _folder.files.entries)
        RemoteFileEntry(name: e.key, size: e.value.length),
    ];
  }

  @override
  Future<void> uploadFile(
    File localFile,
    String remoteName, {
    TransferProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    _folder._step(FtpFolderStep.upload, remoteName);
    final bytes = await localFile.readAsBytes();
    _folder.files[remoteName] = bytes;
    _folder.uploads.add(remoteName);
    onProgress?.call(bytes.length, bytes.length);
  }

  @override
  Future<void> rename(String fromName, String toName) async {
    _folder._step(FtpFolderStep.rename, fromName);
    final bytes = _folder.files.remove(fromName);
    if (bytes == null) throw FtpTransportException('missing $fromName');
    _folder.files[toName] = bytes;
  }

  @override
  Future<void> deleteFile(String remoteName) async {
    _folder._step(FtpFolderStep.delete, remoteName);
    _folder.files.remove(remoteName);
  }

  @override
  Future<void> downloadFile(
    String remoteName,
    File localFile, {
    TransferProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    _folder._step(FtpFolderStep.download, remoteName);
    final bytes = _folder.files[remoteName];
    if (bytes == null) throw FtpTransportException('missing $remoteName');
    _folder.downloads.add(remoteName);
    await localFile.writeAsBytes(bytes);
    onProgress?.call(bytes.length, bytes.length);
  }
}
