import 'package:speleoloc/services/silexgis/silexgis_trip_state_repository.dart';

/// Decides what becomes of a local scan its recording no longer lists.
///
/// The trips stream leaves out every scan of a place the account is not
/// handed, and does not tell a removed scan from a withheld one. So a missing
/// scan is removed here only when this device got it from the installation and
/// never sent it: a scan this device made, or sent, may only be withheld, and
/// removing it would lose the caver's work.
///
/// Once the stream names removed scans by their own tombstones, a missing scan
/// is kept whatever its history and a tombstoned one removed: [removesMissing]
/// then answers false, and the tombstones are applied as recordings' are.
class SilexgisScanMergeRule {
  const SilexgisScanMergeRule();

  /// Whether a scan missing from its recording's list is removed here.
  /// [state] is what this device knows of it on the installation, and
  /// [editedHere] says it has an unsent local edit or waits for a reviewer.
  bool removesMissing(SilexgisTripState? state, {required bool editedHere}) =>
      state != null && state.received && !state.sent && !editedHere;
}
