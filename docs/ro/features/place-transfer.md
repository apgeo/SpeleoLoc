# Transfer de locuri GPX/KML

[← Înapoi la cuprins](../README.md)

SpeleoLoc poate preda locurile din peșteră altor programe de cartografie
sub forma unui fișier GPX sau KML și poate citi puncte de traseu dintr-un
astfel de fișier înapoi, ca locuri ale unei peșteri. Ambele sensuri stau
în meniul **⋮** al ecranului principal.

Denumirile controalelor de pe această pagină sunt cele în limba română.
Aplicația pornește în română; engleza se alege din
**Setări → General → Limba aplicației**.

## Unde se găsește

Deschideți ecranul principal, apăsați **⋮**, iar cele două intrări stau la
sfârșitul părții de meniu dedicate ecranului principal:

- **Exportă punctele (GPX/KML)** — scrie într-un fișier locurile din
  domeniul ales;
- **Importă puncte (GPX/KML)** — citește un fișier într-o singură peșteră.

Aceste intrări sunt singura cale către transferul GPX/KML: nu există
butoane în bara de instrumente pentru el, iar lista de locuri a unei
peșteri nu îl oferă. **Import locuri din CSV**, pe care îl găsiți în
interiorul unei peșteri, este o funcție diferită — vedeți
[Import CSV](csv-import.md).

## Ce călătorește în fișier

Patru lucruri pentru fiecare punct și nimic altceva:

| În SpeleoLoc | În fișier |
|---|---|
| Câmpul **Titlu** al locului | numele punctului de traseu sau al reperului |
| **Latitudine**, **Longitudine** | poziția punctului |
| **Altitudine** | elevația punctului, în metri |
| **Descriere** | descrierea punctului de traseu |

Codurile de loc și conținutul codurilor QR, marcajul de intrare, balizele,
documentele, fotografiile, turele și tot restul rămân pe loc. Un loc care
a plecat într-un fișier GPX și s-a întors este din nou un simplu loc cu
poziție — de aceea transferul este făcut pentru schimbul de poziții cu
alte programe, nu pentru copii de siguranță sau pentru mutarea datelor.
Pentru asta folosiți o arhivă; vedeți
[Export, import și copie de siguranță a bazei de date](database-export-import.md).

## Exportă punctele (GPX/KML)

### Ce ajunge în fișier

Două reguli hotărăsc:

- **Doar locurile care au coordonate.** Un loc fără poziție este lăsat
  afară, fără niciun mesaj.
- **Domeniul urmează lista de pe ecranul principal**, aceeași regulă ca la
  **Harta peșterilor** și la **Generează coduri QR pentru peșteri**: cu
  **Mod selecție** pornit, doar peșterile bifate; altfel, fiecare peșteră
  rămasă vizibilă după filtrul curent.

Un domeniu gol înseamnă *nimic*, niciodată *tot*. Dacă **Mod selecție**
este pornit și nu ați bifat nicio peșteră, sau dacă filtrul nu potrivește
nimic, sau dacă niciun loc din domeniu nu are coordonate, exportul se
oprește acolo cu **Nu există puncte cu coordonate de exportat** — fără
foaia de formate, fără dialog de salvare.

### Cum se face

1. Pe ecranul principal, restrângeți lista de peșteri cu caseta de
   filtrare sau porniți **Mod selecție** și bifați peșterile dorite.
   Lăsați-le pe amândouă în pace ca să exportați tot.
2. **⋮ → Exportă punctele (GPX/KML)**.
3. Alegeți formatul în foaia care se deschide:
   - **GPX** — *Puncte de traseu pentru Garmin, Locus, QGIS*
   - **KML** — *Repere pentru Google Earth*
4. Se deschide dialogul de salvare al sistemului, cu numele de fișier
   `speleoloc_places.gpx` sau `speleoloc_places.kml` deja completat.
   Redenumiți-l sau alegeți alt dosar, apoi salvați.
