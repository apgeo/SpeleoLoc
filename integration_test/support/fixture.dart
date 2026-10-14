import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/beacon/beacon_repository.dart';
import 'package:speleoloc/services/service_locator.dart';

/// Handles on whatever data the device holds, for screens that need an
/// object to open on.
///
/// Chosen by position, never by name: the first cave, its first entrance,
/// its first drawing. That keeps everything built on this blind to what
/// the data says, so the same sweep runs on the invented fixture, on an
/// anonymized dataset, or on one that must not be looked at.
class Fx {
  Fx._(this.db, this.docsDir);

  final AppDatabase db;
  final String docsDir;

  Cave? cave;
  List<Cave> caves = const [];
  CaveArea? area;
  List<CavePlace> places = const [];
  CavePlace? entrance;
  CavePlace? place;
  RasterMap? map;
  List<CavePlaceWithDefinition> placesOnMap = const [];
  CavePlaceToRasterMapDefinition? definition;
  CaveTrip? endedTrip;
  CaveTrip? openTrip;
  DocumentationFile? photo;
  DocumentationFile? textDoc;
  BeaconWithPlace? beacon;
  CavePlaceBeacon? ruuvi;

  static Future<Fx> load() async {
    final db = rootContainer.read(appDatabaseProvider);
    final docs = await getApplicationDocumentsDirectory();
    final fx = Fx._(db, docs.path);

    fx.caves =
        await (db.select(db.caves)
              ..where((c) => c.deletedAt.isNull())
              ..orderBy([(c) => OrderingTerm.asc(c.title)]))
            .get();
    final cave = fx.cave = fx.caves.isEmpty ? null : fx.caves.first;
    if (cave == null) return fx;

    fx.area =
        await (db.select(db.caveAreas)
              ..where(
                (a) => a.caveUuid.equalsValue(cave.uuid) & a.deletedAt.isNull(),
              )
              ..orderBy([(a) => OrderingTerm.asc(a.title)])
              ..limit(1))
            .getSingleOrNull();
    fx.places =
        await (db.select(db.cavePlaces)
              ..where(
                (p) => p.caveUuid.equalsValue(cave.uuid) & p.deletedAt.isNull(),
              )
              ..orderBy([(p) => OrderingTerm.asc(p.title)]))
            .get();
    fx.entrance = fx.places.where((p) => p.isEntrance == 1).firstOrNull;
    fx.place =
        fx.places.where((p) => p.isEntrance != 1).firstOrNull ?? fx.entrance;

    fx.map =
        await (db.select(db.rasterMaps)
              ..where(
                (m) => m.caveUuid.equalsValue(cave.uuid) & m.deletedAt.isNull(),
              )
              ..orderBy([(m) => OrderingTerm.asc(m.orderIndex)])
              ..limit(1))
            .getSingleOrNull();
    final map = fx.map;
    if (map != null) {
      final definitions =
          await (db.select(db.cavePlaceToRasterMapDefinitions)..where(
                (d) =>
                    d.rasterMapUuid.equalsValue(map.uuid) &
                    d.deletedAt.isNull(),
              ))
              .get();
      final byPlace = {for (final d in definitions) d.cavePlaceUuid: d};
      fx.placesOnMap = [
        for (final p in fx.places) CavePlaceWithDefinition(p, byPlace[p.uuid]),
      ];
      fx.definition = fx.place == null ? null : byPlace[fx.place!.uuid];
    }

    final trips =
        await (db.select(db.caveTrips)
              ..where(
                (t) => t.caveUuid.equalsValue(cave.uuid) & t.deletedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.tripStartedAt)]))
            .get();
    fx.endedTrip = trips.where((t) => t.tripEndedAt != null).firstOrNull;
    fx.openTrip = trips.where((t) => t.tripEndedAt == null).firstOrNull;

    final documents =
        await (db.select(db.documentationFiles)
              ..where((d) => d.deletedAt.isNull())
              ..orderBy([(d) => OrderingTerm.asc(d.title)]))
            .get();
    bool onDisk(DocumentationFile d) => fx.fileOf(d).existsSync();
    fx.photo = documents
        .where((d) => d.fileType == 'photo' && onDisk(d))
        .firstOrNull;
    fx.textDoc = documents
        .where((d) => d.fileType == 'text_document' && onDisk(d))
        .firstOrNull;

    final beacons =
        await (db.select(db.cavePlaceBeacons)
              ..where((b) => b.deletedAt.isNull())
              ..orderBy([(b) => OrderingTerm.asc(b.beaconType)]))
            .get();
    final first = beacons.firstOrNull;
    if (first != null) {
      final at = await (db.select(
        db.cavePlaces,
      )..where((p) => p.uuid.equalsValue(first.cavePlaceUuid))).getSingle();
      fx.beacon = BeaconWithPlace(
        beacon: first,
        cavePlace: at,
        caveTitle: cave.title,
      );
    }
    fx.ruuvi = beacons
        .where((b) => b.beaconType == 'ruuvi' && b.macAddress != null)
        .firstOrNull;
    return fx;
  }

  File fileOf(DocumentationFile doc) =>
      File('$docsDir/documentation_files/${doc.fileName}');
}
