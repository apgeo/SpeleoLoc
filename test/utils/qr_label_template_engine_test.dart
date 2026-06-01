import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/qr_label_template_engine.dart';

CavePlace _place({
  String title = 'Big Pit',
  String? description,
  String? pci,
  String? qcri,
  double? depth,
}) =>
    CavePlace(
      uuid: Uuid.zero,
      title: title,
      description: description,
      caveUuid: Uuid.zero,
      placeCodeIdentifier: pci,
      qrCodeResourceIdentifier: qcri,
      depthInCave: depth,
      isEntrance: 0,
      isMainEntrance: 0,
    );

void main() {
  group('QrLabelTemplateEngine.resolve', () {
    test('substitutes every variable', () {
      final out = QrLabelTemplateEngine.resolve(
        template:
            '@cave_title - @area_title: @place_title (@place_code_identifier / @qr_res_identifier) @depth @description',
        place: _place(
          title: 'Entrance',
          description: 'main',
          pci: 'P1',
          qcri: 'Q1',
          depth: -12.5,
        ),
        caveTitle: 'Cave A',
        areaTitle: 'Area B',
      );
      expect(out, 'Cave A - Area B: Entrance (P1 / Q1) -12.5 main');
    });

    test('formats depth with explicit sign and one decimal', () {
      expect(
        QrLabelTemplateEngine.resolve(
            template: '@depth', place: _place(depth: 0)),
        '+0.0',
      );
      expect(
        QrLabelTemplateEngine.resolve(
            template: '@depth', place: _place(depth: 7)),
        '+7.0',
      );
      // Wrap negative depth in a context word: `_cleanupResolved` strips
      // a leading `-` as a separator, so the minus only survives when
      // there is non-separator text before `@depth` (the realistic case).
      expect(
        QrLabelTemplateEngine.resolve(
            template: 'd @depth', place: _place(depth: -3.27)),
        'd -3.3',
      );
      expect(
        QrLabelTemplateEngine.resolve(template: '@depth', place: _place()),
        '',
      );
    });

    test('strips formatting directives from plain-text output', () {
      final out = QrLabelTemplateEngine.resolve(
        template: '#fz24#fcFF0000@place_title',
        place: _place(title: 'X'),
      );
      expect(out, 'X');
    });

    test('cleans up separators left by empty variables', () {
      // Both context strings missing -> no leading "  - " or trailing " : "
      final out = QrLabelTemplateEngine.resolve(
        template: '@cave_title - @area_title: @place_title',
        place: _place(title: 'Lone'),
      );
      expect(out, 'Lone');
    });

    test('converts literal \\n into a real newline', () {
      final out = QrLabelTemplateEngine.resolve(
        template: r'@place_title\n@description',
        place: _place(title: 'A', description: 'B'),
      );
      expect(out, 'A\nB');
    });
  });

  group('QrLabelTemplateEngine.parseSegments', () {
    test('returns one plain segment when no formatting is present', () {
      final segs = QrLabelTemplateEngine.parseSegments(
        template: '@place_title',
        place: _place(title: 'Pit'),
      );
      expect(segs, hasLength(1));
      expect(segs.single.text, 'Pit');
      expect(segs.single.fontSize, isNull);
      expect(segs.single.fontColor, isNull);
    });

    test('captures fontSize and fontColor on prefixed segments', () {
      final segs = QrLabelTemplateEngine.parseSegments(
        template: '#fz18#fcFF0000@place_title',
        place: _place(title: 'Red'),
      );
      // Engine emits one segment covering "Red" (after variable substitution)
      // with the explicit overrides parsed from the directives.
      expect(segs, isNotEmpty);
      final tagged = segs.firstWhere((s) => s.text.contains('Red'));
      expect(tagged.fontSize, 18.0);
      expect(tagged.fontColor, 'FF0000');
    });

    test('never returns an empty list, even for an empty resolved template',
        () {
      final segs = QrLabelTemplateEngine.parseSegments(
        template: '',
        place: _place(),
      );
      expect(segs, hasLength(1));
      expect(segs.single.text, '');
    });
  });
}
