import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/beacon/beacon_scan_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_beacon');
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  for (final check in [true, false]) {
    test('asks for When-In-Use location before initializing '
        '(checkPermissions: $check)', () async {
      await BeaconScanHelper.initializeScanning(checkPermissions: check);

      expect(calls.map((c) => c.method), [
        'setLocationAuthorizationTypeDefault',
        check ? 'initializeAndCheck' : 'initialize',
      ]);
      expect(calls.first.arguments, 'WHEN_IN_USE');
    });
  }
}
