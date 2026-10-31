import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/cave_model/survey_model_format.dart';

void main() {
  Uint8List head(String path) =>
      Uint8List.fromList(File(path).readAsBytesSync().take(32).toList());

  group('SurveyModelFormat.sniff', () {
    test('reads the formats from Therion\'s own output', () {
      expect(
        SurveyModelFormat.sniff(head('test_data/cave_models/test_cave.lox')),
        SurveyModelFormat.lox,
      );
      expect(
        SurveyModelFormat.sniff(head('test_data/cave_models/test_cave.3d')),
        SurveyModelFormat.survex3d,
      );
    });

    test('says nothing of text, a photo or a short file', () {
      expect(
        SurveyModelFormat.sniff(
          Uint8List.fromList('a plain text file, long enough'.codeUnits),
        ),
        isNull,
      );
      final jpeg = Uint8List(32)..setAll(0, [0xff, 0xd8, 0xff, 0xe0]);
      expect(SurveyModelFormat.sniff(jpeg), isNull);
      expect(SurveyModelFormat.sniff(Uint8List.fromList([1, 0, 0, 0])), isNull);
    });
  });

  group('SurveyModelFormat.fromFileName', () {
    test('takes the last extension, in any case', () {
      expect(SurveyModelFormat.fromFileName('a.LOX'), SurveyModelFormat.lox);
      expect(
        SurveyModelFormat.fromFileName('doc_1_a.b.3d'),
        SurveyModelFormat.survex3d,
      );
      expect(SurveyModelFormat.fromFileName('a.lox.txt'), isNull);
      expect(SurveyModelFormat.fromFileName('lox'), isNull);
    });
  });
}
