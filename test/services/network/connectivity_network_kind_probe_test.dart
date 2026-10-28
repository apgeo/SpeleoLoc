import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/network/connectivity_network_kind_probe.dart';
import 'package:speleoloc/services/network/network_kind_probe.dart';

/// What the platform's list of transports amounts to.
void main() {
  NetworkKind kindOf(List<ConnectivityResult> results) =>
      ConnectivityNetworkKindProbe.kindOf(results);

  test('one transport is that kind', () {
    expect(
      kindOf(<ConnectivityResult>[ConnectivityResult.wifi]),
      NetworkKind.wifi,
    );
    expect(
      kindOf(<ConnectivityResult>[ConnectivityResult.ethernet]),
      NetworkKind.ethernet,
    );
    expect(
      kindOf(<ConnectivityResult>[ConnectivityResult.mobile]),
      NetworkKind.mobile,
    );
  });

  test('a VPN is read by what it runs over', () {
    expect(
      kindOf(<ConnectivityResult>[
        ConnectivityResult.vpn,
        ConnectivityResult.wifi,
      ]),
      NetworkKind.wifi,
    );
    expect(
      kindOf(<ConnectivityResult>[
        ConnectivityResult.vpn,
        ConnectivityResult.mobile,
      ]),
      NetworkKind.mobile,
    );
    // Alone, or as the platforms that cannot name one report it.
    expect(
      kindOf(<ConnectivityResult>[ConnectivityResult.vpn]),
      NetworkKind.unknown,
    );
    expect(
      kindOf(<ConnectivityResult>[ConnectivityResult.other]),
      NetworkKind.unknown,
    );
  });

  test('mobile data beside Wi-Fi counts as mobile data', () {
    expect(
      kindOf(<ConnectivityResult>[
        ConnectivityResult.wifi,
        ConnectivityResult.mobile,
      ]),
      NetworkKind.mobile,
    );
  });

  test('nothing is none', () {
    expect(
      kindOf(<ConnectivityResult>[ConnectivityResult.none]),
      NetworkKind.none,
    );
    expect(kindOf(const <ConnectivityResult>[]), NetworkKind.none);
  });

  test('only Wi-Fi and a cable are taken as unmetered', () {
    expect(NetworkKind.values.where((k) => k.isUnmetered), <NetworkKind>[
      NetworkKind.wifi,
      NetworkKind.ethernet,
    ]);
  });
}
