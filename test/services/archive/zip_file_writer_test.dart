import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/services/archive/archive_extraction.dart';
import 'package:speleoloc/services/archive/zip_file_writer.dart';
import 'package:speleoloc/utils/file_digest.dart';

/// Data archives are written and read entry by entry through files, so an
/// archive larger than the memory a phone can spare still round-trips.
void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('zip_file_writer_');
  });

  tearDown(() => dir.delete(recursive: true));

  Future<File> write(String name, List<int> bytes) => File(
    p.join(dir.path, 'src', name),
  ).create(recursive: true).then((f) => f.writeAsBytes(bytes));

  Uint8List pattern(int size) => Uint8List.fromList(
    List<int>.generate(size, (i) => (i * 131 + (i >> 9)) & 0xff),
  );

  test('round-trips small, empty and nested entries, and the zip reads with '
      'the package decoder older app versions use', () async {
    final text = await write('note.txt', utf8.encode('invented note ' * 400));
    final empty = await write('empty.bin', const []);
    final binary = await write('scan.bin', pattern(3 << 20));
    final zipPath = p.join(dir.path, 'out.zip');

    await writeZipFile(zipPath, [
      ZipEntrySource.file('documentation_files/note.txt', text.path),
      ZipEntrySource.file('documentation_files/empty.bin', empty.path),
      ZipEntrySource.file('cave_x/scan.bin', binary.path),
      ZipEntrySource.file('documentation_files/gone.jpg', '${dir.path}/no'),
      ZipEntrySource.bytes('manifest.json', utf8.encode('{"version":1}')),
    ]);

    final decoded = ZipDecoder().decodeBytes(
      await File(zipPath).readAsBytes(),
      verify: true,
    );
    expect(decoded.files.map((f) => f.name), [
      'documentation_files/note.txt',
      'documentation_files/empty.bin',
      'cave_x/scan.bin',
      'manifest.json',
    ]);
    expect(
      decoded.findFile('documentation_files/note.txt')!.content,
      await text.readAsBytes(),
    );
    expect(decoded.findFile('documentation_files/empty.bin')!.content, isEmpty);
    expect(
      decoded.findFile('cave_x/scan.bin')!.content,
      await binary.readAsBytes(),
    );
    // Text compresses; the writer must not have stored it.
    expect(
      await File(zipPath).length(),
      lessThan(await binary.length() + 6000),
    );

    final out = await Directory(p.join(dir.path, 'out')).create();
    final rejected = await extractZipFileInto(zipPath, out.path);

    expect(rejected, isEmpty);
    expect(
      await File(
        p.join(out.path, 'documentation_files', 'note.txt'),
      ).readAsBytes(),
      await text.readAsBytes(),
    );
    expect(
      await File(p.join(out.path, 'documentation_files', 'empty.bin')).length(),
      0,
    );
    expect(
      await File(p.join(out.path, 'cave_x', 'scan.bin')).readAsBytes(),
      await binary.readAsBytes(),
    );
    expect(
      await File(p.join(out.path, 'manifest.json')).readAsString(),
      '{"version":1}',
    );
  });

  test('extracts a zip written whole by the package encoder, as older app '
      'versions exported it', () async {
    final body = pattern(5 << 20);
    final archive = Archive()
      ..addFile(ArchiveFile('documentation_files/a.bin', body.length, body))
      ..addFile(ArchiveFile.string('manifest.json', '{}'));
    final zipPath = p.join(dir.path, 'old.zip');
    await File(zipPath).writeAsBytes(ZipEncoder().encode(archive)!);

    final out = await Directory(p.join(dir.path, 'out')).create();
    await extractZipFileInto(zipPath, out.path);

    expect(
      await File(
        p.join(out.path, 'documentation_files', 'a.bin'),
      ).readAsBytes(),
      body,
    );
  });

  test('writes and extracts a file larger than the memory it may use, '
      'byte for byte', () async {
    // Sparse, so creating it costs neither memory nor disk.
    const size = 256 << 20;
    final video = File(p.join(dir.path, 'src', 'video.mp4'));
    await video.create(recursive: true);
    video.openSync(mode: FileMode.write)
      ..setPositionSync(size - 1)
      ..writeByteSync(0x5a)
      ..closeSync();
    final expected = await FileDigest.of(video.path);
    final zipPath = p.join(dir.path, 'big.zip');

    final peakBefore = ProcessInfo.maxRss;
    await writeZipFile(zipPath, [
      ZipEntrySource.file('documentation_files/video.mp4', video.path),
    ]);
    final out = await Directory(p.join(dir.path, 'out')).create();
    await extractZipFileInto(zipPath, out.path);
    final peakGrowth = ProcessInfo.maxRss - peakBefore;

    final extracted = await FileDigest.of(
      p.join(out.path, 'documentation_files', 'video.mp4'),
    );
    expect(extracted.size, size);
    expect(extracted.sha256Hex, expected.sha256Hex);
    // Holding the entry whole raises the process peak by its size at least.
    expect(peakGrowth, lessThan(size ~/ 2));
  });
}
