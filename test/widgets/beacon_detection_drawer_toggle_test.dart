import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/beacon/beacon_detection_service.dart';
import 'package:speleoloc/widgets/beacon_detection_drawer_toggle.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

void main() {
  testWidgets('a failed switch-off reports it and leaves the switch usable', (
    tester,
  ) async {
    // Reading the stored config is the first thing switching off does.
    final service = BeaconDetectionService.forTesting(
      featureEnabled: true,
      loadConfig: () async => throw StateError('database is locked'),
    );
    service.enabledListenable.value = true;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Stack(
          children: [
            SizedBox.expand(child: child),
            const AppToastHost(),
          ],
        ),
        home: Scaffold(body: BeaconDetectionDrawerToggle(service: service)),
      ),
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.textContaining('database is locked'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNotNull);
    // Let the toast expire so no timer outlives the test.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });
}
