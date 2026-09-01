# Navigarea în subteran

[← Înapoi la cuprins](../README.md)

Tura propriu-zisă: stați într-o galerie cu telefonul în mână, stabiliți
la ce loc sunteți, citiți ce știe deja echipa despre el și adăugați ce
găsiți. Tot ce este pe această pagină funcționează fără semnal —
hărțile topografice, documentele și codurile sunt toate pe dispozitiv.

> Numele controalelor de mai jos sunt cele din interfața în limba
> română. Dacă aplicația pornește în altă limbă, o comutați din
> **Setări → General → Limba aplicației**.

## Înainte de a coborî

- **Aduceți datele curente pe telefon.** Importați cea mai recentă
  arhivă a echipei sau rulați o sincronizare cât timp mai aveți rețea —
  vedeți [Partajarea datelor între echipe](sharing-data.md).
- **Acordați permisiunea pentru cameră la suprafață.** Prima scanare o
  cere, iar baza unui puț este un loc prost în care să descoperiți că
  ați refuzat-o cândva.
- **Porniți detectarea beaconurilor** dacă peștera are taguri BLE pe
  locurile ei — vedeți
  [Când vă găsește un beacon](#letting-a-beacon-find-you). Prima dată
  când o activați, își cere singură permisiunile.
- **Încărcați telefonul și luați un acumulator extern.** Ecranul,
  camera și lanterna împreună golesc repede bateria, iar frigul
  înrăutățește lucrurile.
- **Porniți tura înainte de a intra** sau lăsați eticheta intrării să o
  pornească pentru dumneavoastră — vedeți
  [Desfășurarea unei ture](running-a-trip.md).

## Două feluri de a ști unde sunteți

1. **Scanați eticheta QR** lipită lângă loc. Aceasta este varianta
   sigură: funcționează în orice peșteră care a fost etichetată, nu are
   nevoie de baterii pe perete și tot ea pornește și oprește turele.
2. **Treceți pe lângă beaconul BLE al locului.** Acolo unde un loc are
   un tag înregistrat, aplicația îl recunoaște singură și poate
   deschide locul fără să atingeți telefonul.

Ambele duc în același punct: locul din peșteră identificat și un punct
de tură înregistrat atunci când în peștera aceea rulează o tură.

## Scanarea unei etichete QR

| Unde sunteți | Butonul |
|---|---|
| Pagina principală | **Scanează QR**, primul buton din bara de acțiuni — sau în bara de sus atunci când bara de acțiuni este ascunsă |
| Lista de locuri a unei peșteri | **Scanează QR**, primul buton din bara de instrumente de sus |
| Oriunde, din meniul ⋮ | **Scanează** |

1. Apăsați-l. Se deschide o vedere simplă a camerei, intitulată
   **Scanează QR**.
2. Țineți eticheta în cadru. Detectarea este automată, iar scanerul se
   închide singur — nu există buton de declanșare.
3. Butonul **Lanternă** (flash) din bara de sus a scanerului aprinde
   lanterna telefonului, ceea ce de obicei face lizibilă o etichetă
   noroioasă sau cu contrast slab. Stingeți-o la loc după ce codul a
   fost citit.

Ce urmează depinde de ce s-a citit:

| Ce s-a citit | Ce se întâmplă |
|---|---|
| O etichetă care aparține unui singur loc din peșteră | Se deschide vizualizatorul de hărți pe prima hartă care are deja un punct pentru acel loc, centrat pe pin, iar un mesaj confirmă **Locul din peșteră a fost identificat**, cu titlul locului |
| Un loc care nu are punct pe nicio hartă | Mesajul *Acest loc din peșteră nu este definit pe nicio hartă.*, apoi pagina proprie a locului din peșteră |
| Un cod care există în mai multe peșteri | Un dialog **Alege punctul / peșteră** listează fiecare potrivire cu peștera ei, ca să îl alegeți pe cel bun |
| Un cod care nu este în nicio peșteră de pe acest dispozitiv | *Locul din peșteră nu a fost găsit*, citând codul care a fost citit |
| Orice nu poate fi redus la un identificator | *Cod QR invalid (nu poate fi interpretat conform regulilor)* |

O scanare pornită din lista de locuri a unei peșteri caută numai în acea
peșteră, așa că acolo nu apare niciodată dialogul de alegere. Pe ce
hartă ajungeți ține de ordinea hărților stabilită de dumneavoastră —
vedeți
[Vizualizatorul de hărți și editorul de puncte](../features/map-viewer.md#sorting-the-maps).

Scanarea unei etichete de **intrare** se comportă altfel: vă propune să
porniți o tură, să o opriți pe cea în curs sau să comutați de la o tură
din altă peșteră. Este calea cea mai rapidă de a desfășura o tură fără
să umblați prin meniuri și este descrisă în
[Coduri QR — amplasare, scanare, printare](../features/qr-codes.md) și
[Desfășurarea unei ture](running-a-trip.md).

Cât timp în acea peșteră rulează o tură, fiecare scanare obișnuită
adaugă discret un punct de tură și confirmă cu *Punct adăugat la tură*,
așa că traseul se construiește singur pe măsură ce înaintați. O tură
**pusă pe pauză** nu înregistrează nimic, deși același mesaj apare în
continuare — reluați-o înainte să vă bazați pe traseu.

### Când eticheta nu se lasă scanată

Etichetele se murdăresc, se rup și se udă, iar camera nu reușește
întotdeauna să focalizeze pe ele. Orice cod poate fi tastat în schimb:

1. Țineți apăsat butonul de scanare aproximativ două secunde și
   jumătate.
2. Se deschide **Căutare manuală cod QR**.
3. Tastați codul în **Mod de generare identificatori cod QR** și apăsați
   **Caută loc după id cod QR**.

De acolo, aplicația face exact ce ar fi făcut o scanare reușită.
Apăsarea lungă funcționează pe pagina principală și în lista de locuri
a unei peșteri; lista de locuri are în bara ei de instrumente și un
buton **Căutare manuală cod QR** care deschide aceeași casetă, mai la
îndemână atunci când lucrați cu mai multe coduri unul după altul.

Ce tastați este comparat, fără să conteze literele mari și mici, atât cu
identificatorul codului QR, cât și cu codul de loc lizibil de om, așa că
oricare dintre cele două care mai este descifrabil pe perete găsește locul.

<a id="letting-a-beacon-find-you"></a>

## Când vă găsește un beacon

Un loc din peșteră poate avea un tag BLE înregistrat pe el. Când
detectarea beaconurilor este pornită, intrarea în rază identifică locul
fără nicio scanare — util exact atunci când o etichetă a dispărut și în
galeriile unde este incomod să ajungeți cu telefonul la etichetă.

O porniți din **Setări → Detectare beaconuri → Detectează beaconurile
automat** sau cu comutatorul **Detectare beaconuri** din josul meniului
⋮, care este același comutator și poate fi acționat fără să părăsiți
ecranul pe care sunteți. Este oprită până când o porniți.

Intrarea în rază vă dă atunci:

- un mesaj care spune **Loc detectat**, urmat de titlul locului, și un
  sunet scurt, dacă **Sunet la detectare** nu este oprit;
- un punct de tură, atunci când în peștera acelui loc rulează o tură —
  același punct pe care l-ar fi înregistrat o scanare, cu *Punct
  adăugat la tură* adăugat la mesaj;
- locul deschis pe cea mai potrivită hartă raster, exact cum l-ar
  deschide o scanare, dar numai când **Deschide locul la detectare**
  este pornită. Este oprită implicit, ca trecerea pe lângă un tag să nu
  vă smulgă ecranul de sub ochi.

Două setări hotărăsc când un tag contează drept „aici”: **Prag de
declanșare a semnalului**, care ține detectarea la ultimii câțiva metri,
și **Pauză între redeclanșări**, care amuțește același beacon timp de
cinci minute după ce s-a declanșat, ca un popas să nu vă umple tura cu
repetări.

Câteva lucruri pe care beaconurile nu le fac în mod deliberat:

- **Nu pornesc și nu opresc niciodată o tură.** Chiar și un tag de
  intrare doar anunță locul; întrebările de pornire și oprire țin de
  eticheta QR, pentru că un dialog care apare în timp ce mergeți este
  mai rău decât inutil.
- **Nu întreabă nimic atunci când un tag este ambiguu.** Dacă același
  tag este înregistrat în mai multe peșteri, aplicația preferă în tăcere
  peștera în care vă este tura, apoi peștera pe care ați avut-o ultima
  dată deschisă.
- **Se opresc când aplicația nu este pe ecran**, dacă nu este pornită
  **Continuă detectarea în fundal** (Android). Cu ea pornită, o
  detectare ajunge ca o notificare sonoră în loc de mesaj, iar apăsarea
  acelei notificări deschide locul din peșteră.

Tagurile cu senzori Ruuvi înregistrate pe un loc declanșează detectarea
exact la fel ca un tag iBeacon. Vedeți
[Beaconuri BLE](../features/ble-beacons.md) pentru atribuirea tagurilor
la locuri și pentru verificarea că sunt în viață, și
[Taguri cu senzori Ruuvi](../features/ruuvi-sensors.md) pentru partea de
senzori.

## Citirea topografiei la lumina frontalei

Odată ce un loc este identificat, sunteți în vizualizatorul de hărți, cu
o topografie scanată în față și cu pinii peșterii pe ea.

- **Ciupiți** ecranul pentru zoom, **trageți** pentru deplasare;
  butoanele **−**, resetare și **+** din colțul din dreapta jos al
  imaginii fac același lucru în trepte.
- **Apăsați un pin** ca să faceți din acel loc locul curent — harta se
  deplasează pe el fără să vă schimbe zoomul. **Țineți apăsat un pin**
  ca să citiți numele locului căruia îi aparține, ceea ce vă salvează
  într-un colț unde etichetele se suprapun.
- Banda **Locuri din peșteră** de deasupra hărții listează fiecare loc
  din peșteră; apăsarea unuia mută la el, așa că puteți privi înainte,
  spre unde mergeți.
- **Deschide locul** și **Documente**, din bara de sub hartă, vă duc de
  la pin la pagina proprie a acelui loc sau direct la fotografiile și
  notele lui.

O topografie în creion, fotografiată la lumina frontalei, este adesea
abia lizibilă pe un telefon. Butonul **Procesare imagine** din bara
laterală rezolvă asta: **Inversare culori** pentru o scanare închisă,
**Contrast ridicat** pentru linii palide și **Roșu noapte** atunci când
ați prefera să nu vă pierdeți adaptarea la întuneric. Acestea sunt doar
de afișare — imaginea stocată și punctele de pe ea nu sunt atinse
niciodată. **Ecran complet** dă imaginii tot ecranul, iar rotirea
telefonului pe orizontală face același lucru de la sine.

Lista completă a efectelor și felul în care funcționează cele două se
află în pagina vizualizatorului de hărți: [cum faceți lizibilă o scanare
palidă](../features/map-viewer.md#making-a-faint-scan-readable) și
[ecran complet și mod
peisaj](../features/map-viewer.md#full-screen-and-landscape).

## Adăugarea, pe loc, a ceea ce găsiți

Din secțiunea **Documente** a unui loc din peșteră puteți înregistra
observația chiar în timp ce stați în fața lui. Bara de instrumente
oferă, în ordine:

| Butonul | Ce obțineți |
|---|---|
| **Document text nou** | O notă simplă |
| **Text formatat nou** | O notă formatată |
| **Fă o fotografie** | Camera, cu poza atașată dacă o păstrați |
| **Înregistrare audio** | O înregistrare vocală — cea mai rapidă opțiune cu mâinile reci |
| **Adaugă din fișier** | Orice se află deja pe telefon, mai multe fișiere odată |

Fiecare este atașat acelui loc din peșteră imediat ce este salvat, este
preluat de următorul export sau de următoarea sincronizare și — dacă
rulează o tură care nu este pe pauză — este legat și de acea tură, așa
că apare mai târziu în raportul turei. Vedeți
[Documente](../features/documents.md).

## Când nu sunteți sigur la ce loc vă aflați

- Dacă locul are un **tag BLE** și detectarea este pornită, apropiați-vă
  de el și lăsați aplicația să vă spună.
- Dacă puteți citi orice parte din cod, folosiți **Căutare manuală cod
  QR**.
- În lista de locuri a peșterii, folosiți caseta **Filtrare locuri
  peșteră**: ce tastați este comparat cu numele locului, cu codul lui de
  loc și cu numele zonei de peșteră din care face parte.
- Pe o hartă, apăsați pinul cel mai apropiat de locul unde credeți că
  sunteți sau țineți-l apăsat ca să îi citiți numele înainte să vă
  hotărâți.
- Dacă nimic din toate acestea nu merge, notați acum adâncimea și o
  descriere și lămuriți la suprafață ce loc era — o fotografie
  neatașată, cu o notă, valorează mult mai mult decât o presupunere
  pusă pe locul greșit.

## La întoarcerea la suprafață

1. **Opriți tura** dacă ați pornit una, la intrare sau la suprafață.
   Vedeți [Desfășurarea unei ture](running-a-trip.md).
2. **Opriți detectarea beaconurilor** dacă ați avut-o pornită — scanează
   continuu și nu mai are ce găsi deasupra pământului.
3. **Recitiți ce ați adăugat** din peșteră sau de la locurile pe care
   le-ați vizitat, cât timp tura este proaspătă, și corectați atunci
   titlurile și descrierile, nu peste o lună.
4. **Exportați sau sincronizați**, ca restul echipei să primească ce ați
   adus înapoi — vedeți
   [Partajarea datelor între echipe](sharing-data.md).

## Vezi și

- [Coduri QR — amplasare, scanare, printare](../features/qr-codes.md)
- [Beaconuri BLE](../features/ble-beacons.md)
- [Vizualizatorul de hărți și editorul de puncte](../features/map-viewer.md)
- [Locuri din peșteră](../features/cave-places.md)
- [Desfășurarea unei ture](running-a-trip.md)
- [Partajarea datelor între echipe](sharing-data.md)
