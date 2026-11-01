import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_model/cave_default_model_repository.dart';
import 'package:speleoloc/services/cave_model/cave_model_locator.dart';
import 'package:speleoloc/services/cave_model/place_station_mapping_repository.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/documentation_repository.dart';
import 'package:speleoloc/services/user_repository.dart';

/// Which of a cave's models opens: the caver's default, else the newest; for
/// a place, the first in that order that maps it.
void main() {
  late AppDatabase db;
  late CaveModelLocator locator;
  late CaveDefaultModelRepository defaults;
  late PlaceStationMappingRepository mappings;
  late DocumentationRepository documents;
  late Uuid cave;
  late Uuid place;
  late Uuid older;
  late Uuid newer;

  Future<Uuid> addModel(String name, int createdAt, {Uuid? onPlace}) =>
      documents.insertDocumentationFile(
        companion: DocumentationFilesCompanion.insert(
          uuid: Uuid.v7(),
          title: name,
          fileName: 'documentation_files/$name',
          fileSize: 1,
          fileType: 'survey_model',
          createdAt: Value(createdAt),
        ),
        parentLink: DocumentationGeofeatureLink(
          type: onPlace == null
              ? GeofeatureType.cave
              : GeofeatureType.cavePlace,
          geofeatureUuid: onPlace ?? cave,
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
    final places = CavePlaceRepository(db, user, logger);
    documents = DocumentationRepository(db, logger, user);
    defaults = CaveDefaultModelRepository(db, user, logger);
    mappings = PlaceStationMappingRepository(db, user, logger);
    locator = CaveModelLocator(documents, defaults, mappings, places);
    cave = await CaveRepository(db, user, logger).addCave('Test Cave');
    await places.addCavePlace(cave, 'Lake');
    place = (await places.getCavePlaces(cave)).single.uuid;
    older = await addModel('old.lox', 1000);
    newer = await addModel('new.3d', 2000);
  });

  tearDown(() => db.close());

  test('the newest model comes first, the default before it', () async {
    expect((await locator.modelsOf(cave)).map((d) => d.uuid), [newer, older]);
    await defaults.setDefaultModel(cave, older);
    expect((await locator.modelsOf(cave)).map((d) => d.uuid), [older, newer]);
    expect((await locator.modelToOpen(cave))!.model.uuid, older);
  });

  test('a place opens the first model that maps it', () async {
    await defaults.setDefaultModel(cave, older);
    expect(
      (await locator.modelToOpen(cave, cavePlaceUuid: place))!.mapping,
      isNull,
    );
    await mappings.saveMapping(
      cavePlaceUuid: place,
      caveUuid: cave,
      documentationFileUuid: newer,
      station: 'a.1',
    );
    final open = await locator.modelToOpen(cave, cavePlaceUuid: place);
    expect(open!.model.uuid, newer);
    expect(open.mapping!.station, 'a.1');
  });

  test(
    'a model is found to belong to its cave, also through a place',
    () async {
      final onPlace = await addModel('place.lox', 3000, onPlace: place);
      final doc = (await documents.findById(onPlace))!;
      expect(await locator.caveOf(doc), cave);
      expect(await locator.caveOf((await documents.findById(newer))!), cave);
    },
  );

  test('a cave without models opens nothing', () async {
    await documents.deleteDocumentationFile(older);
    await documents.deleteDocumentationFile(newer);
    expect(await locator.modelToOpen(cave), isNull);
  });
}
