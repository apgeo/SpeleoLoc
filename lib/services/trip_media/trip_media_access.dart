import 'package:photo_manager/photo_manager.dart';
import 'package:speleoloc/services/trip_media/device_library_media_source.dart';
import 'package:speleoloc/services/trip_media/picked_files_media_source.dart';
import 'package:speleoloc/services/trip_media/trip_media_source.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// What the device actually granted, which decides which source the screen
/// gets rather than which one it asked for.
enum TripMediaAccess {
  /// The whole library is readable: browsing and date filtering both work.
  full,

  /// Only the assets the user picked in the system's own selection UI are
  /// visible. Still enumerable and date-filterable, just a smaller set.
  limited,

  /// No library access. The system picker still works and needs no
  /// permission, so the feature degrades to "choose some files" rather than
  /// failing.
  picker,
}

/// Resolution of the access request: the granted level and the source that
/// matches it.
class TripMediaResolution {
  const TripMediaResolution(this.access, this.source);

  final TripMediaAccess access;
  final TripMediaSource source;
}

/// Asks for library access and hands back whichever source the answer
/// permits — and, because the note this screen was built from offers both
/// ways in as the user's own choice, the other one on request.
class TripMediaAccessResolver {
  const TripMediaAccessResolver();

  /// The system picker in place of the library: for files the library does
  /// not hold — a cloud provider, the Files app — or simply a hand-picked
  /// few. Available whatever access was granted, since it needs none.
  TripMediaResolution picker(TripMediaAccess granted) =>
      TripMediaResolution(granted, PickedFilesMediaSource());

  /// Back to the library. Only meaningful when [granted] reaches it.
  TripMediaResolution library(TripMediaAccess granted) =>
      TripMediaResolution(granted, DeviceLibraryMediaSource());

  /// Lets the user change which photos a "selected photos" grant covers
  /// (iOS 14+, Android 14+). On iOS 14 this returns before the user has
  /// finished choosing; later versions wait for them.
  Future<void> chooseMorePhotos() async {
    try {
      await PhotoManager.presentLimited(type: RequestType.common);
    } catch (e, st) {
      _log.info('the limited-selection picker is unavailable', e, st);
    }
  }

  /// Opens this app's page in the system settings — the only place a
  /// denied library permission can be granted again.
  Future<void> openSystemSettings() async {
    try {
      await PhotoManager.openSetting();
    } catch (e, st) {
      _log.info('could not open the app settings', e, st);
    }
  }

  static final _log = AppLogger.of('TripMediaAccessResolver');

  Future<TripMediaResolution> resolve() async {
    PermissionState state;
    try {
      state = await PhotoManager.requestPermissionExtend();
    } catch (e, st) {
      // Desktop and any platform without the plugin's native side: the
      // picker path is still legitimate, so this is not an error.
      _log.info(
        'library permission request unavailable; using the picker',
        e,
        st,
      );
      return TripMediaResolution(
        TripMediaAccess.picker,
        PickedFilesMediaSource(),
      );
    }

    switch (state) {
      case PermissionState.authorized:
        return TripMediaResolution(
          TripMediaAccess.full,
          DeviceLibraryMediaSource(),
        );
      case PermissionState.limited:
        return TripMediaResolution(
          TripMediaAccess.limited,
          DeviceLibraryMediaSource(),
        );
      case PermissionState.denied:
      case PermissionState.restricted:
      case PermissionState.notDetermined:
        return TripMediaResolution(
          TripMediaAccess.picker,
          PickedFilesMediaSource(),
        );
    }
  }
}
