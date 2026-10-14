// Lays screenshots side by side on one image: the same screen in every
// shape, or in every language, so a reader compares instead of hunting.
//
// A reviewer — a person or an agent — is bad at noticing that the padding
// on screen 37 differs from screen 12, and good at noticing that one of
// six pictures on a row is not like the others. One sheet also costs an
// agent far less to look at than its pictures one by one.
//
// Usage:
//   dart run tool/matrix/contact_sheet.dart <plan.json>
//
// plan.json: [{"out": "sheet.png", "title": "...", "height": 900,
//              "images": [{"path": "a.png", "label": "phone_small"}, ...]}]
import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
      'usage: dart run tool/matrix/contact_sheet.dart <plan.json>',
    );
    exit(64);
  }
  final plan = jsonDecode(File(args.first).readAsStringSync()) as List;
  for (final sheet in plan.cast<Map<String, dynamic>>()) {
    _sheet(sheet);
  }
}

void _sheet(Map<String, dynamic> spec) {
  final height = (spec['height'] as num? ?? 900).toInt();
  const gap = 16;
  const caption = 34;
  final tiles = <(img.Image, String)>[];
  for (final entry in (spec['images'] as List).cast<Map<String, dynamic>>()) {
    final source = img.decodePng(
      File(entry['path'] as String).readAsBytesSync(),
    );
    if (source == null) continue;
    // Every tile the same height, so shapes keep their proportions and a
    // landscape screen is visibly wider than a phone one.
    final tile = img.copyResize(
      source,
      height: height,
      interpolation: img.Interpolation.average,
    );
    tiles.add((tile, '${entry['label'] ?? ''}'));
  }
  if (tiles.isEmpty) return;
  final width =
      tiles.fold<int>(0, (sum, t) => sum + t.$1.width) +
      gap * (tiles.length + 1);
  final sheet = img.Image(width: width, height: height + caption * 2 + gap);
  img.fill(sheet, color: img.ColorRgb8(255, 255, 255));
  img.drawString(
    sheet,
    '${spec['title'] ?? ''}',
    font: img.arial24,
    x: gap,
    y: 4,
    color: img.ColorRgb8(20, 20, 20),
  );
  var x = gap;
  for (final (tile, label) in tiles) {
    img.compositeImage(sheet, tile, dstX: x, dstY: caption);
    img.drawRect(
      sheet,
      x1: x - 1,
      y1: caption - 1,
      x2: x + tile.width,
      y2: caption + tile.height,
      color: img.ColorRgb8(160, 160, 160),
    );
    img.drawString(
      sheet,
      label,
      font: img.arial24,
      x: x,
      y: caption + tile.height + 6,
      color: img.ColorRgb8(60, 60, 60),
    );
    x += tile.width + gap;
  }
  final out = File(spec['out'] as String);
  out.parent.createSync(recursive: true);
  out.writeAsBytesSync(img.encodePng(sheet, level: 6));
}
