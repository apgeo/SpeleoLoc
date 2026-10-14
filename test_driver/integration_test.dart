import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver for `flutter drive --driver test_driver/integration_test.dart`.
///
/// Receives what a run on a device produced and puts it on disk, where a
/// person — or an agent iterating on a change — can read it: the
/// screenshots, the semantics tree taken with each one, and `result.json`
/// with every flow's outcome and what the sweep found.
///
/// Everything lands in `SPELEO_OUT_DIR`, default `build/screenshots/`, so
/// several devices can be driven at once without writing over each other.
Future<void> main() async {
  final out = Platform.environment['SPELEO_OUT_DIR'] ?? 'build/screenshots';
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final file = File('$out/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
    // Written on failure too: a failed run is the one whose details matter.
    writeResponseOnFailure: true,
    responseDataCallback: (data) async {
      if (data == null) return;
      final report = Map<String, dynamic>.of(data);
      // The screenshots were already written one by one above.
      report.remove('screenshots');
      final semantics = report.remove('semantics');
      if (semantics is Map) {
        for (final entry in semantics.entries) {
          final file = File('$out/${entry.key}.semantics.txt');
          await file.create(recursive: true);
          await file.writeAsString('${entry.value}');
        }
      }
      final file = File('$out/result.json');
      await file.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent(' ').convert(report),
      );
      stdout.writeln('result: ${file.path}');
    },
  );
}
