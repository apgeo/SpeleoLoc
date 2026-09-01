# Ture

[← Înapoi la cuprins](../README.md)

O **tură** înregistrează o singură ieșire în subteran, într-o singură
peșteră: când a început și când s-a încheiat, o listă ordonată de
**puncte de tură** (locurile la care ați ajuns), un **jurnal de tură**
generat automat și documentele făcute cât timp a rulat.

Turele sunt opționale — puteți folosi SpeleoLoc doar pentru navigare și
documentare, fără să porniți vreodată una. Dar dintr-o tură se
generează un [raport de tură](trip-reports.md).

## Ciclul de viață

```
  Start → (Pause ↔ Resume)* → Stop → (Restart → … → Stop)*
```

- **Începe tura** creează tura, îi marchează ora de început și o face
  singura **tură activă** de pe acest dispozitiv.
- **Pauză** oprește înregistrarea fără să încheie tura.
- **Continuă** reia înregistrarea.
- **Oprește** marchează ora de final și nu lasă nicio tură activă, așa
  că nu se mai înregistrează nimic.
- **Repornește** ia o tură încheiată și o face din nou tura activă.

Pe un dispozitiv poate fi activă **o singură tură** la un moment dat,
indiferent de peșteră. Cât timp rulează o tură în peștera A nu puteți
începe una în peștera B — trebuie mai întâi să o opriți pe prima.

O tură oprită **nu** este blocată. O puteți în continuare redenumi, îi
puteți edita jurnalul, exporta un raport, șterge sau reporni.

## Începerea unei ture

Există trei căi:

- Din lista de locuri a unei peșteri: **⋮ → Începe tura**. Acest
  element apare doar când nu rulează nicio tură, nici în această
  peșteră, nici în alta. După ce confirmați, aplicația deschide ecranul
  **Ture trecute / active** al peșterii.
- Din ecranul **Ture trecute / active** al peșterii: butonul verde
  **Începe tura**.
- Prin scanarea codului QR al unui loc marcat ca intrare în peșteră:
  aplicația întreabă *„Ai scanat o intrare în peșteră. Vrei să începi o
  tură nouă?”*.

Toate trei deschid dialogul **Începe o tură nouă**, cu **Titlul turei**
deja completat: numele peșterii urmat de data de azi, de exemplu
`Grotte de X 2026/04/22`. Dacă o tură din acea peșteră poartă deja exact
același titlu, aplicația adaugă un contor — ` [2]`, ` [3]` și așa mai
departe — astfel încât două ture din aceeași zi să nu se ciocnească
niciodată. Modificați titlul înainte de a confirma dacă vreți ceva mai
descriptiv; dacă goliți câmpul, rămâne sugestia.

## Punctele turei

Cât timp tura rulează, punctele se înregistrează singure. Nu există
niciun buton care să adauge unul manual.

- **Scanarea unui cod QR** al unui loc care aparține peșterii turei
  adaugă un punct de tură (locul + ora curentă) și confirmă cu *„Punct
  adăugat la tură”*. Scanarea unui loc dintr-o **altă** peșteră nu
  înregistrează nimic — locul se deschide totuși ca de obicei.
- **Un beacon BLE detectat** adaugă un punct de tură după aceeași
  regulă a aceleiași peșteri, fără nicio scanare: mesajul spune *„Loc
  detectat: «loc» · Punct adăugat la tură”*, iar când aplicația este în
  fundal notificarea arată dacă a fost înregistrat un punct. Aceasta
  este calea de a construi un traseu fără să folosiți mâinile — vedeți
  [Beaconuri BLE](ble-beacons.md).
- **Locurile de intrare se comportă diferit la scanare.** Dacă tura
  care rulează este pentru aceeași peșteră, aplicația întreabă *„Ai
  scanat o intrare în peșteră. Ieși din peșteră? Oprești tura activă?”*.
  Răspundeți **Da** și tura se oprește; răspundeți **Nu** și intrarea
  este înregistrată ca punct de tură obișnuit. Dacă tura care rulează
  aparține altei peșteri, aplicația numește acea peșteră, se oferă să îi
  oprească tura și apoi se oferă să înceapă una aici.

