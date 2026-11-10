import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sync_device.dart';

/// An archive is one snapshot of the device: an edit made while the export
/// reads the tables lands wholly before it or wholly after it, never between
/// two tables.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  setUp(() async => tmp = await Directory.systemTemp.createTemp('snapshot_'));
  tearDown(() async => tmp.delete(recursive: true));

  test('a place deleted while the export runs is not sent alive beside its '
      'own deletion', () async {
    final trigger = _OnSelect('FROM "cave_places"');
    final a = await SyncTestDevice.create(
      executor: NativeDatabase.memory().interceptWith(trigger),
    );
    addTearDown(a.dispose);

    final cave = await a.caves.addCave('Invented Cave');
    await a.places.addCavePlace(cave, 'Doomed');
    final place = await a.placeUuid(cave, 'Doomed');

    // The caver deletes the place the moment the export has read the places.
    Future<void>? deletion;
    trigger.action = () => deletion = a.places.deleteCavePlace(place);

    final zip = await a.export(tmp, 'a.zip');
    await deletion;
    expect(deletion, isNotNull, reason: 'the export reads the places table');

    final archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
    List<Map<String, dynamic>> rows(String name) => <Map<String, dynamic>>[
      for (final line in const LineSplitter().convert(
        utf8.decode(archive.findFile(name)!.content as List<int>),
      ))
        if (line.trim().isNotEmpty) jsonDecode(line) as Map<String, dynamic>,
    ];
    final carried = rows(
      'tables/cave_places.jsonl',
    ).any((r) => r['uuid'] == place.toString());
    final tombstoned = rows(
      'change_log.jsonl',
    ).any((r) => r['entity_uuid'] == place.toString() && r['change_type'] == 3);
    expect(
      carried && tombstoned,
      isFalse,
      reason: 'the archive carries the place alive and its deletion',
    );
  });
}

/// Runs [action] once, the first time a SELECT containing [marker] is sent.
class _OnSelect extends QueryInterceptor {
  _OnSelect(this.marker);

  final String marker;
  void Function()? action;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    final run = action;
    if (run != null && statement.contains(marker)) {
      action = null;
      // Outside the zone of the statement being run, as another screen's
      // write would be: inside it, drift would nest the write in the
      // export's own transaction.
      Zone.root.run(run);
    }
    return executor.runSelect(statement, args);
  }
}
