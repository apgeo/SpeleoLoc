// Builds invented "cave photos" for seeding an emulator's media library.
//
// The points-from-pictures screen reads the device's own media store, so an
// emulator with an empty camera roll exercises nothing. These files carry
// the two things the screen actually works from: an EXIF capture time, and
// — for some of them — a readable QR label for a cave place, so the
// automatic detection path can be exercised as well as the manual one.
//
// Everything here is invented. No real survey data goes near it.
//
// Usage:
//   dart run tool/android/generate_test_media.dart <out-dir> [place-code...]
//   dart run tool/android/generate_test_media.dart --camera <out.png> <code>
//
// The second form draws one QR label on a plain background, for an
// emulator to show through its back camera (`-camera-back imagefile:`), so
// the live scanner has a code to read.
//
// With no place codes the defaults below are used; pass your own to match
// the codes in the database you are testing against, e.g.
//   dart run tool/android/generate_test_media.dart /tmp/media a1 a2 b7
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

/// Place codes to encode, when the caller names none.
const _defaultCodes = ['a1', 'a2', 'a3'];

/// The day the fixture trip happened on. Fixed rather than "today" so a
/// re-run produces the same library and a date-range filter can be tested
/// against a known answer.
final _tripDay = DateTime(2026, 10, 13);

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'usage: dart run tool/android/generate_test_media.dart '
      '<out-dir> [place-code...]',
    );
    exit(64);
  }
  if (args.first == '--camera') {
    if (args.length != 3) {
      stderr.writeln('usage: ... --camera <out.png> <code>');
      exit(64);
    }
    _writeCameraImage(args[1], args[2]);
    return;
  }
  final outDir = Directory(args.first)..createSync(recursive: true);
  final codes = args.length > 1 ? args.sublist(1) : _defaultCodes;

  var written = 0;

  // One photo per place code, through the day, each with its QR label.
  for (var i = 0; i < codes.length; i++) {
    final at = _tripDay.add(Duration(hours: 10 + i, minutes: 7 * (i + 1)));
    _write(
      '${outDir.path}/speleo_qr_${codes[i]}_${_stamp(at)}.jpg',
      _photo(at: at, qrPayload: codes[i], seed: i),
      at,
    );
    written++;
  }

  // Photos with no code at all: the manual-assignment path, and the bulk
  // that makes the list long enough to be worth filtering.
  for (var i = 0; i < 6; i++) {
    final at = _tripDay.add(Duration(hours: 10, minutes: 3 + i * 17));
    _write(
      '${outDir.path}/speleo_plain_${_stamp(at)}.jpg',
      _photo(at: at, qrPayload: null, seed: 100 + i),
      at,
    );
    written++;
  }

  // One from the day before, so a date-range filter has something to
  // exclude and can be shown to actually exclude it.
  final dayBefore = _tripDay.subtract(const Duration(days: 1, hours: 4));
  _write(
    '${outDir.path}/speleo_otherday_${_stamp(dayBefore)}.jpg',
    _photo(at: dayBefore, qrPayload: null, seed: 200),
    dayBefore,
  );
  written++;

  stdout.writeln('wrote $written file(s) to ${outDir.path}');
  stdout.writeln(
    'seed them with: tool/android/seed_test_media.sh ${outDir.path}',
  );
}

/// Writes [bytes] to [path] and stamps the file's modification time with
/// [at].
///
/// The mtime is not decoration: Android's media scanner fills
/// `MediaStore.date_taken` from it, and ignores the EXIF `DateTimeOriginal`
/// these files also carry — measured on an API 34 emulator, where an
/// otherwise identical file differing only in mtime was the one that got
/// the right date. `adb push` preserves mtime, so this is what survives to
/// the device, and `date_taken` is what `photo_manager` reports as the
/// capture time. The EXIF is still written because the picked-files
/// fallback path reads that instead.
void _write(String path, List<int> bytes, DateTime at) {
  final file = File(path)..writeAsBytesSync(bytes);
  file.setLastModifiedSync(at);
}

String _stamp(DateTime t) =>
    '${t.year}${_two(t.month)}${_two(t.day)}_${_two(t.hour)}${_two(t.minute)}${_two(t.second)}';

