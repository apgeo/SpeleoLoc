import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:speleoloc/services/trip_media/trip_media_item.dart';
import 'package:speleoloc/services/trip_media/trip_media_source.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Reads the device's photo and video library through MediaStore (Android) /
/// PHPhotoLibrary (iOS).
///
/// This is the path that makes the feature workable on a real trip's worth of
/// media: the library is paged rather than loaded whole, the platform query
/// prunes it before anything is listed, and each asset carries the capture
/// time the camera recorded — including for videos, which have no EXIF to
/// fall back on.
///
/// The date range is applied in two steps because the platform's own filter
/// does not mean what its name suggests. On Android the plugin's "create
/// time" condition tests `DATE_ADDED` — when the file arrived on the device —
/// while the time it reports per asset is `DATE_TAKEN`. For a picture the
/// phone took itself the two agree. For one copied over afterwards (a
/// waterproof camera, a teammate's phone: the usual way cave pictures reach a
/// phone) they differ by days, and trusting the platform filter alone hides
/// exactly the pictures a trip-day range is meant to find.
class DeviceLibraryMediaSource implements TripMediaSource {
  DeviceLibraryMediaSource({int pageSize = 200}) : _pageSize = pageSize;

  /// How far a capture time may run ahead of the file's arrival time and
  /// still be found. A picture cannot arrive before it is taken, so arrival
  /// bounds capture from above — except that capture times are local-time
  /// strings stamped with whatever zone and clock the camera had. A day
  /// covers any zone offset and an unset-by-hours camera clock.
  static const Duration arrivalSlack = Duration(days: 1);

  /// The arrival-time window to ask the platform for, given the capture
  /// range wanted: a superset that is safe to prune by.
  ///
  /// Only the lower bound carries over. Anything captured at or after
  /// [from] arrived at or after it too, but a picture captured inside the
  /// range may have arrived at any later moment, so the upper bound is
  /// simply the present.
  static ({DateTime min, DateTime max}) arrivalWindowFor(
    DateTime? from, {
    required DateTime now,
  }) {
    return (
      min: from == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : from.subtract(arrivalSlack),
      max: now.add(arrivalSlack),
    );
  }

  /// Whether a capture time falls inside the wanted range, bounds included.
  static bool isCapturedWithin(DateTime at, DateTime? from, DateTime? to) {
    if (from != null && at.isBefore(from)) return false;
    if (to != null && at.isAfter(to)) return false;
    return true;
  }

  final int _pageSize;
  final _log = AppLogger.of('DeviceLibraryMediaSource');

  /// Caches the asset per id so [thumbnail] and [file] do not re-query the
  /// platform for an item the list already resolved.
  final Map<String, AssetEntity> _assets = {};

  @override
  String get id => 'device_library';

  @override
  bool get supportsDateRange => true;

  @override
  Future<List<TripMediaItem>> list({DateTime? from, DateTime? to}) async {
    final window = arrivalWindowFor(from, now: DateTime.now());
    final albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        createTimeCond: DateTimeCond(min: window.min, max: window.max),
      ),
    );
    if (albums.isEmpty) return const [];

    final all = albums.first;
    final total = await all.assetCountAsync;
    final items = <TripMediaItem>[];
    for (var page = 0; page * _pageSize < total; page++) {
      final assets = await all.getAssetListPaged(page: page, size: _pageSize);
      if (assets.isEmpty) break;
      for (final asset in assets) {
        if (!isCapturedWithin(asset.createDateTime, from, to)) continue;
        _assets[asset.id] = asset;
        items.add(
          TripMediaItem(
            id: asset.id,
            kind: asset.type == AssetType.video
                ? TripMediaKind.video
                : TripMediaKind.photo,
            capturedAt: asset.createDateTime,
            capturedAtSource: MediaTimeSource.library,
            displayName: asset.title,
          ),
        );
      }
    }
    // Sorted here rather than by the platform, whose "create date" order is
    // arrival order for the same reason its filter is.
    items.sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    return items;
  }

  @override
  Future<Uint8List?> thumbnail(TripMediaItem item, {int edge = 200}) async {
    final asset = _assets[item.id];
    if (asset == null) return null;
    try {
      return await asset.thumbnailDataWithSize(ThumbnailSize.square(edge));
    } catch (e, st) {
      _log.fine('thumbnail failed for ${item.id}', e, st);
      return null;
    }
  }

  /// Long edge, in pixels, of the still handed to the QR decoder: enough
  /// for a label filling a tenth of the frame to keep several pixels per
  /// module, far less than a phone camera's 4000-plus.
  static const int scanEdge = 2048;

  @override
  Future<R?> withScanImage<R>(
    TripMediaItem item,
    Future<R?> Function(File file) use,
  ) async {
    final asset = _assets[item.id];
    if (asset == null || !item.isPhoto) return null;
    final Uint8List? bytes;
    try {
      bytes = await asset.thumbnailDataWithOption(
        Platform.isIOS
            // iOS's default delivery is opportunistic, which can answer with
            // a quick degraded image first — the wrong input for a decoder.
            ? ThumbnailOption.ios(
                size: const ThumbnailSize.square(scanEdge),
                deliveryMode: DeliveryMode.highQualityFormat,
                quality: 90,
              )
            : const ThumbnailOption(
                size: ThumbnailSize.square(scanEdge),
                quality: 90,
              ),
      );
    } catch (e, st) {
      _log.fine('scan image failed for ${item.id}', e, st);
      return null;
    }
    if (bytes == null) return null;

    final dir = await getTemporaryDirectory();
    final scan = File('${dir.path}/trip_media_scan_${item.id.hashCode}.jpg');
    try {
      await scan.writeAsBytes(bytes, flush: true);
      return await use(scan);
    } finally {
      try {
        if (await scan.exists()) await scan.delete();
      } catch (e, st) {
        _log.fine('could not remove ${scan.path}', e, st);
      }
    }
  }

  @override
  Future<void> release() async {
    _assets.clear();
    try {
      // Removes the originals the plugin copied for `file` (Android 10,
      // iOS). Safe once the import that needed them has finished.
      await PhotoManager.clearFileCache();
    } catch (e, st) {
      _log.fine('clearing the photo cache failed', e, st);
    }
  }

  @override
  Future<File?> file(TripMediaItem item) async {
    final asset = _assets[item.id];
    if (asset == null) return null;
    try {
      // The original rather than the platform's re-encode: the import stores
      // the caver's own file, and a re-encode would also drop the EXIF.
      return await asset.originFile;
    } catch (e, st) {
      _log.warning('could not materialise asset ${item.id}', e, st);
      return null;
    }
  }
}
