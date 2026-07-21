import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

/// Parsed `metadata` table of an MBTiles file. Every field is optional in
/// the wild; absent values fall back to permissive defaults so a sparse
/// file still renders.
class MbTilesMetadata {
  final String? name;
  final String format;
  final int? minZoom;
  final int? maxZoom;

  /// Coverage as `west, south, east, north` (WGS84), when declared.
  final double? west, south, east, north;

  const MbTilesMetadata({
    this.name,
    required this.format,
    this.minZoom,
    this.maxZoom,
    this.west,
    this.south,
    this.east,
    this.north,
  });

  factory MbTilesMetadata.fromMap(Map<String, String> map) {
    double? boundsPart(int index) {
      final raw = map['bounds']?.split(',');
      if (raw == null || raw.length != 4) return null;
      return double.tryParse(raw[index].trim());
    }

    return MbTilesMetadata(
      name: map['name'],
      format: (map['format'] ?? 'png').toLowerCase(),
      minZoom: int.tryParse(map['minzoom'] ?? ''),
      maxZoom: int.tryParse(map['maxzoom'] ?? ''),
      west: boundsPart(0),
      south: boundsPart(1),
      east: boundsPart(2),
      north: boundsPart(3),
    );
  }

  /// Vector (`pbf`) files need a vector renderer and are not supported;
  /// everything else (png/jpg/webp) is decodable by Flutter's image codecs.
  bool get isRaster => format != 'pbf';

  bool get hasBounds =>
      west != null && south != null && east != null && north != null;
}

/// Read-only accessor over a single raster `.mbtiles` file (a SQLite
/// database with a `metadata` key/value table and a `tiles` table or view;
/// tile rows use the TMS scheme, i.e. the y axis is flipped vs XYZ).
class MbTilesReader {
  MbTilesReader._(this._db, this.path, this.metadata);

  final Database _db;
  final String path;
  final MbTilesMetadata metadata;

  /// Opens [path] read-only and parses its metadata. Throws on files that
  /// are not readable SQLite databases or lack the MBTiles tables — the
  /// `tiles` table/view is probed too, so a metadata-only database is
  /// rejected here (at import/scan) instead of failing per tile at render
  /// time.
  static MbTilesReader open(String path) {
    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    try {
      final rows = db.select('SELECT name, value FROM metadata');
      final map = <String, String>{
        for (final r in rows)
          (r['name'] as String).toLowerCase(): (r['value'] as String?) ?? '',
      };
      db.select('SELECT zoom_level FROM tiles LIMIT 1');
      return MbTilesReader._(db, path, MbTilesMetadata.fromMap(map));
    } catch (_) {
      db.close();
      rethrow;
    }
  }

  /// Tile lookups run per rendered tile during pan/zoom; the prepared
  /// statement is compiled once and reused instead of re-parsing the SQL
  /// on every fetch.
  PreparedStatement? _tileStatement;

  /// Returns the raw tile bytes at XYZ coordinates, or null when the file
  /// holds no tile there (outside coverage or beyond the stored zooms).
  Uint8List? tile(int z, int x, int y) {
    final tmsY = (1 << z) - 1 - y;
    final statement = _tileStatement ??= _db.prepare(
      'SELECT tile_data FROM tiles '
      'WHERE zoom_level = ? AND tile_column = ? AND tile_row = ? LIMIT 1',
    );
    final rows = statement.select([z, x, tmsY]);
    if (rows.isEmpty) return null;
    return rows.first['tile_data'] as Uint8List?;
  }

  void dispose() {
    _tileStatement?.close();
    _db.close();
  }
}
