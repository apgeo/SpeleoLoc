import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/app_logger.dart';

class TestDataHelper {
  static final _log = AppLogger.of('TestDataHelper');

  static Future<void> populateTestData(AppDatabase db) async {
    final stopwatch = Stopwatch()..start();
    _log.info('Starting populateTestData...');
    
    try {
      // Use a transaction to wrap all inserts for better performance
      await db.transaction(() async {
        // Insert caves
        _log.info('Inserting caves...');
        final caveInsertStart = Stopwatch()..start();
        final cave1Id = await db.into(db.caves).insert(CavesCompanion.insert(title: 'P. Ponorul Suspendat'));
        final cave2Id = await db.into(db.caves).insert(CavesCompanion.insert(title: 'P. Ponorul Nou'));
        final cave3Id = await db.into(db.caves).insert(CavesCompanion.insert(title: 'P. Gaura cu Vâjgău'));
        caveInsertStart.stop();
        _log.info('Caves inserted in ${caveInsertStart.elapsedMilliseconds} ms');

        // Insert cave areas
        _log.info('Inserting cave areas...');
        final areaInsertStart = Stopwatch()..start();
        final area1Id = await db.into(db.caveAreas).insert(CaveAreasCompanion.insert(title: 'Galeria Cascadelor', caveId: cave1Id));
        final area2Id = await db.into(db.caveAreas).insert(CaveAreasCompanion.insert(title: 'Colectorul Mare', caveId: cave1Id));
        final area3Id = await db.into(db.caveAreas).insert(CaveAreasCompanion.insert(title: 'Zona nord', caveId: cave1Id));

        final area4Id = await db.into(db.caveAreas).insert(CaveAreasCompanion.insert(title: 'verticale intrare', caveId: cave2Id));
        final area5Id = await db.into(db.caveAreas).insert(CaveAreasCompanion.insert(title: 'activ', caveId: cave2Id));
        areaInsertStart.stop();
        _log.info('Cave areas inserted in ${areaInsertStart.elapsedMilliseconds} ms');

        // Local helper to generate random QR codes (0..99_999_999)
        int generateRandomQr(Random r) => r.nextInt(100000000);
        final rand = Random();

        // Insert cave places
        _log.info('Inserting cave places...');
        final placeInsertStart = Stopwatch()..start();
        final cavePlace1Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'Intrare', caveId: cave1Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        final cavePlace2Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'S. Sorbului', caveId: cave1Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        final cavePlace3Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'S. Colectorului Mic', caveId: cave1Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        final cavePlace4Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'Trifurcație', caveId: cave1Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        final cavePlace5Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'G. Gorjului - intrare', caveId: cave1Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        final cavePlace6Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'G. Uriașilor - sub ', caveId: cave1Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        final cavePlace7Id =await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'Lacul Purificării - capăt sudic', caveId: cave1Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        final cavePlace8Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'Lacul Purificării - capăt nordic', caveId: cave1Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));

        final cavePlace10Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'Intrare', caveId: cave2Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        final cavePlace11Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'Capat puturi principale - sus', caveId: cave2Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        final cavePlace12Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'Baza puturi principale - jos', caveId: cave2Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        final cavePlace13Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'Galeria Condamnatilor - baza put acces', caveId: cave2Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        final cavePlace14Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'Galeria Condamnatilor - intrare', caveId: cave2Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        final cavePlace15Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'cascada 1', caveId: cave2Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        final cavePlace16Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'cascada 2', caveId: cave2Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));

        final cavePlace17Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'Intrare', caveId: cave3Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        final cavePlace18Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'La lift', caveId: cave3Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        final cavePlace19Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'Sala mare intrare', caveId: cave3Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        final cavePlace20Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'La scara', caveId: cave3Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        final cavePlace21Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'maini curente', caveId: cave3Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        final cavePlace22Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'intrare pe activ', caveId: cave3Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        final cavePlace23Id = await db.into(db.cavePlaces).insert(CavePlacesCompanion.insert(title: 'baza puturi activ', caveId: cave3Id, placeQrCodeIdentifier: Value(generateRandomQr(rand))));
        placeInsertStart.stop();
        _log.info('Cave places inserted ($cavePlace1Id...$cavePlace23Id) in ${placeInsertStart.elapsedMilliseconds} ms');

        // Insert surface places
        _log.info('Inserting surface places...');
        final surfaceInsertStart = Stopwatch()..start();
        await db.into(db.surfacePlaces).insert(SurfacePlacesCompanion.insert(
          title: 'Parking Lot',
          description: Value('Main parking area'),
          type: Value('parking'),
          latitude: Value(45.0),
          longitude: Value(2.0),
        ));
        final surface2Id = await db.into(db.surfacePlaces).insert(SurfacePlacesCompanion.insert(
          title: 'Entrance Access',
          description: Value('Path to cave entrance'),
          type: Value('access'),
          latitude: Value(45.0),
          longitude: Value(2.0),
        ));
        surfaceInsertStart.stop();
        _log.info('Surface places inserted in ${surfaceInsertStart.elapsedMilliseconds} ms');

