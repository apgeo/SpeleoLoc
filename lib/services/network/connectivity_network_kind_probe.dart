import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:speleoloc/services/network/network_kind_probe.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// [NetworkKindProbe] over `connectivity_plus`.
class ConnectivityNetworkKindProbe implements NetworkKindProbe {
  ConnectivityNetworkKindProbe([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final _log = AppLogger.of('ConnectivityNetworkKindProbe');

  @override
  Future<NetworkKind> current() async {
    try {
      return kindOf(await _connectivity.checkConnectivity());
    } on Object catch (e) {
      // On a desktop without NetworkManager there is nobody to ask.
      _log.info('the network kind could not be read: $e');
      return NetworkKind.unknown;
    }
  }

  /// The one kind [results] amount to.
  ///
  /// The platform may name several transports at once — a VPN beside the
  /// network it runs over, or Wi-Fi beside a mobile link. Mobile data wins
  /// over everything else, because sending over it is what a caver who keeps
  /// files for Wi-Fi wants to be asked about; a VPN on its own says nothing
  /// about what it runs over.
  static NetworkKind kindOf(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.mobile)) return NetworkKind.mobile;
    if (results.contains(ConnectivityResult.wifi)) return NetworkKind.wifi;
    if (results.contains(ConnectivityResult.ethernet)) {
      return NetworkKind.ethernet;
    }
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return NetworkKind.none;
    }
    return NetworkKind.unknown;
  }
}
