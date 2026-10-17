import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:speleoloc/services/trip_media/picked_files_media_source.dart';
import 'package:speleoloc/services/trip_media/trip_media_item.dart';

/// Hands back whatever the test queued, one batch per pick.
class _QueuedPicker extends ImagePicker {
  final List<List<XFile>> batches = [];
  int calls = 0;

  @override
  Future<List<XFile>> pickMultipleMedia({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async {
    calls++;
    return batches.isEmpty ? const [] : batches.removeAt(0);
  }
}

/// The picker path is where the user hand-picks pictures and then assigns
/// places to them, so losing the list loses that work. Two ways it used to:
/// reloading — after a change of date range — re-opened the picker, and
/// dismissing it then emptied the list.
void main() {
  late Directory dir;
  late _QueuedPicker picker;
  late PickedFilesMediaSource source;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('picked_files_');
    picker = _QueuedPicker();
    source = PickedFilesMediaSource(picker: picker);
  });
  tearDown(() => dir.delete(recursive: true));

  /// An invented photo taken at [at], under [name].
  XFile photo(String name, DateTime at, {int seed = 0}) {
    final image = img.Image(width: 4, height: 4);
    image.setPixelRgb(0, 0, seed % 256, 10, 20);
    image.exif.exifIfd['DateTimeOriginal'] =
        '${at.year}:${_two(at.month)}:${_two(at.day)} '
        '${_two(at.hour)}:${_two(at.minute)}:${_two(at.second)}';
    // A directory per pick: the Android picker keeps the original name
    // inside a fresh folder, so the basename is the picture's own name.
    final folder = Directory('${dir.path}/${dir.listSync().length}')
      ..createSync();
    final file = File('${folder.path}/$name')
      ..writeAsBytesSync(img.encodeJpg(image));
    return XFile(file.path);
  }

  test('it says it is a source the user picks from', () {
    expect(source.choosesItems, isTrue);
  });

  test('listing never opens the picker', () async {
    picker.batches.add([photo('a.jpg', DateTime(2026, 10, 13, 10))]);
    await source.chooseMore();
    expect(picker.calls, 1);

    await source.list();
    await source.list(from: DateTime(2026, 10, 13));
    expect(picker.calls, 1, reason: 'a reload must not re-prompt');
  });

  test('picking again adds to what was picked', () async {
    picker.batches
      ..add([photo('a.jpg', DateTime(2026, 10, 13, 10), seed: 1)])
      ..add([photo('b.jpg', DateTime(2026, 10, 13, 11), seed: 2)]);

    expect(await source.chooseMore(), 1);
    expect(await source.chooseMore(), 1);
    expect((await source.list()).map((i) => i.displayName), ['a.jpg', 'b.jpg']);
  });

  test('a dismissed picker keeps the list as it was', () async {
    picker.batches.add([photo('a.jpg', DateTime(2026, 10, 13, 10))]);
    await source.chooseMore();

    // Nothing queued: the picker comes back empty, as when dismissed.
    expect(await source.chooseMore(), 0);
    expect(await source.list(), hasLength(1));
  });

  test('the same picture picked twice is listed once', () async {
    // The picker hands over a fresh cache copy each time, under a new path.
    picker.batches
      ..add([photo('a.jpg', DateTime(2026, 10, 13, 10), seed: 5)])
      ..add([photo('a.jpg', DateTime(2026, 10, 13, 10), seed: 5)]);
    await source.chooseMore();
    expect(await source.chooseMore(), 0);
    expect(await source.list(), hasLength(1));
  });

  test('the same picture under another name is still listed once', () async {
    // iOS names every copy image_picker_<uuid>, so a name says nothing.
    picker.batches
      ..add([photo('image_picker_1.jpg', DateTime(2026, 10, 13, 10), seed: 9)])
      ..add([photo('image_picker_2.jpg', DateTime(2026, 10, 13, 10), seed: 9)]);
    await source.chooseMore();
    expect(await source.chooseMore(), 0);
    expect(await source.list(), hasLength(1));
  });

  test('the date range filters what was picked, in the order taken', () async {
    picker.batches.add([
      photo('late.jpg', DateTime(2026, 10, 13, 15), seed: 1),
      photo('before.jpg', DateTime(2026, 10, 11, 20), seed: 2),
      photo('early.jpg', DateTime(2026, 10, 13, 9), seed: 3),
    ]);
    await source.chooseMore();

    final listed = await source.list(
      from: DateTime(2026, 10, 13),
      to: DateTime(2026, 10, 13, 23, 59, 59),
    );
    expect(listed.map((i) => i.displayName), ['early.jpg', 'late.jpg']);
    expect(listed.first.capturedAtSource, MediaTimeSource.exif);
  });
}

String _two(int v) => v.toString().padLeft(2, '0');
