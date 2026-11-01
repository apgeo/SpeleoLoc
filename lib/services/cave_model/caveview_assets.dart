/// Where the 3D viewer's host page and the vendored CaveView build sit among
/// the app's assets.
abstract final class CaveViewAssets {
  /// The fork's distribution stamp. `tool/refresh_caveview.sh` writes each
  /// stamp to a directory of its own; pubspec.yaml lists the same directory.
  static const version = '2.9.0-slx.23';

  static const hostDir = 'assets/caveview/host';
  static const buildDir = 'assets/caveview/v$version';
}
