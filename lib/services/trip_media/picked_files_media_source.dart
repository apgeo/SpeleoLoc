import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:speleoloc/services/trip_media/media_capture_time.dart';
import 'package:speleoloc/services/trip_media/trip_media_item.dart';
import 'package:speleoloc/services/trip_media/trip_media_source.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/documentation_file_helper.dart';

/// Fallback source for devices where the library cannot be enumerated —
/// the user denied access, or the platform only offers the system picker.
///
/// The picker needs no permission of its own, which is exactly why it is the
/// fallback. What it costs is the library's own capture dates: the picked
/// file is a copy in a cache directory, so a photo's time comes from its
/// EXIF and a video's only from the copy's filesystem stamp, which is
/// usually the moment of copying. [TripMediaItem.capturedAtSource] records
/// which it was so the screen can say so rather than imply a precision it
/// does not have.
class PickedFilesMediaSource implements TripMediaSource {
  PickedFilesMediaSource({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  final _log = AppLogger.of('PickedFilesMediaSource');

  @override
  String get id => 'picked_files';

  @override
  bool get supportsDateRange => false;

  @override
  Future<List<TripMediaItem>> list({DateTime? from, DateTime? to}) async {
    final List<XFile> picked;
    try {
      picked = await _picker.pickMultipleMedia();
    } catch (e, st) {
      _log.warning('media picker failed', e, st);
      return const [];
    }

    final items = <TripMediaItem>[];
    for (final x in picked) {
      final resolved = await _resolve(x);
      if (resolved == null) continue;
      // The picker has no date range of its own, so the caller's range is
      // applied here instead of being silently ignored.
      if (from != null && resolved.capturedAt.isBefore(from)) continue;
      if (to != null && resolved.capturedAt.isAfter(to)) continue;
      items.add(resolved);
    }
    items.sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    return items;
  }

  Future<TripMediaItem?> _resolve(XFile x) async {
    final file = File(x.path);
    if (!await file.exists()) return null;
    final isVideo = _looksLikeVideo(x);

    DateTime? captured;
    var source = MediaTimeSource.fileModified;
    if (!isVideo) {
      try {
        captured = MediaCaptureTime.fromImageBytes(await file.readAsBytes());
      } catch (e, st) {
        _log.fine('could not read ${x.path} for EXIF', e, st);
      }
      if (captured != null) source = MediaTimeSource.exif;
    }
    captured ??= await _modifiedAt(file);
    if (captured == null) return null;

    return TripMediaItem(
      id: x.path,
      kind: isVideo ? TripMediaKind.video : TripMediaKind.photo,
      capturedAt: captured,
      capturedAtSource: source,
      displayName: x.name,
    );
  }

  Future<DateTime?> _modifiedAt(File file) async {
    try {
      return (await file.stat()).modified;
    } catch (e, st) {
      _log.fine('stat failed for ${file.path}', e, st);
      return null;
    }
  }

  /// The picker reports a mime type on some platforms and nothing on others,
  /// so the extension is the fallback discriminator.
  static bool _looksLikeVideo(XFile x) {
    final mime = x.mimeType?.toLowerCase();
    if (mime != null && mime.isNotEmpty) return mime.startsWith('video/');
    final path = x.path.toLowerCase();
    final dot = path.lastIndexOf('.');
    if (dot < 0) return false;
    return DocumentationFileHelper.videoExtensions.contains(
      path.substring(dot + 1),
    );
  }

  @override
  Future<Uint8List?> thumbnail(TripMediaItem item, {int edge = 200}) async {
    // No platform thumbnailer here: the screen renders stills from the file
    // itself and shows a placeholder for videos.
    return null;
  }

  @override
  Future<File?> file(TripMediaItem item) async {
    final f = File(item.id);
    return await f.exists() ? f : null;
  }

  /// A picked file is already a local copy, so it is scanned as it is.
  @override
  Future<R?> withScanImage<R>(
    TripMediaItem item,
    Future<R?> Function(File file) use,
  ) async {
    if (!item.isPhoto) return null;
    final f = await file(item);
    return f == null ? null : use(f);
  }

  /// The picker's copies are left to the platform, which clears its cache
  /// directory on its own; nothing here was copied by this source.
  @override
  Future<void> release() async {}
}
