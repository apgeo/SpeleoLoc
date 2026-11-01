import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/cave_model/model_splay_offset.dart';
import 'package:speleoloc/services/cave_model/model_viewer_command.dart';
import 'package:speleoloc/services/cave_model/model_viewer_event.dart';

/// The app's half of the protocol `assets/caveview/host/bridge.js` speaks; the
/// page's half is exercised by `tool/caveview/host_page_check.mjs`.
void main() {
  group('ModelViewerEvent.decode', () {
    test('reads each message the page sends', () {
      final ready = ModelViewerEvent.decode(
        '{"v":1,"type":"ready","engine":"caveview","engineVersion":"2.9.0-slx.22"}',
      );
      expect(ready, isA<ModelViewerReady>());
      expect((ready! as ModelViewerReady).engineVersion, '2.9.0-slx.22');

      final loaded = ModelViewerEvent.decode(
        '{"v":1,"type":"loaded","stations":11}',
      );
      expect((loaded! as ModelViewerLoaded).stations, 11);

      final failed = ModelViewerEvent.decode(
        '{"v":1,"type":"error","code":"load","message":"bad file"}',
      );
      expect((failed! as ModelViewerFailed).code, 'load');

      final tapped =
          ModelViewerEvent.decode(
                '{"v":1,"type":"stationTapped","station":"cave.main.3",'
                '"x":15.5,"y":-7,"z":-4.7}',
              )
              as ModelViewerStationTapped;
      expect(tapped.station, 'cave.main.3');
      expect(tapped.y, -7.0);
    });

    test('reads the marks, station, splay and trail answers', () {
      final info =
          ModelViewerEvent.decode(
                '{"v":1,"type":"stationInfo","station":"a.3","x":1,"y":2,"z":3,'
                '"splays":[[1.5,-0.25,2],[0,1],"x"]}',
              )
              as ModelStationInfo;
      expect(info.splays, [const ModelSplayOffset(1.5, -0.25, 2)]);

      final picked =
          ModelViewerEvent.decode(
                '{"v":1,"type":"splayPicked","station":"a.3","offset":[1,2,3]}',
              )
              as ModelSplayPicked;
      expect(picked.offset, const ModelSplayOffset(1, 2, 3));
      expect(
        ModelViewerEvent.decode(
          '{"v":1,"type":"splayPicked","station":"a.3","offset":[1]}',
        ),
        isNull,
      );

      final tapped =
          ModelViewerEvent.decode('{"v":1,"type":"markTapped","ids":["p1",2]}')
              as ModelMarkTapped;
      expect(tapped.ids, ['p1']);

      final trail =
          ModelViewerEvent.decode(
                '{"v":1,"type":"trailInfo","id":"t","lengthM":42.5,"gaps":0,'
                '"atLength":[0,12.5,42.5]}',
              )
              as ModelTrailInfo;
      expect(trail.lengthMetres, 42.5);
      expect(trail.atLength, [0, 12.5, 42.5]);
    });

    test('drops what is not a message of this protocol', () {
      for (final text in [
        'not json',
        '[]',
        '{"type":"loaded","stations":1}',
        '{"v":2,"type":"loaded","stations":1}',
        '{"v":1,"type":"somethingNew"}',
        '{"v":1,"type":"stationTapped"}',
      ]) {
        expect(ModelViewerEvent.decode(text), isNull, reason: text);
      }
    });
  });

  group('ModelViewerCommand.encode', () {
    test('writes marks with their splay offsets', () {
      expect(
        jsonDecode(
          const SetModelMarks([
            ModelMark(
              id: 'p1',
              station: 'a.3',
              label: 'Lake',
              color: '#ff9800',
            ),
            ModelMark(
              id: 'p2',
              station: 'a.4',
              label: 'Window',
              color: '#ff9800',
              offset: ModelSplayOffset(1, 2, 3),
            ),
          ]).encode(),
        ),
        {
          'v': 1,
          'type': 'setMarks',
          'marks': [
            {'id': 'p1', 'station': 'a.3', 'label': 'Lake', 'color': '#ff9800'},
            {
              'id': 'p2',
              'station': 'a.4',
              'offset': [1.0, 2.0, 3.0],
              'label': 'Window',
              'color': '#ff9800',
            },
          ],
        },
      );
    });

    test('writes the commands the page runs', () {
      expect(jsonDecode(const SetModelView(ModelView.north).encode()), {
        'v': 1,
        'type': 'setView',
        'view': 'north',
      });
      expect(
        jsonDecode(const FocusModelStation('a.b.3', spanMetres: 30).encode()),
        {'v': 1, 'type': 'focusStation', 'station': 'a.b.3', 'span': 30.0},
      );
      expect(jsonDecode(const FocusModelStation('a.b.3').encode()), {
        'v': 1,
        'type': 'focusStation',
        'station': 'a.b.3',
      });
    });
  });
}
