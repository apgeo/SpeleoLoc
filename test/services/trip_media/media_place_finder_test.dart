import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/qr_code_lookup_service.dart';
import 'package:speleoloc/services/trip_media/device_library_media_source.dart';
import 'package:speleoloc/services/trip_media/media_place_finder.dart';
import 'package:speleoloc/services/trip_media/media_qr_detector.dart';
import 'package:speleoloc/services/trip_media/media_scan_cache.dart';
import 'package:speleoloc/services/trip_media/trip_media_item.dart';
import 'package:speleoloc/services/trip_media/trip_media_source.dart';

/// Decodes nothing: hands back whatever the test queued, and counts.
class _QueuedDetector extends MediaQrDetector {
  _QueuedDetector(super.lookup);

  final List<QrRead> reads = [];
  int calls = 0;

  @override
  Future<QrRead> readPayload(File file) async {
    calls++;
    return reads.removeAt(0);
  }
}

/// One picture, under a key the test controls.
class _OnePictureSource implements TripMediaSource {
  _OnePictureSource(this.key);

  String? key;

  @override
  Future<String?> scanKey(TripMediaItem item) async => key;

  @override
  Future<R?> withScanImage<R>(
    TripMediaItem item,
    Future<R?> Function(File file) use,
  ) => use(File('/unused'));

  @override
  String get id => 'test';
  @override
  bool get choosesItems => false;
  @override
  Future<int> chooseMore() async => 0;
  @override
  Future<List<TripMediaItem>> list({DateTime? from, DateTime? to}) async =>
      const [];
  @override
  Future<Uint8List?> thumbnail(TripMediaItem item, {int edge = 200}) async =>
      null;
  @override
  Future<File?> file(TripMediaItem item) async => null;
  @override
  Future<void> release() async {}
}

/// Opening the points-from-pictures screen again must not decode every
/// picture again: what each held is remembered — the label's whole text, or
/// that there was none — and only the match to a place is redone, because
/// places and their codes change in between.
void main() {
  late AppDatabase db;
  late _QueuedDetector detector;
  late MediaScanCache cache;
  late Uuid caveUuid;
  late Uuid entrance;

  final picture = TripMediaItem(
    id: 'asset-1',
    kind: TripMediaKind.photo,
    capturedAt: DateTime(2026, 10, 13, 10, 7),
    capturedAtSource: MediaTimeSource.library,
  );

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    detector = _QueuedDetector(QrCodeLookupService(db));
    cache = MediaScanCache(db);
    caveUuid = Uuid.v7();
    entrance = Uuid.v7();
    await db
        .into(db.caves)
        .insert(CavesCompanion.insert(uuid: caveUuid, title: 'Cave'));
    await db
        .into(db.cavePlaces)
        .insert(
          CavePlacesCompanion.insert(
            uuid: entrance,
            title: 'Entrance',
            caveUuid: caveUuid,
            placeCodeIdentifier: const Value('a1'),
          ),
        );
  });

  tearDown(() => db.close());

  MediaPlaceFinder finder() => MediaPlaceFinder(cache, detector);

  test('a picture is read once, then recognised', () async {
    final source = _OnePictureSource('library:1');
    detector.reads.add(const QrRead.found('a1'));

    final first = await finder().find(source, picture, caveUuid: caveUuid);
    final second = await finder().find(source, picture, caveUuid: caveUuid);

    expect(detector.calls, 1);
    expect(first.place?.uuid, entrance);
    expect(first.fromCache, isFalse);
    expect(second.place?.uuid, entrance);
    expect(second.fromCache, isTrue);
  });

  test('the whole raw payload is kept, not the part that matched', () async {
    final source = _OnePictureSource('library:1');
    const payload = 'https://example.invalid/scan?id=a1';
    detector.reads.add(const QrRead.found(payload));
    await finder().find(source, picture, caveUuid: caveUuid);
    expect((await cache.read('library:1'))!.payload, payload);
  });

  test(
    'the cached payload is matched against the places as they are now',
    () async {
      final source = _OnePictureSource('library:1');
      detector.reads.add(const QrRead.found('a1'));
      await finder().find(source, picture, caveUuid: caveUuid);

      // The code moves to another place between visits.
      await (db.update(db.cavePlaces)
            ..where((p) => p.uuid.equalsValue(entrance)))
          .write(const CavePlacesCompanion(placeCodeIdentifier: Value('z9')));
      final moved = Uuid.v7();
      await db
          .into(db.cavePlaces)
          .insert(
            CavePlacesCompanion.insert(
              uuid: moved,
              title: 'Chamber',
              caveUuid: caveUuid,
              placeCodeIdentifier: const Value('a1'),
            ),
          );

      final again = await finder().find(source, picture, caveUuid: caveUuid);
      expect(detector.calls, 1, reason: 'no second decode');
      expect(again.place?.uuid, moved);
    },
  );

  test('a picture with no label is remembered as having none', () async {
    final source = _OnePictureSource('library:1');
    detector.reads.add(const QrRead.none());
    await finder().find(source, picture, caveUuid: caveUuid);
    final again = await finder().find(source, picture, caveUuid: caveUuid);
    expect(detector.calls, 1);
    expect(again.place, isNull);
    expect(again.fromCache, isTrue);
  });

  test('a picture that could not be read is tried again next time', () async {
    final source = _OnePictureSource('library:1');
    detector.reads
      ..add(const QrRead.failed())
      ..add(const QrRead.found('a1'));
    expect(
      (await finder().find(source, picture, caveUuid: caveUuid)).place,
      isNull,
    );
    final again = await finder().find(source, picture, caveUuid: caveUuid);
    expect(detector.calls, 2);
    expect(again.place?.uuid, entrance);
  });

  test('without a key nothing is remembered', () async {
    final source = _OnePictureSource(null);
    detector.reads
      ..add(const QrRead.found('a1'))
      ..add(const QrRead.found('a1'));
    await finder().find(source, picture, caveUuid: caveUuid);
    await finder().find(source, picture, caveUuid: caveUuid);
    expect(detector.calls, 2);
  });

  test('a library picture\'s key changes when the picture does', () {
    String key({int modified = 100, int width = 4000}) =>
        DeviceLibraryMediaSource.scanKeyFor(
          id: '42',
          modifiedSecond: modified,
          width: width,
          height: 3000,
          title: 'IMG_1.jpg',
        );
    expect(key(), key());
    expect(key(modified: 200), isNot(key()), reason: 'edited');
    expect(key(width: 2000), isNot(key()), reason: 'cropped or resized');
  });
}
