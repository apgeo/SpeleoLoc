import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/widgets/add_cave_place_popup.dart';

import '../support/cave_repository_fixture.dart';

void main() {
  late AppDatabase db;

  // PermissionStatus indexes: 0 denied, 1 granted, 4 permanently denied.
  late int cameraStatus;
  var settingsOpened = false;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.steenbakker.mobile_scanner/scanner/method'),
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (call) async {
        switch (call.method) {
          case 'checkPermissionStatus':
            return cameraStatus;
          case 'requestPermissions':
            return {for (final p in call.arguments as List) p: cameraStatus};
          case 'openAppSettings':
            settingsOpened = true;
            return true;
        }
        return null;
      },
    );
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cameraStatus = 1;
    settingsOpened = false;
  });
  tearDown(() => db.close());

  Future<void> openPopup(WidgetTester tester) async {
    final caves = await buildCaveRepository(db);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        caveRepositoryProvider.overrideWithValue(caves),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AddCavePlacePopup(caveUuid: Uuid.v7()),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a scanned code lands in the field and the dialog stays open', (
    tester,
  ) async {
    await openPopup(tester);
    await tester.tap(find.byIcon(Icons.qr_code_scanner));
    await tester.pumpAndSettle();

    tester.widget<MobileScanner>(find.byType(MobileScanner)).onDetect!(
      const BarcodeCapture(barcodes: [Barcode(rawValue: 'x1')]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AddCavePlacePopup), findsOneWidget);
    expect(find.text('x1'), findsOneWidget);
  });

  testWidgets('a permanently denied camera explains and offers the settings, '
      'not the scanner', (tester) async {
    cameraStatus = 4;
    await openPopup(tester);
    await tester.tap(find.byIcon(Icons.qr_code_scanner));
    await tester.pumpAndSettle();

    expect(find.byType(MobileScanner), findsNothing);
    expect(find.text('camera_permission_required'), findsOneWidget);

    await tester.tap(find.text('open_settings'));
    await tester.pumpAndSettle();

    expect(settingsOpened, isTrue);
    expect(find.text('camera_permission_required'), findsNothing);
    expect(find.byType(AddCavePlacePopup), findsOneWidget);
  });
}
