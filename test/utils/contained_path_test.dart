import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/utils/contained_path.dart';

void main() {
  final base = p.join(p.rootPrefix(p.current), 'data', 'app_flutter');

  group('containedPath', () {
    test('keeps a plain and a nested relative name inside the folder', () {
      expect(containedPath(base, 'a.jpg'), p.join(base, 'a.jpg'));
      expect(
        containedPath(base, 'documentation_files/a.jpg'),
        p.join(base, 'documentation_files', 'a.jpg'),
      );
    });

    test('reads a backslash as a separator', () {
      expect(
        containedPath(base, r'documentation_files\a.jpg'),
        p.join(base, 'documentation_files', 'a.jpg'),
      );
    });

    test('drops empty and current-folder segments', () {
      expect(
        containedPath(base, './documentation_files//a.jpg'),
        p.join(base, 'documentation_files', 'a.jpg'),
      );
    });

    test('rejects any parent-folder segment', () {
      for (final name in const [
        '..',
        '../speleo_loc.sqlite',
        '../../shared_prefs/FlutterSecureStorage.xml',
        'documentation_files/../../x',
        'a/../b',
        r'..\x',
        r'documentation_files\..\..\x',
      ]) {
        expect(containedPath(base, name), isNull, reason: name);
      }
    });

    test('rejects absolute names of every form', () {
      for (final name in const [
        '/etc/passwd',
        '/../../../app_flutter/speleo_loc.sqlite',
        r'\Windows\x',
        r'\\host\share\x',
        r'C:\x',
        'C:/x',
        'c:x',
      ]) {
        expect(containedPath(base, name), isNull, reason: name);
      }
    });

    test('rejects names that resolve to the folder itself', () {
      for (final name in const ['', '.', './', '/', '././.', r'.\']) {
        expect(containedPath(base, name), isNull, reason: '"$name"');
      }
    });

    test('rejects a NUL byte', () {
      expect(containedPath(base, 'a\u0000.jpg'), isNull);
    });
  });

  group('isPlainFileName', () {
    test('accepts one ordinary file name', () {
      expect(isPlainFileName('report.odt'), isTrue);
      expect(isPlainFileName('Hall photo (2).jpg'), isTrue);
      expect(isPlainFileName('...'), isTrue);
    });

    test('rejects separators, parent and current folder, and empty', () {
      for (final name in const [
        '',
        '.',
        '..',
        'a/b.odt',
        r'a\b.odt',
        '/report.odt',
        '../report.odt',
        '/../../../shared_prefs/FlutterSecureStorage.xml',
        r'C:\report.odt',
        'a\u0000.odt',
      ]) {
        expect(isPlainFileName(name), isFalse, reason: '"$name"');
      }
    });
  });
}
