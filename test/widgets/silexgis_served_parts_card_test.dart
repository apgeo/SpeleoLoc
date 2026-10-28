import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/screens/settings/silexgis_served_parts_card.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';

import '../support/layout_harness.dart';

/// One line per optional part: whether the installation offered it on the
/// last run, and what this device does with it.
void main() {
  useLayoutHarness();

  const profile = SilexgisProfile(
    profileUuid: 'p-1',
    displayName: 'Club server',
    baseUrl: 'https://club.example.org',
  );

  Future<void> pump(WidgetTester tester, SilexgisProfile profile) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SilexgisServedPartsCard(profile: profile),
            ),
          ),
        ),
      );

  testWidgets('before any run nothing is claimed', (tester) async {
    await pump(tester, profile);

    expect(find.text('Not known until the first sync.'), findsOneWidget);
    for (final part in <String>[
      'Photos and documents',
      'Sending photos and documents',
      'Trips',
      'Raster maps',
      'Review',
      'People',
    ]) {
      expect(find.text(part), findsOneWidget);
    }
    expect(find.textContaining('Offered'), findsNothing);
    expect(find.byIcon(Icons.help_outline), findsNWidgets(6));
  });

  testWidgets('after a run each part says whether it was offered', (
    tester,
  ) async {
    await pump(
      tester,
      profile.copyWith(
        servedFeatures: <String>['documents', 'documentUpload', 'trips'],
      ),
    );

    expect(
      find.text(
        'As of the last sync, and what this device does with each part.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_circle_outline), findsNWidgets(3));
    expect(find.byIcon(Icons.remove_circle_outline), findsNWidgets(3));
    expect(
      find.text(
        'Offered · Files go over Wi-Fi; away from it, you are asked first.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Not offered · Raster maps stay on this device.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Not offered · Phone users are not described, and no caver can be '
        'chosen.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('sending files says what this device\'s settings make of it', (
    tester,
  ) async {
    await pump(
      tester,
      profile.copyWith(
        servedFeatures: <String>['documentUpload'],
        sendsFiles: false,
      ),
    );

    expect(
      find.text('Offered · Switched off on this device: files stay here.'),
      findsOneWidget,
    );
  });
}
