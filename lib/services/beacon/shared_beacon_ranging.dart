import 'dart:async';

import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:speleoloc/services/beacon/beacon_scan_helper.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// The one owner of dchs_flutter_beacon's iBeacon ranging.
///
/// The plugin routes every `ranging()` stream through one platform channel:
/// a second listener takes the channel over and stops the first one's
/// ranging, and cancelling any of them stops ranging for all. So detection,
/// the beacon picker and Beacon Lab listen to [ranging] here instead; native
/// ranging runs while at least one of them listens, over the regions they
/// all need, and every result goes to every listener.
class SharedBeaconRanging {
  SharedBeaconRanging({
    Stream<RangingResult> Function(List<Region> regions)? startRanging,
    List<Region> Function(List<String> uuids)? buildRegions,
  }) : _startRanging = startRanging ?? flutterBeacon.ranging,
       _buildRegions = buildRegions ?? BeaconScanHelper.buildRegions;

  static final SharedBeaconRanging instance = SharedBeaconRanging();

  final Stream<RangingResult> Function(List<Region> regions) _startRanging;
  final List<Region> Function(List<String> uuids) _buildRegions;
  final _log = AppLogger.of('SharedBeaconRanging');

  final List<_RangingClient> _clients = [];
  StreamSubscription<RangingResult>? _native;
  List<String> _nativeRegionIds = const [];
  Future<void> _pending = Future.value();

  /// Ranging results while listened to. [proximityUuids] are the UUIDs this
  /// listener needs ranged (iOS ranges only listed UUIDs); results for other
  /// listeners' regions arrive too.
  Stream<RangingResult> ranging(List<String> proximityUuids) {
    late final _RangingClient client;
    final controller = StreamController<RangingResult>(
      onListen: () {
        _clients.add(client);
        unawaited(_reconcile());
      },
      onCancel: () {
        _clients.remove(client);
        return _reconcile();
      },
    );
    client = _RangingClient({
      for (final u in proximityUuids) u.toUpperCase(),
    }, controller);
    return controller.stream;
  }

  /// Restarts native ranging for the current listeners, for when Bluetooth
  /// comes back on: ranging opened while the adapter was off can stay
  /// silent.
  Future<void> restart() => _reconcile(force: true);

  Future<void> _reconcile({bool force = false}) {
    return _pending = _pending.then((_) => _apply(force)).catchError((
      Object e,
      StackTrace st,
    ) {
      _log.warning('Ranging update failed', e, st);
    });
  }

  Future<void> _apply(bool force) async {
    if (_clients.isEmpty) {
      await _stopNative();
      return;
    }
    final uuids = {for (final c in _clients) ...c.proximityUuids}.toList()
      ..sort();
    final regions = _buildRegions(uuids);
    final regionIds = [for (final r in regions) r.identifier];
    if (!force && _native != null && listEquals(regionIds, _nativeRegionIds)) {
      return;
    }
    await _stopNative();
    _nativeRegionIds = regionIds;
    _native = _startRanging(regions).listen(
      _fanOut,
      onError: (Object e, StackTrace st) {
        for (final c in List.of(_clients)) {
          c.controller.addError(e, st);
        }
      },
      onDone: () => _native = null,
    );
  }

  void _fanOut(RangingResult result) {
    for (final c in List.of(_clients)) {
      c.controller.add(result);
    }
  }

  Future<void> _stopNative() async {
    final native = _native;
    _native = null;
    _nativeRegionIds = const [];
    await native?.cancel();
  }
}

class _RangingClient {
  _RangingClient(this.proximityUuids, this.controller);

  final Set<String> proximityUuids;
  final StreamController<RangingResult> controller;
}
