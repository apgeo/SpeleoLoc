# Taguri cu senzori Ruuvi

[← Înapoi la cuprins](../README.md)

Un tag Ruuvi este un mic senzor Bluetooth alimentat cu baterie, care
difuzează continuu ce măsoară — temperatură, umiditate, presiune
atmosferică și propria tensiune a bateriei — către orice se află în raza
radio. SpeleoLoc poate folosi unul ca reper pentru un loc din peșteră,
exact ca pe un iBeacon, iar pe deasupra vă arată citirile lui: în timp
real, cât stați lângă el, și ulterior din jurnalul de măsurători pe care
tagul îl ține singur.

Denumirile controalelor de pe această pagină sunt cele din aplicația în
română. Aplicația pornește în română; engleza se alege din **Setări →
General → Limba aplicației**.

## Ce măsoară un tag Ruuvi

Nimic nu trebuie împerecheat, pornit sau conectat pentru ca citirile să
apară: tagul își strigă valorile în aer la fiecare una-două secunde, iar
telefonul trebuie doar să fie destul de aproape ca să le audă. O
conexiune se face într-o singură situație — la descărcarea jurnalului
stocat în tag.

| Citire | Afișată ca | Ce este |
|---|---|---|
| **Temperatură** | `12.34 °C` | temperatura aerului la tag |
| **Umiditate** | `96.5 %` | umiditate relativă |
| **Presiune** | `1013.2 hPa` | presiune atmosferică absolută |
| **Baterie** | `2980 mV` | tensiunea celulei; sub 2500 mV este considerată scăzută |
| **Număr mișcări** | un număr | de câte ori a fost deranjat tagul; se reia de la zero după 254 |
| **Accelerație** | `(4, -12, 1010) mG` | cele trei axe: cum stă orientat tagul |
| **Semnal** | `RSSI: -67 dBm` | cât de puternic aude telefonul tagul acum |
| **Putere TX** | `4 dBm` | cât de tare emite tagul |

### Ce model aveți

Aplicația nu întreabă niciodată. Deduce modelul din senzorii care chiar
raportează o valoare și afișează numele dedus — **RuuviTag**, **RuuviTag
Pro 3in1** sau **RuuviTag Pro 2in1**. Citirile pe care modelul nu le
poate face apar ca o liniuță (`—`), nu ca zero, așa că o liniuță la
*Presiune* pe un Pro 3-in-1, sau la *Umiditate* și *Presiune* pe un Pro
2-in-1, înseamnă senzor absent — nu o defecțiune și nu un pachet pierdut.

## Asocierea unui tag cu un loc din peșteră

