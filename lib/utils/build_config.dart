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
    defaultValue: kDebugMode,
  );
}
