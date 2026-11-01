import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_model/current_survey_models.dart';
import 'package:speleoloc/services/silexgis/model/sync_survey_models.dart';

/// The device's local-only record of the survey models installations hand
/// this account — see the `silexgis_survey_model` table.
class SilexgisSurveyModelRepository implements CurrentSurveyModels {
  SilexgisSurveyModelRepository(this._db);

  final AppDatabase _db;

  /// Every model of one installation, by model id.
  Future<Map<Uuid, SilexgisSurveyModelData>> readAll(String profileUuid) async {
    final rows = await (_db.select(
      _db.silexgisSurveyModel,
    )..where((t) => t.profileUuid.equals(profileUuid))).get();
    return <Uuid, SilexgisSurveyModelData>{
      for (final row in rows) row.modelId: row,
    };
  }

  /// The model whose file is [documentUuid] on [profileUuid], or null.
  Future<SilexgisSurveyModelData?> byDocument(
    String profileUuid,
    Uuid documentUuid,
  ) =>
      (_db.select(_db.silexgisSurveyModel)
            ..where(
              (t) =>
                  t.profileUuid.equals(profileUuid) &
                  t.documentId.equalsValue(documentUuid),
            )
            ..limit(1))
          .getSingleOrNull();

  /// The documents every installation holds as a survey model. They are the
  /// server's, and never go back up as the device's own.
  Future<Set<Uuid>> serverDocuments() async => <Uuid>{
    for (final row in await _db.select(_db.silexgisSurveyModel).get())
      row.documentId,
  };

  /// Records [model] as the stream lists it. A model already recorded keeps
  /// the version of its file this device holds.
  Future<void> record(
    String profileUuid,
    Uuid modelId,
    Uuid caveId,
    Uuid documentId,
    SyncSurveyModel model,
  ) => _db
      .into(_db.silexgisSurveyModel)
      .insert(
        SilexgisSurveyModelCompanion.insert(
          profileUuid: profileUuid,
          modelId: modelId,
          caveId: caveId,
          documentId: documentId,
          format: model.format,
        ).copyWith(
          versionId: Value(model.versionId),
          name: Value(model.name),
          isCurrent: Value(model.isCurrent),
          sizeBytes: Value(model.sizeBytes),
          sha256: Value(model.sha256),
          revision: Value(model.revision),
        ),
        onConflict: DoUpdate(
          (_) => SilexgisSurveyModelCompanion(
            caveId: Value(caveId),
            documentId: Value(documentId),
            format: Value(model.format),
            versionId: Value(model.versionId),
            name: Value(model.name),
            isCurrent: Value(model.isCurrent),
            sizeBytes: Value(model.sizeBytes),
            sha256: Value(model.sha256),
            revision: Value(model.revision),
          ),
        ),
      );

  /// The file of [modelId] on this device is now its [versionId].
  Future<void> recordFetched(
    String profileUuid,
    Uuid modelId,
    String? versionId,
  ) =>
      (_db.update(_db.silexgisSurveyModel)..where(
            (t) =>
                t.profileUuid.equals(profileUuid) &
                t.modelId.equalsValue(modelId),
          ))
          .write(
            SilexgisSurveyModelCompanion(fetchedVersionId: Value(versionId)),
          );

  /// The installation no longer hands over these models.
  Future<void> forget(String profileUuid, Iterable<Uuid> modelIds) async {
    if (modelIds.isEmpty) return;
    await (_db.delete(_db.silexgisSurveyModel)..where(
          (t) =>
              t.profileUuid.equals(profileUuid) &
              t.modelId.isIn(modelIds.map((u) => u.bytes)),
        ))
        .go();
  }

  @override
  Future<Set<Uuid>> currentModelDocuments(Uuid caveUuid) async => <Uuid>{
    for (final row
        in await (_db.select(_db.silexgisSurveyModel)..where(
              (t) => t.caveId.equalsValue(caveUuid) & t.isCurrent.equals(true),
            ))
            .get())
      row.documentId,
  };

  @override
  Future<List<ServerSurveyModel>> notHeld(Uuid caveUuid) async {
    final rows = await (_db.select(
      _db.silexgisSurveyModel,
    )..where((t) => t.caveId.equalsValue(caveUuid))).get();
    final held = <Uuid>{
      for (final d in await (_db.select(
        _db.documentationFiles,
      )..where((t) => t.uuid.isIn(rows.map((r) => r.documentId.bytes)))).get())
        d.uuid,
    };
    return <ServerSurveyModel>[
      for (final row in rows)
        if (row.fetchedVersionId == null || !held.contains(row.documentId))
          ServerSurveyModel(
            profileUuid: row.profileUuid,
            modelId: row.modelId,
            documentId: row.documentId,
            name: row.name,
            format: row.format,
            sizeBytes: row.sizeBytes,
            isCurrent: row.isCurrent,
          ),
    ];
  }
}
