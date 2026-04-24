import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/sync/ftp/ftp_sync_progress.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';

/// Detailed view of an in-flight or just-finished FTP sync.
///
/// Phase B: shows current phase, an overall progress bar, the per-file
/// transfer bar, a running log list, and a cancel button. Phase C will
/// replace this with a tabbed interface (Progress / Log) and add pause /
/// resume plus a live transfer-speed readout.
class FtpSyncProgressPage extends ConsumerStatefulWidget {
  const FtpSyncProgressPage({super.key});

  @override
  ConsumerState<FtpSyncProgressPage> createState() =>
      _FtpSyncProgressPageState();
}

class _FtpSyncProgressPageState extends ConsumerState<FtpSyncProgressPage>
    with AppBarMenuMixin<FtpSyncProgressPage> {
  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(ftpSyncControllerProvider);
    final progress = controller.progress;

    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('ftp_sync_progress_title')),
        actions: [
          if (progress.isRunning)
            IconButton(
              icon: const Icon(Icons.stop_circle),
              tooltip: LocServ.inst.t('cancel'),
              onPressed: controller.cancel,
            ),
          buildAppBarMenuButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PhaseHeader(progress: progress),
          const SizedBox(height: 16),
          _OverallProgressSection(progress: progress),
          const SizedBox(height: 16),
          if (progress.currentFileName != null)
            _CurrentFileSection(progress: progress),
          if (progress.phase == FtpSyncPhase.failed &&
              progress.errorMessage != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: progress.errorMessage!),
          ],
          const SizedBox(height: 24),
          Text(
            LocServ.inst.t('ftp_sync_log'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _LogList(entries: progress.log),
        ],
      ),
    );
  }
}

class _PhaseHeader extends StatelessWidget {
  final FtpSyncProgress progress;
  const _PhaseHeader({required this.progress});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _iconFor(progress.phase),
          size: 32,
          color: _colorFor(context, progress.phase),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocServ.inst.t('ftp_phase_${progress.phase.name}'),
                style: textTheme.titleMedium,
              ),
              if (progress.profileName != null)
                Text(
                  progress.profileName!,
                  style: textTheme.bodySmall,
                ),
              if (progress.startedAt != null)
                Text(
                  '${LocServ.inst.t('ftp_started_at')} '
                  '${_formatTime(progress.startedAt!)}',
                  style: textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _iconFor(FtpSyncPhase phase) {
    switch (phase) {
      case FtpSyncPhase.idle:
        return Icons.cloud;
      case FtpSyncPhase.connecting:
      case FtpSyncPhase.listing:
        return Icons.cloud_queue;
      case FtpSyncPhase.downloading:
        return Icons.cloud_download;
      case FtpSyncPhase.importing:
      case FtpSyncPhase.generatingArchive:
        return Icons.sync;
      case FtpSyncPhase.uploading:
        return Icons.cloud_upload;
      case FtpSyncPhase.finalizing:
        return Icons.checklist;
      case FtpSyncPhase.completed:
        return Icons.cloud_done;
      case FtpSyncPhase.failed:
        return Icons.cloud_off;
      case FtpSyncPhase.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Color _colorFor(BuildContext ctx, FtpSyncPhase phase) {
    switch (phase) {
      case FtpSyncPhase.completed:
        return Colors.green;
      case FtpSyncPhase.failed:
        return Colors.red;
      case FtpSyncPhase.cancelled:
        return Colors.orange;
      default:
        return Theme.of(ctx).colorScheme.primary;
    }
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
  }
}

class _OverallProgressSection extends StatelessWidget {
  final FtpSyncProgress progress;
  const _OverallProgressSection({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocServ.inst.t('ftp_overall_progress'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.overallProgress.clamp(0.0, 1.0),
          minHeight: 8,
        ),
        if (progress.archivesTotal > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${LocServ.inst.t('ftp_archives_label')}: '
              '${progress.archivesProcessed} / ${progress.archivesTotal}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _CurrentFileSection extends StatelessWidget {
  final FtpSyncProgress progress;
  const _CurrentFileSection({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocServ.inst.t('ftp_current_file'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          progress.currentFileName!,
          style: const TextStyle(fontFamily: 'monospace'),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.stepProgress.clamp(0.0, 1.0),
          minHeight: 6,
        ),
        if (progress.totalBytes != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${_formatBytes(progress.bytesTransferred)} / '
              '${_formatBytes(progress.totalBytes!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: SelectableText(message)),
        ],
      ),
    );
  }
}

class _LogList extends StatelessWidget {
  final List<FtpSyncLogEntry> entries;
  const _LogList({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text(
        LocServ.inst.t('ftp_sync_log_empty'),
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    // Most recent first.
    final reversed = entries.reversed.toList();
    return Column(
      children: [
        for (final e in reversed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _iconFor(e.level),
                  size: 14,
                  color: _colorFor(e.level),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTs(e.timestamp),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    e.message,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _iconFor(FtpSyncLogLevel level) {
    switch (level) {
      case FtpSyncLogLevel.debug:
        return Icons.bug_report_outlined;
      case FtpSyncLogLevel.info:
        return Icons.info_outline;
      case FtpSyncLogLevel.warning:
        return Icons.warning_amber_outlined;
      case FtpSyncLogLevel.error:
        return Icons.error_outline;
    }
  }

  Color _colorFor(FtpSyncLogLevel level) {
    switch (level) {
      case FtpSyncLogLevel.debug:
        return Colors.grey;
      case FtpSyncLogLevel.info:
        return Colors.blueGrey;
      case FtpSyncLogLevel.warning:
        return Colors.orange;
      case FtpSyncLogLevel.error:
        return Colors.red;
    }
  }

  String _formatTs(DateTime dt) {
    final l = dt.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}:'
        '${l.second.toString().padLeft(2, '0')}';
  }
}