        // Insert cave entrances
        _log.info('Inserting cave entrances...');
        final entranceInsertStart = Stopwatch()..start();
        await db.into(db.caveEntrances).insert(CaveEntrancesCompanion.insert(
          caveId: cave1Id,
          surfacePlaceId: Value(surface2Id),
          isMainEntrance: Value(1),
          title: Value('Main Entrance'),
        ));
        entranceInsertStart.stop();
        _log.info('Cave entrances inserted in ${entranceInsertStart.elapsedMilliseconds} ms');

        // Insert raster maps
        _log.info('Starting raster maps population...');
        final rasterInsertStart = Stopwatch()..start();
        
        // Copy test maps from assets and insert raster maps (3 per cave)
        final assetDir = 'test_data/maps';
        final Map<String, int> assetFiles = {
          // Ponorul Suspendat (use files that actually exist in test_data/maps)
          'ps_20250107_explorari_plan_fundal_negru.jpg': cave1Id,
          'ps_plan_1_distanta_avenul_din_drum.jpg': cave1Id,
          'ps_profil_proiectat_ortogonal_est_vest_fundalalb.png': cave1Id,
          'cerna_ps_pn_pdp_plan_en_articol.jpg': cave1Id,
          'geo_art_tirla_ps__harta_profil.png': cave1Id,

          // Ponorul Nou
          'Ponorul Nou - zona intrare.jpg': cave2Id,
          'Ponorul Nou - zona intrare_nordata.jpg': cave2Id,
          'Ponorul Nou_curatat.jpg': cave2Id,

          // Gaura cu Vajgau
          '1997 Harta P.Gaura cu Vajgau 2.jpg': cave3Id,
        };

        final documents = await getApplicationDocumentsDirectory();
        // reuse existing Random instance defined above

