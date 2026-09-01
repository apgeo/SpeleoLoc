# Documentarea unei peșteri noi

[← Înapoi la cuprins](../README.md)

Tot ce trebuie ca o ridicare topografică proaspătă să devină o peșteră
prin care echipa poate naviga în subteran: fișa peșterii, hărțile și
locurile ei, etichetele QR tipărite și prima arhivă pe care o dați mai
departe. Cele mai multe se fac o singură dată pentru fiecare peșteră —
după aceea doar adăugați la ele.

## De ce veți avea nevoie

- Una sau mai multe **planșe topografice scanate**, ca imagini în
  galeria foto a telefonului — selectorul oferă doar imagini, așa că un
  PDF trebuie salvat mai întâi ca imagine. Ele devin
  [hărțile](../features/raster-maps.md) peșterii.
- O listă a **punctelor pe care vreți să le etichetați** — săli,
  intersecții, strâmtori, sifoane, puncte de ancorare.
- O imprimantă (sau un centru de printare) și **material de etichetare
  durabil și rezistent la apă**. Hârtia simplă nu rezistă într-o peșteră.
- *(Opțional)* **Taguri BLE** pentru punctele pe care vreți să le
  recunoașteți fără mâini. SpeleoLoc citește două familii: taguri de tip
  iBeacon din familia HoneyComm BP1003 — care, așa cum vin din fabrică,
  emit UUID-ul de proximitate `FDA50693-A4E2-4FB1-AFCF-C6EB07647825` — și
  taguri Ruuvi, care raportează și temperatura și umiditatea, plus
  presiunea pe modelele care au acest senzor. Socotiți câte un tag de
  fiecare punct și plănuiți să înregistrați fiecare tag pe teren, stând
  lângă el (pasul 10).

Aplicația pornește în română. Fiecare etichetă citată mai jos este
formularea din română, pe care o alegeți din
**Setări → General → Limba aplicației**.

Două decizii sunt mult mai ieftine luate înainte ca peștera să existe
decât după: schema de numerotare (pasul 1) și aria de suprafață căreia
îi aparține peștera (pasul 2). Amândouă alimentează codurile care ajung
tipărite pe etichete, iar schimbarea lor mai târziu înseamnă reemiterea
codurilor și retipărirea.

## Pasul 1 — Alegeți cum vor fi numerotate locurile

Deschideți **Setări → Identificatori cod loc** și, în fila
**Strategie**, alegeți una:

| Strategie | Forma codului | De ce are nevoie mai întâi |
|---|---|---|
| **Ierarhic global** | segmente de țară + organizație + zonă + peșteră + loc | **Cod țară** și **Cod organizație** în această pagină — fără ele nu se generează nimic. O peșteră fără arie de suprafață primește un segment de zonă numai din zerouri, iar o arie de suprafață fără **Identificator zonă generală** unul numai din nouă |
| **Secvențial per peșteră** | un contor unic în interiorul fiecărei peșteri | **Începe de la**, **Pas**, **Nr. cifre umplere cu zerouri** |
| **Secvențial per zonă** | un contor unic pe o arie de suprafață | aceleași trei și o arie de suprafață pe fiecare peșteră |

Apăsați **Mai multe informații** ca să citiți regulile complete ale
strategiei selectate. În strategia ierarhică, **Separator segmente** pe
care îl tastați este verificat pe măsură ce tastați: un `/` sau un `=`
în el trunchiază, la scanare, orice cod tipărit după aceea, iar câmpul
vă spune asta.

Fila **Identificatori coduri QR** decide ce poartă efectiv pătratul
tipărit: **Identic cu codul locului** tipărește chiar codul locului,
**Hash (identificator scurt derivat)** tipărește un hash scurt al lui,
așa că o etichetă găsită nu dezvăluie nimic.

Aici doar stabiliți regulile — codurile se atribuie la pasul 8. Vedeți
[Coduri de loc (PCI) și conținutul codurilor QR (QCRI)](../features/place-code-identifiers.md).

## Pasul 2 — Creați aria de suprafață (opțional)

Merită făcut dacă grupați peșterile pe regiuni și este obligatoriu dacă
ați ales schema per zonă, care sare peste orice peșteră fără arie de
suprafață.

1. **Pagina principală → ⋮ → Arii de suprafață**.
2. Apăsați **Adaugă arie de suprafață**.
3. Completați **Introduceți titlul ariei de suprafață**,
   **Identificator zonă generală** (segmentul de zonă al codurilor
   ierarhice) și, opțional, **Descriere**.
