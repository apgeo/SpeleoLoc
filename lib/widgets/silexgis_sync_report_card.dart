import 'package:flutter/material.dart';
import 'package:speleoloc/screens/settings/silexgis_sync_settings_page.dart'
    show SilexgisActionLabel;
import 'package:speleoloc/services/silexgis/silexgis_sync_progress.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_runner.dart';
import 'package:speleoloc/utils/localization.dart';

/// What a run left for a caver to decide.
///
/// Three different things end up here and they are not the same. A refused row
/// is the server saying no to one write. A conflict is two people editing the
/// same row, and the server's own version rides back beside it so a caver can
/// see what they are merging against — except where it may not, in which case
/// the answer is to read again rather than to guess. A duplicate report is not
/// a verdict at all: the row was written, and whether it is the same cave as
/// the one nearby is a question only a caver can answer.
class SilexgisSyncReportCard extends StatelessWidget {
  const SilexgisSyncReportCard({required this.progress, super.key});

  final SilexgisSyncProgress progress;

  @override
  Widget build(BuildContext context) {
    final refusals = progress.refusals;
    final unresolved = progress.download?.unresolved ?? const [];
    final duplicates = progress.upload?.duplicates ?? const [];

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.rule),
            title: Text(LocServ.inst.t('silexgis_attention')),
          ),
          for (final refusal in refusals) _RefusalTile(refusal: refusal),
          if (duplicates.isNotEmpty)
            for (final report in duplicates)
              ExpansionTile(
                leading: const Icon(Icons.content_copy_outlined),
                title: Text(LocServ.inst.t('silexgis_duplicate')),
                subtitle: Text(LocServ.inst.t('silexgis_duplicate_desc')),
                children: <Widget>[
                  for (final near in report.nearby)
                    ListTile(
                      dense: true,
                      title: Text(near.name ?? near.id),
                      subtitle: near.distanceMeters == null
                          ? null
                          : Text(
                              LocServ.inst.t('silexgis_metres_away', {
                                'distance': near.distanceMeters!
                                    .toStringAsFixed(0),
                              }),
                            ),
                    ),
                ],
              ),
          if (unresolved.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.link_off),
              title: Text(
                LocServ.inst.t('silexgis_unresolved', <String, String>{
                  'count': '${unresolved.length}',
                }),
              ),
              // Carried but not stored: the caller may read the row and not
              // the cave above it, and a place with no cave is not a shape
              // this application has.
              subtitle: Text(LocServ.inst.t('silexgis_unresolved_desc')),
            ),
        ],
      ),
    );
  }
}

class _RefusalTile extends StatelessWidget {
  const _RefusalTile({required this.refusal});

  final SilexgisRefusal refusal;

  @override
  Widget build(BuildContext context) {
    final server = refusal.serverRow;
    return ListTile(
      leading: Icon(
        refusal.isConflict ? Icons.merge_type : Icons.block_outlined,
        color: Theme.of(context).colorScheme.error,
      ),
      title: Text(
        refusal.isConflict
            ? LocServ.inst.t('silexgis_conflict')
            : (refusal.result.code ?? LocServ.inst.t('silexgis_refused')),
      ),
      // The server's own sentence. Never a diagnosis this application made up:
      // the detail is for a human, and inventing one leaves a support call
      // with nothing to go on.
      subtitle: Text(
        <String>[
          if (refusal.result.detail != null) refusal.result.detail!,
          if (refusal.needsReread)
            LocServ.inst.t('silexgis_conflict_reread')
          else if (server?.name != null)
            LocServ.inst.t('silexgis_server_version', <String, String>{
              'name': server!.name!,
            }),
          LocServ.inst.t(refusal.action.locKey),
        ].join('\n'),
      ),
      isThreeLine: true,
    );
  }
}
