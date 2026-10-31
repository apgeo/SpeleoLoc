import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/cave_model/caveview_assets.dart';

/// The vendored CaveView build is exactly what `tool/refresh_caveview.sh`
/// wrote, and the app, the build directory and pubspec.yaml agree on which.
void main() {
  final build = Directory(CaveViewAssets.buildDir);

  test('one CaveView version is vendored, the one the app names', () {
    final versions = Directory('assets/caveview')
        .listSync()
        .whereType<Directory>()
        .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
        .where((name) => name.startsWith('v'))
        .toList();
    expect(versions, ['v${CaveViewAssets.version}']);
  });

  test('every vendored file matches the checksum it was built with', () {
    final lines = File('${build.path}/BUILD.txt').readAsLinesSync();
    expect(lines.first, 'version ${CaveViewAssets.version}');
    final sums = lines.skip(2).map((l) => l.split(RegExp(r'\s+'))).toList();
    expect(sums, isNotEmpty);
    for (final [sum, path] in sums) {
      final bytes = File('${build.path}/$path').readAsBytesSync();
      expect(sha256.convert(bytes).toString(), sum, reason: path);
    }
  });

  test('pubspec.yaml bundles every vendored folder', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- ${CaveViewAssets.buildDir}/\n'));
    for (final folder in build.listSync().whereType<Directory>()) {
      final name = folder.uri.pathSegments.where((s) => s.isNotEmpty).last;
      expect(
        pubspec,
        contains('- ${CaveViewAssets.buildDir}/$name/\n'),
        reason: name,
      );
    }
  });
}
