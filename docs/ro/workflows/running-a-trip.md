# Flux de lucru: desfășurarea unei ture

[← Înapoi la cuprins](../README.md)

O **tură** înregistrează o singură sesiune de speologie într-o singură
peșteră: când a început, locurile la care ați ajuns și în ce ordine, un
jurnal pe care aplicația îl scrie în locul dumneavoastră și documentele
făcute pe parcurs. Pagina de față parcurge tot procesul, de la parcare
până la raportul final.

## Când merită începută o tură

Începeți o tură când vreți:

- un **traseu** desenat punct cu punct pe hărțile raster ale peșterii;
- o **listă cu marcaje de timp** a locurilor la care ați ajuns;
- un **raport ODT sau DOCX** generat ulterior;
- documentele făcute în subteran grupate cu sesiunea.

Dacă vreți doar să consultați date existente sau să atașați o
fotografie la un loc, nu aveți nevoie de o tură — vedeți
[Navigarea în subteran](navigating-underground.md).

## O singură tură deodată, pentru toată aplicația

SpeleoLoc urmărește **o singură tură activă în toate peșterile**, nu
câte una pentru fiecare peșteră. Cât timp o tură este în desfășurare:

- **Începe tura** dispare din meniul **⋮** al fiecărei peșteri, inclusiv
  al celorlalte;
- ecranul **Ture trecute / active** al altei peșteri arată în
  continuare tura în desfășurare, deși ea aparține unei alte peșteri.

Ca să reluați tura de oriunde, deschideți meniul **⋮** al aplicației
(sertarul care intră dinspre marginea dreaptă) și derulați până jos.
Cardul turei de acolo conține **Vezi tura**, **Pauză** / **Continuă**
și un buton roșu de oprire.

## Înainte de coborâre

- Importați cea mai recentă arhivă a echipei sau rulați o sincronizare,
  astfel încât locurile și hărțile peșterii să fie la zi. Vedeți
  [Partajarea datelor](sharing-data.md).
- Încărcați dispozitivul și luați o baterie externă.
- Dacă vă veți baza pe beaconuri, porniți detectarea automată înainte de
  a intra — există un comutator rapid în meniul **⋮** al aplicației.
  Vedeți [Beaconuri BLE](../features/ble-beacons.md).
