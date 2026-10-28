import 'package:speleoloc/services/silexgis/model/sync_download_page.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';

/// What a raster map shows, as the wire names it.
///
/// The phone keeps the kind as words in `raster_maps.map_type`; the two
/// vocabularies map one to one, and a kind this build has not heard of reads
/// as [other].
enum SyncRasterMapType {
  planView('planView', 'plane view'),
  projectedProfile('projectedProfile', 'projected profile'),
  extendedProfile('extendedProfile', 'extended profile'),
  other('other', 'other');

  const SyncRasterMapType(this.wireName, this.localName);

  final String wireName;

  /// The value of `raster_maps.map_type`.
  final String localName;

  static SyncRasterMapType fromWire(String? wireName) {
    for (final value in values) {
      if (value.wireName == wireName) return value;
    }
    return other;
  }

  static SyncRasterMapType fromLocal(String localName) {
    for (final value in values) {
      if (value.localName == localName) return value;
    }
    return other;
  }
}

/// One place pinned on a map, by pixel.
class SyncRasterPin {
  const SyncRasterPin({
    required this.id,
    required this.placeId,
    required this.x,
    required this.y,
    this.revision,
  });

  final String id;
  final String placeId;

  /// Whole pixels from the left and top edge of the picture.
  final int x;
  final int y;

  /// The pin's own revision, sent back as its `baseRevision`.
  final String? revision;

  static SyncRasterPin fromJson(Map<String, Object?> json) => SyncRasterPin(
    id: json['id']! as String,
    placeId: json['placeId']! as String,
    x: (json['x']! as num).toInt(),
    y: (json['y']! as num).toInt(),
    revision: json['revision'] as String?,
  );
}

/// One map on the rasters stream, with its live pins.
class SyncRasterMap {
  const SyncRasterMap({
    required this.id,
    required this.caveId,
    required this.mapType,
    this.caveAreaId,
    this.title,
    this.sortOrder,
    this.documentId,
    this.revision,
    this.pins = const <SyncRasterPin>[],
  });

  final String id;
  final String caveId;

  /// Null for a map of the whole cave.
  final String? caveAreaId;
  final String? title;
  final SyncRasterMapType mapType;
  final int? sortOrder;

  /// The picture: a document of the documents stream, fetched like any
  /// photograph.
  final String? documentId;

  /// The map's own revision, sent back as its `baseRevision`. A pin added or
  /// removed does not move it.
  final String? revision;

  /// **Pins of a place this account is not handed are left out**, so a pin
  /// missing here may have been removed or may only be withheld; the list says
  /// nothing to tell the two apart.
  final List<SyncRasterPin> pins;

  static SyncRasterMap fromJson(Map<String, Object?> json) => SyncRasterMap(
    id: json['id']! as String,
    caveId: json['caveId']! as String,
    caveAreaId: json['caveAreaId'] as String?,
    title: json['title'] as String?,
    mapType: SyncRasterMapType.fromWire(json['mapType'] as String?),
    sortOrder: (json['sortOrder'] as num?)?.toInt(),
    documentId: json['documentId'] as String?,
    revision: json['revision'] as String?,
    pins: (json['pins'] as List? ?? const <Object?>[])
        .whereType<Map>()
        .map((e) => SyncRasterPin.fromJson(Map<String, Object?>.from(e)))
        .toList(growable: false),
  );
}

/// One page of the rasters stream, on its own cursor.
class SyncRastersPage implements SyncStreamPage {
  const SyncRastersPage({
    required this.setRevision,
    required this.maps,
    required this.tombstones,
    required this.nextCursor,
    required this.hasMore,
  });

  @override
  final int setRevision;
  final List<SyncRasterMap> maps;

  /// Maps removed after the cursor. A removed pin is not one: its map comes
  /// again without it.
  final List<SyncTombstone> tombstones;

  @override
  final String? nextCursor;

  @override
  final bool hasMore;

  static SyncRastersPage fromJson(Map<String, Object?> json) => SyncRastersPage(
    setRevision: (json['setRevision'] as num?)?.toInt() ?? 0,
    maps: (json['maps'] as List? ?? const <Object?>[])
        .whereType<Map>()
        .map((e) => SyncRasterMap.fromJson(Map<String, Object?>.from(e)))
        .toList(growable: false),
    tombstones: (json['tombstones'] as List? ?? const <Object?>[])
        .whereType<Map>()
        .map((e) => SyncTombstone.fromJson(Map<String, Object?>.from(e)))
        .toList(growable: false),
    nextCursor: json['nextCursor'] as String?,
    hasMore: json['hasMore'] as bool? ?? false,
  );
}
