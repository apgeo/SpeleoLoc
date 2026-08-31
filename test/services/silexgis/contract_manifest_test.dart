import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'contract_fixtures.dart';

/// Guards the integrity of the recorded-traffic copy that every other test in
/// this directory replays.
///
/// A refresh that copied nine of eleven directories, or that rewrote a body by
/// hand, has to fail here — otherwise it fails in whichever fixture test
/// happens to reach the changed bytes first, which says nothing about the
/// copy. Currency against the server repository is a different question and no
/// test here can answer it; `docs/integrations/silexgis/00-this-copy.md` says
/// how that one is asked.
void main() {
  group('recorded contract copy', () {
    late Map<String, Object?> manifest;
    late Map<String, Object?> files;

    setUpAll(() {
      manifest =
          jsonDecode(
                File(
                  p.join(contractRoot.path, 'manifest.json'),
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      files = manifest['files']! as Map<String, Object?>;
    });

    test('is the contract version this client is built against', () {
      expect(manifest['contractVersion'], 1);
    });

    test('holds exactly the files the manifest lists', () {
      // manifest.json cannot state its own digest, and names that exclusion
      // itself rather than leaving it to be inferred.
      final excluded = (manifest['notCovered']! as List).cast<String>().toSet();
      final onDisk = contractRoot
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => p.relative(f.path, from: contractRoot.path))
          .where((rel) => !excluded.contains(rel))
          .toSet();

      expect(
        onDisk.difference(files.keys.toSet()),
        isEmpty,
        reason:
            'files present here that the manifest does not list — a '
            'recording left behind by an exchange that was renamed or '
            'deleted upstream',
      );
      expect(
        files.keys.toSet().difference(onDisk),
        isEmpty,
        reason:
            'files the manifest lists that are missing here — a partial '
            'refresh',
      );
      expect(onDisk.length, manifest['fileCount']);
    });

    test('every recorded byte matches its digest', () {
      for (final entry in files.entries) {
        final bytes = File(
          p.join(contractRoot.path, entry.key),
        ).readAsBytesSync();
        final meta = entry.value! as Map<String, Object?>;
        expect(bytes.length, meta['bytes'], reason: entry.key);
        expect(
          sha256.convert(bytes).toString(),
          meta['sha256'],
          reason: entry.key,
        );
      }
    });
  });
}
