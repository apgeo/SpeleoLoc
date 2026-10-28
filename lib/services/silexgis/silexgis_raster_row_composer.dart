import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_rasters.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_rasters.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_row_composer.dart';

/// The local picture of a map, as one run states it.
class SilexgisRasterPicture {
  const SilexgisRasterPicture({required this.sha256, this.sizeBytes});

  /// Lower-case hex.
  final String? sha256;
  final int? sizeBytes;
}

/// Turns a local raster map or pin into the item that goes up.
class SilexgisRasterRowComposer {
  const SilexgisRasterRowComposer();

  /// [areaId] stands in for an area the installation names and this device
  /// does not hold, so an edit never clears it there.
  SyncUploadRasterMap map(
    RasterMap map, {
    required SilexgisRasterPicture picture,
    String? baseRevision,
    String? stagedUploadId,
    Uuid? areaId,
  }) => SyncUploadRasterMap(
    id: map.uuid.toString(),
    baseRevision: baseRevision,
    caveId: map.caveUuid.toString(),
    caveAreaId: (map.caveAreaUuid ?? areaId)?.toString(),
    title: map.title,
    mapType: SyncRasterMapType.fromLocal(map.mapType),
    sortOrder: map.orderIndex,
    fileName: fileNameOf(map.fileName),
    sha256: picture.sha256,
    sizeBytes: picture.sizeBytes,
    stagedUploadId: stagedUploadId,
    clientUpdatedAt: switch (map.updatedAt ?? map.createdAt) {
      final int ms => SilexgisTripRowComposer.iso(ms),
      null => null,
    },
  );

  SyncUploadRasterPin pin(
    CavePlaceToRasterMapDefinition pin, {
    String? baseRevision,
  }) => SyncUploadRasterPin(
    id: pin.uuid.toString(),
    rasterMapId: pin.rasterMapUuid.toString(),
    baseRevision: baseRevision,
    placeId: pin.cavePlaceUuid.toString(),
    x: pin.xCoordinate,
    y: pin.yCoordinate,
  );

  /// The stored path's last segment, at most 255 characters — the width the
  /// installation keeps a file name in.
  static String fileNameOf(String path) {
    final name = path.split('/').last;
    return name.length <= 255 ? name : name.substring(name.length - 255);
  }
}
