import 'dart:convert';

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
      _ => null,
    };
  }

  static String _string(Object? value) => value is String ? value : '';
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
