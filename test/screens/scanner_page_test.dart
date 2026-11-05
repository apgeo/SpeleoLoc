import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:speleoloc/screens/scanner_page.dart';

/// A frame that is still being analysed when the camera is told to stop
/// delivers one more detection, and one scan must not become two lookups or
/// two popped routes.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.steenbakker.mobile_scanner/scanner/method'),
          (call) async => null,
        );
  });

  BarcodeCapture capture(String value) =>
      BarcodeCapture(barcodes: [Barcode(rawValue: value)]);

  Future<void> openScanner(
    WidgetTester tester,
    void Function(String) onScan,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => ScannerPage(onScan: onScan)),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a second detection after the first is ignored', (tester) async {
    final scanned = <String>[];
    await openScanner(tester, scanned.add);

    final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
    scanner.onDetect!(capture('a1'));
    scanner.onDetect!(capture('a1'));
    await tester.pumpAndSettle();

    expect(scanned, ['a1']);
  });

  testWidgets('a second detection does not pop the page underneath', (
    tester,
  ) async {
    await openScanner(tester, (_) {});

    final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
    scanner.onDetect!(capture('a1'));
    scanner.onDetect!(capture('a1'));
    await tester.pumpAndSettle();

    expect(find.byType(ScannerPage), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('a detection during the back animation is ignored', (
    tester,
  ) async {
    final scanned = <String>[];
    await openScanner(tester, scanned.add);

    final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    scanner.onDetect!(capture('a1'));
    await tester.pumpAndSettle();

    expect(scanned, isEmpty);
    expect(find.byType(ScannerPage), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
