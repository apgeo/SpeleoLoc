import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/model_viewer_providers.dart';
import 'package:speleoloc/screens/cave_model/server_models_sheet.dart';
import 'package:speleoloc/services/cave_model/current_survey_models.dart';

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

  Future<Uuid?> open(WidgetTester tester, _Fetcher fetcher) async {
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
}
