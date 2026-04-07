import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/documentation_file_helper.dart';
import 'package:speleoloc/utils/file_utils.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';

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

class _SoundRecorderPageState extends State<SoundRecorderPage>
    with AppBarMenuMixin<SoundRecorderPage> {
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
  String? _recordedPath;
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
      await _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));
      await _player.openPlayer();

      if (_isEditing) {
        await _loadExistingRecording();
      }

      if (mounted) setState(() => _recorderReady = true);
    } catch (e) {
      debugPrint('[SoundRecorderPage] init error: $e');
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
      debugPrint('[SoundRecorderPage] load existing recording error: $e');
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
      await _waveController.record();

      _recorderProgressSub?.cancel();
      _recorderProgressSub = _recorder.onProgress!.listen((event) {
        if (mounted) setState(() => _elapsed = event.duration);
      });

      setState(() {
        _isRecording = true;
        _isPaused = false;
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
      _recorderProgressSub?.cancel();
      _recorderProgressSub = null;
      await _recorder.stopRecorder();
      await _waveController.stop();

      // If we were recording over an existing WAV (splice), merge the original
      // prefix with the newly recorded tail.
      if (_preSpliceWavBytes != null && _recordedPath != null) {
        await _mergeWavFiles(_preSpliceWavBytes!, File(_recordedPath!));
        _preSpliceWavBytes = null;
      }

      // Recreate PlayerController to avoid stale state from the previous
      // recording session (fixes record → stop → record → stop losing buttons).
      await _preparePlayerForRecordedFile();

      setState(() {
        _isRecording = false;
        _isPaused = false;
        _hasRecording = _recordedPath != null;
      });
    } catch (e) {
      debugPrint('[SoundRecorderPage] stop recording error: $e');
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _recorder.pauseRecorder();
      await _waveController.stop();
      setState(() => _isPaused = true);
    } catch (e) {
      debugPrint('[SoundRecorderPage] pause error: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _recorder.resumeRecorder();
      await _waveController.record();
      setState(() => _isPaused = false);
    } catch (e) {
      debugPrint('[SoundRecorderPage] resume error: $e');
    }
  }

  // -----------------------------------------------------------------------
  //  WAV splice
  // -----------------------------------------------------------------------

  /// Merges the prefix of [originalWav] (up to [_currentPositionMs]) with the
  /// newly recorded [newFile]. The result overwrites [_recordedPath].
  Future<void> _mergeWavFiles(Uint8List originalWav, File newFile) async {
    final newBytes = await newFile.readAsBytes();
    final info = _WavInfo.parse(originalWav);
    final newInfo = _WavInfo.parse(Uint8List.fromList(newBytes));

    final bytesPerSecond =
        info.sampleRate * info.numChannels * (info.bitsPerSample ~/ 8);
    final blockAlign = info.numChannels * (info.bitsPerSample ~/ 8);

    int prefixDataBytes =
        (_currentPositionMs / 1000.0 * bytesPerSecond).round();
    prefixDataBytes = (prefixDataBytes ~/ blockAlign) * blockAlign;
    if (prefixDataBytes > info.dataSize) prefixDataBytes = info.dataSize;

    final newDataSize = prefixDataBytes + newInfo.dataSize;

    // Build WAV header from the original, patching chunk sizes.
    final header =
        Uint8List.fromList(originalWav.sublist(0, info.dataOffset));
    final hd = ByteData.sublistView(header);
    hd.setUint32(4, info.dataOffset - 8 + newDataSize, Endian.little);
    hd.setUint32(info.dataOffset - 4, newDataSize, Endian.little);

    final merged = BytesBuilder(copy: false)
      ..add(header)
      ..add(originalWav.sublist(
          info.dataOffset, info.dataOffset + prefixDataBytes))
      ..add(newBytes.sublist(newInfo.dataOffset));

    await File(_recordedPath!).writeAsBytes(merged.toBytes(), flush: true);
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
    // If still recording, stop first so the file is flushed.
    if (_isRecording) {
      await _stopRecording();
    }

    String title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      final now = DateTime.now();
      title = 'rec_'
          '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}'
          '_'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';
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
          buildAppBarMenuButton(),
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
                if (_isRecording) ...[
                  // Pause / resume button
                  IconButton.filled(
                    iconSize: 36,
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                    ),
                    onPressed:
                        _isPaused ? _resumeRecording : _pauseRecording,
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
    );
  }
}

// ---------------------------------------------------------------------------
//  _WavInfo — lightweight WAV header parser for splice support
// ---------------------------------------------------------------------------

class _WavInfo {
  final int sampleRate;
  final int numChannels;
  final int bitsPerSample;
  final int dataOffset; // byte offset where PCM data starts
  final int dataSize;

  _WavInfo({
    required this.sampleRate,
    required this.numChannels,
    required this.bitsPerSample,
    required this.dataOffset,
    required this.dataSize,
  });

  static _WavInfo parse(Uint8List wav) {
    final bd = ByteData.sublistView(wav);
    final sampleRate = bd.getUint32(24, Endian.little);
    final numChannels = bd.getUint16(22, Endian.little);
    final bitsPerSample = bd.getUint16(34, Endian.little);

    // Walk RIFF sub-chunks to find the 'data' chunk.
    int offset = 12;
    while (offset < wav.length - 8) {
      final chunkId = String.fromCharCodes(wav.sublist(offset, offset + 4));
      final chunkSize = bd.getUint32(offset + 4, Endian.little);
      if (chunkId == 'data') {
        return _WavInfo(
          sampleRate: sampleRate,
          numChannels: numChannels,
          bitsPerSample: bitsPerSample,
          dataOffset: offset + 8,
          dataSize: chunkSize,
        );
      }
      offset += 8 + chunkSize;
    }
    // Fallback: standard 44-byte header.
    return _WavInfo(
      sampleRate: sampleRate,
      numChannels: numChannels,
      bitsPerSample: bitsPerSample,
      dataOffset: 44,
      dataSize: wav.length - 44,
    );
  }
}
