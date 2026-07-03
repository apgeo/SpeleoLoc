import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/widgets/raster_map/raster_map_editor_constants.dart';
import 'package:speleoloc/widgets/raster_map/raster_map_sort_options.dart';
import 'package:speleoloc/widgets/raster_map_nav_bar.dart';

/// The subset of the editor State's behaviour that
/// [RasterMapPlacePointEditorController] drives. The editor State implements
/// this so the controller can hold a reference to the editor without depending
/// on the private State type (lets the controller live in its own file).
abstract interface class RasterMapEditorHost {
  void setVisiblePlaceUuids(Set<Uuid>? uuids);
  void setShowLegend(bool v);
  void setShowZoomControls(bool v);
  void setGestureZoomEnabled(bool v);
  void setUseImageTextColor(bool v);
  void applyControllerCavePlaceId();
  void zoomToPoint(double imageX, double imageY, {double zoomLevel});
  void moveToPoint(
    double imageX,
    double imageY, {
    double? targetScale,
    bool animate,
  });
  void zoomIn();
  void zoomOut();
  void resetZoom();
  void zoomToFitPoints(List<Offset> imagePoints, {double padding});
  void setShowNavBar(bool v);
  void setShowTapModeCheckbox(bool v);
  void toggleNavBarCavePlaceFilter();
  void setToolbarVisible(bool v);
  Future<void> navigateToNextUndefined();
  void ensurePlacesListVisible();
  void ensureMapsListVisible();
  void ensureBothListsVisible();
  void setFullScreen(bool v);
  void setColorInverted(bool v);
}

/// - `isReadonly` - when true, taps won't change the selected point.
/// - `onImagePointChanged` - callback(ImageX, ImageY) when user selects a point.
///
/// NOTE: this widget keeps its own PhotoViewController and internal state so
/// it can be reused in multiple places.
class RasterMapPlacePointEditorController {
  RasterMapPlacePointEditorController({
    this.showLegend = false,
    this.showZoomControls = true,
    this.gestureZoomEnabled = true,
    this.useImageTextColor = false,
    this.cavePlaceUuid,
    this.showNavBar = false,
    this.showTapModeCheckbox = false,
    this.autoZoomToPoints = true,
    this.animatePointTransitions = false,
    this.autoSaveSnackbarNotificationDuration =
        RasterMapEditorConstants.shortSnackbarDuration,
    this.textOutlineEnabled = true,
    this.textOutlineWidth = RasterMapEditorConstants.defaultTextOutlineWidth,
    this.textBackgroundEnabled = false,
    this.fadeFilteredMarkers = true,
    this.keepZoomOnNavigation = false,
    this.initialZoomLevel = RasterMapEditorConstants.defaultInitialZoomLevel,
    this.initialTapDefinesNewPoint = false,
  });

  RasterMapEditorHost? _host;

  /// Binds this controller to an editor [host]. Called by the editor State in
  /// its initState/didUpdateWidget; not intended for app code.
  void attach(RasterMapEditorHost host) => _host = host;

  /// Controls whether the embedded legend is shown.
  bool showLegend;

  /// Controls whether the embedded zoom/reset button section is shown.
  bool showZoomControls;

  /// Whether pinch/gesture zooming is enabled.
  bool gestureZoomEnabled;

  /// When true the widget will sample decoded image pixels to choose a
  /// label color via `_getTextColor`. When false (default) the widget
  /// will NOT decode/cache raw image data and will use a default label
  /// color instead (improves performance / reduces memory usage).
  bool useImageTextColor;

  /// Optional default cavePlaceUuid to indicate which cave place should be
  /// considered the initial selected place (editor will highlight it).
  Uuid? cavePlaceUuid;

  /// Whether the embedded navigation bar (raster maps + cave places lists)
  /// is visible.
  bool showNavBar;

  /// Whether the tap-mode checkbox (define-point vs select-place) should
  /// be displayed. Only relevant in edit/add mode (not readonly).
  bool showTapModeCheckbox;

  /// When false, the editor will NOT automatically zoom/pan to points
  /// (e.g. when a marker is tapped or a cave place is selected in the nav bar).
  bool autoZoomToPoints;

  /// When true, point-to-point navigation uses a short animated pan/zoom.
  bool animatePointTransitions;

  /// Duration of the auto-save snackbar shown after switching places.
  Duration autoSaveSnackbarNotificationDuration;

  /// When true, marker label text is rendered with an outline stroke in the
  /// opposite color for readability on any background. Enabled by default.
  bool textOutlineEnabled;

  /// Stroke width for the text outline (only used when [textOutlineEnabled]).
  double textOutlineWidth;

  /// When true, a 40%-transparent rounded-corner background box is drawn
  /// behind marker label text for additional readability. Disabled by default.
  bool textBackgroundEnabled;

  /// When true (default) and a cave-places text filter is active, markers for
  /// filtered-out places are rendered at 25 % opacity with no label so the
  /// user can still see where they are on the map.
  /// When false, filtered-out markers are hidden entirely.
  bool fadeFilteredMarkers;

  /// When true, navigating to another point preserves the current zoom level
  /// instead of resetting/changing it.
  bool keepZoomOnNavigation;

