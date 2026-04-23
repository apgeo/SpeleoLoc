// Run with: dart run tool/generate_test_data.dart
//
// Reads the existing test SQLite database and:
//   1. Exports schema-only, data-only, and schema+data SQL scripts
//   2. Generates additional randomised test data (Romanian language)
//      and appends it to a combined data script
//
// Requirements: sqlite3 CLI must be on PATH.

import 'dart:io';
import 'dart:math';

// ---------------------------------------------------------------------------
//  PATHS
// ---------------------------------------------------------------------------

const String kSqlite3Cmd = 'D:\\dev\\Android\\Sdk\\platform-tools\\sqlite3.exe'; // Adjust if sqlite3 is not on PATH
const String kSourceDbPath =
    'test_data/db/binaries/speleo_loc_export_20260301_tel2.sqlite';
const List<String> kSourceDbFallbackPaths = [
  'test_data/db/binaries/speleo_loc_export_20260423.sqlite',
  'test_data/db/binaries/speleo_loc_export_20260414.sqlite',
  'test_data/db/binaries/speleo_loc_export_20260410.sqlite',
  'test_data/db/binaries/speleo_loc_export_20260301.sqlite',
];
const String kOutputDir = 'test_data/db/generated';
const String kSchemaOnlyFile = '$kOutputDir/schema_only.sql';
const String kDataOnlyFile = '$kOutputDir/data_only.sql';
const String kSchemaAndDataFile = '$kOutputDir/schema_and_data.sql';
const String kExtraDataFile = '$kOutputDir/extra_test_data.sql';
const String kFullDataFile = '$kOutputDir/data_with_extra.sql';
const String kSchemaAndFullDataFile = '$kOutputDir/schema_and_data_with_extra.sql';
const String kGeneratedDbFile = '$kOutputDir/generated_test_data.sqlite';

// ---------------------------------------------------------------------------
//  GENERATION CONSTANTS - adjust as needed
// ---------------------------------------------------------------------------

/// Surface areas: random count in [min, max].
const int kSurfaceAreasMin = 5;
const int kSurfaceAreasMax = 9;

/// Caves total: random count in [min, max].
const int kCavesMin = 40;
const int kCavesMax = 90;

/// Cave areas per cave: random count in [min, max].
const int kCaveAreasPerCaveMin = 0;
const int kCaveAreasPerCaveMax = 9;

/// Cave places per cave: random count in [min, max].
const int kCavePlacesPerCaveMin = 40;
const int kCavePlacesPerCaveMax = 90;

/// Documentation files (text) per cave: random count in [min, max].
const int kDocsPerCaveMin = 0;
const int kDocsPerCaveMax = 18;

/// Cave pictures (as documentation files) per cave: random count in [min, max].
const int kPicturesPerCaveMin = 0;
const int kPicturesPerCaveMax = 18;

/// Cave trips per cave:
/// - 80% chance for [kCaveTripsPerCaveLowMin, kCaveTripsPerCaveLowMax]
/// - 20% chance for [kCaveTripsPerCaveHighMin, kCaveTripsPerCaveHighMax]
const int kCaveTripsPerCaveLowMin = 0;
const int kCaveTripsPerCaveLowMax = 5;
const int kCaveTripsPerCaveHighMin = 6;
const int kCaveTripsPerCaveHighMax = 25;
const double kCaveTripsLowRangeProbability = 0.80;

/// Cave trip points per trip: random count in [min, max].
const int kTripPointsPerTripMin = 0;
const int kTripPointsPerTripMax = 20;

/// Documentation relations to cave trips per trip: random count in [min, max].
const int kDocToTripRelationsPerTripMin = 0;
const int kDocToTripRelationsPerTripMax = 15;

/// Raster maps cloned from existing ones per cave.
const int kRasterMapsPerCaveMin = 1;
const int kRasterMapsPerCaveMax = 5;

/// Cave-place point bindings per raster map.
const int kRasterMapPointsPerMapMin = 1;
const int kRasterMapPointsPerMapMax = 30;

/// Random coordinate limits for cave place points on raster map.
const int kRasterPointMaxX = 6000;
const int kRasterPointMaxY = 6000;

/// How many document text templates to pick from per run.
const int kDocTemplatePoolSize = 10;

// ---------------------------------------------------------------------------
//  FEATURE FLAGS - set to false to skip generation of that category
// ---------------------------------------------------------------------------

const bool kGenerateSurfaceAreas = true;
const bool kGenerateCaves = !true;
const bool kGenerateCaveAreas = true;
const bool kGenerateCavePlaces = true;
const bool kGenerateDocuments = true;
const bool kGeneratePictureDocuments = true;
const bool kGenerateGeofeatureLinks = true;
const bool kGenerateRasterMapsWithBindings = true;
const bool kGenerateRasterForGeneratedCaves = true;
const bool kGenerateRasterForEnrichedCaves = true;
const bool kGenerateRasterForExistingCavesWithoutRaster = true;
const bool kGenerateCaveTrips = true;
const bool kEnrichExistingCavesWithoutData = true;
const bool kGenerateSqliteDatabase = true;

class RasterTemplate {
  const RasterTemplate({
    required this.title,
    required this.mapType,
    required this.fileName,
  });

  final String title;
  final String mapType;
  final String fileName;
}

class CaveMissingDataState {
  const CaveMissingDataState({
    required this.caveId,
    required this.needsAreas,
    required this.needsPlaces,
    required this.needsTextDocs,
    required this.needsPictures,
  });

  final int caveId;
  final bool needsAreas;
  final bool needsPlaces;
  final bool needsTextDocs;
  final bool needsPictures;

  bool get hasAnyNeed =>
      needsAreas || needsPlaces || needsTextDocs || needsPictures;
}

// ---------------------------------------------------------------------------
//  TABLES whose order matters for export (parents before children)
// ---------------------------------------------------------------------------

const List<String> kOrderedTables = [
  'surface_areas',
  'caves',
  'cave_areas',
  'cave_places',
  'cave_place_to_raster_map_definitions',
  'raster_maps',
  'documentation_files',
  'documentation_files_to_geofeatures',
  'cave_trips',
  'cave_trip_points',
  'documentation_files_to_cave_trips',
  'configurations',
  'cave_entrances',
  'surface_places',
];

// ---------------------------------------------------------------------------
//  ROMANIAN TEMPLATES (pre-generated, max lengths as specified)
// ---------------------------------------------------------------------------

// Automatically generated
/// 20 cave description templates (max 1 sentence each).
/// Use {N} as a number placeholder.
const List<String> kCaveDescriptionTemplates = [
  'Pestera descoperita in anul {N}, situata intr-o zona carstica.',
  'Lungimea totala estimata este de {N} metri.',
  'Cavitate cu dezvoltare predominant orizontala, explorata de {N} speologi.',
  'Pestera de tip tunel cu {N} galerii laterale.',
  'Adancimea maxima masurata este de {N} metri sub nivelul intrarii.',
  'Formata in calcare jurasice, cu {N} nivele distincte.',
  'Temperatura interioara constanta de aproximativ {N} grade Celsius.',
  'Habitat pentru {N} specii de chiroptere identificate.',
  'Debit estimat al cursului de apa subteran: {N} litri pe secunda.',
  'Pestera activa cu {N} cascade subterane.',
  'Prima documentare dateaza din anul {N}.',
  'Sistem de galerii cu {N} ramificatii principale.',
  'Acces dificil, necesita echipament tehnic pentru {N} verticale.',
  'Importanta geologica ridicata, cu {N} tipuri de speleoteme.',
  'Pestera fosta turistica, frecventata de {N} vizitatori anual.',
  'Strat de sedimente cu grosimea medie de {N} centimetri.',
  'Zona protejata, biospeologica, cu {N} specii endemice.',
  'Curent de aer puternic detectat la {N} metri de intrare.',
  'Pestera cu potential de extindere, ultima explorare in anul {N}.',
  'Cartare topografica realizata pe {N} sectoare distincte.',
];

/// 20 cave place description templates (max 2 sentences each).
const List<String> kCavePlaceDescriptionTemplates = [
  'Punct de referinta la {N} metri de intrare. Galerie cu sectiune ovala.',
  'Sala cu inaltimea de {N} metri si formatiuni de calcar masive.',
  'Intersectie de galerii, vizibilitate redusa. Se recomanda marcaj la fiecare {N} metri.',
  'Zona cu depozite argiloase pe o lungime de {N} metri. Podeaua este alunecoasa.',
  'Punct de belvedere subteran cu priveliste spre sala de {N} metri lungime.',
  'Loc de bivuac potential, suprafata plana de {N} metri patrati.',
  'Ingustare la {N} centimetri latime. Necesita deplasare in tarais.',
  'Put vertical de {N} metri, coborare pe coarda. Asigurare obligatorie.',
  'Sifon activ cu nivel variabil, adancimea maxima {N} centimetri.',
  'Galerie fosila cu stalactite pe o distanta de {N} metri.',
  'Traversare pe cornisa la {N} metri deasupra cursului de apa subteran.',
  'Camera cu ecou puternic si dimensiuni de circa {N} metri. Buna orientare acustica.',
  'Punct de ramificatie cu {N} directii posibile. Marcajele sunt esentiale.',
  'Zona cu curent de aer, deschidere potentiala la {N} metri distanta.',
  'Cascada interioara de {N} metri inaltime, activa sezonier.',
  'Depozit de guano pe {N} metri patrati. Atentie la calitatea aerului.',
  'Concretii excentrice rare la inaltimea de {N} centimetri.',
  'Pod natural de roca la {N} metri deasupra podelei galeriei.',
  'Lac subteran cu adancimea estimata la {N} metri si apa limpede.',
  'Punct topografic principal, vizibil din {N} directii ale galeriei.',
];

