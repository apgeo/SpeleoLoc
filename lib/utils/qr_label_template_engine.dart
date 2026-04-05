import 'package:speleoloc/data/source/database/app_database.dart';

/// Segment of a rendered label: text content with optional font size/color overrides.
class LabelSegment {
  final String text;
  final double? fontSize;
  final String? fontColor; // hex string e.g. "FF0000"

  const LabelSegment({required this.text, this.fontSize, this.fontColor});
}

/// Parses a label template string and resolves variables against a [CavePlace]
/// and optional cave/area context.
///
/// Template variables:
///   @place_title, @description, @cave_title, @area_title,
///   @place_qr_code_identifier, @depth
///
/// Formatting prefixes (applied per variable or free text):
///   #fz<number>  — font size
///   #fc<color>   — font color (hex, e.g. FF0000)
///
/// Line breaks: \n or literal backslash-n in template
class QrLabelTemplateEngine {
  /// Resolve the template to a single plain-text string (for simple rendering).
  static String resolve({
    required String template,
    required CavePlace place,
    String? caveTitle,
    String? areaTitle,
  }) {
    String result = template;

    result = result.replaceAll('@place_title', place.title);
    result = result.replaceAll('@description', place.description ?? '');
    result = result.replaceAll('@cave_title', caveTitle ?? '');
    result = result.replaceAll('@area_title', areaTitle ?? '');
    result = result.replaceAll('@place_qr_code_identifier',
        place.placeQrCodeIdentifier?.toString() ?? '');
    result = result.replaceAll('@depth', _formatDepth(place.depthInCave));

    // Handle \n as newline
    result = result.replaceAll('\\n', '\n');

    // Strip formatting directives for plain text output
    result = result.replaceAll(RegExp(r'#fz\d+'), '');
    result = result.replaceAll(RegExp(r'#fc[0-9a-fA-F]+'), '');

    return result.trim();
  }

  /// Parse template into segments with formatting info (for PDF rendering).
  static List<LabelSegment> parseSegments({
    required String template,
    required CavePlace place,
    String? caveTitle,
    String? areaTitle,
  }) {
    // First resolve all variables
    String resolved = template;
    resolved = resolved.replaceAll('@place_title', place.title);
    resolved = resolved.replaceAll('@description', place.description ?? '');
    resolved = resolved.replaceAll('@cave_title', caveTitle ?? '');
    resolved = resolved.replaceAll('@area_title', areaTitle ?? '');
    resolved = resolved.replaceAll('@place_qr_code_identifier',
        place.placeQrCodeIdentifier?.toString() ?? '');
    resolved = resolved.replaceAll('@depth', _formatDepth(place.depthInCave));

    // Handle \n as newline
    resolved = resolved.replaceAll('\\n', '\n');

    // Parse segments with #fz and #fc prefixes
    final segments = <LabelSegment>[];
    final pattern = RegExp(r'(#fz(\d+))?(#fc([0-9a-fA-F]+))?([^#]+|$)');

    for (final match in pattern.allMatches(resolved)) {
      final fontSizeStr = match.group(2);
      final fontColorStr = match.group(4);
      final text = match.group(5) ?? '';

      if (text.isEmpty) continue;

      segments.add(LabelSegment(
        text: text,
        fontSize: fontSizeStr != null ? double.tryParse(fontSizeStr) : null,
        fontColor: fontColorStr,
      ));
    }

    if (segments.isEmpty) {
      segments.add(LabelSegment(text: resolved));
    }

    return segments;
  }

  /// Formats depth_in_cave always with sign (+ or -)
  static String _formatDepth(double? depth) {
    if (depth == null) return '';
    final sign = depth >= 0 ? '+' : '';
    // Remove trailing zeros from decimal
    final formatted = depth.toStringAsFixed(1);
    return '$sign$formatted';
  }
}
