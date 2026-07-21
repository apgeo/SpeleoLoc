import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_map/cave_map_controller.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/user_repository.dart';

void main() {
  late AppDatabase db;
  late CaveRepository caveRepo;
  late CavePlaceRepository placeRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger loggerRef;
    final users = UserRepository(db, () => loggerRef);
    final currentUser = CurrentUserService(
      db,
      users,
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    loggerRef = ChangeLogger(db, currentUser);
    caveRepo = CaveRepository(db, currentUser, loggerRef);
    placeRepo = CavePlaceRepository(db, currentUser, loggerRef);
  });

  tearDown(() => db.close());

  Future<Uuid> insertPlace(
    Uuid caveUuid,
    String title, {
    double? lat,
    double? lng,
    bool isEntrance = false,
    bool isMainEntrance = false,
  }) async {
    final uuid = Uuid.v7();
    await db
        .into(db.cavePlaces)
        .insert(
          CavePlacesCompanion.insert(
            uuid: uuid,
            title: title,
            caveUuid: caveUuid,
            latitude: Value(lat),
            longitude: Value(lng),
            isEntrance: Value(isEntrance ? 1 : 0),
            isMainEntrance: Value(isMainEntrance ? 1 : 0),
          ),
        );
    return uuid;
  }

  CaveMapController controller({
    Set<Uuid>? focusCaveUuids,
    Set<Uuid>? focusPlaceUuids,
  }) => CaveMapController(
    placeRepository: placeRepo,
    caveRepository: caveRepo,
    focusCaveUuids: focusCaveUuids,
    focusPlaceUuids: focusPlaceUuids,
  );

  test('loadItems keeps only located places; no filter = all in focus', () async {
    final cave = await caveRepo.addCave('Cave');
    await insertPlace(cave, 'Entrance', lat: 45, lng: 22, isEntrance: true);
    await insertPlace(cave, 'No coordinates');

    final map = controller(focusCaveUuids: const {});
    await map.loadItems();

    expect(map.items, hasLength(1));
    expect(map.items.single.isFocus, isTrue, reason: 'empty set = no filter');
    expect(map.visibleItems, hasLength(1));
  });

  test('toggles filter the visible items and clear a hidden selection', () async {
    final focused = await caveRepo.addCave('Focused');
    final other = await caveRepo.addCave('Other');
    await insertPlace(focused, 'E', lat: 45, lng: 22, isEntrance: true);
    await insertPlace(focused, 'P', lat: 45.1, lng: 22.1);
    final otherPlace = await insertPlace(
      other,
      'X',
      lat: 46,
      lng: 23,
      isEntrance: true,
    );

    final map = controller(focusCaveUuids: {focused});
    await map.loadItems();
    expect(map.visibleItems, hasLength(3));

    map.select(otherPlace);
    expect(map.selectedItem?.uuid, otherPlace);

    map.toggleOtherCaves();
    expect(map.visibleItems.map((i) => i.place.title), ['E', 'P']);
    expect(map.selectedUuid, isNull, reason: 'hidden selection is cleared');

    map.toggleNonEntrances();
    expect(map.visibleItems.map((i) => i.place.title), ['E']);
  });

  test('reveal relaxes the toggles hiding the item and selects it', () async {
    final focused = await caveRepo.addCave('Focused');
    final other = await caveRepo.addCave('Other');
    await insertPlace(focused, 'E', lat: 45, lng: 22, isEntrance: true);
    final hidden = await insertPlace(other, 'P', lat: 46, lng: 23);

    final map = controller(focusCaveUuids: {focused});
    await map.loadItems();
    map.toggleOtherCaves();
    map.toggleNonEntrances();
    expect(map.visibleItems, hasLength(1));

    final target = map.items.firstWhere((i) => i.uuid == hidden);
    map.reveal(target);

    expect(map.showOtherCaves, isTrue);
    expect(map.showNonEntrances, isTrue);
    expect(map.selectedItem?.uuid, hidden);
  });

  test('paint order: focus over non-focus, selected on top', () async {
    final focused = await caveRepo.addCave('Focused');
    final other = await caveRepo.addCave('Other');
    final otherE = await insertPlace(
      other,
      'otherE',
      lat: 46,
      lng: 23,
      isEntrance: true,
    );
    final focusP = await insertPlace(focused, 'focusP', lat: 45.1, lng: 22.1);
    final focusE = await insertPlace(
      focused,
      'focusE',
      lat: 45,
      lng: 22,
      isEntrance: true,
    );

    final map = controller(focusCaveUuids: {focused});
    await map.loadItems();

    List<Uuid> order() => [for (final i in map.paintOrder) i.uuid];
    expect(order(), [otherE, focusP, focusE]);

    map.select(otherE);
    expect(order(), [focusP, focusE, otherE], reason: 'selected paints last');
  });

  test('addToFocus makes a created place focused after reload', () async {
    final focused = await caveRepo.addCave('Focused');
    final other = await caveRepo.addCave('Other');
    await insertPlace(focused, 'E', lat: 45, lng: 22, isEntrance: true);

    final map = controller(focusCaveUuids: {focused});
    await map.loadItems();

    final created = await insertPlace(
      other,
      'New',
      lat: 46,
      lng: 23,
      isEntrance: true,
    );
    map.addToFocus(placeUuid: created);
    await map.loadItems();

    expect(
      map.items.firstWhere((i) => i.uuid == created).isFocus,
      isTrue,
    );
  });
}
