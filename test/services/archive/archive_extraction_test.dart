import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/services/archive/archive_extraction.dart';

/// A data archive opened through Import is a file anyone may have handed
/// over, so its entry names must never place a file outside the folder it is
/// extracted to: the next steps copy that folder over the documents folder.
void main() {
  late Directory root;
  late Directory dest;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('speleoloc_extract_');
    // Two levels deep, so `../` and `../../` still land inside [root].
    dest = Directory(p.join(root.path, 'cache', 'import'));
    await dest.create(recursive: true);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  ArchiveFile text(String name, String body) {
    final bytes = utf8.encode(body);
    return ArchiveFile(name, bytes.length, bytes);
  }

  /// Encodes and decodes [files] so names go through the zip reader the app
  /// uses.
  Archive roundTrip(List<ArchiveFile> files) {
    final archive = Archive();
    files.forEach(archive.addFile);
    return ZipDecoder().decodeBytes(ZipEncoder().encode(archive)!);
  }

  List<String> filesOutsideDest() => [
    for (final e in root.listSync(recursive: true, followLinks: false))
      if (e is File && !p.isWithin(dest.path, e.path)) e.path,
  ];

  test('writes the database, manifest and nested file entries', () async {
    final rejected = extractArchiveInto(
      roundTrip([
        text('speleo_loc.sqlite', 'db'),
        text('manifest.json', '{}'),
        text('documentation_files/hall.jpg', 'photo'),
      ]),
      dest,
    ).outside;

    expect(rejected, isEmpty);
    expect(
      await File(p.join(dest.path, 'speleo_loc.sqlite')).readAsString(),
      'db',
    );
    expect(
      await File(
        p.join(dest.path, 'documentation_files', 'hall.jpg'),
      ).readAsString(),
      'photo',
    );
  });

  test('skips and reports entries that would land outside the folder, and '
      'still writes the rest', () async {
    final hostile = [
      '../speleo_loc.sqlite',
      '../../app_flutter/speleo_loc.sqlite',
      'documentation_files/../../escape.txt',
      r'..\backslash.txt',
      '/${p.join(root.path, 'absolute.txt')}',
      '.',
      'documentation_files/..',
    ];

    final rejected = extractArchiveInto(
      roundTrip([
        for (final name in hostile) text(name, 'payload'),
        text('documentation_files/hall.jpg', 'photo'),
      ]),
      dest,
    ).outside;

    expect(rejected, hasLength(hostile.length));
    expect(filesOutsideDest(), isEmpty);
    expect(
      await File(
        p.join(dest.path, 'documentation_files', 'hall.jpg'),
      ).readAsString(),
      'photo',
    );
    expect(
      dest
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => p.relative(f.path, from: dest.path)),
      [p.join('documentation_files', 'hall.jpg')],
    );
  });

  test('no name built from separators, dots and letters lands outside the '
      'folder', () async {
    final random = Random(20261107);
    const pieces = ['a', '.', '..', '/', r'\'];
    for (var i = 0; i < 200; i++) {
      final name = [
        for (var j = 0; j < 1 + random.nextInt(8); j++)
          pieces[random.nextInt(pieces.length)],
      ].join();
      // One entry per extraction, each deeper than its name can climb, so an
      // escape lands where this test sees it.
      final caseRoot = Directory(p.join(root.path, 'case$i'));
      final into = Directory(
        p.joinAll([caseRoot.path, for (var d = 0; d < 9; d++) 'd$d']),
      );
      await into.create(recursive: true);

      final rejected = extractArchiveInto(
        roundTrip([text(name, 'payload')]),
        into,
      ).outside;

      final outside = [
        for (final e in caseRoot.listSync(recursive: true))
          if (e is File && !p.isWithin(into.path, e.path)) e.path,
      ];
      expect(outside, isEmpty, reason: '"$name"');
      final written = into.listSync(recursive: true).whereType<File>();
      expect(written.length + rejected.length, lessThanOrEqualTo(1));
    }
    expect(
      root.listSync().map((e) => p.basename(e.path)),
      everyElement(anyOf(startsWith('case'), 'cache')),
    );
  });

  test('an entry that cannot be written is reported, and the rest are still '
      'written', () {
    for (final order in [
      ['documentation_files/x', 'documentation_files/x/inner.jpg'],
      ['documentation_files/x/inner.jpg', 'documentation_files/x'],
    ]) {
      final into = Directory(p.join(root.path, 'case${order.first.length}'));
      into.createSync();

      final extraction = extractArchiveInto(
        roundTrip([
          for (final name in order) text(name, 'payload'),
          text('documentation_files/hall.jpg', 'photo'),
        ]),
        into,
      );

      expect(extraction.outside, isEmpty);
      expect(extraction.failures.keys, [order.last], reason: '$order');
      expect(
        File(
          p.join(into.path, 'documentation_files', 'hall.jpg'),
        ).readAsStringSync(),
        'photo',
      );
      expect(
        FileSystemEntity.typeSync(
          p.joinAll([into.path, ...order.first.split('/')]),
        ),
        isNot(FileSystemEntityType.notFound),
      );
    }
  });

  test('never materialises a symbolic-link entry', () async {
    final link = text('documentation_files/link.jpg', '../../speleo_loc.sqlite')
      ..isFile = false
      ..isSymbolicLink = true
      ..nameOfLinkedFile = '../../speleo_loc.sqlite';
    final archive = Archive()..addFile(link);

    final rejected = extractArchiveInto(archive, dest).outside;

    expect(rejected, isEmpty);
    expect(root.listSync(recursive: true).whereType<Link>(), isEmpty);
    expect(dest.listSync(recursive: true).whereType<File>(), isEmpty);
  });
}
