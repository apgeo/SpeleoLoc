# Noutăți

[← Înapoi la cuprins](README.md)

Ce a adus fiecare versiune SpeleoLoc, de la cea mai nouă la cea mai veche.
Fiecare versiune este publicată pe GitHub; [ultima versiune publicată](https://github.com/apgeo/SpeleoLoc/releases/latest)
are întotdeauna cel mai nou APK — vedeți [Instalarea APK-ului de Android](getting-started.md#instalarea-apk-ului-de-android).

> SpeleoLoc este software în stadiu alfa. O versiune marcată *schimbă baza
> de date* sau *schimbă formatul arhivei* nu poate fi anulată instalând o
> versiune mai veche: exportați-vă datele înainte de actualizare și
> actualizați toate dispozitivele care se sincronizează împreună.

## În versiunea următoare

Deja în sursele aplicației, dar încă nu într-un APK publicat:

- **Importul CSV** citește fișiere separate prin punct și virgulă, așa cum
  le scriu foile de calcul setate pe română, luând separatorul din rândul
  de antet. Numele locurilor se potrivesc acum fie că au fost scrise cu
  sedilă (ş, ţ), fie cu virgulă dedesubt (ș, ț). Vedeți
  [Import CSV](features/csv-import.md).
- **Ture**: o tură nu mai poate fi pornită cât timp alta înregistrează pe
  acest telefon.
- **Sincronizare și arhive**: o intrare de arhivă care nu poate fi
  extrasă este raportată, în loc să oprească tot importul; o rulare FTP
  eșuată ține minte arhivele deja importate și face curat după ea oricum
  s-ar încheia. Arhivele mari folosesc mai puțină memorie.
- **Restaurare**: copiile bazei de date puse deoparte de înlocuiri eșuate
  sunt șterse după 30 de zile; cea mai nouă copie este păstrată
  întotdeauna.
- Au fost adăugate etichete românești lipsă.

## 0.4.2-alpha — 9 noiembrie 2026

*Schimbă baza de date și formatul arhivei.* APK-ul publicat este o
versiune completă: toate funcțiile sunt pornite, inclusiv uneltele pentru
dezvoltatori și datele de exemplu descărcabile.

### Pe scurt

- **Beaconuri BLE și taguri Ruuvi** — telefonul recunoaște etichetele din
  locurile peșterii, pe Android și în fundal, cu o alertă sonoră.
- **Modele 3D de topografie** — topografii Therion `.lox` și Survex `.3d`
  într-un vizualizator 3D, cu locurile peșterii pe stații.
- **Harta peșterii** — toate intrările de peșteri pe o hartă geografică ce
  merge și offline, cu GPS, măsurare și schimb GPX/KML.
- **Turele** se maturizează — participanți, ore corectate, puncte din
  fotografiile și filmările dumneavoastră, puncte editabile.
- **Server de club (SilexGIS)** — sincronizare în ambele sensuri cu o
  instalare SilexGIS a clubului.
- **SFTP** cu chei de server fixate înlocuiește FTPS la sincronizarea cu un
  server de fișiere.
- **Aplicația întreabă cine o folosește** la prima pornire.

### Toate adăugirile

**Beaconuri BLE și taguri Ruuvi** — [Beaconuri BLE](features/ble-beacons.md), [Taguri senzor Ruuvi](features/ruuvi-sensors.md)

- Înregistrați beaconuri în locurile peșterii și detectați-le automat cât
  timp aplicația este deschisă, iar pe Android și în fundal, cu o alertă
  sonoră. Interval de scanare de până la 5 s, sunet pornit sau oprit, un
  comutator rapid în meniul lateral.
- Gestionarea etichetelor cu titlu, descriere și fotografie; un ecran de
  diagnostic Beacon Lab.
- Taguri Ruuvi: pagină cu senzorii în timp real, descărcarea istoricului
  păstrat pe tag, cu grafic și export CSV.

**Modele 3D de topografie** — [Modele 3D de topografie](features/3d-models.md)

- Vizualizarea modelelor `.lox` și `.3d` atașate unei peșteri: rotire,
  zoom, vedere în plan și din lateral.
- Asocierea locurilor peșterii cu stații și capete de vize laterale;
  marcaje, informații despre stație și trasee.
- Deschiderea modelului unei peșteri din locurile ei, din hărți, din lista
  de locuri și din ture.

**Harta peșterii** — [Harta peșterii](features/surface-map.md), [GPS și coordonate](features/gps-and-coordinates.md)

- Hartă pe tot ecranul cu intrările și locurile peșterilor, cu hărți de
  bază online, o memorie de dale pentru lucru offline și straturi MBTiles
  importate ([straturi MBTiles offline](workflows/mbtiles-layers.md)).
- Poziție GPS și medierea mai multor citiri GPS; amplasarea intrărilor și
  a punctelor pe hartă cu un ac care se poate trage.
- Măsurarea distanței și a azimutului, grupări de marcaje, filtrare și
  grupare după zona peșterii.
- Coordonate UTM și DMS, afișate și introduse; export și import GPX și KML
  pentru locurile peșterii ([transfer de locuri](features/place-transfer.md)).

**Hărți** — [Hărți](features/raster-maps.md), [Vizualizatorul de hărți](features/map-viewer.md)

- Mod pe tot ecranul, filtre de imagine, o bară laterală de unelte, o
  așezare pentru telefonul ținut orizontal și estomparea marcajelor
  filtrate.

**Ture** — [Ture](features/trips.md), [Desfășurarea unei ture](workflows/running-a-trip.md)

- Participanți și detalii pentru fiecare tură; ore de început și de
  sfârșit care pot fi corectate ulterior.
- **Puncte din imagini**: citirea orei la care au fost făcute și a
  etichetelor QR din fotografiile și filmările din subteran, transformate
  în puncte de tură, documente și legături.
- Adăugarea, mutarea și ștergerea punctelor de tură. Jurnalul turei
  rămâne așa cum a fost scris, cu un avertisment când rămâne în urma
  punctelor.
- O tură pusă pe pauză rămâne pe pauză după repornirea aplicației și după
  înlocuirea bazei de date.

**Documente** — [Documente](features/documents.md)

- Atașarea mai multor fișiere deodată, importul unui dosar întreg în
  peșteri și o galerie de imagini cu glisare și zoom.

**Coduri QR** — [Coduri QR](features/qr-codes.md), [Identificatori cod loc](features/place-code-identifiers.md)

- Generarea etichetelor în serie pentru peșteri din lista principală;
  generarea pe intervale pentru intrări și locuri încă neînregistrate;
  etichete pe care le poate deschide și un telefon fără SpeleoLoc.

**Server de club (SilexGIS)** — [Sincronizare Server de club](features/silexgis-sync.md)

- Autentificarea la instalarea SilexGIS a clubului și sincronizarea în
  ambele sensuri a peșterilor, zonelor, locurilor și ariilor de suprafață;
  acolo unde instalarea le oferă, și a turelor înregistrate, hărților și
  punctelor lor, fotografiilor și documentelor, persoanelor și modelelor 3D.
- O singură pagină pentru conflicte și deciziile recenzenților, inclusiv
  trimiterea versiunii dumneavoastră peste una mai nouă sau retrimiterea
  unui rând pe care serverul l-a șters.
- O întrebare înainte ca fișierele să circule prin datele mobile.

**Sincronizare FTP / SFTP** — [Sincronizare FTP / SFTP](features/ftp-sync.md), [Panoul de sincronizare](features/sync-and-change-log.md)

- Cheia serverului SFTP este reținută la prima conectare, iar o cheie
  schimbată este refuzată. FTPS a dispărut; profilurile lui trec pe SFTP.
- Un import întreabă înainte să șteargă înregistrări, iar o înregistrare
  al cărei nume este deja folosit aici așteaptă decizia dumneavoastră.
- Multe corecturi la sincronizare și arhive.

**Utilizatori** — [Utilizatori](features/users.md)

- Aplicația întreabă cine o folosește la prima pornire și din nou când
  utilizatorul selectat lipsește după o înlocuire a datelor sau a fost
  șters de o sincronizare. Utilizatorul selectat este păstrat la
  înlocuirea datelor.

**Import CSV** — [Import CSV](features/csv-import.md)

- Indexul local al peșterii și identificatorul zonei, intrare principală
  automată și o confirmare înainte de actualizarea peșterilor potrivite.

**Limbă și platforme**

- Componentele de bază ale aplicației, editorul de text și editorul foto
  urmează limba aplicației; traduceri lipsă adăugate.
- Raportare opțională a erorilor, suport pentru construirea pe iOS,
  pictograme adaptive.

## 0.2.1-alpha — 26 mai 2026

*Schimbă baza de date.* Arhivele de sincronizare trebuie să poarte acum un
identificator de dispozitiv; arhivele mai vechi, fără el, sunt refuzate.

### Pe scurt

- Identificatori cod loc și identificatori coduri QR, cu strategii de
  atribuire configurabile.
- Sincronizarea FTP și cea manuală, parțial reproiectate.
- Generarea textului raportului de tură; turele pornesc și se opresc la
  scanarea unei intrări.
- Listele de peșteri și de locuri pot fi sortate, grupate și selectate în
  bloc.
- Un singur mod de scanare QR peste tot.

### Toate adăugirile

**Identificatori cod loc** — [Identificatori cod loc](features/place-code-identifiers.md)

- Coduri de loc (PCI) și identificatori de referință pentru coduri QR
  (QCRI), generați în serie din lista locurilor, din formularul peșterii
  și din lista ariilor de suprafață, cu o pagină de setări pentru
  strategie și parametrii ei.
- QCRI în șabloanele etichetelor QR și în căutarea prin linkuri directe;
  importul CSV și sincronizarea le poartă pe amândouă.

**Sincronizare FTP** — [Sincronizare FTP / SFTP](features/ftp-sync.md), [Panoul de sincronizare](features/sync-and-change-log.md)

- Un panou de sincronizare comun, cu o filă pentru istoricul modificărilor.
- Pagina de progres FTP poate face pauză și relua, arată viteza și timpul
  rămas și duce la setări la o eroare de conexiune.
- Încărcarea este sărită când nu s-a schimbat nimic local; intrări în
  istoric pentru locuri, zone, arii de suprafață și documente.
- Opțiunea de a include parolele conturilor FTP într-un export de date.

**Ture** — [Ture](features/trips.md), [Rapoarte de tură](features/trip-reports.md)

- O tură pornește și se oprește automat când scanați o intrare de peșteră.
- Generarea jurnalului turei; scanările QR din pagina principală sunt
  înregistrate ca puncte de tură.

**Hărți** — [Hărți](features/raster-maps.md)

- Reordonarea hărților prin tragere; imaginile duplicate sunt recunoscute
  după amprenta lor.
- Vizualizator pe tot ecranul, butoane de zoom, o confirmare înainte de a
  șterge o hartă cu locuri definite și prima hartă care are locul scanat,
  selectată după o scanare QR.

**Liste și ecrane** — [Filtrare, sortare și selecție](features/lists-filter-sort-select.md), [Pagina principală](features/home-screen.md)

- Filtrare, sortare și grupare în listele de peșteri și de locuri;
  ștergerea peșterilor în bloc, cu dublă confirmare.
- Un meniu lateral compact, butoane în bara de unelte pentru
  sincronizare, arii de suprafață și importul CSV de peșteri, o bară de
  acțiuni rapide la documente și o întrebare despre modificările nesalvate
  la ieșirea dintr-un editor.
- O peșteră nouă primește automat un loc de intrare.

**Coduri QR** — [Coduri QR](features/qr-codes.md)

- Scanarea QR și linkurile directe folosesc aceeași căutare; linkurile
  sunt reduse la cod cu delimitatori configurabili.
- Module QR pătrate și selectoare de culoare pentru culorile etichetei.

**Altele**

- Înregistrare GPS cu altitudine pentru locurile peșterii, gândită pentru
  intrări.
- Date de exemplu care se descarcă și se importă din aplicație.
- O pagină de informații de depanare.

## 0.1.2-alpha — 23 aprilie 2026

*Schimbă baza de date.*

- **Rapoarte de tură** din șabloane ODT și DOCX — [Rapoarte de tură](features/trip-reports.md).
- **Harta turei**: redarea traseului, zoom pe tură și export PNG.
- **Tururi de ghidare** pe majoritatea ecranelor, cu acțiuni în meniu pentru
  reluare, resetare sau oprire.
- **Import CSV** de peșteri, pe lângă locuri, cu arii de suprafață și
  detectarea duplicatelor — [Import CSV](features/csv-import.md).
- **Intrări**: locurile pot fi marcate ca intrare sau ca intrare
  principală a peșterii.
- Prima versiune a acestei documentații.

## 0.1.1-alpha.2 — 8 aprilie 2026

*Schimbă baza de date.*

- **Ture în peșteră**: pornire, pauză, reluare și oprire; istoric, detalii
  și un jurnal editabil; puncte înregistrate din scanări QR; documente
  legate de tură — [Ture](features/trips.md).
- **Traseul turei pe hărți**, cu săgeți de direcție și puncte numerotate.
- **Meniu global** ca fereastră sau ca meniu lateral.
- Un ecran de alegere când un cod QR se potrivește mai multor locuri.
- Reportofonul poate face pauză, relua și înregistra peste o parte dintr-o
  înregistrare.
- Mod de selecție în lista locurilor, cu ștergere în bloc și etichete QR
  pentru locurile selectate.

## 0.1.0-alpha — 5 aprilie 2026

Prima versiune publică: peșteri și locuri din peșteră, hărți cu editor de
puncte, poziționare prin coduri QR, documente media, generarea codurilor
QR, export și import al bazei de date și import de date CSV.
