/// Where an item a parent lists came from, as far as this device knows.
abstract interface class SilexgisItemHistory {
  /// First met by download: another phone made it.
  bool get received;

  /// This device has sent it.
  bool get sent;
}

/// Decides what becomes of a local item its parent no longer lists — a scan
/// missing from its recording, a pin missing from its map.
///
/// Both lists leave out every item of a place the account is not handed, and
/// neither tells a removed item from a withheld one. So a missing item is
/// removed here only when this device got it from the installation and never
/// sent it: one this device made, or sent, may only be withheld, and removing
/// it would lose the caver's work.
///
/// This is the rule for a server that does not name removed pins and scans.
/// A page that carries those tombstones — even an empty list — removes only
/// what they name and keeps whatever is merely missing, whatever its history;
/// the appliers then never ask here. The rule stays for the installations that
/// predate those tombstones, which a device may still be pointed at.
class SilexgisMissingItemRule {
  const SilexgisMissingItemRule();

  /// Whether an item missing from its parent's list is removed here.
  /// [history] is what this device knows of it on the installation, and
  /// [editedHere] says it has an unsent local edit or waits for a reviewer.
  bool removesMissing(
    SilexgisItemHistory? history, {
    required bool editedHere,
  }) => history != null && history.received && !history.sent && !editedHere;
}
