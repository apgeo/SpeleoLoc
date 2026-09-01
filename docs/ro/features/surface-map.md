# Harta peșterilor

[← Înapoi la cuprins](../README.md)

Harta peșterilor este o hartă geografică pe tot ecranul, cu fiecare loc din
peșteră care are coordonate — aici priviți intrările pe teren și tot aici
creați peșteri, adăugați intrări și fixați poziția unui loc fără să tastați
niciun număr. Notele mai vechi numesc același ecran *harta de suprafață*.

## Deschiderea hărții

- **Ecranul principal → Harta peșterilor** (butonul din bara de instrumente
  sau aceeași intrare din meniul paginii principale). Arată locurile
  peșterilor vizate în acel moment: peșterile bifate când lista este în mod
  selecție, altfel toate peșterile rămase vizibile după filtrare.
- **Lista de locuri a unei peșteri → Harta peșterilor**. Locurile acestei
  peșteri — cele bifate în mod selecție, altfel cele rămase după filtrare —
  sunt desenate evidențiat printre locurile tuturor celorlalte peșteri.
- **Un loc din peșteră → Alege coordonatele pe hartă**. Harta se deschide ca
  selector de coordonate și trimite înapoi în formular poziția pe care o
  confirmați — vedeți [mai jos](#using-the-map-as-a-coordinate-picker).

### Unde se deschide harta

Harta încadrează lucrul pentru care a fost deschisă, nu locul unde ați
lăsat-o data trecută:

- un singur loc vizat — centrată pe el, cu zoom apropiat;
- mai multe locuri — toate încadrate pe ecran, fără a mări niciodată mai mult
  decât o vedere la nivel de stradă;
- selectorul de coordonate — pe poziția existentă a locului, dacă are una,
  altfel pe locurile peșterii sale.

Doar când nu poate încadra absolut nimic revine la poziția camerei memorată de
la ultima vizită, iar dacă nici această memorie nu există, se deschide peste
centrul României, la un zoom larg.

## Ce vedeți pe hartă

> 📷 [Harta peșterilor pe un strat de bază topografic](../screenshots/02-cave-map.md#cave-map-topo-entrances) — Harta de suprafață arătând intrări de peșteră pe un strat de bază topografic.

### Marcaje

| Marcaj | Semnificație |
| --- | --- |
| Reper întunecat în formă de arcadă de peșteră, mai mare | Intrare principală |
| Reper în formă de arcadă de peșteră, mai mic | Altă intrare |
| Punct albastru mic | Un loc din peșteră care nu este intrare |
| Reper gri sau punct gri | Un loc care aparține unei peșteri pentru care nu a fost deschisă harta |

Apăsarea unui marcaj îl selectează: este desenat evidențiat, eticheta lui
rămâne obligatoriu vizibilă și în partea de jos a ecranului apare un card
informativ.

### Etichete

Intrarea unică a unei peșteri cu o singură intrare este etichetată doar cu
titlul peșterii — pe o hartă de suprafață intrarea *este* peștera. Orice alt
loc este etichetat `Titlul peșterii - Titlul locului`.

Etichetele sunt eliminate atunci când s-ar suprapune, într-o ordine fixă de
prioritate: locul pe care l-ați apăsat ultima dată își păstrează
întotdeauna eticheta, apoi tot ce aparține peșterilor sau locurilor pentru
care a fost deschisă harta, iar abia în interiorul fiecăruia dintre aceste
două grupuri intrarea principală bate intrarea, iar intrarea bate locul
obișnuit. Așa că, într-o vedere aglomerată, dispar primele etichetele
celorlalte peșteri, inclusiv cele ale intrărilor lor principale.

### Grupări

Depărtați suficient zoomul și marcajele apropiate se strâng într-un balon
numerotat — albastru când cel puțin unul dintre membrii lui aparține
peșterilor pentru care a fost deschisă harta, gri în rest. Apăsați un balon
pentru a mări exact pe membrii lui. Marcajele grupate nu au etichete;
etichetele revin pe măsură ce măriți și baloanele se desfac.

### Cardul informativ al locului

Apăsarea unui marcaj deschide un card cu titlul locului, peștera lui împreună
cu rolul **Intrare principală** / **Intrare**, coordonatele lui, precum și
altitudinea și adâncimea în peșteră, dacă au fost înregistrate. Coordonatele
apar în formatul ales în **Setări → Hartă** (vedeți
[GPS și coordonate](gps-and-coordinates.md)).

Cele trei butoane ale cardului sunt **Închide**, **Deschide locul din
peșteră** (pagina completă a locului — coordonatele sau titlurile schimbate
acolo sunt preluate când reveniți) și **Stabilește locația** (repoziționează
acest loc pe hartă). Cât timp harta este folosită ca selector de coordonate
nu apare niciun card — bara de plasare are partea de jos a ecranului numai
pentru ea.

## Bara de instrumente

O bară de instrumente compactă înlocuiește bara obișnuită a aplicației din
partea de sus a ecranului. Se derulează lateral când butoanele nu încap toate.

| Buton | Ce face |
| --- | --- |
| **Înapoi** | Închide harta. |
| **Locația mea** | Cere prima dată permisiunea de localizare, apoi arată poziția dumneavoastră ca un punct albastru cu un cerc translucid de precizie și ține harta centrată pe ea. Deplasarea hărții oprește urmărirea; o nouă apăsare a butonului o oprește la fel. |
| **Straturi hartă** | Deschide selectorul de strat de bază / suprapuneri. |
| **Arată locurile din alte peșteri** / **Ascunde locurile din alte peșteri** | Arată sau ascunde locurile estompate ale tuturor peșterilor pentru care nu a fost deschisă harta. |
| **Arată locurile care nu sunt intrări** / **Ascunde locurile care nu sunt intrări** | Arată sau ascunde locurile care nu sunt intrări. |
| **Toate locurile din peșteri** | Deschide lista tuturor locurilor cartate. |
| **Intrări** | Deschide aceeași listă, filtrată la intrări. |
| **Măsoară distanța** | Pornește instrumentul de măsurare. Ascuns cât timp se plasează un punct. |
| **Adaugă punct** | Deschide meniul Peșteră nouă / Intrare nouă. Ascuns cât timp se plasează un punct și în modul selector de coordonate. |

Cele două comutatoare de vizibilitate se combină, așa că, ascunzându-le pe
amândouă, rămân doar intrările peșterilor pentru care ați deschis harta.

Dacă **Locația mea** raportează *Serviciile de localizare sunt oprite*,
aplicația vă deschide și setările de localizare ale sistemului. *Permisiune de
localizare refuzată* este doar o avertizare — pagina de setări a aplicației se
deschide numai când permisiunea a fost refuzată definitiv. În ambele cazuri nu
se arată nicio poziție până când localizarea nu devine disponibilă.

### Listele de locuri

Cele două butoane de listă deschid un panou peste hartă. Rândurile se citesc
`Titlul locului - Titlul peșterii`, sortate alfabetic, fiecare cu pictograma
marcajului său și cu mențiunea **Intrare** sau **Intrare principală**
dedesubt. Apăsați un rând și harta zboară la acel loc și îl selectează.

Listele sunt construite din toate locurile care au coordonate și ignoră cele
două comutatoare de vizibilitate, așa că un loc pe care l-ați ascuns apare
totuși în listă — apăsarea lui repornește comutatorul care îl ascundea. Când
niciun loc nu are coordonate, panoul afișează *Niciun loc din peșteră cu
coordonate*.

Cât timp un panou este deschis, acesta acoperă harta și cardurile de jos;
apăsați din nou același buton din bara de instrumente pentru a-l închide.

## Măsurarea unei distanțe

> 📷 [Măsurarea unei distanțe pe hartă](../screenshots/02-cave-map.md#cave-map-measure-distance) — Modul de măsurare: un traseu din mai multe segmente pe hartă, cu distanța totală și azimutul.

1. Apăsați **Măsoară distanța**.
2. Apăsați harta pentru a adăuga puncte pe traseu. Dacă apăsați în schimb un
   **marcaj**, punctul se fixează exact pe acel loc, așa că distanțele dintre
   punctele înregistrate sunt exacte, nu apreciate din ochi.
3. Bara de jos arată **Total** pentru întregul traseu și **Ultimul segment**,
   cu lungimea și azimutul lui în grade.
4. **Șterge ultimul punct** anulează o apăsare; **Închide** încheie măsurarea.

Distanțele se citesc în metri sub un kilometru și în kilometri peste. Traseul
este temporar — nu se salvează și se pierde când închideți măsurarea sau când
începeți plasarea unui punct.

## Adăugarea și mutarea punctelor

> 📷 [Adăugarea unei peșteri sau a unei intrări de pe hartă](../screenshots/02-cave-map.md#cave-map-add-point-menu) — Meniul Adaugă punct, care oferă Peșteră nouă sau Intrare nouă în locul ales.

Fiecare acțiune de „creare” și de „stabilire a locației” de pe hartă trece
prin același flux de plasare: poziționați un pin roșu, apoi confirmați.

<a id="placing-the-point"></a>

### Plasarea punctului

Porniți o plasare apăsând **Adaugă punct**, ținând apăsat pe hartă în locul
dorit (aceasta deschide același meniu, cu punctul deja acolo) sau din cardul
informativ al unui loc, cu **Stabilește locația**.

Odată ce bara de plasare este afișată jos, punctul poate fi stabilit în trei
feluri:

- **apăsați** harta;
- **trageți** pinul roșu — se mișcă sub degetul dumneavoastră fără a deplasa
  harta, iar aceasta este reglarea mai fină;
- **Folosește locația mea**, care *nu* este o singură citire. Pornește o
  captură mediată: pinul sare la poziția dumneavoastră și apoi se mută
  continuu la media curentă a fiecărei fixări care sosește, așa că, cu cât
  stați mai mult nemișcat, cu atât poziția devine mai strânsă. Apăsați din nou
  butonul pentru a opri medierea și a păstra punctul mediat; apăsarea hărții
  sau tragerea pinului o oprește la fel și vă dă înapoi controlul, iar
  confirmarea îngheață valoarea la care ajunsese media. Nimic pe ecran nu
  arată că medierea rulează sau câte fixări a adunat, așa că stați nemișcat
  câteva secunde înainte de a confirma.

Apăsarea lungă doar *pornește* o plasare. Odată ce bara de plasare este
ridicată, ea nu mai face nimic, iar în timpul măsurării și în modul selector
de coordonate este dezactivată complet.

Apăsarea altui marcaj în timpul plasării doar îl identifică — cardul nu este
afișat, dar locul este evidențiat și etichetat, iar punctul dumneavoastră în
așteptare rămâne unde este. Astfel puteți plasa ușor o intrare nouă la o
distanță cunoscută față de una existentă.

**Anulează** abandonează plasarea. **Confirmă** este activ doar după ce există
un punct.

### Peșteră nouă

> 📷 [Plasarea punctului pentru o peșteră nouă](../screenshots/02-cave-map.md#cave-map-new-cave-placement) — Plasarea punctului de intrare pentru o peșteră nouă pe harta de suprafață.

1. **Adaugă punct → Peșteră nouă** („Creează o peșteră cu o intrare în acest
   punct”).
2. Poziționați punctul și apăsați **Confirmă**. Numele sunt cerute *după*
   confirmare, în mod deliberat — puteți umbla prin zonă și rafina poziția
   înainte de a vă angaja la ceva.
3. Completați **Titlul peșterii** (obligatoriu) și **Numele intrării**
   (precompletat cu *Intrare*) și apăsați **Adaugă**.

Peștera este creată împreună cu un loc de tip intrare în acel punct, iar acea
intrare devine intrarea principală a peșterii. Harta confirmă cu *Peșteră
adăugată*, selectează intrarea nouă și o păstrează printre cele vizate, ca să
nu apară gri.

### Intrare nouă

1. **Adaugă punct → Intrare nouă** („Adaugă o intrare la o peșteră existentă
   în acest punct”).
2. Poziționați punctul și apăsați **Confirmă**.
3. Urcă o filă **Alege o peșteră**, cu caseta de căutare deja focalizată —
   tastați câteva litere din titlul peșterii în loc să derulați.
4. Denumiți intrarea (precompletat cu *Intrare*) și apăsați **OK**.

Locul nou este marcat ca intrare și ca intrare *principală* dacă peștera nu
avea încă una. Harta confirmă cu *Intrare adăugată*.

Dacă peștera are deja un loc cu numele tastat, aplicația nici nu refuză, nici
nu îl suprascrie: adaugă discret un număr, așa că o peșteră la care adăugați
trei intrări de pe hartă ajunge cu *Intrare*, *Intrare 2* și *Intrare 3*.
Tastați nume cu sens pe măsură ce lucrați, dacă vreți să le recunoașteți mai
târziu în liste și pe etichete.

Dacă în baza de date nu există nicio peșteră, aplicația spune *Nu există încă
peșteri — adaugă întâi o peșteră* și vă lasă punctul pe loc; folosiți în
schimb **Peșteră nouă**, care creează peștera și intrarea ei într-un singur
pas.

Renunțarea la oricare dintre aceste dialoguri anulează crearea, dar lasă
punctul pe hartă, așa că puteți apăsa din nou **Confirmă** fără să îl plasați
încă o dată.

### Mutarea unui loc existent

Apăsați marcajul locului, apoi **Stabilește locația** pe cardul lui
informativ. Pinul pornește de la poziția curentă a locului; mutați-l și
apăsați **Confirmă**. Harta raportează *Locație actualizată*.

Se scriu doar latitudinea și longitudinea. Un loc mutat astfel **păstrează
altitudinea pe care o avea deja**, înregistrată la poziția lui veche —
ștergeți-o sau corectați-o în formularul locului din peșteră dacă acest lucru
contează.

### Altitudinea nu se înregistrează aici

Peșterile și intrările create de pe hartă sunt salvate fără altitudine — chiar
și când ați poziționat punctul cu o captură GPS mediată care avea o citire de
altitudine perfect bună; mutarea unui loc existent lasă neatinsă altitudinea
pe care o avea deja. Dacă aveți nevoie de altitudine, deschideți locul după
aceea și folosiți **Înregistrare punct GPS** în formularul locului din
peșteră, care o captează și o completează. Vedeți
[GPS și coordonate](gps-and-coordinates.md).

<a id="using-the-map-as-a-coordinate-picker"></a>

### Folosirea hărții ca selector de coordonate

Dintr-un loc din peșteră, **Alege coordonatele pe hartă** deschide harta deja
în modul de plasare pentru acel loc. Măsurarea, **Adaugă punct** și apăsarea
lungă sunt toate dezactivate, iar apăsarea unui marcaj doar îl evidențiază, în
loc să îi deschidă cardul informativ — ecranul există doar pentru a returna o
singură poziție.

**Confirmă** închide harta și completează câmpurile de latitudine și
longitudine din formular; nimic nu se salvează până când nu salvați locul.
**Anulează** închide harta și lasă formularul neatins.

## Straturi de bază și suprapuneri

Butonul **Straturi hartă** deschide un panou cu o listă **Strat de bază**
(alegeți unul) și o listă **Suprapuneri** (bifați câte vreți).

Straturile de bază sunt zece surse publice online — OpenTopoMap (implicit;
curbele de nivel și umbrirea reliefului se potrivesc cel mai bine muncii de
teren), OpenStreetMap, Google Streets, Google Satellite, Google Hybrid, Esri
World Imagery, Esri World Topo, Carto Positron, CyclOSM și OSM Humanitarian —
plus orice fișier `.mbtiles` offline căruia i-ați dat rolul **Hartă de bază**.
Fișierele cărora le-ați dat rolul **Suprapunere** apar în a doua listă și se
desenează peste stratul de bază; când nu aveți niciunul, panoul spune *Nu s-au
găsit fișiere MBTiles*.

Stratul de bază și suprapunerile activate se rețin de la o sesiune la alta.

O linie mică de atribuire din colțul din stânga jos numește întotdeauna
stratul care este desenat efectiv. Merită o privire: dacă o hartă de bază
offline se dovedește imposibil de citit, harta revine discret la sursa online
în loc să afișeze o eroare, iar acea linie este singurul loc unde se vede
schimbarea.

### Gesturi

Deplasați harta cu un deget, măriți prin ciupire sau prin dublă apăsare. Nu
există butoane de zoom pe ecran, iar **rotirea este dezactivată
intenționat** — nordul este întotdeauna sus, iar o răsucire cu două degete nu
face nimic, în loc să lase harta strâmbă. Mărirea peste maximul propriu al
unui strat continuă să funcționeze: ultimele plăci disponibile sunt scalate în
sus, în loc să rămână gol.

## Folosirea hărții offline

Două mecanisme independente:

- **Plăci online stocate local.** Fiecare placă online pe care ați privit-o
  este păstrată pe dispozitiv: în prima ei săptămână se desenează fără nicio
  cerere de rețea, iar după aceea o copie mai veche este servită ori de câte
  ori rețeaua nu răspunde — așa că o zonă răsfoită acasă continuă să se
  deseneze în subteran sau în afara semnalului. Acoperă doar zonele și
  nivelurile de zoom pe care le-ați privit efectiv.
- **Fișiere MBTiles.** Un fișier `.mbtiles` raster vă dă acoperire offline
  reală și intenționată pentru o regiune întreagă, la fiecare zoom pe care îl
  conține. Vedeți
  [Folosirea straturilor MBTiles offline](../workflows/mbtiles-layers.md)
  pentru cum se produce și se instalează unul.

## Setări → Hartă

| Rând | Ce face |
| --- | --- |
| **Formatul de afișare a coordonatelor** | Grade zecimale, Grade, minute, secunde (DMS) sau UTM. Schimbă modul în care coordonatele sunt *afișate* peste tot — cardul informativ al hărții, bara de plasare, formularul locului din peșteră. Nimic nu se convertește în baza de date, iar la tastare sunt acceptate întotdeauna oricare dintre cele trei formate. |
| **Stochează hărțile online** | Păstrează pe dispozitiv plăcile de hartă de bază descărcate, ca zonele vizitate să funcționeze offline. Activat implicit. |
| **Cache-ul de hartă** | Arată cât spațiu ocupă în acest moment plăcile stocate, cu o pictogramă de coș care le golește (*Cache-ul de hartă a fost golit*). Golirea este sigură: plăcile se descarcă din nou data viitoare când vizitați zona cu conexiune, iar fișierele dumneavoastră MBTiles nu sunt atinse niciodată. |
| **Încărcare automată MBTiles** | Comutatorul principal pentru scanarea folderului MBTiles al aplicației și oferirea fișierelor ca straturi. |
| **Folder MBTiles** | Folderul exact din care sunt citite fișierele, cu un buton **Copiază calea** — calea diferă de la o platformă și de la un dispozitiv la altul. |
| **Importă fișier MBTiles** | Caută un fișier `.mbtiles` cu selectorul de fișiere al sistemului și îl copiază în folder. Aceasta este modalitatea acceptată de a adăuga fișiere pe un telefon. O coliziune de nume întreabă *Fișierul există deja* înainte de a suprascrie. |
| **Fișiere detectate** | Fiecare fișier `.mbtiles` găsit, fiecare cu un rol **Hartă de bază** / **Suprapunere**. Rolurile se rețin per nume de fișier, așa că înlocuirea unui fișier cu un export mai nou îi păstrează rolul. Fișierele vectoriale sunt listate, dar marcate *MBTiles vectorial nesuportat*. |

Bara de aplicație a acelei pagini mai are un buton de import și **Rescanează
folderul**, pentru cazul în care ați copiat un fișier din afara aplicației.

## Vezi și

- [Locuri din peșteră](cave-places.md)
- [GPS și coordonate](gps-and-coordinates.md)
- [Folosirea straturilor MBTiles offline](../workflows/mbtiles-layers.md)
- [Documentarea unei peșteri noi](../workflows/documenting-a-new-cave.md)
- [Setări](settings.md)
