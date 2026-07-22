import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:speleoloc/services/map/tile_disk_cache.dart';

/// Drop-in replacement for flutter_map's NetworkTileProvider that runs
/// every fetch through [loadTileBytes]: fresh tiles render from the
/// [TileDiskCache] without a request, and stale ones are served when the
/// network fails — offline browsing of any previously viewed area.
class CachedNetworkTileProvider extends TileProvider {
  CachedNetworkTileProvider({required this.sourceId, required this.cache});

  final String sourceId;
  final TileDiskCache cache;

  /// One keep-alive client for every provider instance: providers are
  /// rebuilt with the layer stack on each map rebuild, so a per-instance
  /// client would leak sockets (TileLayer may also dispose providers
  /// mid-flight, and in-flight tiles must not lose their client).
  static final http.Client _client = http.Client();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _CachedTileImage(
        provider: this,
        z: coordinates.z,
        x: coordinates.x,
        y: coordinates.y,
        url: getTileUrl(coordinates, options),
      );
}

/// Keyed on the tile URL so Flutter's image cache deduplicates decodes
/// across rebuilds (the URL encodes source, zoom and position).
@immutable
class _CachedTileImage extends ImageProvider<_CachedTileImage> {
  const _CachedTileImage({
    required this.provider,
    required this.z,
    required this.x,
    required this.y,
    required this.url,
  });

  final CachedNetworkTileProvider provider;
  final int z, x, y;
  final String url;

  @override
  Future<_CachedTileImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _CachedTileImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _load(key, decode),
    scale: 1,
    debugLabel: key.url,
  );

  static Future<ui.Codec> _load(
    _CachedTileImage key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await loadTileBytes(
      cache: key.provider.cache,
      sourceId: key.provider.sourceId,
      z: key.z,
      x: key.x,
      y: key.y,
      url: Uri.parse(key.url),
      client: CachedNetworkTileProvider._client,
      headers: key.provider.headers,
    );
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) => other is _CachedTileImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