5. Aplicația confirmă cu **Fișiere salvate**, urmat de numărul de puncte
   de traseu scrise. Comparați acel număr cu ce așteptați — diferența,
   dacă există, sunt locurile care nu au coordonate.

### Cum sunt denumite punctele de traseu

Fiecare punct de traseu poartă numele `<titlul locului> - <titlul
peșterii>`, de exemplu `Intrare - Peștera Mare`. Titlurile simple de loc,
precum „Intrare” sau „P1”, se repetă de la o peșteră la alta și ar fi
inutile într-un program care nu știe nimic despre peșteri; numele peșterii
face fiecare punct identificabil și tot el permite aplicației SpeleoLoc
să-și recunoască propriul fișier la întoarcere.

Un singur fișier poate ține locurile mai multor peșteri. Înăuntru nu
există nicio grupare — numele peșterii din titlul fiecărui punct de traseu
este singurul semn al peșterii din care a venit punctul.

Pozițiile sunt scrise cu șapte zecimale, iar elevațiile cu o zecime de
metru, mult mai fin decât orice GPS de telefon, așa că fișierul nu pierde
nimic din ce ține aplicația.

## Importă puncte (GPX/KML)

### Cum se face

1. **⋮ → Importă puncte (GPX/KML)** pe ecranul principal.
2. Alegeți fișierul. Selectorul oferă **toate** tipurile de fișiere, nu
   doar GPX și KML — selectorul de fișiere din Android adesea nu cunoaște
   aceste tipuri — așa că alegeți cu atenție. Formatul este apoi
   recunoscut din conținutul fișierului, deci o extensie greșită sau
   lipsă nu contează.
3. Alegeți peștera care primește punctele, în foaia **Alege o peșteră**;
   caseta ei **Caută** restrânge o listă lungă. Tot ce se află în fișier
   intră în această singură peșteră.
4. Importul rulează și raportează **N puncte importate (M duplicate
   omise)**.

Dacă ceva nu este în regulă, primiți în schimb unul dintre mesajele de mai
jos și nu se creează nimic:

| Mesaj | Ce înseamnă |
|---|---|
| *Fișierul nu este un document GPX sau KML valid* | Fișierul nu este în niciunul dintre formate sau nu poate fi citit deloc ca text — un KMZ arhivat, o foaie de calcul, o descărcare trunchiată |
| *Nu s-au găsit puncte în fișier* | Fișierul a fost citit, dar nu conținea niciun punct utilizabil |
| *Nu există încă peșteri — adaugă întâi o peșteră* | Importul are nevoie întotdeauna de o peșteră în care să pună punctele; creați mai întâi una |

### Ce devine fiecare punct de traseu

Fiecare punct de traseu acceptat este creat ca **loc care nu este intrare**
în peștera aleasă, purtând:

- **Titlu** — numele punctului de traseu;
- **Latitudine** și **Longitudine** — poziția punctului de traseu;
- **Altitudine** — elevația, când fișierul o are;
- **Descriere** — descrierea punctului de traseu. La GPX se folosește
  câmpul de comentariu când nu există descriere.

Locurile importate sosesc fără cod de loc și fără conținut de cod QR, iar
marcajul de intrare este oprit. Deschideți peștera după aceea ca să
marcați care dintre ele sunt cu adevărat intrări și folosiți **Generează
coduri** dacă le vreți numerotate — vedeți
[Coduri de loc (PCI) și conținutul codurilor QR (QCRI)](place-code-identifiers.md).
Ele apar imediat pe [harta peșterilor](surface-map.md), atâta timp cât
**Arată locurile care nu sunt intrări** este pornit acolo.

Fiecare loc importat este consemnat în **Istoric modificări** pe numele
utilizatorului curent și pleacă la următoarea sincronizare ca orice altă
modificare. Vedeți
[Sincronizarea manuală și istoricul modificărilor](sync-and-change-log.md).

