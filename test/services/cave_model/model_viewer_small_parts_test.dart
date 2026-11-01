import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_model/model_mark_colours.dart';
import 'package:speleoloc/services/cave_model/model_splay_offset.dart';
import 'package:speleoloc/services/cave_model/model_viewer_settings.dart';
import 'package:speleoloc/services/location/last_located_place.dart';

void main() {
  test('settings default on, survive a round trip and ignore junk', () {
    const defaults = ModelViewerSettings();
    expect(defaults.stationMapping, isTrue);
    expect(defaults.markColourByArea, isFalse);
    expect(defaults.autoDownloadModels, isTrue);
    final changed = defaults.copyWith(stationMapping: false);
    expect(
      ModelViewerSettings.fromJson(changed.toJson()).stationMapping,
      isFalse,
    );
    final junk = ModelViewerSettings.fromJson({'stationMapping': 'no'});
    expect(junk.stationMapping, isTrue);
  });

  test('a fix of where the device is stands for half an hour', () {
    var now = DateTime(2026, 11, 1, 10);
    final last = LastLocatedPlace(now: () => now);
    expect(last.current, isNull);
    final place = Uuid.v7();
    last.record(place);
    now = now.add(const Duration(minutes: 29));
    expect(last.current, place);
    now = now.add(const Duration(minutes: 2));
    expect(last.current, isNull);
  });

  test('splay offsets match within ten centimetres', () {
    const a = ModelSplayOffset(1, 2, 3);
    expect(a.matches(const ModelSplayOffset(1.05, 1.95, 3.08)), isTrue);
    expect(a.matches(const ModelSplayOffset(1.2, 2, 3)), isFalse);
    expect(ModelSplayOffset.fromList([1, 2]), isNull);
  });

  test('each area keeps its colour whatever order the areas come in', () {
    CaveArea area(String title) =>
        CaveArea(uuid: Uuid.v7(), title: title, caveUuid: Uuid.v7());
    final b = area('B');
    final a = area('A');
    final first = ModelMarkColours.byArea([b, a]);
    final second = ModelMarkColours.byArea([a, b]);
    expect(first, second);
    expect(first[a.uuid], isNot(first[b.uuid]));
  });
}
