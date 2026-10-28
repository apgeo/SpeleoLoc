import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_decision.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';

/// What the caver can do about what an installation did not write.
///
/// Nothing here happens on its own. A turned-down new item stays on the
/// device as a draft, unsent until the caver edits it; a turned-down edit, or
/// one that met a later version on the server, stays as the caver left it and
/// is not sent again while it does. The caver chooses: go back to the server's
/// version, keep their own without sending it, or throw a draft away.
///
/// Each section's items are named and handled by its own resolver.
class SilexgisDecisionsService {
  SilexgisDecisionsService({
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required List<SilexgisDecisionResolver> resolvers,
  }) : _localState = localState,
       _heldRows = heldRows,
       _resolvers = <SyncUploadSection, SilexgisDecisionResolver>{
         for (final resolver in resolvers)
           for (final section in resolver.sections) section: resolver,
       };

  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final Map<SyncUploadSection, SilexgisDecisionResolver> _resolvers;

  /// The items waiting for the caver's choice on [profileUuid].
  Future<List<SilexgisDecision>> decisions(String profileUuid) async {
    final revisions = await _localState.readRevisions(profileUuid);
    final decisions = <SilexgisDecision>[];
    final orphans = <SyncUploadSection, List<Uuid>>{};
    for (final held in await _heldRows.readAll(profileUuid)) {
      if (!held.awaitsCaver) continue;
      final resolver = _resolvers[held.section];
      if (resolver == null) continue;
      final title = await resolver.title(held);
      if (title == null && !held.isDelete) {
        // The item went with something the caver threw away — a place inside
        // a draft cave, a pin on a draft map — so there is nothing left to
        // choose about.
        (orphans[held.section] ??= <Uuid>[]).add(held.entityUuid);
        continue;
      }
      decisions.add(
        SilexgisDecision(
          held: held,
          isNew: await resolver.isNew(held, revisions),
          title: title,
        ),
      );
    }
    for (final entry in orphans.entries) {
      await _heldRows.clear(profileUuid, entry.key, entry.value);
    }
    return decisions;
  }

  /// Puts the server's version back in place of the caver's. Returns true
  /// when it is already in place; false when the next run brings it.
  Future<bool> useServerVersion(
    SilexgisProfile profile,
    SilexgisDecision decision,
  ) async {
    final resolver = _resolvers[decision.section];
    if (resolver == null || !decision.canUseServerVersion) return false;
    return resolver.useServerVersion(profile, decision.held);
  }

  /// Keeps the caver's version on the device, unsent until they edit it.
  Future<void> keepMine(String profileUuid, SilexgisDecision decision) =>
      _heldRows.markKept(
        profileUuid,
        decision.section,
        decision.held.entityUuid,
      );

  /// Throws away an item the server never had, or a pin whose place another
  /// pin already marks there.
  Future<void> delete(
    SilexgisProfile profile,
    SilexgisDecision decision,
  ) async {
    final resolver = _resolvers[decision.section];
    if (resolver == null || !(decision.canDelete || decision.canRemovePin)) {
      return;
    }
    await resolver.delete(profile, decision.held);
    await _heldRows.clear(profile.profileUuid, decision.section, <Uuid>[
      decision.held.entityUuid,
    ]);
  }
}
