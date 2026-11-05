import 'dart:convert';
import 'dart:io';

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
    );

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
    );

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

  test('never materialises a symbolic-link entry', () async {
    final link = text('documentation_files/link.jpg', '../../speleo_loc.sqlite')
      ..isFile = false
      ..isSymbolicLink = true
      ..nameOfLinkedFile = '../../speleo_loc.sqlite';
    final archive = Archive()..addFile(link);

    final rejected = extractArchiveInto(archive, dest);

    expect(rejected, isEmpty);
    expect(root.listSync(recursive: true).whereType<Link>(), isEmpty);
    expect(dest.listSync(recursive: true).whereType<File>(), isEmpty);
  });
}
