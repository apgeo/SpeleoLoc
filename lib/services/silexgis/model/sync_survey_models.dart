import 'package:speleoloc/services/silexgis/model/sync_stream.dart';

/// A cave's line plot on the survey-models stream: a Therion `.lox` or a
/// Survex `.3d` file, in the cave's own coordinates.
///
/// Listed only for a cave this account may see exactly, since holding the
/// file is holding the cave's position.
class SyncSurveyModel {
  const SyncSurveyModel({
    required this.id,
    required this.caveId,
    required this.documentId,
    required this.format,
    this.versionId,
    this.name,
    this.isCurrent = false,
    this.sizeBytes,
    this.sha256,
    this.revision,
  });

  final String id;
  final String caveId;

  /// The file, fetched through the address route as its `original`.
  final String documentId;

  /// The revision of [documentId] this row describes; a new one is new bytes.
  final String? versionId;
  final String? name;

  /// `lox` or `3d`, as the wire spells it.
  final String format;

  /// The line plot the cave is represented by in the browser. At most one of
  /// a cave's models carries it.
  final bool isCurrent;
  final int? sizeBytes;
  final String? sha256;
  final String? revision;

  /// The file extension the format is stored under.
  String get extension => format == '3d' ? '3d' : 'lox';

  static SyncSurveyModel fromJson(Map<String, Object?> json) => SyncSurveyModel(
    id: json['id']! as String,
    caveId: json['caveId']! as String,
    documentId: json['documentId']! as String,
    versionId: json['versionId'] as String?,
    name: json['name'] as String?,
    format: json['format'] as String? ?? 'lox',
    isCurrent: json['isCurrent'] as bool? ?? false,
    sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
    sha256: json['sha256'] as String?,
    revision: json['revision'] as String?,
  );
}

/// A model or mapping the device is to drop. `revision` is the moment.
class SyncSurveyTombstone {
  const SyncSurveyTombstone({required this.id, this.revision});

  final String id;
  final String? revision;

  static SyncSurveyTombstone fromJson(Map<String, Object?> json) =>
      SyncSurveyTombstone(
        id: json['id']! as String,
        revision: json['revision'] as String?,
      );
}

/// A place of a cave at a station of one of its surveys — or at the far end
/// of a splay from that station.
///
/// The survey is either a server model or a survey file a phone uploaded as a
/// document; exactly one of [surveyModelId] and [documentId] is present.
class SyncPlaceStation {
  const SyncPlaceStation({
    required this.id,
    required this.placeId,
    required this.station,
    this.surveyModelId,
    this.documentId,
    this.splay,
    this.revision,
  });

  final String id;
  final String placeId;
  final String? surveyModelId;
  final String? documentId;

  /// The 3D viewer's spelling: CaveView's dotted station name.
  final String station;

  /// `[east, north, up]` metres from [station], or null for the station
  /// itself.
  final List<double>? splay;
  final String? revision;

  static SyncPlaceStation fromJson(Map<String, Object?> json) =>
      SyncPlaceStation(
        id: json['id']! as String,
        placeId: json['placeId']! as String,
        surveyModelId: json['surveyModelId'] as String?,
        documentId: json['documentId'] as String?,
        station: json['station']! as String,
        splay: _splay(json['splay'] as List?),
        revision: json['revision'] as String?,
      );

  /// Exactly three offsets, or none. Anything else is not a splay this
  /// contract describes, and the mapping is kept at its station rather than
  /// placed somewhere made up.
  static List<double>? _splay(List<Object?>? json) {
    if (json == null || json.length != 3) return null;
    return json.map((e) => (e! as num).toDouble()).toList(growable: false);
  }
}

/// One page of the survey-models stream, on its own cursor.
class SyncSurveyModelsPage implements SyncStreamPage {
  const SyncSurveyModelsPage({
    required this.setRevision,
    required this.models,
    required this.tombstones,
    required this.placeStations,
    required this.placeStationTombstones,
    required this.nextCursor,
    required this.hasMore,
  });

  @override
  final int setRevision;
  final List<SyncSurveyModel> models;

  /// Models removed, or whose cave is now withheld from this account or was
  /// deleted. A removed model takes its mappings with it: they are not named
  /// in [placeStationTombstones].
  final List<SyncSurveyTombstone> tombstones;

  /// **A mapping whose place or survey this account is not handed is left
  /// out**, so one merely missing is withheld, not removed.
  final List<SyncPlaceStation> placeStations;
  final List<SyncSurveyTombstone> placeStationTombstones;

  @override
  final String? nextCursor;

  @override
  final bool hasMore;

  static SyncSurveyModelsPage fromJson(Map<String, Object?> json) =>
      SyncSurveyModelsPage(
        setRevision: (json['setRevision'] as num?)?.toInt() ?? 0,
        models: _list(json['models'], SyncSurveyModel.fromJson),
        tombstones: _list(json['tombstones'], SyncSurveyTombstone.fromJson),
        placeStations: _list(json['placeStations'], SyncPlaceStation.fromJson),
        placeStationTombstones: _list(
          json['placeStationTombstones'],
          SyncSurveyTombstone.fromJson,
        ),
        nextCursor: json['nextCursor'] as String?,
        hasMore: json['hasMore'] as bool? ?? false,
      );

  static List<T> _list<T>(
    Object? json,
    T Function(Map<String, Object?>) read,
  ) => (json as List? ?? const <Object?>[])
      .whereType<Map>()
      .map((e) => read(Map<String, Object?>.from(e)))
      .toList(growable: false);
}
