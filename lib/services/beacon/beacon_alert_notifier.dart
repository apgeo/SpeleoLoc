import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/app_routes.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/utils/navigator_key.dart';

/// System notification with a **loud** alert sound for beacon detections
/// that happen while the app is not in the foreground.
///
/// The Android channel uses alarm audio attributes and a bundled sound
/// (`android/app/src/main/res/raw/beacon_alert.wav`), so it rings at alarm
/// volume even when media volume is down. Tapping the notification brings
/// the app up and opens the detected place.
///
/// On iOS the standard notification sound is used (a "louder than the
/// ringer" alert would require Apple's Critical Alerts entitlement).
class BeaconAlertNotifier {
  BeaconAlertNotifier._();
  static final BeaconAlertNotifier instance = BeaconAlertNotifier._();

  static const _channelId = 'beacon_detection_alerts';
  static const _notificationId = 7003;

  final _plugin = FlutterLocalNotificationsPlugin();
  final _log = AppLogger.of('BeaconAlertNotifier');
  bool _initialized = false;

  /// Idempotent plugin init. Returns false when the platform refuses
  /// (e.g. notification permission permanently denied).
  Future<bool> ensureInitialized() async {
    if (_initialized) return true;
    try {
      final ok = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/speleo_loc_1'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: _onTap,
      );
      _initialized = ok ?? true;
      return _initialized;
    } catch (e, st) {
      _log.warning('Notification init failed', e, st);
      return false;
    }
  }

  /// Ask the platform for notification permission (Android 13+ / iOS).
  Future<bool> requestPermission() async {
    try {
      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await android?.requestNotificationsPermission() ?? true;
      }
      if (Platform.isIOS) {
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        return await ios?.requestPermissions(
              alert: true,
              badge: false,
              sound: true,
            ) ??
            true;
      }
      return true;
    } catch (e, st) {
      _log.warning('Notification permission request failed', e, st);
      return false;
    }
  }

  /// Fire the loud detection alert. [payload] format:
  /// `place/<caveUuid>/<placeUuid>` — used to navigate on tap.
  /// [playSound] false delivers the notification silently (per-message
  /// `silent` flag — the channel's sound setting is immutable once the
  /// channel exists, so it cannot express the preference).
  Future<void> showDetection({
    required String placeTitle,
    required bool tripPointRecorded,
    required Uuid caveUuid,
    required Uuid placeUuid,
    bool playSound = true,
  }) async {
    if (!await ensureInitialized()) return;
    try {
      await _plugin.show(
        id: _notificationId,
        title: '${LocServ.inst.t('beacon_place_detected')}: $placeTitle',
        body: tripPointRecorded ? LocServ.inst.t('trip_point_added') : null,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Beacon detection alerts',
            channelDescription:
                'Loud alert when passing a registered cave beacon',
            importance: Importance.max,
            priority: Priority.high,
            category: AndroidNotificationCategory.alarm,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            sound: const RawResourceAndroidNotificationSound('beacon_alert'),
            enableVibration: true,
            visibility: NotificationVisibility.public,
            silent: !playSound,
          ),
          iOS: DarwinNotificationDetails(presentSound: playSound),
        ),
        payload: 'place/$caveUuid/$placeUuid',
      );
    } catch (e, st) {
      _log.warning('Detection notification failed', e, st);
    }
  }

  /// Cold-start path: when the user taps a detection notification after the
  /// app process died, [_onTap] never fires — the payload arrives via the
  /// launch details instead. Call once after the first frame (the navigator
  /// must exist) to complete that navigation.
  Future<void> handleLaunchFromNotification() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      final response = details?.notificationResponse;
      if ((details?.didNotificationLaunchApp ?? false) && response != null) {
        _onTap(response);
      }
    } catch (e, st) {
      _log.warning('Notification launch-details check failed', e, st);
    }
  }

  void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || !payload.startsWith('place/')) return;
    final parts = payload.split('/');
    if (parts.length != 3) return;
    try {
      final caveUuid = Uuid.parse(parts[1]);
      final placeUuid = Uuid.parse(parts[2]);
      final context = navigatorKey.currentContext;
      if (context == null) return;
      AppRoutes.pushCavePlace(
        context,
        caveUuid: caveUuid,
        cavePlaceUuid: placeUuid,
      );
    } catch (e, st) {
      _log.warning('Notification tap navigation failed', e, st);
    }
  }
}
