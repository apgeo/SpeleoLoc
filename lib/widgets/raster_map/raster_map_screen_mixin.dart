import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/general_data/raster_maps_page.dart';

/// Shared behavior for screens that host a [RasterMapPlacePointEditor]
/// (currently `RasterMapPlaceSelectorPage`, `MapViewerPage`, `CaveTripPage`).
///
/// Centralises the cross-cutting bits that previously had to be wired
/// independently in each page:
///   • opening the raster-maps management screen and reloading on change,
///   • detecting landscape-phone layout so pages can collapse extra UI.
///
/// Per-page state (the boolean `_isFullScreen`, repositories, controllers)
/// stays where it is — only the shared plumbing lives here.
mixin RasterMapScreenMixin<T extends StatefulWidget> on State<T> {
  /// Pushes [RasterMapsPage] for [caveUuid].  When the user returns and the
  /// page reports changes, [onChanged] is invoked so the screen can reload
  /// its title, raster-maps list, and any cached image providers.
  Future<void> openRasterMapsPage({
    required Uuid caveUuid,
    required VoidCallback onChanged,
  }) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RasterMapsPage(caveUuid: caveUuid),
      ),
    );
    if ((changed == true) && mounted) {
      onChanged();
    }
  }

  /// True when the device is a phone (short side &lt; 600 dp) currently held
  /// in landscape orientation. Mirrors the editor's internal helper so the
  /// host screen can hide secondary UI (e.g. action toolbars) when the user
  /// rotates to landscape.
  bool get isLandscapePhone => isLandscapePhoneForContext(context);

  /// Static-style helper for callers without `BuildContext` ambient state.
  static bool isLandscapePhoneForContext(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.shortestSide < 600 && size.width > size.height;
  }
}
