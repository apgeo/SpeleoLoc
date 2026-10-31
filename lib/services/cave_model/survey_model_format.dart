import 'dart:typed_data';

/// The survey-model files the 3D viewer reads.
///
/// CaveView picks its reader from the file name's extension alone, so the
/// viewer is always handed a name ending in [extension], whatever the stored
/// file is called.
enum SurveyModelFormat {
  /// Therion's model export.
  lox('lox'),

  /// Survex's `.3d`, also written by Therion.
  survex3d('3d');

  const SurveyModelFormat(this.extension);

  /// The extension, lower-case and without the dot.
  final String extension;

  static SurveyModelFormat? fromFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0) return null;
    final ext = fileName.substring(dot + 1).toLowerCase();
    for (final format in values) {
      if (format.extension == ext) return format;
    }
    return null;
  }

  static const _survexMagic = 'Survex 3D Image File';

  /// The format the first bytes of a file say it is, or null.
  ///
  /// A `.3d` names itself on its first line. A `.lox` has no magic, but it
  /// opens with a chunk header whose first little-endian word is one of the
  /// six chunk types Therion defines. A file renamed on a server, or saved
  /// without its extension, is still recognised.
  static SurveyModelFormat? sniff(Uint8List head) {
    if (head.length >= _survexMagic.length &&
        String.fromCharCodes(head.sublist(0, _survexMagic.length)) ==
            _survexMagic) {
      return survex3d;
    }
    if (head.length >= 16) {
      final chunkType = ByteData.sublistView(
        head,
        0,
        4,
      ).getUint32(0, Endian.little);
      if (chunkType >= 1 && chunkType <= 6) return lox;
    }
    return null;
  }
}
