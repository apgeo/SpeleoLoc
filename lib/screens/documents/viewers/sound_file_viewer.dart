import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

/// Overlay audio player widget.
///
/// Displays a compact player with waveform visualisation that can be shown
/// as a dialog on top of the current screen.  By default the widget
/// automatically pops when playback finishes ([autoClose] = `true`).
///
/// Usage:
/// ```dart
/// SoundFileViewer.show(context, file: file, doc: doc);
/// ```
class SoundFileViewer extends StatefulWidget {
  const SoundFileViewer({
    super.key,
    required this.file,
    required this.doc,
    this.autoClose = true,
  });

  final File file;
  final DocumentationFile doc;

  /// When `true` the overlay closes itself once playback finishes.
  final bool autoClose;

  /// Convenience method to show the viewer as a modal bottom-sheet overlay.
  static Future<void> show(
    BuildContext context, {
    required File file,
    required DocumentationFile doc,
    bool autoClose = true,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SoundFileViewer(
        file: file,
        doc: doc,
        autoClose: autoClose,
      ),
    );
  }

  @override
  State<SoundFileViewer> createState() => _SoundFileViewerState();
}

class _SoundFileViewerState extends State<SoundFileViewer> {
  late PlayerController _playerController;
  bool _isPlaying = false;
  bool _prepared = false;

  @override
  void initState() {
    super.initState();
    _playerController = PlayerController();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      await _playerController.preparePlayer(
        path: widget.file.path,
        shouldExtractWaveform: true,
      );

      _playerController.onCompletion.listen((_) {
        if (!mounted) return;
        setState(() => _isPlaying = false);
        if (widget.autoClose) {
          Navigator.of(context).pop();
        }
      });

      if (mounted) {
        setState(() => _prepared = true);
        // Auto-start playback.
        _play();
      }
    } catch (e) {
      debugPrint('[SoundFileViewer] prepare error: $e');
    }
  }

  Future<void> _play() async {
    await _playerController.startPlayer();
    if (mounted) setState(() => _isPlaying = true);
  }

  Future<void> _pause() async {
    await _playerController.pausePlayer();
    if (mounted) setState(() => _isPlaying = false);
  }

  @override
  void dispose() {
    _playerController.stopAllPlayers();
    _playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Text(
              widget.doc.title,
              style: theme.textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Waveform
            if (_prepared)
              AudioFileWaveforms(
                size: Size(MediaQuery.of(context).size.width - 64, 80),
                playerController: _playerController,
                enableSeekGesture: true,
                waveformType: WaveformType.long,
                playerWaveStyle: PlayerWaveStyle(
                  fixedWaveColor: theme.colorScheme.outlineVariant,
                  liveWaveColor: theme.colorScheme.primary,
                  seekLineColor: theme.colorScheme.primary,
                ),
              )
            else
              const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 16),

            // Play / pause button
            IconButton.filled(
              iconSize: 36,
              onPressed: _prepared
                  ? (_isPlaying ? _pause : _play)
                  : null,
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            ),
          ],
        ),
      ),
    );
  }
}
