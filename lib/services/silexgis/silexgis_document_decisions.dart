import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_decision.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_document_updater.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_row_lookup.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_row_placer.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_version_reread.dart';

/// Decisions about photos and documents.
///
/// Going back to the server's version makes the document's title and
/// description follow the server's, as they do for any document the caver has
/// not edited.
class SilexgisDocumentDecisions implements SilexgisDecisionResolver {
  SilexgisDocumentDecisions({
    required AppDatabase db,
    required SilexgisServerVersionReread reread,
    required SilexgisServerRowPlacer placer,
    required IDocumentationRepository documents,
  }) : _reread = reread,
       _placer = placer,
       _documents = documents,
       _rows = SilexgisLocalRowLookup(
         db,
         tables: const <String>{SilexgisHeldDocumentUpdater.entityTable},
       );

  final SilexgisServerVersionReread _reread;
  final SilexgisServerRowPlacer _placer;
  final IDocumentationRepository _documents;
  final SilexgisLocalRowLookup _rows;

  @override
  Set<SyncUploadSection> get sections => const <SyncUploadSection>{
    SyncUploadSection.documents,
  };

  @override
  Future<String?> title(SilexgisHeldItem held) async =>
      (await _rows.read(held.entityTable, held.entityUuid))?.title;

  @override
  Future<bool> isNew(
    SilexgisHeldItem held,
    Map<Uuid, StoredRevision> revisions,
  ) async => !revisions.containsKey(held.entityUuid);

  @override
  Future<bool> useServerVersion(
    SilexgisProfile profile,
    SilexgisHeldItem held,
  ) async {
    await _reread.giveUp(
      profile.profileUuid,
      held,
      localUpdatedAt: (await _rows.read(
        held.entityTable,
        held.entityUuid,
      ))?.updatedAt,
    );
    return _placer.place(
      profile.profileUuid,
      profile.syncSetId,
      held,
      held.current,
    );
  }

  @override
  Future<void> delete(SilexgisProfile profile, SilexgisHeldItem held) =>
      _documents.deleteDocumentationFile(held.entityUuid);
}
