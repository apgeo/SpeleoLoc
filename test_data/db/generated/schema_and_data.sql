PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "surface_areas" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL UNIQUE, "description" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER);
INSERT INTO surface_areas VALUES(1,'V. Cernei - sud',NULL,NULL,NULL,NULL);
INSERT INTO surface_areas VALUES(2,'Cheile Cernei',NULL,NULL,NULL,NULL);
INSERT INTO surface_areas VALUES(3,'Dl. Runcului',NULL,NULL,NULL,NULL);
INSERT INTO surface_areas VALUES(4,'V. Porcu',NULL,NULL,NULL,NULL);
INSERT INTO surface_areas VALUES(5,'Dl. Guguiova',NULL,NULL,NULL,NULL);
INSERT INTO surface_areas VALUES(6,'M. Zăvidanul - Dl. Piatra Lupului',NULL,NULL,NULL,NULL);
INSERT INTO surface_areas VALUES(7,'V. Comănii - P. Stanciului',NULL,NULL,NULL,NULL);
INSERT INTO surface_areas VALUES(8,'V. Comănii - V. Tigăilor',NULL,NULL,NULL,NULL);
INSERT INTO surface_areas VALUES(9,'Dl. Pleașa Lupșei - Poiana Pleșița',NULL,NULL,NULL,NULL);
INSERT INTO surface_areas VALUES(10,'Dl. Pleașa Lupșei',NULL,NULL,NULL,NULL);
INSERT INTO surface_areas VALUES(11,'Dl. Bulz',NULL,NULL,NULL,NULL);
INSERT INTO surface_areas VALUES(12,'Dl. Piciora',NULL,NULL,NULL,NULL);
INSERT INTO surface_areas VALUES(13,'Dl. Peștera',NULL,NULL,NULL,NULL);
CREATE TABLE IF NOT EXISTS "caves" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL UNIQUE, "description" TEXT, "surface_area_id" INTEGER REFERENCES surface_areas(id), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER);
INSERT INTO caves VALUES(1,'P. Ponorul Suspendat',NULL,1,NULL,NULL,NULL);
INSERT INTO caves VALUES(2,'P. Ponorul Nou',NULL,1,NULL,NULL,NULL);
INSERT INTO caves VALUES(3,'P. Gaura cu Vâjgău',NULL,NULL,NULL,NULL,NULL);
INSERT INTO caves VALUES(4,'Peștera Ascendentă din Guguiova',NULL,5,NULL,NULL,NULL);
INSERT INTO caves VALUES(5,'Peștera cu Săritoare din Guguiova',NULL,5,NULL,NULL,NULL);
INSERT INTO caves VALUES(6,'Peștera X1 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(7,'Peștera B1 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(8,'Peștera B2 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(9,'Peștera B3 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(10,'Peștera B4 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(11,'Peștera B5 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(12,'Peștera C1 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(13,'Peștera C2 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(14,'Peștera C3 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(15,'Peștera C4 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(16,'Peștera C5 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(17,'Peștera C6 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(18,'Peștera C7 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(19,'Peștera C8 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(20,'Peștera C9 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(21,'Peștera C9 din Piatra Lupului (Gaura cu Vâjagău)','Gaura cu Vâjagău',6,NULL,NULL,NULL);
INSERT INTO caves VALUES(22,'Peștera D1 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(23,'Peștera D2 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(24,'Peștera D3 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(25,'Peștera M1 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(26,'Peștera M2 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(27,'Peștera M3 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(28,'Peștera M4 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(29,'Avenul M5 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(30,'Avenul X2 din Piatra Lupului','Avenul cu Șiroaie',6,NULL,NULL,NULL);
INSERT INTO caves VALUES(31,'Peștera X3 din Piatra Lupului','Sodoale ?',6,NULL,NULL,NULL);
INSERT INTO caves VALUES(32,'Peștera X4 din Piatra Lupului','Sodoale ?',6,NULL,NULL,NULL);
INSERT INTO caves VALUES(33,'Peștera X6 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(34,'Peștera X7 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(35,'Peștera X8 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(36,'Peștera X9 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(37,'Peștera E1 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(38,'Peștera E3 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(39,'Peștera E4 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(40,'Peștera E5 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(41,'Peștera E6 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(42,'Peștera F1 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(43,'Peștera F2 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(44,'Peștera F3 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(45,'Peștera F4 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(46,'Peștera F5 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(47,'Peștera G1 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(48,'Peștera G2 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(49,'Peștera G3 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(50,'Peștera H1 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(51,'Peștera H2 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(52,'Peștera H3 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(53,'Peștera H4 din Piatra Lupului',NULL,6,NULL,NULL,NULL);
INSERT INTO caves VALUES(54,'Peștera din Dealul Glimea','P. Hotel',7,NULL,NULL,NULL);
INSERT INTO caves VALUES(55,'Peștera nr. 1 de la Fața Cerbului','P. din Dealul Cerbului / P. din Valea Tigăii',8,NULL,NULL,NULL);
INSERT INTO caves VALUES(56,'Peștera nr. 2 de la Fața Cerbului','Av. din Dealul Cerbului',8,NULL,NULL,NULL);
INSERT INTO caves VALUES(57,'Avenul nr. 3 din Poiana Pleșița','Av. de sub Păducel',9,NULL,NULL,NULL);
INSERT INTO caves VALUES(58,'Peștera Caroleștilor','P. din Grădina Carolești',10,NULL,NULL,NULL);
INSERT INTO caves VALUES(59,'Peștera nr. 2 din Dealul Bulz',NULL,11,NULL,NULL,NULL);
INSERT INTO caves VALUES(60,'Peștera "Hotel"','(duplicat)',12,NULL,NULL,NULL);
INSERT INTO caves VALUES(61,'Peștera de la Mal',NULL,13,NULL,NULL,NULL);
INSERT INTO caves VALUES(62,'Peștera nr. 1 din Bulz',NULL,11,NULL,NULL,NULL);
CREATE TABLE IF NOT EXISTS "cave_areas" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "cave_id" INTEGER REFERENCES caves(id), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER);
INSERT INTO cave_areas VALUES(1,'Galeria Cascadelor',NULL,1,NULL,NULL,NULL);
INSERT INTO cave_areas VALUES(2,'Colectorul Mare',NULL,1,NULL,NULL,NULL);
INSERT INTO cave_areas VALUES(3,'Zona nord',NULL,1,NULL,NULL,NULL);
INSERT INTO cave_areas VALUES(4,'verticale intrare',NULL,2,NULL,NULL,NULL);
INSERT INTO cave_areas VALUES(5,'activ',NULL,2,NULL,NULL,NULL);
INSERT INTO cave_areas VALUES(6,'intrare',NULL,3,NULL,NULL,NULL);
INSERT INTO cave_areas VALUES(7,'activ',NULL,3,NULL,NULL,NULL);
CREATE TABLE IF NOT EXISTS "surface_places" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "type" TEXT, "surface_place_qr_code_identifier" INTEGER DEFAULT NULL UNIQUE, "latitude" REAL, "longitude" REAL, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER);
INSERT INTO surface_places VALUES(1,'Parking Lot','Main parking area','parking',NULL,45.0,2.0,NULL,NULL,NULL);
INSERT INTO surface_places VALUES(2,'Entrance Access','Path to cave entrance','access',NULL,45.0,2.0,NULL,NULL,NULL);
CREATE TABLE IF NOT EXISTS "cave_entrances" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "cave_id" INTEGER NOT NULL REFERENCES caves(id), "surface_place_id" INTEGER NOT NULL REFERENCES surface_places(id), "is_main_entrance" INTEGER, "title" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER);
INSERT INTO cave_entrances VALUES(1,1,2,1,'Main Entrance',NULL,NULL,NULL);
CREATE TABLE IF NOT EXISTS "raster_maps" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL, "map_type" TEXT NOT NULL, "file_name" TEXT NOT NULL, "cave_id" INTEGER NOT NULL REFERENCES caves(id), "cave_area_id" INTEGER REFERENCES cave_areas(id), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER);
INSERT INTO raster_maps VALUES(1,'ps_20250107_explorari_plan_fundal_negru.jpg','plane view','cave_1/raster_1771183787549.jpg',1,NULL,NULL,NULL,NULL);
INSERT INTO raster_maps VALUES(2,'ps_plan_1_distanta_avenul_din_drum.jpg','plane view','cave_1/raster_1771183787566.jpg',1,NULL,NULL,NULL,NULL);
INSERT INTO raster_maps VALUES(3,'ps_profil_proiectat_ortogonal_est_vest_fundalalb.png','plane view','cave_1/raster_1771183787575.png',1,NULL,NULL,NULL,NULL);
INSERT INTO raster_maps VALUES(4,'cerna_ps_pn_pdp_plan_en_articol.jpg','plane view','cave_1/raster_1771183787584.jpg',1,NULL,NULL,NULL,NULL);
INSERT INTO raster_maps VALUES(5,'geo_art_tirla_ps__harta_profil.png','plane view','cave_1/raster_1771183787593.png',1,NULL,NULL,NULL,NULL);
INSERT INTO raster_maps VALUES(6,'Ponorul Nou - zona intrare.jpg','plane view','cave_2/raster_1771183787599.jpg',2,NULL,NULL,NULL,NULL);
INSERT INTO raster_maps VALUES(7,'Ponorul Nou - zona intrare_nordata.jpg','plane view','cave_2/raster_1771183787610.jpg',2,NULL,NULL,NULL,NULL);
INSERT INTO raster_maps VALUES(8,'Ponorul Nou_curatat.jpg','plane view','cave_2/raster_1771183787617.jpg',2,NULL,NULL,NULL,NULL);
INSERT INTO raster_maps VALUES(9,'1997 Harta P.Gaura cu Vajgau 2.jpg','plane view','cave_3/raster_1771183787629.jpg',3,NULL,NULL,NULL,NULL);
CREATE TABLE IF NOT EXISTS "cave_place_to_raster_map_definitions" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "x_coordinate" INTEGER, "y_coordinate" INTEGER, "cave_place_id" INTEGER REFERENCES cave_places(id), "raster_map_id" INTEGER REFERENCES raster_maps(id), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER);
INSERT INTO cave_place_to_raster_map_definitions VALUES(1,4300,2594,1,1,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(2,3639,2644,2,1,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(3,1856,3365,4,1,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(4,2594,1574,5,1,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(5,1793,2762,6,1,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(6,1635,2038,8,1,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(7,647,559,1,2,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(8,556,562,2,2,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(9,382,656,3,2,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(10,268,684,5,2,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(11,256,465,8,2,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(12,8698,1657,1,3,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(13,3972,2218,4,3,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(14,3329,2215,5,3,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(15,3597,2136,6,3,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(16,3437,2245,7,3,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(17,3446,2122,8,3,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(18,562,185,1,4,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(19,547,107,2,4,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(20,473,310,3,4,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(21,933,505,4,4,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(22,39,161,5,4,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(23,775,213,7,4,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(24,459,181,8,4,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(25,712,796,2,5,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(26,503,166,3,5,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(27,1003,576,4,5,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(28,2032,1230,5,5,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(29,225,1099,7,5,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(30,1026,871,8,5,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(31,1075,1135,9,6,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(32,1358,871,10,6,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(33,1768,453,14,6,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(34,2847,2324,10,7,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(35,3241,922,11,7,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(36,685,2363,12,7,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(37,1788,461,13,7,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(38,1420,511,14,7,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(39,1016,1417,15,7,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(40,1553,1876,10,8,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(41,109,685,11,8,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(42,1337,1171,12,8,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(43,1453,1050,13,8,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(44,1551,1464,14,8,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(45,1653,1556,15,8,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(46,142,966,16,9,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(47,1039,667,17,9,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(48,1134,753,19,9,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(49,1339,630,20,9,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(50,7107,2190,2,3,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(51,2479,3278,3,1,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(52,1623,2151,7,1,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(53,268,673,4,2,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(54,271,571,6,2,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(55,249,496,7,2,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(56,4816,2280,3,3,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(57,1493,809,11,6,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(58,2270,1403,12,6,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(59,2689,100,13,6,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(60,631,974,9,8,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(61,1085,533,22,9,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(62,366,784,18,9,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(63,1237,617,21,9,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(64,3185,2480,43,1,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(65,3344,1979,44,1,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(66,1817,1648,45,1,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(67,1733,2578,46,1,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(68,1558,3511,47,1,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(69,1437,3705,48,1,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(70,1314,3916,49,1,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(71,3485,2044,51,1,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(72,2772,3111,52,1,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(73,2271,4100,53,1,NULL,NULL,NULL);
INSERT INTO cave_place_to_raster_map_definitions VALUES(74,3223,3842,54,1,NULL,NULL,NULL);
CREATE TABLE IF NOT EXISTS "configurations" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL UNIQUE, "value" TEXT, "created_at" INTEGER, "updated_at" INTEGER);
INSERT INTO configurations VALUES(1,'version','1.0',NULL,NULL);
INSERT INTO configurations VALUES(2,'last_open_cave','5',NULL,NULL);
INSERT INTO configurations VALUES(3,'qr_code_generation','{"imagePaddingPx":2,"labelFontSize":28.0,"labelFontFamily":"Helvetica","qrBgColor":4294967295,"qrFgColor":4278190080,"exportImagesAsZip":true,"dpi":300,"includeTitle":true,"imageFormat":"png","qrSizePx":4,"qrErrorCorrectionLevel":"M","pdfQrPaddingH":2.0,"pdfQrPaddingV":2.0}',NULL,NULL);
CREATE TABLE IF NOT EXISTS "cave_places" (
	"id"	INTEGER NOT NULL UNIQUE,
	"title"	TEXT NOT NULL,
	"description"	TEXT,
	"cave_id"	INTEGER,
	"place_qr_code_identifier"	INTEGER,
	"cave_area_id"	INTEGER,
	"latitude"	REAL,
	"longitude"	REAL,
	"created_at"	INTEGER,
	"updated_at"	INTEGER,
	"deleted_at"	INTEGER,
	"is_main_entrance"	INTEGER,
	"is_entrance"	INTEGER, depth_in_cave NUMERIC(7, 2),
	PRIMARY KEY("id" AUTOINCREMENT),
	FOREIGN KEY("cave_area_id") REFERENCES "cave_areas"("id"),
	FOREIGN KEY("cave_id") REFERENCES "caves"("id")
);
INSERT INTO cave_places VALUES(1,'Intrare','xx',1,5,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(2,'S. Sorbului',NULL,1,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(3,'S. Colectorului Mic',NULL,1,62340563,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(4,'Trifurcație',NULL,1,43253129,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(5,'G. Gorjului - intrare',NULL,1,61616395,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(6,'G. Uriașilor - sub ',NULL,1,91222258,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(7,'Lacul Purificării - capăt sudic',NULL,1,43358223,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(8,'Lacul Purificării - capăt nordic',NULL,1,23284700,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(9,'Intrare',NULL,2,3993278,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(10,'Capat puturi principale - sus',NULL,2,62724253,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(11,'Baza puturi principale - jos',NULL,2,438352,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(12,'Galeria Condamnatilor - baza put acces',NULL,2,7244472,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(13,'Galeria Condamnatilor - intrare',NULL,2,5048581,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(14,'cascada 1',NULL,2,71650179,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(15,'cascada 2',NULL,2,89896089,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(16,'Intrare',NULL,3,1500659,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(17,'La lift',NULL,3,34933531,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(18,'Sala mare intrare',NULL,3,76753802,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(19,'La scara',NULL,3,83102191,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(20,'maini curente',NULL,3,79430410,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(21,'intrare pe activ',NULL,3,49642393,7,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(22,'baza puturi activ',NULL,3,18243143,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(23,'Peștera Ascendentă din Guguiova',NULL,1,29,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(24,'Peștera cu Săritoare din Guguiova',NULL,1,14,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(25,'Peștera X1 din Piatra Lupului',NULL,1,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(26,'Peștera B1 din Piatra Lupului',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(27,'Peștera B2 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(28,'Peștera B3 din Piatra Lupului',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(29,'Peștera B4 din Piatra Lupului',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(30,'Peștera B5 din Piatra Lupului',NULL,1,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(31,'Peștera C1 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(32,'Peștera C2 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(33,'Peștera C3 din Piatra Lupului',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(34,'Peștera C4 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(35,'Peștera C5 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(36,'Peștera C6 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(37,'Peștera C7 din Piatra Lupului',NULL,1,16,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(38,'Peștera C8 din Piatra Lupului',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(39,'Peștera C9 din Piatra Lupului',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(40,'Peștera C9 din Piatra Lupului (Gaura cu Vâjagău)',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(41,'Peștera D1 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(42,'Peștera D2 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(43,'Peștera D3 din Piatra Lupului',NULL,1,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(44,'Peștera M1 din Piatra Lupului',NULL,1,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(45,'Peștera M2 din Piatra Lupului',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(46,'Peștera M3 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(47,'Peștera M4 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(48,'Avenul M5 din Piatra Lupului',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(49,'Avenul X2 din Piatra Lupului',NULL,1,12,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(50,'Peștera X3 din Piatra Lupului',NULL,1,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(51,'Peștera X4 din Piatra Lupului',NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(52,'Peștera X6 din Piatra Lupului',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(53,'Peștera X7 din Piatra Lupului',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(54,'Peștera X8 din Piatra Lupului',NULL,1,12,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(55,'Peștera X9 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(56,'Peștera E1 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(57,'Peștera E3 din Piatra Lupului',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(58,'Peștera E4 din Piatra Lupului',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(59,'Peștera E5 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(60,'Peștera E6 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(61,'Peștera F1 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(62,'Peștera F2 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(63,'Peștera F3 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(64,'Peștera F4 din Piatra Lupului',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(65,'Peștera F5 din Piatra Lupului',NULL,1,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(66,'Peștera G1 din Piatra Lupului',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(67,'Peștera G2 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(68,'Peștera G3 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(69,'Peștera H1 din Piatra Lupului',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(70,'Peștera H2 din Piatra Lupului',NULL,1,11,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(71,'Peștera H3 din Piatra Lupului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(72,'Peștera H4 din Piatra Lupului',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(73,'Peștera din Dealul Glimea',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(74,'Peștera nr. 1 de la Fața Cerbului',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(75,'Peștera nr. 2 de la Fața Cerbului',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(76,'Avenul nr. 3 din Poiana Pleșița',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(77,'Peștera Caroleștilor',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(78,'Peștera nr. 2 din Dealul Bulz',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(79,'Peștera "Hotel"',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(80,'Peștera de la Mal',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(81,'Peștera nr. 1 din Bulz',NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(82,'RT Pietricica',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(83,'2025 martie 15',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(84,'Dan Olteanu',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(85,'Ne-am decis sa mergem in Pietricica',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(86,'Am urcat pe poteca turistica si in vreo 45 de min? am ajuns la dolina cu ponorul fosil de pe V. Ulucilor (sub Culmea Prepeleacului). Anul trecut am inceput sapat ura in ea si am ajuns la o mica gaura. Acum era cam infundata de zapada/gheata si sediment cazut din lateral. Am sapat si spart fiecare cu schimbul pana pe la 22 cand un inceput de ploaie scurta ne-a convins sa plecam. Fata de sapatura precedenta am largit gaura destul de bine decolmatand in lateral si spargand la bormasina si ciocan in blocurile mari. Am ajuns din nou la blocuri mai mari ce trebuie sparte/scoase. Arata bine - se vede o gaura printre ele. A fost relativ cald dar am facut si un foc la care s-a dormit cu brio pana unul sapa. Ruxi si Dan au sapat si intr-o alta gaura mai mica la vreo 3 m de sapatura principala. La intoarcere',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(87,'Dolina e la 1104 m alt.',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(88,'Resurgenta cea mai probabil - Izvoarele din Plai',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(89,'Rezulta ca denivelarea teoretica maxima',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(90,'_____________________',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(91,'pt. fb:',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(92,'Pietricica',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(93,'Fulga',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(94,'2025 martie 16',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(95,'Dupa ce ne-am trezit mai tarziu (ca doar am stat la resortul lui Tim)',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(96,'Peștera Ascendentă din Guguiova',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(98,'Peștera X1 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(99,'Peștera B1 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(100,'Peștera B2 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(101,'Peștera B3 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(102,'Peștera B4 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(103,'Peștera B5 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(104,'Peștera C1 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(105,'Peștera C2 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(106,'Peștera C3 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(107,'Peștera C4 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(108,'Peștera C5 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(109,'Peștera C6 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(110,'Peștera C7 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(111,'Peștera C8 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(112,'Peștera C9 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(113,'Peștera C9 din Piatra Lupului (Gaura cu Vâjagău)',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(114,'Peștera D1 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(115,'Peștera D2 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(116,'Peștera D3 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(117,'Peștera M1 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(118,'Peștera M2 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(119,'Peștera M3 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(120,'Peștera M4 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(121,'Avenul M5 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(122,'Avenul X2 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(123,'Peștera X3 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(124,'Peștera X4 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(125,'Peștera X6 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(126,'Peștera X7 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(127,'Peștera X8 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(128,'Peștera X9 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(129,'Peștera E1 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(130,'Peștera E3 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(131,'Peștera E4 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(132,'Peștera E5 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(133,'Peștera E6 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(134,'Peștera F1 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(135,'Peștera F2 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(136,'Peștera F3 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(137,'Peștera F4 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(138,'Peștera F5 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(139,'Peștera G1 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(140,'Peștera G2 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(141,'Peștera G3 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(142,'Peștera H1 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(143,'Peștera H2 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(144,'Peștera H3 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(145,'Peștera H4 din Piatra Lupului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(146,'Peștera din Dealul Glimea',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(147,'Peștera nr. 1 de la Fața Cerbului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(148,'Peștera nr. 2 de la Fața Cerbului',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(149,'Avenul nr. 3 din Poiana Pleșița',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(150,'Peștera Caroleștilor',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(151,'Peștera nr. 2 din Dealul Bulz',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(152,'Peștera "Hotel"',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(153,'Peștera de la Mal',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO cave_places VALUES(154,'Peștera nr. 1 din Bulz',NULL,6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
CREATE TABLE IF NOT EXISTS "documentation_files" (
              id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
              title TEXT(50) NOT NULL,
              description TEXT,
              file_name TEXT(255) NOT NULL,
              file_size INTEGER NOT NULL,
              file_hash TEXT(64),
              file_type TEXT(25) NOT NULL,
              created_at INTEGER,
              updated_at INTEGER,
              deleted_at INTEGER,
              UNIQUE(title, file_name, file_size, file_hash) ON CONFLICT ROLLBACK
            );
CREATE TABLE documentation_files_to_geofeatures (
              id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
              geofeature_id INTEGER,
              geofeature_type TEXT(10) NOT NULL,
              documentation_file_id INTEGER NOT NULL REFERENCES documentation_files(id),
              updated_at INTEGER,
              deleted_at INTEGER,
              UNIQUE(geofeature_id, geofeature_type, documentation_file_id) ON CONFLICT ROLLBACK
            );
CREATE TABLE cave_trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
            cave_id INTEGER NOT NULL REFERENCES caves (id),
            title TEXT(255) NOT NULL,
            description TEXT,
            trip_started_at INTEGER NOT NULL,
            trip_ended_at INTEGER,
            created_at INTEGER,
            updated_at INTEGER,
            deleted_at INTEGER
          , log TEXT);
CREATE TABLE cave_trip_points (
            id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
            cave_trip_id INTEGER NOT NULL REFERENCES cave_trips (id),
            cave_place_id INTEGER NOT NULL REFERENCES cave_places (id),
            scanned_at INTEGER NOT NULL,
            notes TEXT,
            created_at INTEGER,
            updated_at INTEGER,
            deleted_at INTEGER,
            UNIQUE(cave_trip_id, cave_place_id, scanned_at) ON CONFLICT ROLLBACK
          );
CREATE TABLE documentation_files_to_cave_trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
            documentation_file_id INTEGER NOT NULL REFERENCES documentation_files (id),
            cave_trip_id INTEGER NOT NULL REFERENCES cave_trips (id),
            created_at INTEGER,
            deleted_at INTEGER,
            UNIQUE(documentation_file_id, cave_trip_id) ON CONFLICT ROLLBACK
          );
DELETE FROM sqlite_sequence;
INSERT INTO sqlite_sequence VALUES('caves',62);
INSERT INTO sqlite_sequence VALUES('cave_areas',7);
INSERT INTO sqlite_sequence VALUES('surface_places',2);
INSERT INTO sqlite_sequence VALUES('cave_entrances',1);
INSERT INTO sqlite_sequence VALUES('raster_maps',9);
INSERT INTO sqlite_sequence VALUES('cave_place_to_raster_map_definitions',74);
INSERT INTO sqlite_sequence VALUES('configurations',3);
INSERT INTO sqlite_sequence VALUES('surface_areas',13);
INSERT INTO sqlite_sequence VALUES('cave_places',154);
INSERT INTO sqlite_sequence VALUES('documentation_files',0);
INSERT INTO sqlite_sequence VALUES('documentation_files_to_geofeatures',0);
COMMIT;