Un tag trebuie asociat unui loc înainte de a putea ajunge la oricare
dintre ecranele cu senzori; nu există o citire de sine stătătoare, de
tipul „caută taguri”, în afara [Laboratorului beacon](#diagnostics-in-beacon-lab).

1. Deschideți locul din peșteră și salvați-l dacă este nou — secțiunea
   **Beaconuri BLE** apare abia după ce locul există.
2. În acea secțiune apăsați **Asociază beacon**.
3. Se deschide dialogul **Beaconuri în apropiere** și începe să asculte.
   Țineți telefonul lipit de tagul pe care îl instalați: lista este
   sortată cu semnalul cel mai puternic primul, iar ce nu mai este auzit
   timp de 15 secunde dispare din ea, așa că tagul din mână urcă în vârf
   și rămâne acolo.
4. Fiecare intrare Ruuvi arată modelul, adresa MAC, semnalul în dBm și
   temperatura, umiditatea, presiunea și bateria curente — destul cât să
   fiți sigur că alegeți tagul dumneavoastră și nu unul vecin. Tagurile
   deja înregistrate în această peșteră sunt estompate și marcate *deja
   asociat*.
5. Apăsați tagul. Aplicația confirmă cu **Beacon asociat acestui loc**.

De atunci tagul are două roluri: identifică locul când treceți pe lângă
el, dacă detectarea automată este pornită (vedeți
[Beaconuri BLE](ble-beacons.md)), și dă acelui loc o citire de senzor în
timp real și un istoric.

> **Doar Android:** scanările Bluetooth nu returnează absolut nimic cât
> timp comutatorul de localizare al telefonului este oprit, deși nu se
> preia niciodată vreo poziție GPS. Când este oprit, aplicația afișează
> dialogul **Activează localizarea**, cu butonul **Deschide setări**;
> activați localizarea acolo și încercați din nou. Dacă lipsesc
> *permisiunile* Bluetooth sau de localizare, primiți în schimb
> **Permisiunile Bluetooth/localizare sunt necesare pentru scanarea
> beaconurilor**.

## Date senzor în timp real

Două căi de acces, ambele pentru un tag deja asociat unui loc:

- lista locurilor din peșteră → butonul **Peșteră** din bara de
  instrumente → **Beaconurile peșterii**, apoi butonul de monitorizare de
  pe rândul tagului, cu indiciul **Date senzor în timp real**;
- locul din peșteră însuși → secțiunea **Beaconuri BLE** → apăsați rândul
  tagului.

Până la sosirea primei transmisii, ecranul spune **Se așteaptă transmisii
de la tag… apropie-te de tag**. După aceea se completează, iar fiecare
transmisie nouă îl reîmprospătează:

- un rând de antet cu modelul dedus și adresa MAC a tagului, iar sub el
  **Actualizat acum 2s** — un contor care continuă să crească atunci când
  nu sosește nimic, cel mai rapid mod de a vedea că ați ieșit din rază;
- patru carduri mari: **Temperatură**, **Umiditate**, **Presiune**,
  **Baterie**. Cardul bateriei capătă o pictogramă portocalie de
  avertizare sub 2500 mV;
- un panou **Mișcare**, cu **Număr mișcări** și **Accelerație**;
- un panou **Semnal**, cu RSSI, **Putere TX** și **Pachete pierdute**.

Bara de titlu a ecranului arată locul căruia îi este asociat tagul (sau
modelul, când ați venit din ecranul locului), nu cuvintele *Date senzor
în timp real*.

### Cum folosiți cifra pachetelor pierdute

**Pachete pierdute: 12 % (44/50)** înseamnă că, din cele 50 de transmisii
pe care tagul le-a numerotat cât timp ați privit, 44 au ajuns la telefon.
Aplicația o calculează din golurile din numerotarea proprie a tagului,
deci este o estimare a traseului radio dintre acel tag și acel telefon,
în acel punct, chiar acum.

Acesta este modul practic de a decide unde va funcționa cu adevărat un
tag. Parcurgeți galeria cu vizualizarea în timp real deschisă și urmăriți
RSSI și cifra pierderilor. Dacă pierderile sunt mari acolo unde vă
așteptați ca aplicația să recunoască locul automat, tagul are nevoie de o
poziție mai bună — sau pragul de declanșare din **Setări → Detectare
beaconuri** trebuie relaxat.

## Jurnalul de măsurători al tagului

Un tag Ruuvi înregistrează singur temperatura, umiditatea și presiunea
cât timp nu este nimeni acolo, cam la fiecare cinci minute, păstrând
aproximativ zece zile înainte să le suprascrie pe cele mai vechi.
SpeleoLoc poate aduce acel jurnal pe telefon. Deschideți vizualizarea în
timp real a tagului și apăsați pictograma de istoric din bara de titlu
(**Istoric senzor**).

### Descărcarea

1. Stați lângă tag, cu Bluetooth pornit.
2. Apăsați pictograma de descărcare, **Descarcă din tag**.
3. O bară de progres raportează etapele: **Se caută tagul…**, **Se
   conectează…**, **Se descarcă… 300 mostre** (numărul avansează din sută
   în sută), apoi **Se salvează…**.
4. Se încheie cu **Istoric descărcat: 412 citiri noi**.

Rămâneți lângă tag pe toată durata transferului — aceasta este singura
parte a funcției care are nevoie de o conexiune Bluetooth reală și rulează
doar cât timp ecranul este deschis. Aplicația renunță și afișează o eroare
dacă tagul nu este auzit în circa 30 de secunde, dacă legătura nu se
stabilește în 15 secunde sau dacă fluxul amuțește 30 de secunde la mijloc.
Apropiați-vă și porniți din nou; nu se pierde nimic.

O nouă descărcare, mai târziu, cere tagului doar ce este mai nou decât cea
mai recentă citire stocată, așa că a doua descărcare după o tură este
scurtă, iar repetarea uneia nu produce niciodată rânduri duplicate.

### Cum se citesc graficul și lista

Citirile sunt desenate ca grafic cu linie. Butoanele de sus aleg mărimea
— **°C**, **%RH**, **hPa** — iar rândul de sub ele limitează vizualizarea
la **24 h**, **7 z** sau **Tot**; ecranul se deschide pe temperatură, pe
ultimele 24 de ore. Apăsați un punct de pe linie ca să-i citiți data, ora
și valoarea exactă. Pictograma din dreapta comută între grafic și o simplă
**Listă** de citiri, cea mai nouă prima, fiecare rând arătând marca de
timp și fiecare valoare stocată pentru ea. Orele, în ambele, sunt ora
locală a telefonului.

Alegerea unei mărimi pe care tagul nu a înregistrat-o niciodată —
presiunea pe un Pro 3-in-1, de pildă — dă **Nicio valoare pentru această
mărime**. Aceasta este hardware-ul tagului, nu o descărcare eșuată.

### Când totul pare gol

Mărcile de timp din jurnal vin de la ceasul propriu al tagului, iar
SpeleoLoc nu potrivește niciodată acel ceas. Un tag al cărui ceas nu a
fost sincronizat niciodată își marchează citirile cu date mult în trecut,
așa că filtrele **24 h** și **7 z** par goale, deși descărcarea a reușit.
Ecranul o spune: **Nicio citire în acest interval — 2874 stocate în total,
selectează „Tot”**. Treceți pe **Tot** și citirile sunt acolo.
Măsurătorile în sine sunt bune; doar datele lor sunt greșite și vor rămâne
greșite pentru acele rânduri.

### Exportă CSV

Pictograma de salvare scrie tot ce este stocat pentru acest tag prin
selectorul de fișiere al sistemului, ca fișier numit de forma
`ruuvi_E1A24C90F3B7_2026-09-01T14-05-11.csv`. Are patru coloane —
`timestamp_utc` (în UTC, nu ora locală), `temperature_c`, `humidity_pct`
și `pressure_hpa` — gata pentru un tabel de calcul. Exportă întotdeauna
tot setul stocat, nu intervalul de pe ecran, și confirmă cu **Istoric
exportat (2874 rânduri)**. Dacă nu este nimic stocat încă, refuză:
**Niciun istoric stocat încă — descarcă din tag**.

Aceasta este singura cale de a scoate citirile de senzor de pe telefon.
Vedeți [Limite de știut](#limits-worth-knowing).

### Șterge istoricul stocat

Pictograma coș, **Șterge istoricul stocat**, șterge fiecare citire stocată
pe acest telefon pentru acest tag, după ce întreabă **Ștergi tot istoricul
stocat local pentru acest tag? Tagul își păstrează ultimele ~10 zile.**

**Operația nu poate fi anulată** și nu există nicio copie în altă parte,
așa că exportați întâi CSV-ul dacă citirile contează. Ce nu atinge este
tagul: jurnalul lui rămâne neatins, iar o descărcare nouă aduce înapoi ce
mai este în el. Ștergerea este mișcarea potrivită când un tag a fost mutat
în alt loc, iar citirile vechi ar induce în eroare.

## Ce înregistrează aplicația de la sine

Cât timp detectarea automată a beaconurilor rulează, aplicația notează
discret valorile pe care le difuzează fiecare tag Ruuvi înregistrat pe
lângă care treceți — cel mult o dată pe minut per tag — fără să deschideți
nimic. Acestea se înscriu pe înregistrarea tagului, oriunde ar fi el
înregistrat.

Lista locurilor din peșteră → **Peșteră** → **Beaconurile peșterii** arată
rezultatul: un rând pentru fiecare tag înregistrat în peșteră, cu locul,
modelul, adresa MAC, ora **Văzut ultima dată**, bateria în mV și ultimele
valori de temperatură, umiditate și presiune. Un tag sub 2500 mV primește
o pictogramă portocalie de baterie, cu indiciul **Baterie slabă**. O
privire aruncată peste lista aceea înainte de o tură este modul în care
aflați ce taguri au nevoie de baterii noi înainte să amuțească sub pământ.
Versiunea de firmware a tagului apare și ea acolo (`fw …`) după ce i-ați
descărcat istoricul măcar o dată — atunci o citește aplicația.

Numărul de mișcări este și el înregistrat, dar singurele locuri unde este
arătat sunt vizualizarea în timp real și Laboratorul beacon.

Titlurile, pozele și descrierile tagurilor sunt comune cu iBeacon-urile și
stau la **Setări → Detectare beaconuri → Administrare tag-uri**; vedeți
[Beaconuri BLE](ble-beacons.md).

<a id="diagnostics-in-beacon-lab"></a>

### Diagnostic în Laboratorul beacon

**Setări → Detectare beaconuri → Laborator beacon**, fila **Scanare
brută**, apoi **Pornește scanarea**, listează dispozitivele de tip beacon
aflate în rază — dezactivați **Afișează doar dispozitivele de tip beacon**
ca să le vedeți pe toate — și decodează pe cele Ruuvi: model, baterie,
cele trei citiri, accelerație, putere TX, contorul de mișcări și numărul
de secvență al transmisiei. Funcționează pe orice tag aflat în rază,
asociat sau nu, ceea ce îl face unealta potrivită pentru a verifica un tag
direct din pachetul lui sau unul pe care nu îl puteți identifica.

## Cât valorează citirile sub pământ

- **Temperatura și umiditatea aerului în puncte fixe.** Un tag lăsat la o
  intrare, într-o strâmtoare și într-o sală vă dă profilul pe zece zile,
  nu pe o clipă, iar forma curbei de temperatură este cea care arată o
  galerie care respiră.
- **Presiunea.** Utilă mai ales ca context pentru celelalte două și ca
  înregistrare a vremii de afară în perioada cât ați lipsit.
- **A fost atins reperul?** Un număr de mișcări mai mare decât ultima dată
  când ați privit înseamnă că tagul a fost lovit sau manevrat, ceea ce
  merită știut înainte să vă bazați pe el ca reper de poziție.
- **Până unde ajunge de fapt un tag.** Cifra pierderilor de pachete în
  timp real, purtată de-a lungul galeriei, este răspunsul cinstit.
- **Bateria înainte de o tură.** Mai ieftin de verificat la suprafață.

Aplicația înregistrează și desenează; nu interpretează. Nu există praguri,
alarme sau tendințe dincolo de semnalarea bateriei slabe.

<a id="limits-worth-knowing"></a>

## Limite de știut

- **Istoricul descărcat rămâne pe telefonul care l-a descărcat.** Nu este
  în arhivele de export, nu este într-un import prin îmbinare și nu este
  în sincronizarea FTP, așa că un coechipier care vă importă arhiva nu
  primește nicio citire. Trimiteți-i CSV-ul.
- Istoricul aparține tagului fizic, legat de adresa lui MAC, nu locului.
  Supraviețuiește dezasocierii tagului, reasocierii lui la alt loc și
  mutării în altă peșteră — iar două locuri care au avut același tag împart
  o singură grămadă de citiri.
- Aplicația nu potrivește niciodată ceasul tagului și nu schimbă cât de des
  înregistrează. Ambele rămân cum le-a lăsat aplicația proprie Ruuvi.
- Descărcarea cere să fiți lângă tag, cu ecranul deschis. Nu poate rula în
  fundal și nu poate recupera mai târziu.
- Pierderea de pachete este o estimare din numerotarea transmisiilor, nu o
  calitate măsurată a legăturii.
- Numele modelului este dedus din senzorii care răspund, așa că un tag cu
  un senzor defect va fi numit ca un model mai mic.

## Vezi și

- [Beaconuri BLE](ble-beacons.md)
- [Locuri din peșteră](cave-places.md)
- [Navigarea sub pământ](../workflows/navigating-underground.md)
- [Setări](settings.md)
- [Export, import și copie de siguranță a bazei de date](database-export-import.md)
- [Glosar de termeni](../glossary.md)
