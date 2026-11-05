import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:speleoloc/widgets/raster_map/raster_map_picture_size.dart';

/// The map picture under the editor's markers, panned and zoomed through
/// [controller].
///
/// PhotoView's frame is the picture's own pixel size, read from its header,
/// while the pixels shown are decoded no larger than
/// [rasterMapDisplayMaxSide] and stretched over that frame. Viewport
/// positions, the controller's scale and the points stored on the map are
/// then in the same pixels on every device, whatever size the picture was
/// decoded to.
class RasterMapPictureView extends StatefulWidget {
  const RasterMapPictureView({
    required this.picture,
    required this.controller,
    required this.scaleStateController,
    required this.gestureZoomEnabled,
    this.colorFilter,
    this.onPictureSize,
    super.key,
  });

  final ImageProvider picture;
  final PhotoViewController controller;
  final PhotoViewScaleStateController scaleStateController;
  final bool gestureZoomEnabled;
  final ColorFilter? colorFilter;

  /// Told the picture's own size once it is read, or null when it cannot be.
  final ValueChanged<Size?>? onPictureSize;

  @override
  State<RasterMapPictureView> createState() => _RasterMapPictureViewState();
}

class _RasterMapPictureViewState extends State<RasterMapPictureView> {
  Size? _size;
  bool _decoded = false;
  bool _failed = false;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(RasterMapPictureView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.picture != widget.picture) _load();
  }

  @override
  void dispose() {
    _unwatch();
    super.dispose();
  }

  void _load() {
    final picture = widget.picture;
    _size = null;
    _decoded = false;
    _failed = false;
    rasterMapPictureSize(picture).then((size) {
      if (!mounted || widget.picture != picture) return;
      final frame = size == null
          ? null
          : Size(size.width.toDouble(), size.height.toDouble());
      widget.onPictureSize?.call(frame);
      setState(() {
        _size = frame;
        _failed = _failed || frame == null;
      });
    }).ignore();
    _watch(picture);
  }

  /// Follows the display decode for the spinner. The listener stays until
  /// the picture changes: removing it once decoded could let the stream
  /// drop a picture too large for the image cache before the Image widget
  /// subscribes, and decode it a second time.
  void _watch(ImageProvider picture) {
    _unwatch();
    final stream = rasterMapDisplayPicture(
      picture,
    ).resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (info, _) {
        info.dispose();
        if (mounted && !_decoded) setState(() => _decoded = true);
      },
      onError: (_, _) {
        if (mounted) setState(() => _failed = true);
      },
    );
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  void _unwatch() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  @override
  Widget build(BuildContext context) {
    final size = _size;
    if (_failed) {
      return const Center(
        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
      );
    }
    if (size == null) {
      return const Center(child: CircularProgressIndicator());
    }
    Widget view = PhotoView.customChild(
      controller: widget.controller,
      scaleStateController: widget.scaleStateController,
      childSize: size,
      minScale: widget.gestureZoomEnabled
          ? PhotoViewComputedScale.contained * 0.5
          : PhotoViewComputedScale.contained,
      maxScale: widget.gestureZoomEnabled
          ? PhotoViewComputedScale.covered * 4.8
          : PhotoViewComputedScale.contained,
      initialScale: PhotoViewComputedScale.contained,
      enableRotation: false,
      basePosition: Alignment.topLeft,
      disableGestures: true,
      child: Image(
        image: rasterMapDisplayPicture(widget.picture),
        fit: BoxFit.fill,
        gaplessPlayback: true,
        // As PhotoView draws a picture it decodes itself.
        filterQuality: FilterQuality.none,
      ),
    );
    final filter = widget.colorFilter;
    if (filter != null) view = ColorFiltered(colorFilter: filter, child: view);
    return Stack(
      fit: StackFit.expand,
      children: [
        view,
        if (!_decoded) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
