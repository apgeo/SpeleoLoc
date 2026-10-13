import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speleoloc/services/trip_media/media_capture_time.dart';

/// On the picked-files path a photo's EXIF is the only surviving record of
/// when it was taken — the picker hands over a cache copy whose filesystem
/// stamps are the copy's. These tests pin the parse, including the all-zero
/// form cameras with no clock set write, which must not become a date in
/// year zero.
void main() {
  group('parseExifDateTime', () {
    test('reads the standard colon-separated form as local time', () {
      expect(
        MediaCaptureTime.parseExifDateTime('2026:10:13 14:32:05'),
        DateTime(2026, 10, 13, 14, 32, 5),
      );
    });

    test('tolerates a T separator and trailing subsecond text', () {
      expect(
        MediaCaptureTime.parseExifDateTime('2026:10:13T14:32:05.123'),
        DateTime(2026, 10, 13, 14, 32, 5),
      );
    });

    test('rejects the all-zero date of an unset camera clock', () {
      expect(MediaCaptureTime.parseExifDateTime('0000:00:00 00:00:00'), isNull);
    });

    test('rejects a zero month or day', () {
      expect(MediaCaptureTime.parseExifDateTime('2026:00:13 10:00:00'), isNull);
      expect(MediaCaptureTime.parseExifDateTime('2026:10:00 10:00:00'), isNull);
    });

    test('rejects blank, null and non-date text', () {
      expect(MediaCaptureTime.parseExifDateTime(null), isNull);
      expect(MediaCaptureTime.parseExifDateTime('   '), isNull);
      expect(MediaCaptureTime.parseExifDateTime('yesterday'), isNull);
    });
  });

  group('fromImageBytes', () {
    /// A 2x2 JPEG carrying whatever EXIF the caller sets — invented data, so
    /// the round-trip is the real decoder on a real file.
    List<int> jpegWith(void Function(img.Image) setExif) {
      final image = img.Image(width: 2, height: 2);
      setExif(image);
      return img.encodeJpg(image);
    }

    test('prefers DateTimeOriginal', () {
      final bytes = jpegWith((image) {
        image.exif.exifIfd['DateTimeOriginal'] = '2026:10:13 09:15:00';
        image.exif.imageIfd['DateTime'] = '2026:10:14 20:00:00';
      });
      expect(
        MediaCaptureTime.fromImageBytes(Uint8List.fromList(bytes)),
        DateTime(2026, 10, 13, 9, 15),
      );
    });

    test('falls back to the file-level DateTime', () {
      final bytes = jpegWith((image) {
        image.exif.imageIfd['DateTime'] = '2026:10:14 20:00:00';
      });
      expect(
        MediaCaptureTime.fromImageBytes(Uint8List.fromList(bytes)),
        DateTime(2026, 10, 14, 20, 0),
      );
    });

    test('returns null for an image with no EXIF date', () {
      final bytes = jpegWith((_) {});
      expect(
        MediaCaptureTime.fromImageBytes(Uint8List.fromList(bytes)),
        isNull,
      );
    });

    test('returns null rather than throwing on non-image bytes', () {
      expect(
        MediaCaptureTime.fromImageBytes(
          Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
        ),
        isNull,
      );
    });
  });
}
