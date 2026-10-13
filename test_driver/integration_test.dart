import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver for `flutter drive --driver test_driver/integration_test.dart`.
///
/// Its only job is to receive screenshots the test asks for and put them on
/// disk, where a person — or an agent iterating on a change — can look at
/// them. Screenshots land in `build/screenshots/`, which is git-ignored.
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final file = File('build/screenshots/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      stdout.writeln('screenshot: ${file.path} (${bytes.length} bytes)');
      return true;
    },
  );
}
