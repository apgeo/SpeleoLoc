import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/screens/cave_place/cave_place_form_utils.dart';

void main() {
  group('formatDepthValue', () {
    test('null returns empty string', () {
      expect(formatDepthValue(null), '');
    });

    test('trailing .0 is trimmed', () {
      expect(formatDepthValue(12.0), '12');
      expect(formatDepthValue(-3.0), '-3');
      expect(formatDepthValue(0.0), '0');
    });

    test('non-zero decimal is preserved', () {
      expect(formatDepthValue(12.5), '12.5');
      expect(formatDepthValue(-0.7), '-0.7');
    });
  });

  group('computeDescriptionLines', () {
    test('empty text → 1 line', () {
      expect(computeDescriptionLines(''), 1);
    });

    test('single-line text → 1 line', () {
      expect(computeDescriptionLines('one line'), 1);
    });

    test('two-line text → 2 lines', () {
      expect(computeDescriptionLines('a\nb'), 2);
    });

    test('clamps to a maximum of 5 lines', () {
      expect(computeDescriptionLines('1\n2\n3\n4\n5\n6\n7'), 5);
    });
  });

  group('parseDepthValue', () {
    test('empty string → null', () {
      expect(parseDepthValue(''), null);
      expect(parseDepthValue('   '), null);
    });

    test('lone minus sign → null', () {
      expect(parseDepthValue('-'), null);
    });

    test('decimal point and comma are both accepted', () {
      expect(parseDepthValue('12.5'), 12.5);
      expect(parseDepthValue('12,5'), 12.5);
    });

    test('negative value parses', () {
      expect(parseDepthValue('-3.7'), -3.7);
    });

    test('garbage → null', () {
      expect(parseDepthValue('abc'), null);
      expect(parseDepthValue('1.2.3'), null);
    });
  });

  group('depthInputFormatter', () {
    TextEditingValue v(String s) => TextEditingValue(text: s);
    TextEditingValue apply(String oldText, String newText) =>
        depthInputFormatter.formatEditUpdate(v(oldText), v(newText));

    test('accepts empty / lone minus / dot', () {
      expect(apply('', '').text, '');
      expect(apply('', '-').text, '-');
      expect(apply('', '.').text, '.');
      expect(apply('-', '-.').text, '-.');
    });

    test('accepts up to 4 integer digits + 1 decimal', () {
      expect(apply('', '1234').text, '1234');
      expect(apply('', '1234.5').text, '1234.5');
      expect(apply('', '-1234.5').text, '-1234.5');
    });

    test('rejects 5 integer digits', () {
      expect(apply('1234', '12345').text, '1234');
    });

    test('rejects 2-digit fraction', () {
      expect(apply('12.5', '12.56').text, '12.5');
    });

    test('comma is accepted (treated like dot)', () {
      expect(apply('', '12,5').text, '12,5');
    });

    test('rejects letters', () {
      expect(apply('12', '12a').text, '12');
    });
  });
}