// Automatically generated
/// 20 document text templates (max ~20 sentences each).
const List<String> kDocumentTextTemplates = [
  // Template 1
  'Raport de explorare pentru sectorul {N}. '
      'Echipa formata din {N} membri a pornit de la intrarea principala. '
      'Temperatura la start a fost de {N} grade. '
      'Am parcurs galeria principala pe o distanta de {N} metri. '
      'La {N} metri de intrare am intalnit o bifurcatie. '
      'Ramura dreapta se ingusteaza dupa {N} metri. '
      'Am instalat {N} spituri de asigurare. '
      'Putul principal are o adancime de {N} metri. '
      'Baza putului se deschide intr-o sala de {N} metri latime. '
      'Am colectat {N} probe de apa pentru analiza. '
      'Nivelul apei din sifon depasea {N} centimetri. '
      'Debitul estimat era de {N} litri pe minut. '
      'Formatiunile de calcar acopera {N} procente din tavan. '
      'Am fotografiat {N} speleoteme deosebite. '
      'Durata totala a explorarii a fost de {N} ore. '
      'Am marcat {N} puncte noi pe harta. '
      'Starea generala a echipamentului este buna dupa {N} utilizari. '
      'Propunem revenire pentru cartarea sectorului {N}. '
      'Estimam un potential suplimentar de {N} metri de galerii. '
      'Raportul complet va fi disponibil in {N} zile.',

  // Template 2
  'Observatii topografice - tura nr. {N}. '
      'Am efectuat {N} vizari cu busola si clinometrul. '
      'Lungimea poligonalei este de {N} metri. '
      'Diferenta de nivel totala: {N} metri. '
      'Am folosit statia nr. {N} ca baza. '
      'Eroarea de inchidere a poligonalei a fost sub {N} procente. '
      'Galeria prezinta un azimut predominant de {N} grade. '
      'Panta medie a galeriei este de {N} grade. '
      'Latimea variaza intre {N} si aproximativ dublu. '
      'Inaltimea maxima a sectiunii este de {N} metri. '
      'Am setat {N} borne fixe din otel inoxidabil. '
      'Urmatoarea sesiune va incepe de la statia {N}. '
      'Estimare galerie nemasurata: {N} metri. '
      'Am notat {N} caracteristici morfologice particulare. '
      'Planul rezultat va fi la scara 1:{N}. '
      'Informam administratia ariei protejate despre descoperirea de la sectorul {N}.',

  // Template 3
  'Nota de biospeologie - campania nr. {N}. '
      'Am identificat {N} specii de nevertebrate. '
      'Dintre acestea, {N} sunt considerate troglobionti. '
      'Colonia de lilieci numara aproximativ {N} indivizi. '
      'Probele au fost colectate de la {N} puncte distincte. '
      'Temperatura substratului la colectare: {N} grade Celsius. '
      'Umiditatea relativa a fost de {N} procente. '
      'Am montat {N} capcane Barber in galeria principala. '
      'Capcanele vor fi ridicate dupa {N} zile. '
      'Am observat urme de activitate la {N} metri de intrare. '
      'Speciile rare au fost fotografiate cu obiectiv macro de {N} milimetri. '
      'Raportul preliminar identifica {N} potentiale specii noi. '
      'Colaboram cu {N} institute de cercetare. '
      'Analiza ADN a probelor va dura aproximativ {N} saptamani. '
      'Am catalogat {N} exemplare pentru colectia de referinta. '
      'Fauna acvatica a fost colectata din lacul de la cota {N}. '
      'Datele vor fi publicate in volumul {N} al revistei de speologie.',

  // Template 4
  'Jurnal de expeditie subterana - ziua {N}. '
      'Am intrat in pestera la ora {N}. '
      'Parcursul pana la tabara subterana a durat {N} ore. '
      'Am transportat {N} kilograme de echipament. '
      'La tabara temperatura era de {N} grade. '
      'Am montat {N} corturi in sala mare. '
      'Rezerva de apa potabila este de {N} litri. '
      'Am planificat {N} obiective de explorat. '
      'Primul obiectiv se afla la {N} metri de tabara. '
      'Comunicarea radio functioneaza pe o distanta de {N} metri. '
      'Am verificat starea corzilor pe {N} puturi. '
      'Am acumulat {N} ore de topografie. '
      'Fotodocumentarea a produs {N} imagini RAW. '
      'Urmatoarea tura de explorare incepe in {N} ore. '
      'Echipa este formata acum din {N} persoane active. '
      'Atmosfera din galeria inferioara contine {N} procente CO2. '
      'Am stabilit o limita de siguranta la {N} metri distanta. '
      'Stocul de baterii este suficient pentru {N} ore de functionare. '
      'Moralul echipei este excelent dupa {N} zile sub pamant.',

  // Template 5
  'Evaluare risc - sectorul {N}. '
      'Am identificat {N} zone cu risc de prabusire a plafonului. '
      'Blocurile instabile au dimensiuni de pana la {N} centimetri. '
      'Nivelul apei poate creste cu {N} metri in caz de precipitatii. '
      'Distanta de la intrare pana la prima zona de risc: {N} metri. '
      'Am instalat {N} indicatoare de avertizare reflectorizante. '
      'Evacuarea de urgenta dureaza estimativ {N} minute. '
      'Echipamentul de prim ajutor este pozitionat la statia {N}. '
      'Am testat comunicarea radio in {N} puncte critice. '
      'Semnalul radio este pierdut dupa {N} metri de la intrare. '
      'Am recomandat echipa minima de {N} persoane pentru acest sector. '
      'Casca si lampa frontala trebuie verificate la fiecare {N} ore. '
      'Protocoalele de securitate au fost revizuite de {N} ori anul acesta. '
      'Ultimul incident a avut loc cu {N} luni in urma. '
      'Am efectuat {N} exercitii de evacuare. '
      'Planul de urgenta a fost actualizat la versiunea {N}.',

  // Template 6
  'Raport geologic - profil {N}. '
      'Stratele de calcar apartin etajului {N}. '
      'Grosimea medie a stratelor este de {N} centimetri. '
      'Fisurile tectonice au un azimut predominant de {N} grade. '
      'Am recoltat {N} probe de roca pentru datarea izotopica. '
      'Continutul de CaCO3 depaseste {N} procente. '
      'Concretii de aragonita au fost gasite la cota {N}. '
      'Varsta estimata a speleothemelor: {N} mii de ani. '
      'Depozitele clastice au o grosime de {N} centimetri. '
      'Am identificat {N} tipuri diferite de sedimente. '
      'Nivelul paleoclappei fosile este la cota {N} metri. '
      'Analiza XRD confirma {N} faze minerale distincte. '
      'Sectorul analizat are o lungime de {N} metri. '
      'Am realizat {N} profile transversale ale galeriei. '
      'Cutele vizibile au amplitudini de {N} centimetri.',

  // Template 7
  'Raport climatologic subteran - statia {N}. '
      'Senzorul a inregistrat {N} cicluri complete de temperatura. '
      'Temperatura medie anuala: {N} grade Celsius. '
      'Amplitudinea termica maxima: {N} grade. '
      'Umiditatea relativa medie: {N} procente. '
      'Concentratia de CO2: {N} ppm. '
      'Curentul de aer maxim masurat: {N} metri pe secunda. '
      'Directia predominanta a curentului: sector {N}. '
      'Datalogerul a functionat {N} zile fara intrerupere. '
      'Am descarcat {N} megabytes de date brute. '
      'Presiunea barometrica la intrare: {N} mbar. '
      'Evaporarea masurata: {N} milimetri pe luna. '
      'Am comparat datele cu {N} statii meteorologice de suprafata. '
      'Raportul complet include {N} grafice si tabele. '
      'Monitorizarea continua de {N} luni confirma stabilitatea climatica.',

  // Template 8
  'Inventar echipament - depozit subteran {N}. '
      'Total corzi disponibile: {N} metri. '
      'Dintre acestea, {N} metri necesita inlocuire. '
      'Am verificat {N} carabiniere si {N} plachete. '
      'Corzi statice diametru 10mm: {N} bucati. '
      'Am adaugat {N} saci de transport noi. '
      'Lampi de rezerva: {N} bucati cu baterii pline. '
      'Stocul de carbid: {N} kilograme. '
      'Truse de prim ajutor: {N} complete, verificate. '
      'Echipamentul este depozitat la {N} metri de intrare. '
      'Urmatoarea verificare programata peste {N} saptamani. '
      'Am retras din uz {N} echipamente expirate. '
      'Bugetul anual de echipament: {N} lei.',

  // Template 9
  'Protocol de fotodocumentare - sesiunea {N}. '
      'Am realizat {N} fotografii in format RAW. '
      'Dintre acestea, {N} sunt panorame la 360 grade. '
      'Timp total de expunere cumulat: {N} minute. '
      'Am folosit {N} surse de lumina pozitionate strategic. '
      'Flash-urile au fost declansate de {N} ori fiecare. '
      'Obiectivele au acoperit focal de la {N} milimetri. '
      'Am fotografiat {N} speleoteme rare pentru catalog. '
      'Dimensiunea totala a fisierelor: {N} gigabytes. '
      'Coordonatele punctelor foto au fost notate pentru {N} locatii. '
      'Post-procesarea va necesita aproximativ {N} ore de lucru. '
      'Am selectat {N} imagini pentru publicare imediata. '
      'Calitatea generala: {N} din 10.',

  // Template 10
  'Rezumat activitate anuala - anul {N}. '
      'Total zile petrecute in subteran: {N}. '
      'Numar de expeditii organizate: {N}. '
      'Participanti unici: {N} speologi. '
      'Metri noi de galerie explorata: {N}. '
      'Metri noi topografiati: {N}. '
      'Numar de pesteri vizitate: {N}. '
      'Pesteri noi descoperite: {N}. '
      'Publicatii stiintifice: {N} articole. '
      'Prezentari la conferinte: {N}. '
      'Am format {N} speologi noi. '
      'Am actualizat {N} fise de pestera. '
      'Costul total al expeditiilor: {N} lei. '
      'Am colaborat cu {N} organizatii partenere. '
      'Obiective pentru anul urmator: {N} expeditii planificate. '
      'Multumim celor {N} voluntari care au contribuit.',

  // Template 11
  'Evidenta resurse hidrologice - punctul {N}. '
      'Debitul mediu masurat: {N} litri pe secunda. '
      'Am efectuat {N} masuratori in perioade diferite. '
      'Temperatura apei: {N} grade Celsius, constanta. '
      'pH-ul masurat: {N} unitati. '
      'Conductivitatea electrica: {N} microsiemensi. '
      'Am injectat {N} grame de trasor fluorescent. '
      'Trasorul a aparut la izvor dupa {N} ore. '
      'Distanta estimata: {N} metri de conducte carstice. '
      'Nivelul maxim in sezonul ploios: {N} centimetri peste normal. '
      'Am monitorizat {N} izvoare din bazin. '
      'Volumul estimat al lacului subteran: {N} metri cubi.',

  // Template 12
  'Raport conservare patrimoniu - obiectiv {N}. '
      'Am evaluat starea a {N} inscriptii istorice. '
      'Dintre acestea, {N} necesita interventie urgenta. '
      'Am curatat {N} metri patrati de graffiti modern. '
      'Am instalat {N} panouri informative la intrare. '
      'Bariera de protectie acopera {N} metri liniari. '
      'Am documentat {N} urme de vandalism. '
      'Raportul a fost transmis autoritatilor locale in {N} exemplare. '
      'Am propus clasificarea a {N} formatiuni ca monument natural. '
      'Vizitele ghidate sunt limitate la {N} persoane simultan. '
      'Am instruit {N} ghizi locali. '
      'Costul estimat al lucrarilor: {N} lei. '
      'Termenul de finalizare: {N} luni.',

  // Template 13
  'Nota de mentenanta balize - traseul {N}. '
      'Am verificat {N} balize reflectorizante. '
      'Dintre acestea, {N} au fost inlocuite. '
      'Am adaugat {N} balize noi in zonele nemarcate. '
      'Distanta medie intre balize: {N} metri. '
      'Am folosit {N} culori diferite conform codificarii. '
      'Vizibilitatea minima a balizelor: {N} metri cu lampa frontala. '
      'Am eliminat {N} marcaje vechi si confuze. '
      'Traseul total balizat: {N} metri. '
      'Urmatoarea verificare: peste {N} luni. '
      'Materialul consumat: {N} benzi reflectorizante.',

  // Template 14
  'Registru vizitatori - luna {N}. '
      'Total vizitatori inregistrati: {N}. '
      'Dintre acestia, {N} au participat la ture ghidate. '
      'Am organizat {N} ture pentru grupuri scolare. '
      'Media participantilor per tura: {N} persoane. '
      'Am distribuit {N} pliante informative. '
      'Am colectat {N} chestionare de feedback. '
      'Nota medie acordata: {N} din 10. '
      'Am inregistrat {N} incidente minore. '
      'Veniturile din taxe: {N} lei. '
      'Am angajat {N} ghizi suplimentari. '
      'Programul de vizitare a fost extins cu {N} ore pe saptamana.',

  // Template 15
  'Plan de explorare - obiectiv {N}. '
      'Am identificat {N} galerii laterale neexplorate. '
      'Lungimea estimata: {N} metri pe fiecare. '
      'Sunt necesare {N} zile de explorare. '
      'Echipa recomandata: {N} persoane. '
      'Echipament vertical necesar pentru {N} puturi. '
      'Am pregatit {N} kilograme de echipament. '
      'Rezerva de carbid: {N} kilograme. '
      'Punctul de plecare este statia topografica {N}. '
      'Comunicarea radio va fi testata la {N} puncte. '
      'Am obtinut {N} autorizatii necesare. '
      'Data planificata: peste {N} saptamani. '
      'Bugetul estimat: {N} lei.',

  // Template 16
  'Fisa tehnica echipare put - verticala nr. {N}. '
      'Adancimea: {N} metri. '
      'Am instalat {N} spituri din otel inoxidabil. '
      'Distanta intre spituri: {N} metri. '
      'Lungimea corzii principale: {N} metri. '
      'Coarda de siguranta: {N} metri. '
      'Am montat {N} protectoare de franghie. '
      'Fractionarea se face la {N} metri de buza putului. '
      'Deviatia este la {N} metri sub fractionare. '
      'Am testat echiparea cu {N} coborari. '
      'Ultimul control al spiturilor: acum {N} luni.',

  // Template 17
  'Proces verbal intalnire club - sedinta nr. {N}. '
      'Au participat {N} membri. '
      'Am discutat {N} puncte pe ordinea de zi. '
      'S-a aprobat bugetul de {N} lei pentru trimestrul urmator. '
      'Am planificat {N} expeditii in urmatoarele luni. '
      'S-au inscris {N} membri noi. '
      'Am evaluat {N} rapoarte de explorare. '
      'S-a votat achizitionarea de echipament in valoare de {N} lei. '
      'Urmatoarea sedinta: peste {N} saptamani. '
      'Am desemnat {N} responsabili pentru proiecte.',

  // Template 18
  'Raport formare speologica - curs nr. {N}. '
      'Am instruit {N} cursanti. '
      'Durata cursului: {N} zile. '
      'Am efectuat {N} sesiuni practice in pestera. '
      'Fiecare cursant a parcurs {N} metri de galerie. '
      'Am acoperit {N} module teoretice. '
      'Examenul final a fost promovat de {N} participanti. '
      'Am distribuit {N} seturi de echipament pentru practica. '
      'Feedback-ul mediu: {N} din 10. '
      'Urmatorul curs incepe in {N} saptamani.',

  // Template 19
  'Studiu speleogenetic - sectorul {N}. '
      'Am analizat {N} probe de calcar sub microscop. '
      'Varsta estimata a galeriei: {N} milioane de ani. '
      'Am identificat {N} faze de speleogeneza. '
      'Nivelul freatic actual este la {N} metri adancime. '
      'Am corelat cu {N} alte pesteri din zona. '
      'Porozitatea medie a rocii: {N} procente. '
      'Am realizat {N} sectiuni subtiri din probe. '
      'Studiul va fi publicat in volumul {N} al buletinului. '
      'Am colaborat cu {N} geologi specialisti.',
      
  // Template 20
  'Studiu speleogenetic - sectorul {N}. '
      'Am analizat {N} probe de calcar sub microscop. '
      'Varsta estimata a galeriei: {N} milioane de ani. '
      'Am identificat {N} faze de speleogeneza. '
      'Nivelul freatic actual este la {N} metri adancime. '
      'Am corelat cu {N} alte pesteri din zona. '
      'Porozitatea medie a rocii: {N} procente. '
      'Am realizat {N} sectiuni subtiri din probe. '
      'Studiul va fi publicat in volumul {N} al buletinului. '
      'Am colaborat cu {N} geologi specialisti.',
];

