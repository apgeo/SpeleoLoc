import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/beacon/beacon_enabled_notice.dart';
import 'package:speleoloc/services/trip_record_outcome.dart';

/// What beacon detection needs from the screens: telling the caver what it
/// did, and opening the place it found. The app supplies one at start, so
/// detection never reaches for widgets or the navigator itself.
abstract interface class BeaconDetectionHost {
  /// Switching detection on stopped because a scan permission is missing.
  void permissionsMissing();

  /// Switching detection on stopped because the platform refused to scan;
  /// [reason] is the platform's own message.
  void scanningRefused(String reason);

  /// Detection was just switched on; [notice] is what the caver should know
  /// about it.
  void switchedOn(BeaconEnabledNotice notice);

  /// A beacon placed the caver at [place] while the app is on screen.
  /// [tripOutcome] is null when the place is not in the active trip's cave,
  /// so no trip point was due.
  void placeDetected(CavePlace place, TripRecordOutcome? tripOutcome);

  /// Opens [place] the way a QR scan of it would.
  Future<void> openPlace(CavePlace place);
}
