/// This device's choices for the 3D survey-model viewer.
class ModelViewerSettings {
  const ModelViewerSettings({
    this.stationMapping = true,
    this.markColourByArea = false,
    this.autoDownloadModels = true,
  });

  /// Configuration key the settings are stored under, as JSON.
  static const storageKey = 'model_viewer_settings';

  /// Mapping cave places to stations: off hides the mapping actions, the
  /// marks and the list, and keeps what is stored.
  final bool stationMapping;

  /// Marks coloured by the place's cave area instead of one colour.
  final bool markColourByArea;

  /// Models listed by SilexGIS downloaded by the sync run, instead of on
  /// demand.
  final bool autoDownloadModels;

  ModelViewerSettings copyWith({
    bool? stationMapping,
    bool? markColourByArea,
    bool? autoDownloadModels,
  }) => ModelViewerSettings(
    stationMapping: stationMapping ?? this.stationMapping,
    markColourByArea: markColourByArea ?? this.markColourByArea,
    autoDownloadModels: autoDownloadModels ?? this.autoDownloadModels,
  );

  factory ModelViewerSettings.fromJson(Map<String, dynamic> json) {
    const defaults = ModelViewerSettings();
    bool read(String key, bool fallback) =>
        json[key] is bool ? json[key] as bool : fallback;
    return ModelViewerSettings(
      stationMapping: read('stationMapping', defaults.stationMapping),
      markColourByArea: read('markColourByArea', defaults.markColourByArea),
      autoDownloadModels: read(
        'autoDownloadModels',
        defaults.autoDownloadModels,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'stationMapping': stationMapping,
    'markColourByArea': markColourByArea,
    'autoDownloadModels': autoDownloadModels,
  };
}
