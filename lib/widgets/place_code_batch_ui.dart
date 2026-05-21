import 'package:flutter/material.dart';
import 'package:speleoloc/services/place_code/batch/place_code_batch_runner.dart';
import 'package:speleoloc/services/place_code/batch/place_code_overwrite_policy.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/localization.dart';

/// UI bridge that runs a [PlaceCodeBatchRunner] with overwrite prompts,
/// a real-time progress dialog, and a final summary dialog.
class PlaceCodeBatchUi {
  /// Confirms with the user, runs the batch with a progress dialog,
  /// and shows the summary.
  static Future<void> run(
    BuildContext context, {
    required PlaceCodeBatchScope scope,
    required String confirmTitle,
    required String confirmBody,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(confirmTitle),
        content: Text(confirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocServ.inst.t('generate_codes')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // The progress dialog widget runs the batch internally and returns
    // the summary when the batch finishes.
    final summary = await showDialog<PlaceCodeBatchSummary>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BatchProgressDialog(scope: scope),
    );
    if (summary == null || !context.mounted) return;
    await _showSummary(context, summary);
  }

  // ---- Overwrite prompt (called from _BatchProgressDialogState) ----

  static Future<OverwriteDecision> promptOverwrite(
    BuildContext context, {
    required OverwriteField field,
    required String? existing,
    required String computed,
  }) async {
    final fieldName = field == OverwriteField.pci
        ? LocServ.inst.t('place_code_overwrite_field_pci')
        : LocServ.inst.t('place_code_overwrite_field_qcri');
    final body = LocServ.inst
        .t('place_code_overwrite_body')
        .replaceAll('{field}', fieldName)
        .replaceAll('{existing}', existing ?? '—')
        .replaceAll('{computed}', computed);

    final result = await showDialog<OverwriteDecision>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('place_code_overwrite_title')),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, OverwriteDecision.cancelBatch),
            child: Text(LocServ.inst.t('cancel_batch')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, OverwriteDecision.keepAll),
            child: Text(LocServ.inst.t('keep_all')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, OverwriteDecision.keep),
            child: Text(LocServ.inst.t('keep')),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, OverwriteDecision.replaceAll),
            child: Text(LocServ.inst.t('replace_all')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, OverwriteDecision.replace),
            child: Text(LocServ.inst.t('replace')),
          ),
        ],
      ),
    );
    return result ?? OverwriteDecision.cancelBatch;
  }

  // ---- Summary dialog ----

  static Future<void> _showSummary(
    BuildContext context,
    PlaceCodeBatchSummary summary,
  ) async {
    final t = LocServ.inst.t;
    final durationSec = (summary.durationMs / 1000.0).toStringAsFixed(1);

    // Detect known abort causes so we can show a targeted error message.
    final hasMissingConfig = summary.aborted.any(
      (e) => e.reason == 'missingDatasetConfig',
    );
    final hasOtherAborts = summary.aborted.any(
      (e) => e.reason != 'missingDatasetConfig',
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('batch_summary_title')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // -- Abort error banners (shown before stats when relevant) --
              if (hasMissingConfig) ...[
                _ErrorBanner(message: t('batch_abort_missing_dataset_config')),
                const SizedBox(height: 8),
              ],
              if (hasOtherAborts) ...[
                _ErrorBanner(
                  message: t('batch_abort_internal_error').replaceAll(
                    '{n}',
                    summary.aborted
                        .where((e) => e.reason != 'missingDatasetConfig')
                        .length
                        .toString(),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // -- Core stats --
              Text(t('batch_summary_caves_updated')
                  .replaceAll('{n}', summary.cavesUpdated.toString())),
              Text(t('batch_summary_updated')
                  .replaceAll('{n}', summary.updated.toString())),
              Text(t('batch_summary_overwritten')
                  .replaceAll('{n}', summary.overwritten.toString())),
              Text(t('batch_summary_duration')
                  .replaceAll('{s}', durationSec)),
              const Divider(height: 16),
              Text(t('batch_summary_skipped')
                  .replaceAll('{n}', summary.skipped.length.toString())),
              Text(t('batch_summary_refused')
                  .replaceAll('{n}', summary.refused.length.toString())),
              Text(t('batch_summary_aborted')
                  .replaceAll('{n}', summary.aborted.length.toString())),
              if (summary.cancelled) ...[
                const SizedBox(height: 4),
                Text(
                  t('batch_summary_cancelled'),
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],

              // -- Strategy-1 fallback sections --
              if (summary.noSurfaceAreaFallbacks.isNotEmpty) ...[
                const SizedBox(height: 12),
                _FallbackSection(
                  title: t('batch_summary_no_surface_area_title').replaceAll(
                    '{caves}',
                    summary.noSurfaceAreaFallbacks.length.toString(),
                  ).replaceAll(
                    '{places}',
                    summary.noSurfaceAreaFallbacks
                        .fold(0, (s, e) => s + e.placeCount)
                        .toString(),
                  ),
                  subtitle: t('batch_summary_no_surface_area_hint'),
                  infos: summary.noSurfaceAreaFallbacks,
                ),
              ],
              if (summary.noIdentifierFallbacks.isNotEmpty) ...[
                const SizedBox(height: 8),
                _FallbackSection(
                  title: t('batch_summary_no_identifier_title').replaceAll(
                    '{caves}',
                    summary.noIdentifierFallbacks.length.toString(),
                  ).replaceAll(
                    '{places}',
                    summary.noIdentifierFallbacks
                        .fold(0, (s, e) => s + e.placeCount)
                        .toString(),
                  ),
                  subtitle: t('batch_summary_no_identifier_hint'),
                  infos: summary.noIdentifierFallbacks,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('ok')),
          ),
        ],
      ),
    );
  }
}
// ---------------------------------------------------------------------------
// Progress dialog widget
// ---------------------------------------------------------------------------

class _BatchProgressDialog extends StatefulWidget {
  final PlaceCodeBatchScope scope;

  const _BatchProgressDialog({required this.scope});

  @override
  State<_BatchProgressDialog> createState() => _BatchProgressDialogState();
}

class _BatchProgressDialogState extends State<_BatchProgressDialog> {
  late final BatchCancellationToken _token;
  late final DateTime _startTime;
  int _current = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _token = BatchCancellationToken();
    _startTime = DateTime.now();
    _startBatch();
  }

  void _startBatch() {
    placeCodeBatchRunner.run(
      scope: widget.scope,
      cancellationToken: _token,
      onProgress: (c, t) {
        if (mounted) {
          setState(() {
            _current = c;
            _total = t;
          });
        }
      },
      onPrompt: ({
        required cavePlaceUuid,
        required field,
        required existing,
        required computed,
      }) async {
        if (!mounted) return OverwriteDecision.cancelBatch;
        return PlaceCodeBatchUi.promptOverwrite(
          context,
          field: field,
          existing: existing,
          computed: computed,
        );
      },
    ).then((summary) {
      if (mounted) Navigator.pop(context, summary);
    });
  }

  String _formatEta() {
    if (_current == 0 || _total == 0) return '';
    final elapsedMs =
        DateTime.now().difference(_startTime).inMilliseconds;
    final msPerItem = elapsedMs / _current;
    final remainingMs = (_total - _current) * msPerItem;
    final secs = (remainingMs / 1000).round();
    if (secs < 60) return '~${secs}s';
    final mins = secs ~/ 60;
    final rem = secs % 60;
    return '~${mins}m ${rem}s';
  }

  @override
  Widget build(BuildContext context) {
    final t = LocServ.inst.t;
    final pct =
        _total > 0 ? (_current / _total * 100).toStringAsFixed(0) : '0';
    final progressValue = _total > 0 ? _current / _total : null;
    final eta = _formatEta();

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(t('batch_progress_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: progressValue),
            const SizedBox(height: 12),
            Text(t('batch_progress_count')
                .replaceAll('{current}', _current.toString())
                .replaceAll('{total}', _total.toString())
                .replaceAll('{pct}', pct)),
            if (eta.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(t('batch_progress_eta').replaceAll('{eta}', eta)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _token.cancel(),
            child: Text(t('stop')),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fallback section widget (expandable cave list)
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline,
              size: 18,
              color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _FallbackSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<FallbackCaveInfo> infos;

  const _FallbackSection({
    required this.title,
    required this.subtitle,
    required this.infos,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Text(title, style: textTheme.bodyMedium),
      subtitle: Text(subtitle,
          style: textTheme.bodySmall
              ?.copyWith(fontStyle: FontStyle.italic)),
      children: infos.map((info) {
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.only(left: 16),
          title: Text(info.caveName,
              style: textTheme.bodySmall),
          trailing: Text('×${info.placeCount}',
              style: textTheme.bodySmall),
        );
      }).toList(),
    );
  }
}
