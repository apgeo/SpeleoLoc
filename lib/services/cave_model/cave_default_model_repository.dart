import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/utils/clock.dart';

class CaveDefaultModelRepository implements ICaveDefaultModelRepository {
  CaveDefaultModelRepository(
    this._db,
    this._currentUser,
    this._logger, {
    Clock clock = const SystemClock(),
  }) : _clock = clock;

  final AppDatabase _db;
  final CurrentUserService _currentUser;
  final ChangeLogger _logger;
  final Clock _clock;

  static const _table = 'cave_default_survey_models';

  Future<CaveDefaultSurveyModel?> _row(Uuid caveUuid) => (_db.select(
    _db.caveDefaultSurveyModels,
  )..where((d) => d.caveUuid.equalsValue(caveUuid))).getSingleOrNull();

  @override
  Future<Uuid?> defaultModelOf(Uuid caveUuid) async =>
      (await _row(caveUuid))?.documentationFileUuid;

  @override
  Future<void> setDefaultModel(Uuid caveUuid, Uuid documentationFileUuid) =>
      _db.transaction(() async {
        final now = _clock.nowMs();
        final author = await _currentUser.currentOrSystem();
        final existing = await _row(caveUuid);
        if (existing == null) {
          final uuid = Uuid.v7();
          await _db
              .into(_db.caveDefaultSurveyModels)
              .insert(
                CaveDefaultSurveyModelsCompanion.insert(
                  uuid: uuid,
                  caveUuid: caveUuid,
                  documentationFileUuid: documentationFileUuid,
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  createdByUserUuid: Value(author),
                  lastModifiedByUserUuid: Value(author),
                ),
              );
          await _logger.logInsert(_table, uuid);
          return;
        }
        if (existing.documentationFileUuid == documentationFileUuid) return;
        await (_db.update(
          _db.caveDefaultSurveyModels,
        )..where((d) => d.uuid.equalsValue(existing.uuid))).write(
          CaveDefaultSurveyModelsCompanion(
            documentationFileUuid: Value(documentationFileUuid),
            updatedAt: Value(now),
            lastModifiedByUserUuid: Value(author),
          ),
        );
        await _logger.logUpdate(
          _table,
          existing.uuid,
          oldValues: {
            'documentation_file_uuid': existing.documentationFileUuid,
          },
          newValues: {'documentation_file_uuid': documentationFileUuid},
        );
      });

  @override
  Future<void> clearDefaultModel(Uuid caveUuid) => _db.transaction(() async {
    final existing = await _row(caveUuid);
    if (existing == null) return;
    await (_db.delete(
      _db.caveDefaultSurveyModels,
    )..where((d) => d.uuid.equalsValue(existing.uuid))).go();
    await _logger.logDelete(
      _table,
      existing.uuid,
      oldValues: {
        'cave_uuid': existing.caveUuid,
        'documentation_file_uuid': existing.documentationFileUuid,
      },
    );
  });
}