// ---------------------------------------------------------------------------
//  ROMANIAN NAME POOLS
// ---------------------------------------------------------------------------

// Automatically generated from Romanian geographical names
const List<String> kSurfaceAreaNames = [
  'Platoul Mehedinti',
  'Depresiunea Baia de Fier',
  'Muntii Bihor',
  'Cheile Bicajelului',
  'Muntii Apuseni',
  'Podisul Mehedinti',
  'Depresiunea Vadul Crisului',
  'Muntii Padurea Craiului',
  'Cheile Turzii',
  'Platoul Cernisoara',
  'Muntii Macinului',
  'Cheile Nerei',
  'Valea Crisului Repede',
  'Platoul Vascau',
  'Depresiunea Hunedoara',
  'Muntii Trascau',
  'Cheile Galbenei',
  'Platoul Padis',
  'Muntii Codru-Moma',
  'Cheile Somesului Cald',
  'Platoul Scarisoara',
  'Muntii Vladeasa',
  'Cheile Ordancusei',
  'Depresiunea Campeni',
  'Muntii Metaliferi',
];

const List<String> kCaveNamePrefixes = [
  'Pestera',
  'Avenul',
  'Grota',
  'Caverna',
  'Ponorul',
];

const List<String> kCaveNameSuffixes = [
  'Mare',
  'Mica',
  'de la Izvor',
  'Ursului',
  'Liliecilor',
  'din Cheile Nerii',
  'Vantului',
  'cu Apa',
  'Seaca',
  'Piatra Alba',
  'din Padure',
  'de Sub Stanca',
  'Cetatea Veche',
  'Portii',
  'Cascadelor',
  'Cristalelor',
  'cu Oase',
  'Misterioasa',
  'Intunecata',
  'Luminii',
  'Fericirii',
  'Strigoiului',
  'Zmeului',
  'Dragonului',
  'Piticilor',
  'Ursilor',
  'Cobailor',
  'din Deal',
  'din Vale',
  'din Camp',
];

