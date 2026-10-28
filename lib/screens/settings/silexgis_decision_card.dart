import 'package:flutter/material.dart';
import 'package:speleoloc/services/silexgis/model/sync_review.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_decision.dart';
import 'package:speleoloc/utils/localization.dart';

/// One item waiting for the caver: what it is, why it was not written, and
/// the choices that apply to it.
class SilexgisDecisionCard extends StatelessWidget {
  const SilexgisDecisionCard({
    required this.decision,
    required this.enabled,
    required this.onUseServer,
    required this.onKeepMine,
    required this.onDelete,
    super.key,
  });

  final SilexgisDecision decision;
  final bool enabled;
  final VoidCallback onUseServer;
  final VoidCallback onKeepMine;

  /// Deletes a draft, or removes a pin another already stands for.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final held = decision.held;
    final title = decision.title;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title == null || title.isEmpty
                  ? LocServ.inst.t('silexgis_review_untitled')
                  : title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              _sectionLabel(decision.section),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              <String>[
                _reason(decision),
                if (held.isDelete) LocServ.inst.t('silexgis_review_removal'),
                if (decision.isNew && !decision.isPinExists)
                  LocServ.inst.t('silexgis_review_new_row'),
              ].join(' · '),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            // The reviewer's own words, and the server's code for a failure.
            // Never a reason this application made up.
            if (held.note != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(held.note!),
            ],
            if (held.code != null && !held.isConflict) ...<Widget>[
              const SizedBox(height: 4),
              Text(held.code!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              children: <Widget>[
                if (decision.canDelete)
                  TextButton(
                    onPressed: enabled ? onDelete : null,
                    child: Text(LocServ.inst.t('silexgis_review_delete')),
                  ),
                if (decision.canRemovePin)
                  TextButton(
                    onPressed: enabled ? onDelete : null,
                    child: Text(LocServ.inst.t('silexgis_decision_remove_pin')),
                  ),
                TextButton(
                  onPressed: enabled ? onKeepMine : null,
                  child: Text(LocServ.inst.t('silexgis_review_keep_mine')),
                ),
                if (decision.canUseServerVersion)
                  FilledButton(
                    onPressed: enabled ? onUseServer : null,
                    child: Text(
                      LocServ.inst.t(
                        decision.hasServerRow
                            ? 'silexgis_review_use_server'
                            : 'silexgis_decision_reread',
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _reason(SilexgisDecision decision) {
    if (decision.isPinExists) {
      return LocServ.inst.t('silexgis_decision_pin_exists');
    }
    if (decision.isConflict) return LocServ.inst.t('silexgis_conflict');
    return decision.held.outcome == SyncReviewOutcome.failed
        ? LocServ.inst.t('silexgis_review_failed')
        : LocServ.inst.t('silexgis_review_rejected');
  }

  static String _sectionLabel(SyncUploadSection section) => switch (section) {
    SyncUploadSection.rows => LocServ.inst.t('silexgis_decision_feature'),
    SyncUploadSection.people => LocServ.inst.t('silexgis_decision_person'),
    SyncUploadSection.documents => LocServ.inst.t('silexgis_decision_document'),
    SyncUploadSection.documentLinks => LocServ.inst.t(
      'silexgis_decision_document_link',
    ),
    SyncUploadSection.tripRecordings => LocServ.inst.t(
      'silexgis_decision_recording',
    ),
    SyncUploadSection.tripPoints => LocServ.inst.t('silexgis_decision_scan'),
    SyncUploadSection.rasterMaps => LocServ.inst.t('silexgis_decision_map'),
    SyncUploadSection.rasterPins => LocServ.inst.t('silexgis_decision_pin'),
  };
}
