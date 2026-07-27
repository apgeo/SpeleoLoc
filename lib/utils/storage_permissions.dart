import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Runtime storage-permission helpers for features that read or write
/// user-chosen shared-storage folders with dart:io (bulk document import,
/// archive export). Both methods are no-ops on non-Android platforms.
class StoragePermissions {
  StoragePermissions._();

  /// Media/storage read permissions: photos + videos + audio on Android 13+,
  /// READ_EXTERNAL_STORAGE on 12 and below. Without these, scoped storage
  /// still lists directories but hides other apps' files inside them.
  static Future<void> ensureRead() async {
    if (!Platform.isAndroid) return;
    await [
      Permission.photos,
      Permission.videos,
      Permission.audio,
      Permission.storage,
    ].request();
  }

  /// All-files access: WRITE/READ_EXTERNAL_STORAGE on Android ≤10 and
  /// MANAGE_EXTERNAL_STORAGE (the system "all files access" toggle) on 11+.
  /// Needed to WRITE into an arbitrary user-picked shared folder (archive
  /// export) and to READ non-media documents (pdf, txt) that the media
  /// permissions do not expose. Best-effort: returns whether all-files
  /// access is granted afterwards, but callers still handle I/O failures.
  static Future<bool> ensureAllFilesAccess() async {
    if (!Platform.isAndroid) return true;
    await Permission.storage.request();
    if (await Permission.manageExternalStorage.isGranted) return true;
    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }
}
