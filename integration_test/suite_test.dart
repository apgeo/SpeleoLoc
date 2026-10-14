import 'package:flutter_test/flutter_test.dart';

import 'app_smoke_test.dart' as smoke;
import 'flows/scanner_test.dart' as scanner;
import 'flows/sweep_test.dart' as sweep;
import 'support/cell.dart';
import 'support/driver.dart';
import 'support/recorder.dart';
import 'trip_media_fixture_test.dart' as trip_media;

/// One entry point, so a run builds and installs the app once rather than
/// once per file. Which of these flows actually run is decided at run time
/// by the matrix cell the device was given; see `support/cell.dart`.
void main() {
  final binding = AppDriver.ensureInitialized();

  smoke.main();
  sweep.main();
  trip_media.main();
  scanner.main();

  // The result has to outlive the test process. On a device it rides back
  // to the host with the driver's response; the desktop build shares a
  // disk with whoever started it and writes the file itself.
  tearDownAll(() async {
    final cell = await MatrixCell.load();
    final recorder = Recorder.instance
      ..cell = {
        'device': cell.device,
        'language': cell.language,
        'settings': cell.settings,
        'theme': cell.theme,
        'data_origin': cell.dataOrigin,
        'shapes': [for (final s in cell.shapes) s.name],
      };
    binding.reportData = recorder.toJson();
    final out = cell.outDir;
    if (AppDriver.onDesktop && out != null) recorder.writeTo(out);
  });
}
