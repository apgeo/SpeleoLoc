import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/settings/silexgis_decision_card.dart';
import 'package:speleoloc/services/silexgis/model/sync_review.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_decision.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';

import '../support/layout_harness.dart';

/// Each item waiting for the caver offers exactly the choices that apply to
/// it, named for what they do.
void main() {
  useLayoutHarness();

  SilexgisHeldItem held(
    SyncUploadSection section, {
    SyncReviewOutcome? outcome,
    bool conflict = false,
    bool deletedOnServer = false,
    bool refused = false,
    String? code,
    Map<String, Object?>? current,
  }) => SilexgisHeldItem(
    section: section,
    entityUuid: Uuid.v7(),
    entityTable: 'invented',
    reviewId: conflict || deletedOnServer || refused ? '' : 'review-1',
    outcome: outcome,
    isConflict: conflict,
    isDeletedOnServer: deletedOnServer,
    isRefused: refused,
    code: code,
    current: current,
  );

  Future<List<String>> pump(
    WidgetTester tester,
    SilexgisDecision decision,
  ) async {
    final pressed = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SilexgisDecisionCard(
            decision: decision,
            enabled: true,
            onUseServer: () => pressed.add('server'),
            onKeepMine: () => pressed.add('keep'),
            onSendMine: () => pressed.add('send'),
            onSendAgain: () => pressed.add('again'),
            onDelete: () => pressed.add('delete'),
          ),
        ),
      ),
    );
    return pressed;
  }

  testWidgets('a recording in conflict is re-read, or kept', (tester) async {
    final pressed = await pump(
      tester,
      SilexgisDecision(
        held: held(
          SyncUploadSection.tripRecordings,
          conflict: true,
          code: 'sync.conflict',
        ),
        isNew: false,
        title: 'Invented trip',
      ),
    );

    expect(find.text('Invented trip'), findsOneWidget);
    expect(find.text('Trip recording'), findsOneWidget);
    expect(find.text('Changed on the server as well'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
    // No server row came back, so there is no revision to send over.
    expect(find.text('Send mine anyway'), findsNothing);
    await tester.tap(find.text('Re-read from the server'));
    await tester.tap(find.text('Keep mine, don\'t send'));
    expect(pressed, <String>['server', 'keep']);
  });

  testWidgets('a feature in conflict with the server\'s row goes back to it', (
    tester,
  ) async {
    await pump(
      tester,
      SilexgisDecision(
        held: held(
          SyncUploadSection.rows,
          conflict: true,
          code: 'sync.conflict',
          current: const <String, Object?>{'name': 'Server name'},
        ),
        isNew: false,
        title: 'Mine',
      ),
    );

    expect(find.text('Use the server\'s version'), findsOneWidget);
    expect(find.text('Re-read from the server'), findsNothing);
  });

  testWidgets('a feature in conflict can also be sent over the server\'s row', (
    tester,
  ) async {
    final pressed = await pump(
      tester,
      SilexgisDecision(
        held: held(
          SyncUploadSection.rows,
          conflict: true,
          code: 'sync.conflict',
          current: const <String, Object?>{
            'name': 'Server name',
            'updatedAt': '2026-10-28T07:00:00Z',
          },
        ),
        isNew: false,
        title: 'Mine',
        canSendMineAnyway: true,
      ),
    );

    await tester.tap(find.text('Send mine anyway'));
    expect(pressed, <String>['send']);
  });

  testWidgets('a pin another marks the place of is removed, not deleted', (
    tester,
  ) async {
    final pressed = await pump(
      tester,
      SilexgisDecision(
        held: held(
          SyncUploadSection.rasterPins,
          conflict: true,
          code: 'sync.pin_exists',
        ),
        isNew: true,
        title: 'Plan · Sump',
      ),
    );

    expect(
      find.text('Another point marks this place on the server\'s map'),
      findsOneWidget,
    );
    expect(find.text('Delete'), findsNothing);
    expect(find.text('Re-read from the server'), findsNothing);
    await tester.tap(find.text('Remove my point'));
    expect(pressed, <String>['delete']);
  });

  testWidgets('a turned-down new document can be deleted', (tester) async {
    await pump(
      tester,
      SilexgisDecision(
        held: held(
          SyncUploadSection.documents,
          outcome: SyncReviewOutcome.rejected,
        ),
        isNew: true,
        title: 'Invented photo',
      ),
    );

    expect(find.text('Photo or document'), findsOneWidget);
    expect(
      find.text('Turned down · New here; the server never had it'),
      findsOneWidget,
    );
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Use the server\'s version'), findsNothing);
    expect(find.text('Re-read from the server'), findsNothing);
  });

  testWidgets('an edit the server refused outright shows the server\'s code', (
    tester,
  ) async {
    await pump(
      tester,
      SilexgisDecision(
        held: held(
          SyncUploadSection.rows,
          refused: true,
          code: 'sync.row_forbidden',
        ),
        isNew: false,
        title: 'Invented place',
      ),
    );

    expect(find.text('Could not be written'), findsOneWidget);
    expect(find.text('sync.row_forbidden'), findsOneWidget);
    expect(find.text('Re-read from the server'), findsOneWidget);
    expect(find.text('Keep mine, don\'t send'), findsOneWidget);
  });

  testWidgets('a cave removed on the server with work of the caver\'s in it is '
      'deleted here too, or kept', (tester) async {
    final pressed = await pump(
      tester,
      SilexgisDecision(
        held: held(SyncUploadSection.rows, deletedOnServer: true),
        // The device holds no revision for it any more.
        isNew: true,
        title: 'Invented cave',
        canSendAgainAsNew: true,
      ),
    );

    expect(
      find.text('Deleted on the server, but holds work of yours it never had'),
      findsOneWidget,
    );
    expect(find.text('Use the server\'s version'), findsNothing);
    expect(find.text('Re-read from the server'), findsNothing);
    await tester.tap(find.text('Delete'));
    await tester.tap(find.text('Keep mine, don\'t send'));
    await tester.tap(find.text('Send again as new'));
    expect(pressed, <String>['delete', 'keep', 'again']);
  });

  testWidgets('a cave removed on the server and kept here no longer offers to '
      'keep it', (tester) async {
    final pressed = await pump(
      tester,
      SilexgisDecision(
        held: SilexgisHeldItem(
          section: SyncUploadSection.rows,
          entityUuid: Uuid.v7(),
          entityTable: 'caves',
          reviewId: '',
          isDeletedOnServer: true,
          keptAt: 1,
        ),
        isNew: true,
        title: 'Invented cave',
        canSendAgainAsNew: true,
      ),
    );

    expect(find.textContaining('Kept on this device only'), findsOneWidget);
    expect(find.text('Keep mine, don\'t send'), findsNothing);
    await tester.tap(find.text('Send again as new'));
    await tester.tap(find.text('Delete'));
    expect(pressed, <String>['again', 'delete']);
  });
}
