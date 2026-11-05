import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/model_viewer_providers.dart';
import 'package:speleoloc/screens/cave_model/server_models_sheet.dart';
import 'package:speleoloc/services/cave_model/current_survey_models.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

class _Fetcher implements ServerSurveyModelFetcher {
  _Fetcher(this.outcome);

  final ServerModelFetchOutcome outcome;
  final asked = <Uuid>[];

  @override
  Future<ServerModelFetchOutcome> fetch(ServerSurveyModel model) async {
    asked.add(model.modelId);
    return outcome;
  }
}

class _Throwing implements ServerSurveyModelFetcher {
  @override
  Future<ServerModelFetchOutcome> fetch(ServerSurveyModel model) =>
      throw const FileSystemException('disk full');
}

/// The list of a cave's models still on the server: one tap fetches a model,
/// and the sheet hands back its document so the viewer can open it.
void main() {
  final cave = Uuid.v7();
  final model = ServerSurveyModel(
    profileUuid: 'p-1',
    modelId: Uuid.v7(),
    documentId: Uuid.v7(),
    name: 'Invented plot',
    format: 'lox',
    sizeBytes: 2048,
    isCurrent: true,
  );

  Future<Uuid?> open(
    WidgetTester tester,
    ServerSurveyModelFetcher fetcher, {
    bool toasts = false,
  }) async {
    Uuid? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caveServerModelsProvider(
            cave,
          ).overrideWith((ref) async => <ServerSurveyModel>[model]),
          serverSurveyModelFetcherProvider.overrideWithValue(fetcher),
        ],
        child: MaterialApp(
          builder: (context, child) => Stack(
            children: [
              SizedBox.expand(child: child),
              if (toasts) const AppToastHost(),
            ],
          ),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await showServerModelsSheet(context, cave),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Invented plot'), findsOneWidget);
    expect(find.textContaining('2.0 KB'), findsOneWidget);
    await tester.tap(find.text('Invented plot'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('a fetched model is handed back by its document', (tester) async {
    final fetcher = _Fetcher(ServerModelFetchOutcome.fetched);
    expect(await open(tester, fetcher), model.documentId);
    expect(fetcher.asked, <Uuid>[model.modelId]);
  });

  testWidgets('a refused model keeps the sheet open', (tester) async {
    final fetcher = _Fetcher(ServerModelFetchOutcome.refused);
    expect(await open(tester, fetcher), isNull);
    expect(find.text('Invented plot'), findsOneWidget);
  });

  testWidgets('no connection says so and leaves the tiles usable', (
    tester,
  ) async {
    final fetcher = _Fetcher(ServerModelFetchOutcome.offline);
    expect(await open(tester, fetcher, toasts: true), isNull);
    expect(find.text('model_server_offline'), findsOneWidget);

    final tile = tester.widget<ListTile>(find.byType(ListTile).last);
    expect(tile.enabled, isTrue);
    // Let the toasts expire so no timer outlives the test.
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('a fetch that throws does not lock the sheet', (tester) async {
    expect(await open(tester, _Throwing(), toasts: true), isNull);
    expect(find.text('model_server_failed'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    final tile = tester.widget<ListTile>(find.byType(ListTile).last);
    expect(tile.enabled, isTrue);
    await tester.pump(const Duration(seconds: 6));
  });
}
