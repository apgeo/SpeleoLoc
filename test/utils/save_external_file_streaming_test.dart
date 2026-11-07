import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/utils/documentation_file_helper.dart';

/// Attached files include multi-gigabyte videos, so storing one must hash it
/// as a stream: reading it whole would claim its size in the heap.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('save_external_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => p.join(dir.path, 'docs'),
        );
  });

  tearDown(() => dir.delete(recursive: true));

  test('stores a small file with the hash and size of its content', () async {
    final bytes = Uint8List.fromList(utf8.encode('an invented field note'));
    final source = await File(p.join(dir.path, 'note.txt')).writeAsBytes(bytes);

    final info = await DocumentationFileHelper.saveExternalFile(source);

    expect(info.fileSize, bytes.length);
    expect(info.fileHash, sha256.convert(bytes).toString());
    expect(await File(info.absolutePath).readAsBytes(), bytes);
  });

  test('stores a file larger than the memory it is allowed to use, with the '
      'same hash a whole read gives', () async {
    // Sparse, so writing the source costs no disk and no memory.
    const size = 256 << 20;
    final source = File(p.join(dir.path, 'video.mp4'));
    final raf = source.openSync(mode: FileMode.write);
    raf
      ..setPositionSync(size - 1)
      ..writeByteSync(0x7f)
      ..closeSync();

    final expected = _digestOfZerosThen(size - 1, 0x7f);
    // Growth is measured from the resident size at the start, not from the
    // peak: a peak left high by earlier work would hide any growth that
    // stays below it, and the check would pass whatever the code held.
    final rssBefore = ProcessInfo.currentRss;

    final info = await DocumentationFileHelper.saveExternalFile(source);

    expect(info.fileSize, size);
    expect(info.fileHash, expected);
    // A whole read raises the process peak by at least the file's size.
    expect(ProcessInfo.maxRss - rssBefore, lessThan(size ~/ 2));
  });
}

/// SHA-256 of [zeros] zero bytes followed by [last], fed in small chunks.
String _digestOfZerosThen(int zeros, int last) {
  Digest? result;
  final input = sha256.startChunkedConversion(
    ChunkedConversionSink<Digest>.withCallback((d) => result = d.single),
  );
  final chunk = Uint8List(1 << 20);
  var left = zeros;
  while (left > 0) {
    final n = left < chunk.length ? left : chunk.length;
    input.add(n == chunk.length ? chunk : Uint8List.sublistView(chunk, 0, n));
    left -= n;
  }
  input
    ..add([last])
    ..close();
  return result!.toString();
}