const List<String> kCaveAreaNames = [
  'Galeria Principala',
  'Galeria Superioara',
  'Galeria Inferioara',
  'Sectorul Nordic',
  'Sectorul Sudic',
  'Sectorul Vestic',
  'Sectorul Estic',
  'Sala Mare',
  'Sala Mica',
  'Galeria cu Apa',
  'Galeria Fosila',
  'Galeria Activa',
  'Sectorul de Intrare',
  'Sectorul Terminal',
  'Labirintul',
  'Zona Cascadelor',
  'Zona Lacurilor',
  'Galeria Secreta',
  'Reteaua Inferioara',
  'Reteaua Superioara',
];

const List<String> kCavePlacePrefixes = [
  'Punct',
  'Statie',
  'Bifurcatie',
  'Sifon',
  'Cascada',
  'Lac',
  'Put',
  'Sala',
  'Ingustare',
  'Nisa',
  'Cornisa',
  'Platforma',
  'Depozit',
  'Coloana',
  'Stalactita',
  'Stalagmita',
  'Curtina',
  'Fundatura',
  'Intrare',
  'Iesire',
];

// ---------------------------------------------------------------------------
//  MAIN
// ---------------------------------------------------------------------------

void main() async {
  final rng = Random();
  final sourceDbPath = _resolveSourceDbPath();

  // Ensure output directory exists
  Directory(kOutputDir).createSync(recursive: true);

  // ------------------------------------------------------------------
  //  Step 1: Export existing DB -> SQL scripts via sqlite3 CLI
  // ------------------------------------------------------------------
  print('=== Exporting existing database ===');

  if (sourceDbPath == null) {
    stderr.writeln('Source database not found. Checked:');
    stderr.writeln('  - $kSourceDbPath');
    for (final path in kSourceDbFallbackPaths) {
      stderr.writeln('  - $path');
    }
    exit(2);
  }
  print('  Source DB    -> $sourceDbPath');

  _runSqlite3(sourceDbPath, '.schema', kSchemaOnlyFile);
  print('  Schema only  -> $kSchemaOnlyFile');

  _exportDataOnly(sourceDbPath, kDataOnlyFile);
  print('  Data only    -> $kDataOnlyFile');

  _runSqlite3(sourceDbPath, '.dump', kSchemaAndDataFile);
  print('  Schema+Data  -> $kSchemaAndDataFile');

    final hasDocFileType =
      _tableHasColumn(sourceDbPath, 'documentation_files', 'file_type');
    final hasDocGeoTable =
      _tableExists(sourceDbPath, 'documentation_files_to_geofeatures');
      final hasDocCaveId =
      _tableHasColumn(sourceDbPath, 'documentation_files', 'cave_id');
  final hasTripsTable = _tableExists(sourceDbPath, 'cave_trips');
  final hasTripPointsTable = _tableExists(sourceDbPath, 'cave_trip_points');
    final hasDocToTripTable =
      _tableExists(sourceDbPath, 'documentation_files_to_cave_trips');

  // ------------------------------------------------------------------
  //  Step 2: Determine max existing IDs from data export
  // ------------------------------------------------------------------
  print('\n=== Reading existing data for ID offsets ===');
  final existingData = File(kDataOnlyFile).readAsStringSync();
  int nextSurfaceAreaId = _maxId(existingData, 'surface_areas') + 1;
  int nextCaveId = _maxId(existingData, 'caves') + 1;
  int nextCaveAreaId = _maxId(existingData, 'cave_areas') + 1;
  int nextCavePlaceId = _maxId(existingData, 'cave_places') + 1;
  int nextDocFileId = _maxId(existingData, 'documentation_files') + 1;
    int nextDocGeoId =
      _maxId(existingData, 'documentation_files_to_geofeatures') + 1;
    int nextRasterMapId = _maxId(existingData, 'raster_maps') + 1;
    int nextRasterPointId =
      _maxId(existingData, 'cave_place_to_raster_map_definitions') + 1;
    int nextTripId = _maxId(existingData, 'cave_trips') + 1;
    int nextTripPointId = _maxId(existingData, 'cave_trip_points') + 1;
    int nextDocToTripId =
      _maxId(existingData, 'documentation_files_to_cave_trips') + 1;

  print('  Next IDs: surfaceArea=$nextSurfaceAreaId cave=$nextCaveId '
      'caveArea=$nextCaveAreaId cavePlace=$nextCavePlaceId '
      'docFile=$nextDocFileId docGeo=$nextDocGeoId '
      'raster=$nextRasterMapId rasterPoint=$nextRasterPointId '
      'trip=$nextTripId tripPoint=$nextTripPointId docTrip=$nextDocToTripId');

  // ------------------------------------------------------------------
  //  Step 3: Generate extra test data
  // ------------------------------------------------------------------
  print('\n=== Generating extra test data ===');
  final buf = StringBuffer();
  buf.writeln('-- Extra test data generated by tool/generate_test_data.dart');
  buf.writeln('-- Generated on: ${DateTime.now().toIso8601String()}');
  _emitCompatibilitySchema(
    buf,
    addDocFileTypeColumn: !hasDocFileType,
    addDocGeoTable: !hasDocGeoTable,
    addTripsTable: !hasTripsTable,
    addTripPointsTable: !hasTripPointsTable,
    addDocToTripTable: !hasDocToTripTable,
  );
  buf.writeln('BEGIN TRANSACTION;\n');

  // Track generated objects for cross-referencing
  final generatedSurfaceAreas = <int, String>{}; // id -> title
  final generatedCaves = <int, String>{}; // id -> title
  final generatedCaveAreas = <int, ({int caveId, String title})>{};
  // cave_id -> list of area ids
  final caveToAreaIds = <int, List<int>>{};
  // cave_id -> list of cave place ids
  final caveToPlaceIds = <int, List<int>>{};
  // cave_id -> list of generated documentation_file ids
  final caveToDocIds = <int, List<int>>{};
  final enrichedCaveIds = <int>{};

  // ---------- 1. Surface areas ----------
  if (kGenerateSurfaceAreas) {
    final count = _randBetween(rng, kSurfaceAreasMin, kSurfaceAreasMax);
    print('  Surface areas: $count');
    final usedNames = <String>{};
    for (int i = 0; i < count; i++) {
      final name = _uniqueName(rng, kSurfaceAreaNames, usedNames);
      usedNames.add(name);
      final id = nextSurfaceAreaId++;
      generatedSurfaceAreas[id] = name;
      final desc = _fillTemplate(
          rng, kCaveDescriptionTemplates[rng.nextInt(kCaveDescriptionTemplates.length)]);
      buf.writeln(
          "INSERT INTO surface_areas (id, title, description, created_at) "
          "VALUES ($id, ${_esc(name)}, ${_esc(desc)}, ${_nowEpoch()});");
    }
    buf.writeln();
  }

  // ---------- 2. Caves ----------
  if (kGenerateCaves) {
    final count = _randBetween(rng, kCavesMin, kCavesMax);
    print('  Caves: $count');
    final usedNames = <String>{};
    final saIds = generatedSurfaceAreas.keys.toList();
    for (int i = 0; i < count; i++) {
      final name = _uniqueCaveName(rng, usedNames);
      usedNames.add(name);
      final id = nextCaveId++;
      generatedCaves[id] = name;
      final saId = saIds.isNotEmpty ? saIds[rng.nextInt(saIds.length)] : null;
      final desc = _fillTemplate(
          rng, kCaveDescriptionTemplates[rng.nextInt(kCaveDescriptionTemplates.length)]);
      buf.writeln("INSERT INTO caves (id, title, description, surface_area_id, created_at) "
          "VALUES ($id, ${_esc(name)}, ${_esc(desc)}, ${saId ?? 'NULL'}, ${_nowEpoch()});");
    }
    buf.writeln();
  }

  // ---------- 3. Cave areas ----------
  if (kGenerateCaveAreas) {
    int totalAreas = 0;
    for (final caveId in generatedCaves.keys) {
      final count =
          _randBetween(rng, kCaveAreasPerCaveMin, kCaveAreasPerCaveMax);
      final usedNames = <String>{};
      caveToAreaIds[caveId] = [];
      for (int i = 0; i < count; i++) {
        final name = _uniqueName(rng, kCaveAreaNames, usedNames);
        usedNames.add(name);
        final id = nextCaveAreaId++;
        generatedCaveAreas[id] = (caveId: caveId, title: name);
        caveToAreaIds[caveId]!.add(id);
        buf.writeln(
            "INSERT INTO cave_areas (id, title, cave_id, created_at) "
            "VALUES ($id, ${_esc(name)}, $caveId, ${_nowEpoch()});");
        totalAreas++;
      }
    }
    print('  Cave areas: $totalAreas');
    buf.writeln();
  }

  // ---------- 4. Cave places ----------
  if (kGenerateCavePlaces) {
    int totalPlaces = 0;
    int qrCounter = _maxQrCode(existingData) + 1;
    for (final caveId in generatedCaves.keys) {
      final count =
          _randBetween(rng, kCavePlacesPerCaveMin, kCavePlacesPerCaveMax);
      final areaIds = caveToAreaIds[caveId] ?? [];
      final usedNames = <String>{};
      caveToPlaceIds[caveId] = [];
      for (int i = 0; i < count; i++) {
        final name = _uniqueCavePlaceName(rng, i, usedNames);
        usedNames.add(name);
        final id = nextCavePlaceId++;
        caveToPlaceIds[caveId]!.add(id);
        // Assign to an area ~60% of the time if areas exist
        int? areaId;
        if (areaIds.isNotEmpty && rng.nextDouble() < 0.6) {
          areaId = areaIds[rng.nextInt(areaIds.length)];
        }
        // Assign QR code ~70% of the time
        int? qr;
        if (rng.nextDouble() < 0.7) {
          qr = qrCounter++;
        }
        final desc = _fillTemplate(
            rng,
            kCavePlaceDescriptionTemplates[
                rng.nextInt(kCavePlaceDescriptionTemplates.length)]);
        buf.writeln(
            "INSERT INTO cave_places (id, title, description, cave_id, place_qr_code_identifier, cave_area_id, created_at) "
            "VALUES ($id, ${_esc(name)}, ${_esc(desc)}, $caveId, ${qr ?? 'NULL'}, ${areaId ?? 'NULL'}, ${_nowEpoch()});");
        totalPlaces++;
      }
    }
    print('  Cave places: $totalPlaces');
    buf.writeln();
  }

  // ---------- 5. Documentation files (text type) ----------
  if (kGenerateDocuments) {
    // Pick a pool of templates to choose from
    final templatePool = <String>[];
    final templateIndices = <int>{};
    while (templateIndices.length < kDocTemplatePoolSize &&
        templateIndices.length < kDocumentTextTemplates.length) {
      templateIndices.add(rng.nextInt(kDocumentTextTemplates.length));
    }
    for (final idx in templateIndices) {
      templatePool.add(kDocumentTextTemplates[idx]);
    }

    int totalDocs = 0;
    for (final caveId in generatedCaves.keys) {
      caveToDocIds.putIfAbsent(caveId, () => []);
      final count = _randBetween(rng, kDocsPerCaveMin, kDocsPerCaveMax);
      for (int i = 0; i < count; i++) {
        final fileId = nextDocFileId++;
        final template = templatePool[rng.nextInt(templatePool.length)];
        final text = _fillTemplate(rng, template);
        final title = 'Document ${generatedCaves[caveId]} #${i + 1}';
        final fileName = 'doc_cave${caveId}_${i + 1}.txt';
        final fileSize = text.length;

        buf.writeln(
            "INSERT INTO documentation_files (id, title, description, file_name, file_size, file_hash, file_type, created_at) "
            "VALUES ($fileId, ${_esc(title)}, ${_esc(text)}, ${_esc(fileName)}, $fileSize, NULL, 'text_document', ${_nowEpoch()});");
        caveToDocIds[caveId]!.add(fileId);

        if (kGenerateGeofeatureLinks) {
          nextDocGeoId = _addGeofeatureLinksForDoc(
            rng: rng,
            buf: buf,
            docId: fileId,
            caveId: caveId,
            caveAreaIds: caveToAreaIds[caveId] ?? const [],
            cavePlaceIds: caveToPlaceIds[caveId] ?? const [],
            nextDocGeoId: nextDocGeoId,
          );
        }

        totalDocs++;
      }
    }
    print('  Documentation text files: $totalDocs');
    buf.writeln();
  }

  // ---------- 6. Cave pictures as documentation files ----------
  if (kGeneratePictureDocuments) {
    final pictureDir = Directory('test_data/pictures/cave');
    final pictureFiles = pictureDir
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.toLowerCase().endsWith('.jpg') ||
            f.path.toLowerCase().endsWith('.jpeg') ||
            f.path.toLowerCase().endsWith('.png') ||
            f.path.toLowerCase().endsWith('.webp'))
        .toList();

    int totalPictures = 0;
    for (final caveId in generatedCaves.keys) {
      caveToDocIds.putIfAbsent(caveId, () => []);
      if (pictureFiles.isEmpty) {
        break;
      }
      final count =
          _randBetween(rng, kPicturesPerCaveMin, kPicturesPerCaveMax);
      for (int i = 0; i < count; i++) {
        final pic = pictureFiles[rng.nextInt(pictureFiles.length)];
        final fileId = nextDocFileId++;
        final fileName = pic.uri.pathSegments.isNotEmpty
            ? pic.uri.pathSegments.last
            : pic.path.split('\\').last;
        final title = 'Foto ${generatedCaves[caveId]} #${i + 1}';
        final desc = 'Fotografie de pestera pentru arhiva tehnica.';
        final fileSize = pic.lengthSync();

        buf.writeln(
            "INSERT INTO documentation_files (id, title, description, file_name, file_size, file_hash, file_type, created_at) "
            "VALUES ($fileId, ${_esc(title)}, ${_esc(desc)}, ${_esc(fileName)}, $fileSize, NULL, 'photo', ${_nowEpoch()});");
        caveToDocIds[caveId]!.add(fileId);

        if (kGenerateGeofeatureLinks) {
          nextDocGeoId = _addGeofeatureLinksForDoc(
            rng: rng,
            buf: buf,
            docId: fileId,
            caveId: caveId,
            caveAreaIds: caveToAreaIds[caveId] ?? const [],
            cavePlaceIds: caveToPlaceIds[caveId] ?? const [],
            nextDocGeoId: nextDocGeoId,
          );
        }

        totalPictures++;
      }
    }
    print('  Documentation picture files: $totalPictures');
    buf.writeln();
  }

  // ---------- 7. Enrich existing caves without data ----------
  if (kEnrichExistingCavesWithoutData) {
    final caveTitles = _loadCaveTitles(sourceDbPath);
    final missingStates = _loadCavesMissingData(
      dbPath: sourceDbPath,
      hasDocFileType: hasDocFileType,
      hasDocGeoTable: hasDocGeoTable,
      hasDocCaveId: hasDocCaveId,
    );

    int addedAreas = 0;
    int addedPlaces = 0;
    int addedTextDocs = 0;
    int addedPictures = 0;

    final pictureFiles = _loadPictureFiles();
    final templatePool = _pickRandomTemplates(
      rng,
      kDocumentTextTemplates,
      kDocTemplatePoolSize,
    );

    for (final state in missingStates) {
      if (!state.hasAnyNeed) {
        continue;
      }
      final caveId = state.caveId;
      final caveTitle = caveTitles[caveId] ?? 'Pestera #$caveId';
      enrichedCaveIds.add(caveId);

      caveToAreaIds.putIfAbsent(caveId, () =>
          _queryIntList(sourceDbPath, 'SELECT id FROM cave_areas WHERE cave_id = $caveId;'));
      caveToPlaceIds.putIfAbsent(caveId, () =>
          _queryIntList(sourceDbPath, 'SELECT id FROM cave_places WHERE cave_id = $caveId;'));
      caveToDocIds.putIfAbsent(caveId, () => []);

      if (state.needsAreas) {
        final count = _randBetween(
          rng,
          max(1, kCaveAreasPerCaveMin),
          max(1, kCaveAreasPerCaveMax),
        );
        final usedNames = <String>{};
        for (int i = 0; i < count; i++) {
          final name = _uniqueName(rng, kCaveAreaNames, usedNames);
          usedNames.add(name);
          final areaId = nextCaveAreaId++;
          caveToAreaIds[caveId]!.add(areaId);
          buf.writeln(
              "INSERT INTO cave_areas (id, title, cave_id, created_at) VALUES ($areaId, ${_esc(name)}, $caveId, ${_nowEpoch()});");
          addedAreas++;
        }
      }

      if (state.needsPlaces) {
        final count = _randBetween(rng, kCavePlacesPerCaveMin, kCavePlacesPerCaveMax);
        final usedNames = <String>{};
        int qrCounter = _maxQrCode(existingData) + 100000 + caveId;
        for (int i = 0; i < count; i++) {
          final placeId = nextCavePlaceId++;
          final name = _uniqueCavePlaceName(rng, i, usedNames);
          usedNames.add(name);
          int? areaId;
          final areaIds = caveToAreaIds[caveId] ?? const [];
          if (areaIds.isNotEmpty && rng.nextDouble() < 0.6) {
            areaId = areaIds[rng.nextInt(areaIds.length)];
          }
          final desc = _fillTemplate(
            rng,
            kCavePlaceDescriptionTemplates[
                rng.nextInt(kCavePlaceDescriptionTemplates.length)],
          );
          buf.writeln(
              "INSERT INTO cave_places (id, title, description, cave_id, place_qr_code_identifier, cave_area_id, created_at) VALUES ($placeId, ${_esc(name)}, ${_esc(desc)}, $caveId, $qrCounter, ${areaId ?? 'NULL'}, ${_nowEpoch()});");
          caveToPlaceIds[caveId]!.add(placeId);
          qrCounter++;
          addedPlaces++;
        }
      }

      if (state.needsTextDocs) {
        final count = _randBetween(
          rng,
          max(1, kDocsPerCaveMin),
          max(1, kDocsPerCaveMax),
        );
        for (int i = 0; i < count; i++) {
          final fileId = nextDocFileId++;
          final template = templatePool[rng.nextInt(templatePool.length)];
          final text = _fillTemplate(rng, template);
          final title = 'Document $caveTitle #${i + 1}';
          final fileName = 'doc_existing_c${caveId}_${i + 1}.txt';
          buf.writeln(
              "INSERT INTO documentation_files (id, title, description, file_name, file_size, file_hash, file_type, created_at) VALUES ($fileId, ${_esc(title)}, ${_esc(text)}, ${_esc(fileName)}, ${text.length}, NULL, 'text_document', ${_nowEpoch()});");
          caveToDocIds[caveId]!.add(fileId);
          if (kGenerateGeofeatureLinks) {
            nextDocGeoId = _addGeofeatureLinksForDoc(
              rng: rng,
              buf: buf,
              docId: fileId,
              caveId: caveId,
              caveAreaIds: caveToAreaIds[caveId] ?? const [],
              cavePlaceIds: caveToPlaceIds[caveId] ?? const [],
              nextDocGeoId: nextDocGeoId,
            );
          }
          addedTextDocs++;
        }
      }

      if (state.needsPictures && pictureFiles.isNotEmpty) {
        final count = _randBetween(
          rng,
          max(1, kPicturesPerCaveMin),
          max(1, kPicturesPerCaveMax),
        );
        for (int i = 0; i < count; i++) {
          final pic = pictureFiles[rng.nextInt(pictureFiles.length)];
          final fileId = nextDocFileId++;
          final fileName = pic.uri.pathSegments.isNotEmpty
              ? pic.uri.pathSegments.last
              : pic.path.split('\\').last;
          final title = 'Foto $caveTitle #${i + 1}';
          final desc = 'Fotografie de pestera pentru arhiva tehnica.';
          buf.writeln(
              "INSERT INTO documentation_files (id, title, description, file_name, file_size, file_hash, file_type, created_at) VALUES ($fileId, ${_esc(title)}, ${_esc(desc)}, ${_esc(fileName)}, ${pic.lengthSync()}, NULL, 'photo', ${_nowEpoch()});");
          caveToDocIds[caveId]!.add(fileId);
          if (kGenerateGeofeatureLinks) {
            nextDocGeoId = _addGeofeatureLinksForDoc(
              rng: rng,
              buf: buf,
              docId: fileId,
              caveId: caveId,
              caveAreaIds: caveToAreaIds[caveId] ?? const [],
              cavePlaceIds: caveToPlaceIds[caveId] ?? const [],
              nextDocGeoId: nextDocGeoId,
            );
          }
          addedPictures++;
        }
      }
    }

    print('  Enriched caves: ${enrichedCaveIds.length}');
    print('  Enrichment added cave areas: $addedAreas');
    print('  Enrichment added cave places: $addedPlaces');
    print('  Enrichment added text docs: $addedTextDocs');
    print('  Enrichment added pictures: $addedPictures');
    buf.writeln();
  }

  // ---------- 8. Raster maps cloned from existing + place points ----------
  if (kGenerateRasterMapsWithBindings) {
    final templates = _loadRasterTemplates(sourceDbPath);
    int totalMaps = 0;
    int totalMapPoints = 0;
    int targetGenerated = 0;
    int targetEnriched = 0;
    int targetExistingNoRaster = 0;
    final cavesForRaster = <int>{};
    if (kGenerateRasterForGeneratedCaves) {
      cavesForRaster.addAll(generatedCaves.keys);
      targetGenerated = generatedCaves.length;
    }
    if (kGenerateRasterForEnrichedCaves) {
      cavesForRaster.addAll(enrichedCaveIds);
      targetEnriched = enrichedCaveIds.length;
    }
    if (kGenerateRasterForExistingCavesWithoutRaster) {
      final missingRaster = _loadCavesWithoutRasterMaps(sourceDbPath);
      cavesForRaster.addAll(missingRaster);
      targetExistingNoRaster = missingRaster.length;
    }

    for (final caveId in cavesForRaster) {
      caveToPlaceIds.putIfAbsent(
        caveId,
        () => _queryIntList(
          sourceDbPath, 'SELECT id FROM cave_places WHERE cave_id = $caveId;'),
      );
      caveToAreaIds.putIfAbsent(
        caveId,
        () => _queryIntList(
          sourceDbPath, 'SELECT id FROM cave_areas WHERE cave_id = $caveId;'),
      );

      final placeIds = caveToPlaceIds[caveId] ?? const <int>[];
      if (placeIds.isEmpty || templates.isEmpty) {
        continue;
      }

      final areaIds = caveToAreaIds[caveId] ?? const <int>[];
      final mapCount = _randBetween(rng, kRasterMapsPerCaveMin, kRasterMapsPerCaveMax);
      for (int m = 0; m < mapCount; m++) {
        final template = templates[rng.nextInt(templates.length)];
        final mapId = nextRasterMapId++;
        final title = '${template.title} [C$caveId #${m + 1}]';
        int? caveAreaId;
        if (areaIds.isNotEmpty && rng.nextDouble() < 0.35) {
          caveAreaId = areaIds[rng.nextInt(areaIds.length)];
        }
        buf.writeln(
            "INSERT INTO raster_maps (id, title, map_type, file_name, cave_id, cave_area_id, created_at) VALUES ($mapId, ${_esc(title)}, ${_esc(template.mapType)}, ${_esc(template.fileName)}, $caveId, ${caveAreaId ?? 'NULL'}, ${_nowEpoch()});");
        totalMaps++;

        final pointCountTarget =
            _randBetween(rng, kRasterMapPointsPerMapMin, kRasterMapPointsPerMapMax);
        final pointCount = min(pointCountTarget, placeIds.length);
        final localPlaces = [...placeIds]..shuffle(rng);
        for (int i = 0; i < pointCount; i++) {
          final placeId = localPlaces[i];
          final mapPointId = nextRasterPointId++;
          final x = rng.nextInt(kRasterPointMaxX + 1);
          final y = rng.nextInt(kRasterPointMaxY + 1);
          buf.writeln(
              "INSERT INTO cave_place_to_raster_map_definitions (id, x_coordinate, y_coordinate, cave_place_id, raster_map_id, created_at) VALUES ($mapPointId, $x, $y, $placeId, $mapId, ${_nowEpoch()});");
          totalMapPoints++;
        }
      }
    }

    print('  Raster target generated caves: $targetGenerated');
    print('  Raster target enriched caves: $targetEnriched');
    print('  Raster target existing without maps: $targetExistingNoRaster');
    print('  Raster maps added: $totalMaps');
    print('  Raster map place points added: $totalMapPoints');
    buf.writeln();
  }

  // ---------- 9. Cave trips + points + doc relations ----------
  if (kGenerateCaveTrips) {
    int totalTrips = 0;
    int totalTripPoints = 0;
    int totalDocToTrip = 0;

    for (final caveId in generatedCaves.keys) {
      final hasLowCount = rng.nextDouble() < kCaveTripsLowRangeProbability;
      final tripCount = hasLowCount
          ? _randBetween(
              rng, kCaveTripsPerCaveLowMin, kCaveTripsPerCaveLowMax)
          : _randBetween(
              rng, kCaveTripsPerCaveHighMin, kCaveTripsPerCaveHighMax);

      final cavePlaceIds = caveToPlaceIds[caveId] ?? const <int>[];
      final caveDocIds = caveToDocIds[caveId] ?? const <int>[];

      for (int t = 0; t < tripCount; t++) {
        final tripId = nextTripId++;
        final startedAt = _nowEpoch() - _randBetween(rng, 3600, 3600 * 24 * 120);
        final endedAt = startedAt + _randBetween(rng, 1800, 3600 * 10);
        final title = 'Tura ${generatedCaves[caveId]} #${t + 1}';
        final desc = _fillTemplate(
            rng,
            kCavePlaceDescriptionTemplates[
                rng.nextInt(kCavePlaceDescriptionTemplates.length)]);

        buf.writeln(
            "INSERT INTO cave_trips (id, cave_id, title, description, trip_started_at, trip_ended_at, created_at) "
            "VALUES ($tripId, $caveId, ${_esc(title)}, ${_esc(desc)}, $startedAt, $endedAt, ${_nowEpoch()});");
        totalTrips++;

        // Add cave_trip_points.
        final pointCount =
            _randBetween(rng, kTripPointsPerTripMin, kTripPointsPerTripMax);
        for (int p = 0; p < pointCount; p++) {
          if (cavePlaceIds.isEmpty) {
            break;
          }
          final placeId = cavePlaceIds[rng.nextInt(cavePlaceIds.length)];
          final scannedAt = startedAt + _randBetween(rng, 60, 3600 * 8) + p;
          final notes =
              'Punct marcat in timpul turei la minutul ${p + 1}.';
          final tripPointId = nextTripPointId++;
          buf.writeln(
              "INSERT INTO cave_trip_points (id, cave_trip_id, cave_place_id, scanned_at, notes, created_at) "
              "VALUES ($tripPointId, $tripId, $placeId, $scannedAt, ${_esc(notes)}, ${_nowEpoch()});");
          totalTripPoints++;
        }

        // Add relations to documentation files.
        final relationCount = _randBetween(
            rng, kDocToTripRelationsPerTripMin, kDocToTripRelationsPerTripMax);
        final usedDocIds = <int>{};
        for (int r = 0; r < relationCount; r++) {
          if (caveDocIds.isEmpty || usedDocIds.length >= caveDocIds.length) {
            break;
          }
          int docId = caveDocIds[rng.nextInt(caveDocIds.length)];
          while (usedDocIds.contains(docId)) {
            docId = caveDocIds[rng.nextInt(caveDocIds.length)];
          }
          usedDocIds.add(docId);
          final relationId = nextDocToTripId++;
          buf.writeln(
              "INSERT INTO documentation_files_to_cave_trips (id, documentation_file_id, cave_trip_id, created_at) "
              "VALUES ($relationId, $docId, $tripId, ${_nowEpoch()});");
          totalDocToTrip++;
        }
      }
    }

    print('  Cave trips: $totalTrips');
    print('  Cave trip points: $totalTripPoints');
    print('  Doc-trip relations: $totalDocToTrip');
    buf.writeln();
  }

  buf.writeln('COMMIT;');

  // Write extra data script
  File(kExtraDataFile).writeAsStringSync(buf.toString());
  print('\n  Extra test data -> $kExtraDataFile');

  // Write combined data (original + extra)
  final combined = StringBuffer();
  combined.writeln('-- Original data from $sourceDbPath');
  combined.writeln(existingData);
  combined.writeln();
  combined.writeln('-- =========================================');
  combined.writeln('-- Extra generated test data');
  combined.writeln('-- =========================================');
  combined.writeln();
  combined.write(buf.toString());
  File(kFullDataFile).writeAsStringSync(combined.toString());
  print('  Combined data  -> $kFullDataFile');

  // Write combined schema + original data + extra generated data.
  final schemaAndData = File(kSchemaAndDataFile).readAsStringSync();
  final combinedSchemaData = StringBuffer();
  combinedSchemaData.writeln('-- Original schema+data from $sourceDbPath');
  combinedSchemaData.writeln(schemaAndData);
  combinedSchemaData.writeln();
  combinedSchemaData.writeln('-- =========================================');
  combinedSchemaData.writeln('-- Extra generated test data');
  combinedSchemaData.writeln('-- =========================================');
  combinedSchemaData.writeln();
  combinedSchemaData.write(buf.toString());
  File(kSchemaAndFullDataFile).writeAsStringSync(combinedSchemaData.toString());
  print('  Combined schema+data -> $kSchemaAndFullDataFile');

  if (kGenerateSqliteDatabase) {
    _buildDatabaseFromSql(kGeneratedDbFile, kSchemaAndFullDataFile);
    print('  Generated DB   -> $kGeneratedDbFile');
  }

  print('\n=== Done ===');
}