Punctele sunt ordonate după ora la care au fost înregistrate. Același
loc poate fi înregistrat de mai multe ori într-o tură — fiecare scanare
sau detectare este un punct separat.

> Atenție: cât timp tura este **în pauză** mesajul de confirmare apare
> în continuare, dar nu se salvează niciun punct.

## Ecranul turei

Deschideți o tură din cardul turei aflat în meniul lateral **⋮**, sau
apăsând-o în ecranul **Ture trecute / active** al peșterii. Ecranul are
sus un rând de butoane de acțiune și se deschide în vedere listă. Pe un
telefon ținut orizontal butoanele se reduc doar la pictograme — apăsați
lung pe una ca să îi vedeți numele — iar rândul se derulează lateral
când butoanele nu încap toate.

### Cardul rezumat și lista punctelor

Cardul de sus arată peștera, **Început**, **Terminat** (după ce tura
s-a încheiat), **Durată** și **Puncte**, plus o etichetă verde **Tură
activă** sau portocalie **Tură în pauză** cât timp tura este în
desfășurare.

Sub el, fiecare punct este listat în ordinea vizitării, cu un număr care
corespunde numărului de pe hartă, ora la care a fost înregistrat și, în
dreapta, adâncimea locului în peșteră atunci când se cunoaște. Apăsați
un rând ca să deschideți acel loc din peșteră. Înainte de primul punct,
lista arată *„Niciun punct înregistrat”*.

### Vederea hartă

Dacă peștera are cel puțin o hartă raster, rândul de butoane oferă și
**Vedere hartă** (și **Vedere listă** pentru întoarcere). În vederea
hartă apar încă trei butoane: **Redă traseul**, **Încadrează traseul**
și **Exportă harta**.

Traseul este desenat pe harta selectată în acel moment în banda
hărților de deasupra imaginii:

- un **cerc albastru numerotat** la fiecare punct, în ordinea
  vizitării, cu o săgeată de direcție pe fiecare linie de legătură;
- punctele al căror loc nu are pin pe harta **selectată** sunt omise —
  atât numărul, cât și segmentul de linie — așa că schimbați harta dacă
  o parte din traseu pare să lipsească;
- când același loc a fost vizitat de mai multe ori, numerele lui se
  desfac în evantai în jurul pinului, în loc să se acopere unele pe
  altele.

**Redă traseul** dezvăluie punctele unul câte unul, cam 0,8 s fiecare;
apăsați-l din nou (devine un stop roșu) ca să săriți la traseul
complet. **Încadrează traseul** mărește și deplasează harta astfel încât
tot traseul să încapă pe ecran. **Exportă harta** salvează un PNG al
vederii curente în folderul de documente al aplicației și arată calea
completă în mesajul de confirmare.

Harta de aici este doar pentru citit: apăsarea unui loc din banda
locurilor doar îl evidențiază și centrează harta pe el. Nu înregistrează
niciodată un punct și nu puteți muta pinii locurilor din acest ecran.

### Meniul ⋮

| Element | Ce face |
|---|---|
| **Filtrare locuri peșteră** | Filtrează banda de locuri de deasupra hărții. |
| **Sortare locuri peșteră** | Schimbă ordinea acelei benzi. |
| **Sortare hărți** | Reordonează miniaturile hărților raster. |
| **Administrare hărți** | Deschide ecranul de [hărți raster](raster-maps.md) al peșterii, ca să puteți adăuga sau corecta o hartă fără să părăsiți tura. |
| **Redenumește tura** | Vedeți mai jos. |
| **Șterge tura** | Vedeți mai jos. |

## Urmărirea unei ture în desfășurare de oriunde

Cât timp o tură rulează, în partea de jos a meniului lateral **⋮** stă
un card, pe fiecare ecran care are un asemenea meniu — verde cât timp
înregistrează, portocaliu cât timp este în pauză. Arată titlul turei,
peștera, de cât timp sunteți în subteran, numărul total de puncte și
ultimele cinci puncte, cu ora la care a fost înregistrat fiecare.
Apăsarea cardului deschide tura.

În partea de jos a cardului stau trei butoane:

- **Vezi tura** — deschide ecranul turei.
- **Pauză** / **Continuă** — comută înregistrarea.
- **Oprește** (roșu) — oprește tura **imediat, fără confirmarea
  obișnuită**. Folosiți-l cu grijă.

