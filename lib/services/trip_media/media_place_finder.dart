import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/trip_media/media_qr_detector.dart';
import 'package:speleoloc/services/trip_media/media_scan_cache.dart';
import 'package:speleoloc/services/trip_media/trip_media_item.dart';
import 'package:speleoloc/services/trip_media/trip_media_source.dart';

/// The cave place a picture's label points at, and whether its label came
/// from an earlier read.
class MediaPlaceFinding {
  const MediaPlaceFinding(this.place, {this.fromCache = false});

  final CavePlace? place;
  final bool fromCache;
}

/// Finds the cave place a picture shows a label for, decoding the picture
/// only the first time.
///
/// What is remembered is the label's raw text, not the place: places and
/// their codes can change between visits to the screen, so the text is
/// matched against the cave as it is now on every call. A picture that
/// could not be read at all is not remembered, so the next visit tries
/// again.
class MediaPlaceFinder {
  MediaPlaceFinder(this._cache, this.detector);

  final MediaScanCache _cache;
  final MediaQrDetector detector;

  Future<MediaPlaceFinding> find(
    TripMediaSource source,
    TripMediaItem item, {
    required Uuid caveUuid,
  }) async {
    if (!item.isPhoto) return const MediaPlaceFinding(null);
    final key = await source.scanKey(item);
    final cached = key == null ? null : await _cache.read(key);

    String? payload;
    final fromCache = cached != null;
    if (cached != null) {
      payload = cached.payload;
    } else {
      final read = await source.withScanImage(item, detector.readPayload);
      if (read == null || !read.readable) return const MediaPlaceFinding(null);
      payload = read.payload;
      if (key != null) await _cache.write(key, payload);
    }

    if (payload == null) return MediaPlaceFinding(null, fromCache: fromCache);
    final place = await detector.placeForPayload(payload, caveUuid: caveUuid);
    return MediaPlaceFinding(place, fromCache: fromCache);
  }
}
