import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// The beginning of a text file, read for display.
class TextFilePreview {
  const TextFilePreview({
    required this.text,
    required this.shownBytes,
    required this.totalBytes,
  });

  final String text;
  final int shownBytes;
  final int totalBytes;

  bool get truncated => shownBytes < totalBytes;

  /// Laying out a whole multi-megabyte CSV as one text would freeze the
  /// screen on its own, so a preview stops here.
  static const int defaultMaxBytes = 256 * 1024;

  /// Reads at most [maxBytes] of the file at [path].
  ///
  /// Not every text file is UTF-8: exports from older tools use a legacy
  /// code page, and a cut at [maxBytes] can split a character. Bytes that do
  /// not decode show as replacement characters instead of failing the view.
  static Future<TextFilePreview> load(
    String path, {
    int maxBytes = defaultMaxBytes,
  }) async {
    final file = await File(path).open();
    try {
      final total = await file.length();
      final bytes = await file.read(math.min(total, maxBytes));
      return TextFilePreview(
        text: utf8.decode(bytes, allowMalformed: true),
        shownBytes: bytes.length,
        totalBytes: total,
      );
    } finally {
      await file.close();
    }
  }
}
