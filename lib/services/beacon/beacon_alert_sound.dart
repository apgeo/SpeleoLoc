import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Plays the short detection alert (`assets/sounds/beacon_alert.wav`) for
/// detections that happen while the app is on screen — background
/// detections alert via the notification channel sound instead
/// ([BeaconAlertNotifier]). Same audio file in both paths, so a detection
/// sounds identical either way.
class BeaconAlertSound {
  BeaconAlertSound._();
  static final BeaconAlertSound instance = BeaconAlertSound._();

  static const _assetPath = 'assets/sounds/beacon_alert.wav';

  final _log = AppLogger.of('BeaconAlertSound');
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  Uint8List? _bytes;

  /// Fire-and-forget playback; a failure must never break the detection
  /// pipeline, so every error is only logged.
  Future<void> play() async {
    try {
      _bytes ??= (await rootBundle.load(
        _assetPath,
      )).buffer.asUint8List();
      if (!_player.isOpen()) await _player.openPlayer();
      if (_player.isPlaying) await _player.stopPlayer();
      await _player.startPlayer(
        fromDataBuffer: _bytes,
        codec: Codec.pcm16WAV,
      );
    } catch (e, st) {
      _log.warning('Beacon alert sound failed', e, st);
    }
  }
}
