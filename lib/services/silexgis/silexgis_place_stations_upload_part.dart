import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_place_stations.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_document_updater.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_paged_stream_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_runner.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// A mapping one run sends.
class _Planned {
  const _Planned(this.id, {this.localUpdatedAt, this.isDelete = false});

  final Uuid id;

  /// The local row's stamp as sent; null for a removal.
  final int? localUpdatedAt;
  final bool isDelete;
}

/// The `placeStations` section: the places this run puts at a station of a
/// survey, moves to another station, or takes off one.
///
/// A mapping goes up when its place is on the installation or goes in this
/// run, and its survey is there: a server model, named by its model id, or a
/// survey file the installation holds as this device's upload, named by its
/// document. A mapping whose survey is not there yet waits.
///
/// Answered as pins are: a conflict, or another mapping already putting the
/// place at a station of that survey, is kept for the caver and has the
/// stream read again from the beginning, since neither answer carries the
/// installation's version.
class SilexgisPlaceStationsUploadPart implements SilexgisUploadPart {
  SilexgisPlaceStationsUploadPart({
    required AppDatabase db,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required SilexgisSurveyModelRepository models,
    required SilexgisCursorStore surveyModelsCursor,
    required String profileUuid,
  }) : _db = db,
       _localState = localState,
       _heldRows = heldRows,
       _models = models,
       _surveyModelsCursor = surveyModelsCursor,
       _profileUuid = profileUuid;

  final AppDatabase _db;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final SilexgisSurveyModelRepository _models;
  final SilexgisCursorStore _surveyModelsCursor;
  final String _profileUuid;
  final _log = AppLogger.of('SilexgisPlaceStationsUploadPart');

  static const String _table = SilexgisSurveyTables.placeStations;

  final Map<String, _Planned> _planned = <String, _Planned>{};

  @override
  SyncUploadSection get section => SyncUploadSection.placeStations;

  @override
  Future<List<SyncUploadItem>> build(SilexgisUploadContext context) async {
    final revisions = await _localState.readRevisions(_profileUuid);
    final held = await _heldRows.readSection(_profileUuid, section);
    final places = <Uuid>{
      for (final e in revisions.entries)
        if (e.value.entityTable == 'cave_places') e.key,
      ...context.rowsSent,
    };
    final modelOf = <Uuid, Uuid>{
      for (final m in (await _models.readAll(_profileUuid)).values)
        m.documentId: m.modelId,
    };
    final uploaded = <Uuid>{
      for (final e in revisions.entries)
        if (e.value.entityTable == SilexgisHeldDocumentUpdater.entityTable)
          e.key,
    };

    final items = <SyncUploadItem>[];
    final present = <Uuid>{};
    for (final mapping in await _db.select(_db.cavePlaceModelStations).get()) {
      present.add(mapping.uuid);
      if (!places.contains(mapping.cavePlaceUuid)) continue;
      final survey = mapping.documentationFileUuid;
      final model = modelOf[survey];
      if (model == null && !uploaded.contains(survey)) continue;
      final splay = _splayOf(mapping);
      if (!SyncUploadPlaceStation.fits(mapping.station, splay)) continue;
      final stored = switch (revisions[mapping.uuid]) {
        final r? when r.entityTable == _table => r,
        _ => null,
      };
      if (stored != null && stored.agreesWith(mapping.updatedAt)) continue;
      if (held[mapping.uuid]?.stillAsSent(mapping.updatedAt) ?? false) {
        continue;
      }
      final item = SyncUploadPlaceStation(
        id: mapping.uuid.toString(),
        baseRevision: stored?.revision,
        placeId: mapping.cavePlaceUuid.toString(),
        surveyModelId: model?.toString(),
        documentId: model == null ? survey.toString() : null,
        station: mapping.station,
        splay: splay,
      );
      _planned[item.id] = _Planned(
        mapping.uuid,
        localUpdatedAt: mapping.updatedAt,
      );
      items.add(item);
    }

    // Ahead of the mappings that go: the server applies items in order and
    // holds one live mapping per place on a survey, so a place unmapped and
    // mapped again here has to be taken down there before its successor goes
    // up.
    final removals = <SyncUploadItem>[];
    for (final entry in revisions.entries) {
      if (entry.value.entityTable != _table) continue;
      if (present.contains(entry.key)) continue;
      if (held[entry.key]?.isDelete ?? false) continue;
      final item = SyncUploadPlaceStation.delete(
        id: entry.key.toString(),
        baseRevision: entry.value.revision,
      );
      _planned[item.id] = _Planned(entry.key, isDelete: true);
      removals.add(item);
    }
    return <SyncUploadItem>[...removals, ...items];
  }

