import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:speleoloc/services/map/mbtiles_isolate_reader.dart';

/// 1×1 fully transparent PNG served for coordinates the MBTiles file does
/// not cover, so partial-coverage overlays don't paint error tiles.
final Uint8List _transparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// Serves flutter_map tiles from a local raster MBTiles file, reading the
/// bytes on the file's worker isolate so pan/zoom never blocks on SQLite.
///
/// The provider is a thin per-build wrapper: the [MbTilesIsolateReader] is
/// owned and disposed by the map page, not by this provider.
class MbTilesTileProvider extends TileProvider {
  MbTilesTileProvider(this._reader);

  final MbTilesIsolateReader _reader;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _MbTilesImage(_reader, coordinates.z, coordinates.x, coordinates.y);
}

/// Keyed on (reader, z, x, y) so Flutter's image cache reuses decoded
/// tiles across rebuilds instead of re-fetching and re-decoding.
@immutable
class _MbTilesImage extends ImageProvider<_MbTilesImage> {
  const _MbTilesImage(this.reader, this.z, this.x, this.y);

  final MbTilesIsolateReader reader;
  final int z, x, y;

  @override
  Future<_MbTilesImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _MbTilesImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _load(key, decode),
    scale: 1,
    debugLabel: 'mbtiles(${key.z}/${key.x}/${key.y})',
  );

  static Future<ui.Codec> _load(
    _MbTilesImage key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await key.reader.tile(key.z, key.x, key.y);
    final buffer = await ui.ImmutableBuffer.fromUint8List(
      bytes ?? _transparentPng,
    );
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) =>
      other is _MbTilesImage &&
      identical(other.reader, reader) &&
      other.z == z &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode => Object.hash(identityHashCode(reader), z, x, y);
}
