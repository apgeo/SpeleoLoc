import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Services and data code never import Flutter UI: no widget library, no
/// screen or widget of the app, no navigation. Whatever they need from the
/// screens comes through a small interface the UI layer supplies.
void main() {
  final forbidden = <RegExp>[
    RegExp(
      r'''^import\s+['"]package:flutter/(material|widgets|cupertino)\.dart''',
    ),
    RegExp(r'''^import\s+['"]package:speleoloc/(screens|widgets)/'''),
    RegExp(
      r'''^import\s+['"]package:speleoloc/utils/(app_routes|navigator_key)\.dart''',
    ),
    RegExp(r'''^import\s+['"](\.\./)+(screens|widgets)/'''),
  ];

  for (final layer in ['lib/services', 'lib/data']) {
    test('$layer imports no UI code', () {
      final offenders = <String>[];
      final files = Directory(layer)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (forbidden.any((r) => r.hasMatch(line))) {
            offenders.add('${p.normalize(file.path)}:${i + 1}: $line');
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  }
}
