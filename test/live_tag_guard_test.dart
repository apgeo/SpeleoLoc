import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// A test that contacts a real server is tagged `live`. CI leaves the tag out
/// with `--exclude-tags live`; elsewhere each such file skips itself unless
/// its own environment variable is set. A new one that forgets the tag
/// escapes that exclusion, and signs in wherever its environment points.
void main() {
  test('every live test file is tagged live', () {
    final files =
        Directory('test')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('_live_test.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(files, isNotEmpty);
    final untagged = <String>[
      for (final file in files)
        if (!_tagsLive(file.readAsLinesSync())) p.relative(file.path),
    ];
    expect(untagged, isEmpty, reason: 'add @Tags([\'live\']) and library;');
  });

  test('dart_test.yaml declares the live tag', () {
    final config = File('dart_test.yaml').readAsStringSync();
    expect(config, matches(RegExp(r'^\s+live:', multiLine: true)));
  });

  test('every SilexGIS live test names its switch', () {
    // The server's end-to-end runner finds the files to run by that name.
    final files = Directory('test/services/silexgis')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('_live_test.dart'));
    expect(files, isNotEmpty);
    for (final file in files) {
      expect(
        file.readAsStringSync(),
        contains('SPELEO_LOC_SILEXGIS_LIVE'),
        reason: p.relative(file.path),
      );
    }
  });
}

/// The library annotation, ahead of any import: tags placed anywhere else
/// annotate a single declaration and do not reach the file's tests.
bool _tagsLive(List<String> lines) {
  for (final line in lines) {
    final text = line.trim();
    if (text.isEmpty || text.startsWith('//')) continue;
    return text == "@Tags(['live'])";
  }
  return false;
}
