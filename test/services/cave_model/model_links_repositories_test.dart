import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_model/cave_default_model_repository.dart';
import 'package:speleoloc/services/cave_model/model_splay_offset.dart';
import 'package:speleoloc/services/cave_model/place_station_mapping_repository.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/documentation_repository.dart';
import 'package:speleoloc/services/user_repository.dart';

/// Mappings of places to model stations and a cave's default model: saved,
/// replaced, removed with a tombstone, and gone with the place, the cave or
/// the model document they hang on.
void main() {
  late AppDatabase db;
  late PlaceStationMappingRepository mappings;
  late CaveDefaultModelRepository defaults;
  late CaveRepository caves;
  late CavePlaceRepository places;
  late DocumentationRepository documents;
  late Uuid cave;
  late Uuid place;
  late Uuid model;
  late Uuid otherModel;

  Future<Uuid> addModel(String name) => documents.insertDocumentationFile(
    companion: DocumentationFilesCompanion.insert(
      uuid: Uuid.v7(),
      title: name,
      fileName: 'documentation_files/$name',
      fileSize: 10,
      fileType: 'survey_model',
    ),
    parentLink: DocumentationGeofeatureLink(
      type: GeofeatureType.cave,
      geofeatureUuid: cave,
    ),
  );

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger logger;
    final user = CurrentUserService(
      db,
      UserRepository(db, () => logger),
      ConfigurationRepository(db),
    );
    await user.initialize();
    logger = ChangeLogger(db, user);
    caves = CaveRepository(db, user, logger);
    places = CavePlaceRepository(db, user, logger);
    documents = DocumentationRepository(db, logger, user);
    mappings = PlaceStationMappingRepository(db, user, logger);
    defaults = CaveDefaultModelRepository(db, user, logger);

    cave = await caves.addCave('Test Cave');
    await places.addCavePlace(cave, 'Chamber');
    place = (await places.getCavePlaces(cave)).single.uuid;
    model = await addModel('a.lox');
    otherModel = await addModel('b.3d');
  });

  tearDown(() => db.close());

  Future<int> tombstones(String table) async =>
      (await db
              .customSelect(
                "SELECT COUNT(*) AS n FROM change_log "
                "WHERE entity_table = ? AND change_type = 3",
                variables: [Variable<String>(table)],
              )
              .getSingle())
          .read<int>('n');

  test('one mapping per place per model; saving again replaces it', () async {
    await mappings.saveMapping(
      cavePlaceUuid: place,
      caveUuid: cave,
      documentationFileUuid: model,
      station: 'cave.main.3',
    );
    final moved = await mappings.saveMapping(
      cavePlaceUuid: place,
      caveUuid: cave,
      documentationFileUuid: model,
      station: 'cave.main.4',
    );
    await mappings.saveMapping(
      cavePlaceUuid: place,
      caveUuid: cave,
      documentationFileUuid: otherModel,
      station: 'cave.main.3',
    );

    expect(await mappings.mappingsForModel(model), hasLength(1));
    expect(moved.station, 'cave.main.4');
    expect(await mappings.mappingsForPlace(place), hasLength(2));
  });

  test('a splay mapping keeps its offset and needs review', () async {
    final splay = await mappings.saveMapping(
      cavePlaceUuid: place,
      caveUuid: cave,
      documentationFileUuid: model,
      station: 'cave.main.3',
      splay: const ModelSplayOffset(1.5, -0.25, 2),
    );
    expect(splay.needsReview, 1);
    expect([splay.splayEast, splay.splayNorth, splay.splayUp], [1.5, -0.25, 2]);

    final station = await mappings.saveMapping(
      cavePlaceUuid: place,
      caveUuid: cave,
      documentationFileUuid: model,
      station: 'cave.main.3',
    );
    expect(station.needsReview, 0);
    expect(station.splayEast, isNull);
  });

  test('removing a mapping leaves a tombstone', () async {
    await mappings.saveMapping(
      cavePlaceUuid: place,
      caveUuid: cave,
      documentationFileUuid: model,
      station: 'cave.main.3',
    );
    expect(await mappings.deleteMapping(place, model), isTrue);
    expect(await mappings.deleteMapping(place, model), isFalse);
    expect(await mappings.mappingsForModel(model), isEmpty);
    expect(await tombstones('cave_place_model_stations'), 1);
  });

  test('the default model is set, changed and cleared', () async {
    expect(await defaults.defaultModelOf(cave), isNull);
    await defaults.setDefaultModel(cave, model);
    await defaults.setDefaultModel(cave, otherModel);
    expect(await defaults.defaultModelOf(cave), otherModel);
    await defaults.clearDefaultModel(cave);
    expect(await defaults.defaultModelOf(cave), isNull);
    expect(await tombstones('cave_default_survey_models'), 1);
  });

  group('the links go with what they hang on', () {
    setUp(() async {
      await mappings.saveMapping(
        cavePlaceUuid: place,
        caveUuid: cave,
        documentationFileUuid: model,
        station: 'cave.main.3',
      );
      await defaults.setDefaultModel(cave, model);
    });

    test('a deleted place', () async {
      await places.deleteCavePlace(place);
      expect(await mappings.mappingsForModel(model), isEmpty);
      expect(await defaults.defaultModelOf(cave), model);
      expect(await tombstones('cave_place_model_stations'), 1);
    });

    test('a deleted model document', () async {
      await documents.deleteDocumentationFile(model);
      expect(await mappings.mappingsForPlace(place), isEmpty);
      expect(await defaults.defaultModelOf(cave), isNull);
      expect(await tombstones('cave_default_survey_models'), 1);
    });

    test('a deleted cave', () async {
      await caves.deleteCave(cave);
      expect(await db.select(db.cavePlaceModelStations).get(), isEmpty);
      expect(await db.select(db.caveDefaultSurveyModels).get(), isEmpty);
    });
  });
}
