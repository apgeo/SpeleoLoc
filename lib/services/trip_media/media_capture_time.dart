import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:speleoloc/utils/app_logger.dart';

/// Reads a capture time out of a still image's own metadata.
///
/// Only needed on the picked-files path: `image_picker` hands over a copy in
/// a cache directory, whose filesystem timestamps are the copy's, so the
/// picture's own EXIF is the only remaining record of when it was taken.
class MediaCaptureTime {
  const MediaCaptureTime._();

  static final _log = AppLogger.of('MediaCaptureTime');

  /// EXIF writes a local date-time as `YYYY:MM:DD HH:MM:SS`, with no zone.
  /// It is parsed as local time, which is what the camera recorded.
  static final _exifDateTimeRe = RegExp(
    r'^(\d{4}):(\d{2}):(\d{2})[ T](\d{2}):(\d{2}):(\d{2})',
  );

  /// Parses an EXIF date-time string, returning null for the blank and
  /// all-zero forms cameras write when they have no clock set.
  static DateTime? parseExifDateTime(String? raw) {
    if (raw == null) return null;
    final match = _exifDateTimeRe.firstMatch(raw.trim());
    if (match == null) return null;
    final parts = [for (var i = 1; i <= 6; i++) int.parse(match.group(i)!)];
    if (parts[0] == 0 || parts[1] == 0 || parts[2] == 0) return null;
    try {
      return DateTime(
        parts[0],
        parts[1],
        parts[2],
        parts[3],
        parts[4],
        parts[5],
      );
    } catch (e, st) {
      _log.fine('EXIF date out of range: "$raw"', e, st);
      return null;
    }
  }

  /// Pulls the capture time out of [bytes], preferring the camera's
  /// `DateTimeOriginal` over the file-level `DateTime`, and returning null
  /// when the image carries neither (or is not a JPEG).
  static DateTime? fromImageBytes(Uint8List bytes) {
    try {
      final exif = img.decodeJpgExif(bytes);
      if (exif == null) return null;
      final candidates = <String?>[
        exif.exifIfd['DateTimeOriginal']?.toString(),
        exif.exifIfd['DateTimeDigitized']?.toString(),
        exif.imageIfd['DateTime']?.toString(),
      ];
      for (final c in candidates) {
        final parsed = parseExifDateTime(c);
        if (parsed != null) return parsed;
      }
      return null;
    } catch (e, st) {
      // A truncated or non-JPEG file is an ordinary outcome here, not a bug.
      _log.fine('EXIF read failed', e, st);
      return null;
    }
  }
}
