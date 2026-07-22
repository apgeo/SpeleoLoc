import 'package:speleoloc/screens/settings/settings_helper.dart';

/// Configuration key for [BeaconDetectionConfig] (device-local JSON).
const String beaconDetectionConfigKey = 'beacon_detection_config';

/// Tuning for automatic beacon detection. Persisted per device (detection
/// behaviour is a personal preference, not shared cave data).
class BeaconDetectionConfig {
  /// Master switch; when false the detection service never starts.
  final bool enabled;

  /// A sighting only counts when RSSI ≥ this (dBm). Phase-0 field data
  /// showed −17…−43 dBm at room distance; −75 keeps detection within a
  /// few metres in-passage while ignoring far reflections.
  final int rssiThresholdDbm;

  /// Trigger after this many qualifying sightings…
  final int debounceCount;

  /// …within this window (protects against single-packet reflections).
  final int debounceWindowSec;

  /// After a trigger the same beacon stays silent for this long.
  final int cooldownSec;

  /// When true, navigate to the detected place (like a QR scan); when
  /// false (default) show only a toast and record the trip point.
  final bool autoOpenPlace;

  /// Play an audible alert on detection: a short in-app sound in the
  /// foreground, the loud notification channel sound in the background.
  final bool soundEnabled;

  /// Keep detecting with the app in the background via a foreground
  /// service (Android). Detections raise a loud notification.
  final bool backgroundEnabled;

  /// Background duty cycle: one scan burst starts every this many seconds
  /// (5–60 s; the burst itself is ~5 s, so 5 means continuous scanning).
  final int backgroundScanIntervalSec;

  const BeaconDetectionConfig({
    this.enabled = false,
    this.rssiThresholdDbm = -75,
    this.debounceCount = 2,
    this.debounceWindowSec = 5,
    this.cooldownSec = 300,
    this.autoOpenPlace = false,
    this.soundEnabled = true,
    this.backgroundEnabled = false,
    this.backgroundScanIntervalSec = 30,
  });

  BeaconDetectionConfig copyWith({
    bool? enabled,
    int? rssiThresholdDbm,
    int? debounceCount,
    int? debounceWindowSec,
    int? cooldownSec,
    bool? autoOpenPlace,
    bool? soundEnabled,
    bool? backgroundEnabled,
    int? backgroundScanIntervalSec,
  }) => BeaconDetectionConfig(
    enabled: enabled ?? this.enabled,
    rssiThresholdDbm: rssiThresholdDbm ?? this.rssiThresholdDbm,
    debounceCount: debounceCount ?? this.debounceCount,
    debounceWindowSec: debounceWindowSec ?? this.debounceWindowSec,
    cooldownSec: cooldownSec ?? this.cooldownSec,
    autoOpenPlace: autoOpenPlace ?? this.autoOpenPlace,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    backgroundEnabled: backgroundEnabled ?? this.backgroundEnabled,
    backgroundScanIntervalSec:
        backgroundScanIntervalSec ?? this.backgroundScanIntervalSec,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'rssiThresholdDbm': rssiThresholdDbm,
    'debounceCount': debounceCount,
    'debounceWindowSec': debounceWindowSec,
    'cooldownSec': cooldownSec,
    'autoOpenPlace': autoOpenPlace,
    'soundEnabled': soundEnabled,
    'backgroundEnabled': backgroundEnabled,
    'backgroundScanIntervalSec': backgroundScanIntervalSec,
  };

  static BeaconDetectionConfig fromJson(Map<String, dynamic> j) {
    const d = BeaconDetectionConfig();
    return BeaconDetectionConfig(
      enabled: j['enabled'] as bool? ?? d.enabled,
      rssiThresholdDbm: j['rssiThresholdDbm'] as int? ?? d.rssiThresholdDbm,
      debounceCount: j['debounceCount'] as int? ?? d.debounceCount,
      debounceWindowSec: j['debounceWindowSec'] as int? ?? d.debounceWindowSec,
      cooldownSec: j['cooldownSec'] as int? ?? d.cooldownSec,
      autoOpenPlace: j['autoOpenPlace'] as bool? ?? d.autoOpenPlace,
      soundEnabled: j['soundEnabled'] as bool? ?? d.soundEnabled,
      backgroundEnabled: j['backgroundEnabled'] as bool? ?? d.backgroundEnabled,
      backgroundScanIntervalSec:
          j['backgroundScanIntervalSec'] as int? ?? d.backgroundScanIntervalSec,
    );
  }

  static Future<BeaconDetectionConfig> load() async {
    final j = await SettingsHelper.loadJsonConfig(
      beaconDetectionConfigKey,
      () => const BeaconDetectionConfig().toJson(),
    );
    return fromJson(j);
  }

  Future<void> save() =>
      SettingsHelper.saveJsonConfig(beaconDetectionConfigKey, toJson());
}

/// Pure detection logic: decides when a stream of beacon sightings
/// becomes a "you are at this place" trigger.
///
/// Feed every ranged sighting via [observe]; it returns true exactly when
/// the identity passes threshold + debounce and is outside its cooldown.
/// Only identities present in [updateRegistrations] are considered.
class BeaconMatchEngine {
  BeaconMatchEngine(this.config);

  BeaconDetectionConfig config;

  Set<String> _registered = {};
  final Map<String, List<DateTime>> _sightings = {};
  final Map<String, DateTime> _cooldownUntil = {};

  /// Replace the registered-identity cache (`UUID/major/minor`,
  /// uppercase UUID).
  void updateRegistrations(Set<String> identities) {
    _registered = identities;
    _sightings.removeWhere((k, _) => !identities.contains(k));
    _cooldownUntil.removeWhere((k, _) => !identities.contains(k));
  }

  /// Process one sighting. Returns true when this sighting fires a
  /// detection trigger for [identity].
  bool observe(String identity, int rssi, DateTime now) {
    if (!_registered.contains(identity)) return false;
    if (rssi == 0 || rssi < config.rssiThresholdDbm) return false;

    final cooldownEnd = _cooldownUntil[identity];
    if (cooldownEnd != null) {
      if (now.isBefore(cooldownEnd)) return false;
      _cooldownUntil.remove(identity);
    }

    final window = Duration(seconds: config.debounceWindowSec);
    final recent = (_sightings[identity] ?? [])
      ..removeWhere((t) => now.difference(t) > window)
      ..add(now);
    _sightings[identity] = recent;

    if (recent.length < config.debounceCount) return false;

    _sightings.remove(identity);
    _cooldownUntil[identity] = now.add(Duration(seconds: config.cooldownSec));
    return true;
  }

  /// Clears transient state (sightings + cooldowns), e.g. on restart.
  void reset() {
    _sightings.clear();
    _cooldownUntil.clear();
  }
}
