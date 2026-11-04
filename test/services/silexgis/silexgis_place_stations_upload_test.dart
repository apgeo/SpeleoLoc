import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_survey_models.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_document_updater.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_paged_stream_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_place_stations_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_builder.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_runner.dart';
import 'package:speleoloc/utils/clock.dart';

import 'scripted_client.dart';
import 'token_source.dart';

/// Places at stations up: which go, how their survey is named, which wait,
/// and what is kept of each answer.
void main() {
  const profile = 'p-1';
  const setId = 'set-1';
  const capabilities = SilexgisCapabilities(
    contractVersion: 1,
    pageSizeMax: 500,
    uploadRowsMax: 500,
    features: <String>['download', 'upload', 'surveyModels'],
  );
  final clock = FakeClock(DateTime.utc(2026, 11, 1, 8));
  final uploadPath = SilexgisContract.uploadPath(setId);

  late AppDatabase db;
  late SilexgisLocalStateRepository localState;
  late SilexgisHeldRowRepository heldRows;
  late SilexgisSurveyModelRepository models;

  final caveId = Uuid.v7();
  final placeId = Uuid.v7();
  final serverModel = Uuid.v7();
  final serverModelDoc = Uuid.v7();
  final uploadedDoc = Uuid.v7();
  final ownDoc = Uuid.v7();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localState = SilexgisLocalStateRepository(db, clock: clock);
    heldRows = SilexgisHeldRowRepository(db, clock: clock);
    models = SilexgisSurveyModelRepository(db);

    final t0 = clock.nowMs();
    await db
        .into(db.caves)
        .insert(Cave(uuid: caveId, title: 'Invented', updatedAt: t0));
    await db
        .into(db.cavePlaces)
        .insert(
          CavePlace(
            uuid: placeId,
            title: 'Sump',
            caveUuid: caveId,
            isEntrance: 0,
            isMainEntrance: 0,
            updatedAt: t0,
          ),
        );
    for (final doc in <Uuid>[serverModelDoc, uploadedDoc, ownDoc]) {
      await db
          .into(db.documentationFiles)
          .insert(
            DocumentationFilesCompanion.insert(
              uuid: doc,
              title: 'survey.lox',
              fileName: 'documentation_files/$doc.lox',
              fileSize: 1,
              fileType: 'survey_model',
            ).copyWith(updatedAt: Value(t0)),
          );
    }
    for (final (id, table) in <(Uuid, String)>[
      (caveId, 'caves'),
      (placeId, 'cave_places'),
      (uploadedDoc, SilexgisHeldDocumentUpdater.entityTable),
    ]) {
      await localState.writeRevision(
        profile,
        id,
        entityTable: table,
        wireKind: table == SilexgisHeldDocumentUpdater.entityTable
            ? SilexgisHeldDocumentUpdater.wireKind
            : null,
        revision: '2026-10-31T10:00:00Z',
        localUpdatedAt: t0,
      );
    }
    await models.record(
      profile,
      serverModel,
      caveId,
      serverModelDoc,
      const SyncSurveyModel(
        id: 'unused',
        caveId: 'unused',
        documentId: 'unused',
        format: 'lox',
      ),
    );
  });
  tearDown(() => db.close());

  Future<Uuid> mapping(Uuid survey, {String station = '1.12'}) async {
    final id = Uuid.v7();
    await db
        .into(db.cavePlaceModelStations)
        .insert(
          CavePlaceModelStationsCompanion.insert(
            uuid: id,
            cavePlaceUuid: placeId,
            caveUuid: caveId,
            documentationFileUuid: survey,
            station: station,
          ).copyWith(updatedAt: Value(clock.nowMs())),
        );
    return id;
  }

  ScriptedResponse answer(List<Map<String, Object?>> stations) =>
      ScriptedResponse.json(
        path: uploadPath,
        json: <String, Object?>{
          'batchId': 'b',
          'importBatchId': 'i',
          'replayed': false,
          'written': 0,
          'refused': 0,
          'rows': const <Object?>[],
          'conflicts': const <Object?>[],
          'duplicates': const <Object?>[],
          'placeStations': stations,
        },
      );

  Map<String, Object?> verdict(Uuid id, String status, {String? code}) =>
      <String, Object?>{
        'id': id.toString(),
        'status': status,
        'revision': code == null ? '2026-11-01T08:00:00Z' : null,
        'code': code,
        'detail': null,
      };

  Future<SilexgisUploadReport> run(ScriptedClient client) {
    final http = SilexgisHttp(
      baseUri: Uri.parse('https://club.example.org'),
      tokens: FixedTokenSource(),
      client: client,
    );
    return SilexgisUploadRunner(
      api: SilexgisSyncApi(http),
      builder: SilexgisUploadBuilder(
        db: db,
        localState: localState,
        heldRows: heldRows,
        profileUuid: profile,
      ),
      localState: localState,
      heldRows: heldRows,
      profileUuid: profile,
      parts: [
        SilexgisPlaceStationsUploadPart(
          db: db,
          localState: localState,
          heldRows: heldRows,
          models: models,
          surveyModelsCursor: SilexgisStreamCursorStore(
            localState: localState,
            profileUuid: profile,
            setId: setId,
            stream: SyncStream.surveyModels,
          ),
          profileUuid: profile,
        ),
      ],
    ).run(setId, capabilities: capabilities);
  }

  List<Map<String, Object?>> sent(
    ScriptedClient client,
  ) => <Map<String, Object?>>[
    for (final r in client.sent.where((r) => r.url.path == uploadPath))
      for (final item
          in (r.jsonBody[SyncUploadSection.placeStations.wireName] as List? ??
              const []))
        item as Map<String, Object?>,
  ];

  test('a mapping on a server model names the model, and is agreed once '
      'written', () async {
    final id = await mapping(serverModelDoc);
    final client = ScriptedClient(<ScriptedResponse>[
      answer(<Map<String, Object?>>[verdict(id, 'created')]),
    ]);

    await run(client);

    final item = sent(client).single;
    expect(item['surveyModelId'], serverModel.toString());
    expect(item.containsKey('documentId'), isFalse);
    expect(item['placeId'], placeId.toString());
    expect(item['station'], '1.12');
    final stored = (await localState.readRevisions(profile))[id]!;
    expect(stored.entityTable, SilexgisSurveyTables.placeStations);
    expect(stored.revision, '2026-11-01T08:00:00Z');

    // Agreed now: nothing goes on the next run.
    final again = ScriptedClient(<ScriptedResponse>[]);
    await run(again);
    expect(sent(again), isEmpty);
  });

  test('a mapping on a survey file this device uploaded names the document, '
      'with its splay', () async {
    final id = await mapping(uploadedDoc, station: 'A.3');
    await (db.update(
      db.cavePlaceModelStations,
    )..where((t) => t.uuid.equalsValue(id))).write(
      const CavePlaceModelStationsCompanion(
        splayEast: Value(1.5),
        splayNorth: Value(-2),
        splayUp: Value(0.25),
      ),
    );
    final client = ScriptedClient(<ScriptedResponse>[
      answer(<Map<String, Object?>>[verdict(id, 'created')]),
    ]);

    await run(client);

    final item = sent(client).single;
    expect(item['documentId'], uploadedDoc.toString());
    expect(item.containsKey('surveyModelId'), isFalse);
    expect(item['splay'], <double>[1.5, -2, 0.25]);
  });

  test('a mapping on a survey file the server does not hold waits', () async {
    await mapping(ownDoc);
    final client = ScriptedClient(<ScriptedResponse>[]);

    await run(client);

    expect(client.sent, isEmpty);
  });

  test('a mapping removed here goes up as a removal', () async {
    final id = Uuid.v7();
    await localState.writeRevision(
      profile,
      id,
      entityTable: SilexgisSurveyTables.placeStations,
      revision: 'r-1',
      localUpdatedAt: 1,
    );
    final client = ScriptedClient(<ScriptedResponse>[
      answer(<Map<String, Object?>>[verdict(id, 'deleted')]),
    ]);

    await run(client);

    expect(sent(client).single, <String, Object?>{
      'id': id.toString(),
      'baseRevision': 'r-1',
      'deleted': true,
    });
    expect((await localState.readRevisions(profile))[id], isNull);
  });

  test(
    'a place unmapped and mapped again goes down before it goes up',
    () async {
      // One live mapping per place on a survey: the new one sent first would
      // be refused as a second mapping of the place.
      final oldMapping = Uuid.v7();
      await localState.writeRevision(
        profile,
        oldMapping,
        entityTable: SilexgisSurveyTables.placeStations,
        revision: 'r-1',
        localUpdatedAt: 1,
      );
      final newMapping = await mapping(serverModelDoc, station: '1.13');
      final client = ScriptedClient(<ScriptedResponse>[
        answer(<Map<String, Object?>>[
          verdict(oldMapping, 'deleted'),
          verdict(newMapping, 'created'),
        ]),
      ]);

      await run(client);

      expect(sent(client).map((item) => item['id']), <String>[
        oldMapping.toString(),
        newMapping.toString(),
      ]);
    },
  );

  test('place_station_exists is kept for the caver and has the stream read '
      'again from the beginning', () async {
    final id = await mapping(serverModelDoc);
    await localState.writeStreamCursor(
      profile,
      setId,
      SyncStream.surveyModels,
      cursor: 'models-c9',
      setRevision: 1,
    );
    final client = ScriptedClient(<ScriptedResponse>[
      answer(<Map<String, Object?>>[
        verdict(id, 'rejected', code: SilexgisCodes.placeStationExists),
      ]),
    ]);

    final report = await run(client);

    expect(
      report.refusals.single.result.code,
      SilexgisCodes.placeStationExists,
    );
    expect(
      (await localState.readStreamCursor(
        profile,
        setId,
        SyncStream.surveyModels,
      )).cursor,
      isNull,
    );
    final held = (await heldRows.readSection(
      profile,
      SyncUploadSection.placeStations,
    ))[id]!;
    expect(held.code, SilexgisCodes.placeStationExists);

    // Not sent again while it waits for the caver.
    final again = ScriptedClient(<ScriptedResponse>[]);
    await run(again);
    expect(sent(again), isEmpty);
  });

  test('survey_not_found is told and nothing is kept', () async {
    final id = await mapping(serverModelDoc);
    final client = ScriptedClient(<ScriptedResponse>[
      answer(<Map<String, Object?>>[
        verdict(id, 'rejected', code: SilexgisCodes.surveyNotFound),
      ]),
    ]);

    final report = await run(client);

    expect(report.refusals.single.result.code, SilexgisCodes.surveyNotFound);
    expect((await localState.readRevisions(profile))[id], isNull);
  });
}