// ---------------------------------------------------------------------------
//  HELPERS
// ---------------------------------------------------------------------------

/// Run sqlite3 CLI with a dot-command and capture output to a file.
void _runSqlite3(String dbPath, String dotCommand, String outputPath) {
  final result = Process.runSync(
    kSqlite3Cmd,
    [dbPath, dotCommand],
    stdoutEncoding: null,
  );
  if (result.exitCode != 0) {
    stderr.writeln('sqlite3 failed (exit ${result.exitCode}): ${result.stderr}');
    exit(1);
  }
  File(outputPath).writeAsBytesSync(result.stdout as List<int>);
}

/// Export data only using INSERT statements for each table.
void _exportDataOnly(String dbPath, String outputPath) {
  final buf = StringBuffer();
  buf.writeln('-- Data-only export from $dbPath');
  buf.writeln('-- Generated on: ${DateTime.now().toIso8601String()}');
  buf.writeln();
  for (final table in kOrderedTables) {
    final result = Process.runSync(
      kSqlite3Cmd,
      [dbPath, '.mode insert $table', 'SELECT * FROM $table;'],
    );
    if (result.exitCode != 0) {
      // Table may not exist in DB - skip silently
      continue;
    }
    final output = (result.stdout as String).trim();
    if (output.isNotEmpty) {
      buf.writeln('-- Table: $table');
      buf.writeln(output);
      buf.writeln();
    }
  }
  File(outputPath).writeAsStringSync(buf.toString());
}