  /// Initial zoom level to apply when the editor first renders. Default 1.0
  /// (=contained). Use a smaller value (e.g. 0.8) for a wider view.
  double initialZoomLevel;

  /// When true the editor starts in define-point tap mode (new-point tap).
  /// When false (default) it starts in select-place mode.
  bool initialTapDefinesNewPoint;

  /// Current sort option applied to the raster-map nav bar thumbnails.
  /// Defaults to [RasterMapSortField.orderIndex] ascending (DB order).
  RasterMapSortOption sortOption = const RasterMapSortOption();

  /// When set, the editor delegates nav-bar interactions (filter toggle,
  /// ensure-item-visible, set-selected-place) to this external key instead
  /// of its own internal embedded-nav-bar key. Set this in [initState] of
  /// the parent page when the [RasterMapNavBar] is built outside the editor.
  GlobalKey<RasterMapNavBarState>? externalNavBarKey;

  /// Update the set of cave-place UUIDs visible after text filtering.
  /// Passing null clears the filter (all places visible). Call this from
  /// the parent page when using an external [RasterMapNavBar] so that
  /// filtered-out markers are faded/hidden on the map.
  void setVisiblePlaceUuids(Set<Uuid>? uuids) =>
      _host?.setVisiblePlaceUuids(uuids);

  void setShowLegend(bool v) {
    showLegend = v;
    _host?.setShowLegend(v);
  }

  void setShowZoomControls(bool v) {
    showZoomControls = v;
    _host?.setShowZoomControls(v);
  }

  void setGestureZoomEnabled(bool v) {
    gestureZoomEnabled = v;
    _host?.setGestureZoomEnabled(v);
  }

  /// Enable/disable sampling the image to determine label text color.
  void setUseImageTextColor(bool v) {
    useImageTextColor = v;
    _host?.setUseImageTextColor(v);
  }

  /// Update the default cavePlaceUuid at runtime and notify the state.
  void setCavePlaceId(Uuid? id) {
    cavePlaceUuid = id;
    _host?.applyControllerCavePlaceId();
  }

  /// Zooms/pans to center the provided image-space point.
  void zoomToPoint(
    double imageX,
    double imageY, {
    double zoomLevel = RasterMapEditorConstants.defaultZoomToPointLevel,
  }) => _host?.zoomToPoint(imageX, imageY, zoomLevel: zoomLevel);

  /// Pans to center the given image-space point while keeping the current zoom.
  void panToPoint(double imageX, double imageY) =>
      _host?.moveToPoint(imageX, imageY, animate: animatePointTransitions);

  void zoomIn() => _host?.zoomIn();
  void zoomOut() => _host?.zoomOut();
  void resetZoom() => _host?.resetZoom();

  /// Zoom/pan to fit a bounding box of image-space points.
  void zoomToFitPoints(
    List<Offset> imagePoints, {
    double padding = RasterMapEditorConstants.defaultZoomToFitPadding,
  }) => _host?.zoomToFitPoints(imagePoints, padding: padding);

  void setShowNavBar(bool v) {
    showNavBar = v;
    _host?.setShowNavBar(v);
  }

  /// Detaches the controller from its current editor state.
  /// Call this in dispose() of pages that own this controller.
  void detach() {
    _host = null;
  }

  /// Detaches only if [host] is the currently-bound editor. Called by the
  /// editor State in its dispose/didUpdateWidget so a stale State teardown
  /// does not clear a binding that has already moved to a newer State.
  void detachHost(RasterMapEditorHost host) {
    if (_host == host) _host = null;
  }

  void setShowTapModeCheckbox(bool v) {
    showTapModeCheckbox = v;
    _host?.setShowTapModeCheckbox(v);
  }

  /// Update the animate-point-transitions flag. Reads by the state at
  /// navigation time, so no immediate rebuild is required.
  void setAnimatePointTransitions(bool v) {
    animatePointTransitions = v;
  }

  /// Toggles the cave-places filter text field in the embedded nav bar.
  void toggleCavePlaceFilter() => _host?.toggleNavBarCavePlaceFilter();

  /// Programmatically show or hide the side toolbar.
  void setToolbarVisible(bool v) => _host?.setToolbarVisible(v);

  /// Navigates (selects) the next cave place that has no point defined for
  /// the current raster map.
  void navigateToNextUndefined() => _host?.navigateToNextUndefined();

  /// Ensures the cave-places horizontal list is visible.
  void ensurePlacesListVisible() => _host?.ensurePlacesListVisible();

  /// Ensures the raster-maps horizontal list is visible.
  void ensureMapsListVisible() => _host?.ensureMapsListVisible();

  /// Ensures both horizontal lists are visible (call when switching format).
  void ensureBothListsVisible() => _host?.ensureBothListsVisible();

  /// Enters or leaves full-screen mode (hides the nav bar; the parent should
  /// hide its own AppBar via the [onFullScreenChanged] callback).
  void setFullScreen(bool v) => _host?.setFullScreen(v);

  /// Inverts or restores the raster-map image colours.
  void setColorInverted(bool v) => _host?.setColorInverted(v);
}
