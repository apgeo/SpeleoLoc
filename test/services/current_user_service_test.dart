import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/user_repository.dart';

/// Wraps a real config repo but slows `readString` so the initialize() race
/// is observable in a deterministic way.
class _SlowConfigRepo implements IConfigurationRepository {
  _SlowConfigRepo(this._inner, this._delay);
  final IConfigurationRepository _inner;
  final Duration _delay;

  @override
  Future<String?> readString(String key) async {
    await Future<void>.delayed(_delay);
    return _inner.readString(key);
  }

  @override
  Future<void> writeString(String key, String value, {bool isSynced = false}) =>
      _inner.writeString(key, value, isSynced: isSynced);
  @override
  Future<Map<String, dynamic>> readJson(
    String key, {
    Map<String, dynamic> Function()? defaults,
  }) => _inner.readJson(key, defaults: defaults);
  @override
  Future<void> writeJson(
    String key,
    Map<String, dynamic> value, {
    bool isSynced = false,
  }) => _inner.writeJson(key, value, isSynced: isSynced);
  @override
  Future<void> delete(String key) => _inner.delete(key);
  @override
  Future<List<Configuration>> getAllRows() => _inner.getAllRows();
  @override
  Future<void> replaceRow(Configuration row) => _inner.replaceRow(row);
  @override
  Future<void> insertRow(ConfigurationsCompanion companion) =>
      _inner.insertRow(companion);
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  CurrentUserService build(IConfigurationRepository configs) {
    late ChangeLogger loggerRef;
    final users = UserRepository(db, () => loggerRef);
    final svc = CurrentUserService(db, users, configs);
    loggerRef = ChangeLogger(db, svc);
    return svc;
  }

  test(
    'awaiting a concurrent initialize() observes the loaded state',
    () async {
      final svc = build(
        _SlowConfigRepo(
          ConfigurationRepository(db),
          const Duration(milliseconds: 40),
        ),
      );
      // Kick off init fire-and-forget (as the provider does), then await a
      // second call. Pre-fix the second call returned immediately — the
      // `_initialized` flag was set before the first await — leaving the
      // notifiers null. Now both share one cached future.
      final firstUnawaited = svc.initialize();
      await svc.initialize();
      expect(svc.deviceUuid.value, isNotNull);
      await firstUnawaited;
    },
  );

  test('initialize() is idempotent and creates one device_uuid', () async {
    final svc = build(ConfigurationRepository(db));
    await svc.initialize();
    final first = svc.deviceUuid.value;
    expect(first, isNotNull);
    await svc.initialize();
    expect(svc.deviceUuid.value, first);
    final rows = await (db.select(
      db.configurations,
    )..where((c) => c.title.equals('device_uuid'))).get();
    expect(rows, hasLength(1));
  });
}
