import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:photo_view/photo_view.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/widgets/raster_map_points_legend.dart';
import 'package:speleoloc/widgets/raster_map_nav_bar.dart';
import 'package:speleoloc/widgets/raster_map_image_cache.dart';
import 'package:speleoloc/widgets/raster_map_marker_builder.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/utils/raw_image_data.dart';
import 'package:speleoloc/screens/cave_place_page.dart';
import 'package:speleoloc/screens/general_data/documentation_files_page.dart';
import 'package:speleoloc/widgets/add_cave_place_popup.dart';

// Re-export so existing callers (e.g. MapViewerPage) that import the image
// cache functions from this file continue to work without changes.
export 'package:speleoloc/widgets/raster_map_image_cache.dart';

/// Trip overlay data for displaying trip route on a raster map.
///
/// Contains the ordered sequence of cave place IDs visited during a trip.
/// The editor uses this together with [CavePlaceWithDefinition] data to
/// draw lines between consecutive points, direction arrows, and incremental
/// numbering.
class TripOverlayData {
  /// Ordered list of cave place IDs in the order they were visited.
  /// A place may appear more than once if revisited during the trip.
  final List<int> orderedCavePlaceIds;

  /// Line/arrow color for the trip route.
  final Color routeColor;

  /// Line width for the trip route.
  final double routeLineWidth;

  /// Size of the incremental number labels.
  final double numberFontSize;

  const TripOverlayData({
    required this.orderedCavePlaceIds,
    this.routeColor = Colors.blue,
    this.routeLineWidth = 2.5,
    this.numberFontSize = 12.0,
  });
}


/// A reusable widget that encapsulates PhotoView-based image display,
/// tapping to select a point (image-space coordinates), zoom/pan controls
/// and overlaying existing/selected markers.
///
/// - `imageFile` (required) - source image file to display.
/// - `cavePlacesWithDefinitions` - used to draw existing definition markers.
/// - `initialImageX`/`initialImageY` - optional initial image-space selection.
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
    this.cavePlaceId,
    this.showNavBar = false,
    this.showTapModeCheckbox = false,
    this.autoZoomToPoints = true,
    this.animatePointTransitions = false,
    this.autoSaveSnackbarNotificationDuration = const Duration(seconds: 1),
    this.textOutlineEnabled = true,
    this.textOutlineWidth = 2.0,
    this.textBackgroundEnabled = false,
    this.keepZoomOnNavigation = false,
    this.initialZoomLevel = 1.0,
  });

  _RasterMapPlacePointEditorState? _state;

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

  /// Optional default cavePlaceId to indicate which cave place should be
  /// considered the initial selected place (editor will highlight it).
  int? cavePlaceId;

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

  /// When true, navigating to another point preserves the current zoom level
  /// instead of resetting/changing it.
  bool keepZoomOnNavigation;

  /// Initial zoom level to apply when the editor first renders. Default 1.0
  /// (=contained). Use a smaller value (e.g. 0.8) for a wider view.
  double initialZoomLevel;

  void setShowLegend(bool v) {
    showLegend = v;
    _state?._setShowLegend(v);
  }

  void setShowZoomControls(bool v) {
    showZoomControls = v;
    _state?._setShowZoomControls(v);
  }

  void setGestureZoomEnabled(bool v) {
    gestureZoomEnabled = v;
    _state?._setGestureZoomEnabled(v);
  }

  /// Enable/disable sampling the image to determine label text color.
  void setUseImageTextColor(bool v) {
    useImageTextColor = v;
    _state?._setUseImageTextColor(v);
  }

  /// Update the default cavePlaceId at runtime and notify the state.
  void setCavePlaceId(int? id) {
    cavePlaceId = id;
    _state?._applyControllerCavePlaceId();
  }

  /// Zooms/pans to center the provided image-space point.
  void zoomToPoint(double imageX, double imageY, {double zoomLevel = 2.5}) =>
      _state?.zoomToPoint(imageX, imageY, zoomLevel: zoomLevel);

  /// Pans to center the given image-space point while keeping the current zoom.
  void panToPoint(double imageX, double imageY) =>
      _state?._moveToPoint(imageX, imageY, animate: animatePointTransitions);

  void zoomIn() => _state?.zoomIn();
  void zoomOut() => _state?.zoomOut();
  void resetZoom() => _state?.resetZoom();

  /// Zoom/pan to fit a bounding box of image-space points.
  void zoomToFitPoints(List<Offset> imagePoints, {double padding = 40.0}) =>
      _state?._zoomToFitPoints(imagePoints, padding: padding);

  void setShowNavBar(bool v) {
    showNavBar = v;
    _state?._setShowNavBar(v);
  }

  /// Detaches the controller from its current editor state.
  /// Call this in dispose() of pages that own this controller.
  void detach() {
    _state = null;
  }

  void setShowTapModeCheckbox(bool v) {
    showTapModeCheckbox = v;
    _state?._setShowTapModeCheckbox(v);
  }

  /// Update the animate-point-transitions flag. Reads by the state at
  /// navigation time, so no immediate rebuild is required.
  void setAnimatePointTransitions(bool v) {
    animatePointTransitions = v;
  }
}

class RasterMapPlacePointEditor extends StatefulWidget {
  const RasterMapPlacePointEditor({
    super.key,
    required this.imageFile,
    required this.cavePlacesWithDefinitions,
    this.initialImageX,
    this.initialImageY,
    this.isReadonly = false,
    this.debugUi = false,
    this.showLegend = false,
    this.showZoomControls = true,
    this.gestureZoomEnabled = true,

    /// When sampling is disabled, `defaultLabelColor` is used for all
    /// marker/label text. Default is `Colors.white`.
    this.defaultLabelColor = Colors.white,

    this.useImageTextColor = false,
    this.useSimpleViewerForTests = false,
    this.imageProvider,
    this.controller,
    this.onImagePointChanged,
    this.onMarkerTap,

    /// Nav bar integration
    this.showNavBar = false,
    this.showTapModeCheckbox = false,
    this.rasterMaps = const [],
    this.selectedRasterMapId,
    this.navBarStyle = const RasterMapNavBarStyle.compact(),
    this.onRasterMapSelected,
    this.onCavePlaceSelected,
    this.onAutoSaveRequested,
    this.onRemoveDefinitionRequested,
    this.onCavePlaceAdded,
    this.onSaveDefinitionRequested,
    this.caveId,
    this.tripOverlay,
  });

