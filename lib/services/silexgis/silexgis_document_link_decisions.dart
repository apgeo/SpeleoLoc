import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_decision.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_upload_planner.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_row_placer.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_version_reread.dart';

/// Decisions about where a document hangs.
///
/// A link has no revision of its own on this device: once the installation
/// holds it, it is recorded and never sent again. So a link waiting here is
/// one the installation does not hold as the device sent it — new, unless the
/// answer was a conflict or handed over the server's link, either of which
/// says the installation holds something of it. Its name is the document's.
class SilexgisDocumentLinkDecisions implements SilexgisDecisionResolver {
  SilexgisDocumentLinkDecisions({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisServerVersionReread reread,
    required SilexgisServerRowPlacer placer,
  }) : _db = db,
       _logger = logger,
       _reread = reread,
       _placer = placer;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisServerVersionReread _reread;
  final SilexgisServerRowPlacer _placer;

  /// Each local link table, and the column naming what the document hangs
  /// on there.
  static const Map<String, String> _targetColumns = <String, String>{
    SilexgisDocumentUploadPlanner.linkTable: 'geofeature_uuid',
    SilexgisDocumentUploadPlanner.recordingLinkTable: 'cave_trip_uuid',
    SilexgisDocumentUploadPlanner.scanLinkTable: 'cave_trip_point_uuid',
  };

  @override
  Set<SyncUploadSection> get sections => const <SyncUploadSection>{
    SyncUploadSection.documentLinks,
  };

  @override
  Future<String?> title(SilexgisHeldItem held) async =>
      (await _link(held))?.read<String?>('title');

  @override
  Future<bool> isNew(
    SilexgisHeldItem held,
    Map<Uuid, StoredRevision> revisions,
  ) async => !held.isConflict && held.current == null;

  /// Forgets the decision and puts the server's link in the catalogue, or
  /// reads the catalogue again from the beginning: a link the installation
  /// holds is then recorded as held, not sent.
  @override
  Future<bool> useServerVersion(
    SilexgisProfile profile,
    SilexgisHeldItem held,
  ) async {
    await _reread.giveUp(profile.profileUuid, held);
    return _placer.place(
      profile.profileUuid,
      profile.syncSetId,
      held,
      held.current,
    );
  }

  @override
  Future<void> delete(SilexgisProfile profile, SilexgisHeldItem held) async {
    final link = await _link(held);
    final target = _targetColumns[held.entityTable];
    if (link == null || target == null) return;
    await _db.customStatement(
      'DELETE FROM ${held.entityTable} WHERE uuid = ?',
      <Object>[held.entityUuid.bytes],
    );
    await _logger.logDelete(
      held.entityTable,
      held.entityUuid,
      oldValues: <String, Object?>{
        'documentation_file_uuid': Uuid.fromBytes(
          link.read<Uint8List>('document'),
        ),
        target: switch (link.read<Uint8List?>('target')) {
          final bytes? => Uuid.fromBytes(bytes),
          null => null,
        },
      },
    );
  }

  /// The link row with its document's title, or null when it is gone.
  Future<QueryRow?> _link(SilexgisHeldItem held) async {
    final target = _targetColumns[held.entityTable];
    if (target == null) return null;
    final rows = await _db
        .customSelect(
          'SELECT d.title AS title, l.documentation_file_uuid AS document, '
          'l.$target AS target FROM ${held.entityTable} l '
          'JOIN documentation_files d ON d.uuid = l.documentation_file_uuid '
          'WHERE l.uuid = ? LIMIT 1',
          variables: <Variable<Object>>[
            Variable<Uint8List>(held.entityUuid.bytes),
          ],
        )
        .get();
    return rows.isEmpty ? null : rows.single;
  }
}
