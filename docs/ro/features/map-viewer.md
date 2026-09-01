# Vizualizatorul de hărți și editorul de puncte

[← Înapoi la cuprins](../README.md)

Această pagină descrie ecranele care arată o [hartă raster](raster-maps.md)
cu pini pentru locurile din peșteră — cum vă deplasați pe imagine, ce
înseamnă pinii și cum dați unui loc din peșteră poziția lui pe o hartă.

> Numele controalelor de mai jos sunt cele din interfața în limba română.
> Dacă aplicația pornește în altă limbă, o comutați din
> **Setări → General → Limba aplicației**.

## Cele patru locuri în care apare o hartă

| Ecran | Ce puteți face |
|---|---|
| **Vezi hărți** (vizualizatorul de hărți) | Doar priviți. Deplasați, măriți, apăsați pinii, săriți la pagina unui loc sau la documentele lui. |
| **Poziționare locuri pe hartă** | Tot ce face vizualizatorul, plus amplasarea, mutarea și eliminarea punctelor. |
| Secțiunea **Hărți** a unui loc din peșteră | O previzualizare statică a fiecărei hărți. Apăsarea ei deschide *Poziționare locuri pe hartă*. |
| **Vedere hartă** a unei ture | Doar priviți, cu ruta turei desenată peste hartă. |

### Cum ajungeți la fiecare dintre ele

