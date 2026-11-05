import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Longest side, in pixels, that a map picture is decoded to for display.
///
/// A GPU cannot hold a texture beyond its maximum size, and the engine
/// shrinks a larger picture to whatever the device's GPU holds, so the same
/// scan would decode to different sizes on different phones. Phone and tablet
/// GPUs of the last decade commonly hold 8192 or 16384 px; capping at 8192
/// makes the reduction the same on all of them, leaves every picture up to
/// that size decoded whole as before, and bounds the memory a scan takes:
/// 8192 × 8192 RGBA is 256 MB, where an A0 sheet at 400 dpi (about
/// 13000 × 18700 px) decoded whole is about 970 MB. Points are kept in the
/// picture's own pixels (see [rasterMapPictureSize]), so the cap costs only
/// sharpness at deep zoom on such sheets.
const int rasterMapDisplayMaxSide = 8192;

/// [picture] as the map editor decodes it for display: whole up to
/// [rasterMapDisplayMaxSide] px on its longest side, reduced to fit beyond.
///
/// A picture that already asks for its own reduction is decoded as it asks;
/// the engine cannot apply two reductions to one decode.
ImageProvider rasterMapDisplayPicture(ImageProvider picture) =>
    picture is ResizeImage
    ? picture
    : ResizeImage(
        picture,
        width: rasterMapDisplayMaxSide,
        height: rasterMapDisplayMaxSide,
        policy: ResizeImagePolicy.fit,
      );

/// The picture's own pixel size, the frame points on it are stored in, or
/// null when it cannot be read.
///
/// Read from the encoded header rather than from a decode, so neither the
/// display cap, a reduction [picture] itself asks for, nor a GPU's limit
/// changes it. The engine reports the header size in the orientation it
/// shows the picture in.
Future<({int width, int height})?> rasterMapPictureSize(
  ImageProvider picture,
) async {
  final source = picture is ResizeImage ? picture.imageProvider : picture;
  final ui.ImmutableBuffer? buffer;
  try {
    buffer = switch (source) {
      FileImage(:final file) => await ui.ImmutableBuffer.fromFilePath(
        file.path,
      ),
      MemoryImage(:final bytes) => await ui.ImmutableBuffer.fromUint8List(
        bytes,
      ),
      _ => null,
    };
  } catch (_) {
    return null;
  }
  if (buffer == null) return _decodedSize(source);
  try {
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final size = (width: descriptor.width, height: descriptor.height);
    descriptor.dispose();
    return size;
  } catch (_) {
    return null;
  } finally {
    buffer.dispose();
  }
}

/// Fallback for providers whose bytes cannot be reached: the size they
/// decode to.
Future<({int width, int height})?> _decodedSize(ImageProvider picture) {
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
