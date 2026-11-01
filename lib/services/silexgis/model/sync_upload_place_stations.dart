import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';

/// One item of an upload's `placeStations` section: a place at a station of
/// a survey, or its removal.
///
/// The survey is named by exactly one of [surveyModelId] — a server model —
/// and [documentId] — a survey file this device uploaded as a document.
class SyncUploadPlaceStation implements SyncUploadItem {
  const SyncUploadPlaceStation({
    required this.id,
    required this.baseRevision,
    required String this.placeId,
    required String this.station,
    this.surveyModelId,
    this.documentId,
    this.splay,
  }) : assert((surveyModelId == null) != (documentId == null)),
       deleted = false;

  const SyncUploadPlaceStation.delete({
    required this.id,
    required this.baseRevision,
  }) : deleted = true,
       placeId = null,
       station = null,
       surveyModelId = null,
       documentId = null,
       splay = null;

  /// The longest station name the server takes.
  static const int maxStationLength = 400;

  /// The farthest a splay end may be from its station, either way, in metres.
  static const double maxSplayMetres = 10000;

  final String id;
  final String? baseRevision;
  final bool deleted;
  final String? placeId;
  final String? surveyModelId;
  final String? documentId;
  final String? station;

  /// `[east, north, up]` metres from [station], or null for the station.
  final List<double>? splay;

  /// Whether the server takes [station] and [splay] as they are.
  static bool fits(String station, List<double>? splay) =>
      station.isNotEmpty &&
      station.length <= maxStationLength &&
      (splay == null ||
          (splay.length == 3 &&
              splay.every((v) => v.isFinite && v.abs() <= maxSplayMetres)));

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'baseRevision': baseRevision,
      'deleted': deleted,
    };
    if (deleted) return json;
    return json..addAll(<String, Object?>{
      'placeId': placeId,
      'surveyModelId': ?surveyModelId,
      'documentId': ?documentId,
      'station': station,
      'splay': ?splay,
    });
  }
}
