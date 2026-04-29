import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/trip_log_method.dart';
import 'package:speleoloc/services/trip_log_renderer.dart';
import 'package:speleoloc/utils/localization.dart';

/// Pure-function tests for [TripLogRenderer.render]. We do not load the
/// i18n bundle here — `LocServ.t(key, params)` falls back to returning the
/// key when strings are not loaded, but the substituted timestamps,
/// elapsed deltas, and event counts are still observable in the output.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await LocServ.inst.setLocale('en');
    await LocServ.inst.load();
  });
  final r = TripLogRenderer.instance;

  TripLogEvent ev(TripLogEventKind k, DateTime at,
      {String? title, String? label, String? notes}) {
    return TripLogEvent(
      kind: k,
      at: at,
      title: title,
      label: label,
      notes: notes,
    );
  }

  final start = DateTime(2026, 4, 28, 14, 32);
  final p1 = start.add(const Duration(minutes: 3));
  final p2 = start.add(const Duration(minutes: 8));
  final p3 = start.add(const Duration(minutes: 16));
  final docAt = start.add(const Duration(minutes: 50));
  final end = start.add(const Duration(hours: 2, minutes: 38));

  List<TripLogEvent> sample({bool withEnd = true}) {
    return [
      ev(TripLogEventKind.start, start, title: 'Main Gallery Survey'),
      ev(TripLogEventKind.point, p1, label: 'Sala Mare'),
      ev(TripLogEventKind.point, p2, label: 'Bifurcatie Nord', notes: 'wet'),
      ev(TripLogEventKind.point, p3, label: 'End Chamber'),
      ev(TripLogEventKind.documentAdded, docAt, label: 'sketch.jpg'),
      if (withEnd) ev(TripLogEventKind.end, end),
    ];
  }

  group('render — empty', () {
    test('returns empty string when no events', () {
      expect(r.render(const [], TripLogMethod.raw), '');
      expect(r.render(const [], TripLogMethod.classic), '');
      expect(r.render(const [], TripLogMethod.journal), '');
      expect(r.render(const [], TripLogMethod.narrative), '');
    });
  });

  group('render — raw', () {
    test('produces one line per event', () {
      final out = r.render(sample(), TripLogMethod.raw);
      expect(out.split('\n'), hasLength(6));
      // Every line begins with the legacy "[yyyy/MM/dd HH:mm:ss]" prefix.
      for (final line in out.split('\n')) {
        expect(line, matches(r'^\[\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}\] '));
      }
    });
  });

  group('render — classic', () {
    test('produces one line per event with timestamp prefix', () {
      final out = r.render(sample(), TripLogMethod.classic);
      expect(out.split('\n'), hasLength(6));
      for (final line in out.split('\n')) {
        expect(line, startsWith('['));
      }
    });

    test('appends point notes in parentheses', () {
      final out = r.render(sample(), TripLogMethod.classic);
      expect(out, contains('(wet)'));
    });
  });

  group('render — journal', () {
    test('start line has [HH:mm] without elapsed marker', () {
      final out = r.render(sample(), TripLogMethod.journal);
      final firstLine = out.split('\n').first;
      expect(firstLine, matches(r'^\[\d{2}:\d{2}\] '));
      expect(firstLine, isNot(contains('+')));
    });

    test('subsequent lines have elapsed marker', () {
      final out = r.render(sample(), TripLogMethod.journal);
      final secondLine = out.split('\n')[1];
      expect(secondLine, matches(r'^\[\d{2}:\d{2} · \+'));
      expect(secondLine, contains('+3min'));
    });

    test('first/next stop phrasing uses different keys', () {
      final out = r.render(sample(), TripLogMethod.journal);
      expect(out, contains('First stop:'));
      expect(out, contains('Moved on to'));
    });
  });

  group('render — narrative', () {
    test('paragraphs separated by blank line', () {
      final out = r.render(sample(), TripLogMethod.narrative);
      expect(out, contains('\n\n'));
    });

    test('groups three consecutive points into one paragraph', () {
      final events = [
        ev(TripLogEventKind.start, start, title: 'T'),
        ev(TripLogEventKind.point, p1, label: 'A'),
        ev(TripLogEventKind.point, p2, label: 'B'),
        ev(TripLogEventKind.point, p3, label: 'C'),
      ];
      final out = r.render(events, TripLogMethod.narrative);
      // Opening + one movement paragraph = exactly two paragraphs.
      expect(out.split('\n\n'), hasLength(2));
    });

    test('summarizes consecutive points and document into separate paragraphs', () {
      final out = r.render(sample(), TripLogMethod.narrative);
      // Opening + grouped-points paragraph + (optional notes) + document + closing.
      expect(out.split('\n\n').length, greaterThanOrEqualTo(4));
    });

    test('ongoing trip omits closing paragraph', () {
      final out =
          r.render(sample(withEnd: false), TripLogMethod.narrative);
      expect(out, isNot(contains('concluded at')));
    });

    test('emits restart paragraph between previous-run and current events',
        () {
      final earlyPoint = start.subtract(const Duration(hours: 1));
      final events = [
        ev(TripLogEventKind.start, earlyPoint, title: 'T'),
        ev(TripLogEventKind.point, earlyPoint.add(const Duration(minutes: 5)),
            label: 'Old'),
        ev(TripLogEventKind.restart, start, title: 'T'),
        ev(TripLogEventKind.point, p1, label: 'A'),
      ];
      final out = r.render(events, TripLogMethod.narrative);
      expect(out, contains('restarted'));
    });
  });
}
