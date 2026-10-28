import 'dart:async';

import 'package:flutter/widgets.dart';

/// The pixel size [picture] decodes to, or null when it cannot be decoded.
///
/// Read the way the map editor reads it, so it is the frame the editor draws
/// pins in, after any orientation the decoder applies.
Future<({int width, int height})?> rasterMapPictureSize(ImageProvider picture) {
  final size = Completer<({int width, int height})?>();
  final stream = picture.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      if (!size.isCompleted) {
        size.complete((width: info.image.width, height: info.image.height));
      }
      info.dispose();
      stream.removeListener(listener);
    },
    onError: (_, _) {
      if (!size.isCompleted) size.complete(null);
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return size.future;
}
