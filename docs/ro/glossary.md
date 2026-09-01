# Glosar

[← Înapoi la cuprins](README.md)

Fiecare termen folosit în acest wiki, cu o definiție scurtă și un link către
pagina care îl tratează pe larg. Denumirile sunt cele din interfața în limba
română; aplicația pornește în română, iar engleza se alege din
**Setări → General → Limba aplicației**.

## Peșteri, zone și locuri

### Zonă de suprafață
O regiune geografică de la suprafață, cu nume — un platou carstic, un masiv,
o vale — care grupează mai multe peșteri. Este opțională: o peșteră poate să
nu aibă niciuna. Poate purta și un **Identificator zonă generală**, folosit
la construirea codurilor structurate ale locurilor.
Vedeți [Arii de suprafață](features/surface-areas.md).

### Peșteră
Înregistrarea de cel mai înalt nivel. Conține un **Titlul peșterii**, o
**Descriere**, o zonă de suprafață opțională și un **Index local peșteră**
opțional — și nimic altceva: peștera în sine nu are cod QR și nici cod de
loc. Tot restul (locuri, zone ale peșterii, hărți raster, ture, beaconuri,
documente) atârnă de ea.
Vedeți [Peșteri și zone ale peșterii](features/caves-and-areas.md).

### Index local peșteră
Numărul scurt opțional care identifică o peșteră în interiorul ariei sale de
suprafață atunci când aplicația compune coduri structurate ale locurilor.
**Generează coduri QR pentru locuri (interval)**, din lista de locuri a unei
peșteri, refuză să pornească până când peștera are unul.
Vedeți [Peșteri și zone ale peșterii](features/caves-and-areas.md).

### Zonă peșteră
O zonă cu nume din *interiorul* unei singure peșteri — „Galeria principală”,
„Sala lacului” — folosită pentru gruparea locurilor la filtrare, sortare și
afișare. Opțională și niciodată împărțită între peșteri.
Vedeți [Peșteri și zone ale peșterii](features/caves-and-areas.md).

### Loc din peșteră
Un singur punct cu nume din interiorul unei peșteri și unitatea în jurul
căreia este construit SpeleoLoc: etichetele QR, documentele, pinurile de pe
hartă, beaconurile BLE și punctele turelor trimit toate către un loc din
peșteră. Are un **Titlu**, o **Descriere**, o **Adâncime '+/-'** opțională, o
zonă a peșterii opțională, coduri opționale, o poziție opțională și cele două
casete de bifat pentru intrare.
Vedeți [Locuri din peșteră](features/cave-places.md).

### Intrare în peșteră / Intrarea principală
Două casete de bifat la baza formularului locului din peșteră. O intrare
primește o pictogramă de ușă și eticheta **Intrare** în lista de locuri;
intrarea principală este marcată **Intrare principală**, cu albastru, și este
cea desenată ca reper mare pe harta peșterilor. O peșteră ar trebui să aibă
exact o intrare principală.
Vedeți [Locuri din peșteră](features/cave-places.md).

### Adâncime '+/-'
Adâncimea opțională, cu semn, a unui loc din peșteră față de intrare, în
metri — negativă sub, pozitivă deasupra. Intervalul acceptat este ±5000, iar
orice depășește ±1800 vă cere să confirmați că nu este o greșeală de tastare.
Vedeți [Locuri din peșteră](features/cave-places.md).

## Coduri, etichete și legături

### Identificator cod loc (PCI)
Codul **lizibil de către om** atașat unui loc din peșteră: ceea ce se
tipărește pe etichetă și ceea ce filtrează și sortează lista de locuri. Poate
fi orice șir de caractere, nu doar un număr, și poate codifica o ierarhie
țară / organizație / zonă / peșteră / loc. Ar trebui să fie unic în cadrul
unei peșteri.
Vedeți [Coduri de loc](features/place-code-identifiers.md).