        Future<int> addRasterForCave(int caveId, int cavePlaceId, String assetFile, List<int> places, {int? caveAreaId}) async {
          final addRasterForCaveStart = Stopwatch()..start();
          
          final loadAssetBytesStart = Stopwatch()..start();
          // Load asset bytes
          ByteData data;
          Uint8List bytes;
          try {
            data = await rootBundle.load('$assetDir/$assetFile');
            bytes = data.buffer.asUint8List();
          } catch (e) {
            // Fallback during development: try to read directly from the repo folder
            final repoPath = p.join(Directory.current.path, 'test_data', 'maps', assetFile);
            final repoFile = File(repoPath);
            if (await repoFile.exists()) {
              bytes = await repoFile.readAsBytes();
            } else {
              rethrow;
            }
          }
          
            loadAssetBytesStart.stop();
            _log.info('Loading asset $assetFile took ${loadAssetBytesStart.elapsedMilliseconds} ms');

            final saveFileStart = Stopwatch()..start();
            // Ensure cave folder exists
            final subfolder = Directory('${documents.path}/cave_$caveId');
            if (!await subfolder.exists()) await subfolder.create(recursive: true);

            // Save file with timestamped name preserving extension
            final ext = p.extension(assetFile);
            final fileName = 'raster_${DateTime.now().millisecondsSinceEpoch}$ext';
            final savedPath = p.join(subfolder.path, fileName);
            final file = File(savedPath);
            await file.writeAsBytes(bytes, flush: true);

            saveFileStart.stop();
            _log.info('Saving file $fileName took ${saveFileStart.elapsedMilliseconds} ms');
          

          final insertRasterMapRowStart = Stopwatch()..start();
          // Insert raster map row
          final rasterId = await db.into(db.rasterMaps).insert(RasterMapsCompanion.insert(
            title: assetFile,
            mapType: 'plane view',
            fileName: 'cave_$caveId/$fileName',
            caveId: caveId,
            caveAreaId: caveAreaId == null ? Value.absent() : Value(caveAreaId),
          ));

          insertRasterMapRowStart.stop();
          _log.info('Inserting raster map row for $assetFile took ${insertRasterMapRowStart.elapsedMilliseconds} ms');

          // Decode image to get dimensions
          try {
            final decodeImageStart = Stopwatch()..start();

            Map<String, int>? getImageDimensions(Uint8List data) {
              if (data.length >= 24) {
                // PNG: signature then IHDR with width/height at offset 16/20 (big-endian)
                if (data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47 && data[4] == 0x0D && data[5] == 0x0A && data[6] == 0x1A && data[7] == 0x0A) {
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
              // JPEG: search for SOF marker
              if (data.length >= 2 && data[0] == 0xFF && data[1] == 0xD8) {
                int offset = 2;
                final bd = data.buffer.asByteData();
                while (offset + 1 < data.length) {
                  if (data[offset] != 0xFF) {
                    offset++;
                    continue;
                  }
                  int marker = data[offset + 1];
                  // SOF0/1/2/3/5/6/7/9/10/11/13/14/15 markers indicate frame header with dims
                  if ((marker >= 0xC0 && marker <= 0xCF) && marker != 0xC4 && marker != 0xC8 && marker != 0xCC) {
                    try {
                      final height = bd.getUint16(offset + 5);
                      final width = bd.getUint16(offset + 7);
                      return {'width': width, 'height': height};
                    } catch (_) {
                      return null;
                    }
                  } else {
                    // Skip segment
                    try {
                      final blockLen = bd.getUint16(offset + 2);
                      offset += 2 + blockLen;
                    } catch (_) {
                      break;
                    }
                  }
                }
              }
              // GIF: width/height are little-endian at offsets 6 and 8
              if (data.length >= 10 && data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46) {
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

            // slow version (maybe for fallback or used for testing performance improvements of the faster method above):
            // final image = img.decodeImage(bytes);
            // final maxX = image?.width ?? 1000;
            // final maxY = image?.height ?? 1000;

            // Create a few definitions linking cavePlaceId to rasterId
            // final defsCount = 3 + rand.nextInt(3); // 3-5 definitions

            decodeImageStart.stop();
            _log.info('Reading image dims for $assetFile took ${decodeImageStart.elapsedMilliseconds} ms');

            final addCavePlaceToRasterMapDefinitionsStart = Stopwatch()..start();
 
            int definitionCount = 0;
            for (final cavePlaceId in places) {
                  //todo: add debug flag based probability addition
                  int probability = rand.nextInt(100) + 1;

                  if (probability <= 75) 
                  { // 75% chance to add a definition for this place
                    {
                      final x = rand.nextInt(maxX.clamp(1, 10000));
                      final y = rand.nextInt(maxY.clamp(1, 10000));

                      await db.into(db.cavePlaceToRasterMapDefinitions).insert(CavePlaceToRasterMapDefinitionsCompanion.insert(
                        xCoordinate: Value(x),
                        yCoordinate: Value(y),
                        cavePlaceId: cavePlaceId,
                        rasterMapId: rasterId,
                      ));

                      definitionCount++;
                    }
                  }
            }

            addCavePlaceToRasterMapDefinitionsStart.stop();
            _log.info('Adding cave place to raster map definition= ($definitionCount records) took ${addCavePlaceToRasterMapDefinitionsStart.elapsedMilliseconds} ms');
          } catch (_) {}
          
          addRasterForCaveStart.stop();
          _log.info('Added raster map for caveId $caveId with asset $assetFile in ${addRasterForCaveStart.elapsedMilliseconds} ms');
          return rasterId;
        }

        final cavesAndPlaces = [
          {'caveId': cave1Id, 'places': [cavePlace1Id, cavePlace2Id, cavePlace3Id, cavePlace4Id, cavePlace5Id, cavePlace6Id, cavePlace7Id, cavePlace8Id], 'areas': [area1Id, area2Id, area3Id]},
          {'caveId': cave2Id, 'places': [cavePlace10Id, cavePlace11Id, cavePlace12Id, cavePlace13Id, cavePlace14Id, cavePlace15Id, cavePlace16Id], 'areas': [area4Id, area5Id]},
          {'caveId': cave3Id, 'places': [cavePlace17Id, cavePlace18Id, cavePlace19Id, cavePlace20Id, cavePlace21Id, cavePlace22Id, cavePlace23Id], 'areas': <int?>[]},
        ];

        int rasterMapsAdded = 0;
        for (var ci = 0; ci < cavesAndPlaces.length; ci++) {
          final entry = cavesAndPlaces[ci];
          // final caveId = entry['caveId'] as int;
          final places = (entry['places'] as List).cast<int>();
          // final areas = (entry['areas'] as List).cast<int?>();

          for (final assetEntry in assetFiles.entries) {
            final assetFile = assetEntry.key;
            final assetCaveId = assetEntry.value;
            
            if (assetCaveId == entry['caveId'])
            {
              await addRasterForCave(assetCaveId, places[ci], assetFile, places, caveAreaId: null);
              rasterMapsAdded++;
              // small delay to vary timestamps
              // await Future.delayed(const Duration(milliseconds: 5));
            }
          }
        }
        rasterInsertStart.stop();
        _log.info('Raster maps population completed: $rasterMapsAdded maps added in ${rasterInsertStart.elapsedMilliseconds} ms');

        // Insert configurations
        _log.info('Inserting configurations...');
        final configInsertStart = Stopwatch()..start();
        await db.into(db.configurations).insert(ConfigurationsCompanion.insert(
          title: 'version',
          value: Value('1.0'),
        ));
        configInsertStart.stop();
        _log.info('Configurations inserted in ${configInsertStart.elapsedMilliseconds} ms');
      });
    } catch (e, stackTrace) {
      _log.info('ERROR during populateTestData: $e');
      _log.info('Stack trace: $stackTrace');
      rethrow;
    } finally {
      stopwatch.stop();
      _log.info('populateTestData completed in ${stopwatch.elapsedMilliseconds} ms');
    }
  }
}