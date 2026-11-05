import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:photo_view/photo_view.dart';

/// The part of the map editor that follows the picture as it pans and zooms:
/// markers, labels, the pulse and the trip route.
///
/// Pan and zoom change [viewport] once per frame. Only this layer listens to
/// it, so a gesture rebuilds the markers and nothing else of the editor (the
/// nav bar, toolbars, action bar). The layer paints behind its own repaint
/// boundary for the same reason.
class RasterMapViewportLayer extends StatelessWidget {
  const RasterMapViewportLayer({
    required this.viewport,
    required this.builder,
    this.animation,
    this.onSize,
    super.key,
  });

  /// Where the picture currently sits in the viewport.
  final ValueListenable<PhotoViewControllerValue> viewport;

  /// Another per-frame source the layer redraws on, such as a tap pulse.
  final Listenable? animation;

  /// Told the layer's size on every layout, before [builder] runs.
  final ValueChanged<Size>? onSize;

  /// Builds the layer's children for the picture at [value], in a viewport
  /// of [size].
  final List<Widget> Function(
    BuildContext context,
    PhotoViewControllerValue value,
    Size size,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    final redrawOn = animation == null
        ? viewport
        : Listenable.merge(<Listenable>[viewport, animation!]);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        onSize?.call(size);
        return RepaintBoundary(
          child: ListenableBuilder(
            listenable: redrawOn,
            builder: (context, _) =>
                Stack(children: builder(context, viewport.value, size)),
          ),
        );
      },
    );
  }
}
