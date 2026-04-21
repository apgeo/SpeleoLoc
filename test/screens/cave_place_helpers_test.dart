import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_place/cave_place_form_utils.dart';
import 'package:speleoloc/screens/cave_places/cave_place_filter.dart';

void main() {
  group('formatDepthValue', () {
    test('null returns empty', () {
      expect(formatDepthValue(null), '');
    });

    test('integer-valued double shows no decimals', () {
      expect(formatDepthValue(10.0), '10');
    });

    test('fractional value shows 1 decimal, trimming trailing zero', () {
      expect(formatDepthValue(10.5), '10.5');
      expect(formatDepthValue(10.25), '10.3'); // toStringAsFixed(1) rounds
      expect(formatDepthValue(10.10), '10.1');
    });
  });

  group('parseDepthValue', () {
    test('null/empty/invalid returns null', () {
      expect(parseDepthValue(''), isNull);
      expect(parseDepthValue('abc'), isNull);
    });

    test('comma or dot decimal separators both parse', () {
      expect(parseDepthValue('10'), 10.0);
      expect(parseDepthValue('10.5'), 10.5);
      expect(parseDepthValue('10,5'), 10.5);
    });
  });

  group('computeDescriptionLines', () {
    test('empty → 1 line, short text → 1 line', () {
      expect(computeDescriptionLines(''), 1);
      expect(computeDescriptionLines('short'), 1);
    });

    test('grows with newlines, capped at 5', () {
      expect(computeDescriptionLines('a\nb\nc'), 3);
      expect(computeDescriptionLines('a\nb\nc\nd\ne\nf\ng'), 5);
    });
  });

  group('filterCavePlaces', () {
    CavePlace mk(int id, String title,
        {int? qr, int? areaId}) =>
        CavePlace(
          id: id,
          title: title,
          caveId: 1,
          placeQrCodeIdentifier: qr,
          caveAreaId: areaId,
        );

    final places = [
      mk(1, 'Entrance', qr: 1001, areaId: 10),
      mk(2, 'Sump Room', qr: 2002, areaId: 20),
      mk(3, 'Crystal Hall', qr: 3003),
    ];
    final areaTitles = {10: 'Main Gallery', 20: 'Deep Section'};

    test('empty query returns a copy of all', () {
      final r = filterCavePlaces(places, '', areaTitles);
      expect(r, places);
      expect(identical(r, places), isFalse);
    });

    test('filters by title (case-insensitive)', () {
      expect(filterCavePlaces(places, 'sump', areaTitles).map((p) => p.id),
          [2]);
    });

    test('filters by qr code substring', () {
      expect(
          filterCavePlaces(places, '2002', areaTitles).map((p) => p.id), [2]);
    });

    test('filters by area title', () {
      expect(filterCavePlaces(places, 'deep', areaTitles).map((p) => p.id),
          [2]);
    });

    test('whitespace-only query returns all', () {
      expect(filterCavePlaces(places, '   ', areaTitles).length, 3);
    });
  });
}