String _two(int v) => v.toString().padLeft(2, '0');

/// Renders a 640x480 JPEG that looks vaguely like a cave wall, optionally
/// with a QR label on it, stamped with [at] as its EXIF capture time.
List<int> _photo({
  required DateTime at,
  required String? qrPayload,
  required int seed,
}) {
  const w = 640;
  const h = 480;
  final image = img.Image(width: w, height: h);
  final rnd = Random(seed);

  // A mottled dark background, so each file has distinct bytes — and
  // therefore a distinct hash, which is what the importer dedupes on.
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final base = 40 + ((x * y + seed) % 23) + rnd.nextInt(12);
      image.setPixelRgb(
        x,
        y,
        base,
        (base * 0.85).round(),
        (base * 0.7).round(),
      );
    }
  }

  if (qrPayload != null) {
    _drawQr(image, qrPayload);
  }

  image.exif.exifIfd['DateTimeOriginal'] = _exifStamp(at);
  image.exif.imageIfd['DateTime'] = _exifStamp(at);
  image.exif.imageIfd['Make'] = 'SpeleoLoc';
  image.exif.imageIfd['Model'] = 'Fixture';
  return img.encodeJpg(image, quality: 92);
}

/// EXIF writes a local date-time as `YYYY:MM:DD HH:MM:SS`.
String _exifStamp(DateTime t) =>
    '${t.year}:${_two(t.month)}:${_two(t.day)} '
    '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

/// Draws [payload] as a QR code onto [image], white-on-black with a quiet
/// zone, sized so a scanner reads it from the whole frame.
void _drawQr(img.Image image, String payload) {
  final code = QrCode.fromData(
    data: payload,
    errorCorrectLevel: QrErrorCorrectLevel.M,
  );
  final rendered = QrImage(code);
  final modules = rendered.moduleCount;

  const targetPx = 300;
  final scale = (targetPx / modules).floor().clamp(2, 20);
  final size = modules * scale;
  final quiet = scale * 4;
  final originX = (image.width - size - quiet * 2) ~/ 2;
  final originY = (image.height - size - quiet * 2) ~/ 2;

  // Quiet zone: a QR without surrounding white is frequently unreadable.
  img.fillRect(
    image,
    x1: originX,
    y1: originY,
    x2: originX + size + quiet * 2,
    y2: originY + size + quiet * 2,
    color: img.ColorRgb8(255, 255, 255),
  );

  for (var row = 0; row < modules; row++) {
    for (var col = 0; col < modules; col++) {
      if (!rendered.isDark(row, col)) continue;
      final x = originX + quiet + col * scale;
      final y = originY + quiet + row * scale;
      img.fillRect(
        image,
        x1: x,
        y1: y,
        x2: x + scale - 1,
        y2: y + scale - 1,
        color: img.ColorRgb8(0, 0, 0),
      );
    }
  }
}

/// QR labels held up in front of the camera: the same code six times over,
/// on a light, slightly uneven wall.
///
/// Six, not one: the emulator turns the picture into camera frames and the
/// scanner's preview then rotates and crops them to fill a portrait screen,
/// so a single centred label ended up half outside the part the scanner
/// looks at. With a grid, whatever the crop, a whole label is in it.
void _writeCameraImage(String path, String code) {
  const w = 1280;
  const h = 960;
  const tile = 420;
  final image = img.Image(width: w, height: h);
  final rnd = Random(code.hashCode);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final base = 150 + ((x ~/ 7 + y ~/ 5) % 9) + rnd.nextInt(10);
      image.setPixelRgb(
        x,
        y,
        base,
        (base * 0.95).round(),
        (base * 0.88).round(),
      );
    }
  }
  final label = img.Image(width: tile, height: tile);
  img.fill(label, color: img.ColorRgb8(255, 255, 255));
  _drawQr(label, code);
  for (var row = 0; row < 2; row++) {
    for (var col = 0; col < 3; col++) {
      img.compositeImage(
        image,
        label,
        dstX: 10 + col * (tile + 5),
        dstY: 40 + row * (tile + 20),
      );
    }
  }
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
  stdout.writeln('wrote ${file.path} (QR for "$code", six times)');
}
