import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:speleoloc/services/beacon/shared_ble_scan.dart';
import 'package:speleoloc/services/ruuvi/ruuvi_advertisement_parser.dart';

/// One decoded Ruuvi advertisement observation.
class RuuviSighting {
  final RuuviAdvertisement advertisement;

  /// `RUUVI/<MAC>` — never null (payloads without a MAC are dropped).
  final String identity;

  /// Handle for a later GATT connection (history download); on iOS this is
  /// the only way to reach the peripheral, since the OS hides real MACs.
  final fbp.BluetoothDevice device;

  final int rssi;
  final DateTime seenAt;

  const RuuviSighting({
    required this.advertisement,
    required this.identity,
    required this.device,
    required this.rssi,
    required this.seenAt,
  });
}

/// Shared Ruuvi advertisement source. Consumers — picker, live view,
/// detection — listen to [sightings]; the BLE scan runs while at least one
/// listener is attached (the broadcast controller's onListen/onCancel
/// ref-count it), so the radio is only busy when something actually wants
/// Ruuvi frames.
///
/// A singleton because the underlying scanner is process-global static
/// state; wrapping it in per-consumer instances would only fake isolation.
/// Callers must run the permission/location gate (`BeaconScanHelper`)
/// before listening — this service never prompts.
class RuuviScanService {
  RuuviScanService({SharedBleScan? scan})
    : _scan = scan ?? SharedBleScan.instance;
  static final RuuviScanService instance = RuuviScanService();

  final SharedBleScan _scan;
  StreamSubscription<fbp.ScanResult>? _scanSub;
  late final StreamController<RuuviSighting> _controller =
      StreamController.broadcast(onListen: _start, onCancel: _stop);

  /// Decoded sightings of every Ruuvi tag in radio range, one event per
  /// received advertisement.
  Stream<RuuviSighting> get sightings => _controller.stream;

  void _start() {
    _scanSub ??= _scan.advertisements().listen(
      _onAdvertisement,
      onError: _controller.addError,
    );
  }

  void _onAdvertisement(fbp.ScanResult r) {
    final adv = RuuviAdvertisement.fromManufacturerData(
      r.advertisementData.manufacturerData,
    );
    final identity = adv?.identity;
    if (adv == null || identity == null) return;
    _controller.add(
      RuuviSighting(
        advertisement: adv,
        identity: identity,
        device: r.device,
        rssi: r.rssi,
        seenAt: r.timeStamp,
      ),
    );
  }

  Future<void> _stop() async {
    final sub = _scanSub;
    _scanSub = null;
    await sub?.cancel();
  }
}
