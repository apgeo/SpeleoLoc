import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/settings/change_log_page.dart';
import 'package:speleoloc/screens/settings/ftp_sync_settings_page.dart';
import 'package:speleoloc/services/sync/ftp/ftp_sync_progress.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';

/// Detailed view of an in-flight or just-finished FTP sync.
///
/// Two tabs: *Progress* (phase header, overall + per-file bars, speed, ETA)
/// and *Log* (reverse-chronological timeline). The app bar carries the
/// pause / resume / stop controls that gate the controller.
class FtpSyncProgressPage extends ConsumerStatefulWidget {
  const FtpSyncProgressPage({super.key});

  @override
  ConsumerState<FtpSyncProgressPage> createState() =>
      _FtpSyncProgressPageState();
}

class _FtpSyncProgressPageState extends ConsumerState<FtpSyncProgressPage>
    with
        AppBarMenuMixin<FtpSyncProgressPage>,
        SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(ftpSyncControllerProvider);
    final progress = controller.progress;
    final isRunning = progress.isRunning;
    final isPaused = progress.isPaused;

    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('ftp_sync_progress_title')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: LocServ.inst.t('ftp_tab_progress')),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(LocServ.inst.t('ftp_tab_log')),
                  if (progress.log.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _LogCountBadge(count: progress.log.length),
                  ],
                ],
              ),
            ),
            Tab(text: LocServ.inst.t('sync_dashboard_changes_tab')),
          ],
        ),
        actions: [
          if (!isRunning && !isPaused)
            IconButton(
              icon: const Icon(Icons.play_circle),
              tooltip: LocServ.inst.t('ftp_sync_start'),
              onPressed: () => unawaited(controller.startDefault()),
            ),
          if (isRunning)
            IconButton(
              icon: const Icon(Icons.pause_circle),
              tooltip: LocServ.inst.t('ftp_sync_pause'),
              onPressed: controller.pause,
            ),
          if (isPaused)
            IconButton(
              icon: const Icon(Icons.play_circle),
              tooltip: LocServ.inst.t('ftp_sync_resume'),
              onPressed: controller.resume,
            ),
          if (isRunning || isPaused)
            IconButton(
              icon: const Icon(Icons.stop_circle),
              tooltip: LocServ.inst.t('ftp_sync_cancel'),
              onPressed: controller.cancel,
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: LocServ.inst.t('ftp_sync_settings'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FtpSyncSettingsPage()),
            ),
          ),
          buildAppBarMenuButton(),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProgressTab(progress: progress),
          _LogTab(entries: progress.log),
          const ChangeLogPage(embedded: true),
        ],
      ),
    );
  }
}

class _LogCountBadge extends StatelessWidget {
  final int count;
  const _LogCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _ProgressTab extends StatelessWidget {
  final FtpSyncProgress progress;
  const _ProgressTab({required this.progress});

  @override
  Widget build(BuildContext context) {
    return ListView(
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
          _ErrorBanner(
            message: progress.errorMessage!,
            onOpenSettings: (progress.statusMessage == 'ftp_connection_failed' ||
                    progress.statusMessage == 'ftp_auth_failed')
                ? () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const FtpSyncSettingsPage()))
                : null,
          ),
        ],
        if (progress.isPaused) ...[
          const SizedBox(height: 12),
          const _PausedBanner(),
        ],
      ],
    );
  }
}

class _LogTab extends StatelessWidget {
  final List<FtpSyncLogEntry> entries;
  const _LogTab({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            LocServ.inst.t('ftp_sync_log_empty'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    // Most recent first.
    final reversed = entries.reversed.toList();
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: reversed.length,
      separatorBuilder: (_, __) => const Divider(height: 4),
      itemBuilder: (context, i) {
        final e = reversed[i];
        if (e.isSeparator) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '─── ${LocServ.inst.t('ftp_sync_log_new_session')} ───',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
          );
        }
        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: EdgeInsets.zero,
          leading: Icon(_iconFor(e.level), size: 16, color: _colorFor(e.level)),
          title: Text(e.message, style: const TextStyle(fontSize: 12)),
          subtitle: Text(
            _formatTs(e.timestamp),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
          ),
        );
      },
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
      case FtpSyncPhase.paused:
        return Icons.pause_circle_outline;
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
      case FtpSyncPhase.paused:
        return Colors.blueGrey;
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocServ.inst.t('ftp_current_file'),
          style: theme.textTheme.titleSmall,
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
        const SizedBox(height: 6),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            if (progress.totalBytes != null)
              _Metric(
                label: LocServ.inst.t('ftp_bytes_label'),
                value: '${_formatBytes(progress.bytesTransferred)} / '
                    '${_formatBytes(progress.totalBytes!)}',
              ),
            if (progress.bytesPerSecond != null)
              _Metric(
                label: LocServ.inst.t('ftp_speed_label'),
                value: '${_formatBytes(progress.bytesPerSecond!.round())}/s',
              ),
            if (progress.stepEta != null)
              _Metric(
                label: LocServ.inst.t('ftp_eta_label'),
                value: _formatDuration(progress.stepEta!),
              ),
          ],
        ),
      ],
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String _formatDuration(Duration d) {
    if (d.inHours >= 1) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes >= 1) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onOpenSettings;
  const _ErrorBanner({required this.message, this.onOpenSettings});

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(message),
                if (onOpenSettings != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onOpenSettings,
                    icon: const Icon(Icons.settings, size: 16),
                    label: Text(LocServ.inst.t('open_settings')),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _PausedBanner extends StatelessWidget {
  const _PausedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.pause_circle_outline, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(LocServ.inst.t('ftp_paused_hint')),
          ),
        ],
      ),
    );
  }
}
