import 'dart:io';
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';
import 'package:speleoloc/services/trip_media/trip_media_item.dart';
import 'package:speleoloc/services/trip_media/trip_media_source.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Reads the device's photo and video library through MediaStore (Android) /
/// PHPhotoLibrary (iOS).
///
/// This is the path that makes the feature workable on a real trip's worth of
/// media: the library is paged rather than loaded whole, the date range is
/// pushed down to the platform query instead of filtering after the fact, and
/// each asset carries the capture time the camera recorded — including for
/// videos, which have no EXIF to fall back on.
class DeviceLibraryMediaSource implements TripMediaSource {
  DeviceLibraryMediaSource({int pageSize = 200}) : _pageSize = pageSize;

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
    final albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        createTimeCond: DateTimeCond(
          min: from ?? DateTime.fromMillisecondsSinceEpoch(0),
          max: to ?? DateTime.now(),
        ),
        orders: const [
          OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
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
