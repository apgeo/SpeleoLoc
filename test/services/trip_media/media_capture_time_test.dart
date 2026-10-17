import 'dart:io';
import 'dart:math';
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

    test(
      'reads the date from the head of a picture far larger than it',
      () async {
        // Noise does not compress, so this lands well past the header read —
        // the decoder must find the date without the rest of the file.
        final rnd = Random(7);
        final image = img.Image(width: 1600, height: 1200);
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x++) {
            image.setPixelRgb(
              x,
              y,
              rnd.nextInt(256),
              rnd.nextInt(256),
              rnd.nextInt(256),
            );
          }
        }
        image.exif.exifIfd['DateTimeOriginal'] = '2026:10:13 09:15:00';
        final dir = await Directory.systemTemp.createTemp('capture_time_');
        addTearDown(() => dir.delete(recursive: true));
        final file = File('${dir.path}/big.jpg')
          ..writeAsBytesSync(img.encodeJpg(image, quality: 95));
        expect(
          file.lengthSync(),
          greaterThan(MediaCaptureTime.headerBytes * 2),
          reason: 'the fixture must be bigger than what is read of it',
        );
        expect(
          await MediaCaptureTime.fromImageFile(file),
          DateTime(2026, 10, 13, 9, 15),
        );
      },
    );

    test('reads a picture smaller than the header whole', () async {
      final dir = await Directory.systemTemp.createTemp('capture_time_');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/small.jpg')
        ..writeAsBytesSync(
          jpegWith((image) {
            image.exif.exifIfd['DateTimeOriginal'] = '2026:10:13 09:15:00';
          }),
        );
      expect(
        await MediaCaptureTime.fromImageFile(file),
        DateTime(2026, 10, 13, 9, 15),
      );
    });

    test('a missing file is no date, not an exception', () async {
      expect(
        await MediaCaptureTime.fromImageFile(File('/nonexistent/x.jpg')),
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
