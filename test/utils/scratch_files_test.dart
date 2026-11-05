import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/utils/scratch_files.dart';

/// Recordings and waveform files go to the temporary folder, which the OS
/// clears only when it runs short of space, so the screen removes them.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('scratch_files_'));
  tearDown(() => dir.deleteSync(recursive: true));

  String touch(String name) =>
      (File('${dir.path}/$name')..writeAsStringSync('x')).path;

  test('deleteAll removes every tracked file', () async {
    final scratch = ScratchFiles()
      ..add(touch('a.wav'))
      ..add(touch('b.wav'));

    await scratch.deleteAll();

    expect(dir.listSync(), isEmpty);
  });

  test('deleteAllExcept keeps the named file and forgets the rest', () async {
    final scratch = ScratchFiles();
    final old = touch('old.wav');
    final current = touch('current.wav');
    scratch
      ..add(old)
      ..add(current);

    await scratch.deleteAllExcept(current);
    expect(File(old).existsSync(), isFalse);
    expect(File(current).existsSync(), isTrue);

    await scratch.deleteAll();
    expect(File(current).existsSync(), isFalse);
  });

  test('a file that is already gone is not an error', () async {
    final scratch = ScratchFiles()..add('${dir.path}/never_written.wav');
    await scratch.deleteAll();
  });

  test('files outside the tracked set are left alone', () async {
    final untracked = touch('saved.wav');
    final scratch = ScratchFiles()..add(touch('rec.wav'));

    await scratch.deleteAll();

    expect(File(untracked).existsSync(), isTrue);
  });
}