### Identificator resursă cod QR (QCRI)
Conținutul **codificat efectiv în pixelii codului QR** și partea de după
`sp://` dintr-un link direct. Este fie o copie a codului locului (modul
identic), fie un hash scurt al acestuia (modul hash).
Vedeți [Coduri de loc](features/place-code-identifiers.md).

### Mod identic / mod hash
Cele două valori ale setării **Identificator cod QR**. **Identic cu codul
locului** copiază codul locului în conținutul codului QR, așa că cine citește
eticheta poate citi și codul. **Hash (identificator scurt derivat)** pune
acolo un hash scurt, ceea ce ține schema de numerotare departe de etichetă.
Vedeți [Coduri de loc](features/place-code-identifiers.md).

### Strategia codurilor de loc
Regula pe care o urmează aplicația când completează coduri de loc în lot. Se
alege din **Setări → Identificatori cod loc → Strategie**: **Ierarhic
global**, **Secvențial per peșteră** sau **Secvențial per zonă**. Alegerea
călătorește în arhivele de sincronizare, așa că o echipă întreagă
numerotează la fel.
Vedeți [Coduri de loc](features/place-code-identifiers.md).

### Link direct
Un link de forma `sp://<code>`. Deschiderea unuia — din scaner sau, pe
Android, dintr-un mesaj, o notiță ori un fișier din afara aplicației — vă
duce la locul din peșteră corespunzător.
Vedeți [Linkuri directe](features/deep-links.md).

### Etichetă QR
Autocolantul sau plăcuța tipărită și montată în peșteră. SpeleoLoc așază
etichetele pe o pagină imprimabilă cu **Printează coduri QR**, iar textul de
sub fiecare urmează **Șablon etichetă cod QR** stabilit în
**Setări → Generare grafică cod QR**.
Vedeți [Coduri QR](features/qr-codes.md).

## Hărți în interiorul peșterii

### Hartă raster
O imagine bitmap a unei peșteri — o ridicare topografică scanată sau un
export dintr-un program de topografie — importată în aplicație. SpeleoLoc
**nu** desenează hărți; le afișează pe cele pe care i le dați.
Vedeți [Hărți raster](features/raster-maps.md).

### Tip hartă
Ce arată o hartă raster, ales în formularul hărții: **vedere plană**,
**profil proiectat** sau **profil extins**.
Vedeți [Hărți raster](features/raster-maps.md).

### Definiție de punct
Poziția unui loc din peșteră pe o anumită hartă raster. Un loc poate să nu
aibă nicio definiție de punct, să aibă una sau câte una pe fiecare hartă.
Raportul **Definiții hărți**, deschis din contorul de pinuri al unui loc,
arată ce hărți conțin deja un punct pentru el.
Vedeți [Vizualizator de hărți și editor de puncte](features/map-viewer.md).

## Harta de suprafață

### Harta peșterilor
Harta geografică pe tot ecranul, cu fiecare loc din peșteră care are
coordonate, deschisă cu **Harta peșterilor** din ecranul principal sau din
lista de locuri a unei peșteri. Notele mai vechi numesc același ecran *harta
de suprafață*.
Vedeți [Harta peșterilor](features/surface-map.md).

### Strat de bază
Singura hartă de fundal pe care desenează harta peșterilor — una dintre cele
zece surse publice online sau unul dintre fișierele dumneavoastră MBTiles
cărora le-ați dat rolul **Hartă de bază**. Se alege din **Straturi hartă**.
Vedeți [Harta peșterilor](features/surface-map.md).

### Suprapunere
Un strat desenat *peste* stratul de bază. Se pot bifa oricâte deodată în
**Straturi hartă**; acolo apar doar fișierele MBTiles cărora le-ați dat rolul
**Suprapunere**.
Vedeți [Harta peșterilor](features/surface-map.md).

### Strat MBTiles
Unul dintre fișierele dumneavoastră de hartă offline — un fișier `.mbtiles`
care conține plăci de hartă pretăiate, produs pe calculator dintr-o planșă
scanată sau dintr-un export. Doar fișiere raster; cele vectoriale sunt
listate, dar nu pot fi desenate. Se administrează din **Setări → Hartă**.
Vedeți [Folosirea straturilor MBTiles offline](workflows/mbtiles-layers.md).