4. **Salvează**.

Vedeți [Arii de suprafață](../features/surface-areas.md).

## Pasul 3 — Creați peștera

Două căi. Folosiți-o pe cea de pe hartă când sunteți chiar la intrare.

### Din pagina principală

1. Apăsați **Adaugă peșteră nouă** — **+** din bara de sus sau aceeași
   intrare din meniul **⋮**.
2. Completați **Titlul peșterii**, opțional **Descriere**, aria de
   suprafață la **Titlul ariei (opțional)** și **Index local peșteră**
   dacă folosiți coduri ierarhice.
3. Apăsați **Adaugă**.

Dacă nu ați dezactivat **Setări → General → Adaugă automat intrarea la
creare peșteră**, peștera nouă conține deja un loc, numit **Intrare** și
marcat atât ca **Intrare în peșteră**, cât și ca **Intrarea
principală**.

### De pe harta de suprafață, stând la intrare

1. Deschideți **Harta peșterilor** din pagina principală.
2. Apăsați **Adaugă punct**, apoi **Peșteră nouă** („Creează o peșteră
   cu o intrare în acest punct”).
3. Fixați punctul: atingeți harta, țineți apăsat pe ea sau apăsați
   **Folosește locația mea**, care pornește o captură GPS mediată —
   pinul urmează media curentă pe măsură ce sosesc fixările. Apăsați din
   nou ca să opriți medierea.
4. Apăsați **Confirmă**, apoi dați **Titlul peșterii** și **Numele
   intrării** și apăsați **Adaugă**.

