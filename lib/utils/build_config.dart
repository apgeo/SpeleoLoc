import 'package:flutter/foundation.dart';

/// Compile-time deployment configuration.
///
/// The single switch between developer builds and store builds. Everything
/// gated on [devToolsEnabled] is tree-shaken out of release binaries, so a
/// store build cannot expose test tooling by accident.
abstract final class BuildConfig {
  /// Whether developer/test tooling (test-archive loading, DB reinitialize
  /// with test data, manual QR entry, SQL runner) is compiled in.
  ///
  /// Defaults to on in debug/profile builds and off in release builds.
  /// Override per build with `--dart-define=DEV_TOOLS=true|false` — e.g.
  /// `DEV_TOOLS=true` on a release-mode build used for internal testing.
  static const bool devToolsEnabled = bool.fromEnvironment(
    'DEV_TOOLS',
    defaultValue: kDebugMode || kProfileMode,
  );

  /// Whether the app offers to load the sample-data archive at
  /// `test_archive_url` (first-start prompt on an empty database, and the
  /// button on the export/import page).
  ///
  /// Separate from [devToolsEnabled] so a store build can carry sample data
  /// for closed testing and store review — testers have no beacons or cave
  /// QR plates, so an empty app gives them nothing to try — without also
  /// shipping the SQL runner and the other developer tooling. The archive is
  /// downloaded on request, never bundled. Override per build with
  /// `--dart-define=SAMPLE_DATA=true|false`; follows [devToolsEnabled]
  /// otherwise.
  static const bool sampleDataEnabled = bool.fromEnvironment(
    'SAMPLE_DATA',
    defaultValue: devToolsEnabled,
  );

  /// Feature switches for builds that ship with a feature hidden, e.g. a
  /// closed-testing build whose testers have no SilexGIS account or no
  /// beacons. Only the entry points are hidden; the code and the stored data
  /// stay, so switching a feature back on loses nothing. Override with
  /// `--dart-define=FEATURE_SILEXGIS=false` / `FEATURE_BEACONS=false`.
  static const bool silexgisEnabled = bool.fromEnvironment(
    'FEATURE_SILEXGIS',
    defaultValue: true,
  );

  /// Bluetooth beacons: settings, the drawer's detection toggle, the
  /// per-place and per-cave beacon screens, and background detection.
  static const bool beaconsEnabled = bool.fromEnvironment(
    'FEATURE_BEACONS',
    defaultValue: true,
  );
}
