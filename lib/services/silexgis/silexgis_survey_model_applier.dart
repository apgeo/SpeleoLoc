import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/silexgis/model/sync_survey_models.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_copies.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_repository.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/clock.dart';

/// The local table places at stations come from.
abstract final class SilexgisSurveyTables {
  static const String placeStations = 'cave_place_model_stations';
}

/// What applying the survey-models stream did.
class SilexgisSurveyModelsApplied {
  const SilexgisSurveyModelsApplied({
    this.models = 0,
    this.modelsRemoved = 0,
    this.mappingsInserted = 0,
    this.mappingsUpdated = 0,
    this.mappingsRemoved = 0,
    this.heldBack = 0,
    this.withoutPlaceOrSurvey = 0,
    this.collisions = const <Uuid>[],
  });

  /// Models listed, whether or not their file is here yet.
  final int models;
  final int modelsRemoved;
  final int mappingsInserted;
  final int mappingsUpdated;
  final int mappingsRemoved;

  /// Mappings with a local edit not yet sent, or waiting for a reviewer, left
  /// as the caver has them.
  final int heldBack;

  /// Mappings of a place or a survey file this device does not hold.
  final int withoutPlaceOrSurvey;

  /// Mappings whose place another local mapping already ties to that survey.
  /// The local one is kept.
  final List<Uuid> collisions;

  int get changed => mappingsInserted + mappingsUpdated;
  int get removed => modelsRemoved + mappingsRemoved;

  SilexgisSurveyModelsApplied plus(SilexgisSurveyModelsApplied other) =>
      SilexgisSurveyModelsApplied(
        models: models + other.models,
        modelsRemoved: modelsRemoved + other.modelsRemoved,
        mappingsInserted: mappingsInserted + other.mappingsInserted,
        mappingsUpdated: mappingsUpdated + other.mappingsUpdated,
        mappingsRemoved: mappingsRemoved + other.mappingsRemoved,
        heldBack: heldBack + other.heldBack,
        withoutPlaceOrSurvey: withoutPlaceOrSurvey + other.withoutPlaceOrSurvey,
        collisions: <Uuid>[...collisions, ...other.collisions],
      );
}

/// Writes what the survey-models stream says: the installation's models into
/// local-only state, and its places at stations into the mapping table.
///
/// - A model is recorded whatever is here; its file is fetched afterwards.
/// - A removed model goes with its local copy and that copy's mappings — its
///   tombstone stands for theirs.
/// - A mapping is written only when its place and its survey's file are on
///   this device. One with a local edit not yet sent, or waiting for a
///   reviewer, is left as the caver has it, as a pin is. A splay end stays
///   marked as needing review.
/// - A mapping merely missing is kept: it may only be withheld.
class SilexgisSurveyModelApplier {
  SilexgisSurveyModelApplier({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required SilexgisSurveyModelRepository models,
    required SilexgisSurveyModelCopies copies,
    required String profileUuid,
    Clock clock = const SystemClock(),
  }) : _db = db,
       _logger = logger,
       _localState = localState,
       _heldRows = heldRows,
       _models = models,
       _copies = copies,
       _profileUuid = profileUuid,
       _clock = clock;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final SilexgisSurveyModelRepository _models;
  final SilexgisSurveyModelCopies _copies;
  final String _profileUuid;
  final Clock _clock;
  final _log = AppLogger.of('SilexgisSurveyModelApplier');

  Map<Uuid, StoredRevision> _agreed = const <Uuid, StoredRevision>{};
  Set<Uuid> _held = const <Uuid>{};

