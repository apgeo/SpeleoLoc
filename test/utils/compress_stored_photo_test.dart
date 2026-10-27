import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speleoloc/utils/documentation_file_helper.dart';
import 'package:speleoloc/utils/image_compression_settings.dart';

/// Compression happens on the copy in app storage; the file the caver picked
/// keeps its bytes.
void main() {
  late Directory dir;
  late Directory storage;

  const settings = ImageCompressionSettings(
    enabled: true,
    maxResolution: 32,
    quality: 50,
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('compress_stored_');
    storage = await Directory('${dir.path}/stored').create();
  });

  tearDown(() => dir.delete(recursive: true));

  Uint8List inventedPng() {
    final image = img.Image(width: 64, height: 48);
    img.fill(image, color: img.ColorRgb8(30, 120, 200));
    return Uint8List.fromList(img.encodePng(image));
  }

  Future<SavedFileInfo> copyOf(File source) async {
    final copy = await source.copy(
      '${storage.path}/${source.uri.pathSegments.last}',
    );
    final bytes = await copy.readAsBytes();
    return SavedFileInfo(
      relativePath: 'documentation_files/${copy.uri.pathSegments.last}',
      absolutePath: copy.path,
      fileSize: bytes.length,
      fileHash: DocumentationFileHelper.computeSha256(bytes),
    );
  }

  test('the source file keeps its bytes and the copy becomes a .jpg', () async {
    final original = inventedPng();
    final source = await File('${dir.path}/pick.png').writeAsBytes(original);
    final info = await copyOf(source);

    final result = await DocumentationFileHelper.compressStoredPhoto(
      info,
      settings,
    );

    expect(await source.readAsBytes(), original);
    expect(result.absolutePath, endsWith('.jpg'));
    expect(result.relativePath, endsWith('.jpg'));
    expect(await File(info.absolutePath).exists(), isFalse);

    final stored = await File(result.absolutePath).readAsBytes();
    expect(stored.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
    expect(result.fileSize, stored.length);
    expect(result.fileHash, DocumentationFileHelper.computeSha256(stored));
    expect(img.decodeImage(stored)!.width, 32);
  });

  test('a copy that is already .jpg keeps its name', () async {
    final jpg = Uint8List.fromList(
      img.encodeJpg(img.Image(width: 64, height: 48)),
    );
    final source = await File('${dir.path}/pick.jpg').writeAsBytes(jpg);
    final info = await copyOf(source);

    final result = await DocumentationFileHelper.compressStoredPhoto(
      info,
      settings,
    );

    expect(result.relativePath, info.relativePath);
    expect(await source.readAsBytes(), jpg);
  });

  test('an undecodable file is returned untouched', () async {
    final source = await File(
      '${dir.path}/pick.png',
    ).writeAsBytes(Uint8List.fromList(List.filled(64, 7)));
    final info = await copyOf(source);

    final result = await DocumentationFileHelper.compressStoredPhoto(
      info,
      settings,
    );

    expect(result.relativePath, info.relativePath);
    expect(await File(result.absolutePath).readAsBytes(), List.filled(64, 7));
  });
}