### Cache de hartă
Depozitul de plăci de hartă online pe care aplicația le păstrează pe
dispozitiv, pentru ca o zonă vizitată deja să se deseneze și fără semnal. Se
umple cât timp **Stochează hărțile online** este activ și se golește cu
**Golește cache-ul de hartă** din **Setări → Hartă**. Golirea nu atinge
niciodată fișierele dumneavoastră MBTiles.
Vedeți [Harta peșterilor](features/surface-map.md).

## Poziții și coordonate

### Poziție
Latitudinea, longitudinea și altitudinea opțională ale unui loc din peșteră.
Latitudinea și longitudinea sunt stocate în grade zecimale, altitudinea în
metri. Orice loc poate purta una, nu doar o intrare, iar fiecare loc care are
una este desenat pe harta peșterilor.
Vedeți [GPS și coordonate](features/gps-and-coordinates.md).

### Înregistrator GPS
Ecranul **Înregistrare punct GPS**, care face media multor fixări de la
sateliți cât timp stați nemișcat și predă media formularului locului din
peșteră când apăsați **Capturează** și apoi **Folosește această poziție**.
Dintre cele trei ajutoare pentru coordonate de pe formularul locului, este
singurul care completează câmpul de altitudine, deși puteți oricând
introduce singur o altitudine.
Vedeți [GPS și coordonate](features/gps-and-coordinates.md).

### Format de coordonate
Modul în care se scrie o poziție. **Introdu coordonatele** acceptă grade
zecimale, grade-minute-secunde și UTM și își dă seama singur ce ați tastat;
**Setări → Hartă → Formatul de afișare a coordonatelor** alege în care
dintre cele trei sunt *afișate* pozițiile. Este doar o setare de afișare —
câmpurile stocate și fișierele exportate conțin întotdeauna grade zecimale.
Vedeți [GPS și coordonate](features/gps-and-coordinates.md).

## Beaconuri și tag-uri cu senzori

### Beacon BLE
Un tag Bluetooth mic, alimentat de baterie, montat într-un punct de interes.
Odată înregistrat pe un loc din peșteră, trecerea pe lângă el identifică acel
loc fără mâini — fără telefon în mână, fără cameră. Sunt recunoscute două
familii: tag-uri de tip iBeacon și tag-uri cu senzori Ruuvi.
Vedeți [Beaconuri BLE](features/ble-beacons.md).

### Tag
Hardware-ul propriu-zis al beaconului, spre deosebire de locul din peșteră pe
care îl reprezintă. **Setări → Detectare beaconuri → Administrare tag-uri**
listează fiecare tag înregistrat și vă lasă să dați fiecăruia un **Titlu**, o
**Descriere** și o fotografie a lui montat — fotografia rămâne pe telefonul
care a făcut-o și nu intră în nicio arhivă.
Vedeți [Beaconuri BLE](features/ble-beacons.md).

### Detectare beaconuri
Ascultarea în fundal care transformă un tag prin dreptul căruia treceți
într-o identificare de loc. Este oprită implicit; se pornește cu
**Detectează beaconurile automat** din **Setări → Detectare beaconuri** sau
din comutatorul **Detectare beaconuri** din meniul aplicației. Opțiunile ei
stabilesc cât de puternic trebuie să fie semnalul, cât timp rămâne același
tag tăcut după aceea, dacă se deschide locul, dacă se aude un sunet și dacă
scanarea continuă în fundal pe Android.
Vedeți [Beaconuri BLE](features/ble-beacons.md).

### Tag cu senzori Ruuvi
Un beacon care măsoară și temperatura, umiditatea, presiunea atmosferică,
tensiunea bateriei și mișcarea și le transmite continuu. Se folosește ca
marcaj de loc, ca orice alt tag, având în plus ecranele **Date senzor în
timp real** și **Istoric senzor**.
Vedeți [Tag-uri cu senzori Ruuvi](features/ruuvi-sensors.md).