/// Add schema compatibility statements for optional tables/columns.
void _emitCompatibilitySchema(
  StringBuffer buf, {
  required bool addDocFileTypeColumn,
  required bool addDocGeoTable,
  required bool addTripsTable,
  required bool addTripPointsTable,
  required bool addDocToTripTable,
}) {
  if (addDocFileTypeColumn) {
    buf.writeln(
        "ALTER TABLE documentation_files ADD COLUMN file_type TEXT(25) NOT NULL DEFAULT 'text_document';");
  }

  if (addDocGeoTable) {
    buf.writeln('CREATE TABLE IF NOT EXISTS documentation_files_to_geofeatures ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, '
        'geofeature_id INTEGER, '
        'geofeature_type TEXT(10) NOT NULL, '
        'documentation_file_id INTEGER NOT NULL REFERENCES documentation_files (id), '
        'updated_at INTEGER, '
        'deleted_at INTEGER, '
        'UNIQUE(geofeature_id, geofeature_type, documentation_file_id) ON CONFLICT ROLLBACK'
        ');');
  }

  if (addTripsTable) {
    buf.writeln('CREATE TABLE IF NOT EXISTS cave_trips ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, '
        'cave_id INTEGER NOT NULL REFERENCES caves (id), '
        'title TEXT(255) NOT NULL, '
        'description TEXT, '
        'trip_started_at INTEGER NOT NULL, '
        'trip_ended_at INTEGER, '
        'log TEXT, '
        'created_at INTEGER, '
        'updated_at INTEGER, '
        'deleted_at INTEGER'
        ');');
  }

  if (addTripPointsTable) {
    buf.writeln('CREATE TABLE IF NOT EXISTS cave_trip_points ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, '
        'cave_trip_id INTEGER NOT NULL REFERENCES cave_trips (id), '
        'cave_place_id INTEGER NOT NULL REFERENCES cave_places (id), '
        'scanned_at INTEGER NOT NULL, '
        'notes TEXT, '
        'created_at INTEGER, '
        'updated_at INTEGER, '
        'deleted_at INTEGER, '
        'UNIQUE(cave_trip_id, cave_place_id, scanned_at) ON CONFLICT ROLLBACK'
        ');');
  }

  if (addDocToTripTable) {
    buf.writeln('CREATE TABLE IF NOT EXISTS documentation_files_to_cave_trips ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, '
        'documentation_file_id INTEGER NOT NULL REFERENCES documentation_files (id), '
        'cave_trip_id INTEGER NOT NULL REFERENCES cave_trips (id), '
        'created_at INTEGER, '
        'deleted_at INTEGER, '
        'UNIQUE(documentation_file_id, cave_trip_id) ON CONFLICT ROLLBACK'
        ');');
  }

  if (addDocFileTypeColumn ||
      addDocGeoTable ||
      addTripsTable ||
      addTripPointsTable ||
      addDocToTripTable) {
    buf.writeln();
  }
}

