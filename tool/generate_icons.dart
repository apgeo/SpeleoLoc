// Run with: dart run tool/generate_icons.dart
// Generates Android mipmap and iOS AppIcon/LaunchImage variants from
// assets/icons/speleo_loc_5.png using the `image` package (already in pubspec).

import 'dart:io';
import 'package:image/image.dart' as img;

final srcPath = 'assets/icons/speleo_loc_5.png';

void main() {
  final srcFile = File(srcPath);
  if (!srcFile.existsSync()) {
    stderr.writeln('Source file not found: $srcPath');
    exit(2);
  }

  final src = img.decodeImage(srcFile.readAsBytesSync());
  if (src == null) {
    stderr.writeln('Failed to decode image: $srcPath');
    exit(3);
  }

  // Android mipmap sizes (square width in px)
  final androidTargets = {
    'android/app/src/main/res/mipmap-mdpi/speleo_loc_1.png': 48,
    'android/app/src/main/res/mipmap-hdpi/speleo_loc_1.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/speleo_loc_1.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/speleo_loc_1.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/speleo_loc_1.png': 192,
  };

  // iOS AppIcon / LaunchImage: provide @1x, @2x, @3x copies (will be used by Xcode)
  final iosTargets = {
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/speleo_loc_1.png': 1024,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/speleo_loc_1@2x.png': 2048,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/speleo_loc_1@3x.png': 3072,
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/speleo_loc_1.png': 1200,
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/speleo_loc_1@2x.png': 2400,
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/speleo_loc_1@3x.png': 3600,
  };

  _generate(androidTargets, src);
  _generate(iosTargets, src);

  stdout.writeln('Icon generation finished.');
}

void _generate(Map<String, int> targets, img.Image src) {
  targets.forEach((path, size) {
    final outDir = Directory(path).parent;
    if (!outDir.existsSync()) outDir.createSync(recursive: true);

    // Resize preserving aspect ratio, fit to square `size`x`size`
    final int cropSize = src.width < src.height ? src.width : src.height;
    final square = img.copyResizeCropSquare(src, size: cropSize);
    final resized = img.copyResize(square, width: size, height: size);
    final bytes = img.encodePng(resized);
    File(path).writeAsBytesSync(bytes);
    stdout.writeln('Wrote $path (${size}x$size)');
  });
}