  @override
  Future<SilexgisPartAnswers> apply(
    List<SyncUploadItem> sent,
    List<SyncRowResult> answers, {
    required bool resent,
  }) async {
    final revisions = <SilexgisRevisionEntry>[];
    final forgotten = <Uuid>[];
    final heldNow = <SilexgisHeldEntry>[];
    final conflicts = <SilexgisConflictEntry>[];
    final answeredOtherwise = <Uuid>[];
    final refusals = <SilexgisRefusal>[];
    var reread = false;
    var held = 0;

    for (final answer in answers) {
      final item = _planned[answer.id];
      if (item == null) {
        _log.warning('the answer names an item this batch did not send');
        continue;
      }
      if (answer.status != SyncRowStatus.held) answeredOtherwise.add(item.id);

      switch (answer.status) {
        case SyncRowStatus.created:
        case SyncRowStatus.updated:
        case SyncRowStatus.unchanged:
          if (item.isDelete) {
            // A removal of something never received is `unchanged`.
            forgotten.add(item.id);
            break;
          }
          if (answer.revision case final revision?) {
            revisions.add(
              SilexgisRevisionEntry(
                entityUuid: item.id,
                entityTable: _table,
                revision: revision,
                localUpdatedAt: item.localUpdatedAt,
              ),
            );
          }
        case SyncRowStatus.deleted:
          forgotten.add(item.id);
        case SyncRowStatus.held:
          held++;
          final reviewId = answer.reviewId;
          if (reviewId == null) {
            _log.warning('a held answer named no review: ${answer.id}');
            break;
          }
          heldNow.add(
            SilexgisHeldEntry(
              section: section,
              entityUuid: item.id,
              entityTable: _table,
              reviewId: reviewId,
              isDelete: item.isDelete,
              sentLocalUpdatedAt: item.localUpdatedAt,
            ),
          );
        case SyncRowStatus.rejected
            when answer.code == SilexgisCodes.rowNotFound:
          // Not there after all: forgotten, it goes as new next time.
          forgotten.add(item.id);
          refusals.add(_refusal(item, answer));
        case SyncRowStatus.rejected
            when answer.code == SilexgisCodes.placeStationExists:
          reread = true;
          conflicts.add(_conflict(item, SilexgisCodes.placeStationExists));
          refusals.add(_refusal(item, answer));
        case SyncRowStatus.conflict:
          reread = true;
          conflicts.add(_conflict(item, answer.code ?? SilexgisCodes.conflict));
          refusals.add(_refusal(item, answer));
        case SyncRowStatus.rejected:
        case null:
          refusals.add(_refusal(item, answer));
      }
    }

    await _localState.writeRevisions(_profileUuid, revisions);
    await _localState.forgetRevisions(_profileUuid, forgotten);
    await _heldRows.clear(_profileUuid, section, answeredOtherwise);
    await _heldRows.recordHeld(_profileUuid, heldNow);
    await _heldRows.recordConflicts(_profileUuid, conflicts);
    if (reread) await _surveyModelsCursor.drop();
    return SilexgisPartAnswers(refusals: refusals, held: held);
  }

  static List<double>? _splayOf(CavePlaceModelStation m) =>
      m.splayEast == null || m.splayNorth == null || m.splayUp == null
      ? null
      : <double>[m.splayEast!, m.splayNorth!, m.splayUp!];

  /// Kept for the caver to settle; until they do, the mapping is not sent
  /// again and the installation's version is not laid over it.
  SilexgisConflictEntry _conflict(_Planned item, String code) =>
      SilexgisConflictEntry(
        section: section,
        entityUuid: item.id,
        entityTable: _table,
        code: code,
        isDelete: item.isDelete,
        sentLocalUpdatedAt: item.localUpdatedAt,
      );

  static SilexgisRefusal _refusal(_Planned item, SyncRowResult answer) =>
      SilexgisRefusal(entityUuid: item.id, entityTable: _table, result: answer);
}
