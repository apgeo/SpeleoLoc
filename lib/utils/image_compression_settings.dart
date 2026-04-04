import 'package:speleo_loc/screens/settings/settings_helper.dart';
import 'package:speleo_loc/utils/constants.dart';

/// Predefined image compression profiles.
///
/// Each profile defines a max resolution (longest side in px) and a JPEG
/// quality percentage.  "manual" lets the user set both values freely.
enum ImageCompressionProfile {
  low,      // gentle reduction
  medium,   // moderate reduction
  high,     // aggressive reduction
  veryHigh, // very aggressive reduction
  manual,   // user-defined values
}

/// Settings that control whether and how imported images are compressed.
class ImageCompressionSettings {
  final bool enabled;
  final ImageCompressionProfile profile;
  final int maxResolution; // longest side in px
  final int quality;       // JPEG quality 1-100

  const ImageCompressionSettings({
    this.enabled = false,
    this.profile = ImageCompressionProfile.medium,
    this.maxResolution = 1920,
    this.quality = 80,
  });

  /// Profile presets (maxResolution, quality).
  static const Map<ImageCompressionProfile, (int, int)> presets = {
    ImageCompressionProfile.low:      (3840, 92),
    ImageCompressionProfile.medium:   (1920, 80),
    ImageCompressionProfile.high:     (1280, 65),
    ImageCompressionProfile.veryHigh: (800,  45),
  };

  /// Returns settings with the selected profile's preset values applied.
  ImageCompressionSettings applyProfile(ImageCompressionProfile p) {
    if (p == ImageCompressionProfile.manual) {
      return ImageCompressionSettings(
        enabled: enabled,
        profile: p,
        maxResolution: maxResolution,
        quality: quality,
      );
    }
    final (res, q) = presets[p]!;
    return ImageCompressionSettings(
      enabled: enabled,
      profile: p,
      maxResolution: res,
      quality: q,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'profile': profile.name,
    'maxResolution': maxResolution,
    'quality': quality,
  };

  factory ImageCompressionSettings.fromJson(Map<String, dynamic> json) {
    return ImageCompressionSettings(
      enabled: json['enabled'] as bool? ?? false,
      profile: ImageCompressionProfile.values.firstWhere(
        (p) => p.name == json['profile'],
        orElse: () => ImageCompressionProfile.medium,
      ),
      maxResolution: json['maxResolution'] as int? ?? 1920,
      quality: json['quality'] as int? ?? 80,
    );
  }

  /// Loads the current settings from the DB.
  static Future<ImageCompressionSettings> load() async {
    final json = await SettingsHelper.loadJsonConfig(
      imageCompressionConfigKey,
      () => const ImageCompressionSettings().toJson(),
    );
    return ImageCompressionSettings.fromJson(json);
  }

  /// Persists the current settings to the DB.
  Future<void> save() async {
    await SettingsHelper.saveJsonConfig(imageCompressionConfigKey, toJson());
  }
}
