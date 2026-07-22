import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart' show Uuid;

/// Filesystem store for tag photos: one JPEG per registration under
/// `<documents>/beacon_photos/<registration-uuid>.jpg`. Deliberately kept
/// out of the database and out of sync/archive — a tag photo is a local
/// field aid (which physical tag is which), not shared cave data.
class BeaconPhotoStore {
  const BeaconPhotoStore._();

  static Future<File> _file(Uuid beaconUuid) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'beacon_photos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return File(p.join(dir.path, '$beaconUuid.jpg'));
  }

  /// The stored photo, or null when none was taken.
  static Future<File?> find(Uuid beaconUuid) async {
    final f = await _file(beaconUuid);
    return await f.exists() ? f : null;
  }

  /// Stores [source] (JPEG-encoded by the picker) as the tag's photo,
  /// replacing any previous one.
  static Future<File> save(Uuid beaconUuid, File source) async {
    final f = await _file(beaconUuid);
    return source.copy(f.path);
  }

  static Future<void> delete(Uuid beaconUuid) async {
    final f = await _file(beaconUuid);
    if (await f.exists()) await f.delete();
  }
}