- **Scanați codul QR al unui loc sau intrați în raza beaconului său BLE** —
  SpeleoLoc deschide vizualizatorul de hărți pe prima hartă (în ordinea
  hărților stabilită de dumneavoastră, vedeți
  [Sortarea hărților](#sorting-the-maps)) care are deja un punct pentru
  acel loc, ușor depărtată și centrată pe pin. Dacă nicio hartă nu are un
  punct pentru el, ajungeți în schimb pe pagina locului din peșteră —
  după o scanare QR, cu mesajul *Acest loc din peșteră nu este definit pe
  nicio hartă.*
- **Din lista de locuri a unei peșteri** — butonul cu pin din bara de
  instrumente, *Poziționare locuri pe hartă*, deschide prima hartă cu
  primul loc selectat. Fiecare rând din acea listă are și o pictogramă de
  pin cu un număr; apăsarea ei listează hărțile peșterii ca *Definiții
  hărți*, cu o bifă lângă cele care au deja un punct pentru acel loc, iar
  alegerea uneia o deschide pentru editare.
- **Dintr-un loc din peșteră** — derulați până la secțiunea **Hărți**,
  descrisă la [Poziționarea unui loc](#giving-a-place-a-position).
- **Dintr-o tură** — butonul **Vedere hartă** din bara de instrumente a
  turei.

> 📷 [Selectorul de locuri pe harta raster](../screenshots/03-raster-maps.md#raster-map-place-selector) — Amplasarea locurilor din peșteră pe o hartă raster, cu barele de navigare pentru hărți și locuri.

## Deplasarea pe hartă

- **Ciupire (pinch)** — măriți și micșorați. Punctul de sub degete rămâne
  pe loc.
- **Tragere** — deplasați imaginea.
- **Butoanele de zoom**, în dreapta jos a imaginii — **−**, un buton de
  resetare care aduce toată harta înapoi în cadru, și **+**.
- **Apăsați un pin** — locul din peșteră devine cel curent: pinul
  clipește, harta se mută pe el fără să vă schimbe mărirea, iar banda cu
  locuri derulează până la el. Nu deschide locul; pentru asta folosiți
  butonul **Deschide locul**.
- **Apăsați lung un pin** — un mesaj scurt numește locul din peșteră
  căruia îi aparține. Util într-un colț aglomerat, unde etichetele se
  suprapun.
- **Apăsați pe imagine** — pe o hartă doar de vizualizare nu se întâmplă
  nimic. Pe *Poziționare locuri pe hartă* fie lasă un punct nou, fie alege
  pinul cel mai apropiat, în funcție de modul de atingere descris mai jos.

Trecerea de la un loc la altul vă păstrează mărirea curentă și doar
deplasează harta pe noul pin, așa că puteți lucra pe toată ridicarea
topografică la o scară constantă.

Nu există zoom prin dublă atingere și nici zoom din rotița mouse-ului —
ciupirea și butoanele de zoom sunt singurele moduri de a schimba scara.

## Benzile de deasupra hărții

Între bara aplicației și imagine stau două benzi orizontale:

- banda **hărților** — o miniatură și un titlu pentru fiecare hartă raster
  a acestei peșteri, în ordinea de hărți aleasă de dumneavoastră;
- banda **locurilor din peșteră** — o insignă rotundă cu prima literă din
  numele fiecărui loc, iar dedesubt numele.

Culoarea insignei vă spune starea locului **pe harta la care vă uitați**:

| Insignă | Semnificație |
|---|---|
| Gri | Încă niciun punct pe această hartă |
| Roșu | Are deja un punct pe această hartă |
| Albastru, și mai mare | Locul la care lucrați |

Parcurgerea benzii după insigne gri este cea mai rapidă cale de a vedea cât
din peșteră a rămas fără pini.

### Afișarea, ascunderea și micșorarea benzilor

- **Vizualizare bară navigație** (butonul cu straturi din bara laterală)
  deschide un meniu cu două casete de bifat, **Afișează lista hărților** și
  **Afișează lista locurilor**. Dezactivarea oricăreia dă înălțimea ei
  înapoi hărții. Orice acțiune care are nevoie de o bandă ascunsă o aduce
  singură înapoi — filtrarea sau sortarea locurilor arată banda locurilor,
  sortarea sau administrarea hărților arată banda hărților — așa că nu
  puteți rămâne blocat.
- **Comutare navigare compactă**, în bara aplicației, micșorează *ambele*
  benzi la miniaturi și subtitluri mai mici (titlurile rămân, doar mai
  mici). Această setare este comună tuturor ecranelor cu hartă și se
  reține între sesiuni. Harta turei este întotdeauna compactă și nu are
  comutator.

### Filtrarea benzii cu locuri

Lupa din bara laterală — și **Filtrare locuri peșteră** din meniul ⋮ al
ecranului — deschide o casetă mică de căutare deasupra benzii cu locuri. Ce
tastați este comparat cu numele, descrierea, codul locului și zona de
peșteră ale fiecărui loc. Banda se restrânge la potriviri; pe hartă,
locurile care nu se potrivesc rămân vizibile ca puncte estompate, fără
etichete, ca să nu vă pierdeți reperele. Goliți caseta, sau apăsați lupa
din nou, ca să aduceți totul înapoi.

<a id="sorting-the-maps"></a>

### Sortarea hărților

**Sortare hărți** (⋮ din bara laterală, sau meniul ⋮ al ecranului) oferă
**Ordine manuală**, **Număr de locuri**, **Titlu (alfabetic)** sau
**Dimensiune hartă**, **Crescător** sau **Descrescător**. *Ordine manuală*
este ordinea pe care o stabiliți trăgând rândurile pe ecranul
[Hărți](raster-maps.md) al peșterii.

Alegerea se reține între sesiuni dacă o faceți din vizualizatorul de hărți
sau din harta turei. Contează dincolo de ordine: când scanați un cod QR sau
când este detectat un beacon, SpeleoLoc deschide **prima hartă din această
ordine** care are deja un punct pentru acel loc.

### Sortarea benzii cu locuri

**Sortare locuri peșteră** reordonează insignele. Câmpurile sunt **Ultima
modificare**, **Titlu (alfabetic)**, **Zonă peșteră**, **Adâncime**,
**Identificator cod QR**, **Tip intrare**, **Are cod QR** și **Hărți cu
poziție**, crescător sau descrescător. Alegerea se reține; dacă nu ați
făcut niciodată una, urmează sortarea folosită ultima dată pe lista de
locuri din peșteră.

Sortarea după **Zonă peșteră** face ceva în plus pe *Poziționare locuri pe
hartă*: banda este împărțită în casete mici cu chenar, câte una pentru
fiecare zonă, cu numele zonei deasupra fiecăreia, ca să puteți lucra pe
rând, pe o singură parte a peșterii.

## Bara laterală de instrumente

Fiecare ecran cu hartă începe doar cu un mic **chevron** în colțul din
stânga sus al imaginii. Apăsați-l ca să glisați afară o bară verticală,
semitransparentă; apăsați-l din nou ca să o strângeți la loc. Alegerea
dumneavoastră se păstrează pe toate ecranele cu hartă până închideți
aplicația.

Bara este aceeași în vizualizatorul de hărți, în *Poziționare locuri pe
hartă* și pe harta turei:

| Buton | Ce face |
|---|---|
| **Următorul loc fără coordonate** (țintă) | Sare la următorul loc din peșteră care nu are punct pe această hartă, reluând de la capăt la final, și derulează banda cu locuri până la el. Indiciul lui numără cât a mai rămas — *Următorul loc fără coordonate (7 rămase)*. Se estompează, cu *Toate locurile au deja o locație definită*, când ați terminat. |
| **Filtrare locuri peșteră** (lupă) | Deschide sau închide caseta de căutare de deasupra benzii cu locuri. |
| **Vizualizare bară navigație** (straturi) | Arată / ascunde banda hărților și banda locurilor. |
| **Mai multe acțiuni** (⋮) | Filtrare locuri peșteră, Sortare locuri peșteră, Sortare hărți, Administrare hărți. |
| **Ecran complet** | Vedeți [Ecran complet și mod peisaj](#full-screen-and-landscape). |
| **Inversare culori** | Inversare dintr-o singură apăsare, pentru o scanare întunecată. Apăsați din nou (*Restaurare culori*) ca să reveniți. |
| **Procesare imagine** (glisoare) | Meniul de efecte, vedeți [Cum faceți lizibilă o scanare palidă](#making-a-faint-scan-readable). |

**Administrare hărți** părăsește harta și deschide ecranul
[Hărți](raster-maps.md) al peșterii, unde hărțile se adaugă, se editează,
se reordonează și se șterg.

## Bara de acțiuni de sub hartă

| Buton | Unde | Ce face |
|---|---|---|
| **Comutare legendă** (ⓘ) | Peste tot | Arată sau ascunde legenda din colțul din stânga jos. |
| **Mod atingere** | Doar *Poziționare locuri pe hartă* | Comută între lăsarea de puncte noi și selectarea celor existente. |
| **Resetează punctul la poziția inițială** (↶) | Doar *Poziționare locuri pe hartă* | Anulează un punct pe care l-ați atins, dar nu l-ați salvat încă. |
| **Elimină definiția punctului** (coș roșu) | Doar *Poziționare locuri pe hartă* | Șterge punctul acestui loc de pe această hartă. |
| **Adăugare loc peșteră** | Doar *Poziționare locuri pe hartă* | Creează un loc nou în peșteră acolo unde atingeți. |
| **Deschide locul** | Peste tot, odată ce un loc este selectat | Deschide pagina completă a acelui loc. |
| **Documente** | Peste tot, odată ce un loc este selectat | Deschide fotografiile și fișierele atașate acelui loc. |

Pe ecranele doar de vizualizare — vizualizatorul de hărți și harta turei —
cele patru butoane de editare pur și simplu nu sunt acolo, rămânând
comutatorul de legendă și cele două scurtături. **Deschide locul** și
**Documente** salvează orice punct tocmai atins înainte de a naviga, așa că
nu puteți pierde o poziționare folosindu-le. Împreună fac din vizualizatorul
de hărți o cale practică de a parcurge o peșteră: găsiți pinul, citiți
locul, priviți fotografiile lui, reveniți.

## Legenda

| Marcaj | Semnificație |
|---|---|
| Punct albastru plin | **Curent** — locul la care lucrați, așa cum este salvat |
| Disc albastru cu centru portocaliu | **Nou** — punctul pe care tocmai l-ați atins, nesalvat încă |
| Inel albastru gol | **Original** — unde era punctul înainte să îl mutați |
| Punct roșu plin | **Existent** — orice alt loc din peșteră care are un punct pe această hartă |

Fiecare pin are numele locului alături, în afară de pinii estompați de
filtru.

## Moduri de atingere

Doar **Poziționare locuri pe hartă** are un comutator de mod de atingere, și
numai când a fost deschis pentru editare. Butonul stă în bara de acțiuni și
arată în ce mod sunteți:

- **Mod atingere: Definește punct nou** (o pictogramă de pin, albastră) —
  atingerea imaginii lasă un punct acolo unde ați atins.
- **Mod atingere: Selectează loc existent** (o pictogramă de mână,
  portocalie) — atingerea alege pinul cel mai apropiat, cu condiția să
  atingeți la aproximativ un vârf de deget de el. Atingerea hărții goale nu
  face nimic.

Modul în care pornește ecranul depinde de cum l-ați deschis: dintr-un loc
din peșteră pornește în modul *definire*, din lista de locuri a peșterii în
modul *selectare*.

Când schimbați modul, în colțul din stânga jos apare un scurt text —
*Apăsați pe hartă pentru a defini un punct nou sau schimbați modul de
interacțiune* / *Apăsați pe un alt punct pentru a îl selecta* — și dispare
după câteva secunde. Pictograma și culoarea butonului arată întotdeauna
modul curent.

> 📷 [Definirea unui punct pe o hartă raster](../screenshots/03-raster-maps.md#raster-map-define-point) — Amplasarea locurilor din peșteră pe o ridicare topografică scanată, cu editorul de puncte al hărții raster.

<a id="giving-a-place-a-position"></a>

## Poziționarea unui loc

1. Deschideți locul din peșteră și derulați până la secțiunea **Hărți**.
2. Alegeți o hartă din filele de sus; săgețile **◀ ▶** ajung la hărțile mai
   îndepărtate. Fiecare filă arată o previzualizare statică a acelei hărți.
3. Apăsați previzualizarea, sau butonul cu pin (**Definește locul pe
   hartă**) din colțul ei din stânga sus. Se deschide **Poziționare locuri
   pe hartă**.
4. Verificați că modul de atingere arată **Mod atingere: Definește punct
   nou**.
5. Atingeți harta acolo unde se află fizic locul. Acolo apare un disc
   albastru cu centru portocaliu, iar poziția anterioară, dacă există,
   rămâne vizibilă ca un inel albastru gol.
6. Punctul este salvat când părăsiți ecranul, sau imediat ce comutați la alt
   loc ori la altă hartă — vedeți [Salvarea punctelor](#storing-points).
   Odată salvat, este desenat ca orice alt punct amplasat: roșu pe hărțile
   unde nu este locul curent, albastru cât timp este.

Ca să parcurgeți o peșteră întreagă, rămâneți pe acest ecran și folosiți
**Următorul loc fără coordonate** din bara laterală după fiecare punct: vă
plimbă prin fiecare loc care încă nu are pin pe această hartă.

### Anularea unui punct tocmai atins

Apăsați **Resetează punctul la poziția inițială** (butonul ↶). Este
estompat până când chiar ați atins un punct nou, iar folosirea lui comută
și modul de atingere înapoi pe *selectează loc existent*, așa că o atingere
greșită nu mai poate muta punctul.

### Eliminarea unei poziționări

Apăsați coșul roșu, **Elimină definiția punctului**, și confirmați
*Eliminați definiția punctului pentru acest loc pe harta curentă?*

Aceasta șterge punctul **numai de pe harta la care vă uitați**. Locul din
peșteră în sine și punctele lui de pe alte hărți rămân neatinse. Nu există
anulare — ca să recuperați punctul trebuie să îl amplasați din nou.

<a id="storing-points"></a>

## Salvarea punctelor

Nu există buton de salvare. Un punct pe care l-ați atins este scris:

- când părăsiți ecranul, și
- imediat ce comutați la alt loc din peșteră sau la altă hartă.

Prima dată în fiecare sesiune când comutați având un punct nesalvat,
SpeleoLoc întreabă:

> *Salvați automat punctul curent când comutați la alt loc sau hartă?*

**Da** îl salvează și nu mai întreabă până reporniți aplicația.
**Anulează** renunță la comutare și lasă punctul în așteptare exact unde
este. O confirmare scurtă numește locul de fiecare dată când un punct este
salvat astfel.

## Adăugare loc peșteră

Pe **Poziționare locuri pe hartă**, butonul cu pin și plus vă lasă să
creați un loc și să îl poziționați dintr-o singură mișcare.

1. Apăsați **Adăugare loc peșteră**. Butonul devine verde și apare mesajul
   *Atingeți harta pentru a defini punctul pentru noul loc din peșteră*.
2. Atingeți harta acolo unde se află noul loc.
3. Completați dialogul scurt de adăugare a locului și confirmați. Locul este
   creat, iar punctul lui este salvat acolo unde ați atins.

Modul rămâne activ după aceea, așa că puteți merge de-a lungul unei galerii
adăugând loc după loc, fără să reveniți la buton. Apăsați din nou butonul
verde ca să îl opriți.

<a id="full-screen-and-landscape"></a>

## Ecran complet și mod peisaj

Butonul **Ecran complet** din bara laterală ascunde bara aplicației ca să
dea imaginii suprafață maximă; pe *Poziționare locuri pe hartă* ascunde și
ambele benzi. Bara de acțiuni rămâne. Apăsați butonul din nou (acum *Ieșire
ecran complet*) ca să reveniți.

Cât timp ecranul complet este pornit, butonul Înapoi al telefonului sau
gestul de întoarcere iese din ecranul complet în loc să părăsească ecranul,
așa că nu vă puteți pierde locul glisând înapoi. Apăsați-l din nou, odată ce
se vede aranjarea normală, ca să părăsiți harta.

Întoarcerea telefonului în **mod peisaj** pune harta pe ecran complet de la
sine, iar bara de acțiuni se mută de sub imagine pe o bandă verticală, pe
marginea ei din dreapta. Întoarcerea înapoi în mod portret restaurează
aranjarea normală — dacă nu cumva ați pornit ecranul complet chiar
dumneavoastră, caz în care rămâne pornit până îl opriți.

Modificările de vizibilitate a benzilor făcute în ecran complet se păstrează
când ieșiți din el.

> 📷 [O hartă raster în vizualizatorul pe ecran complet](../screenshots/03-raster-maps.md#raster-map-full-screen) — O hartă raster de peșteră deschisă pe ecran complet pentru inspecție prin pinch-zoom.

<a id="making-a-faint-scan-readable"></a>

## Cum faceți lizibilă o scanare palidă

Butonul **Procesare imagine** din bara laterală aplică efecte de afișare
imaginii hărții. Sunt pur vizuale: fișierul imagine salvat și punctele de pe
el nu sunt niciodată atinse.

| Alegere | Efect |
|---|---|
| **Normal (fără filtru)** | Imaginea așa cum este. |
| **Inversare culori** | Harta întunecată devine deschisă. Este și butonul separat din bara laterală. |
| **Tonuri de gri** | Elimină culoarea. |
| **Sepia** | Ton cald. |
| **Contrast ridicat** | Ridică contrastul — bun pentru linii palide de creion. |
| **Roșu noapte** | Lasă o tentă roșie, prietenoasă cu ochii adaptați la întuneric. |
| **Combinare efecte…** | Deschide panoul de mai jos. |

**Combinare efecte imagine** este un panou cu o casetă de bifat pentru
fiecare dintre cele cinci efecte — se cumulează — plus un glisor
**Luminozitate** (−1.00 până la +1.00) și un glisor **Contrast** (0.20 până
la 3.00). **Resetare** șterge tot, **Anulează** renunță la modificările
dumneavoastră, iar **Aplică** le pune pe hartă.

Efectul ales se reține pentru fiecare hartă raster cât timp aplicația
rulează și se uită când o închideți.

## Harta turei

O tură care are cel puțin o hartă raster disponibilă primește butonul
**Vedere hartă** în bara ei de instrumente (**Vedere listă** comută înapoi).
Ruta turei este desenată peste hartă ca marcaje numerotate, unite prin linii
albastre cu săgeți, în ordinea în care au fost vizitate locurile. Cât timp
harta este afișată apar încă trei butoane:

- **Redă traseul** — animează ruta de la primul loc vizitat la ultimul,
  aproximativ un pas pe secundă, desenând marcajele și liniile pe măsură ce
  înaintează. Butonul devine un buton roșu de oprire cât timp rulează.
- **Încadrează traseul** — mărește astfel încât toate locurile vizitate în
  tură să încapă pe ecran.
- **Exportă harta** — salvează ce vedeți, inclusiv ruta, ca PNG în stocarea
  proprie a aplicației; mesajul care urmează dă numele fișierului. Este o
  imagine de sine stătătoare. Exportarea unui **raport de tură** este o
  acțiune separată și nu preia această imagine — vedeți
  [Rapoarte de tură](trip-reports.md).

Harta turei este doar de vizualizare: punctele nu pot fi mutate sau adăugate
din ea.

## Când lipsește ceva

- **Un loc fără punct pe această hartă.** Alegerea lui din bandă, în
  vizualizatorul de hărți, arată *Nu există un punct nou definit pentru
  acest loc pe harta selectată*. Devine totuși locul curent, așa că pe
  *Poziționare locuri pe hartă* puteți atinge harta imediat ca să îi dați
  unul; în vizualizatorul de hărți, încercați altă hartă din bandă.
- **O hartă al cărei fișier imagine a dispărut**, de exemplu după
  restaurarea unei baze de date fără imagini. Miniatura ei din bandă devine
  o pictogramă de imagine ruptă, iar *Poziționare locuri pe hartă* arată
  *Imaginea nu a fost găsită*. Fiecare punct deja amplasat pe acea hartă se
  păstrează — mergeți la ecranul [Hărți](raster-maps.md) al peșterii și
  indicați din nou imaginea hărții.

## Vezi și

- [Hărți raster](raster-maps.md) — adăugarea, editarea, reordonarea și
  ștergerea hărților unei peșteri
- [Locuri din peșteră](cave-places.md)
- [Coduri QR — amplasare, scanare, printare](qr-codes.md)
- [Beaconuri BLE](ble-beacons.md)
- [Ture — înregistrarea traseului](trips.md)
- [Navigarea în subteran](../workflows/navigating-underground.md)
