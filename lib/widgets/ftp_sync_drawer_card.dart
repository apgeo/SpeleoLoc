import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/settings/ftp_sync_progress_page.dart';
import 'package:speleoloc/screens/settings/ftp_sync_settings_page.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_sync_controller.dart';
import 'package:speleoloc/services/sync/ftp/ftp_sync_progress.dart';
import 'package:speleoloc/utils/localization.dart';

/// Mini card shown at the bottom of the global drawer (right above the
/// active-trip card) to give one-tap access to FTP sync + live feedback.
///
/// Visual states:
/// 1. No FTP profile configured → a compact hint that opens the settings
///    screen when tapped.
/// 2. Profile configured, sync idle → a "Sync now" action row with the
///    profile name as subtitle.
/// 3. Sync running → a determinate progress bar, phase label and a cancel
///    icon button. Tapping the card opens the detail screen.
/// 4. Sync just finished / failed → a compact result line with a tiny
///    retry button when failed.
class FtpSyncDrawerCard extends ConsumerStatefulWidget {
  const FtpSyncDrawerCard({super.key});

  @override
  ConsumerState<FtpSyncDrawerCard> createState() =>
      _FtpSyncDrawerCardState();
}

class _FtpSyncDrawerCardState extends ConsumerState<FtpSyncDrawerCard> {
  FtpProfile? _defaultProfile;
  bool _loadedProfile = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultProfile();
  }

  Future<void> _loadDefaultProfile() async {
    final repo = ref.read(ftpProfileRepositoryProvider);
    final profile = await repo.getDefaultProfile();
    if (!mounted) return;
    setState(() {
      _defaultProfile = profile;
      _loadedProfile = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(ftpSyncControllerProvider);
    final progress = controller.progress;
    if (!_loadedProfile) {
      return const SizedBox.shrink();
    }
    if (_defaultProfile == null &&
        progress.phase == FtpSyncPhase.idle) {
      return _buildConfigurePrompt(context);
    }
    return _buildSyncCard(context, controller, progress);
  }

  Widget _buildConfigurePrompt(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FtpSyncSettingsPage()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_outlined, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  LocServ.inst.t('ftp_configure_to_sync'),
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncCard(
    BuildContext context,
    FtpSyncController controller,
    FtpSyncProgress progress,
  ) {
    final theme = Theme.of(context);
    final isRunning = progress.isRunning;
    final isPaused = progress.isPaused;
    final phaseLabel =
        progress.phase == FtpSyncPhase.idle && _defaultProfile != null
            ? LocServ.inst.t('ftp_sync_now')
            : LocServ.inst.t('ftp_phase_${progress.phase.name}');
    final profileName = progress.profileName ??
        _defaultProfile?.displayName ??
        '';

    Color? background;
    IconData leadingIcon;
    Color leadingColor;
    switch (progress.phase) {
      case FtpSyncPhase.idle:
        background = theme.colorScheme.surfaceContainerHigh;
        leadingIcon = Icons.cloud_sync;
        leadingColor = theme.colorScheme.primary;
        break;
      case FtpSyncPhase.completed:
        background = Colors.green.withValues(alpha: 0.10);
        leadingIcon = Icons.cloud_done;
        leadingColor = Colors.green;
        break;
      case FtpSyncPhase.failed:
        background = Colors.red.withValues(alpha: 0.10);
        leadingIcon = Icons.cloud_off;
        leadingColor = Colors.red;
        break;
      case FtpSyncPhase.cancelled:
        background = Colors.orange.withValues(alpha: 0.10);
        leadingIcon = Icons.cancel_outlined;
        leadingColor = Colors.orange;
        break;
      case FtpSyncPhase.paused:
        background = Colors.blueGrey.withValues(alpha: 0.10);
        leadingIcon = Icons.pause_circle_outline;
        leadingColor = Colors.blueGrey;
        break;
      default:
        background = theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
        leadingIcon = Icons.cloud_upload;
        leadingColor = theme.colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: background,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isRunning ||
              isPaused ||
              progress.phase == FtpSyncPhase.completed ||
              progress.phase == FtpSyncPhase.failed ||
              progress.phase == FtpSyncPhase.cancelled) {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FtpSyncProgressPage()),
            );
          } else {
            _startSync(controller);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(leadingIcon, size: 16, color: leadingColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      phaseLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isRunning)
                    IconButton(
                      icon: const Icon(Icons.pause_circle, size: 18),
                      tooltip: LocServ.inst.t('ftp_sync_pause'),
                      visualDensity: VisualDensity.compact,
                      onPressed: controller.pause,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else if (isPaused)
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill, size: 18),
                      tooltip: LocServ.inst.t('ftp_sync_resume'),
                      visualDensity: VisualDensity.compact,
                      onPressed: controller.resume,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else if (progress.phase == FtpSyncPhase.idle)
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill, size: 18),
                      tooltip: LocServ.inst.t('ftp_sync_now'),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _startSync(controller),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              if (profileName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    profileName,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (isRunning) ...[
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress.overallProgress.clamp(0.0, 1.0),
                  minHeight: 4,
                ),
                if (progress.currentFileName != null ||
                    progress.archivesTotal > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _subLabel(progress),
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              if (!isRunning && progress.phase == FtpSyncPhase.failed)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    progress.errorMessage ?? '',
                    style: const TextStyle(fontSize: 10, color: Colors.red),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _subLabel(FtpSyncProgress p) {
    final pieces = <String>[];
    if (p.archivesTotal > 0 &&
        (p.phase == FtpSyncPhase.downloading ||
            p.phase == FtpSyncPhase.importing)) {
      pieces.add('${p.archivesProcessed + 1}/${p.archivesTotal}');
    }
    if (p.currentFileName != null) {
      pieces.add(p.currentFileName!);
    }
    if (p.totalBytes != null && p.bytesTransferred > 0) {
      pieces.add('${_formatBytes(p.bytesTransferred)} / '
          '${_formatBytes(p.totalBytes!)}');
    }
    return pieces.join(' · ');
  }

  Future<void> _startSync(FtpSyncController controller) async {
    if (_defaultProfile == null) return;
    // Don't close the drawer — live progress updates there.
    unawaited(controller.startDefault());
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
