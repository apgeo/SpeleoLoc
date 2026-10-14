import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Things worth knowing about a screen that are not failures.
///
/// A layout exception is a failure and is reported as one. These are the
/// softer findings a person would only notice by looking: text that was
/// cut off to make it fit. Each is a map so it serialises straight into
/// the run's result.
class Probes {
  const Probes._();

  /// Text the framework had to cut short, by an ellipsis or a line limit.
  ///
  /// A title that truncates on the narrowest phone in one language is not
  /// a bug in itself, but it is exactly the kind of thing that is invisible
  /// on the developer's own device and obvious on someone else's.
  static List<Map<String, Object?>> truncatedText(WidgetTester tester) {
    final findings = <Map<String, Object?>>[];
    final seen = <String>{};
    for (final element in find.byType(RichText).evaluate()) {
      final render = element.renderObject;
      if (render is! RenderParagraph || !render.attached || !render.hasSize) {
        continue;
      }
      if (!render.didExceedMaxLines) continue;
      final text = render.text.toPlainText().replaceAll('\n', ' ').trim();
      if (text.isEmpty || !seen.add(text)) continue;
      findings.add({
        'kind': 'truncated_text',
        'text': text.length > 80 ? '${text.substring(0, 80)}…' : text,
        'width': render.size.width.round(),
      });
    }
    return findings;
  }

  /// Flutter's own accessibility guidelines, run against the screen as it
  /// stands: controls smaller than Android's 48 dp minimum, tappable
  /// things with no label for a screen reader, and text without enough
  /// contrast against what is behind it.
  ///
  /// Each guideline reports every offending node at once. Failures are
  /// findings, not test failures: the app has never been held to these, and
  /// a check introduced as a hard gate on day one gets switched off by
  /// day two. The report counts them so the number can only go down.
  ///
  /// [contrast] is off on devices: it reads the rendered pixels back,
  /// which software rendering makes slow, and colours do not depend on the
  /// platform, so the desktop build's answer stands for both.
  static Future<List<Map<String, Object?>>> accessibility(
    WidgetTester tester, {
    bool contrast = true,
  }) async {
    final findings = <Map<String, Object?>>[];
    for (final (name, guideline) in [
      ('tap_target', androidTapTargetGuideline),
      ('unlabeled_tap_target', labeledTapTargetGuideline),
      if (contrast) ('text_contrast', textContrastGuideline),
    ]) {
      try {
        final result = await guideline.evaluate(tester);
        if (result.passed) continue;
        final issues = result.reason!
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .toList();
        findings.add({
          'kind': name,
          'count': issues.length,
          'examples': [
            for (final line in issues.take(3))
              line.length > 160 ? '${line.substring(0, 160)}…' : line,
          ],
        });
      } catch (e) {
        final text = '$e';
        findings.add({
          'kind': name,
          'probe_error': text.length > 160 ? text.substring(0, 160) : text,
        });
      }
    }
    return findings;
  }
}
