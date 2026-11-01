import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';

/// Removes the rows that tie places and caves to survey models before a
/// place, a cave or a model document is deleted, logging a tombstone for
/// each so peers remove the same rows on sync import.
///
/// Called inside the caller's transaction, before the parent row goes.
Future<void> deleteModelLinks(
  AppDatabase db,
  ChangeLogger logger, {
  Uuid? cavePlaceUuid,
  Uuid? caveUuid,
  Uuid? documentationFileUuid,
}) async {
  assert(
    cavePlaceUuid != null || caveUuid != null || documentationFileUuid != null,
  );
  Expression<bool> mappingFilter(CavePlaceModelStations t) => [
    if (cavePlaceUuid != null) t.cavePlaceUuid.equalsValue(cavePlaceUuid),
    if (caveUuid != null) t.caveUuid.equalsValue(caveUuid),
    if (documentationFileUuid != null)
      t.documentationFileUuid.equalsValue(documentationFileUuid),
  ].reduce((a, b) => a | b);

  final mappings = await (db.select(
    db.cavePlaceModelStations,
  )..where(mappingFilter)).get();
  await (db.delete(db.cavePlaceModelStations)..where(mappingFilter)).go();
  for (final m in mappings) {
    await logger.logDelete(
      'cave_place_model_stations',
      m.uuid,
      oldValues: {
        'cave_place_uuid': m.cavePlaceUuid,
        'documentation_file_uuid': m.documentationFileUuid,
        'station': m.station,
      },
    );
  }

  if (caveUuid == null && documentationFileUuid == null) return;
  Expression<bool> defaultFilter(CaveDefaultSurveyModels t) => [
    if (caveUuid != null) t.caveUuid.equalsValue(caveUuid),
    if (documentationFileUuid != null)
      t.documentationFileUuid.equalsValue(documentationFileUuid),
  ].reduce((a, b) => a | b);

  final defaults = await (db.select(
    db.caveDefaultSurveyModels,
  )..where(defaultFilter)).get();
  await (db.delete(db.caveDefaultSurveyModels)..where(defaultFilter)).go();
  for (final d in defaults) {
    await logger.logDelete(
      'cave_default_survey_models',
      d.uuid,
      oldValues: {
        'cave_uuid': d.caveUuid,
        'documentation_file_uuid': d.documentationFileUuid,
      },
    );
  }
}
