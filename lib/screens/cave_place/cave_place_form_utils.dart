/// Pure, stateless helpers extracted from [CavePlacePage] during Phase 2.1
/// of the refactoring plan.
///
/// Keep these free of `BuildContext`, `State`, or side effects so they can
/// be unit-tested in isolation.
library;

import 'package:flutter/services.dart';

/// Formats a nullable depth value: `null` → empty; trims trailing `.0`.
String formatDepthValue(double? value) {
  if (value == null) return '';
  return value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
}

/// Counts line-break–separated lines (min 1, max 5) for sizing a text field.
int computeDescriptionLines(String text) {
  if (text.isEmpty) return 1;
  final lines = '\n'.allMatches(text).length + 1;
  return lines.clamp(1, 5);
}

/// Parses a user-entered depth. Accepts comma or dot as decimal separator.
/// Returns `null` for empty / `-` / unparseable input.
double? parseDepthValue(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty || trimmed == '-') return null;
  return double.tryParse(trimmed.replaceAll(',', '.'));
}

/// Input formatter that constrains the depth field to an optionally-negative
/// number with up to 4 integer digits and 1 decimal digit.
final TextInputFormatter depthInputFormatter =
    TextInputFormatter.withFunction((oldValue, newValue) {
  final text = newValue.text;
  if (text.isEmpty || text == '-' || text == '.' || text == '-.') {
    return newValue;
  }
  final normalized = text.replaceAll(',', '.');
  final pattern = RegExp(r'^-?\d{0,4}(?:\.\d{0,1})?$');
  return pattern.hasMatch(normalized) ? newValue : oldValue;
});