### Istoric senzor
Jurnalul de măsurători pe care un tag Ruuvi îl păstrează la bord — cam
ultimele zece zile. **Descarcă din tag** îl copiază în aplicație, unde este
reprezentat grafic și listat și de unde poate pleca într-un fișier CSV cu
**Exportă CSV**. **Șterge istoricul stocat** șterge copia de pe telefon și nu
poate fi anulat; jurnalul din tag rămâne neatins.
Vedeți [Tag-uri cu senzori Ruuvi](features/ruuvi-sensors.md).

### Laborator beacon
Ecranul de diagnostic din
**Setări → Detectare beaconuri → Laborator beacon**. Arată ce aude de fapt
radioul, în formă brută, și este unealta pentru verificarea unei poziții de
montare sau pentru urmărirea unui tag care nu vrea să fie văzut. Nu
înregistrează nimic și nu schimbă niciun fel de date despre peșteri.
Vedeți [Beaconuri BLE](features/ble-beacons.md).

## Ture și documente

### Tură
O sesiune de speologie înregistrată într-o singură peșteră: o oră de început,
o oră de sfârșit opțională, o listă ordonată de puncte ale turei, un jurnal
generat și documentele făcute cât timp a rulat. Pe un dispozitiv este activă
o singură tură la un moment dat, pentru toate peșterile.
Vedeți [Ture](features/trips.md).

### Punct al turei
O intrare din secvența de puncte a unei ture: un loc din peșteră plus un
moment de timp. Se creează unul când scanați codul QR al unui loc din peștera
turei active — la scanarea unei intrări sunteți întrebat mai întâi dacă
ieșiți — și, de asemenea, ori de câte ori detectarea automată a beaconurilor
recunoaște un tag înregistrat pe un loc din aceeași peșteră. Ambele surse
produc puncte identice și niciuna nu adaugă vreunul cât timp tura este în
pauză.
Vedeți [Ture](features/trips.md).

### Jurnalul turei
Relatarea în text a unei ture, regenerată din evenimentele înregistrate —
începută, punct adăugat, repornită, încheiată. Se deschide cu **Jurnal** de
pe ecranul turei; pictograma cu carte de pe ecranul jurnalului alege stilul
formulărilor.
Vedeți [Ture](features/trips.md).

### Șablon de raport de tură
Un fișier ODT sau DOCX care conține variabile de tip substituent, păstrat în
**Administrare șabloane**. Alegerea unuia la exportul unei ture completează
substituenții cu datele acelei ture și produce un document finit.
Vedeți [Rapoarte de tură și șabloane](features/trip-reports.md).

### Fișier de documentație
Ceea ce aplicația numește document: o fotografie, un video, o înregistrare
audio, o notiță în text simplu sau în text formatat, un link web sau orice
alt fișier, atașat unui loc din peșteră sau unei peșteri. Documentele care
vin de pe alt dispozitiv pot fi atașate și unei zone a peșterii.
Vedeți [Documente](features/documents.md).

## Partajare și evidență

### Arhivă
Fișierul `.zip` produs de **Setări → Export / Import Date → Exportă
Arhivă**: o copie a întregii baze de date, opțional cu fișierele documentelor
și imaginile hărților raster alături. Acesta este formatul de backup și modul
de a pregăti un dispozitiv nou de la zero.
Vedeți [Export, import și backup al bazei de date](features/database-export-import.md).

### Arhivă de sincronizare
Fișierul `.zip` produs de **Sinc. man. → Exportă arhivă de sincronizare**,
care ține câte o linie pentru fiecare înregistrare, cu momentul ultimei
modificări. Dispozitivul care o primește o *îmbină* cu ce are deja, în loc să
înlocuiască ceva, așa că doi speologi care fac schimb de arhive ajung fiecare
cu ambele jumătăți ale muncii.
Vedeți [Sincronizare manuală și istoricul modificărilor](features/sync-and-change-log.md).

