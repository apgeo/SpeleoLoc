# Ture

[← Înapoi la cuprins](../README.md)

O **tură** înregistrează o singură ieșire în subteran, într-o singură
peșteră: când a început și când s-a încheiat, cine a participat, o listă
ordonată de **puncte de tură** (locurile la care ați ajuns), un **jurnal
de tură** generat automat și documentele și pozele care țin de ea.

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
puteți adăuga, muta sau elimina punctele, corecta ora de început și de
sfârșit, completa participanții, edita jurnalul, exporta un raport, o
puteți șterge sau reporni.

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

Cât timp tura rulează, punctele se înregistrează singure:

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

Punctele nu trebuie să provină neapărat din scanări. Le puteți adăuga,
muta și elimina chiar dumneavoastră, în timpul turei sau mult după ea —
vedeți [Corectarea punctelor](#correcting-the-points) — și le puteți
construi din fotografiile și filmările făcute în subteran — vedeți
[Puncte din poze](#points-from-pictures).

## Ecranul turei

Deschideți o tură din cardul turei aflat în meniul lateral **⋮**, sau
apăsând-o în ecranul **Ture trecute / active** al peșterii. Ecranul are
sus un rând de butoane de acțiune și se deschide în vedere listă. Pe un
telefon ținut orizontal butoanele se reduc doar la pictograme — apăsați
lung pe una ca să îi vedeți numele — iar rândul se derulează lateral
când butoanele nu încap toate.

| Buton | Ce face |
|---|---|
| **Oprește** / **Pauză** / **Continuă** | Apar cât timp aceasta este tura activă. Vedeți [Pauză și continuare](#pausing-and-resuming) și [Oprirea unei ture](#stopping-a-trip). |
| **Repornește** | Apare în locul lor după ce tura s-a încheiat. Vedeți [Repornirea unei ture încheiate](#restarting-a-finished-trip). |
| **Adaugă punct** | Înregistrează un punct la un loc și la o oră alese de dumneavoastră. Vedeți [Corectarea punctelor](#correcting-the-points). |
| **Poze** | Deschide **Puncte din poze**. Vedeți [Puncte din poze](#points-from-pictures). |
| **Jurnal** | Deschide jurnalul. Vedeți [Jurnalul turei](#the-trip-log). |
| **Export raport** | Vedeți [Rapoarte de tură](trip-reports.md). |
| **Vedere hartă** / **Vedere listă** | Doar când peștera are cel puțin o hartă raster. Vedeți [Vederea hartă](#map-view). |

### Cardul rezumat și lista punctelor

Cardul de sus arată peștera, **Început**, **Terminat** (după ce tura
s-a încheiat), **Durată** și **Puncte**, plus o etichetă verde **Tură
activă** sau portocalie **Tură în pauză** cât timp tura este în
desfășurare. Sub ore arată participanții turei (**Participanți**) și
începutul detaliilor ei, sau un buton **Adaugă participanți și detalii**
cât timp nu există; apăsați oricare dintre ele ca să le editați —
vedeți [Participanți și detalii](#participants-and-details).

Când punctele au fost modificate și jurnalul a fost lăsat așa cum era,
un card de sub rezumat spune **Jurnalul turei nu mai e la zi** — vedeți
[Când se modifică punctele](#when-the-points-change).

Sub el, fiecare punct este listat în ordinea vizitării, cu un număr care
corespunde numărului de pe hartă, ora la care a fost înregistrat și, în
dreapta, adâncimea locului în peșteră atunci când se cunoaște. Apăsați
un rând ca să deschideți acel loc din peșteră. Înainte de primul punct,
lista arată *„Niciun punct înregistrat”*.

În dreapta unui rând mai stau două controale:

- o **pictogramă de poză cu un număr**, la punctele care au poze legate
  de ele (vedeți [Puncte din poze](#points-from-pictures)). Apăsați-o
  pentru **Poze la acest punct**, o foaie cu acele poze; apăsați una ca
  să o deschideți. Foaia este doar pentru vizualizare — aceleași fișiere
  sunt atașate și locului din peșteră și apar și printre documentele
  lui;
- un buton **⋮** (**Acțiuni punct**) cu **Schimbă ora** și **Șterge
  punctul**.

<a id="map-view"></a>

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
| **Puncte din poze** | Același ecran ca butonul **Poze**. Vedeți [Puncte din poze](#points-from-pictures). |
| **Participanți și detalii** | Vedeți [Participanți și detalii](#participants-and-details). |
| **Ora de început și de sfârșit** | Vedeți [Corectarea orei de început și de sfârșit](#correcting-the-start-and-end-times). |
| **Redenumește tura** | Vedeți mai jos. |
| **Șterge tura** | Vedeți mai jos. |

<a id="correcting-the-points"></a>

## Corectarea punctelor

O scanare ratată, o etichetă care nu a putut fi citită, o tură scrisă
abia în seara de după: orice punct poate fi adăugat, mutat sau eliminat
manual, la o tură în desfășurare sau la una încheiată de mult.

- **Adaugă punct** din rândul de butoane vă cere întâi locul, în
  dialogul **Alege un punct**, dintre locurile peșterii turei (cu o
  casetă **Caută**), apoi **Ora punctului** — **Data** și **Ora**. Ora
  pornește de la momentul întrebării la o tură în desfășurare și de la
  finalul turei la una încheiată. Punctul este înregistrat exact cum ar
  fi fost înregistrată o scanare în acel moment și este înregistrat
  chiar și cât timp tura este în pauză.
- **⋮ → Schimbă ora** de pe rândul unui punct îl mută la alt moment.
  Lista se reordonează singură după oră, iar numerele de pe hartă
  urmează.
- **⋮ → Șterge punctul** întreabă *„Elimini punctul „…” din această
  tură?”*. Pozele legate de acel punct rămân la locul din peșteră.

O oră dinaintea începutului turei sau de după încheierea ei este
permisă, dar dialogul de oră o semnalează cu portocaliu cât timp o
alegeți — *„Această oră este înainte de începutul turei (…).”* — ca să
o confirmați în cunoștință de cauză. Același loc nu poate fi înregistrat
de două ori exact în același moment: aplicația refuză cu *„Acest punct
este deja înregistrat la ora respectivă”*.

Fiecare dintre aceste modificări schimbă ce ar trebui să spună jurnalul.
Ce se întâmplă apoi cu jurnalul hotărăște o setare — vedeți
[Când se modifică punctele](#when-the-points-change).

<a id="correcting-the-start-and-end-times"></a>

## Corectarea orei de început și de sfârșit

**⋮ → Ora de început și de sfârșit** arată **Început** și, pentru o tură
încheiată, **Terminat**; apăsați oricare ca să alegeți o nouă dată și
oră. Există mai ales pentru turele introduse ulterior, ale căror ore
înregistrate sunt momentul în care le-ați introdus, nu momentul în care
ați coborât în subteran, și pentru a readuce începutul inițial după un
**Repornește**.

- O tură în desfășurare oferă doar începutul — *„Tura este încă în
  desfășurare; sfârșitul se stabilește când o oprești.”*
- Un sfârșit înaintea începutului este refuzat: *„Sfârșitul este
  înaintea începutului.”*, iar **OK** rămâne estompat.
- Dacă puncte înregistrate ar rămâne în afara noilor ore, dialogul le
  numără — *„N punct(e) înregistrate ar rămâne în afara acestor ore.
  Sunt păstrate așa cum sunt.”* Nimic nu este mutat sau șters în locul
  dumneavoastră.

Salvarea afișează **Orele turei au fost salvate**. Jurnalul este tratat
ca la o modificare a punctelor.

<a id="participants-and-details"></a>

## Participanți și detalii

**⋮ → Participanți și detalii**, sau o apăsare pe linia participanților
din cardul rezumat, deschide o pagină cu două câmpuri:

- **Participanți** — nume separate prin virgulă, scrise dintr-o dată.
  Fiecare nume apare ca o etichetă sub câmp, arătând cum a fost înțeles
  textul; × de pe o etichetă scoate din nou acel nume. Butonul de la
  capătul câmpului (**Adaugă un participant**) cere în schimb un singur
  **Nume**. Un nume dat de două ori este păstrat o singură dată.
- **Detalii** — text liber pentru orice altceva merită păstrat despre
  tură: scopul, vremea, echipamentul, ce s-a găsit.

Apăsați **Salvează** ca să le păstrați (*„Detaliile turei au fost
salvate”*). Amândouă ajung la echipă împreună cu tura. Nu sunt scrise în
jurnalul turei, așa că nu ajung singure într-un raport exportat —
copiați-le în jurnal sau în șablonul de raport dacă le vreți acolo.

<a id="points-from-pictures"></a>

## Puncte din poze

Cei mai mulți speologi ies din peșteră cu o galerie plină de fotografii,
nu cu o listă ordonată de scanări. Ecranul **Puncte din poze** —
butonul **Poze** sau **⋮ → Puncte din poze** — transformă fotografiile
și filmările de pe dispozitiv în puncte de tură, la momentele în care au
fost făcute, și poate atașa pozele însele locurilor și punctelor cărora
le aparțin.

Ecranul este o foaie de lucru: nu se scrie nimic până nu apăsați
butonul **Adaugă N** de jos, așa că puteți parcurge câteva sute de poze
și le puteți corecta mai întâi.

### Ce poze sunt listate

Intervalul de date de sus pornește de la zilele turei înseși, din ziua
în care a început până în ziua în care s-a încheiat (azi, pentru o tură
în desfășurare). Apăsați-l ca să alegeți alte zile; butonul de
reîmprospătare (**Reîncarcă**) citește lista din nou. Pozele sunt
listate după momentul în care au fost făcute, care, pentru pozele
copiate de pe un aparat foto rezistent la apă sau de pe telefonul unui
coechipier, este ora de captură a aparatului, nu ziua în care a ajuns
fișierul — așa că potriviți ceasul aparatului înainte de tură.

De unde provin pozele depinde de ce îi permite telefonul aplicației să
vadă. O linie de sub intervalul de date arată în ce caz vă aflați:

| Linie | Înțeles | Butoane |
|---|---|---|
| *Sunt afișate pozele și filmările de pe acest dispozitiv.* | Acces complet la galeria foto. | **Alege fișiere** |
| *Sunt afișate doar pozele pentru care ai permis accesul.* | Ați dat acces doar la anumite fotografii. | **Alege mai multe poze**, **Alege fișiere** |
| *Fără acces la galerie, sunt afișate doar fișierele alese de tine. …* | Fără acces la galerie: alegeți fișierele câte un lot pe rând. | **Adaugă fișiere**, **Permite accesul la toate pozele** |
| *Sunt afișate fișierele alese de tine.* | Ați ales fișiere deși galeria era disponibilă. | **Adaugă fișiere**, **Folosește galeria** |

Pentru fișierele alese, ora vine din fișierul însuși și poate fi mai
puțin exactă. O pictogramă de ceas lângă ora unei poze înseamnă că
aparatul nu a înregistrat nicio oră de captură și s-a folosit în schimb
data fișierului — care poate fi momentul copierii, nu al fotografierii.

### Citirea etichetelor QR din poze

Dacă ați fotografiat etichetele QR ale locurilor prin care ați trecut,
aplicația le citește în locul dumneavoastră. După ce lista apare pe
ecran, ea parcurge una câte una fotografiile din zilele selectate —
*„Se caută coduri QR în zilele selectate: 12/80 (5 găsite)”* — și
completează locul oriunde găsește eticheta unui loc din peștera turei,
marcat cu o mică pictogramă QR verde. **Oprește** încheie căutarea mai
devreme; ce a găsit până atunci rămâne. Filmările nu sunt căutate.

Căutarea nu suprascrie niciodată un loc pe care l-ați ales deja singuri.
Ce a citit este reținut pe acest dispozitiv, așa că redeschiderea
ecranului pe aceleași poze este rapidă; potrivirea cu locurile se face
din nou de fiecare dată, așa că un loc al cărui cod s-a schimbat este
găsit în continuare corect. Unele dispozitive nu pot citi deloc coduri
din pozele salvate; ecranul spune atunci *„Acest dispozitiv nu poate
citi coduri QR din poze salvate — alege punctele manual.”*

### Alegerea manuală a locurilor și orelor

Apăsați rândul unei poze (sau **⋮ → Alege punctul**) ca să îi alegeți
locul. Meniul **⋮** al rândului oferă și **Schimbă ora**, care mută
punctul pe care îl va crea acea poză fără să atingă poza, și **Șterge**,
care elimină locul. Un rând poate fi bifat doar după ce are un loc și
este bifat imediat ce primește unul; debifați-le pe cele pe care nu le
vreți.

### Adăugarea punctelor

**Salvează și pozele**, activată implicit, atașează fiecare poză bifată
locului ei din peșteră și o leagă de punctul de traseu pe care îl
creează, astfel încât ea apare în spatele pictogramei de poză a acelui
punct în ecranul turei. Se aplică setările de
[compresie imagini](settings.md#image-compression). Cu opțiunea
dezactivată, se adaugă doar punctele.

Apăsați **Adaugă N**. Dacă vreo poză bifată este la o intrare a
peșterii, întâi apare un dialog **Poze la intrare**, pentru că o poză
la o intrare înseamnă intrarea sau ieșirea și poate contrazice ce
conține deja tura. Dialogul poate oferi:

- eliminarea punctelor de intrare aflate deja în tură, fiecare bifat
  separat;
- **Mută începutul turei** la ora unei poze de la intrare;
- **Mută sfârșitul turei**, la fel, la o tură încheiată.

Două sau mai multe poze la intrare sunt citite ca „am intrat la prima,
am ieșit la ultima”; una singură mută capătul turei de care este mai
aproape. **Totul în acest dialog pornește dezactivat** — apăsați **OK**
fără să atingeți nimic și punctele sunt pur și simplu adăugate.

Punctele sunt apoi adăugate, cu o linie de progres, iar ecranul se
închide cu un rezumat ca *„7 punct(e) adăugate · 2 deja înregistrate ·
7 poză(e) salvate”*. O poză al cărei loc este deja înregistrat exact în
acel moment nu adaugă un al doilea punct, dar este totuși legată de cel
existent. Cât timp se adaugă punctele, ecranul nu poate fi părăsit.

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

<a id="pausing-and-resuming"></a>

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

<a id="the-trip-log"></a>

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
- **Regenerarea** după modificarea punctelor face același lucru —
  vedeți mai jos.
- În stilurile **Brut**, **Clasic** și **Jurnal de teren** un eveniment
  nou este doar adăugat la sfârșit, așa că modificările anterioare îi
  supraviețuiesc. În stilul **Narativ** fiecare punct sau document nou
  rescrie tot jurnalul.

Adăugați astfel de note la sfârșitul turei și păstrați o copie în altă
parte dacă sunt importante.

O tură cu jurnal gol nu poate fi exportată ca raport: **Export raport**
răspunde *„Nu există jurnal de excursie de exportat”*.

<a id="when-the-points-change"></a>

### Când se modifică punctele

Adăugarea, mutarea sau ștergerea unui punct, corectarea orelor turei ori
adăugarea de puncte din poze schimbă toate ce ar trebui să spună
jurnalul. Ce se întâmplă apoi cu jurnalul se stabilește în
**Setări → Jurnalul turei → Regenerează jurnalul când se modifică
punctele**, care este **dezactivată** implicit. Pagina jurnalului arată
cum este setată, cu un buton cu rotiță care deschide setarea.

- **Dezactivată** — jurnalul rămâne așa cum l-ați scris, iar tura este
  marcată ca având un jurnal care nu mai e la zi. Nu se pierde nimic din
  ce ați scris.
- **Activată** — jurnalul este rescris din puncte, în stilul de jurnal
  curent. Dacă se citește încă exact cum l-ar produce punctele, asta se
  întâmplă în tăcere. Dacă mai conține altceva — text scris de
  dumneavoastră sau modificări rămase în urmă — aplicația întreabă
  întâi, într-un dialog cu titlul **Regenerarea ar înlocui text din
  jurnal**: **Regenerează**, **Păstrează așa** (care îl marchează în
  schimb ca nefiind la zi) sau **Anulează**, care renunță și la
  modificarea punctelor.

Cât timp un jurnal nu e la zi, atât ecranul turei, cât și pagina
jurnalului arată un card: **Jurnalul turei nu mai e la zi** —
*„Punctele s-au schimbat din … și jurnalul nu a fost regenerat, deci nu
mai corespunde cu ele.”* Cardul oferă:

- **Regenerează** — întreabă **Regenerezi jurnalul turei?**, avertizează
  că orice text scris de mână este înlocuit, apoi rescrie jurnalul din
  puncte;
- **Păstrează așa** — acceptă jurnalul așa cum este și elimină cardul;
  textul nu este atins;
- **Setări jurnal** — deschide setarea de mai sus.

Scanările în timp real și detectările de beaconuri nu sunt modificări:
ele continuă să adauge la jurnal cum s-a descris mai sus, oricum ar fi
setarea.

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

Pozele salvate prin [Puncte din poze](#points-from-pictures) sunt legate
altfel: fiecare de **punctul de traseu** pe care l-a creat, precum și de
locul ei din peșteră. Pe acestea le arată pictograma de poză de pe
rândul unui punct.

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

<a id="stopping-a-trip"></a>

## Oprirea unei ture

Apăsați butonul roșu **Oprește**: în ecranul turei, în ecranul **Ture
trecute / active** al peșterii sau pe cardul turei din meniul ⋮.
Primele două întreabă *„Oprești înregistrarea acestei ture?”*; butonul
de pe card oprește imediat, fără confirmare. Scanarea codului QR al unei
intrări din peștera turei se oferă și ea să o oprească.

Oprirea înregistrează ora de final și nu mai lasă nicio tură activă.
Toate datele turei sunt păstrate.

<a id="restarting-a-finished-trip"></a>

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
  **⋮ → Ora de început și de sfârșit** readuce începutul inițial.
- Jurnalul este reconstruit în același timp. Păstrează punctele
  anterioare și primește o intrare „tură repornită” între cele două
  reprize, dar tot ce ați scris manual în el se pierde.

## Ștergerea unei ture

**⋮ → Șterge tura** din ecranul turei întreabă *„Șterge această tură și
toate punctele ei?”*. Dacă tura este cea care rulează în acel moment, ea
este mai întâi oprită, așa că rămâneți fără nicio tură activă.

**Este ireversibil.** Tura, punctele și jurnalul ei dispar, iar
ștergerea este transmisă mai departe coechipierilor la următoarea
sincronizare. Documentele care erau legate de tură și pozele legate de
punctele ei **nu** sunt șterse — rămân atașate peșterii sau locului din
peșteră și pierd doar legătura cu tura.

## Unde ajung datele turelor

Turele, punctele lor, participanții și detaliile lor, jurnalele și
legăturile dintre poze și puncte stau în baza de date ca orice altceva,
așa că sunt incluse în exporturile de arhivă și călătoresc prin
[sincronizare FTP](ftp-sync.md) către restul echipei. Fișierele de
raport exportate și imaginile de hartă exportate sunt fișiere obișnuite
pe dispozitiv și nu se sincronizează. Nici ce a citit **Puncte din
poze** din etichetele QR ale pozelor nu se sincronizează: aceasta se
referă doar la pozele de pe acest dispozitiv.

## Vezi și

- [Desfășurarea unei ture](../workflows/running-a-trip.md)
- [Rapoarte de tură și șabloane](trip-reports.md)
- [Coduri QR](qr-codes.md)
- [Beaconuri BLE](ble-beacons.md)
- [Vizualizatorul de hărți](map-viewer.md)
- [Documente](documents.md)
