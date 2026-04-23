import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/uuid.dart';

class TestDataHelper {
  static final _log = AppLogger.of('TestDataHelper');

  static Future<void> populateTestData(AppDatabase db) async {
    final stopwatch = Stopwatch()..start();
    _log.info('Starting populateTestData...');

    try {
      await db.transaction(() async {
        // ---------- Caves ----------
        final cave1Uuid = Uuid.v7();
        final cave2Uuid = Uuid.v7();
        final cave3Uuid = Uuid.v7();
        await db.into(db.caves).insert(CavesCompanion.insert(
              uuid: cave1Uuid,
              title: 'P. Ponorul Suspendat',
            ));
        await db.into(db.caves).insert(CavesCompanion.insert(
              uuid: cave2Uuid,
              title: 'P. Ponorul Nou',
            ));
        await db.into(db.caves).insert(CavesCompanion.insert(
              uuid: cave3Uuid,
              title: 'P. Gaura cu Vâjgău',
            ));

        // ---------- Cave areas ----------
        Future<Uuid> insertArea(String title, Uuid caveUuid) async {
          final u = Uuid.v7();
          await db.into(db.caveAreas).insert(CaveAreasCompanion.insert(
                uuid: u,
                title: title,
                caveUuid: caveUuid,
              ));
          return u;
        }

        final area1Uuid = await insertArea('Galeria Cascadelor', cave1Uuid);
        final area2Uuid = await insertArea('Colectorul Mare', cave1Uuid);
        final area3Uuid = await insertArea('Zona nord', cave1Uuid);
        final area4Uuid = await insertArea('verticale intrare', cave2Uuid);
        final area5Uuid = await insertArea('activ', cave2Uuid);

        int generateRandomQr(Random r) => r.nextInt(100000000);
        final rand = Random();

        // ---------- Cave places ----------
        Future<Uuid> insertPlace(String title, Uuid caveUuid) async {
          final u = Uuid.v7();
          await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(
                uuid: u,
                title: title,
                caveUuid: caveUuid,
                placeQrCodeIdentifier: Value(generateRandomQr(rand)),
              ));
          return u;
        }

        final cavePlace1Uuid = await insertPlace('Intrare', cave1Uuid);
        final cavePlace2Uuid = await insertPlace('S. Sorbului', cave1Uuid);
        final cavePlace3Uuid =
            await insertPlace('S. Colectorului Mic', cave1Uuid);
        final cavePlace4Uuid = await insertPlace('Trifurcație', cave1Uuid);
        final cavePlace5Uuid =
            await insertPlace('G. Gorjului - intrare', cave1Uuid);
        final cavePlace6Uuid =
            await insertPlace('G. Uriașilor - sub ', cave1Uuid);
        final cavePlace7Uuid =
            await insertPlace('Lacul Purificării - capăt sudic', cave1Uuid);
        final cavePlace8Uuid =
            await insertPlace('Lacul Purificării - capăt nordic', cave1Uuid);

        final cavePlace10Uuid = await insertPlace('Intrare', cave2Uuid);
        final cavePlace11Uuid =
            await insertPlace('Capat puturi principale - sus', cave2Uuid);
        final cavePlace12Uuid =
            await insertPlace('Baza puturi principale - jos', cave2Uuid);
        final cavePlace13Uuid = await insertPlace(
            'Galeria Condamnatilor - baza put acces', cave2Uuid);
        final cavePlace14Uuid =
            await insertPlace('Galeria Condamnatilor - intrare', cave2Uuid);
        final cavePlace15Uuid = await insertPlace('cascada 1', cave2Uuid);
        final cavePlace16Uuid = await insertPlace('cascada 2', cave2Uuid);

        final cavePlace17Uuid = await insertPlace('Intrare', cave3Uuid);
        final cavePlace18Uuid = await insertPlace('La lift', cave3Uuid);
        final cavePlace19Uuid =
            await insertPlace('Sala mare intrare', cave3Uuid);
        final cavePlace20Uuid = await insertPlace('La scara', cave3Uuid);
        final cavePlace21Uuid = await insertPlace('maini curente', cave3Uuid);
        final cavePlace22Uuid =
            await insertPlace('intrare pe activ', cave3Uuid);
        final cavePlace23Uuid =
            await insertPlace('baza puturi activ', cave3Uuid);

        // Reference so unused analysis doesn't complain
        final _ = [area1Uuid, area2Uuid, area3Uuid, area4Uuid, area5Uuid];

        // ---------- Surface places ----------
        final surface2Uuid = Uuid.v7();
        await db.into(db.surfacePlaces).insert(SurfacePlacesCompanion.insert(
              uuid: Uuid.v7(),
              title: 'Parking Lot',
              description: Value('Main parking area'),
              type: Value('parking'),
              latitude: Value(45.0),
              longitude: Value(2.0),
            ));
        await db.into(db.surfacePlaces).insert(SurfacePlacesCompanion.insert(
              uuid: surface2Uuid,
              title: 'Entrance Access',
              description: Value('Path to cave entrance'),
              type: Value('access'),
              latitude: Value(45.0),
              longitude: Value(2.0),
            ));

        // ---------- Cave entrances ----------
        await db.into(db.caveEntrances).insert(CaveEntrancesCompanion.insert(
              uuid: Uuid.v7(),
              caveUuid: cave1Uuid,
              surfacePlaceUuid: Value(surface2Uuid),
              isMainEntrance: Value(1),
              title: Value('Main Entrance'),
            ));

        // ---------- Raster maps ----------
        final assetDir = 'test_data/maps';
        final Map<String, Uuid> assetFiles = {
          'ps_20250107_explorari_plan_fundal_negru.jpg': cave1Uuid,
          'ps_plan_1_distanta_avenul_din_drum.jpg': cave1Uuid,
          'ps_profil_proiectat_ortogonal_est_vest_fundalalb.png': cave1Uuid,
          'cerna_ps_pn_pdp_plan_en_articol.jpg': cave1Uuid,
          'geo_art_tirla_ps__harta_profil.png': cave1Uuid,
          'Ponorul Nou - zona intrare.jpg': cave2Uuid,
          'Ponorul Nou - zona intrare_nordata.jpg': cave2Uuid,
          'Ponorul Nou_curatat.jpg': cave2Uuid,
          '1997 Harta P.Gaura cu Vajgau 2.jpg': cave3Uuid,
        };

        final documents = await getApplicationDocumentsDirectory();

        Future<Uuid> addRasterForCave(
          Uuid caveUuid,
          Uuid cavePlaceUuid,
          String assetFile,
          List<Uuid> places, {
          Uuid? caveAreaUuid,
        }) async {
          ByteData data;
          Uint8List bytes;
          try {
            data = await rootBundle.load('$assetDir/$assetFile');
            bytes = data.buffer.asUint8List();
          } catch (e) {
            final repoPath =
                p.join(Directory.current.path, 'test_data', 'maps', assetFile);
            final repoFile = File(repoPath);
            if (await repoFile.exists()) {
              bytes = await repoFile.readAsBytes();
            } else {
              rethrow;
            }
          }

          final subfolder = Directory('${documents.path}/cave_$caveUuid');
          if (!await subfolder.exists()) await subfolder.create(recursive: true);
          final ext = p.extension(assetFile);
          final fileName =
              'raster_${DateTime.now().millisecondsSinceEpoch}$ext';
          final savedPath = p.join(subfolder.path, fileName);
          final file = File(savedPath);
          await file.writeAsBytes(bytes, flush: true);

          final rasterUuid = Uuid.v7();
          await db.into(db.rasterMaps).insert(RasterMapsCompanion.insert(
                uuid: rasterUuid,
                title: assetFile,
                mapType: 'plane view',
                fileName: 'cave_$caveUuid/$fileName',
                caveUuid: caveUuid,
                caveAreaUuid: caveAreaUuid == null
                    ? const Value.absent()
                    : Value(caveAreaUuid),
              ));

          try {
            Map<String, int>? getImageDimensions(Uint8List data) {
              if (data.length >= 24) {
                if (data[0] == 0x89 &&
                    data[1] == 0x50 &&
                    data[2] == 0x4E &&
                    data[3] == 0x47 &&
                    data[4] == 0x0D &&
                    data[5] == 0x0A &&
                    data[6] == 0x1A &&
                    data[7] == 0x0A) {
                  final bd = data.buffer.asByteData();
                  try {
                    final w = bd.getUint32(16);
                    final h = bd.getUint32(20);
                    return {'width': w, 'height': h};
                  } catch (_) {
                    return null;
                  }
                }
              }
              if (data.length >= 2 && data[0] == 0xFF && data[1] == 0xD8) {
                int offset = 2;
                final bd = data.buffer.asByteData();
                while (offset + 1 < data.length) {
                  if (data[offset] != 0xFF) {
                    offset++;
                    continue;
                  }
                  int marker = data[offset + 1];
                  if ((marker >= 0xC0 && marker <= 0xCF) &&
                      marker != 0xC4 &&
                      marker != 0xC8 &&
                      marker != 0xCC) {
                    try {
                      final height = bd.getUint16(offset + 5);
                      final width = bd.getUint16(offset + 7);
                      return {'width': width, 'height': height};
                    } catch (_) {
                      return null;
                    }
                  } else {
                    try {
                      final blockLen = bd.getUint16(offset + 2);
                      offset += 2 + blockLen;
                    } catch (_) {
                      break;
                    }
                  }
                }
              }
              if (data.length >= 10 &&
                  data[0] == 0x47 &&
                  data[1] == 0x49 &&
                  data[2] == 0x46) {
                final bd = data.buffer.asByteData();
                try {
                  final w = bd.getUint16(6, Endian.little);
                  final h = bd.getUint16(8, Endian.little);
                  return {'width': w, 'height': h};
                } catch (_) {
                  return null;
                }
              }
              return null;
            }

            final dims = getImageDimensions(bytes);
            final maxX = dims?['width'] ?? 1000;
            final maxY = dims?['height'] ?? 1000;

            for (final placeUuid in places) {
              int probability = rand.nextInt(100) + 1;
              if (probability <= 75) {
                final x = rand.nextInt(maxX.clamp(1, 10000));
                final y = rand.nextInt(maxY.clamp(1, 10000));
                await db
                    .into(db.cavePlaceToRasterMapDefinitions)
                    .insert(CavePlaceToRasterMapDefinitionsCompanion.insert(
                      uuid: Uuid.v7(),
                      xCoordinate: Value(x),
                      yCoordinate: Value(y),
                      cavePlaceUuid: placeUuid,
                      rasterMapUuid: rasterUuid,
                    ));
              }
            }
          } catch (_) {}

          // Reference unused placeholder
          final ignored = cavePlaceUuid;
          return rasterUuid == ignored ? rasterUuid : rasterUuid;
        }

        final cavesAndPlaces = <Map<String, Object>>[
          {
            'caveUuid': cave1Uuid,
            'places': <Uuid>[
              cavePlace1Uuid,
              cavePlace2Uuid,
              cavePlace3Uuid,
              cavePlace4Uuid,
              cavePlace5Uuid,
              cavePlace6Uuid,
              cavePlace7Uuid,
              cavePlace8Uuid,
            ],
          },
          {
            'caveUuid': cave2Uuid,
            'places': <Uuid>[
              cavePlace10Uuid,
              cavePlace11Uuid,
              cavePlace12Uuid,
              cavePlace13Uuid,
              cavePlace14Uuid,
              cavePlace15Uuid,
              cavePlace16Uuid,
            ],
          },
          {
            'caveUuid': cave3Uuid,
            'places': <Uuid>[
              cavePlace17Uuid,
              cavePlace18Uuid,
              cavePlace19Uuid,
              cavePlace20Uuid,
              cavePlace21Uuid,
              cavePlace22Uuid,
              cavePlace23Uuid,
            ],
          },
        ];

        for (var ci = 0; ci < cavesAndPlaces.length; ci++) {
          final entry = cavesAndPlaces[ci];
          final places = (entry['places']! as List).cast<Uuid>();
          final entryCaveUuid = entry['caveUuid']! as Uuid;
          for (final assetEntry in assetFiles.entries) {
            final assetFile = assetEntry.key;
            final assetCaveUuid = assetEntry.value;
            if (assetCaveUuid == entryCaveUuid) {
              await addRasterForCave(
                  assetCaveUuid, places[ci], assetFile, places,
                  caveAreaUuid: null);
            }
          }
        }

        // ---------- Configurations ----------
        await db.into(db.configurations).insert(ConfigurationsCompanion.insert(
              title: 'version',
              value: Value('1.0'),
            ));
      });
    } catch (e, stackTrace) {
      _log.info('ERROR during populateTestData: $e');
      _log.info('Stack trace: $stackTrace');
      rethrow;
    } finally {
      stopwatch.stop();
      _log.info(
          'populateTestData completed in ${stopwatch.elapsedMilliseconds} ms');
    }
  }
}
