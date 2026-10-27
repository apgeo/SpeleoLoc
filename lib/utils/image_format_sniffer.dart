import 'dart:typed_data';

/// Names an image file by what its bytes are, not by what the picker called
/// it: a gallery can hand over a PNG or WebP under any extension, and a file
/// whose name promises the wrong format is mislabelled everywhere it travels.
class ImageFormatSniffer {
  ImageFormatSniffer._();

  /// The extension (without dot) for the format [bytes] start with, or
  /// `null` when it is none of JPEG, PNG or WebP.
  static String? extensionFor(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'jpg';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    // RIFF <4-byte size> WEBP
    if (bytes.length >= 12 &&
        _ascii(bytes, 0, 'RIFF') &&
        _ascii(bytes, 8, 'WEBP')) {
      return 'webp';
    }
    return null;
  }

  /// The extension for a file with [bytes] picked as [pickedName]: the
  /// sniffed one, else the picked name's own extension lowercased, else `jpg`
  /// (the only format the picker produced before this existed).
  static String extensionForPicked(Uint8List bytes, String pickedName) {
    final sniffed = extensionFor(bytes);
    if (sniffed != null) return sniffed;
    final dot = pickedName.lastIndexOf('.');
    if (dot >= 0 && dot < pickedName.length - 1) {
      final ext = pickedName.substring(dot + 1).toLowerCase();
      return ext == 'jpeg' ? 'jpg' : ext;
    }
    return 'jpg';
  }

  static bool _ascii(Uint8List bytes, int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      if (bytes[offset + i] != text.codeUnitAt(i)) return false;
    }
    return true;
  }
}
