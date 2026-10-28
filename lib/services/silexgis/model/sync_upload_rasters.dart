import 'package:speleoloc/services/silexgis/model/sync_rasters.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';

/// One map going up in the `rasterMaps` section.
///
/// A new map brings its picture as staged bytes; an edit brings them only when
/// the caver gave the map another picture. The cave never changes: a map stays
/// with the cave it was made for.
class SyncUploadRasterMap implements SyncUploadItem {
  const SyncUploadRasterMap({
    required this.id,
    required this.baseRevision,
    required this.caveId,
    required this.title,
    required this.mapType,
    required this.sha256,
    this.caveAreaId,
    this.sortOrder,
    this.fileName,
    this.sizeBytes,
    this.stagedUploadId,
    this.clientUpdatedAt,
  }) : deleted = false;

  /// A removal: arbitrated on [baseRevision], and carrying nothing else. Its
  /// picture and its pins go with it.
  const SyncUploadRasterMap.delete({
    required this.id,
    required this.baseRevision,
  }) : deleted = true,
       caveId = null,
       title = null,
       mapType = null,
       sha256 = null,
       caveAreaId = null,
       sortOrder = null,
       fileName = null,
       sizeBytes = null,
       stagedUploadId = null,
       clientUpdatedAt = null;

  final String id;

  /// Null for a map new to the installation.
  final String? baseRevision;
  final bool deleted;
  final String? caveId;

  /// Absent for the whole cave. An edit without it clears the area there.
  final String? caveAreaId;
  final String? title;
  final SyncRasterMapType? mapType;
  final int? sortOrder;
  final String? fileName;

  /// The lower-case hex hash of the picture the phone holds.
  final String? sha256;
  final int? sizeBytes;

  /// The staged bytes of a new picture; absent when the picture stands.
  final String? stagedUploadId;

  /// Provenance only, never compared.
  final String? clientUpdatedAt;

  /// The same map naming other staged bytes — the answer to bytes the server
  /// no longer holds.
  SyncUploadRasterMap withStagedUpload(String transferId) =>
      SyncUploadRasterMap(
        id: id,
        baseRevision: baseRevision,
        caveId: caveId,
        caveAreaId: caveAreaId,
        title: title,
        mapType: mapType,
        sortOrder: sortOrder,
        fileName: fileName,
        sha256: sha256,
        sizeBytes: sizeBytes,
        stagedUploadId: transferId,
        clientUpdatedAt: clientUpdatedAt,
      );

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'baseRevision': baseRevision,
      'deleted': deleted,
    };
    if (deleted) return json;
    return json..addAll(<String, Object?>{
      'caveId': caveId,
      'caveAreaId': ?caveAreaId,
      'title': title,
      'mapType': mapType?.wireName,
      'sortOrder': ?sortOrder,
      'fileName': ?fileName,
      'sha256': sha256,
      'sizeBytes': ?sizeBytes,
      'stagedUploadId': ?stagedUploadId,
      'clientUpdatedAt': ?clientUpdatedAt,
    });
  }
}

/// One pin going up in the `rasterPins` section.
class SyncUploadRasterPin implements SyncUploadItem {
  const SyncUploadRasterPin({
    required this.id,
    required this.rasterMapId,
    required this.baseRevision,
    required this.placeId,
    required this.x,
    required this.y,
  }) : deleted = false;

  /// A removal names its map too: a pin belongs to one for good.
  const SyncUploadRasterPin.delete({
    required this.id,
    required this.rasterMapId,
    required this.baseRevision,
  }) : deleted = true,
       placeId = null,
       x = null,
       y = null;

  /// The largest pixel either way the server takes.
  static const int maxPixel = 1000000;

  final String id;
  final String rasterMapId;
  final String? baseRevision;
  final bool deleted;
  final String? placeId;

  /// Whole pixels from the left and top edge, 0 to [maxPixel].
  final int? x;
  final int? y;

  static bool isPixel(int? value) =>
      value != null && value >= 0 && value <= maxPixel;

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'rasterMapId': rasterMapId,
      'baseRevision': baseRevision,
      'deleted': deleted,
    };
    if (deleted) return json;
    return json..addAll(<String, Object?>{'placeId': placeId, 'x': x, 'y': y});
  }
}