bool _tableExists(String dbPath, String tableName) {
  final result = Process.runSync(
    kSqlite3Cmd,
    [
      dbPath,
      "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='${tableName.replaceAll("'", "''")}';",
    ],
  );
  if (result.exitCode != 0) {
    return false;
  }
  final out = (result.stdout as String).trim();
  return out == '1';
}

String? _resolveSourceDbPath() {
  if (File(kSourceDbPath).existsSync()) {
    return kSourceDbPath;
  }
  for (final path in kSourceDbFallbackPaths) {
    if (File(path).existsSync()) {
      return path;
    }
  }
  return null;
}

bool _tableHasColumn(String dbPath, String tableName, String columnName) {
  final result = Process.runSync(
    kSqlite3Cmd,
    [dbPath, 'PRAGMA table_info($tableName);'],
  );
  if (result.exitCode != 0) {
    return false;
  }
  final output = result.stdout as String;
  final pattern = RegExp(
      r'^\d+\|'+ RegExp.escape(columnName) + r'\|',
      caseSensitive: false,
      multiLine: true);
  return pattern.hasMatch(output);
}

int _addGeofeatureLinksForDoc({
  required Random rng,
  required StringBuffer buf,
  required int docId,
  required int caveId,
  required List<int> caveAreaIds,
  required List<int> cavePlaceIds,
  required int nextDocGeoId,
}) {
  final links = <({String type, int id})>[];

  // Always link to cave.
  links.add((type: 'cave', id: caveId));

  // Optionally link to cave area and cave place.
  if (caveAreaIds.isNotEmpty && rng.nextDouble() < 0.6) {
    links.add((type: 'cave_area', id: caveAreaIds[rng.nextInt(caveAreaIds.length)]));
  }
  if (cavePlaceIds.isNotEmpty && rng.nextDouble() < 0.75) {
    links.add((type: 'cave_place', id: cavePlaceIds[rng.nextInt(cavePlaceIds.length)]));
  }

  for (final link in links) {
    buf.writeln(
        "INSERT INTO documentation_files_to_geofeatures (id, geofeature_id, geofeature_type, documentation_file_id, updated_at) "
        "VALUES ($nextDocGeoId, ${link.id}, '${link.type}', $docId, ${_nowEpoch()});");
    nextDocGeoId++;
  }

  return nextDocGeoId;
}

List<File> _loadPictureFiles() {
  final pictureDir = Directory('test_data/pictures/cave');
  if (!pictureDir.existsSync()) {
    return const <File>[];
  }
  return pictureDir
      .listSync()
      .whereType<File>()
      .where((f) =>
          f.path.toLowerCase().endsWith('.jpg') ||
          f.path.toLowerCase().endsWith('.jpeg') ||
          f.path.toLowerCase().endsWith('.png') ||
          f.path.toLowerCase().endsWith('.webp'))
      .toList();
}

