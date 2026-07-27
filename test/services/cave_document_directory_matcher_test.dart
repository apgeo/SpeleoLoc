import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/cave_document_directory_matcher.dart';
import 'package:speleoloc/utils/uuid.dart';

void main() {
  final caveA = Uuid.v7();
  final caveB = Uuid.v7();
  final caveC = Uuid.v7();

  final candidates = [
    CaveMatchCandidate(
      caveUuid: caveA,
      title: 'Peștera Fisurii',
      areaCode: '2046',
      caveCode: '18',
    ),
    CaveMatchCandidate(
      caveUuid: caveB,
      title: 'Avenul Mare',
      areaCode: '2046',
      caveCode: '7',
    ),
    // No codes — only matchable by title.
    CaveMatchCandidate(caveUuid: caveC, title: 'Grota fără cod'),
  ];

  group('parseLeadingCode', () {
    test('splits the first token on the first hyphen', () {
      final code = CaveDocumentDirectoryMatcher.parseLeadingCode(
        '2046-18 P. Fisurii',
      );
      expect(code, isNotNull);
      expect(code!.areaCode, '2046');
      expect(code.caveCode, '18');
    });

    test('works without a trailing name', () {
      final code = CaveDocumentDirectoryMatcher.parseLeadingCode('2046-7');
      expect(code!.areaCode, '2046');
      expect(code.caveCode, '7');
    });

    test('returns null when there is no hyphen in the first token', () {
      expect(
        CaveDocumentDirectoryMatcher.parseLeadingCode('Fisurii'),
        isNull,
      );
      expect(
        CaveDocumentDirectoryMatcher.parseLeadingCode('2046 18'),
        isNull,
      );
    });

    test('returns null for empty or dash-only input', () {
      expect(CaveDocumentDirectoryMatcher.parseLeadingCode(''), isNull);
      expect(CaveDocumentDirectoryMatcher.parseLeadingCode('  '), isNull);
      expect(CaveDocumentDirectoryMatcher.parseLeadingCode('-18'), isNull);
      expect(CaveDocumentDirectoryMatcher.parseLeadingCode('2046-'), isNull);
    });
  });

  group('match', () {
    test('matches by exact title (case-insensitive, trimmed)', () {
      final m = CaveDocumentDirectoryMatcher.match(
        '  peștera fisurii  ',
        candidates,
      );
      expect(m.caveUuid, caveA);
      expect(m.method, CaveDirMatchMethod.title);
    });

    test('matches by leading area/cave code', () {
      final m = CaveDocumentDirectoryMatcher.match(
        '2046-18 P. Fisurii',
        candidates,
      );
      expect(m.caveUuid, caveA);
      expect(m.method, CaveDirMatchMethod.code);
    });

    test('title match wins over code match', () {
      final withCodeTitle = [
        CaveMatchCandidate(
          caveUuid: caveA,
          title: '2046-18 P. Fisurii',
          areaCode: '9999',
          caveCode: '1',
        ),
        CaveMatchCandidate(
          caveUuid: caveB,
          title: 'Other',
          areaCode: '2046',
          caveCode: '18',
        ),
      ];
      final m = CaveDocumentDirectoryMatcher.match(
        '2046-18 P. Fisurii',
        withCodeTitle,
      );
      expect(m.caveUuid, caveA, reason: 'title equality is tried first');
      expect(m.method, CaveDirMatchMethod.title);
    });

    test('is unmatched when neither title nor code resolves a cave', () {
      final m = CaveDocumentDirectoryMatcher.match(
        '9999-99 Unknown',
        candidates,
      );
      expect(m.caveUuid, isNull);
      expect(m.method, CaveDirMatchMethod.unmatched);
    });

    test('does not code-match candidates missing area or cave code', () {
      final m = CaveDocumentDirectoryMatcher.match('9999-1 whatever', [
        CaveMatchCandidate(
          caveUuid: caveC,
          title: 'Grota fără cod',
          caveCode: '1',
        ),
      ]);
      expect(m.method, CaveDirMatchMethod.unmatched);
    });

    test('code comparison is case-insensitive and trimmed', () {
      final m = CaveDocumentDirectoryMatcher.match('2046-18', [
        CaveMatchCandidate(
          caveUuid: caveA,
          title: 'X',
          areaCode: ' 2046 ',
          caveCode: ' 18 ',
        ),
      ]);
      expect(m.caveUuid, caveA);
      expect(m.method, CaveDirMatchMethod.code);
    });

    test('ambiguous title is left unmatched, not attached arbitrarily', () {
      final m = CaveDocumentDirectoryMatcher.match('Pestera Ungurului', [
        CaveMatchCandidate(caveUuid: caveA, title: 'Pestera Ungurului'),
        CaveMatchCandidate(caveUuid: caveB, title: 'pestera ungurului'),
      ]);
      expect(m.method, CaveDirMatchMethod.unmatched);
      expect(m.caveUuid, isNull);
    });

    test('ambiguous title still falls through to a unique code match', () {
      final m = CaveDocumentDirectoryMatcher.match('2046-18 Dup', [
        CaveMatchCandidate(caveUuid: caveA, title: 'Dup'),
        CaveMatchCandidate(
          caveUuid: caveB,
          title: 'Dup',
          areaCode: '2046',
          caveCode: '18',
        ),
      ]);
      expect(m.caveUuid, caveB);
      expect(m.method, CaveDirMatchMethod.code);
    });

    test('ambiguous code is left unmatched', () {
      final m = CaveDocumentDirectoryMatcher.match('2046-18 X', [
        CaveMatchCandidate(
          caveUuid: caveA,
          title: 'A',
          areaCode: '2046',
          caveCode: '18',
        ),
        CaveMatchCandidate(
          caveUuid: caveB,
          title: 'B',
          areaCode: '2046',
          caveCode: '18',
        ),
      ]);
      expect(m.method, CaveDirMatchMethod.unmatched);
      expect(m.caveUuid, isNull);
    });
  });
}
