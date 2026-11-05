import 'dart:io';

import 'package:speleoloc/utils/app_logger.dart';

/// Temporary files a screen writes for its own use. The OS clears the
/// temporary folder only when it runs short of space, so whoever writes a
/// scratch file removes it.
class ScratchFiles {
  static final _log = AppLogger.of('ScratchFiles');

  final _paths = <String>[];

  void add(String path) => _paths.add(path);

  /// Deletes every tracked file except [keep], which stays tracked.
  Future<void> deleteAllExcept(String? keep) async {
    final doomed = _paths.where((p) => p != keep).toList();
    _paths.removeWhere((p) => p != keep);
    for (final path in doomed) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } on FileSystemException catch (e) {
        _log.warning('could not remove scratch file', e);
      }
    }
  }

  Future<void> deleteAll() => deleteAllExcept(null);
}
