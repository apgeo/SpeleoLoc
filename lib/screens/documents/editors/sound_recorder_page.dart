import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speleo_loc/data/source/database/app_database.dart';
import 'package:speleo_loc/utils/documentation_file_helper.dart';
import 'package:speleo_loc/utils/localization.dart';

/// Audio recorder with waveform visualisation.
///
/// Uses `flutter_sound` for recording and `audio_waveforms` for the live
/// waveform display.  Saved files use the `.wav` extension.
///
/// * **Create mode** (default): record → preview → save.
/// * **Edit mode** (`existingDoc != null`): re-record and overwrite.
class SoundRecorderPage extends StatefulWidget {
  const SoundRecorderPage({
    super.key,
    this.cavePlaceId,
    this.caveId,
    this.caveAreaId,
    this.existingDoc,
  });

  final int? cavePlaceId;
  final int? caveId;
  final int? caveAreaId;
  final DocumentationFile? existingDoc;

  @override
  State<SoundRecorderPage> createState() => _SoundRecorderPageState();
}

class _SoundRecorderPageState extends State<SoundRecorderPage> {
  final _titleCtrl = TextEditingController();

  // flutter_sound
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  // audio_waveforms
  late RecorderController _waveController;
  late PlayerController _playerController;

  bool _recorderReady = false;
  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isPlaying = false;
  bool _isSaving = false;
  String? _recordedPath;
  Duration _elapsed = Duration.zero;

  bool get _isEditing => widget.existingDoc != null;

  @override
  void initState() {
    super.initState();
    _waveController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
    _playerController = PlayerController();

    if (_isEditing) {
      _titleCtrl.text = widget.existingDoc!.title;
    }

    _initRecorder();
  }

  Future<void> _initRecorder() async {
    try {
      await _recorder.openRecorder();
      await _player.openPlayer();
      if (mounted) setState(() => _recorderReady = true);
    } catch (e) {
      debugPrint('[SoundRecorderPage] init error: $e');
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    _waveController.dispose();
    _playerController.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  //  Recording
  // -----------------------------------------------------------------------

  Future<void> _startRecording() async {
    if (!_recorderReady) return;

    // Check and request microphone permission if needed.
    var micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      micStatus = await Permission.microphone.request();
    }
    if (!micStatus.isGranted) {
      if (!mounted) return;
      if (micStatus.isPermanentlyDenied) {
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
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocServ.inst.t('microphone_permission_denied'))),
        );
      }
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      _recordedPath =
          '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.startRecorder(
        toFile: _recordedPath,
        codec: Codec.pcm16WAV,
      );
      await _waveController.record();

      _recorder.onProgress!.listen((event) {
        if (mounted) setState(() => _elapsed = event.duration);
      });

      setState(() {
        _isRecording = true;
        _hasRecording = false;
      });
    } catch (e) {
      debugPrint('[SoundRecorderPage] start recording error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocServ.inst.t('recording_error'))),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stopRecorder();
      await _waveController.stop();
      if (_recordedPath != null) {
        await _playerController.preparePlayer(
          path: _recordedPath!,
          shouldExtractWaveform: true,
        );
      }
      setState(() {
        _isRecording = false;
        _hasRecording = _recordedPath != null;
      });
    } catch (e) {
      debugPrint('[SoundRecorderPage] stop recording error: $e');
    }
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
        setState(() => _isPlaying = false);
      } else {
        await _player.startPlayer(
          fromURI: _recordedPath,
          codec: Codec.pcm16WAV,
          whenFinished: () {
            if (mounted) setState(() => _isPlaying = false);
          },
        );
        await _playerController.startPlayer();
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      debugPrint('[SoundRecorderPage] playback error: $e');
    }
  }

  // -----------------------------------------------------------------------
  //  Save
  // -----------------------------------------------------------------------

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocServ.inst.t('title_required'))),
      );
      return;
    }
    if (_recordedPath == null || !File(_recordedPath!).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocServ.inst.t('no_recording'))),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final recordedFile = File(_recordedPath!);

      if (_isEditing) {
        // ---- UPDATE ----
        final doc = widget.existingDoc!;
        final bytes = await recordedFile.readAsBytes();
        final saved = await DocumentationFileHelper.overwriteBytes(
          relativePath: doc.fileName,
          bytes: bytes,
        );
        await DocumentationFileHelper.updateRecord(
          id: doc.id,
          title: title,
          description: doc.description,
          savedFile: saved,
        );
      } else {
        // ---- CREATE ----
        final saved =
            await DocumentationFileHelper.saveExternalFile(recordedFile);
        final parentLink = await appDatabase.getDocumentationParentLink(
          cavePlaceId: widget.cavePlaceId,
          caveId: widget.caveId,
          caveAreaId: widget.caveAreaId,
        );
        await DocumentationFileHelper.insertRecord(
          title: title,
          savedFile: saved,
          fileType: 'audio',
          parentLink: parentLink,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? LocServ.inst.t('edit_audio')
              : LocServ.inst.t('new_audio_recording'),
        ),
        actions: [
          if (_hasRecording && !_isSaving)
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
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ---- Title field ----
            TextField(
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
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: Colors.grey),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_hasRecording && !_isRecording)
                  IconButton.filled(
                    iconSize: 36,
                    onPressed: _togglePlayback,
                    icon: Icon(
                      _isPlaying ? Icons.stop : Icons.play_arrow,
                    ),
                  ),
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
    );
  }
}