Cardul este cea mai rapidă cale de întoarcere la o tură în desfășurare
și singura cale de a ajunge la prima tură a unei peșteri înainte ca ea
să fi fost oprită vreodată.

## Pauză și continuare

**Pauză** oprește înregistrarea: scanările QR și detectările de
beaconuri nu mai adaugă puncte, iar documentele pe care le creați nu mai
sunt legate de tură. **Continuă** repornește înregistrarea. Pauza și
continuarea se află în ecranul turei, în ecranul **Ture trecute /
active** al peșterii și pe cardul turei din meniul ⋮.

Două lucruri merită știute înainte să vă bazați pe ea:

- **Pauza nu lasă nicio urmă în jurnalul turei.** Nimic din
  înregistrarea finală nu arată unde au fost întreruperile.
- **Pauza se uită dacă aplicația este închisă.** Tura activă în sine
  supraviețuiește închiderii aplicației, opririi ei forțate sau
  repornirii telefonului, dar starea de pauză nu — tura revine
  înregistrând. După o repornire, verificați culoarea cardului turei din
  meniul ⋮: verde înseamnă că înregistrează din nou.

## Jurnalul turei

Jurnalul turei este scris **de aplicație**, nu de dumneavoastră.
Transformă în text evenimentele înregistrate — tura a început, fiecare
punct atins, fiecare document adăugat, repornirea, încheierea.
Deschideți-l cu butonul **Jurnal** din ecranul turei.

### Stiluri de jurnal

Pictograma cu carte din bara de sus a ecranului de jurnal alege
**Metoda de generare a jurnalului**. Alegerea este reținută la nivelul
întregii aplicații și se aplică fiecărei ture de atunci încolo; implicit
este **Clasic**.

| Stil | Cum arată un punct |
|---|---|
| **Brut (marcaje de timp + mesaje scurte)** | `[2026/04/22 10:14:03] Punct: „Sala Mare”` |
| **Clasic (propoziții complete)** — implicit | `[2026/04/22 10:14:03] S-a ajuns la „Sala Mare”.` |
| **Jurnal de teren (timp scurs + secvență)** | `[10:14 · +1h12min] S-a continuat spre „Sala Mare”.` |
| **Narativ (paragrafe)** | paragrafe de proză care grupează deplasările consecutive, de ex. *„După 1 h 12 min, echipa a ajuns la Sala Mare”* |

Alegerea altui stil întreabă **Regenerăm jurnalul turei?** și
avertizează că *„Modificările manuale vor fi pierdute.”* — tot jurnalul
este reconstruit din evenimentele înregistrate.

### Editarea jurnalului

Puteți scrie în jurnal și apăsa pictograma de salvare, și acolo își au
locul notele narative: vremea, componența echipei, observațiile care nu
țin de un anume loc, concluziile. Dar textul aparține aplicației, așa că
tratați-vă notele ca pe ceva fragil:

- **Repornirea** turei sau **schimbarea stilului de jurnal**
  reconstruiește tot jurnalul din evenimentele înregistrate; textul
  scris de dumneavoastră dispare.
- În stilurile **Brut**, **Clasic** și **Jurnal de teren** un eveniment
  nou este doar adăugat la sfârșit, așa că modificările anterioare îi
  supraviețuiesc. În stilul **Narativ** fiecare punct sau document nou
  rescrie tot jurnalul.

Adăugați astfel de note la sfârșitul turei și păstrați o copie în altă
parte dacă sunt importante.

O tură cu jurnal gol nu poate fi exportată ca raport: **Export raport**
răspunde *„Nu există jurnal de excursie de exportat”*.

## Documente create în timpul unei ture

Documentele făcute cu editoarele proprii ale aplicației — captură cu
camera, editorul de imagini și schițe, notele text și text formatat,
înregistrările audio — sunt legate automat de tura în desfășurare, pe
lângă peștera sau locul din peșteră căruia îi aparțin, iar în jurnalul
turei apare câte o linie despre fiecare.

Documentele adăugate prin atașarea unui fișier existent în formularul de
document sau prin import în masă nu sunt legate, iar cât timp tura este
în pauză nu se leagă nimic. Nu există nicio cale de a lega sau dezlega
manual un document, iar ecranele turei nu listează documentele legate —
vedeți [Documente](documents.md) pentru răsfoirea lor.

