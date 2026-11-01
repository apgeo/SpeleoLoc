import 'dart:convert';

import 'package:speleoloc/services/cave_model/model_splay_offset.dart';

/// What the 3D viewer's page reports to the app (protocol 1, see
/// `assets/caveview/host/bridge.js`).
sealed class ModelViewerEvent {
  const ModelViewerEvent();

  static const protocol = 1;

  /// The event in [text], or null when it is not a message of this protocol.
  ///
  /// The page is the app's own, but what it relays comes from a survey file
  /// and from CaveView, so anything malformed is dropped rather than thrown.
  static ModelViewerEvent? decode(String text) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, dynamic> || json['v'] != protocol) return null;
    return switch (json['type']) {
      'ready' => ModelViewerReady(
        engine: _string(json['engine']),
        engineVersion: _string(json['engineVersion']),
      ),
      'loaded' => ModelViewerLoaded(
        stations: (json['stations'] as num?)?.toInt() ?? 0,
      ),
      'error' => ModelViewerFailed(
        code: _string(json['code']),
        message: _string(json['message']),
      ),
      'stationTapped' when json['station'] is String =>
        ModelViewerStationTapped(
          station: json['station'] as String,
          x: (json['x'] as num?)?.toDouble(),
          y: (json['y'] as num?)?.toDouble(),
          z: (json['z'] as num?)?.toDouble(),
        ),
      'marksResolved' => ModelMarksResolved(
        unresolved: _strings(json['unresolved']),
      ),
      'markTapped' => ModelMarkTapped(ids: _strings(json['ids'])),
      'stationInfo' when json['station'] is String => ModelStationInfo(
        station: json['station'] as String,
        x: (json['x'] as num?)?.toDouble(),
        y: (json['y'] as num?)?.toDouble(),
        z: (json['z'] as num?)?.toDouble(),
        splays: [
          for (final s in (json['splays'] as List?) ?? const [])
            ?ModelSplayOffset.fromList(s),
        ],
      ),
      'stations' => ModelStationList(names: _strings(json['names'])),
      'splayPicked' when json['station'] is String =>
        switch (ModelSplayOffset.fromList(json['offset'])) {
          final offset? => ModelSplayPicked(
            station: json['station'] as String,
            offset: offset,
          ),
          null => null,
        },
      'splayPickerEmpty' => ModelSplayPickerEmpty(
        station: _string(json['station']),
      ),
      'trailInfo' => ModelTrailInfo(
        id: _string(json['id']),
        lengthMetres: (json['lengthM'] as num?)?.toDouble() ?? 0,
        gaps: (json['gaps'] as num?)?.toInt() ?? 0,
        atLength: [
          for (final v in (json['atLength'] as List?) ?? const [])
            if (v is num) v.toDouble(),
        ],
      ),
      _ => null,
    };
  }

  static String _string(Object? value) => value is String ? value : '';

  static List<String> _strings(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];
}

/// The page is up and the viewer exists; the survey may still be loading.
final class ModelViewerReady extends ModelViewerEvent {
  const ModelViewerReady({required this.engine, required this.engineVersion});

  final String engine;
  final String engineVersion;
}

/// The survey is drawn.
final class ModelViewerLoaded extends ModelViewerEvent {
  const ModelViewerLoaded({required this.stations});

  final int stations;
}

/// Something failed: `load` (the file could not be read), `notFound` (a
/// command named a station the model does not have) or `script`.
final class ModelViewerFailed extends ModelViewerEvent {
  const ModelViewerFailed({required this.code, required this.message});

  final String code;
  final String message;
}

/// A station was tapped. [station] is CaveView's dotted path for it, the
/// spelling SilexGIS also stores; the coordinates are the model's own, in
/// metres east, north and up.
final class ModelViewerStationTapped extends ModelViewerEvent {
  const ModelViewerStationTapped({
    required this.station,
    this.x,
    this.y,
    this.z,
  });

  final String station;
  final double? x;
  final double? y;
  final double? z;
}

/// The marks [SetModelMarks] could not place: their station is not in the
/// loaded model.
final class ModelMarksResolved extends ModelViewerEvent {
  const ModelMarksResolved({required this.unresolved});

  final List<String> unresolved;
}

/// A mark was tapped; several when they share a station.
final class ModelMarkTapped extends ModelViewerEvent {
  const ModelMarkTapped({required this.ids});

  final List<String> ids;
}

final class ModelStationInfo extends ModelViewerEvent {
  const ModelStationInfo({
    required this.station,
    required this.splays,
    this.x,
    this.y,
    this.z,
  });

  final String station;
  final double? x;
  final double? y;
  final double? z;
  final List<ModelSplayOffset> splays;
}

final class ModelStationList extends ModelViewerEvent {
  const ModelStationList({required this.names});

  final List<String> names;
}

final class ModelSplayPicked extends ModelViewerEvent {
  const ModelSplayPicked({required this.station, required this.offset});

  final String station;
  final ModelSplayOffset offset;
}

/// The station has no splays to pick from.
final class ModelSplayPickerEmpty extends ModelViewerEvent {
  const ModelSplayPickerEmpty({required this.station});

  final String station;
}

/// A route drawn by [SetModelTrail]: its length along the survey, how many
/// pairs of stations the survey could not join, and how far along it each
/// given station lies.
final class ModelTrailInfo extends ModelViewerEvent {
  const ModelTrailInfo({
    required this.id,
    required this.lengthMetres,
    required this.gaps,
    required this.atLength,
  });

  final String id;
  final double lengthMetres;
  final int gaps;
  final List<double> atLength;
}
