import 'package:flutter/material.dart';
import 'package:speleoloc/services/sync/archive_sync_decision.dart';
import 'package:speleoloc/utils/localization.dart';

/// One record a sync held because a different record here has its name:
/// what it is, what it clashes with, what waits with it, and the choices.
class ArchiveSyncDecisionCard extends StatelessWidget {
  const ArchiveSyncDecisionCard({
    required this.decision,
    required this.enabled,
    required this.onMerge,
    required this.onKeepBoth,
    required this.onDiscard,
    super.key,
  });

  final ArchiveSyncDecision decision;
  final bool enabled;
  final VoidCallback onMerge;
  final VoidCallback onKeepBoth;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kind = kindLabel(decision.table);
    final cave = decision.caveTitle;
    final local = decision.localTitle;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(decision.title ?? kind, style: theme.textTheme.titleMedium),
            Text(
              cave == null
                  ? kind
                  : '$kind · ${LocServ.inst.t('archive_decision_in_cave', {'cave': cave})}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              decision.isEdit
                  ? LocServ.inst.t('archive_decision_clash_edit', {
                      'local': local ?? kind,
                    })
                  : LocServ.inst.t('archive_decision_clash_new', {
                      'local': local ?? kind,
                    }),
              style: TextStyle(color: theme.colorScheme.error),
            ),
            if (decision.waiting.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                LocServ.inst.t('archive_decision_waiting', {
                  'count': '${decision.waiting.length}',
                }),
              ),
            ],
            const SizedBox(height: 8),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              children: <Widget>[
                TextButton(
                  onPressed: enabled ? onDiscard : null,
                  child: Text(LocServ.inst.t('archive_decision_discard')),
                ),
                if (decision.canKeepBoth)
                  TextButton(
                    onPressed: enabled ? onKeepBoth : null,
                    child: Text(LocServ.inst.t('archive_decision_keep_both')),
                  ),
                FilledButton(
                  onPressed: enabled ? onMerge : null,
                  child: Text(LocServ.inst.t('archive_decision_merge')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// What kind of record a table holds, as the caver calls it.
  static String kindLabel(String table) => switch (table) {
    'surface_areas' => LocServ.inst.t('archive_decision_kind_surface_area'),
    'caves' => LocServ.inst.t('archive_decision_kind_cave'),
    'cave_areas' => LocServ.inst.t('archive_decision_kind_cave_area'),
    'cave_places' => LocServ.inst.t('archive_decision_kind_place'),
    'cave_place_beacons' => LocServ.inst.t('archive_decision_kind_beacon'),
    'raster_maps' => LocServ.inst.t('archive_decision_kind_map'),
    'cave_place_to_raster_map_definitions' => LocServ.inst.t(
      'archive_decision_kind_pin',
    ),
    'cave_trips' => LocServ.inst.t('archive_decision_kind_trip'),
    'documentation_files' => LocServ.inst.t('archive_decision_kind_document'),
    'trip_report_templates' => LocServ.inst.t('archive_decision_kind_template'),
    _ => LocServ.inst.t('archive_decision_kind_other'),
  };
}
