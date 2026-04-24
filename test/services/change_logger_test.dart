import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/user_repository.dart';

void main() {
  late AppDatabase db;
  late ChangeLogger logger;
  late CaveRepository caveRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger ref;
    final userRepo = UserRepository(db, () => ref);
    final currentUser = CurrentUserService(db, userRepo);
    await currentUser.initialize();
    ref = ChangeLogger(db, currentUser);
    logger = ref;
    caveRepo = CaveRepository(db, currentUser, logger);
  });

  tearDown(() async {
    await db.close();
  });

  Future<List<ChangeLogData>> allChanges() =>
      (db.select(db.changeLog)..orderBy([(c) => OrderingTerm.asc(c.changedAt)]))
          .get();

  test('logInsert writes a change_log header', () async {
    await caveRepo.addCave('My Cave');
    final rows = await allChanges();
    expect(rows, hasLength(greaterThanOrEqualTo(1)));
    final caveInsert =
        rows.firstWhere((r) => r.entityTable == 'caves');
    expect(caveInsert.changeType, ChangeType.insert);
    expect(caveInsert.deviceUuid != null, isTrue);
  });

  test('logUpdate only records changed fields as old values', () async {
    final id = await caveRepo.addCave('Original');
    await caveRepo.updateCave(id, 'Renamed', description: 'd');
    final rows = await allChanges();
    final upd = rows.firstWhere(
      (r) => r.entityTable == 'caves' && r.changeType == ChangeType.update,
    );
    final fields = await (db.select(db.changeLogField)
          ..where((f) => f.changeUuid.equalsValue(upd.uuid)))
        .get();
    final fieldNames = fields.map((f) => f.fieldName).toSet();
    expect(fieldNames, contains('title'));
    expect(fieldNames, contains('description'));
    expect(fieldNames, isNot(contains('created_at')));
    expect(fieldNames, isNot(contains('updated_at')));
  });

  test('runSuspended skips writes', () async {
    await logger.runSuspended(() async {
      await caveRepo.addCave('Hidden');
    });
    final rows = await allChanges();
    // Only the implicit "system" user bootstrap insert may have logged
    // *before* suspension (it doesn't in our setup because currentOrSystem
    // already resolved during addCave-less initialize()), and no caves row.
    expect(rows.any((r) => r.entityTable == 'caves'), isFalse);
  });

  test('identical update emits no field rows', () async {
    final id = await caveRepo.addCave('Same');
    await caveRepo.updateCave(id, 'Same');
    final rows = await allChanges();
    final updates = rows.where(
      (r) => r.entityTable == 'caves' && r.changeType == ChangeType.update,
    );
    // No-diff updates are not logged at all.
    expect(updates, isEmpty);
  });
}
