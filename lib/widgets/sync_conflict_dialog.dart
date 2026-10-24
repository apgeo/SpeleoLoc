import 'package:flutter/material.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/utils/localization.dart';

/// Returns a [ConflictResolver] that asks the user about each conflict in a
/// side-by-side dialog shown over [context]. Once the user picks an
/// apply-to-all answer it is reused for the rest of the import without
/// asking again.
ConflictResolver promptingConflictResolver(BuildContext context) {
  final batch = _BatchResolverState();
  return (SyncConflict conflict) async {
    if (batch.sticky != null) return batch.sticky;
    if (!context.mounted) return null;
    final result = await showDialog<_ConflictDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ConflictDialog(conflict: conflict),
    );
    if (result == null) return SyncConflictAction.keepLocal;
    if (result.applyToAll) batch.sticky = result.action;
    return result.action;
  };
}

class _BatchResolverState {
  SyncConflictAction? sticky;
}

class _ConflictDialogResult {
  final SyncConflictAction action;
  final bool applyToAll;
  const _ConflictDialogResult(this.action, {this.applyToAll = false});
}

/// Side-by-side diff dialog for a single sync conflict.
class _ConflictDialog extends StatelessWidget {
  const _ConflictDialog({required this.conflict});

  final SyncConflict conflict;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        LocServ.inst.t('sync_conflict_title', {'table': conflict.tableName}),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${LocServ.inst.t('sync_conflict_fields')}: '
                '${conflict.differingFields.join(', ')}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                LocServ.inst.t('sync_conflict_ts', {
                  'local': _fmtTs(conflict.localUpdatedAt),
                  'incoming': _fmtTs(conflict.incomingUpdatedAt),
                }),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              _SideBySideDiff(
                differingFields: conflict.differingFields,
                local: conflict.localFields,
                incoming: conflict.incomingFields,
              ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const _ConflictDialogResult(SyncConflictAction.keepLocal),
          ),
          child: Text(LocServ.inst.t('sync_conflict_keep_local')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const _ConflictDialogResult(SyncConflictAction.useIncoming),
          ),
          child: Text(LocServ.inst.t('sync_conflict_use_incoming')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const _ConflictDialogResult(
              SyncConflictAction.keepLocal,
              applyToAll: true,
            ),
          ),
          child: Text(LocServ.inst.t('sync_conflict_keep_all_local')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const _ConflictDialogResult(
              SyncConflictAction.useIncoming,
              applyToAll: true,
            ),
          ),
          child: Text(LocServ.inst.t('sync_conflict_use_all_incoming')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const _ConflictDialogResult(SyncConflictAction.cancel),
          ),
          child: Text(
            LocServ.inst.t('sync_conflict_cancel_import'),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  static String _fmtTs(int? ms) {
    if (ms == null || ms == 0) return '—';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    return dt.toString().split('.').first;
  }
}

class _SideBySideDiff extends StatelessWidget {
  const _SideBySideDiff({
    required this.differingFields,
    required this.local,
    required this.incoming,
  });

  final List<String> differingFields;
  final Map<String, dynamic> local;
  final Map<String, dynamic> incoming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      border: TableBorder.all(color: theme.dividerColor, width: 0.5),
      children: [
        TableRow(
          decoration: BoxDecoration(color: theme.hoverColor),
          children: [
            _cell(LocServ.inst.t('sync_conflict_field'), bold: true),
            _cell(LocServ.inst.t('sync_conflict_local'), bold: true),
            _cell(LocServ.inst.t('sync_conflict_incoming'), bold: true),
          ],
        ),
        for (final key in differingFields)
          TableRow(
            children: [
              _cell(key, bold: true),
              _cell('${local[key] ?? '—'}'),
              _cell('${incoming[key] ?? '—'}'),
            ],
          ),
      ],
    );
  }

  Widget _cell(String text, {bool bold = false}) => Padding(
    padding: const EdgeInsets.all(6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );
}
