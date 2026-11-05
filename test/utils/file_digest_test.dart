import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/utils/file_digest.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('file_digest_');
  });

  tearDown(() => dir.delete(recursive: true));

  const mb = 1 << 20;

  for (final size in [0, 1, mb - 1, mb, mb + 1, 3 * mb + 17]) {
    test('a $size-byte file hashes to what a whole read gives', () async {
      final bytes = Uint8List.fromList(
        List<int>.generate(size, (i) => (i * 31 + 7) & 0xff),
      );
      final path = p.join(dir.path, 'f$size.bin');
      await File(path).writeAsBytes(bytes);

      final digest = await FileDigest.of(path);

      expect(digest.size, size);
      expect(digest.sha256Hex, sha256.convert(bytes).toString());
    });
  }

  test('a missing file fails rather than hashing nothing', () async {
    await expectLater(
      FileDigest.of(p.join(dir.path, 'absent.bin')),
      throwsA(isA<FileSystemException>()),
    );
  });
}