### Rezolvarea conflictelor
Alegerea dispozitivului care importă, privitor la ce face când ambele părți
au modificat aceeași înregistrare: **Automat (ultima modificare câștigă)**
păstrează în tăcere modificarea mai nouă, **Manual (revizuiește fiecare
conflict)** vă arată cele două versiuni una lângă alta și vă întreabă. Nimic
din această alegere nu este stocat în arhivă.
Vedeți [Sincronizare manuală și istoricul modificărilor](features/sync-and-change-log.md).

### Istoric modificări
Evidența curentă a fiecărei adăugări, modificări și ștergeri făcute pe acest
dispozitiv, cu ora și utilizatorul care a făcut-o. Ea este cea care permite
unei îmbinări să reia ștergerile altcuiva. O citiți în fila **Istoric
modificări** din **Sinc. man.** sau, în timpul unei rulări, pe ecranul de
sincronizare FTP. Călătorește întotdeauna într-o arhivă de sincronizare.
Vedeți [Sincronizare manuală și istoricul modificărilor](features/sync-and-change-log.md).

### Sesiune de sincronizare
O rulare a unei sincronizări FTP. Fila **Jurnal** de pe ecranul de
sincronizare FTP păstrează ultimele 200 de linii de activitate și marchează
începutul fiecărei rulări cu un separator `─── sincronizare nouă ───`.
Istoricul modificărilor nu are noțiunea de sesiune — este o listă continuă.
Vedeți [Sincronizare FTP / SFTP](features/ftp-sync.md).

### Profil de server
Un punct final FTP, FTPS sau SFTP salvat — nume, server, port, credențiale și
folder pe server — adăugat din **Setări → Sincronizare FTP / SFTP**. Un
profil este marcat ca implicit, iar acela este cel folosit de o rulare de
sincronizare.
Vedeți [Sincronizare FTP / SFTP](features/ftp-sync.md).

### Server de club (SilexGIS)
Un registru de peșteri pe care un club îl ține pe serverul propriu, cu
interfață web, conturi și permisiuni, cu care acest dispozitiv se poate
sincroniza **rând cu rând**, nu prin instantanee întregi. Călătoresc doar
peșterile, zonele peșterii, locurile din peșteră și zonele de suprafață;
documentele, hărțile raster, turele și beaconurile niciodată. Se adaugă
din **Setări → Server de club (SilexGIS)** și este necesar doar dacă
clubul dumneavoastră are deja o astfel de instalare.
Vedeți [Server de club (SilexGIS)](features/silexgis-sync.md).

### Selecție
Lista cu nume a punctelor de pornire de pe un server de club care
hotărăște ce peșteri ale acestuia poartă dispozitivul — vine și tot ce se
află înăuntrul acelor puncte, inclusiv ce se adaugă mai târziu în ele.
Selecțiile se fac în interfața web a serverului, niciodată în aplicație;
**Alege**, de pe ecranul de sincronizare, selectează dintre cele pe care
le deține contul dumneavoastră. Interfața proprie a instalării numește una
*set*. Nu are legătură cu **Mod selecție** de la liste.
Vedeți [Server de club (SilexGIS)](features/silexgis-sync.md).

### Rădăcină
Un punct de pornire al unei selecții: o zonă de suprafață sau o peșteră de
la care începe selecția, numărat lângă fiecare selecție în selector —
*3 rădăcini*. Doar ceva ce serverul are deja poate fi rădăcină, motiv
pentru care o peșteră despre care serverul nu a auzit niciodată ajunge la
el prin **Trimite peșterile explorate în altă parte**, nu prin adăugarea
într-o selecție.
Vedeți [Server de club (SilexGIS)](features/silexgis-sync.md).

### Club de speologie
Clubul căruia îi aparține un rând în registrul unui server de club. O
selecție care nu numește niciunul poate fi citită în continuare fără nicio
problemă, dar tot ce trimiteți este refuzat, pentru că serverul nu poate
ști ce club ar trebui să dețină rândul nou. Remediul este pe server: dați
acelei selecții un club din interfața web.
Vedeți [Server de club (SilexGIS)](features/silexgis-sync.md).

