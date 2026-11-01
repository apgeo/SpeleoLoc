import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_survey_models.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_file_store.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_fetcher.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_copies.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_fetcher.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_models_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/utils/clock.dart';

import 'contract_fixtures.dart';
import 'scripted_client.dart';
import 'token_source.dart';

/// Survey models down: listed into local-only state, their files fetched
/// into copies under the document's identifier and checked against what was
/// listed, removed with their mappings when the server says so or a full
/// read no longer lists them — and places at stations written once their
/// survey's file is here.
void main() {
  const profile = 'p-1';
  const setId = 'set-1';
  const capabilities = SilexgisCapabilities(
    contractVersion: 1,
    pageSizeMax: 500,
    uploadRowsMax: 500,
    features: <String>['download', 'surveyModels'],
  );
  final baseUri = Uri.parse('https://club.example.org');
  final clock = FakeClock(DateTime.utc(2026, 11, 1, 8));
  const revision = '2026-11-01T12:00:00Z';

  // Invented bytes of the sizes recording 31 lists; never a real survey.
  final loxBytes = List<int>.generate(29, (i) => i);
  final survexBytes = List<int>.generate(32, (i) => 200 - i);

  late Directory base;
  late AppDatabase db;
  late ChangeLogger logger;
  late SilexgisLocalStateRepository localState;
  late SilexgisHeldRowRepository heldRows;
  late SilexgisSurveyModelRepository models;
  late SilexgisFileCopyRepository fileCopies;
  late SilexgisSurveyModelCopies copies;
  late SilexgisSurveyModelApplier applier;

  final caveId = Uuid.v7();
  final placeId = Uuid.v7();
  final loxModel = Uuid.v7();
  final loxDocument = Uuid.v7();
  final survexModel = Uuid.v7();
  final survexDocument = Uuid.v7();
  final withheldModel = Uuid.v7();
  final mappingId = Uuid.v7();

  setUp(() async {
    base = await Directory.systemTemp.createTemp('silexgis_models_down_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger loggerRef;
    final currentUser = CurrentUserService(
      db,
      UserRepository(db, () => loggerRef),
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    logger = loggerRef = ChangeLogger(db, currentUser, clock: clock);
    localState = SilexgisLocalStateRepository(db, clock: clock);
    heldRows = SilexgisHeldRowRepository(db, clock: clock);
    models = SilexgisSurveyModelRepository(db);
    fileCopies = SilexgisFileCopyRepository(db, clock: clock);
    copies = SilexgisSurveyModelCopies(
      db: db,
      logger: logger,
      copies: fileCopies,
      baseDir: () async => base,
      clock: clock,
    );
    applier = SilexgisSurveyModelApplier(
      db: db,
      logger: logger,
      localState: localState,
      heldRows: heldRows,
      models: models,
      copies: copies,
      profileUuid: profile,
      clock: clock,
    );
    await db.into(db.caves).insert(Cave(uuid: caveId, title: 'Invented'));
    await db
        .into(db.cavePlaces)
        .insert(
          CavePlace(
            uuid: placeId,
            title: 'Sump',
            caveUuid: caveId,
            isEntrance: 0,
            isMainEntrance: 0,
          ),
        );
  });
  tearDown(() async {
    await db.close();
    await base.delete(recursive: true);
  });

  /// Recording 31, its placeholders filled with identifiers this device can
  /// hold and fingerprints of the invented bytes.
  Map<String, Object?> recorded31({String cursor = 'models-c1'}) =>
      fillPlaceholders(
            ContractExchange('31-survey-models-first-page').responseBody,
            <String, String>{
              '<lox-model>': loxModel.toString(),
              '<lox-document>': loxDocument.toString(),
              '<lox-version>': 'v-lox-1',
              '<lox-sha256>': sha256.convert(loxBytes).toString(),
              '<survex-model>': survexModel.toString(),
              '<survex-document>': survexDocument.toString(),
              '<survex-version>': 'v-3d-1',
              '<survex-sha256>': sha256.convert(survexBytes).toString(),
              '<withheld-model>': withheldModel.toString(),
              '<cave>': caveId.toString(),
              '<place>': placeId.toString(),
              '<place-station>': mappingId.toString(),
              '<timestamp>': revision,
              '<cursor>': cursor,
            },
          )!
          as Map<String, Object?>;

  SyncSurveyModelsPage page31() => SyncSurveyModelsPage.fromJson(recorded31());

  SyncSurveyModelsPage pageOf({
    List<Map<String, Object?>> models = const <Map<String, Object?>>[],
    List<String> tombstones = const <String>[],
    List<Map<String, Object?>> placeStations = const <Map<String, Object?>>[],
    List<String> placeStationTombstones = const <String>[],
  }) => SyncSurveyModelsPage.fromJson(<String, Object?>{
    'setRevision': 1,
    'models': models,
    'tombstones': <Object?>[
      for (final id in tombstones)
        <String, Object?>{'id': id, 'deleted': true, 'revision': revision},
    ],
    'placeStations': placeStations,
    'placeStationTombstones': <Object?>[
      for (final id in placeStationTombstones)
        <String, Object?>{'id': id, 'deleted': true, 'revision': revision},
    ],
    'nextCursor': 'c',
    'hasMore': false,
  });

  Future<DocumentationFile?> doc(Uuid id) => (db.select(
    db.documentationFiles,
  )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull();

  Future<List<CavePlaceModelStation>> mappings() =>
      db.select(db.cavePlaceModelStations).get();

  /// Holds [document] as a fetched copy, without going over the wire.
  Future<void> holdCopy(Uuid document, Uuid model) async {
    final file = File('${base.path}/documentation_files/m_$document.lox');
    await file.create(recursive: true);
    await file.writeAsBytes(loxBytes);
    await copies.store(
      documentUuid: document,
      caveUuid: caveId,
      title: 'Sistemul.lox',
      relativePath: 'documentation_files/m_$document.lox',
      sizeBytes: loxBytes.length,
      sha256: sha256.convert(loxBytes).toString(),
      versionId: 'v-lox-1',
    );
    await models.recordFetched(profile, model, 'v-lox-1');
  }

  group('the stream', () {
    test('lists the models, drops the withheld one, and leaves a mapping '
        'whose survey is not here yet', () async {
      final applied = await applier.applyPage(page31());

      expect(applied.models, 2);
      expect(applied.withoutPlaceOrSurvey, 1);
      final recorded = await models.readAll(profile);
      expect(recorded.keys, unorderedEquals(<Uuid>[loxModel, survexModel]));
      expect(recorded[loxModel]!.documentId, loxDocument);
      expect(recorded[loxModel]!.isCurrent, isTrue);
      expect(recorded[loxModel]!.fetchedVersionId, isNull);
      expect(await mappings(), isEmpty);
    });

    test(
      'a mapping arrives once its survey is here, with its revision',
      () async {
        await applier.applyPage(page31());
        await holdCopy(loxDocument, loxModel);

        final applied = await applier.applyPage(page31());

        expect(applied.mappingsInserted, 1);
        final mapping = (await mappings()).single;
        expect(mapping.uuid, mappingId);
        expect(mapping.cavePlaceUuid, placeId);
        expect(mapping.caveUuid, caveId);
        expect(mapping.documentationFileUuid, loxDocument);
        expect(mapping.station, '1.12');
        expect(mapping.needsReview, 0);
        final stored = (await localState.readRevisions(profile))[mappingId]!;
        expect(stored.revision, revision);
        expect(stored.entityTable, SilexgisSurveyTables.placeStations);
        // Written as the server's, not as the caver's edit.
        expect(
          await db.select(db.changeLog).get(),
          isEmpty,
          reason: 'server-driven writes are not logged',
        );
      },
    );

    test('a splay end is written as needing review', () async {
      await applier.applyPage(page31());
      await holdCopy(loxDocument, loxModel);
      await applier.applyPage(
        pageOf(
          placeStations: <Map<String, Object?>>[
            <String, Object?>{
              'id': mappingId.toString(),
              'placeId': placeId.toString(),
              'surveyModelId': loxModel.toString(),
              'station': 'A.3',
              'splay': <Object?>[1.5, -2, 0.25],
              'revision': revision,
            },
          ],
        ),
      );
      final mapping = (await mappings()).single;
      expect(mapping.needsReview, 1);
      expect(
        <double?>[mapping.splayEast, mapping.splayNorth, mapping.splayUp],
        <double>[1.5, -2, 0.25],
      );
    });

    test('a mapping the caver edited since is left as they have it', () async {
      await applier.applyPage(page31());
      await holdCopy(loxDocument, loxModel);
      await applier.applyPage(page31());
      await (db.update(
        db.cavePlaceModelStations,
      )..where((t) => t.uuid.equalsValue(mappingId))).write(
        const CavePlaceModelStationsCompanion(
          station: Value('1.13'),
          updatedAt: Value(1),
        ),
      );

      final applied = await applier.applyPage(page31());

      expect(applied.heldBack, 1);
      expect((await mappings()).single.station, '1.13');
    });

    test(
      'a mapping waiting for a reviewer is left as the caver has it',
      () async {
        await applier.applyPage(page31());
        await holdCopy(loxDocument, loxModel);
        await applier.applyPage(page31());
        await heldRows.recordHeld(profile, <SilexgisHeldEntry>[
          SilexgisHeldEntry(
            section: SyncUploadSection.placeStations,
            entityUuid: mappingId,
            entityTable: SilexgisSurveyTables.placeStations,
            reviewId: 'rv-1',
          ),
        ]);
        final applied = await applier.applyPage(
          pageOf(placeStationTombstones: <String>[mappingId.toString()]),
        );
        expect(applied.heldBack, 1);
        expect(await mappings(), hasLength(1));
      },
    );

    test('another local mapping of the place in that survey is kept', () async {
      await applier.applyPage(page31());
      await holdCopy(loxDocument, loxModel);
      final mine = Uuid.v7();
      await db
          .into(db.cavePlaceModelStations)
          .insert(
            CavePlaceModelStationsCompanion.insert(
              uuid: mine,
              cavePlaceUuid: placeId,
              caveUuid: caveId,
              documentationFileUuid: loxDocument,
              station: '1.2',
            ),
          );

      final applied = await applier.applyPage(page31());

      expect(applied.collisions, <Uuid>[mappingId]);
      expect((await mappings()).single.uuid, mine);
    });

    test('a removed mapping goes, and its revision with it', () async {
      await applier.applyPage(page31());
      await holdCopy(loxDocument, loxModel);
      await applier.applyPage(page31());

      final applied = await applier.applyPage(
        pageOf(placeStationTombstones: <String>[mappingId.toString()]),
      );

      expect(applied.mappingsRemoved, 1);
      expect(await mappings(), isEmpty);
      expect((await localState.readRevisions(profile))[mappingId], isNull);
    });

    test('a removed model takes its copy, its mappings and the cave\'s '
        'choice of it', () async {
      await applier.applyPage(page31());
      await holdCopy(loxDocument, loxModel);
      await applier.applyPage(page31());
      await db
          .into(db.caveDefaultSurveyModels)
          .insert(
            CaveDefaultSurveyModelsCompanion.insert(
              uuid: Uuid.v7(),
              caveUuid: caveId,
              documentationFileUuid: loxDocument,
            ),
          );
      final path = (await doc(loxDocument))!.fileName;

      final applied = await applier.applyPage(
        pageOf(tombstones: <String>[loxModel.toString()]),
      );

      expect(applied.modelsRemoved, 1);
      expect(await doc(loxDocument), isNull);
      expect(await File('${base.path}/$path').exists(), isFalse);
      expect(await mappings(), isEmpty);
      expect(await db.select(db.caveDefaultSurveyModels).get(), isEmpty);
      expect(await fileCopies.read(loxDocument), isNull);
      expect((await localState.readRevisions(profile))[mappingId], isNull);
      expect((await models.readAll(profile)).keys, <Uuid>[survexModel]);
    });

    test('the caver\'s own file stays when its model goes', () async {
      final own = File('${base.path}/documentation_files/own.lox');
      await own.create(recursive: true);
      await own.writeAsBytes(loxBytes);
      await db
          .into(db.documentationFiles)
          .insert(
            DocumentationFilesCompanion.insert(
              uuid: loxDocument,
              title: 'mine.lox',
              fileName: 'documentation_files/own.lox',
              fileSize: loxBytes.length,
              fileType: 'survey_model',
            ),
          );
      await applier.applyPage(page31());

      await applier.applyPage(
        pageOf(tombstones: <String>[loxModel.toString()]),
      );

      expect(await doc(loxDocument), isNotNull);
      expect(await own.exists(), isTrue);
    });
  });

  group('the files', () {
    late _Files files;
    late ScriptedClient scripted;

    SilexgisSyncApi syncApi(List<ScriptedResponse> script) {
      scripted = ScriptedClient(script);
      return SilexgisSyncApi(
        SilexgisHttp(
          baseUri: baseUri,
          tokens: FixedTokenSource(),
          client: scripted,
        ),
      );
    }

    SilexgisSurveyModelFetcher fetcher(SilexgisSyncApi api) {
      files = _Files();
      return SilexgisSurveyModelFetcher(
        db: db,
        api: api,
        fetcher: SilexgisFileFetcher(baseUri: baseUri, client: files),
        store: SilexgisDocumentFileStore(baseDir: () async => base),
        models: models,
        copies: copies,
        profileUuid: profile,
      );
    }

    ScriptedResponse address(Uuid document) => ScriptedResponse.json(
      path: SilexgisContract.fileLinksPath,
      json: <String, Object?>{
        'links': <Object?>[
          <String, Object?>{
            'documentId': document.toString(),
            'rendition': 'original',
            'url': '/api/v1/files/f-$document/content?token=t1',
            'expiresAt': '2026-11-01T13:00:00Z',
          },
        ],
        'refused': const <Object?>[],
      },
    );

    ScriptedResponse stream({String cursor = 'models-c1'}) =>
        ScriptedResponse.json(
          path: SilexgisContract.surveyModelsPath(setId),
          json: recorded31(cursor: cursor),
        );

    test('a run reads the stream, fetches both files, and reads it again to '
        'bring the mappings', () async {
      final api = syncApi(<ScriptedResponse>[
        stream(),
        address(loxDocument),
        address(survexDocument),
        stream(cursor: 'models-c2'),
      ]);
      final pending = fetcher(api);
      files
        ..serve('/api/v1/files/f-$loxDocument/content', loxBytes)
        ..serve('/api/v1/files/f-$survexDocument/content', survexBytes);

      final report = await SilexgisSurveyModelsRunner(
        api: api,
        localState: localState,
        applier: applier,
        models: models,
        fetcher: pending,
        profileUuid: profile,
      ).run(setId, capabilities: capabilities);

      expect(scripted.isExhausted, isTrue);
      expect(report.pages, 2);
      expect(report.files.fetched, hasLength(2));
      final lox = (await doc(loxDocument))!;
      expect(lox.fileType, 'survey_model');
      expect(lox.title, 'Sistemul.lox');
      expect(lox.fileName, endsWith('Sistemul.lox'));
      expect(
        await File('${base.path}/${lox.fileName}').readAsBytes(),
        loxBytes,
      );
      expect(lox.fileHash, sha256.convert(loxBytes).toString());
      expect((await doc(survexDocument))!.title, 'Sistemul-3d.3d');
      final link = (await db.select(db.documentationFilesToGeofeatures).get())
          .firstWhere((l) => l.documentationFileUuid == loxDocument);
      expect(link.geofeatureUuid, caveId);
      expect(
        (await fileCopies.read(loxDocument))!.origin,
        SilexgisCopyOrigin.server,
      );
      expect((await mappings()).single.station, '1.12');
      expect(
        (await localState.readStreamCursor(
          profile,
          setId,
          SyncStream.surveyModels,
        )).cursor,
        'models-c2',
      );
    });

    test('bytes other than the ones listed are not stored', () async {
      await applier.applyPage(page31());
      final api = syncApi(<ScriptedResponse>[address(loxDocument)]);
      final pending = fetcher(api);
      files.serve('/api/v1/files/f-$loxDocument/content', survexBytes);

      final report = await pending.fetchPending(only: <Uuid>{loxModel});

      expect(report.failed, 1);
      expect(report.fetched, isEmpty);
      expect(await doc(loxDocument), isNull);
      expect(
        (await models.readAll(profile))[loxModel]!.fetchedVersionId,
        isNull,
      );
    });

    test(
      'a new version replaces the copy\'s bytes, and its mappings stay',
      () async {
        await applier.applyPage(page31());
        await holdCopy(loxDocument, loxModel);
        await applier.applyPage(page31());
        final before = (await doc(loxDocument))!.fileName;
        final changed = List<int>.generate(29, (i) => 7);
        final json = recorded31();
        final lox = ((json['models']! as List).first as Map<String, Object?>)
          ..['versionId'] = 'v-lox-2'
          ..['sha256'] = sha256.convert(changed).toString();
        await applier.applyPage(pageOf(models: <Map<String, Object?>>[lox]));
        final api = syncApi(<ScriptedResponse>[address(loxDocument)]);
        final pending = fetcher(api);
        files.serve('/api/v1/files/f-$loxDocument/content', changed);

        final report = await pending.fetchPending(only: <Uuid>{loxModel});

        expect(report.fetched, <Uuid>[loxModel]);
        final after = (await doc(loxDocument))!;
        expect(after.fileName, isNot(before));
        expect(await File('${base.path}/$before').exists(), isFalse);
        expect(
          await File('${base.path}/${after.fileName}').readAsBytes(),
          changed,
        );
        expect(await mappings(), hasLength(1));
      },
    );

    test('the caver\'s own file is never fetched over', () async {
      await db
          .into(db.documentationFiles)
          .insert(
            DocumentationFilesCompanion.insert(
              uuid: loxDocument,
              title: 'mine.lox',
              fileName: 'documentation_files/own.lox',
              fileSize: loxBytes.length,
              fileType: 'survey_model',
            ).copyWith(fileHash: Value(sha256.convert(loxBytes).toString())),
          );
      await applier.applyPage(page31());
      final pending = fetcher(syncApi(<ScriptedResponse>[]));

      final report = await pending.fetchPending(only: <Uuid>{loxModel});

      // Same bytes: counted as here, and nothing went over the wire.
      expect(report.fetched, <Uuid>[loxModel]);
      expect(scripted.sent, isEmpty);
      expect((await doc(loxDocument))!.title, 'mine.lox');
    });

    test(
      'a read from the beginning drops the models it no longer lists',
      () async {
        await applier.applyPage(page31());
        await holdCopy(loxDocument, loxModel);
        final json = recorded31()
          ..['models'] = <Object?>[(recorded31()['models']! as List).last];
        final api = syncApi(<ScriptedResponse>[
          ScriptedResponse.json(
            path: SilexgisContract.surveyModelsPath(setId),
            json: json,
          ),
        ]);

        final report = await SilexgisSurveyModelsRunner(
          api: api,
          localState: localState,
          applier: applier,
          models: models,
          profileUuid: profile,
        ).run(setId, capabilities: capabilities, fromBeginning: true);

        expect(report.applied.modelsRemoved, 1);
        expect(await doc(loxDocument), isNull);
        expect((await models.readAll(profile)).keys, <Uuid>[survexModel]);
      },
    );

    test('without fetching, the models wait to be asked for', () async {
      final api = syncApi(<ScriptedResponse>[stream()]);
      await SilexgisSurveyModelsRunner(
        api: api,
        localState: localState,
        applier: applier,
        models: models,
        profileUuid: profile,
      ).run(setId, capabilities: capabilities);

      final waiting = await models.notHeld(caveId);
      expect(
        waiting.map((m) => m.documentId),
        unorderedEquals(<Uuid>[loxDocument, survexDocument]),
      );
      expect(await models.currentModelDocuments(caveId), <Uuid>{loxDocument});
    });
  });
}

/// Serves invented file bytes at fixed paths.
class _Files extends http.BaseClient {
  final Map<String, List<int>> _served = <String, List<int>>{};

  void serve(String path, List<int> bytes) => _served[path] = bytes;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = _served[request.url.path];
    if (bytes == null) {
      return http.StreamedResponse(const Stream<List<int>>.empty(), 404);
    }
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      200,
      contentLength: bytes.length,
      headers: const <String, String>{
        'content-type': 'application/octet-stream',
      },
      request: request,
    );
  }
}
