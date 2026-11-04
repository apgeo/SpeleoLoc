import 'package:flutter/material.dart';
import 'package:speleoloc/utils/localization.dart';

/// The question asked before an imported archive deletes records on this
/// device, with what the import would do. Shared by the manual import and
/// the FTP sync, so both ask in the same words.
String _consentText(int deletes, int inserts, int updates) => LocServ.inst.t(
  'sync_deletions_body',
  {'deletes': '$deletes', 'inserts': '$inserts', 'updates': '$updates'},
);

/// Asks whether an archive may delete [deletes] records on this device.
/// True means delete and import; false or dismissing imports nothing.
Future<bool> showSyncDeletionConsentDialog(
  BuildContext context, {
  required int deletes,
  required int inserts,
  required int updates,
}) async {
  final apply = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(LocServ.inst.t('sync_deletions_title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_consentText(deletes, inserts, updates)),
          const SizedBox(height: 12),
          Text(
            LocServ.inst.t('sync_deletions_keep_hint'),
            style: Theme.of(ctx).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(LocServ.inst.t('sync_deletions_keep')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(LocServ.inst.t('sync_deletions_apply')),
        ),
      ],
    ),
  );
  return apply ?? false;
}

/// The same question inline, for a sync that waits while the user may be
/// looking elsewhere: the run stays paused on it until one button is used.
class SyncDeletionConsentCard extends StatelessWidget {
  const SyncDeletionConsentCard({
    super.key,
    required this.archiveName,
    required this.deletes,
    required this.inserts,
    required this.updates,
    required this.onApply,
    required this.onKeep,
  });

  final String archiveName;
  final int deletes;
  final int inserts;
  final int updates;
  final VoidCallback onApply;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.orange),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.delete_sweep_outlined, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    LocServ.inst.t('sync_deletions_title'),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              archiveName,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(_consentText(deletes, inserts, updates)),
            const SizedBox(height: 8),
            Text(
              LocServ.inst.t('sync_deletions_ftp_keep_hint'),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: onKeep,
                  child: Text(LocServ.inst.t('sync_deletions_keep')),
                ),
                FilledButton(
                  onPressed: onApply,
                  child: Text(LocServ.inst.t('sync_deletions_apply')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