  final File imageFile;
  final List<CavePlaceWithDefinition> cavePlacesWithDefinitions;
  final double? initialImageX;
  final double? initialImageY;
  final bool isReadonly;
  final bool debugUi;

  /// Widget-level defaults (controller can override at runtime)
  final bool showLegend;
  final bool showZoomControls;
  final bool gestureZoomEnabled;

  /// When true the widget will sample decoded image pixels to determine
  /// label text color. Default is false (no decoding/cache).
  final bool useImageTextColor;

  /// Color to use for labels when image-based sampling is disabled or
  /// when sampling can't determine a color. Default: `Colors.white`.
  final Color defaultLabelColor;

  final bool useSimpleViewerForTests;
  final ImageProvider? imageProvider; // optional cached provider (MapViewerPage passes this)
  final RasterMapPlacePointEditorController? controller;
  final void Function(double imageX, double imageY)? onImagePointChanged;

  /// Called when an existing place marker (definition) is tapped. The
  /// provided `CavePlaceWithDefinition` contains the cave place and the
  /// corresponding definition with image-space coordinates.
  final void Function(CavePlaceWithDefinition cpwd)? onMarkerTap;

  // ---- Nav bar integration ----

  /// Whether to show the embedded [RasterMapNavBar] above the image.
  final bool showNavBar;

  /// Whether to show the define-point / select-place checkbox (edit mode only).
  final bool showTapModeCheckbox;

  /// List of raster maps for the nav bar. Only needed when [showNavBar] is true.
  final List<RasterMap> rasterMaps;

  /// Currently selected raster map id (for nav bar highlight).
  final int? selectedRasterMapId;

  /// Visual style for the embedded nav bar (defaults to compact).
  final RasterMapNavBarStyle navBarStyle;

  /// Called when the user picks a different raster map via the nav bar.
  final void Function(RasterMap rm)? onRasterMapSelected;

  /// Called when the user picks a different cave place via the nav bar.
  final void Function(CavePlaceWithDefinition cpwd)? onCavePlaceSelected;

  /// Called before switching cave place / raster map in editor mode so the
  /// parent can auto-save the current new-point selection. The callback
  /// receives (cavePlaceId, rasterMapId, imageX, imageY) of the pending
  /// point and returns whether the switch should proceed.
  final Future<bool> Function(int cavePlaceId, int rasterMapId, double imageX, double imageY)? onAutoSaveRequested;

  /// Called when the user requests to remove the current cave place definition
  /// for the selected raster map. The callback receives (cavePlaceId, rasterMapId).
  /// Should return true if the definition was successfully removed.
  final Future<bool> Function(int cavePlaceId, int rasterMapId)? onRemoveDefinitionRequested;

  /// Called after a new cave place has been created from the inline add-place
  /// popup. The parent should refresh its cave places list.
  final VoidCallback? onCavePlaceAdded;

  /// Called when the user taps the save/define button. The parent should
  /// save the current point and optionally pop the page.
  final VoidCallback? onSaveDefinitionRequested;

  /// Cave id — needed for the add-cave-place popup to know which cave to add
  /// a place to. Only required when [onCavePlaceAdded] is provided.
  final int? caveId;

  /// Optional trip overlay data. When provided, the editor draws the trip
  /// route (lines, direction arrows, and incremental point numbers) on top
  /// of the raster map.
  final TripOverlayData? tripOverlay;

  @override
  State<RasterMapPlacePointEditor> createState() =>
      _RasterMapPlacePointEditorState();
}

class _RasterMapPlacePointEditorState extends State<RasterMapPlacePointEditor> with TickerProviderStateMixin {
  // Selected image-space coordinates
  double? _imageSelectedX;
  double? _imageSelectedY;

  // PhotoView controllers
  late PhotoViewController _photoViewController;
  late PhotoViewScaleStateController _scaleStateController;

  // Stream subscription for PhotoView state changes (#9 fix)
  StreamSubscription? _pvSubscription;

  // Decoded image for color-sampling (now stored as raw RGBA for fast sampling)
  RawImageData? _img;

  // Last-known PhotoView viewport size (updated in the LayoutBuilder). This
  // is used by `zoomToPoint` so offsets are computed relative to the actual
  // editor viewport instead of the full screen (fixes image moving off-screen).
  Size? _photoViewportSize;

  late bool _showLegend;
  late bool _showZoomControls;
  late bool _gestureZoomEnabled;
  late bool _useImageTextColor;

  // If controller provided a cavePlaceId, the editor will show the
  // coordinates for that cave place here (initial highlight). This is
  // separate from _imageSelectedX/Y which represent user selection.
  double? _initialControllerCavePlaceX;
  double? _initialControllerCavePlaceY;
  String? _initialControllerCavePlaceTitle;

  // Tracks if the user has tapped/selected a *new* point in the editor.
  // Blue+orange filled markers are shown only when this is true.
  bool _userHasSelectedNewPoint = false;

  // Pulse animation when a marker is tapped
  late final AnimationController _pulseController;
  double? _pulseImageX;
  double? _pulseImageY;

  // Pan/zoom animation for point transitions
  late final AnimationController _panZoomController;
  Tween<double>? _scaleTween;
  Offset? _panStart;
  Offset? _panEnd;

  // Nav bar visibility + tap mode
  late bool _showNavBar;
  late bool _showTapModeCheckbox;

  /// When true, tapping on the map defines a new point (default edit mode).
  /// When false, tapping selects an existing marker instead.
  bool _tapDefinesNewPoint = true;

