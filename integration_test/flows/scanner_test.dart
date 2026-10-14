import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/screens/scanner_page.dart';

import '../support/cell.dart';
import '../support/flow.dart';

/// The code the emulator's back camera shows: the matrix boots emulators
/// with `-camera-back imagefile:` pointing at a picture of this label,
/// made by `generate_test_media.dart --camera`.
const _labelOnCamera = 'a1';

/// The live scanner, end to end on a device: camera permission, the camera
/// stream, the barcode library decoding a frame, and the page handing the
/// code back. Before the emulator could be given a picture to show, this
/// was listed as something only a real phone could check.
void main() {
  flow('scanner_live_qr', needs: {Need.camera}, (driver) async {
    await driver.launch();
    String? scanned;
    driver.push(ScannerPage(onScan: (code) => scanned = code));
    await driver.pumpUntil(
      () => scanned != null,
      reason: 'the scanner to read the label the camera shows',
      timeout: const Duration(seconds: 90),
    );
    expect(scanned, _labelOnCamera);
    await driver.settle(timeout: const Duration(seconds: 5));
    expect(driver.tester.takeException(), isNull);
  });
}