  /// Applies one page; [afterwards] runs once its rows are written, which is
  /// where the caller stores the page's position.
  ///
  /// Removed models go first and outside the page's transaction: their files
  /// leave the disk, which no rollback would bring back.
  Future<SilexgisSurveyModelsApplied> applyPage(
    SyncSurveyModelsPage page, {
    Future<void> Function()? afterwards,
  }) async {
    var applied = await removeModels(<Uuid>[
      for (final t in page.tombstones) ?Uuid.tryParse(t.id),
    ]);
    applied = applied.plus(
      await _suspendedTransaction(() async {
        var applied = const SilexgisSurveyModelsApplied();
        for (final model in page.models) {
          applied = applied.plus(await _model(model));
        }
        for (final mapping in page.placeStations) {
          applied = applied.plus(await _mapping(mapping));
        }
        applied = applied.plus(
          await _mappingTombstones(page.placeStationTombstones),
        );
        await afterwards?.call();
        return applied;
      }),
    );
    return applied;
  }

  /// Writes one mapping that did not come on a page — the server's own
  /// version, handed back with a reviewer's decision.
  Future<SilexgisSurveyModelsApplied> applyMapping(SyncPlaceStation server) =>
      _suspendedTransaction(() => _mapping(server));

  /// Drops [modelIds] — named removed, or missing from a read from the
  /// beginning — with their local copies.
  Future<SilexgisSurveyModelsApplied> removeModels(List<Uuid> modelIds) async {
    if (modelIds.isEmpty) return const SilexgisSurveyModelsApplied();
    final recorded = await _models.readAll(_profileUuid);
    var removed = 0;
    for (final id in modelIds) {
      final model = recorded[id];
      if (model == null) continue;
      final mappings = await _copies.remove(model.documentId);
      await _localState.forgetRevisions(_profileUuid, mappings);
      removed++;
    }
    await _models.forget(_profileUuid, modelIds);
    return SilexgisSurveyModelsApplied(modelsRemoved: removed);
  }

  Future<SilexgisSurveyModelsApplied> _suspendedTransaction(
    Future<SilexgisSurveyModelsApplied> Function() body,
  ) => _logger.runSuspended(
    () => _db.transaction(() async {
      _agreed = await _localState.readRevisions(_profileUuid);
      _held = (await _heldRows.readSection(
        _profileUuid,
        SyncUploadSection.placeStations,
      )).keys.toSet();
      return body();
    }),
  );

  // ------------------------------------------------------------------ models

  Future<SilexgisSurveyModelsApplied> _model(SyncSurveyModel server) async {
    final id = Uuid.tryParse(server.id);
    final cave = Uuid.tryParse(server.caveId);
    final document = Uuid.tryParse(server.documentId);
    if (id == null || cave == null || document == null) {
      _log.warning('a survey model with an unreadable identifier was skipped');
      return const SilexgisSurveyModelsApplied();
    }
    await _models.record(_profileUuid, id, cave, document, server);
    return const SilexgisSurveyModelsApplied(models: 1);
  }

  // ---------------------------------------------------------------- mappings

