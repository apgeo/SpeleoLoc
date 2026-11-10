import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/services/archive/archive_extraction.dart';
import 'package:speleoloc/services/archive/zip_file_writer.dart';

/// Reading chosen entries of a zip: the small ones into memory, the others
/// to the files the caller names, each on its own and in chunks. Every
/// entry here is invented.
void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('zip_entry_extraction_');
  });

  tearDown(() => dir.delete(recursive: true));

  Uint8List pattern(int size) => Uint8List.fromList(
    List<int>.generate(size, (i) => (i * 131 + (i >> 9)) & 0xff),
  );

  Future<String> zipOf(Map<String, List<int>> entries) async {
    final path = p.join(dir.path, 'in.zip');
    await writeZipFile(path, [
      for (final MapEntry(:key, :value) in entries.entries)
        ZipEntrySource.bytes(key, Uint8List.fromList(value)),
    ]);
    return path;
  }

  test('reads the names of every file entry and the content of the wanted '
      'ones only', () async {
    final zip = await zipOf({
      'manifest.json': utf8.encode('{"v":1}'),
      'tables/a.jsonl': utf8.encode('{"x":1}\n'),
      'assets/big.bin': pattern(2 << 20),
    });

    final (:fileNames, :contents) = await readZipEntries(zip, {
      'manifest.json',
      'tables/a.jsonl',
      'tables/absent.jsonl',
    });

    expect(fileNames, ['manifest.json', 'tables/a.jsonl', 'assets/big.bin']);
    expect(contents.keys, unorderedEquals(['manifest.json', 'tables/a.jsonl']));
    expect(utf8.decode(contents['manifest.json']!), '{"v":1}');
  });

  test('writes the named entries to their files, reports the missing ones, '
      'and one that fails does not stop the rest', () async {
    final body = pattern(3 << 20);
    final zip = await zipOf({
      'assets/a.bin': body,
      'assets/b.txt': utf8.encode('invented'),
      'assets/c.txt': utf8.encode('not asked for'),
    });
    final a = p.join(dir.path, 'out', 'a.bin');
    final blocked = Directory(p.join(dir.path, 'out', 'b.txt'));
    await blocked.create(recursive: true);

    final result = await extractZipEntriesTo(zip, {
      'assets/a.bin': a,
      'assets/b.txt': blocked.path,
      'assets/absent.txt': p.join(dir.path, 'out', 'absent.txt'),
    });

    expect(result.written, 1);
    expect(result.failures.keys, ['assets/b.txt']);
    expect(result.missing, ['assets/absent.txt']);
    expect(await File(a).readAsBytes(), body);
    expect(await blocked.exists(), isTrue);
    expect(
      Directory(
        p.join(dir.path, 'out'),
      ).listSync().map((e) => p.basename(e.path)),
      unorderedEquals(['a.bin', 'b.txt']),
    );
  });

  test('an entry whose data is damaged leaves no half-written file', () async {
    final archive = Archive()
      ..addFile(ArchiveFile('assets/a.bin', 1 << 20, pattern(1 << 20)));
    final bytes = Uint8List.fromList(ZipEncoder().encode(archive)!);
    // Past the local header, inside the deflated data.
    bytes.fillRange(80, 4000, 0xff);
    final zip = p.join(dir.path, 'damaged.zip');
    await File(zip).writeAsBytes(bytes);
    final out = p.join(dir.path, 'a.bin');

    final result = await extractZipEntriesTo(zip, {'assets/a.bin': out});

    expect(result.written, 0);
    expect(result.failures.keys, ['assets/a.bin']);
    expect(File(out).existsSync(), isFalse);
  });
}
