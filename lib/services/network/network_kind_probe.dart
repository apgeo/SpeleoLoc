/// Which kind of network the device is on, as far as the platform says.
///
/// A transport, not a price: a phone's hotspot is [wifi] to the phone using
/// it, and a metered Wi-Fi is not told apart from any other.
enum NetworkKind {
  wifi,
  ethernet,
  mobile,

  /// The platform reports no network.
  none,

  /// A VPN alone, Bluetooth, or anything the platform could not name — or the
  /// platform could not be asked at all.
  unknown;

  /// The kinds a caver who keeps files for Wi-Fi is content to send over.
  bool get isUnmetered => this == wifi || this == ethernet;
}

/// Says which kind of network the device is on now.
///
/// Services depend on this rather than on a plugin, so a test answers it with
/// whatever network it needs.
abstract interface class NetworkKindProbe {
  Future<NetworkKind> current();
}