### Duplicatele și reimportul propriului export

Înainte de compararea numelor, un ` - <titlul peșterii>` de la sfârșit,
care aparține peșterii *în care* importați, este tăiat — exact decorația
pe care o adaugă exportul. Asta face dus-întorsul sigur: exportați o
peșteră, deschideți fișierul în alt program, importați-l înapoi în aceeași
peșteră, iar punctele pe care le aveați deja sunt recunoscute în loc să
fie duplicate.

Un punct de traseu este omis când numele lui, după această tăiere și fără
a ține seama de literele mari și mici, aparține deja unui loc din peșteră
sau a fost deja folosit de un punct de traseu anterior din același fișier.
Din asta decurg două lucruri:

- **A omite nu înseamnă niciodată a actualiza.** Un loc existent își
  păstrează coordonatele, altitudinea și descrierea, orice ar spune
  fișierul. Importul GPX/KML poate adăuga locuri unei peșteri; nu le poate
  niciodată corecta. Ca să mutați un loc, editați-l în aplicație.
- **Importați un export într-o *altă* peșteră și decorația rămâne**,
  pentru că se taie doar titlul peșterii care primește. Locurile se
  creează, dar denumite `Intrare - Peștera Mare` și așa mai departe;
  redenumiți-le de mână sau importați fișierul în peștera din care a venit.

Un punct de traseu fără niciun nume devine *Punct 1*, *Punct 2*, …,
numerotându-le pe cele fără nume în ordinea în care apar. Dacă un loc cu
acel nume există deja în peșteră, acel punct de traseu se socotește
duplicat și este omis.

Importul este totul-sau-nimic. Dacă eșuează la mijlocul listei, nu se
creează absolut nimic — nu trebuie niciodată să curățați un import pe
jumătate înainte de a încerca din nou.

### Ce lasă importul deoparte, fără să spună

Importul este îngăduitor, dar selectiv, și nu raportează ce a lăsat în
urmă, așa că numărul pe care îl anunță poate fi mai mic decât numărul de
puncte pe care le-ați văzut în celălalt program:

- Un punct a cărui poziție lipsește, nu poate fi citită sau este
  imposibilă (latitudine peste ±90, longitudine peste ±180) este aruncat
  fără o vorbă.
- Liniile, poligoanele, traseele și rutele sunt ignorate — trec numai
  punctele singulare.
- Dintr-un reper cu un șir întreg de coordonate se citește doar primul
  punct.
- Stilurile, pictogramele, culorile, marcajele de timp, dosarele și orice
  adaosuri specifice unui program sunt ignorate.

Fișierele scrise de alte programe sunt citite indiferent de denumirile
interne pe care le folosesc, așa că exporturile din Garmin BaseCamp,
Locus, QGIS, Google Earth și programe asemănătoare intră toate.

## Sfaturi

- Faceți restrângerea înainte de a exporta: filtrați sau bifați pe ecranul
  principal, pentru că mai târziu, în timpul operației, nu mai există o
  alegere loc cu loc.
- Verificați numerele raportate. **Fișiere salvate: 40** față de 52 de
  locuri înseamnă că douăsprezece dintre ele nu au coordonate;
  **3 puncte importate (37 duplicate omise)** la un reimport înseamnă că
  dus-întorsul a funcționat și doar trei puncte sunt noi.
- Țineți fișierul exportat lângă datele de topografie. Este text simplu și
  o evidență utilă a locului unde se află totul, dar conține doar poziții
  — nu este o copie de siguranță.

## Vezi și

- [Pagina principală](home-screen.md)
- [Locuri din peșteră](cave-places.md)
- [GPS și coordonate](gps-and-coordinates.md)
- [Harta peșterilor](surface-map.md)
- [Import CSV](csv-import.md)
- [Export, import și copie de siguranță a bazei de date](database-export-import.md)
