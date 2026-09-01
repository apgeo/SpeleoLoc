# Locuri din peșteră

[← Înapoi la cuprins](../README.md)

Un **loc din peșteră** este un punct denumit dintr-o singură peșteră. Este
înregistrarea de care atârnă tot restul: etichetele QR, documentele,
punctele de pe hartă, beaconurile BLE și punctele de tură trimit toate
către un loc din peșteră.

## Lista locurilor din peșteră

Apăsați o peșteră pe ecranul principal și se deschide lista locurilor ei.
De sus în jos, ecranul cuprinde o bandă de butoane, un buton opțional
**Ture trecute / active**, antetul listei și locurile propriu-zise.

> 📷 [Lista locurilor unei peșteri](../screenshots/01-home-and-caves.md#cave-places-list) — lista locurilor dintr-o peșteră, cu bara ei de acțiuni și pictogramele de stare.

### Ce arată un rând

Fiecare rând arată titlul locului. Intrările primesc o pictogramă de ușă
înaintea titlului, o legendă dedesubt (**Intrare**, sau **Intrare
principală** cu albastru) și un fundal gri estompat, ca să iasă în
evidență într-o listă lungă.

În dreapta titlului stau trei lucruri:

| Element | Semnificație |
|---|---|
| Pictograma QR | Verde când locul are deja un cod de loc, gri când nu are niciunul. |
| Contorul de puncte | Pe câte dintre hărțile peșterii a fost poziționat acest loc. Roșu la zero, verde odată ce este marcat pe fiecare hartă a peșterii, gri între ele. |
| Butonul coș de gunoi | **Șterge locul din peșteră** — vezi [Ștergerea unui loc din peșteră](#deleting-a-cave-place). |

Adâncimea, aria și textul codului **nu** sunt afișate pe rând. Folosiți
selectorul **Sortează după** sau caseta de filtrare dacă trebuie să găsiți
un loc după una dintre ele.

Apăsarea contorului de puncte deschide raportul **Definiții hărți**: o
listă a fiecărei hărți din această peșteră, fiecare cu o bifă verde dacă
locul este marcat pe ea sau cu un cerc roșu dacă nu. Apăsarea unei intrări
închide raportul și deschide editorul de puncte al acelei hărți pentru
acest loc, deci este cea mai rapidă cale de a parcurge hărțile de pe care
un loc încă lipsește. Dacă peștera nu are încă hărți, primiți „Nu există
hărți pentru această peșteră”.

### Banda de butoane

Banda de deasupra listei se derulează lateral, iar butoanele au doar
pictograme — apăsați lung pe unul ca să îi citiți eticheta.

| Buton | Ce face |
|---|---|
| **Scanează QR** | Deschide scanerul camerei și sare la locul din *această* peșteră căruia îi aparține codul; un cod din altă peșteră este raportat ca negăsit aici. Apăsați-l lung vreo două secunde și jumătate ca să tastați în schimb un cod de mână. |
| **Adaugă loc** | Deschide un formular gol de loc din peșteră. |
| **Vezi hărți** | Hărțile peșterii — vezi [Hărți](raster-maps.md). |
| **Harta peșterilor** | Deschide harta de suprafață cu locurile acestei peșteri evidențiate — vezi [Harta peșterilor](surface-map.md). |
| **Printează coduri QR** | Construiește etichete QR printabile pentru peșteră — vezi [Coduri QR](qr-codes.md). |
| **Căutare manuală cod QR** | Arată sub bandă o casetă **Mod de generare identificatori cod QR** cu un buton **Caută loc după id cod QR**. |
| **Zonele peșterii** | Gestionează zonele în care pot fi grupate locurile — vezi [Peșteri și zone de peșteră](caves-and-areas.md). |
| **Poziționare locuri pe hartă** | Deschide editorul de puncte pentru toată peștera, ca să marcați mai multe locuri dintr-o singură ședință. |
| **Import locuri din CSV** | Import în masă — vezi [Import CSV](csv-import.md). |
| **Generează coduri** | Generează coduri de loc pentru fiecare loc din peșteră, întrebând întâi înainte să suprascrie unul deja stabilit — vezi [Coduri de loc](place-code-identifiers.md). |
| **Generează coduri QR pentru locuri (interval)** | Pre-printează etichete pentru numere de loc care încă nu există (mai jos). |
| **Peșteră** | Un mic meniu cu **Editează peștera**, **Beaconurile peșterii** și **Șterge peștera**. |

Meniul ⋮ al ecranului repetă **Editează peștera**, **Șterge peștera**,
**Import locuri din CSV**, **Generează coduri** și **Poziționare locuri pe
hartă**, și adaugă **Începe tura** când nu rulează nicio tură.

### Numărare, filtrare, sortare și selecție

Antetul listei poartă un contor viu al locurilor — arată `(45)` în mod
normal și `(5 /45)` cât timp un filtru îngustează lista — plus trei
butoane:

- **Arată filtrul** deschide o casetă **Filtrare locuri peșteră** care se
  potrivește cu titlul locului, cu codul locului **sau** cu numele zonei
  peșterii.
- **Sortează după** ordonează lista după **Ultima modificare** (implicit,
  cele mai noi întâi), **Titlu**, **Zonă peșteră**, **Adâncime**,
  **Identificator cod QR**, **Intrare**, **Are cod QR** sau **Hărți cu
  poziție**. Sortarea după titlu, zonă, statut de intrare sau prezența
  codului inserează și titluri de grup gri, ca să vedeți dintr-o privire
  ce locuri încă nu au cod sau care aparțin cărei zone. Locurile fără
  adâncime și cele fără cod se sortează la urmă când ordinea este
  crescătoare. Alegerea este reținută pentru această listă între vizite.
- **Mod selecție** pune o casetă de bifat pe fiecare rând și adaugă
  **Selectează tot**, **Inversează selecția** și **Șterge selectate** în
  antet. Cât timp sunt locuri bifate, **Printează coduri QR** le printează
  doar pe acelea, iar **Harta peșterilor** le evidențiază doar pe acelea.
  În afara modului de selecție, **Harta peșterilor** revine la ce lasă
  filtrul vizibil, în timp ce **Printează coduri QR** revine întotdeauna
  la toate locurile din peșteră, cu filtru sau fără.

Comportamentul complet este descris la
[Liste: filtrare, sortare și selecție](lists-filter-sort-select.md).

### Turele din acest ecran

Odată ce cel puțin o tură din această peșteră s-a încheiat, deasupra
listei apare un buton **Ture trecute / active** cu numărul lor; el
deschide istoricul turelor peșterii. Pe acest ecran nu există bandă de
tură — cât timp o tură este în desfășurare, meniul ⋮ al aplicației arată
un card de tură activă cu numele turei, peștera, timpul scurs, numărul de
puncte, ultimele locuri scanate și **Vezi tura** / **Pauză** (sau
**Continuă**) / **Oprește**. Vezi [Ture](trips.md).

## Adăugarea unui loc din peșteră

Patru moduri, alegeți-l pe cel potrivit:

1. **Formularul complet** — butonul **Adaugă loc** din banda de butoane.
   Toate câmpurile sunt disponibile. Folosiți-l când documentați un loc
   ca lumea.
2. **Adăugare loc peșteră** — se ajunge la ea doar din editorul de puncte
   al hărții. Cere un titlu, o valoare **Adâncime '+/-'**, o zonă a
   peșterii și un cod de loc (pe care îl puteți scana de pe o etichetă în
   loc să îl tastați), apoi salvează imediat. Refuză un titlu care există
   deja în această peșteră și un cod de loc folosit deja de alt loc din
   această peșteră.
3. **Prin apăsare pe o hartă** — în editorul de puncte al hărții apăsați
   butonul **Adăugare loc peșteră**; aplicația vă spune „Atingeți harta
   pentru a defini punctul pentru noul loc din peșteră”. Apăsați locul,
   se deschide dialogul de adăugare rapidă, iar la salvare noul loc este
   marcat exact unde ați apăsat. Modul rămâne pornit după aceea, așa că
   puteți adăuga un loc după altul fără să mai apăsați butonul. Vezi
   [Vizualizatorul de hărți și editorul de puncte](map-viewer.md).
4. **Import CSV** — în masă, dintr-un tabel. Vezi
   [Import CSV](csv-import.md).

### Pre-printarea etichetelor pentru locuri care încă nu există

**Generează coduri QR pentru locuri (interval)** cere un **De la indexul**
și un **Până la indexul** și produce etichete printabile pentru tot acel
interval de numere de loc, indiferent dacă locurile respective există sau
nu în aplicație. Este gândit pentru o tură în care duceți sub pământ o
coală de etichete numerotate și notați după aceea la ce ați lipit fiecare.
Numerele deja folosite de un loc existent sunt sărite, la fel și indexul
rezervat intrării principale, iar vi se spune câte au fost sărite.
Funcționează doar cu strategia ierarhică de coduri de loc și doar după ce
peștera are un index local și codurile de țară și de organizație sunt
setate — altfel aplicația spune care dintre ele lipsește.

## Formularul locului din peșteră

Apăsarea unui rând deschide formularul locului din peșteră. Este o
singură pagină lungă, cu derulare, nu un set de file. De sus în jos
cuprinde:

1. **Titlu** și **Descriere** (butonul de lângă descriere îi adaugă un
   rând, până la cinci).
2. Un rând cu câmpul **Depth '+/-'** (adâncimea), lista derulantă **Titlul
   ariei (opțional)** și un buton pentru gestionarea ariilor peșterii.
   Eticheta acestui câmp nu este încă tradusă: formularul o afișează în
   engleză chiar și cu aplicația setată pe română. În fereastra de
   adăugare rapidă, în schimb, ea apare tradusă, ca **Adâncime '+/-'**.
3. Rândul **Identificator cod loc** și rândul **Identificator resursă cod
   QR**, fiecare în spatele unui lacăt.
4. **Beaconuri BLE** — doar după ce locul a fost salvat o dată.
5. **Latitudine / Longitudine / Altitudine** — ascunse până le afișați.
6. **Hărți** — câte o filă pentru fiecare hartă a peșterii, ca să marcați
   acest loc pe fiecare.
7. Casetele de bifat **Intrare în peșteră** și **Intrarea principală**.

Bara de sus poartă un buton de salvare, un buton glob **Alege
coordonatele pe hartă**, meniul ⋮ și — odată ce locul a fost salvat — un
buton dosar **Documente**. Documentele nu sunt o filă a acestui formular;
vezi [Documente](documents.md).

Orice câmp a cărui valoare diferă de ce a fost încărcat capătă o nuanță
verde palidă, așa că înainte de salvare vedeți dintr-o privire exact ce
ați schimbat. Nuanța dispare când locul este salvat. Încercarea de a ieși
cu modificări nesalvate întreabă „Renunți la modificări și ieși fără
salvare?”.

> 📷 [Formularul locului: coduri și beacon](../screenshots/04-places-and-qr-codes.md#cave-place-form-codes-and-beacons) — formularul locului din peșteră, derulat de la Titlu prin Beaconuri BLE până la filele Hărți.

### Referință de câmpuri

| Câmp | Observații |
|---|---|
| **Titlu** | Obligatoriu — salvarea fără el avertizează „Titlul este obligatoriu”. Dialogul de adăugare rapidă refuză un titlu care există deja în peșteră; formularul complet nu verifică, așa că păstrați dumneavoastră titlurile distincte. Titlul este ceea ce vedeți în liste, pe etichetele printate și în jurnalele de tură. |
| **Descriere** | Text liber, pe mai multe rânduri. |
| **Depth '+/-'** (adâncimea; în formular eticheta apare netradusă) | Număr cu semn, opțional, până la patru cifre întregi și o zecimală. Valorile negative (de exemplu `-45`) sunt obișnuite pentru puncte de sub intrare, cele pozitive pentru cele de deasupra. Și virgula, și punctul funcționează ca separator zecimal. Peste ±5000 aplicația refuză să salveze („Adâncimea trebuie să fie între -5000 și +5000”); peste ±1800 vă cere să confirmați că valoarea nu este o greșeală de tastare. Lăsați-l gol dacă nu știți. |
| **Titlul ariei (opțional)** | Leagă locul de o [zonă a peșterii](caves-and-areas.md). Alegerea **Niciuna** pentru un loc care avea deja o arie întreabă întâi „Șterge aria atribuită acestui loc?”. |
| **Identificator cod loc** | Codul lizibil printat pe etichetă — orice șir, în funcție de [strategia](place-code-identifiers.md) activă. Ar trebui să fie unic în cadrul unei peșteri: dacă alt loc din aceeași peșteră îl folosește deja, salvarea vă avertizează, dar vă lasă să păstrați duplicatul. Același cod refolosit într-o *altă* peșteră nu este semnalat la salvare; scanarea lui mai târziu vă oferă locurile potrivite din care să alegeți. |
| **Identificator resursă cod QR** | Conținutul înglobat efectiv în pixelii QR și în linkul `sp://`. Este egal cu codul locului în modul oglindă sau un hash scurt în modul hash — iar în modul oglindă o intrare este oricum trecută prin hash când setarea **Hash pentru intrări** este activă. Aplicația îl calculează pentru dumneavoastră la salvare, dar **numai dacă ați lăsat câmpul gol**; orice tastați acolo este salvat exact așa cum a fost tastat. Ștergerea codului locului îl șterge și pe acesta. Vezi [Coduri de loc](place-code-identifiers.md). |
| **Latitudine / Longitudine / Altitudine** | Poziție opțională, ascunsă până afișați rândul. Latitudinea și longitudinea sunt în grade zecimale; altitudinea este în metri. Vezi [GPS și coordonate](gps-and-coordinates.md). |
| **Intrare în peșteră** / **Intrarea principală** | Două casete de bifat la baza formularului (mai jos). |

### Cele două rânduri de cod

Atât câmpul **Identificator cod loc**, cât și câmpul **Identificator
resursă cod QR** se deschid **blocate de fiecare dată** — inclusiv la un
loc nou-nouț — ca o lovitură în telefon într-o galerie udă să nu poată
suprascrie un cod deja printat pe o etichetă. Apăsați lacătul din stânga
unui câmp ca să îl deblocați; eticheta lui comută între **Activează
editarea codului QR** și **Dezactivează editarea codului QR**. Butonul
**Generează automat** de lângă fiecare câmp rămâne gri până deblocați acel
câmp.

În modul oglindă implicit, conținutul QR este doar o copie a codului
locului, așa că formularul ascunde rândul **Identificator cod loc** când
deschideți un loc ale cărui două valori sunt deja identice. Apăsați
butonul ochi (**Afișează codul locului**) din dreapta rândului cu
adâncimea și aria ca să îl aduceți înapoi. Rândul este afișat întotdeauna
când cele două valori diferă, când locul nu are încă niciun cod sau când
se folosește modul hash.

Butonul **Scanează** de la capătul rândului Identificator resursă cod QR
preia un cod de pe o etichetă deja montată în peșteră:

1. Dacă codul scanat este deja folosit de alt loc de oriunde din baza de
   date, aplicația îl refuză și numește acel loc.
2. Dacă acest loc are deja un cod diferit, întreabă **Înlocui codul QR?**
   — „Un cod QR diferit este deja setat pentru acest loc. Doriți să-l
   înlocuiți?”. Aceasta schimbă doar valoarea din formularul din fața
   dumneavoastră, niciodată un cod stocat pe alt loc.
3. Odată acceptat, câmpul este deblocat și completat. În modul oglindă,
   câmpul codului locului este completat cu aceeași valoare, dar numai
   dacă era încă gol — și nu dacă alt loc de oriunde folosește deja acel
   cod, caz în care sunteți avertizat și se completează doar câmpul cu
   conținutul QR.
4. Pentru un loc care a fost deja salvat, se afișează o previzualizare a
   codului QR rezultat.

Apăsați lung butonul **Scanează** vreo două secunde și jumătate ca să
tastați un cod de mână în loc să îl scanați. Când locul este salvat și are
un conținut QR, un buton **Vizualizează cod QR** de la începutul rândului
îi arată eticheta oricând.

### Beaconuri BLE

Odată ce un loc a fost salvat cel puțin o dată, formularul arată o
secțiune **Beaconuri BLE** care listează tagurile Bluetooth montate în
acel punct.

- **Asociază beacon** deschide **Beaconuri în apropiere**, care scanează
  după tagurile din jurul dumneavoastră — țineți telefonul lângă cel pe
  care îl montați și alegeți-l din listă. Tagurile deja înregistrate
  oriunde în această peșteră sunt gri și marcate „deja asociat”, așa că nu
  puteți atașa același tag de două ori.
- Fiecare rând arată identitatea tagului — major/minor și identificatorul
  de proximitate pentru un iBeacon, adresa MAC și modelul pentru un senzor
  Ruuvi — plus ultima tensiune raportată a bateriei. Apăsarea unui rând
  Ruuvi deschide citirile lui în timp real; vezi
  [Senzori Ruuvi](ruuvi-sensors.md).
- Butonul de dezasociere din dreapta rândului întreabă „Elimini beaconul …
  de la acest loc?” și apoi eliberează tagul pentru alt loc.

**Aceste modificări sunt scrise imediat, nu când apăsați Salvează**, și nu
sunt anulate dacă renunțați la restul modificărilor. Vezi
[Beaconuri BLE](ble-beacons.md).

### Coordonate GPS

Rândul de coordonate este ascuns implicit. Bifați **Arată/Ascunde
coordonate GPS** din meniul ⋮ ca să îl scoateți la iveală. Alegerea nu
este reținută — rândul este ascuns din nou data viitoare când deschideți
locul — dar alegerea unei poziții pe hartă îl scoate la iveală pentru
dumneavoastră.

La capătul rândului stau trei butoane cu pictograme:

- **Înregistrare punct GPS** deschide înregistratorul. Preia continuu
  fixuri de la dispozitiv și ține o medie curentă, arătând numărul de
  mostre, acuratețea în metri și un cuvânt de calitate (Excelent, Bun,
  Acceptabil, Slab, Foarte slab). Apăsați **Capturează** odată ce citirea
  în timp real s-a așezat, apoi **Folosește această poziție** ca să
  copiați rezultatul în formular — aceasta este singura cale care
  completează și **Altitudine**.
- **Alege coordonatele pe hartă** deschide harta de suprafață ca selector
  și întoarce latitudinea și longitudinea. Același buton se află pe
  pictograma glob din bara de sus, unde funcționează chiar și cât timp
  rândul de coordonate este ascuns.
- **Introdu coordonatele** deschide o singură casetă care acceptă grade
  zecimale, grade-minute-secunde sau UTM — formatul este detectat din ce
  tastați, iar cele trei rânduri de exemplu de sub câmp arată formele
  acceptate. Completează doar latitudinea și longitudinea.

Cele trei câmpuri iau ele însele numere zecimale simple, așa că folosiți
**Introdu coordonatele** pentru orice este în DMS sau UTM. Dacă formatul
de afișare a coordonatelor este setat pe altceva decât zecimal, poziția
convertită apare în timp real sub câmpuri. Nimic nu se stochează până nu
salvați locul. Vezi [GPS și coordonate](gps-and-coordinates.md).

### Hărți

Când peștera are hărți, aproape de baza formularului apare o bandă
**Hărți** cu o filă pentru fiecare hartă (butoanele săgeată de o parte și
de alta le parcurg) și o previzualizare a celei curente. Apăsarea
previzualizării, sau a butonului **Definește locul pe hartă** de pe ea,
deschide editorul de puncte pentru acest loc și acea hartă.

Dacă locul nu a fost salvat niciodată, aplicația îl salvează întâi și
rămâne pe formular, ca să puteți crea un loc și să îl marcați dintr-o
singură trecere — fiecare întrebare obișnuită de la salvare (titlu lipsă,
adâncime neobișnuită, cod duplicat) apare tot în acel moment. Vezi
[Vizualizatorul de hărți și editorul de puncte](map-viewer.md).

### Marcajele de intrare

Cele două casete de bifat de la baza formularului sunt **Intrare în
peșteră** și **Intrarea principală**. **Intrarea principală** rămâne gri
până când **Intrare în peșteră** este bifată, iar debifarea **Intrare în
peșteră** o șterge din nou.

Orice schimbare a oricăreia dintre casete cere întâi o confirmare. În
plus:

- Bifarea **Intrare în peșteră** când peștera are deja alte intrări le
  listează sub **Există alte intrări în peșteră** și întreabă dacă chiar
  asta vreți.
- Bifarea **Intrarea principală** când alt loc poartă deja acel marcaj
  este **refuzată**: aplicația arată **Intrarea principală este deja
  definită**, numește locul care îl poartă și lasă bifa dumneavoastră
  neaplicată. Deschideți acel loc, retrogradați-l la intrare obișnuită,
  apoi reveniți.

Marcajele de intrare determină pictogramele de ușă din listă, rapoartele
și fluxul QR pentru intrări descris la [Coduri QR](qr-codes.md).

### Ce se întâmplă când salvați

Apăsarea butonului de salvare rulează aceste verificări, în ordine, și
oricare dintre ele poate opri salvarea:

1. **Titlul este obligatoriu.**
2. Adâncimea trebuie să fie un număr lizibil și în interiorul ±5000.
3. O adâncime peste ±1800 întreabă „Valoarea adâncimii (…) este în afara
   intervalului obișnuit (-1800 până la +1800). Sunteți sigur că este
   corectă?”.
4. Dacă alt loc din **aceeași peșteră** folosește deja acest cod de loc,
   apare un avertisment **Cod QR duplicat**: „Locul "…" folosește deja
   codul QR …. Salvați cu duplicat?”. **Da** salvează oricum și lasă
   ambele locuri cu același cod; **Anulează** abandonează salvarea, deci
   nu se scrie nimic. Aplicația nu editează și nu șterge niciodată codul
   de pe celălalt loc — dacă vreți codul mutat, deschideți acel loc și
   ștergeți-l dumneavoastră.
5. Dacă ați editat de mână identificatorul resursă cod QR la o valoare
   folosită deja **oriunde în baza de date**, apare același avertisment
   pentru acel câmp.
6. Dacă titlul este exact „intrare” și locul nu este încă marcat,
   aplicația se oferă să îl marcheze ca intrare.
7. Dacă locul este salvat ca intrare și peștera nu are încă o intrare
   principală, aplicația se oferă să o facă pe aceasta intrarea
   principală.

Ultimele două decizii sunt aplicate înregistrării salvate, dar casetele de
bifat de pe ecran nu sunt rebifate, în mod deliberat — redeschideți locul
dacă vreți să vedeți rezultatul.

<a id="deleting-a-cave-place"></a>

## Ștergerea unui loc din peșteră

Ștergerea se face doar din **lista locurilor din peșteră**; pe formularul
locului nu există nicio acțiune de ștergere. Fie apăsați butonul coș de
gunoi din dreapta unui rând și confirmați „Sigur doriți să ștergeți acest
loc din peșteră?”, fie porniți **Mod selecție**, bifați mai multe locuri
și folosiți **Șterge selectate**.

**Ștergerea este ireversibilă.** Odată cu locul se șterg:

- punctele lui de pe fiecare hartă a peșterii,
- legăturile lui către documente — documentele în sine nu sunt șterse și
  rămân accesibile din orice alt loc sau peșteră de care sunt legate,
- fiecare asociere de beacon BLE de pe acel loc, inclusiv tagurile care
  fuseseră deja dezasociate. Tagul fizic montat acolo încetează să mai fie
  recunoscut până când îl asociați altui loc, iar eliminarea ajunge la
  celelalte dispozitive la următoarea sincronizare.

Punctele de tură care au înregistrat locul **nu** sunt șterse: rămân în
turele lor, dar nu mai numesc niciun loc.

## Vezi și

- [Coduri de loc (PCI) și conținut QR (QCRI)](place-code-identifiers.md)
- [Coduri QR](qr-codes.md)
- [Vizualizatorul de hărți și editorul de puncte](map-viewer.md)
- [Beaconuri BLE](ble-beacons.md)
- [GPS și coordonate](gps-and-coordinates.md)
- [Liste: filtrare, sortare și selecție](lists-filter-sort-select.md)
