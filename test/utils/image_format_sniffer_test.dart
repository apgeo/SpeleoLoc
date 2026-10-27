import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/utils/image_format_sniffer.dart';

void main() {
  Uint8List bytes(List<int> head) =>
      Uint8List.fromList([...head, ...List.filled(16, 0)]);

  final webp = bytes([...'RIFF'.codeUnits, 1, 2, 3, 4, ...'WEBP'.codeUnits]);

  group('extensionFor', () {
    test('recognises JPEG, PNG and WebP by their magic bytes', () {
      expect(ImageFormatSniffer.extensionFor(bytes([0xFF, 0xD8, 0xFF])), 'jpg');
      expect(
        ImageFormatSniffer.extensionFor(bytes([0x89, 0x50, 0x4E, 0x47])),
        'png',
      );
      expect(ImageFormatSniffer.extensionFor(webp), 'webp');
    });

    test('a RIFF file that is not WebP is not recognised', () {
      final wav = bytes([...'RIFF'.codeUnits, 1, 2, 3, 4, ...'WAVE'.codeUnits]);
      expect(ImageFormatSniffer.extensionFor(wav), isNull);
    });

    test('short or unknown input is not recognised', () {
      expect(ImageFormatSniffer.extensionFor(Uint8List(0)), isNull);
      expect(
        ImageFormatSniffer.extensionFor(Uint8List.fromList([0xFF])),
        isNull,
      );
      expect(ImageFormatSniffer.extensionFor(bytes([1, 2, 3, 4])), isNull);
    });
  });

  group('extensionForPicked', () {
    test('content wins over the picked name', () {
      expect(
        ImageFormatSniffer.extensionForPicked(
          bytes([0x89, 0x50, 0x4E, 0x47]),
          'IMG_1.jpg',
        ),
        'png',
      );
    });

    test('falls back to the picked extension, lowercased', () {
      expect(
        ImageFormatSniffer.extensionForPicked(bytes([1, 2, 3, 4]), 'a.TIFF'),
        'tiff',
      );
      expect(
        ImageFormatSniffer.extensionForPicked(bytes([1, 2, 3, 4]), 'a.jpeg'),
        'jpg',
      );
    });

    test('falls back to jpg when there is no extension either', () {
      expect(
        ImageFormatSniffer.extensionForPicked(bytes([1, 2, 3, 4]), 'noext'),
        'jpg',
      );
    });
  });
}