List<String> _pickRandomTemplates(
  Random rng,
  List<String> source,
  int count,
) {
  final indexes = <int>{};
  while (indexes.length < count && indexes.length < source.length) {
    indexes.add(rng.nextInt(source.length));
  }
  return indexes.map((idx) => source[idx]).toList();
}

Map<int, String> _loadCaveTitles(String dbPath) {
  final rows = _queryRows(dbPath, 'SELECT id, title FROM caves;');
  final out = <int, String>{};
  for (final row in rows) {
    if (row.length < 2) {
      continue;
    }
    final id = int.tryParse(row[0]);
    if (id == null) {
      continue;
    }
    out[id] = row[1];
  }
  return out;
}

List<CaveMissingDataState> _loadCavesMissingData({
  required String dbPath,
  required bool hasDocFileType,
  required bool hasDocGeoTable,
  required bool hasDocCaveId,
}) {
  final caveIds = _queryIntList(dbPath, 'SELECT id FROM caves;');
  final out = <CaveMissingDataState>[];

  for (final caveId in caveIds) {
    final areas = _queryScalarInt(
        dbPath, 'SELECT COUNT(*) FROM cave_areas WHERE cave_id = $caveId;');
    final places = _queryScalarInt(
        dbPath, 'SELECT COUNT(*) FROM cave_places WHERE cave_id = $caveId;');

    final textDocs = _countDocsForCave(
      dbPath: dbPath,
      caveId: caveId,
      hasDocFileType: hasDocFileType,
      hasDocGeoTable: hasDocGeoTable,
      hasDocCaveId: hasDocCaveId,
      wantedType: 'text_document',
    );
    final pictureDocs = _countDocsForCave(
      dbPath: dbPath,
      caveId: caveId,
      hasDocFileType: hasDocFileType,
      hasDocGeoTable: hasDocGeoTable,
      hasDocCaveId: hasDocCaveId,
      wantedType: 'photo',
    );

    out.add(CaveMissingDataState(
      caveId: caveId,
      needsAreas: areas == 0,
      needsPlaces: places == 0,
      needsTextDocs: textDocs == 0,
      needsPictures: pictureDocs == 0,
    ));
  }

  return out;
}

int _countDocsForCave({
  required String dbPath,
  required int caveId,
  required bool hasDocFileType,
  required bool hasDocGeoTable,
  required bool hasDocCaveId,
  required String wantedType,
}) {
  final conditions = <String>[];
  if (hasDocGeoTable) {
    conditions.add(
        'EXISTS (SELECT 1 FROM documentation_files_to_geofeatures g WHERE g.documentation_file_id = d.id AND g.geofeature_type = ''cave'' AND g.geofeature_id = $caveId)');
  }
  if (hasDocCaveId) {
    conditions.add('d.cave_id = $caveId');
  }
  if (conditions.isEmpty) {
    return 0;
  }

  String typeFilter;
  if (hasDocFileType) {
    typeFilter = "d.file_type = '$wantedType'";
  } else if (wantedType == 'photo') {
    typeFilter =
        "(LOWER(d.file_name) LIKE '%.jpg' OR LOWER(d.file_name) LIKE '%.jpeg' OR LOWER(d.file_name) LIKE '%.png' OR LOWER(d.file_name) LIKE '%.webp')";
  } else {
    typeFilter = "LOWER(d.file_name) LIKE '%.txt'";
  }

  final sql =
      'SELECT COUNT(*) FROM documentation_files d WHERE ($typeFilter) AND (${conditions.join(' OR ')});';
  return _queryScalarInt(dbPath, sql);
}

List<RasterTemplate> _loadRasterTemplates(String dbPath) {
  final rows = _queryRows(
    dbPath,
    "SELECT title, map_type, file_name FROM raster_maps WHERE file_name IS NOT NULL AND file_name != '';",
  );
  return rows
      .where((r) => r.length >= 3)
      .map((r) => RasterTemplate(title: r[0], mapType: r[1], fileName: r[2]))
      .toList();
}

List<int> _loadCavesWithoutRasterMaps(String dbPath) {
  return _queryIntList(
    dbPath,
    'SELECT c.id FROM caves c LEFT JOIN raster_maps rm ON rm.cave_id = c.id '
    'GROUP BY c.id HAVING COUNT(rm.id) = 0;',
  );
}

List<int> _queryIntList(String dbPath, String sql) {
  return _queryRows(dbPath, sql)
      .map((r) => r.isNotEmpty ? int.tryParse(r[0]) : null)
      .whereType<int>()
      .toList();
}

int _queryScalarInt(String dbPath, String sql) {
  final rows = _queryRows(dbPath, sql);
  if (rows.isEmpty || rows.first.isEmpty) {
    return 0;
  }
  return int.tryParse(rows.first.first) ?? 0;
}

List<List<String>> _queryRows(String dbPath, String sql) {
  final result = Process.runSync(
    kSqlite3Cmd,
    [dbPath, '-separator', '\t', sql],
  );
  if (result.exitCode != 0) {
    return const <List<String>>[];
  }
  final lines = (result.stdout as String)
      .split(RegExp(r'\r?\n'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  return lines.map((line) => line.split('\t')).toList();
}

/// Build a SQLite database file by importing SQL script content.
void _buildDatabaseFromSql(String dbPath, String sqlPath) {
  final dbFile = File(dbPath);
  if (dbFile.existsSync()) {
    dbFile.deleteSync();
  }

  final sqliteSqlPath = sqlPath.replaceAll('\\', '/');
  final result = Process.runSync(
    kSqlite3Cmd,
    [dbPath, '.read $sqliteSqlPath'],
  );

  if (result.exitCode != 0) {
    stderr.writeln(
        'Failed to build SQLite DB from $sqlPath (exit ${result.exitCode}): ${result.stderr}');
    exit(1);
  }
}

/// Find the maximum id value inserted for a given table from SQL INSERT text.
int _maxId(String sql, String tableName) {
  final pattern = RegExp(
    r'INSERT\s+INTO\s+["\x27]?' +
        RegExp.escape(tableName) +
        r'["\x27]?\s+VALUES\s*\(\s*(\d+)',
    caseSensitive: false,
  );
  int maxVal = 0;
  for (final match in pattern.allMatches(sql)) {
    final id = int.tryParse(match.group(1) ?? '') ?? 0;
    if (id > maxVal) maxVal = id;
  }
  return maxVal;
}

/// Find the max QR code from existing cave_places inserts.
int _maxQrCode(String sql) {
  final pattern = RegExp(
    r'INSERT\s+INTO\s+["\x27]?cave_places["\x27]?\s+VALUES\s*\('
    r'[^,]+,[^,]+,[^,]+,[^,]+,\s*(\d+)',
    caseSensitive: false,
  );
  int maxVal = 0;
  for (final match in pattern.allMatches(sql)) {
    final qr = int.tryParse(match.group(1) ?? '') ?? 0;
    if (qr > maxVal) maxVal = qr;
  }
  return maxVal;
}

/// Random int in [min, max] inclusive.
int _randBetween(Random rng, int min, int max) {
  return min + rng.nextInt(max - min + 1);
}

/// Replace all {N} placeholders with random numbers.
String _fillTemplate(Random rng, String template) {
  return template.replaceAllMapped(
    RegExp(r'\{N\}'),
    (_) => '${rng.nextInt(500) + 1}',
  );
}

/// Epoch seconds for "now".
int _nowEpoch() =>
    DateTime.now().millisecondsSinceEpoch ~/ 1000;

/// SQL-escape a string value (single quotes).
String _esc(String value) {
  final escaped = value.replaceAll("'", "''");
  return "'$escaped'";
}

/// Pick a unique name from a list, appending a number if needed.
String _uniqueName(Random rng, List<String> pool, Set<String> used) {
  for (int attempt = 0; attempt < 50; attempt++) {
    final candidate = pool[rng.nextInt(pool.length)];
    if (!used.contains(candidate)) return candidate;
  }
  String base = pool[rng.nextInt(pool.length)];
  int suffix = 2;
  while (used.contains('$base $suffix')) {
    suffix++;
  }
  return '$base $suffix';
}

/// Generate a unique cave name.
String _uniqueCaveName(Random rng, Set<String> used) {
  for (int attempt = 0; attempt < 100; attempt++) {
    final prefix = kCaveNamePrefixes[rng.nextInt(kCaveNamePrefixes.length)];
    final suffix = kCaveNameSuffixes[rng.nextInt(kCaveNameSuffixes.length)];
    final name = '$prefix $suffix';
    if (!used.contains(name)) return name;
  }
  final prefix = kCaveNamePrefixes[rng.nextInt(kCaveNamePrefixes.length)];
  final suffix = kCaveNameSuffixes[rng.nextInt(kCaveNameSuffixes.length)];
  int n = 2;
  while (used.contains('$prefix $suffix $n')) n++;
  return '$prefix $suffix $n';
}

/// Generate a unique cave place name.
String _uniqueCavePlaceName(Random rng, int index, Set<String> used) {
  final prefix = kCavePlacePrefixes[rng.nextInt(kCavePlacePrefixes.length)];
  final candidate = '$prefix ${index + 1}';
  if (!used.contains(candidate)) return candidate;
  for (int c = 65; c < 91; c++) {
    final name = '$candidate${String.fromCharCode(c)}';
    if (!used.contains(name)) return name;
  }
  return '$candidate-${rng.nextInt(1000)}';
}