- Dacă vreți raportul chiar în aceeași seară, adăugați întâi un șablon
  (vedeți [Exportarea unui raport](#step-6--export-a-report)); ecranul
  cu șabloane se poate deschide doar din fluxul de export.

## Pasul 1 — Începeți tura

Din peșteră:

1. Deschideți peștera (**Pagina principală** → apăsați peștera).
   Ajungeți în lista ei de locuri.
2. Deschideți meniul **⋮** și alegeți **Începe tura** (pictograma verde
   de redare). Dacă opțiunea lipsește, o tură este deja în desfășurare
   undeva — opriți-o mai întâi.
3. Se deschide dialogul **Începe o tură nouă**, cu **Titlul turei** deja
   completat: numele peșterii și data de azi, de exemplu
   `Grotte de X 2026/04/22`. Dacă o tură din acea peșteră are deja exact
   acel titlu, aplicația adaugă un contor — ` [2]`, apoi ` [3]` — așa
   încât două ture din aceeași zi nu se ciocnesc niciodată. Înlocuiți
   titlul cu unul mai util dacă doriți; dacă goliți câmpul, rămâne
   sugestia.
4. Confirmați. Tura începe și aplicația deschide ecranul
   **Ture trecute / active** al peșterii, unde tura în desfășurare apare
   ca un card verde. De acum înainte apare și ca un card la baza
   meniului **⋮** al aplicației, pe fiecare ecran.

Același buton **Începe tura** se află în partea de sus a ecranului
**Ture trecute / active** al peșterii.

### Începerea prin scanarea intrării

Puteți face totul fără să deschideți vreun meniu. Scanați codul QR al
unui loc marcat ca intrare în peșteră și, dacă nu rulează nicio tură,
aplicația întreabă *„Ai scanat o intrare în peșteră. Vrei să începi o
tură nouă?”*, apoi afișează același dialog de titlu.

Dacă o tură este deja în desfășurare pentru o **altă** peșteră,
aplicația numește acea peșteră și întreabă dacă îi opriți tura;
răspundeți da, iar apoi vă oferă *„Vrei să începi o tură nouă pentru
această peșteră?”*.

## Pasul 2 — În subteran

Nu există un buton „adaugă punct”. Punctele se înregistrează singure:

| Ce faceți | Ce se înregistrează |
|---|---|
| Scanați codul QR al unui loc **din această peșteră** | Un punct de tură, confirmat cu *„Punct adăugat la tură”* |
| Este detectat un **beacon BLE** pentru un loc din această peșteră | Același punct de tură, fără să atingeți telefonul |
| Scanați un loc din **altă** peșteră | Nimic — locul se deschide normal |
| Scanați o **intrare** a acestei peșteri | Aplicația întreabă dacă ieșiți (vedeți mai jos) |

Detectarea prin beacon este cazul fără mâini: cu detectarea automată
pornită, telefonul poate rămâne în buzunar, iar traseul se completează
pe măsură ce treceți pe lângă fiecare loc cu beacon. Pe ecran primiți
*„Loc detectat: …”*, urmat de *„Punct adăugat la tură”*; în fundal,
același lucru sosește ca notificare, care adaugă *„Punct adăugat la
tură”* doar dacă a fost înregistrat un punct.

Același loc poate fi înregistrat de mai multe ori — fiecare scanare sau
detectare este un punct propriu, așa că un traseu dus-întors arată
ambele treceri.

### Documentele făcute în timpul turei

Fiecare document creat cât timp tura înregistrează — fotografie, notă
audio, notă text — este legat atât de tură, cât și de locul său, iar
jurnalul turei primește o linie pentru el. Niciun ecran nu listează
documentele unei ture, dar legătura se păstrează și circulă odată cu
sincronizarea și cu exportul. Vedeți
[Documente](../features/documents.md).

### Verificarea progresului fără a lăsa din mână ce faceți

Deschideți meniul **⋮** al aplicației și priviți cardul de jos. Arată
titlul turei, peștera, de cât timp sunteți în subteran, numărul total de
puncte și ultimele cinci, cu ora la care au fost înregistrate.

### Pauza

Apăsați **Pauză** — pe cardul turei, pe rândul de butoane al ecranului
turei sau pe ecranul **Ture trecute / active** — ca să opriți
înregistrarea în timpul unei pauze la suprafață sau al unei galerii
laterale pe care nu o vreți pe traseu. Cardul și eticheta de rezumat
devin portocalii și afișează **Tură în pauză**. **Continuă** repornește
înregistrarea.

Două lucruri de știut despre pauză:

- Este **uitată dacă aplicația repornește**. Tura în sine
  supraviețuiește închiderii aplicației, opririi ei forțate sau
  repornirii telefonului, dar revine **înregistrând**. După orice
  repornire, verificați culoarea cardului turei: verde înseamnă că
  înregistrează din nou.
- Nu lasă **nicio urmă în jurnalul turei**, așa că înregistrarea finală
  nu arată unde au fost pauzele.

## Pasul 3 — Opriți tura

1. Apăsați butonul roșu **Oprește**. Se află pe rândul de butoane al
   ecranului turei, pe ecranul **Ture trecute / active** al peșterii și
   pe cardul turei din meniul **⋮** al aplicației.
2. Primele două întreabă *„Oprești înregistrarea acestei ture?”* —
   confirmați. **Butonul de pe cardul din sertar oprește tura imediat,
   fără confirmare.**

La ieșire puteți în schimb să scanați codul QR al intrării: aplicația
întreabă *„Ai scanat o intrare în peșteră. Ieși din peșteră? Oprești
tura activă?”*. Răspundeți **Da** și tura se încheie; răspundeți **Nu**
și intrarea este înregistrată ca punct de tură obișnuit.

O tură oprită **nu** este blocată. Traseul, jurnalul, documentele legate
și orele ei se păstrează, ea intră în istoricul turelor peșterii și o
puteți în continuare redenumi, edita în jurnal, exporta, șterge sau
reporni.

## Pasul 4 — Verificați traseul

Deschideți tura din ecranul **Ture trecute / active** al peșterii sau de
pe cardul din sertar cât timp ea încă rulează. Ecranul se deschide în
vedere listă: un card de rezumat cu peștera, **Început**, **Terminat**,
**Durată** și **Puncte**, apoi fiecare punct în ordinea vizitării, cu o
insignă numerotată, ora și adâncimea locului în dreapta, acolo unde este
cunoscută. Apăsați un rând ca să deschideți acel loc din peșteră.

Dacă peștera are cel puțin o hartă raster, rândul de butoane oferă și
**Vedere hartă**. Acolo traseul este desenat ca o linie albastră cu
săgeți de direcție și cu un cerc albastru numerotat la fiecare punct și
apar încă trei butoane:

- **Redă traseul** — animează traseul, dezvăluind punctele unul câte
  unul, la aproximativ unul la 0,8 secunde. Apăsați din nou (butonul a
  devenit un stop roșu) ca să săriți la traseul complet.
- **Încadrează traseul** — mărește și deplasează imaginea astfel încât
  tot traseul să încapă pe ecran.
- **Exportă harta** — salvează o imagine a vederii curente în dosarul de
  documente al aplicației; mesajul de confirmare arată calea fișierului.

Dacă lipsește o porțiune din traseu, probabil sunteți pe harta greșită:
punctele al căror loc nu are un pin pe harta **selectată** sunt sărite
complet, atât numărul, cât și linia până la ele. Alegeți altă hartă în
banda de deasupra imaginii.

Pe un telefon ținut orizontal, rândul de butoane se reduce doar la
pictograme și derulează lateral — apăsați lung o pictogramă ca să-i
vedeți numele.

## Pasul 5 — Jurnalul turei

Jurnalul turei este **scris de aplicație** din evenimentele înregistrate;
nu este un carnet gol. Deschideți tura și apăsați **Jurnal**. Puteți
edita textul liber și apăsați pictograma de salvare ca să-l păstrați.

Ca să schimbați stilul de scriere, apăsați pictograma de carte din bara
de titlu a jurnalului:

| Stil | Cum sună |
|---|---|
| Brut (marcaje de timp + mesaje scurte) | O linie datată pentru fiecare eveniment |
| Clasic (propoziții complete) | Varianta implicită — „S-a ajuns la …” |
| Jurnal de teren (timp scurs + secvență) | „Prima oprire: …”, „S-a continuat spre …” |
| Narativ (paragrafe) | Proză curgătoare; cea mai bună bază pentru un raport |

Schimbarea întreabă **„Regenerăm jurnalul turei?”** și avertizează că
orice modificări manuale se vor pierde — tot jurnalul este reconstruit
din evenimentele înregistrate. Alegerea se memorează pentru întreaga
aplicație și se folosește și la turele viitoare.

Textul scris de dumneavoastră dispare și dacă apăsați **Repornește**,
care reconstruiește jurnalul. Punctele noi adăugate cât timp tura rulează
sunt *adăugate la sfârșit* în stilurile Brut, Clasic și Jurnal de teren,
așa că nu deranjează textul deja scris. Narativ este excepția: fiecare
punct nou reconstruiește tot jurnalul, iar modificările manuale se duc
odată cu el.

<a id="step-6--export-a-report"></a>

## Pasul 6 — Exportarea unui raport

1. Deschideți tura și apăsați **Export raport**.
2. Alegeți un șablon în dialogul **Selectează un șablon**. Formatul
   rezultat este cel al șablonului — un șablon ODT produce ODT, un
   șablon DOCX produce DOCX — iar formatul fiecărui șablon este afișat
   sub numele lui. Nu există o alegere de format.
   - Dacă nu aveți încă niciun șablon, aplicația spune *„Nu există
     șabloane. Adăugați un șablon mai întâi.”* și oferă
     **Administrare șabloane**. Același buton se află sub lista de
     șabloane. Aceasta este singura cale către ecranul cu șabloane —
     nimic din **Pagina principală**, **Setări** sau meniul aplicației
     nu îl deschide.
   - Dacă jurnalul turei este gol, exportul este refuzat cu *„Nu există
     jurnal de excursie de exportat”*. Deschideți întâi **Jurnal**.
3. Alegeți unde salvați fișierul. Raportul este șablonul cu textul
   jurnalului turei adăugat la sfârșit — harta traseului **nu** este
   inclusă; exportați-o separat cu **Exportă harta**.
4. După salvare, aplicația predă fișierul aplicației implicite a
   dispozitivului pentru acel format și acesta se deschide.

Vedeți [Rapoarte de tură](../features/trip-reports.md) pentru șabloane
în detaliu.

## Pasul 7 — Trimiteți datele echipei

Turele, punctele lor și legăturile lor către documente sunt înregistrări
obișnuite: ajung la colegii de echipă printr-o sincronizare sau printr-o
arhivă exportată, ca orice altceva. Șabloanele de raport sunt excepția:
ce circulă este intrarea din lista de șabloane, niciodată fișierul ODT
sau DOCX din spatele ei, așa că fiecare dispozitiv trebuie să-și adauge
propria copie. Vedeți [Partajarea datelor](sharing-data.md).

## Repararea greșelilor după aceea

**Ați oprit tura prea devreme sau ați reintrat în aceeași zi.**
Deschideți tura; acolo unde era butonul roșu de oprire se află acum un
**Repornește** albastru. Apăsându-l, acea tură devine din nou tura
activă, așa că scanările noi și detectările de beaconuri continuă să
adauge la același traseu. Două consecințe: ora de început este
**resetată la momentul repornirii**, așa că **Început** și **Durată** se
socotesc de acolo, nu de la plecarea inițială; iar jurnalul este
reconstruit, păstrând punctele anterioare și primind o linie de
„repornire”, dar pierzând tot ce ați scris de mână.

**Titlul nu spune nimic.** Deschideți tura și alegeți
**⋮ → Redenumește tura**. Funcționează la fel pentru turele în
desfășurare și pentru cele încheiate și nu atinge nimic altceva, deși
linia de deschidere a jurnalului continuă să citeze titlul vechi până la
regenerarea jurnalului.

**Tura a fost o greșeală.** **⋮ → Șterge tura** întreabă *„Șterge
această tură și toate punctele ei?”*. **Operația nu poate fi anulată**,
iar ștergerea este transmisă colegilor de echipă la următoarea
sincronizare. Dacă tura ștearsă este cea în desfășurare, ea este oprită
întâi, lăsându-vă fără nicio tură activă. Documentele care erau legate
de ea **nu** sunt șterse — rămân la peștera sau la locul lor din peșteră
și pierd doar legătura cu tura.

**Harta din spatele traseului are nevoie de lucru.** Meniul **⋮** al
ecranului turei conține și **Filtrare locuri peșteră**, **Sortare locuri
peșteră**, **Sortare hărți** și **Administrare hărți**, așa că puteți
adăuga sau corecta o hartă fără să părăsiți tura. Pinurile locurilor nu
pot fi mutate de aici.

## Găsirea turelor anterioare

Odată ce o peșteră are cel puțin o tură **încheiată**, în blocul de
antet al peșterii, sub detaliile ei, apare un buton
**Ture trecute / active (N)**. El deschide ecranul de ture al peșterii:
sus, controalele de pornire / oprire / pauză / vizualizare, apoi tura în
desfășurare dacă există și, mai jos, turele încheiate cu numărul lor de
puncte. Apăsați oricare dintre ele ca să-i revedeți harta, lista de
puncte și jurnalul.

Până când prima dumneavoastră tură dintr-o peșteră nu s-a încheiat,
butonul acela nu există — ajungeți la tura în desfășurare prin cardul din
meniul **⋮** al aplicației.

## Vezi și

- [Ture](../features/trips.md) — fiecare ecran și control în detaliu
- [Rapoarte de tură](../features/trip-reports.md) — șabloane și stiluri de jurnal
- [Navigarea în subteran](navigating-underground.md) — fluxul de scanare
- [Beaconuri BLE](../features/ble-beacons.md) — puncte de tură fără mâini
- [Documente](../features/documents.md) — fotografii, audio și note
- [Partajarea datelor](sharing-data.md) — trimiterea turei către restul echipei