> 📷 [Amplasarea punctului pentru o peșteră nouă](../screenshots/02-cave-map.md#cave-map-new-cave-placement) — Amplasarea punctului de intrare pentru o peșteră nouă pe harta de suprafață.

Prima intrare a unei peșteri devine automat intrarea ei principală. O
peșteră făcută astfel are coordonate imediat, dar nu are arie de
suprafață, așa că deschideți-o și folosiți **Editează peștera** ca să îi
setați una înainte de a genera coduri. **Index local peșteră** vă este
alocat prima dată când se generează coduri, dacă nu ați tastat unul
dumneavoastră.

Vedeți [Peșteri și zone de peșteră](../features/caves-and-areas.md) și
[Harta peșterilor](../features/surface-map.md).

## Pasul 4 — Adăugați planșele topografice

1. Deschideți peștera și apăsați **Vezi hărți** în bara ei de
   instrumente.
2. Apăsați **Adaugă hartă**.
3. Dați-i un **Titlu**, apăsați **Selectează imagine** și alegeți
   fișierul, apoi alegeți **Tip hartă**: *vedere plană*, *profil
   proiectat*, *profil extins* sau *Altele*.
4. **Salvează** și repetați pentru fiecare planșă.

Două titluri de același tip nu se pot repeta în aceeași peșteră. Dacă
alegeți o imagine pe care o folosește deja altă hartă, aplicația numește
acea hartă și întreabă dacă să **Salvează oricum**. **Reordonare hărți**
vă lasă să trageți lista în ordinea în care vreți să o răsfoiți în
subteran.

Vedeți [Hărți](../features/raster-maps.md).

## Pasul 5 — Împărțiți peștera în zone (opțional)

1. În bara de instrumente a peșterii, apăsați **Zonele peșterii**.
2. Apăsați **Adaugă arie**, tastați numele în **Introduceți titlul
   ariei**, apoi **Salvează**.

Fiecare loc poate purta o zonă („Seria de la intrare”, „Galeria
principală”, „Nivelul inferior”). Zonele sunt cele după care filtrați și
sortați mai târziu lista de locuri, iar numele zonei poate fi tipărit pe
etichete.

## Pasul 6 — Creați locurile din peșteră

Patru căi de intrare; combinați-le liber.

### Unul câte unul

1. Apăsați **Adaugă loc** în bara de instrumente a peșterii.
2. Completați **Titlu**, **Descriere**, **Depth '+/-'** (adâncimea față
   de intrare; o valoare peste ±1800 cere confirmare, iar peste ±5000
   este refuzată) și zona la **Titlul ariei (opțional)**.
3. Adăugați acum **Identificator cod loc** și **Identificator resursă
   cod QR** sau lăsați-le pentru pasul 8.
4. Folosiți intrarea **⋮ → Arată/Ascunde coordonate GPS** ca să
   dezvăluiți **Latitudine**, **Longitudine** și **Altitudine**, dacă
   locul are o poziție cunoscută.
5. Activați **Intrare în peșteră** și **Intrarea principală** acolo unde
   se aplică, apoi salvați cu pictograma de salvare din bara de sus.

Dacă numiți un loc exact *Intrare* și nu l-ați marcat, la salvare vi se
cere să confirmați dacă să fie marcat ca intrare în peșteră; dacă este
intrare, iar peștera nu are încă o intrare principală, se întreabă apoi
dacă să devină cea principală. Vedeți
[Locuri din peșteră](../features/cave-places.md).

### Dintr-o listă CSV

1. Apăsați **Import locuri din CSV** în bara de instrumente a peșterii.
2. **Selectează fișier CSV**. Fișierul trebuie să aibă un rând de
   antet.
3. Mapați coloanele: **Nume loc peșteră** este obligatorie, iar
   **Cod QR** este opțională. **Rânduri de date găsite** și
   **Previzualizare date** arată ce va fi citit.
4. Apăsați **Pornește importul**. Intrările deja existente în baza de
   date sunt listate înainte să se scrie ceva, iar conflictele de QR vă
   lasă să alegeți **Omite actualizare QR** sau **Suprascrie coduri
   QR**. Un rezumat raportează câte locuri din peșteră au fost create și
   câte coduri QR au fost actualizate.

Vedeți [Import CSV](../features/csv-import.md).

### Atingând planșa topografică

1. Apăsați **Poziționare locuri pe hartă** în bara de instrumente a
   peșterii.
2. Apăsați **Adăugare loc peșteră**. Pictograma devine verde, iar
   aplicația vă spune să atingeți harta.
3. Atingeți planșa acolo unde se află locul. Un dialog cere **Titlu loc
   peșteră**, **Adâncime '+/-'**, **Zonă peșteră** și **Identificator
   cod loc** — ultimul cu un buton **Scanează**, dacă eticheta există
   deja.
4. **Salvează**. Locul este creat *și* punctul lui pe acea hartă este
   deja definit, așa că pasul 7 este gata pentru harta aceasta.

### Dintr-un fișier GPX sau KML

**Pagina principală → ⋮ → Importă puncte (GPX/KML)**, alegeți fișierul,
apoi alegeți peștera căreia îi aparține. Fiecare waypoint devine un loc
cu coordonate; duplicatele sunt sărite, iar numărătorile sunt raportate.
Vedeți [Exportul și importul locurilor](../features/place-transfer.md).

## Pasul 7 — Fixați fiecare loc pe fiecare hartă

Un loc fixat este ceea ce face ca o scanare ulterioară să arate un punct
pe planșă.

1. Apăsați **Poziționare locuri pe hartă** în bara de instrumente a
   peșterii.
2. Alegeți locul din bara de navigare, apoi atingeți planșa acolo unde
   se află. Punctul nou este un punct albastru cu centrul portocaliu,
   etichetat **nou**; dacă locul era deja fixat aici, poziția veche
   rămâne vizibilă ca un contur albastru etichetat **inițial**. Locurile
   deja fixate pe această hartă sunt puncte roșii care își poartă
   titlurile.
3. Apăsați **Definește locul pe hartă** (pictograma de salvare) ca să
   stocați punctul. Asta închide și editorul, așa că folosiți-o pentru
   ultimul loc dintr-o sesiune, nu pentru fiecare în parte.
4. Ca să fixați multe locuri dintr-o dată, treceți pur și simplu la
   locul următor. Prima dată când faceți asta cu un punct nesalvat,
   aplicația întreabă *„Salvați automat punctul curent când comutați la
   alt loc sau hartă?”* — răspundeți **Da** și continuă să salveze tot
   restul sesiunii.
5. **Următorul loc fără coordonate** sare direct la următorul loc fără
   punct pe *această* planșă, iar indiciul lui numără câte au mai rămas.

Alte controale de știut: **Comutare legendă** explică culorile
(**Curent**, **Nou**, **Original**, **Existent**); **Resetează punctul
la poziția inițială** anulează o mutare nesalvată; **Elimină definiția
punctului** șterge fixarea acestui loc pe această hartă, după o
confirmare; butonul de mod atingere comută între **Mod atingere:
Definește punct nou** și **Mod atingere: Selectează loc existent**.

Repetați pentru fiecare planșă pe care apare un loc — o stație are de
obicei nevoie de un punct atât pe vederea plană, cât și pe profil.
Vedeți [Vizualizatorul de hărți și editorul de puncte](../features/map-viewer.md).

## Pasul 8 — Dați fiecărui loc codul lui

Pătratul tipărit codifică identificatorul resursei codului QR al
locului sau codul lui de loc, dacă nu s-a calculat niciun QCRI. Un loc
care nu are niciunul primește totuși o etichetă, dar pătratul nu poartă
nimic de căutat — așa că atribuiți codurile înainte de tipărire.

- **Un singur loc**: apăsați **Generează automat** lângă
  **Identificator cod loc** (și lângă **Identificator resursă cod QR**)
  în pagina locului din peșteră.
- **O peșteră întreagă**: apăsați **Generează coduri** în bara de
  instrumente a peșterii și confirmați *„Generați coduri pentru fiecare
  loc din această peșteră?”*.
- **O arie de suprafață întreagă**: deschideți **Arii de suprafață**,
  editați aria și apăsați acolo **Generează coduri**.
- **Tot**: **Setări → Identificatori cod loc → Generează coduri pentru
  întregul set de date**.

Locurile care au deja o valoare opresc procesul cu **Suprascrieți
valoarea existentă?**, arătând codul vechi și pe cel nou și oferind
**Înlocuiește**, **Păstrează**, **Înlocuiește toate**, **Păstrează-le pe
toate la fel** sau **Anulează procesul**. La final primiți un rezumat cu
câte au fost actualizate, sărite, refuzate sau abandonate. Dacă
schimbați ulterior modul QCRI, folosiți **Recalculează toate
QCRI-urile**, ca etichetele pe care urmează să le tipăriți să fie de
acord cu baza de date.

## Pasul 9 — Tipăriți etichetele QR

1. Stabiliți întâi ieșirea. **Setări → Generare grafică cod QR** ține
   **Ieșire QR:** (**PDF** sau **Imagini**), **Dimensiune QR (px)**,
   culorile, **DPI (calitate)** și **Corecția erorii**;
   **Setări → Ieșire PDF** ține **Coduri QR pe pagină** (**Coloane**,
   **Rânduri**).
2. Scrieți textul care se tipărește sub fiecare pătrat în **Șablon
   etichetă cod QR**, mai jos în aceeași pagină **Generare grafică cod
   QR**, folosind variabilele pe care le listează: `@place_title`,
   `@description`, `@cave_title`, `@area_title`,
   `@place_code_identifier`, `@qr_res_identifier`, `@depth` și `\n`
   pentru un rând nou. Prefixați o variabilă cu `#fz` pentru o
   dimensiune de font sau cu `#fc` pentru o culoare.
3. Decideți spre ce arată pătratul însuși. Lăsată goală, **Adresa de
   destinație pentru etichetele tipărite** tipărește un pătrat `sp://`
   pe care îl deschide doar SpeleoLoc; puneți în ea adresa de destinație
   a serverului clubului și pătratul se deschide și pe telefonul unui
   străin, rezolvându-se în continuare în aplicație.
4. În lista de locuri a peșterii apăsați **Printează coduri QR**. Cu
   modul de selecție pornit și cu locuri bifate, se tipăresc doar
   acelea; altfel se tipărește toată peștera.
5. În ecranul **Coduri QR generate**, **Regenerare PDF** redesenează
   după o schimbare de setări, iar **Exportă** salvează rezultatul — un
   PDF sau, în modul *Imagini*, o arhivă zip de PNG-uri cât timp
   **Exportă imaginile ca zip** este activ.

Etichete pentru locuri care nu există încă: **Generează coduri QR pentru
locuri (interval)** din bara de instrumente a peșterii compune coduri
pentru un interval de indici de loc (câmpurile **De la indexul** și
**Până la indexul**, cel mult 500 odată) fără să scrie nimic în baza de
date, așa că puteți tipări o bandă de etichete neatribuite și atașa
codurile unor locuri reale ulterior. Are nevoie de strategia ierarhică,
de codurile de țară și de organizație și de un index local de peșteră pe
peșteră.

Vedeți [Coduri QR — amplasare, scanare, printare](../features/qr-codes.md).

## Pasul 10 — Tura în care montați etichetele

În subteran, lipiți sau prindeți cu bolț fiecare etichetă la punctul ei.
Dacă instalați și taguri BLE, înregistrați-le în aceeași tură —
aplicația găsește un tag ascultându-l, deci trebuie să fiți lângă el:

1. Deschideți locul din peșteră căruia îi aparține tagul.
2. În secțiunea **Beaconuri BLE**, apăsați **Asociază beacon**.
3. **Beaconuri în apropiere** listează ce aude, cu semnalul cel mai
   puternic primul, iar tagurile deja înregistrate în această peșteră
   apar estompate. Țineți telefonul lipit de tagul pe care îl instalați
   și alegeți prima intrare.
4. Locul confirmă *„Beacon asociat acestui loc”*.

Pe Android, comutatorul de locație al dispozitivului trebuie să fie
pornit, altfel o scanare Bluetooth nu întoarce absolut nimic; aplicația
explică asta înainte să deschidă selectorul. Vedeți
[Beaconuri BLE](../features/ble-beacons.md) și
[Taguri cu senzori Ruuvi](../features/ruuvi-sensors.md).

Cât sunteți acolo, scanați o dată fiecare etichetă proaspăt montată. O
etichetă care deschide locul corect a fost tipărită, codificată și
montată corect; o etichetă care nu deschide nimic este mult mai ușor de
reparat în tura asta decât în următoarea.

## Pasul 11 — Atașați primele documente

Documentația de bază face peștera utilă cuiva care nu a fost niciodată
în ea.

- **Pentru fiecare loc**: deschideți un loc din peșteră, apăsați
  **Documente**, apoi folosiți **Document text nou**, **Text formatat
  nou**, **Fă o fotografie**, **Înregistrare audio** sau **Adaugă din
  fișier**.
- **În masă**: **Pagina principală → ⋮ → Importă documente în
  peșteri**, apoi **Selectează director**. Fiecare subdirector este
  potrivit cu o peșteră după nume, după un token inițial
  `<area code>-<cave code>` sau manual; fișierele lui sunt atașate acelei
  peșteri. Fișierele deja prezente sunt sărite, iar rezumatul numără
  importate, sărite și eșuate.

Vedeți [Documente](../features/documents.md).

## Pasul 12 — Predați peștera echipei

- Partajarea de zi cu zi: **Setări → Sinc. man. → Arhivă sincronizare →
  Exportă arhivă de sincronizare**, și lăsați-i pe ceilalți să o importe
  din același ecran. Câștigă modificarea cea mai recentă, iar ștergerile
  circulă și ele.
- Un set de date complet nou, cu tot cu media: **Setări → Export /
  Import Date**, bifați **Include fișiere documentație** și **Include
  imagini hărți**, apoi **Exportă Arhivă**. Dispozitivul care primește
  folosește **Importă Arhivă** și alege **Îmbinare cu datele existente**
  sau **Înlocuire totală** — înlocuirea șterge ce se află deja pe acel
  telefon.
- Fără intervenție: îndreptați-i pe toți spre același folder cu
  [Sincronizare FTP](../features/ftp-sync.md) și lăsați aplicația să
  împingă și să tragă arhivele.

Cele două feluri de arhivă nu sunt interschimbabile; citiți
[Partajarea datelor între echipe](sharing-data.md) înainte de primul
schimb.

## Verificați ce ați făcut

- Intrarea apare pe harta de suprafață, etichetată cu titlul peșterii,
  odată ce are coordonate.
- Fiecare loc pe care ați vrut să îl etichetați are un cod, iar codul
  este pe pătratul tipărit.
- Pe fiecare planșă, butonul **Următorul loc fără coordonate** a devenit
  gri și scrie *Toate locurile au deja o locație definită* — numărul pe
  care îl arată este pentru planșa la care vă uitați, așa că verificați
  fiecare planșă în parte.
- O scanare a unei etichete montate deschide locul corect din peșteră.

> 📷 [Etichete de intrare degajate](../screenshots/02-cave-map.md#cave-map-decluttered-labels) — Harta de suprafață pe OpenTopoMap, cu reperele de intrare etichetate cu titlurile peșterilor.

## Vezi și

- [Navigarea în subteran](navigating-underground.md)
- [Partajarea datelor între echipe](sharing-data.md)
- [Locuri din peșteră](../features/cave-places.md)
- [Hărți](../features/raster-maps.md)
- [Coduri QR — amplasare, scanare, printare](../features/qr-codes.md)
- [Coduri de loc (PCI) și conținutul codurilor QR (QCRI)](../features/place-code-identifiers.md)
