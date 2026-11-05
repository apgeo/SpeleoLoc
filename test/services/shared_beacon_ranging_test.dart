import 'dart:async';

import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/beacon/shared_beacon_ranging.dart';

const _uuidA = 'AAAAAAAA-0000-0000-0000-000000000001';
const _uuidB = 'BBBBBBBB-0000-0000-0000-000000000002';

/// Stands in for the plugin's single ranging channel: one native session at
/// a time, recording the regions of each start and every stop.
class _FakeNativeRanging {
  final List<List<String>> startedRegionIds = [];
  int stopCount = 0;
  StreamController<RangingResult>? _session;

  bool get isRanging => _session != null;

  Stream<RangingResult> start(List<Region> regions) {
    startedRegionIds.add([for (final r in regions) r.identifier]);
    late final StreamController<RangingResult> session;
    session = StreamController<RangingResult>(
      onCancel: () {
        stopCount++;
        if (identical(_session, session)) _session = null;
      },
    );
    _session = session;
    return session.stream;
  }

  void deliver(String regionId) {
    _session!.add(
      RangingResult.from({
        'region': {'identifier': regionId},
        'beacons': <dynamic>[],
      }),
    );
  }
}

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _FakeNativeRanging native;

  SharedBeaconRanging rangingWith(List<Region> Function(List<String>) build) =>
      SharedBeaconRanging(startRanging: native.start, buildRegions: build);

  // Android ranges every iBeacon in one wildcard region.
  List<Region> androidRegions(List<String> _) => [
    Region(identifier: 'speleoloc-all'),
  ];

  // iOS needs one region per proximity UUID.
  List<Region> iosRegions(List<String> uuids) => [
    for (final u in uuids) Region(identifier: 'speleoloc-$u'),
  ];

  setUp(() => native = _FakeNativeRanging());

  test('a screen that ranges for a while leaves detection ranging', () async {
    final hub = rangingWith(androidRegions);
    final detection = <RangingResult>[];
    final detectionSub = hub.ranging([_uuidA]).listen(detection.add);
    await _settle();

    // The beacon picker opens and closes.
    final pickerSub = hub.ranging([_uuidA]).listen((_) {});
    await _settle();
    native.deliver('speleoloc-all');
    await _settle();
    await pickerSub.cancel();
    await _settle();

    expect(native.isRanging, isTrue);
    expect(native.stopCount, 0);
    native.deliver('speleoloc-all');
    await _settle();
    expect(detection, hasLength(2));
    await detectionSub.cancel();
  });

  test('ranges the regions every listener needs, then narrows back', () async {
    final hub = rangingWith(iosRegions);
    final detectionSub = hub.ranging([_uuidA]).listen((_) {});
    await _settle();
    expect(native.startedRegionIds.last, ['speleoloc-$_uuidA']);

    final labSub = hub.ranging([_uuidB.toLowerCase()]).listen((_) {});
    await _settle();
    expect(native.startedRegionIds.last, [
      'speleoloc-$_uuidA',
      'speleoloc-$_uuidB',
    ]);

    await labSub.cancel();
    await _settle();
    expect(native.isRanging, isTrue);
    expect(native.startedRegionIds.last, ['speleoloc-$_uuidA']);
    await detectionSub.cancel();
  });

  test('stops native ranging when the last listener leaves', () async {
    final hub = rangingWith(androidRegions);
    final sub = hub.ranging([_uuidA]).listen((_) {});
    await _settle();
    expect(native.isRanging, isTrue);

    await sub.cancel();
    await _settle();
    expect(native.isRanging, isFalse);
  });

  test('restart opens a new native session for the same listeners', () async {
    final hub = rangingWith(androidRegions);
    final results = <RangingResult>[];
    final sub = hub.ranging([_uuidA]).listen(results.add);
    await _settle();

    await hub.restart();
    await _settle();
    expect(native.startedRegionIds, hasLength(2));
    native.deliver('speleoloc-all');
    await _settle();
    expect(results, hasLength(1));
    await sub.cancel();
  });
}
