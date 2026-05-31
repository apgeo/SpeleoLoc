import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/utils/documentation_file_helper.dart';

void main() {
  group('DocumentationFileHelper.detectFileType', () {
    test('recognises photo extensions case-insensitively', () {
      for (final n in ['a.png', 'a.JPG', 'a.jpeg', 'a.gif', 'a.BMP', 'a.webp', 'a.heic']) {
        expect(DocumentationFileHelper.detectFileType(n), 'photo', reason: n);
      }
    });

    test('recognises video extensions', () {
      for (final n in ['v.mp4', 'v.MOV', 'v.avi', 'v.mkv', 'v.webm']) {
        expect(DocumentationFileHelper.detectFileType(n), 'video', reason: n);
      }
    });

    test('recognises audio extensions', () {
      for (final n in ['a.mp3', 'a.wav', 'a.OGG', 'a.m4a', 'a.flac']) {
        expect(DocumentationFileHelper.detectFileType(n), 'audio', reason: n);
      }
    });

    test('recognises text-document extensions', () {
      for (final n in ['d.txt', 'd.rtf', 'd.doc', 'd.DOCX', 'd.odt', 'd.pdf', 'd.md']) {
        expect(
          DocumentationFileHelper.detectFileType(n),
          'text_document',
          reason: n,
        );
      }
    });

    test('returns unknown for files without a usable extension', () {
      expect(DocumentationFileHelper.detectFileType('README'), 'unknown');
      expect(DocumentationFileHelper.detectFileType(''), 'unknown');
      expect(DocumentationFileHelper.detectFileType('archive.tar.gz'), 'unknown');
    });

    test('uses only the final extension component', () {
      // The helper splits on the LAST dot, so a "photo.txt" is text, not photo.
      expect(
        DocumentationFileHelper.detectFileType('photo.txt'),
        'text_document',
      );
    });
  });

  group('DocumentationFileHelper.computeSha256', () {
    test('produces the canonical SHA-256 hex of the empty input', () {
      // Well-known constant. If this fails the digest algo has changed
      // and every existing dedup record on disk just became invalid.
      expect(
        DocumentationFileHelper.computeSha256(Uint8List(0)),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('produces the canonical SHA-256 hex of "abc"', () {
      expect(
        DocumentationFileHelper.computeSha256(
          Uint8List.fromList('abc'.codeUnits),
        ),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('is deterministic for the same input', () {
      final a = DocumentationFileHelper.computeSha256(
        Uint8List.fromList([1, 2, 3, 4, 5]),
      );
      final b = DocumentationFileHelper.computeSha256(
        Uint8List.fromList([1, 2, 3, 4, 5]),
      );
      expect(a, b);
      expect(a, hasLength(64));
    });
  });
}