  /// When true, next image tap captures coordinates for a new cave place.
  bool _waitingForNewCavePlaceTap = false;

  // Key for the embedded nav bar (for programmatic scrolling)
  final GlobalKey<RasterMapNavBarState> _navBarKey = GlobalKey<RasterMapNavBarState>();

  static const bool SHOW_SAVE_CAVE_PLACE_BUTTON = false;

  @override
  void initState() {
    super.initState();
    _imageSelectedX = widget.initialImageX;
    _imageSelectedY = widget.initialImageY;

    // initial visibility/gesture settings: controller overrides widget defaults
    _showLegend = widget.controller?.showLegend ?? widget.showLegend;
    _showZoomControls =
        widget.controller?.showZoomControls ?? widget.showZoomControls;
    _gestureZoomEnabled =
        widget.controller?.gestureZoomEnabled ?? widget.gestureZoomEnabled;

    // whether to sample image pixels for label text color (controller/widget)
    _useImageTextColor = widget.controller?.useImageTextColor ?? widget.useImageTextColor;

    // nav bar / tap-mode visibility
    _showNavBar = widget.controller?.showNavBar ?? widget.showNavBar;
    _showTapModeCheckbox = widget.controller?.showTapModeCheckbox ?? widget.showTapModeCheckbox;

    // wire controller -> state if controller provided
    widget.controller?._state = this;

    // apply controller's cavePlaceId (if any) so initial highlight shows
    _applyControllerCavePlaceId();

    _photoViewController = PhotoViewController();
    _scaleStateController = PhotoViewScaleStateController();

    _pvSubscription = _photoViewController.outputStateStream.listen((value) {
      // rebuild markers when zoom/pan changes
      if (mounted) setState(() {});
    });

    // pulse animation controller for marker-tap feedback
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 420))
      ..addListener(() {
        if (mounted) setState(() {});
      });

    _panZoomController = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
      ..addListener(() {
        final t = _panZoomController.value;
        final start = _panStart ?? _photoViewController.position;
        final end = _panEnd ?? start;
        final pos = Offset.lerp(start, end, t) ?? end;
        final scale = _scaleTween?.transform(t) ?? (_photoViewController.scale ?? 1.0);
        _photoViewController.position = pos;
        _photoViewController.scale = scale;
      });

    // Decode image only when image-sampling for label color is enabled.
    // Otherwise ensure we do not hold or populate the decoded-image cache
    // for this image (performance / memory optimization).
    if (_useImageTextColor) {
      // Decode image. In tests we allow the synchronous path; in normal
      // runtime decode happens inside an isolate via `compute` to avoid
      // blocking the UI thread on large images.
      if (widget.useSimpleViewerForTests) {
        try {
          final decoded = img.decodeImage(widget.imageFile.readAsBytesSync());
          if (decoded != null) {
            final pixels = Uint8List.fromList(decoded.getBytes());
            _img = RawImageData(decoded.width, decoded.height, pixels);
          } else {
            _img = null;
          }
        } catch (_) {
          _img = null;
        }
      } else {
        // use persistent cache to avoid re-decoding when switching maps
        decodeImageToRawCached(widget.imageFile.path).then((raw) {
          if (raw != null && mounted) {
            setState(() {
              _img = raw;
            });
          }
        }).catchError((_) {
          // ignore failures; _img stays null
        });
      }
    } else {
      // sampling disabled: clear any existing decoded cache for this image
      _img = null;
      decodedImageCache.remove(widget.imageFile.path);
    }
  }

  @override
  void dispose() {
    // Auto-save modified point when navigating away
    _saveDefinitionIfNeeded();
    // detach controller reference
    if (widget.controller?._state == this) widget.controller?._state = null;
    _pvSubscription?.cancel();
    _photoViewController.dispose();
    _scaleStateController.dispose();
    _pulseController.dispose();
    _panZoomController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RasterMapPlacePointEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the image file changed (raster map switch), reset decoded sampling
    // data so stale pixels from the old image are not used for text color.
    if (widget.imageFile.path != oldWidget.imageFile.path) {
      _img = null;
      if (_useImageTextColor) {
        if (widget.useSimpleViewerForTests) {
          try {
            final decoded = img.decodeImage(widget.imageFile.readAsBytesSync());
            if (decoded != null) {
              final pixels = Uint8List.fromList(decoded.getBytes());
              if (mounted) setState(() => _img = RawImageData(decoded.width, decoded.height, pixels));
            }
          } catch (e) {
            debugPrint('[RasterMapPlacePointEditor] Error decoding image: $e');
          }
        } else {
          decodeImageToRawCached(widget.imageFile.path).then((raw) {
            if (raw != null && mounted) setState(() => _img = raw);
          }).catchError((e) {
            debugPrint('[RasterMapPlacePointEditor] Error decoding image async: $e');
          });
        }
      }
    }

    // prefer controller setting; otherwise fall back to widget prop
    final newVal = widget.controller?.useImageTextColor ?? widget.useImageTextColor;
    final oldVal = oldWidget.controller?.useImageTextColor ?? oldWidget.useImageTextColor;
    if (newVal != oldVal) _setUseImageTextColor(newVal);

    // if controller instance changed, rebind state
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?._state == this) oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }

    // If the cave-places list was replaced (e.g. after async DB reload in the
    // parent), re-apply the controller's cavePlaceId so the blue selected-place
    // marker is built with the up-to-date coordinate data.
    if (widget.cavePlacesWithDefinitions != oldWidget.cavePlacesWithDefinitions) {
      _applyControllerCavePlaceId();
    }
  }

  // Methods used by controller to update state at runtime
  void _setShowLegend(bool v) {
    if (mounted) setState(() => _showLegend = v);
  }

  void _setShowZoomControls(bool v) {
    if (mounted) setState(() => _showZoomControls = v);
  }

  void _setGestureZoomEnabled(bool v) {
    if (mounted) setState(() => _gestureZoomEnabled = v);
  }

  void _setShowNavBar(bool v) {
    if (mounted) setState(() => _showNavBar = v);
  }

  void _setShowTapModeCheckbox(bool v) {
    if (mounted) setState(() => _showTapModeCheckbox = v);
  }

  void _setUseImageTextColor(bool v) {
    if (!mounted) return;
    if (_useImageTextColor == v) return;
    setState(() => _useImageTextColor = v);

    if (v) {
      // enable sampling -> decode now (same logic as initState)
      if (widget.useSimpleViewerForTests) {
        try {
          final decoded = img.decodeImage(widget.imageFile.readAsBytesSync());
          if (decoded != null) {
            final pixels = Uint8List.fromList(decoded.getBytes());
            setState(() => _img = RawImageData(decoded.width, decoded.height, pixels));
          }
        } catch (_) {
          setState(() => _img = null);
        }
      } else {
        decodeImageToRawCached(widget.imageFile.path).then((raw) {
          if (raw != null && mounted) setState(() => _img = raw);
        }).catchError((_) {
          // ignore
        });
      }
    } else {
      // disable sampling -> clear local decoded image and cache entry
      decodedImageCache.remove(widget.imageFile.path);
      setState(() => _img = null);
    }
  }

  /// Apply controller-provided `cavePlaceId` by locating the corresponding
  /// definition (if present) in `widget.cavePlacesWithDefinitions` and
  /// storing its image-space coordinates in `_initialControllerCavePlaceX/Y`.
  void _applyControllerCavePlaceId() {
    final id = widget.controller?.cavePlaceId;
    if (id == null) {
      if (_initialControllerCavePlaceX != null || _initialControllerCavePlaceY != null) {
        if (mounted) {
          setState(() {
          _initialControllerCavePlaceX = null;
          _initialControllerCavePlaceY = null;
          _initialControllerCavePlaceTitle = null;
        });
        }
      }
      return;
    }

    try {
      final cpwd = widget.cavePlacesWithDefinitions.where((c) => c.cavePlace.id == id).firstOrNull;
      if (cpwd == null) return;
      final def = cpwd.definition;
      if (def != null && def.xCoordinate != null && def.yCoordinate != null) {
        final x = def.xCoordinate!.toDouble();
        final y = def.yCoordinate!.toDouble();
        if (mounted) {
          setState(() {
          _initialControllerCavePlaceX = x;
          _initialControllerCavePlaceY = y;
          _initialControllerCavePlaceTitle = cpwd.cavePlace.title;
        });
        }
        return;
      }
    } catch (_) {
      // not found or no definition; fallthrough to clear
    }

    if (mounted) {
      setState(() {
      _initialControllerCavePlaceX = null;
      _initialControllerCavePlaceY = null;
      _initialControllerCavePlaceTitle = null;
    });
    }
  }

  /// Transform image-space coordinates to PhotoView viewport-space coordinates.
  Offset _imageToViewportCoordinates(
    double imageX,
    double imageY,
    PhotoViewControllerValue controllerValue,
  ) => RasterMapMarkerBuilder.imageToViewport(imageX, imageY, controllerValue);

  String _resolveSelectedCavePlaceTitle() {
    if (_initialControllerCavePlaceTitle != null &&
        _initialControllerCavePlaceTitle!.trim().isNotEmpty) {
      return _initialControllerCavePlaceTitle!;
    }

    final controllerId = widget.controller?.cavePlaceId;
    if (controllerId != null) {
      final match = widget.cavePlacesWithDefinitions
          .where((c) => c.cavePlace.id == controllerId)
          .firstOrNull;
      if (match != null) return match.cavePlace.title;
    }

    if (widget.initialImageX != null && widget.initialImageY != null) {
      final initialX = widget.initialImageX!.toInt();
      final initialY = widget.initialImageY!.toInt();
      final match = widget.cavePlacesWithDefinitions.where((c) {
        final def = c.definition;
        if (def == null) return false;
        return def.xCoordinate == initialX && def.yCoordinate == initialY;
      }).firstOrNull;
      if (match != null) return match.cavePlace.title;
    }

    return '';
  }

  Future<void> _onImageTap(
    TapDownDetails details,
    PhotoViewControllerValue controllerValue,
  ) async {
    if (widget.isReadonly) return;

    final pos = details.localPosition;
    final offset = controllerValue.position;
    final scale = controllerValue.scale ?? 1.0;

    final rawX = (pos.dx - offset.dx) / scale;
    final rawY = (pos.dy - offset.dy) / scale;

    // When waiting for a new-cave-place tap, capture coordinates,
    // open popup, and auto-save the definition.
    if (_waitingForNewCavePlaceTap) {
      final imgW = _img?.width.toDouble();
      final imgH = _img?.height.toDouble();
      final mxX = (imgW != null && imgW > 0) ? (imgW - 1.0) : double.infinity;
      final mxY = (imgH != null && imgH > 0) ? (imgH - 1.0) : double.infinity;
      final cx = rawX.clamp(0.0, mxX);
      final cy = rawY.clamp(0.0, mxY);
      setState(() => _waitingForNewCavePlaceTap = false);

      if (widget.caveId == null) return;
      final newId = await showDialog<int?>(
        context: context,
        builder: (ctx) => AddCavePlacePopup(caveId: widget.caveId!),
      );
      if (newId != null && mounted) {
        if (widget.onAutoSaveRequested != null && widget.selectedRasterMapId != null) {
          await widget.onAutoSaveRequested!(newId, widget.selectedRasterMapId!, cx, cy);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocServ.inst.t('cave_place_added')),
            duration: const Duration(seconds: 1),
          ),
        );
        widget.onCavePlaceAdded?.call();
      }
      return;
    }

    // When in "select place" tap mode, find the closest existing marker
    // if the tap is within a threshold distance and select it instead of
    // defining a new point.
    if (!_tapDefinesNewPoint) {
      const double hitThreshold = 30.0; // viewport pixels
      CavePlaceWithDefinition? nearest;
      double nearestDist = double.infinity;
      for (final cpwd in widget.cavePlacesWithDefinitions) {
        final def = cpwd.definition;
        if (def == null || def.xCoordinate == null || def.yCoordinate == null) continue;
        final vp = _imageToViewportCoordinates(
          def.xCoordinate!.toDouble(),
          def.yCoordinate!.toDouble(),
          controllerValue,
        );
        final dist = (vp - pos).distance;
        if (dist < nearestDist) {
          nearestDist = dist;
          nearest = cpwd;
        }
      }
      if (nearest != null && nearestDist <= hitThreshold) {
        _startPulseAtImagePoint(
          nearest.definition!.xCoordinate!.toDouble(),
          nearest.definition!.yCoordinate!.toDouble(),
        );
        await _handleNavCavePlaceSelected(nearest, notifyMarkerTap: true);
        _navBarKey.currentState?.setSelectedPlaceId(nearest.cavePlace.id);
      }
      return;
    }

    final imgWidth = _img?.width.toDouble();
    final imgHeight = _img?.height.toDouble();

    final maxX = (imgWidth != null && imgWidth > 0) ? (imgWidth - 1.0) : double.infinity;
    final maxY = (imgHeight != null && imgHeight > 0) ? (imgHeight - 1.0) : double.infinity;

    final clampedX = rawX.clamp(0.0, maxX);
    final clampedY = rawY.clamp(0.0, maxY);

    // mark that user explicitly selected a new point — used to control
    // whether the blue+orange 'new' marker is displayed.
    _userHasSelectedNewPoint = true;

    setState(() {
      _imageSelectedX = clampedX;
      _imageSelectedY = clampedY;
    });

    widget.onImagePointChanged?.call(_imageSelectedX!, _imageSelectedY!);
  }

  void zoomIn() {
    _photoViewController.scale = (_photoViewController.scale! * 1.2).clamp(
      0.01,
      5.0,
    );
  }

  void zoomOut() {
    _photoViewController.scale = (_photoViewController.scale! / 1.2).clamp(
      0.01,
      5.0,
    );
  }

  void resetZoom() {
    _panZoomController.stop();
    _scaleStateController.scaleState = PhotoViewScaleState.initial;
    _photoViewController.position = Offset.zero;
  }

  /// Programmatically pan/zoom to center an image-space point in the viewport.
  void zoomToPoint(double imageX, double imageY, {double zoomLevel = 2.5}) {
    _photoViewController.scale = zoomLevel;

    // Prefer the actual PhotoView viewport size; fall back to full screen if
    // not available (defensive).
    final viewport = _photoViewportSize ?? MediaQuery.of(context).size;
    final offsetX = (viewport.width / 2) - (imageX * zoomLevel);
    final offsetY = (viewport.height / 2) - (imageY * zoomLevel);
    _photoViewController.position = Offset(offsetX, offsetY);
  }

  /// Zoom/pan to fit a bounding box of image-space points with padding.
  void _zoomToFitPoints(List<Offset> imagePoints, {double padding = 40.0}) {
    if (imagePoints.isEmpty) return;
    final viewport = _photoViewportSize ?? MediaQuery.of(context).size;

    double minX = imagePoints.first.dx, maxX = minX;
    double minY = imagePoints.first.dy, maxY = minY;
    for (final p in imagePoints) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    final imageW = (maxX - minX).clamp(1.0, double.infinity);
    final imageH = (maxY - minY).clamp(1.0, double.infinity);
    final scaleX = (viewport.width - padding * 2) / imageW;
    final scaleY = (viewport.height - padding * 2) / imageH;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final clampedScale = scale.clamp(0.01, 5.0);

    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;
    final offsetX = (viewport.width / 2) - (centerX * clampedScale);
    final offsetY = (viewport.height / 2) - (centerY * clampedScale);
    _photoViewController.scale = clampedScale;
    _photoViewController.position = Offset(offsetX, offsetY);
  }

  bool _isZoomed() {
    return _scaleStateController.scaleState != PhotoViewScaleState.initial;
  }

  Offset _offsetForPoint(double imageX, double imageY, double scale) {
    final viewport = _photoViewportSize ?? MediaQuery.of(context).size;
    final offsetX = (viewport.width / 2) - (imageX * scale);
    final offsetY = (viewport.height / 2) - (imageY * scale);
    return Offset(offsetX, offsetY);
  }

  void _moveToPoint(
    double imageX,
    double imageY, {
    double? targetScale,
    bool animate = false,
  }) {
    final currentScale = _photoViewController.scale ?? 1.0;
    final endScale = targetScale ?? currentScale;
    final endPos = _offsetForPoint(imageX, imageY, endScale);

    if (!animate) {
      _photoViewController.scale = endScale;
      _photoViewController.position = endPos;
      return;
    }

    _panZoomController.stop();
    _panStart = _photoViewController.position;
    _panEnd = endPos;
    _scaleTween = Tween<double>(begin: currentScale, end: endScale);
    _panZoomController.forward(from: 0.0);
  }

  /// Start a short pulse animation centered at an image-space coordinate.
  void _startPulseAtImagePoint(double imageX, double imageY) {
    _pulseImageX = imageX;
    _pulseImageY = imageY;
    _pulseController.forward(from: 0.0);
  }

  /// Auto-save the current new-point selection if user has tapped a new point
  /// before switching to another raster map or cave place.
  Future<bool> _autoSaveIfNeeded() async {
    if (!_userHasSelectedNewPoint) return true;
    if (_imageSelectedX == null || _imageSelectedY == null) return true;

    final cavePlaceId = widget.controller?.cavePlaceId;
    final rasterMapId = widget.selectedRasterMapId;
    if (cavePlaceId == null || rasterMapId == null) return true;

    if (widget.onAutoSaveRequested != null) {
      final allowed = await widget.onAutoSaveRequested!(
        cavePlaceId,
        rasterMapId,
        _imageSelectedX!,
        _imageSelectedY!,
      );
      if (!allowed) return false;

      // Save occurred — show a brief snackbar with the place title.
      if (mounted) {
        String title = '';
        final match = widget.cavePlacesWithDefinitions
            .where((c) => c.cavePlace.id == cavePlaceId)
            .firstOrNull;
        if (match != null) title = match.cavePlace.title;
        if (title.isNotEmpty) {
          final dur = widget.controller?.autoSaveSnackbarNotificationDuration ?? const Duration(seconds: 1);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${LocServ.inst.t('new_point_saved_for')} $title'),
              duration: dur,
            ),
          );
        }
      }
    }

    // reset user-selected flag after saving
    _userHasSelectedNewPoint = false;
    _imageSelectedX = null;
    _imageSelectedY = null;
    return true;
  }

  Future<void> _handleNavRasterMapSelected(RasterMap rm) async {
    final canSwitch = await _autoSaveIfNeeded();
    if (!canSwitch) return;
    widget.onRasterMapSelected?.call(rm);
  }

  Future<void> _handleNavCavePlaceSelected(
    CavePlaceWithDefinition cpwd, {
    bool notifyMarkerTap = false,
  }) async {
    final canSwitch = await _autoSaveIfNeeded();
    if (!canSwitch) return;

    // Update controller to highlight the new cave place
    try {
      widget.controller?.setCavePlaceId(cpwd.cavePlace.id);
    } catch (_) {}

    // Zoom/pan to the new place's definition coordinates if available
    final autoZoom = widget.controller?.autoZoomToPoints ?? true;
    final animate = widget.controller?.animatePointTransitions ?? false;
    final keepZoom = widget.controller?.keepZoomOnNavigation ?? false;
    final def = cpwd.definition;
    if (def != null && def.xCoordinate != null && def.yCoordinate != null) {
      final imageX = def.xCoordinate!.toDouble();
      final imageY = def.yCoordinate!.toDouble();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (keepZoom) {
            // Always pan to point, keeping current scale
            _moveToPoint(imageX, imageY, animate: animate);
          } else if (_isZoomed()) {
            _moveToPoint(imageX, imageY, animate: animate);
          } else if (autoZoom) {
            _moveToPoint(imageX, imageY, targetScale: 1.2, animate: animate);
          }
        } catch (_) {}
      });
    }

    if (notifyMarkerTap) {
      widget.onMarkerTap?.call(cpwd);
    }
    widget.onCavePlaceSelected?.call(cpwd);
  }

  /// Reset the selected point back to the initial position (from when the
  /// cave place was selected). Only active when `_userHasSelectedNewPoint`.
  void _resetPointToInitial() {
    if (!_userHasSelectedNewPoint) return;
    setState(() {
      _userHasSelectedNewPoint = false;
      _imageSelectedX = widget.initialImageX;
      _imageSelectedY = widget.initialImageY;
    });
    widget.onImagePointChanged?.call(
      _imageSelectedX ?? 0,
      _imageSelectedY ?? 0,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocServ.inst.t('point_reset')),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  /// Show a confirmation dialog and remove the definition if confirmed.
  Future<void> _handleRemoveDefinition() async {
    final cavePlaceId = widget.controller?.cavePlaceId;
    final rasterMapId = widget.selectedRasterMapId;
    if (cavePlaceId == null || rasterMapId == null) return;
    if (widget.onRemoveDefinitionRequested == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocServ.inst.t('remove_definition')),
        content: Text(LocServ.inst.t('confirm_remove_definition')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(LocServ.inst.t('yes')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final removed = await widget.onRemoveDefinitionRequested!(cavePlaceId, rasterMapId);
    if (removed && mounted) {
      setState(() {
        _userHasSelectedNewPoint = false;
        _imageSelectedX = null;
        _imageSelectedY = null;
        _initialControllerCavePlaceX = null;
        _initialControllerCavePlaceY = null;
        _initialControllerCavePlaceTitle = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocServ.inst.t('definition_removed')),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  /// Activate add-cave-place flow: highlight button, show snackbar,
  /// and wait for user to tap on the map.
  void _handleAddCavePlace() {
    if (widget.caveId == null) return;
    setState(() => _waitingForNewCavePlaceTap = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocServ.inst.t('tap_on_map_to_define_place')),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Notify the parent to save the current point when the user has modified it.
  void _saveDefinitionIfNeeded() {
    if (_userHasSelectedNewPoint && widget.onSaveDefinitionRequested != null) {
      widget.onSaveDefinitionRequested!();
    }
  }

  /// Open CavePlacePage for the currently selected cave place.
  Future<void> _openCavePlacePage() async {
    _saveDefinitionIfNeeded();
    final cavePlaceId = widget.controller?.cavePlaceId;
    if (cavePlaceId == null) return;

    // Resolve caveId: use widget prop if available, otherwise look it up
    // from the cave places list (covers MapViewerPage where caveId is not passed).
    int? caveId = widget.caveId;
    if (caveId == null) {
      final match = widget.cavePlacesWithDefinitions
          .where((c) => c.cavePlace.id == cavePlaceId)
          .firstOrNull;
      caveId = match?.cavePlace.caveId;
    }
    if (caveId == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CavePlacePage(
          caveId: caveId!,
          cavePlaceId: cavePlaceId,
        ),
      ),
    );
    // Reload data after returning
    if (mounted) {
      widget.onCavePlaceAdded?.call();
    }
  }

  /// Open DocumentationFilesPage for the currently selected cave place.
  Future<void> _openCavePlaceDocuments() async {
    _saveDefinitionIfNeeded();
    final cavePlaceId = widget.controller?.cavePlaceId;
    if (cavePlaceId == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentationFilesPage(cavePlaceId: cavePlaceId),
      ),
    );
  }

  /// Show a toast message when a cave place point is long-tapped.
  void _showLongTapToast(String cavePlaceTitle) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocServ.inst.t('long_tap_detected', {'cavePlaceTitle': cavePlaceTitle})),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Embedded nav bar (raster maps + cave places) when enabled
        if (_showNavBar)
          RasterMapNavBar(
            key: _navBarKey,
            rasterMaps: widget.rasterMaps,
            cavePlacesWithDefinitions: widget.cavePlacesWithDefinitions,
            selectedRasterMapId: widget.selectedRasterMapId,
            selectedPlaceId: widget.controller?.cavePlaceId,
            style: widget.navBarStyle,
            onRasterMapSelected: (rm) => _handleNavRasterMapSelected(rm),
            onCavePlaceSelected: (cpwd) => _handleNavCavePlaceSelected(cpwd),
          ),

        Expanded(
          child: ClipRect(
            child: Stack(
              children: [
                PhotoView(
                  controller: _photoViewController,
                  scaleStateController: _scaleStateController,
                  imageProvider: widget.imageProvider ?? FileImage(widget.imageFile),
                  minScale: _gestureZoomEnabled
                      ? PhotoViewComputedScale.contained * 0.5
                      : PhotoViewComputedScale.contained,
                  maxScale: _gestureZoomEnabled
                      ? PhotoViewComputedScale.covered * 4.8
                      : PhotoViewComputedScale.contained,
                  initialScale: PhotoViewComputedScale.contained,
                  enableRotation: false,
                  basePosition: Alignment.topLeft,
                  onTapDown: (context, details, controllerValue) {
                    _onImageTap(details, controllerValue);
                  },
                  loadingBuilder: (context, event) =>
                      const Center(child: CircularProgressIndicator()),
                ),
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // store the current viewport size for use by zoomToPoint
                      _photoViewportSize = constraints.biggest;

                      final List<Widget> overlay = [];
                      final controllerValue = PhotoViewControllerValue(
                        scale: _photoViewController.scale,
                        position: _photoViewController.position,
                        rotation: _photoViewController.rotation,
                        rotationFocusPoint: _photoViewController.rotationFocusPoint,
                      );
                      final selectedCavePlaceTitle =
                          _resolveSelectedCavePlaceTitle();
                      String markerLabel(String qualifierKey) {
                        final suffix = LocServ.inst.t(qualifierKey);
                        if (selectedCavePlaceTitle.isEmpty) {
                          return '($suffix)';
                        }
                        return '$selectedCavePlaceTitle ($suffix)';
                      }

                      // Compute special point keys (to skip their red dots)
                      final specialPointKeys = RasterMapMarkerBuilder.computeSpecialPointKeys(
                        userHasSelectedNewPoint: _userHasSelectedNewPoint,
                        selectedX: _imageSelectedX,
                        selectedY: _imageSelectedY,
                        initialX: widget.initialImageX,
                        initialY: widget.initialImageY,
                        controllerX: _initialControllerCavePlaceX,
                        controllerY: _initialControllerCavePlaceY,
                      );

                      final outlineEnabled = widget.controller?.textOutlineEnabled ?? true;
                      final outlineWidth = widget.controller?.textOutlineWidth ?? 2.0;
                      final bgEnabled = widget.controller?.textBackgroundEnabled ?? false;

                      // Existing definitions (red dots + labels)
                      overlay.addAll(RasterMapMarkerBuilder.buildDefinitionMarkers(
                        definitions: widget.cavePlacesWithDefinitions,
                        controllerValue: controllerValue,
                        specialPointKeys: specialPointKeys,
                        useImageTextColor: _useImageTextColor,
                        img: _img,
                        defaultLabelColor: widget.defaultLabelColor,
                        outlineEnabled: outlineEnabled,
                        outlineWidth: outlineWidth,
                        bgEnabled: bgEnabled,
                        onTap: (cpwd) async {
                          final def = cpwd.definition!;
                          _startPulseAtImagePoint(
                            (def.xCoordinate ?? 0).toDouble(),
                            (def.yCoordinate ?? 0).toDouble(),
                          );
                          await _handleNavCavePlaceSelected(cpwd, notifyMarkerTap: true);
                        },
                        onLongPress: _showLongTapToast,
                      ));

                      // Selected / initial markers
                      if (_userHasSelectedNewPoint && _imageSelectedX != null && _imageSelectedY != null) {
                        overlay.addAll(RasterMapMarkerBuilder.buildNewPointMarkers(
                          newX: _imageSelectedX!,
                          newY: _imageSelectedY!,
                          oldX: widget.initialImageX,
                          oldY: widget.initialImageY,
                          controllerValue: controllerValue,
                          markerLabel: markerLabel,
                          useImageTextColor: _useImageTextColor,
                          img: _img,
                          defaultLabelColor: widget.defaultLabelColor,
                          outlineEnabled: outlineEnabled,
                          outlineWidth: outlineWidth,
                          bgEnabled: bgEnabled,
                        ));
                      } else if (_initialControllerCavePlaceX != null && _initialControllerCavePlaceY != null) {
                        overlay.addAll(RasterMapMarkerBuilder.buildControllerPlaceMarker(
                          imageX: _initialControllerCavePlaceX!,
                          imageY: _initialControllerCavePlaceY!,
                          controllerValue: controllerValue,
                          definitions: widget.cavePlacesWithDefinitions,
                          useImageTextColor: _useImageTextColor,
                          img: _img,
                          defaultLabelColor: widget.defaultLabelColor,
                          outlineEnabled: outlineEnabled,
                          outlineWidth: outlineWidth,
                          bgEnabled: bgEnabled,
                          onLongPress: _showLongTapToast,
                        ));
                      } else if (widget.initialImageX != null && widget.initialImageY != null && !_userHasSelectedNewPoint) {
                        overlay.addAll(RasterMapMarkerBuilder.buildLegacyOldPointMarker(
                          imageX: widget.initialImageX!,
                          imageY: widget.initialImageY!,
                          controllerValue: controllerValue,
                          markerLabel: markerLabel,
                          useImageTextColor: _useImageTextColor,
                          img: _img,
                          defaultLabelColor: widget.defaultLabelColor,
                          outlineEnabled: outlineEnabled,
                          outlineWidth: outlineWidth,
                          bgEnabled: bgEnabled,
                        ));
                      }

                      // Pulse animation overlay
                      final pulseWidget = RasterMapMarkerBuilder.buildPulseOverlay(
                        pulseImageX: _pulseImageX,
                        pulseImageY: _pulseImageY,
                        pulseValue: _pulseController.value,
                        controllerValue: controllerValue,
                        primaryColor: Theme.of(context).colorScheme.primary,
                      );
                      if (pulseWidget != null) overlay.add(pulseWidget);

                      // Trip route overlay (lines, arrows, numbers)
                      if (widget.tripOverlay != null) {
                        overlay.addAll(RasterMapMarkerBuilder.buildTripOverlay(
                          tripOverlay: widget.tripOverlay!,
                          definitions: widget.cavePlacesWithDefinitions,
                          controllerValue: controllerValue,
                        ));
                      }

                      return Stack(children: overlay);
                    },
                  ),
                ),
                // Legend overlay (bottom-left corner)
                if (_showLegend)
                  const Positioned(
                    left: 8,
                    bottom: 8,
                    child: RasterMapPointsLegend(),
                  ),
                // Zoom controls overlay (bottom-right corner)
                if (_showZoomControls)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.60),
                        border: Border.all(color: Colors.grey, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: zoomOut,
                            icon: const Icon(Icons.remove),
                          ),
                          IconButton(
                            onPressed: resetZoom,
                            icon: const Icon(Icons.refresh),
                          ),
                          IconButton(
                            onPressed: zoomIn,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 2),

        // Action bar (bottom-toolbar) with legend toggle, edit actions, and cave place quick-add
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
              // Legend toggle (always available)
              IconButton(
                onPressed: () => setState(() => _showLegend = !_showLegend),
                icon: Icon(Icons.info_outline, size: 20, color: _showLegend ? Colors.blue : null),
                tooltip: LocServ.inst.t('toggle_legend'),
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
              // Action buttons (edit mode only)
              if (!widget.isReadonly) ...[
              // Tap mode toggle
              if (_showTapModeCheckbox)
                IconButton(
                  onPressed: () {
                    if (mounted) setState(() => _tapDefinesNewPoint = !_tapDefinesNewPoint);
                  },
                  icon: Icon(
                    // tap_mode_define_point icon options to consider: move_up, edit_location, edit_location_alt, swipe_up, swipe_right_alt
                    _tapDefinesNewPoint ? Icons.edit_location_alt : Icons.touch_app,
                    size: 20,
                    color: _tapDefinesNewPoint ? Colors.blue : Colors.orange,
                  ),
                  tooltip: _tapDefinesNewPoint
                      ? LocServ.inst.t('tap_mode_define_point')
                      : LocServ.inst.t('tap_mode_select_place'),
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
              // Reset point
              IconButton(
                onPressed: _userHasSelectedNewPoint ? _resetPointToInitial : null,
                icon: const Icon(Icons.undo, size: 20),
                tooltip: LocServ.inst.t('reset_point'),
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
              // Remove definition
              if (widget.onRemoveDefinitionRequested != null)
                IconButton(
                  onPressed: _handleRemoveDefinition,
                  icon: Icon(Icons.delete_outline, size: 20, color: Colors.red[400]),
                  tooltip: LocServ.inst.t('remove_definition'),
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
              // Add new cave place (tap-to-define)
              if (widget.caveId != null && widget.onCavePlaceAdded != null)
                IconButton(
                  onPressed: _waitingForNewCavePlaceTap
                      ? () => setState(() => _waitingForNewCavePlaceTap = false)
                      : _handleAddCavePlace,
                  icon: Icon(
                    Icons.add_location_alt,
                    size: 20,
                    color: _waitingForNewCavePlaceTap ? Colors.green : null,
                  ),
                  tooltip: LocServ.inst.t('add_cave_place_quick'),
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: _waitingForNewCavePlaceTap ? Colors.green.withValues(alpha: 0.15) : null,
                  ),
                ),
              // Save / define place on map
              if (SHOW_SAVE_CAVE_PLACE_BUTTON && widget.onSaveDefinitionRequested != null)
                IconButton(
                  onPressed: widget.onSaveDefinitionRequested,
                  icon: Icon(Icons.save_alt, size: 24, color: Theme.of(context).colorScheme.primary),
                  tooltip: LocServ.inst.t('define_place_on_map'),
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
            ],
            // View-mode actions (always available)
            if (widget.controller?.cavePlaceId != null)
              IconButton(
                onPressed: _openCavePlacePage,
                icon: const Icon(Icons.open_in_new, size: 20),
                tooltip: LocServ.inst.t('open_cave_place'),
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            if (widget.controller?.cavePlaceId != null)
              IconButton(
                onPressed: _openCavePlaceDocuments,
                icon: const Icon(Icons.description, size: 20),
                tooltip: LocServ.inst.t('documentation'),
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
          ],
        ),

        const SizedBox(height: 4),

        if (widget.debugUi) ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _imageSelectedX?.toInt().toString() ?? '',
                  decoration: const InputDecoration(labelText: 'X Coordinate'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final x = double.tryParse(value);
                    if (x != null) setState(() => _imageSelectedX = x);
                    widget.onImagePointChanged?.call(
                      _imageSelectedX ?? 0,
                      _imageSelectedY ?? 0,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: _imageSelectedY?.toInt().toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Y Coordinate'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final y = double.tryParse(value);
                    if (y != null) setState(() => _imageSelectedY = y);
                    widget.onImagePointChanged?.call(
                      _imageSelectedX ?? 0,
                      _imageSelectedY ?? 0,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