  Future<SilexgisSurveyModelsApplied> _mapping(SyncPlaceStation server) async {
    final id = Uuid.tryParse(server.id);
    final place = Uuid.tryParse(server.placeId);
    final survey = await _surveyDocument(server);
    if (id == null || place == null || survey == null) {
      return const SilexgisSurveyModelsApplied(withoutPlaceOrSurvey: 1);
    }
    final placeRow = await (_db.select(
      _db.cavePlaces,
    )..where((t) => t.uuid.equalsValue(place))).getSingleOrNull();
    if (placeRow == null || await _copies.local(survey) == null) {
      return const SilexgisSurveyModelsApplied(withoutPlaceOrSurvey: 1);
    }

    final local = await _row(id);
    if (local != null) {
      if (local.cavePlaceUuid != place ||
          local.documentationFileUuid != survey) {
        // A mapping stays with its place and its survey; this one is
        // another's here.
        return SilexgisSurveyModelsApplied(collisions: <Uuid>[id]);
      }
      if (_editedHere(id, local.updatedAt)) {
        return const SilexgisSurveyModelsApplied(heldBack: 1);
      }
    }
    if (await _collides(id, place, survey)) {
      return SilexgisSurveyModelsApplied(collisions: <Uuid>[id]);
    }

    final stamp = _clock.nowMs();
    final splay = server.splay;
    final values = CavePlaceModelStationsCompanion(
      station: Value(server.station),
      splayEast: Value(splay?[0]),
      splayNorth: Value(splay?[1]),
      splayUp: Value(splay?[2]),
      needsReview: Value(splay == null ? 0 : 1),
      updatedAt: Value(stamp),
    );
    if (local == null) {
      await _db
          .into(_db.cavePlaceModelStations)
          .insert(
            values.copyWith(
              uuid: Value(id),
              cavePlaceUuid: Value(place),
              caveUuid: Value(placeRow.caveUuid),
              documentationFileUuid: Value(survey),
              createdAt: Value(stamp),
            ),
          );
    } else {
      await (_db.update(
        _db.cavePlaceModelStations,
      )..where((t) => t.uuid.equalsValue(id))).write(values);
    }
    if (server.revision case final revision?) {
      await _localState.writeRevision(
        _profileUuid,
        id,
        entityTable: SilexgisSurveyTables.placeStations,
        revision: revision,
        localUpdatedAt: stamp,
      );
    }
    return local == null
        ? const SilexgisSurveyModelsApplied(mappingsInserted: 1)
        : const SilexgisSurveyModelsApplied(mappingsUpdated: 1);
  }

  /// A removed mapping goes — unless the caver has an edit of it not yet
  /// sent, which is theirs and is answered when it goes up.
  Future<SilexgisSurveyModelsApplied> _mappingTombstones(
    List<SyncSurveyTombstone> tombstones,
  ) async {
    final removed = <Uuid>[];
    var heldBack = 0;
    for (final tombstone in tombstones) {
      final id = Uuid.tryParse(tombstone.id);
      if (id == null) continue;
      final local = await _row(id);
      if (local == null) continue;
      if (_editedHere(id, local.updatedAt)) {
        heldBack++;
        continue;
      }
      await (_db.delete(
        _db.cavePlaceModelStations,
      )..where((t) => t.uuid.equalsValue(id))).go();
      removed.add(id);
    }
    await _localState.forgetRevisions(_profileUuid, removed);
    return SilexgisSurveyModelsApplied(
      mappingsRemoved: removed.length,
      heldBack: heldBack,
    );
  }

  /// The local document a mapping's survey is: a server model's file, or a
  /// survey file uploaded as a document, held under its own identifier.
  Future<Uuid?> _surveyDocument(SyncPlaceStation server) async {
    if (server.documentId case final document?) return Uuid.tryParse(document);
    final model = Uuid.tryParse(server.surveyModelId ?? '');
    if (model == null) return null;
    return (await _models.readAll(_profileUuid))[model]?.documentId;
  }

  Future<CavePlaceModelStation?> _row(Uuid id) => (_db.select(
    _db.cavePlaceModelStations,
  )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull();

  /// Whether a different local mapping already ties [place] to [survey] — the
  /// table's unique key, asked before writing because it is declared
  /// `ON CONFLICT ROLLBACK`, which would take the page's transaction with it.
  Future<bool> _collides(Uuid id, Uuid place, Uuid survey) async {
    final twin =
        await (_db.select(_db.cavePlaceModelStations)
              ..where(
                (t) =>
                    t.uuid.equalsValue(id).not() &
                    t.cavePlaceUuid.equalsValue(place) &
                    t.documentationFileUuid.equalsValue(survey),
              )
              ..limit(1))
            .getSingleOrNull();
    if (twin != null) _log.warning('a mapping collides with ${twin.uuid}');
    return twin != null;
  }

  bool _editedHere(Uuid id, int? localUpdatedAt) {
    if (_held.contains(id)) return true;
    final agreed = _agreed[id];
    return agreed != null && !agreed.agreesWith(localUpdatedAt);
  }
}