### Citește tot
Al doilea dintre cele două butoane de rulare de pe ecranul de
sincronizare cu serverul de club. Rulează exact ca **Sincronizează
acum**, doar că jumătatea de citire pornește selecția de la început, nu
de unde a rămas acest dispozitiv. Este întotdeauna sigur, doar mai lent —
și este singurul lucru care aduce o peșteră la care contul dumneavoastră
tocmai a primit acces.
Vedeți [Server de club (SilexGIS)](features/silexgis-sync.md).

### Necesită atenția ta
Cardul pe care îl lasă în urmă o rulare către serverul de club atunci când
ceva rămâne de decis de dumneavoastră: un rând schimbat și pe server, un
rând refuzat de server, o peșteră creată de dumneavoastră care se află
aproape de una pe care serverul o are deja sau rânduri pe care nu le-a
putut stoca. Nu este scris nicăieri — trăiește cât timp aplicația rulează,
iar rularea următoare scoate la iveală tot ce a rămas nerezolvat.
Vedeți [Server de club (SilexGIS)](features/silexgis-sync.md).

### Utilizator
Identitatea unui speolog, păstrată în aplicație pentru ca fiecare modificare
să poată fi atribuită. Nu este un cont cu autentificare și nu există parolă.
Se alege din **Setări → Utilizatori** și se aplică pe fiecare înregistrare pe
care o atingeți; până când alegeți unul, aplicația creează și folosește un
utilizator **system**.
Vedeți [Utilizatori](features/users.md).

### UUID de dispozitiv
Identificatorul pe care aplicația îl dă acestei instalări la prima pornire. În
mod normal nu îl vedeți niciodată: el marchează intrările din istoricul
modificărilor, ca o modificare să poată fi urmărită înapoi până la
dispozitivul care a făcut-o, și nu este suprascris când importați arhiva
altcuiva.
Vedeți [Utilizatori](features/users.md).

## Lucrul cu liste și ecrane

### Filtru
Caseta de căutare deschisă cu **Arată filtrul** deasupra unei liste.
Îngustează lista pe măsură ce tastați, potrivind mai mult decât titlul — în
lista locurilor din peșteră potrivește și codul locului și numele zonei
peșterii — iar contorul din antet se schimbă ca să arate câte din câte au
rămas.
Vedeți [Liste: filtrare, sortare și selecție](features/lists-filter-sort-select.md).

### Sortează după
Selectorul care ordonează o listă, cu câmpuri care depind de listă. Alegerea
este reținută pentru acea listă între vizite, iar unele câmpuri inserează și
titluri de grup gri.
Vedeți [Liste: filtrare, sortare și selecție](features/lists-filter-sort-select.md).

### Mod de selecție
Modul care pune o casetă de bifat pe fiecare rând și adaugă în antet
**Selectează tot**, **Inversează selecția** și o acțiune de ștergere. Acțiuni
precum **Harta peșterilor** se aplică atunci doar rândurilor bifate; dacă nu
este bifat nimic, ele revin la ce lasă vizibil filtrul. **Printează coduri
QR** urmează și el rândurile bifate, dar dacă nu este bifat nimic tipărește
toate locurile din peșteră și ignoră filtrul.
Vedeți [Liste: filtrare, sortare și selecție](features/lists-filter-sort-select.md).

### Tur de ghidare
Suprapunerea care evidențiază și explică, pornită prima dată când deschideți
majoritatea ecranelor. Îl reluați din intrarea **Tur de ghidare** din meniul
⋮ al acelui ecran sau readuceți toate tururile cu **Resetează tururile de
ghidare** din **Setări → General**.
Vedeți [Setări](features/settings.md).

## Vezi și

- [Prezentare generală](overview.md)
- [Primii pași](getting-started.md)
- [Locuri din peșteră](features/cave-places.md)
- [Coduri de loc](features/place-code-identifiers.md)
- [Sincronizare manuală și istoricul modificărilor](features/sync-and-change-log.md)
- [Setări](features/settings.md)
