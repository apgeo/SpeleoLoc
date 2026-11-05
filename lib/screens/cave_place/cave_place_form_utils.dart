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

/// Parses a user-entered latitude, longitude or altitude. A decimal comma
/// counts as a decimal point: a Romanian decimal keypad types one, and a
/// pasted `45,359167` must not be mistaken for garbage.
///
/// Returns `null` for empty or unparseable input; callers tell the two
/// apart by the text itself, so a cleared field can still clear the column
/// while a typo blocks the save instead of erasing the stored value.
/// NaN and infinities are rejected because `double.tryParse` accepts them.
double? parseCoordinateValue(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  final value = double.tryParse(trimmed.replaceAll(',', '.'));
  return value != null && value.isFinite ? value : null;
}

/// Input formatter that constrains the depth field to an optionally-negative
/// number with up to 4 integer digits and 1 decimal digit.
final TextInputFormatter depthInputFormatter = TextInputFormatter.withFunction((
  oldValue,
  newValue,
) {
  final text = newValue.text;
  if (text.isEmpty || text == '-' || text == '.' || text == '-.') {
    return newValue;
  }
  final normalized = text.replaceAll(',', '.');
  final pattern = RegExp(r'^-?\d{0,4}(?:\.\d{0,1})?$');
  return pattern.hasMatch(normalized) ? newValue : oldValue;
});