## Ture trecute și active

Odată ce o peșteră are cel puțin o tură **încheiată**, sub antetul
peșterii din lista ei de locuri apare un buton **Ture trecute / active
(N)**. Acesta deschide un ecran cu:

- un rând de butoane: **Începe tura** când nu rulează nimic, altfel
  **Oprește**, **Pauză** / **Continuă** și **Vezi tura**;
- un card evidențiat pentru tura care rulează în acel moment, dacă
  există;
- turele încheiate ale peșterii, cele mai noi primele, cu data și ora de
  început și numărul de puncte. Apăsați una ca să o deschideți.

Butoanele și cardul acționează asupra turei care rulează, chiar și
atunci când acea tură aparține **altei** peșteri — de aceea butonul
**Începe tura** dispare cât timp orice tură este activă. Când peștera nu
are încă ture încheiate și nu rulează nimic, lista arată *„Nicio tură
trecută”*.

**Export raport** și **Șterge tura** nu se află aici; ele stau chiar în
ecranul turei.

## Redenumirea unei ture

Deschideți tura și alegeți **⋮ → Redenumește tura**, modificați titlul
și confirmați. Funcționează fie că tura rulează, fie că s-a încheiat, și
nu schimbă nimic altceva — deși prima linie a jurnalului continuă să
citeze titlul vechi până când jurnalul este regenerat.

## Oprirea unei ture

Apăsați butonul roșu **Oprește**: în ecranul turei, în ecranul **Ture
trecute / active** al peșterii sau pe cardul turei din meniul ⋮.
Primele două întreabă *„Oprești înregistrarea acestei ture?”*; butonul
de pe card oprește imediat, fără confirmare. Scanarea codului QR al unei
intrări din peștera turei se oferă și ea să o oprească.

Oprirea înregistrează ora de final și nu mai lasă nicio tură activă.
Toate datele turei sunt păstrate.

## Repornirea unei ture încheiate

Când deschideți o tură care s-a încheiat deja, butonul **Oprește** este
înlocuit de un buton albastru **Repornește**. Apăsarea lui face din nou
acea tură tura activă, așa că scanările și detectările de beaconuri noi
continuă să se adauge aceluiași traseu, în loc să înceapă o tură nouă.
Folosiți-l când ați oprit o tură din greșeală sau când coborâți din nou
în subteran în aceeași zi și vreți o singură înregistrare continuă.

Două consecințe:

- Repornirea **readuce ora de început a turei la momentul repornirii**,
  așa că ora **Început** și **Durată** din ecranul turei se numără de
  acum de la repornire, nu de la coborârea inițială.
- Jurnalul este reconstruit în același timp. Păstrează punctele
  anterioare și primește o intrare „tură repornită” între cele două
  reprize, dar tot ce ați scris manual în el se pierde.

## Ștergerea unei ture

**⋮ → Șterge tura** din ecranul turei întreabă *„Șterge această tură și
toate punctele ei?”*. Dacă tura este cea care rulează în acel moment, ea
este mai întâi oprită, așa că rămâneți fără nicio tură activă.

**Este ireversibil.** Tura, punctele și jurnalul ei dispar, iar
ștergerea este transmisă mai departe coechipierilor la următoarea
sincronizare. Documentele care erau legate de tură **nu** sunt șterse —
rămân atașate peșterii sau locului din peșteră și pierd doar legătura cu
tura.

## Unde ajung datele turelor

Turele, punctele și jurnalele lor stau în baza de date ca orice
altceva, așa că sunt incluse în exporturile de arhivă și călătoresc prin
[sincronizare FTP](ftp-sync.md) către restul echipei. Fișierele de
raport exportate și imaginile de hartă exportate sunt fișiere obișnuite
pe dispozitiv și nu se sincronizează.

## Vezi și

- [Desfășurarea unei ture](../workflows/running-a-trip.md)
- [Rapoarte de tură și șabloane](trip-reports.md)
- [Coduri QR](qr-codes.md)
- [Beaconuri BLE](ble-beacons.md)
- [Vizualizatorul de hărți](map-viewer.md)
- [Documente](documents.md)
