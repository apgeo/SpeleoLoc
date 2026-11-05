import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/documentation_file_helper.dart';
import 'package:speleoloc/utils/file_utils.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/utils/wav_splice.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Audio recorder with waveform visualisation.
///
/// Uses `flutter_sound` for recording and `audio_waveforms` for the live
/// waveform display.  Saved files use the `.wav` extension.
///
/// * **Create mode** (default): record → preview → save.
/// * **Edit mode** (`existingDoc != null`): re-record and overwrite.
class SoundRecorderPage extends ConsumerStatefulWidget {
  const SoundRecorderPage({
    super.key,
    this.cavePlaceUuid,
    this.caveUuid,
    this.caveAreaUuid,
    this.existingDoc,
  });

  final Uuid? cavePlaceUuid;
  final Uuid? caveUuid;
  final Uuid? caveAreaUuid;
  final DocumentationFile? existingDoc;

  @override
  ConsumerState<SoundRecorderPage> createState() => _SoundRecorderPageState();
}

class _SoundRecorderPageState extends ConsumerState<SoundRecorderPage>
    with
        AppBarMenuMixin<SoundRecorderPage>,
        ProductTourMixin<SoundRecorderPage> {
  @override
  String get tourId => 'sound_recorder';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(
      keyId: 'controls',
      titleLocKey: 'tour_sound_recorder_controls_title',
      bodyLocKey: 'tour_sound_recorder_controls_body',
    ),
    TourStepDef(
      keyId: 'title_field',
      titleLocKey: 'tour_sound_recorder_title_field_title',
      bodyLocKey: 'tour_sound_recorder_title_field_body',
    ),
    TourStepDef(
      keyId: 'menu',
      titleLocKey: 'tour_sound_recorder_menu_title',
      bodyLocKey: 'tour_sound_recorder_menu_body',
    ),
  ];

  final _titleCtrl = TextEditingController();

  // flutter_sound
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  // audio_waveforms
  late RecorderController _waveController;
  PlayerController _playerController = PlayerController();

  bool _recorderReady = false;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _hasRecording = false;
  bool _isPlaying = false;
  bool _isSaving = false;

  /// True while a start/stop/pause/resume call is in flight; a second tap on
  /// the same button would otherwise run it again before the first returned.
  bool _transitioning = false;

  /// True once this page has recorded something that is not stored yet.
  bool _hasUnsavedRecording = false;
  String? _recordedPath;

  /// Scratch files of the waveform recorder, removed as soon as it stops.
  final List<String> _waveformPaths = [];
  Duration _elapsed = Duration.zero;

  StreamSubscription<RecordingDisposition>? _recorderProgressSub;

  // WAV splice support: when re-recording from slider position, the original
  // WAV bytes are kept so only the portion before the slider is preserved.
  int _currentPositionMs = 0;
  Uint8List? _preSpliceWavBytes;

  bool get _isEditing => widget.existingDoc != null;

  @override
  void initState() {
    super.initState();
    _waveController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;

    if (_isEditing) {
      _titleCtrl.text = widget.existingDoc!.title;
    }

    _initRecorder();
  }

  Future<void> _initRecorder() async {
    try {
      await _recorder.openRecorder();
      await _recorder.setSubscriptionDuration(
        const Duration(milliseconds: 100),
      );
      await _player.openPlayer();

      if (_isEditing) {
        await _loadExistingRecording();
      }

      if (mounted) setState(() => _recorderReady = true);
    } catch (e) {
      log.warning('init error', e);
      if (mounted) SnackBarService.showError(LocServ.inst.t('recording_error'));
    }
  }

  /// In edit mode, copy the existing audio file to a temp location and prepare
  /// the player so the user can listen before deciding to re-record.
  Future<void> _loadExistingRecording() async {
    try {
      final doc = widget.existingDoc!;
      final existingFile = await getDocumentsFile(doc.fileName);
      if (existingFile != null && existingFile.existsSync()) {
        final dir = await getTemporaryDirectory();
        final tempPath =
            '${dir.path}/edit_${DateTime.now().millisecondsSinceEpoch}.wav';
        await existingFile.copy(tempPath);
        _recordedPath = tempPath;

        await _playerController.preparePlayer(
          path: tempPath,
          shouldExtractWaveform: true,
        );
        _playerController.onCurrentDurationChanged.listen((ms) {
          _currentPositionMs = ms;
          if (mounted && !_isRecording) {
            setState(() => _elapsed = Duration(milliseconds: ms));
          }
        });

        if (mounted) setState(() => _hasRecording = true);
      }
    } catch (e) {
      log.warning('load existing recording error', e);
    }
  }

  /// Disposes the current [PlayerController] and creates a fresh one wired to
  /// the recorded file at [_recordedPath].
  Future<void> _preparePlayerForRecordedFile() async {
    _playerController.dispose();
    _playerController = PlayerController();
    if (_recordedPath != null) {
      await _playerController.preparePlayer(
        path: _recordedPath!,
        shouldExtractWaveform: true,
      );
      _playerController.onCurrentDurationChanged.listen((ms) {
        _currentPositionMs = ms;
        if (mounted && !_isRecording) {
          setState(() => _elapsed = Duration(milliseconds: ms));
        }
      });
    }
  }

  @override
  void dispose() {
    _recorderProgressSub?.cancel();
    _recorder.closeRecorder();
    _player.closePlayer();
    unawaited(_disposeWaveform());
    _playerController.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  //  Recording
  // -----------------------------------------------------------------------

  Future<void> _startRecording() async {
    if (!_recorderReady || _transitioning || _isSaving) return;
    _transitioning = true;
    try {
      await _startRecordingGuarded();
    } finally {
      _transitioning = false;
    }
  }

  Future<void> _startRecordingGuarded() async {
    // Check and request microphone permission if needed.
    var micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      micStatus = await Permission.microphone.request();
    }
    if (!micStatus.isGranted) {
      if (!mounted) return;
      if (micStatus.isPermanentlyDenied) {
        unawaited(
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(LocServ.inst.t('permission_required')),
              content: Text(LocServ.inst.t('microphone_permission_required')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(LocServ.inst.t('cancel')),
                ),
                TextButton(
                  onPressed: () {
                    openAppSettings();
                    Navigator.of(context).pop();
                  },
                  child: Text(LocServ.inst.t('open_settings')),
                ),
              ],
            ),
          ),
        );
      } else {
        SnackBarService.showWarning(
          LocServ.inst.t('microphone_permission_denied'),
        );
      }
      return;
    }

    try {
      // If re-recording over an existing recording, preserve the WAV prefix
      // up to the current slider position so only the tail is overwritten.
      if (_hasRecording && _recordedPath != null) {
        final file = File(_recordedPath!);
        if (file.existsSync()) {
          _preSpliceWavBytes = await file.readAsBytes();
        }
        if (_isPlaying) {
          await _player.stopPlayer();
          await _playerController.pausePlayer();
          _isPlaying = false;
        }
      }

      final dir = await getTemporaryDirectory();
      _recordedPath =
          '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.startRecorder(
        toFile: _recordedPath,
        codec: Codec.pcm16WAV,
      );
      await _startWaveform();

      unawaited(_recorderProgressSub?.cancel());
      _recorderProgressSub = _recorder.onProgress!.listen((event) {
        if (mounted) setState(() => _elapsed = event.duration);
      });

      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _hasRecording = false;
        _hasUnsavedRecording = true;
      });
    } catch (e) {
      log.warning('start recording error', e);
      if (mounted) {
        SnackBarService.showError(LocServ.inst.t('recording_error'));
      }
    }
  }

  /// Starts the waveform recorder. It exists only to feed the live waveform,
  /// but the package always records to a file; left to itself it writes an
  /// `.m4a` into the cache folder (Android) or the app documents folder (iOS)
  /// that nothing ever reads or deletes. The file goes to a known temporary
  /// path instead and [_stopWaveform] removes it. The saved recording is
  /// always the `flutter_sound` WAV.
  Future<void> _startWaveform() async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/wave_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _waveformPaths.add(path);
    await _waveController.record(path: path);
  }

  Future<void> _stopWaveform() async {
    try {
      await _waveController.stop();
    } finally {
      await _deleteWaveformFiles();
    }
  }

  /// A recording abandoned mid-way still has a scratch file; stop the
  /// recorder and remove it before the controller goes away.
  Future<void> _disposeWaveform() async {
    try {
      await _stopWaveform();
    } finally {
      _waveController.dispose();
    }
  }

  Future<void> _deleteWaveformFiles() async {
    for (final path in _waveformPaths) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } on FileSystemException catch (e) {
        log.warning('could not remove waveform scratch file', e);
      }
    }
    _waveformPaths.clear();
  }

  Future<void> _stopRecording() async {
    if (_transitioning) return;
    _transitioning = true;
    try {
      await _stopRecordingGuarded();
    } finally {
      _transitioning = false;
    }
  }

  Future<void> _stopRecordingGuarded() async {
    try {
      unawaited(_recorderProgressSub?.cancel());
      _recorderProgressSub = null;
      await _recorder.stopRecorder();
      await _stopWaveform();

      // If we were recording over an existing WAV (splice), merge the original
      // prefix with the newly recorded tail.
      if (_preSpliceWavBytes != null && _recordedPath != null) {
        final original = _preSpliceWavBytes!;
        _preSpliceWavBytes = null;
        await _mergeWavFiles(original, File(_recordedPath!));
      }

      // Recreate PlayerController to avoid stale state from the previous
      // recording session (fixes record → stop → record → stop losing buttons).
      await _preparePlayerForRecordedFile();

      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _hasRecording = _recordedPath != null;
      });
    } catch (e) {
      log.warning('stop recording error', e);
      _preSpliceWavBytes = null;
      if (!mounted) return;
      // Leave the recording state, or the screen would stay on the stop
      // button with no way out.
      final recorded =
          _recordedPath != null && File(_recordedPath!).existsSync();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _hasRecording = recorded;
      });
      SnackBarService.showError(LocServ.inst.t('recording_error'));
    }
  }

  Future<void> _pauseRecording() async {
    if (_transitioning) return;
    _transitioning = true;
    try {
      await _recorder.pauseRecorder();
      await _stopWaveform();
      if (mounted) setState(() => _isPaused = true);
    } catch (e) {
      log.warning('pause error', e);
      if (mounted) SnackBarService.showError(LocServ.inst.t('recording_error'));
    } finally {
      _transitioning = false;
    }
  }

  Future<void> _resumeRecording() async {
    if (_transitioning) return;
    _transitioning = true;
    try {
      await _recorder.resumeRecorder();
      await _startWaveform();
      if (mounted) setState(() => _isPaused = false);
    } catch (e) {
      log.warning('resume error', e);
      if (mounted) SnackBarService.showError(LocServ.inst.t('recording_error'));
    } finally {
      _transitioning = false;
    }
  }

  // -----------------------------------------------------------------------
  //  WAV splice
  // -----------------------------------------------------------------------

  /// Merges the prefix of [originalWav] (up to [_currentPositionMs]) with the
  /// newly recorded [newFile]. The result overwrites [_recordedPath].
  ///
  /// When the original cannot be spliced (not PCM WAV, or another sample
  /// format than the recorder produces) the new recording is kept on its own
  /// and the caver is told, so nothing is silently corrupted.
  Future<void> _mergeWavFiles(Uint8List originalWav, File newFile) async {
    final newBytes = await newFile.readAsBytes();
    final merged = spliceWav(originalWav, newBytes, _currentPositionMs);
    if (merged == null) {
      SnackBarService.showWarning(LocServ.inst.t('audio_splice_unsupported'));
      return;
    }
    await newFile.writeAsBytes(merged, flush: true);
  }

  // -----------------------------------------------------------------------
  //  Playback
  // -----------------------------------------------------------------------

  Future<void> _togglePlayback() async {
    if (_recordedPath == null) return;
    try {
      if (_isPlaying) {
        await _player.stopPlayer();
        await _playerController.pausePlayer();
        if (mounted) setState(() => _isPlaying = false);
      } else {
        await _player.startPlayer(
          fromURI: _recordedPath,
          codec: Codec.pcm16WAV,
          whenFinished: () {
            if (mounted) setState(() => _isPlaying = false);
          },
        );
        await _playerController.startPlayer();
        if (mounted) setState(() => _isPlaying = true);
      }
    } catch (e) {
      log.warning('playback error', e);
    }
  }

  // -----------------------------------------------------------------------
  //  Save
  // -----------------------------------------------------------------------

  Future<void> _save() async {
    if (_isSaving || _transitioning) return;
    // Set before the first await: stopping a live recording takes long enough
    // for a second tap on Save to arrive.
    setState(() => _isSaving = true);
    var closed = false;
    try {
      closed = await _saveGuarded();
    } finally {
      // After a successful save the page is closing; keep Save disabled
      // through the exit transition.
      if (!closed && mounted) setState(() => _isSaving = false);
    }
  }

  /// Returns whether the page was closed after saving.
  Future<bool> _saveGuarded() async {
    // If still recording, stop first so the file is flushed.
    if (_isRecording) {
      await _stopRecording();
      if (!mounted) return false;
    }

    String title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      final now = DateTime.now();
      title =
          'rec_'
          '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}'
          '_'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';
    }
    if (_recordedPath == null || !File(_recordedPath!).existsSync()) {
      SnackBarService.showWarning(LocServ.inst.t('no_recording'));
      return false;
    }

    try {
      final recordedFile = File(_recordedPath!);

      if (_isEditing) {
        // ---- UPDATE ----
        await ref
            .read(documentationByteEditServiceProvider)
            .save(
              widget.existingDoc!,
              await recordedFile.readAsBytes(),
              title: title,
            );
      } else {
        // ---- CREATE ----
        final saved = await DocumentationFileHelper.saveExternalFile(
          recordedFile,
        );
        final parentLink = await ref
            .read(documentationRepositoryProvider)
            .getDocumentationParentLink(
              cavePlaceUuid: widget.cavePlaceUuid,
              caveUuid: widget.caveUuid,
              caveAreaUuid: widget.caveAreaUuid,
            );
        await DocumentationFileHelper.insertRecord(
          title: title,
          savedFile: saved,
          fileType: 'audio',
          parentLink: parentLink,
        );
      }

      if (!mounted) return false;
      Navigator.pop(context, true);
      return true;
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(e);
      }
      return false;
    }
  }

  Future<void> _leaveIfConfirmed() async {
    if (!await _confirmLeave() || !mounted) return;
    Navigator.of(context).pop();
  }

  /// Asks what to do with a recording that is not stored. Returns whether the
  /// page may close now.
  Future<bool> _confirmLeave() async {
    if (_isSaving) return false;
    if (!_isRecording && !_hasUnsavedRecording) return true;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('unsaved_changes')),
        content: Text(LocServ.inst.t('unsaved_changes_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: Text(LocServ.inst.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: Text(LocServ.inst.t('discard')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: Text(LocServ.inst.t('save')),
          ),
        ],
      ),
    );
    if (result == 'save') {
      await _save(); // pops the page on success
      return false;
    }
    return result == 'discard';
  }

  // -----------------------------------------------------------------------
  //  Helpers
  // -----------------------------------------------------------------------

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // -----------------------------------------------------------------------
  //  Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leaveIfConfirmed();
      },
      child: Scaffold(
        key: appMenuScaffoldKey,
        endDrawer: buildAppMenuEndDrawer(),
        appBar: AppBar(
          title: Text(
            _isEditing
                ? LocServ.inst.t('edit_audio')
                : LocServ.inst.t('new_audio_recording'),
          ),
          actions: [
            if ((_hasRecording || _isRecording) && !_isSaving)
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: LocServ.inst.t('save'),
                onPressed: _save,
              ),
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton()),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ---- Title field ----
              TextField(
                key: tourKeys['title_field'],
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: LocServ.inst.t('title'),
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),

              // ---- Waveform visualisation ----
              if (_isRecording)
                AudioWaveforms(
                  enableGesture: false,
                  size: Size(MediaQuery.of(context).size.width - 32, 120),
                  recorderController: _waveController,
                  waveStyle: WaveStyle(
                    waveColor: theme.colorScheme.primary,
                    extendWaveform: true,
                    showMiddleLine: true,
                    middleLineColor: theme.colorScheme.outline,
                  ),
                )
              else if (_hasRecording)
                AudioFileWaveforms(
                  size: Size(MediaQuery.of(context).size.width - 32, 120),
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
                Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: Text(
                    LocServ.inst.t('tap_record'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // ---- Elapsed time ----
              Text(
                _formatDuration(_elapsed),
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),

              // ---- Controls ----
              Row(
                key: tourKeys['controls'],
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_hasRecording && !_isRecording)
                    IconButton.filled(
                      iconSize: 36,
                      onPressed: _togglePlayback,
                      icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    ),
                  if (_isRecording) ...[
                    // Pause / resume button
                    IconButton.filled(
                      iconSize: 36,
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                      ),
                      onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                      icon: Icon(
                        _isPaused ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  const SizedBox(width: 24),
                  IconButton.filled(
                    iconSize: 48,
                    style: IconButton.styleFrom(
                      backgroundColor: _isRecording
                          ? Colors.red
                          : theme.colorScheme.primary,
                    ),
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    icon: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
