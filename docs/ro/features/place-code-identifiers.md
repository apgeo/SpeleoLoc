# Coduri de loc (PCI) și conținutul codurilor QR (QCRI)

[← Înapoi la cuprins](../README.md)

Fiecare [loc din peșteră](cave-places.md) poate purta două coduri: un
**identificator cod loc** lizibil, pe care îl tipăriți ca text lângă
etichetă, și un **identificator resursă cod QR** — conținutul codificat
efectiv în pixelii codului QR. Această pagină explică ce este fiecare,
cum le construiește aplicația pentru dumneavoastră și la ce trebuie să
fiți atenți odată ce etichetele sunt tipărite și montate în subteran.

## Cele două coduri

| Cod | Ce este | Unde îl vedeți |
|---|---|---|
| **PCI** — identificator cod loc | Codul **lizibil de om**, de exemplu `04-015-001-007-0003`, `001`, `12`. În formularul locului din peșteră este câmpul **Identificator cod loc**. | Tipărit ca text lângă o etichetă, în formularul locului din peșteră, în rapoarte. |
| **QCRI** — identificator resursă cod QR | **Conținutul din imaginea QR** (și dintr-un deep link `sp://`). Este fie o copie exactă a codului locului, fie un hash scurt al acestuia. În formular este câmpul **Identificator resursă cod QR**. | În pixelii codului QR; în deep link-uri. |

Aplicația folosește formele scurte PCI și QCRI pe mai multe ecrane — fila
de setări se numește **Identificatori coduri QR**, iar butonul care
reîmprospătează conținuturile este **Recalculează toate QCRI-urile**.

Câteva etichete mai vechi au supraviețuit: lista locurilor din peșteră se
sortează după **Identificator cod QR** și se grupează după **Are cod QR**
— amândouă citesc codul locului — iar dialogul de căutare manuală își
etichetează caseta **Mod de generare identificatori cod QR**, unde este
acceptat oricare dintre cele două coduri.

## De ce două coduri

- **Codul locului** este pentru oameni. Este lizibil, ierarhic dacă
  doriți asta, și îl puteți scrie pe un marcaj de lângă o etichetă care a
  căzut.
- **Conținutul QR** este pentru cameră. S-ar putea să îl vreți mai scurt
  sau opac, astfel încât o etichetă fotografiată să nu dezvăluie cum își
  numerotează clubul dumneavoastră peșterile.

Dacă niciuna dintre acestea nu contează pentru dumneavoastră, lăsați
modul de generare pe **Identic cu codul locului** și cele două sunt
identice.

> Hash-ul este pentru scurtime și opacitate, nu pentru securitate. Nu
> este o protecție criptografică a nimic.

## Unde se află setările

Deschideți **Setări → Identificatori cod loc**. Pagina are două file:

- **Strategie** — ce schemă de numerotare este activă, regulile ei și
  butonul **Generează coduri pentru întregul set de date**.
- **Identificatori coduri QR** — cum se derivă conținutul QR, opțiunile
  de hash și butonul **Recalculează toate QCRI-urile**.

Acestea sunt setări **la nivel de set de date** și călătoresc împreună cu
datele dumneavoastră: sunt incluse în arhivă și în sincronizarea FTP,
deci schimbarea strategiei sau a salt-ului de hash pe un telefon o
schimbă pentru toți cei care folosesc acel set de date. Vedeți
[Sincronizarea și istoricul modificărilor](sync-and-change-log.md).

## Cum își primește un loc codul

1. **Tastați-l** în câmpul **Identificator cod loc** din formularul
   locului din peșteră (deblocați mai întâi câmpul cu lacătul de lângă
   el).
2. **Apăsați butonul ✨** (indiciu *Generează automat*) de lângă câmp.
   Completează câmpul folosind strategia activă; nimic nu este stocat
   până când nu salvați locul. Rămâne estompat cât timp câmpul este
   blocat.
3. **Rulați un lot** pentru o peșteră întreagă, o arie de suprafață
   întreagă sau întregul set de date — vedeți
   [Generarea codurilor în lot](#generating-codes-in-bulk).

Locurile create prin fereastra **Adăugare loc peșteră** de pe harta
raster și locurile aduse prin [import CSV](csv-import.md) își obțin
automat conținutul QR din codul de loc pe care îl poartă, așa că nu
trebuie să rulați o generare după aceea. Un cod de loc importat
înlocuiește unul existent doar când importul este setat să suprascrie
codurile.

## Strategii de numerotare

Strategia este ceea ce folosește aplicația pentru a calcula un cod de
loc. Alegeți-o din **Setări → Identificatori cod loc → Strategie**;
legătura **Mai multe informații** de sub listă arată o descriere mai
lungă a celei selectate.

<a id="global-hierarchical-default"></a>

### Ierarhic global (implicit)

Cinci segmente, concatenate în această ordine:

```
country · organization · surface area · cave index · place index
```

- **Cod țară** și **Cod organizație** sunt **obligatorii**. Dacă vreunul
  este gol nu se generează absolut nimic: rularea se oprește la primul
  loc, iar sumarul arată un banner roșu cu textul *„Generare anulată:
  codul de țară sau codul de organizație nu sunt configurate."*
  Setați-le pe amândouă înainte de a genera.
- Segmentul de **zonă** este **Identificator zonă generală** al
  [ariei de suprafață](surface-areas.md) a peșterii, inserat exact așa
  cum este stocat — nu este niciodată completat cu zerouri.
- **Indexul peșterii** este **Index local peșteră** al peșterii. Un număr
  alocat de aplicație este completat cu zerouri până la **Nr. cifre
  index local peșteră**; o valoare tastată de dumneavoastră în acel câmp
  este folosită exact așa cum a fost tastată.
- **Indexul locului** este alocat per peșteră și completat cu zerouri
  până la **Nr. cifre index local loc**.
- **Separator segmente** (de exemplu `-`) este inserat între *fiecare*
  segment, așa că un cod nu poate începe niciodată cu un număr de zonă
  simplu.

  ⚠️ **Nu folosiți niciodată `/` sau `=` ca separator.** Acestea sunt
  cele două caractere la care o scanare taie o adresă web. Odată ce
  etichetele dumneavoastră poartă o
  [adresă de destinație](qr-codes.md#what-a-printed-label-contains) în
  loc de `sp://`, aplicația păstrează doar textul de după ultimul `/`
  sau `=` din adresa citită — așa că un cod asamblat cu oricare dintre
  cei doi separatori se întoarce doar ca segmentul lui final și nu
  potrivește niciun loc. Aplicația **avertizează** pe câmp în clipa în
  care tastați unul (*„Un / sau = aici trunchiază orice cod tipărit
  atunci când e scanat."*), iar acel avertisment este toată protecția
  ei: separatorul este totuși salvat, este folosit în continuare pentru
  fiecare cod generat după aceea și nimic nu este verificat vreodată la
  codurile alocate mai devreme sau tastate manual. Schimbați-l înainte
  de o serie de tipărire — după aceea costă o retipărire. (În modul
  **Hash (identificator scurt derivat)** conținutul tipărit este format
  doar din litere și cifre, așa că nu poate fi afectat.)
- **Sufix intrare principală** este folosit ca atare (fără completare cu
  zerouri) ca segment de loc al intrării principale a peșterii, atunci
  când acel cod este încă liber. Niciun alt loc nu primește acel număr.
- **Nr. cifre identificator zonă generală** *nu* dimensionează segmentul
  de zonă. Este menit doar să dimensioneze substituentul folosit când
  zona lipsește, iar în versiunea actuală nu are niciun efect —
  substituentul are întotdeauna trei caractere.
- **Permite segmente non-numerice** nu are niciun efect în versiunea
  actuală, pentru că nimic din ce tastați nu este verificat față de
  strategie.

Țara `04`, organizația `015`, identificatorul zonei `001`, nr. cifre
index peșteră 3, nr. cifre index loc 4, fără separator:

```
040150010070003    ← country 04, org 015, area 001, cave 007, place 0003
```

Cu `-` ca separator de segmente, același cod se citește
`04-015-001-007-0003`.

> 📷 [Gestionarea ariilor de suprafață](../screenshots/01-home-and-caves.md#surface-areas-list) — lista ariilor de suprafață, unde sunt create și editate regiunile care grupează peșteri.

**Peșterile cu date lipsă primesc totuși coduri.** O peșteră care nu a
fost atribuită unei arii de suprafață nu este sărită: locurile ei
primesc un cod al cărui segment de zonă este numai zerouri (`000`). O
peșteră a cărei arie de suprafață nu are Identificator zonă generală
primește numai cifre de nouă (`999`). Aceste coduri sunt reale, sunt
scrise în baza de date și pot ajunge tipărite. Sumarul generării
semnalează amândouă cazurile, ca să puteți corecta datele și regenera
înainte de a tipări ceva.

**Indexul peșterii este alocat o singură dată și păstrat.** Fiecare
peșteră are un câmp **Index local peșteră** pe ecranul de adăugare sau
editare a peșterii. Setați-l dumneavoastră sau lăsați-l gol, iar prima
generare pentru acea peșteră alege cel mai mic număr liber și îl
salvează definitiv în peșteră — regenerările ulterioare produc atunci
aceleași coduri. Numărul trebuie să fie liber doar *în cadrul
segmentului său de zonă*, așa că două peșteri din arii de suprafață
diferite pot fi amândouă peștera `001`. Modificarea sau golirea câmpului
ulterior schimbă codurile generate pentru acea peșteră.

### Secvențial per peșteră

Numere întregi simple, care reîncep în interiorul fiecărei peșteri.
Pornind de la **Începe de la** (implicit 1), aplicația urcă cu **Pas**
până găsește un număr liber și îl completează cu zerouri până la
**Nr. cifre umplere cu zerouri** (0 înseamnă fără completare).
**Intrarea principală prima** rezervă valoarea de start pentru intrarea
principală a peșterii.

Doar codurile numerice contează ca fiind „deja ocupate", așa că un cod
tastat manual precum `LAKE-A12` nu blochează un număr.

### Secvențial per zonă

Aceeași idee, dar contorul este împărțit de **toate peșterile din aceeași
[arie de suprafață](surface-areas.md)** — regiunea de la suprafață care
grupează peșteri întregi — în loc să reînceapă în interiorul fiecărei
peșteri. Nu există două locuri dintr-o arie de suprafață cărora să li se
dea același număr, ceea ce se potrivește unei regiuni carstice numerotate
ca o singură serie continuă.

Peșterile care **nu** sunt atribuite unei arii de suprafață sunt
**sărite**: locurile lor rămân fără coduri și sunt numărate la *Sărite*
în sumarul generării.

### Alegerea unei strategii

| Dacă doriți… | Strategia |
|---|---|
| Coduri stabile, de partajat între echipe și cluburi | **Ierarhic global** |
| Numerotare simplă `1..N` per peșteră, fără configurare | **Secvențial per peșteră** |
| Numerotare simplă `1..N` împărțită de toate peșterile dintr-o arie de suprafață | **Secvențial per zonă** |

Puteți schimba strategia mai târziu, dar regenerarea vă va propune să
suprascrieți coduri care s-ar putea să fie deja tipărite pe etichete
fizice — vedeți
[Viața cu etichete tipărite](#living-with-printed-labels).

### Setați regulile înainte de primul lot

⚠️ Casetele din fila **Strategie** nu intră în vigoare până când nu
editați una dintre ele. Până atunci aplicația folosește propriile valori
încorporate, care nu sunt întotdeauna cele afișate în casete.

Asta lovește cele două strategii secvențiale, pentru că ele nu au nevoie
de nicio configurare: rulați un lot imediat și codurile ies **fără
completare cu zerouri** (`1`, `2`, `3` în loc de `001`), iar intrarea
principală **primește** valoarea de start, chiar dacă **Nr. cifre
umplere cu zerouri** arată 3, iar **Intrarea principală prima** apare
dezactivată.

Editarea oricărui câmp din filă salvează dintr-odată tot ce este pe
ecran, după care ecranul și codurile generate se potrivesc. Așadar
deschideți fila și setați explicit valorile dorite înainte de primul lot
— chiar dacă doar retastați valoarea care este deja acolo. (Ierarhic
global este sigur în practică: refuză să genereze până nu ați tastat
codurile de țară și de organizație, iar tastarea lor salvează și restul
filei.)

## Conținutul QR

În fila **Identificatori coduri QR**, lista derulantă **Identificator cod
QR** decide cum este derivat conținutul.

| Mod | Comportament |
|---|---|
| **Identic cu codul locului** (implicit) | Conținutul este chiar codul locului. Scanarea unei etichete este același lucru cu tastarea codului ei de loc. |
| **Hash (identificator scurt derivat)** | Conținutul este un hash scurt al codului locului. Imaginea QR codifică hash-ul, nu codul lizibil. |

Sub controale, un exemplu în timp real arată ce produc setările
dumneavoastră curente — *Exemplu: cod loc= 040150001001 → cod QR= …* — și
se actualizează pe măsură ce mutați cursorul de lungime sau editați
salt-ul, așa că puteți vedea rezultatul înainte de a genera ceva.

### Lungime hash

Afișată doar când se aplică hash-ul. Cursorul merge de la **4 la 16**
caractere, implicit 8; mai lung înseamnă șansă mai mică de ciocnire între
două locuri și o imagine QR mai densă.

Dacă un hash calculat s-ar ciocni cu al altui loc, aplicația adaugă
discret un caracter **doar pentru acel loc** (până la 16), așa că câteva
coduri din setul dumneavoastră de date pot ieși cu un caracter sau două
mai lungi decât restul.

### Salt hash

Un șir opțional amestecat în hash, astfel încât două seturi de date care
conțin aceleași coduri de loc să producă conținuturi diferite. Caseta
apare doar când hash-ul este în joc, cu ajutorul de pe ecran *„Șir
opțional adăugat la intrarea hash. Modificarea acestuia va schimba toate
QCRI generate — recalculați după salvare."*

**Nu este o parolă**: este stocat împreună cu setările dumneavoastră și
se sincronizează pe fiecare dispozitiv care folosește setul de date.
Tratați-l ca pe o setare a setului de date. Setați-l o dată, înainte de a
tipări ceva — schimbarea lui ulterioară schimbă fiecare conținut și
fiecare etichetă tipărită trebuie înlocuită.

### Hash pentru intrări

Acest comutator apare **doar în modul Identic cu codul locului**: cu
modul setat pe *Identic cu codul locului*, activarea lui face ca
**intrările să fie singurele locuri cu conținut hash-uit**, în timp ce
orice alt loc păstrează conținut = cod de loc. Se aplică oricărui loc
marcat ca **Intrare în peșteră**, nu doar intrării principale. Activarea
lui dezvăluie și cursorul de lungime a hash-ului, și caseta de salt.

În modul *Hash (identificator scurt derivat)* nu există un asemenea
comutator — totul, inclusiv intrările, este hash-uit.

<a id="generating-codes-in-bulk"></a>

## Generarea codurilor în lot

### De unde puteți porni o generare

| De unde | Domeniu |
|---|---|
| **Setări → Identificatori cod loc → Strategie → Generează coduri pentru întregul set de date** | Fiecare loc din baza de date. |
| Lista locurilor din peșteră → butonul ✨ din bara de instrumente (indiciu *Generează coduri*) sau **⋮ → Generează coduri** pe același ecran | Fiecare loc din acea peșteră. |
| Ecranul de editare a peșterii → **⋮ → Generează coduri** (doar când editați o peșteră existentă) | Fiecare loc din acea peșteră. |
| **Arii de suprafață** → **⋮ → Afișează pictogramele de generare**, apoi ✨ de pe rândul unei arii | Fiecare loc din fiecare peșteră a acelei arii de suprafață. |
| Butonul **Generează coduri** din dialogul de editare a ariei | Același domeniu, la nivel de arie. |
| Formularul locului din peșteră → ✨ de lângă **Identificator cod loc** | Doar acest loc și doar în câmp — nimic nu este stocat până nu salvați locul. |

Butonul ✨ de pe rândurile din **Arii de suprafață** este ascuns până
bifați **Afișează pictogramele de generare** în meniul **⋮** al acelui
ecran. Butonul de interval QR de lângă el este întotdeauna vizibil.

### Ce se întâmplă în timpul unei rulări

1. Apare mai întâi o confirmare simplă — de exemplu *„Generați coduri
   pentru întregul set de date?"* — cu **Anulează** și **Generează
   coduri**. Nu există listă de previzualizare.
2. Un dialog **Se generează coduri…** arată o bară de progres, un contor
   *Procesare: 12 / 340 (4%)*, o linie **Timp estimat** și un buton
   **Oprire**. **Oprire** încheie rularea; tot ce a fost scris până în
   acel punct rămâne scris.
3. Locurile care nu au încă un cod sunt completate în tăcere. Un loc al
   cărui cod recalculat este identic cu cel pe care îl are deja este
   lăsat în pace.
4. Doar atunci când un cod existent chiar s-ar **schimba**, rularea se
   oprește și întreabă.

Întrebarea este intitulată **Suprascrieți valoarea existentă?**, numește
câmpul și arată valoarea veche și pe cea nouă:

| Buton | Efect |
|---|---|
| **Păstrează** | Lasă acest cod în pace. |
| **Înlocuiește** | Ia noul cod pentru acest loc. |
| **Păstrează-le pe toate la fel** | Lasă în pace fiecare conflict rămas, fără alte întrebări. |
| **Înlocuiește toate** | Ia noua valoare pentru fiecare conflict rămas. |
| **Anulează procesul** | Oprește rularea aici. Tot ce a fost scris până acum rămâne scris. |

Codul locului și conținutul QR sunt întrebate **separat**, iar un răspuns
general se aplică doar câmpului pentru care a fost dat — răspunsul
**Păstrează-le pe toate la fel** pentru codurile de loc lasă în
continuare aplicația liberă să întrebe despre conținuturile QR.

### Sumarul generării

Când rularea se încheie primiți un **Sumar generare**: peșteri cu coduri
generate, locuri actualizate, locuri suprascrise (aveau deja un cod),
timp de procesare și numărul locurilor sărite / refuzate / întrerupte.
Dacă ați oprit-o, apare și *„Lotul a fost anulat."*

Un banner roșu apare când rularea a fost întreruptă — cel mai adesea
*„Generare anulată: codul de țară sau codul de organizație nu sunt
configurate."*

Dacă vreunei peșteri îi lipsea aria de suprafață sau aria ei nu avea
identificator, o secțiune extensibilă listează acele peșteri după nume,
cu câte locuri a contribuit fiecare, și spune ce substituent a fost
folosit (`000…` sau `999…`). Corectați datele lipsă și regenerați
**înainte** de a tipări acele etichete.

### „Recalculează toate QCRI-urile" este o regenerare completă

⚠️ Butonul din partea de jos a filei **Identificatori coduri QR** este
etichetat **Recalculează toate QCRI-urile**, iar confirmarea lui
menționează doar conținuturile QR, dar el rulează exact aceeași generare
pe întregul set de date ca butonul din fila Strategie. Va recalcula și
**codurile de loc** și se va opri să întrebe *Suprascrieți valoarea
existentă?* pentru codurile de loc care s-ar schimba.

Ca să reîmprospătați doar conținuturile după schimbarea lungimii
hash-ului sau a salt-ului: răspundeți **Păstrează-le pe toate la fel**
prima dată când întreabă despre *Identificatorul codului locului* și
**Înlocuiește toate** prima dată când întreabă despre *Identificatorul
resursei codului QR*. Dacă chiar întreabă despre codurile de loc,
opriți-vă și verificați mai întâi setările strategiei: conținuturile pe
care le scrie apoi sunt derivate din **noile** coduri de loc, nu din
cele pe care le-ați păstrat, așa că textul lizibil și pixelii QR ar
înceta să se potrivească.

## Tastarea codurilor manual

Amândouă câmpurile din formularul locului din peșteră stau în spatele
unui lacăt (indiciu *Activează editarea codului QR* / *Dezactivează
editarea codului QR*). Deblocați un câmp ca să tastați în el sau ca să
folosiți butonul lui ✨.

**Nimic din ce tastați nu este verificat față de strategie.** Orice
puneți în câmpul **Identificator cod loc** este stocat exact așa cum a
fost tastat; regulile de cifre, structura segmentelor și comutatorul
**Permite segmente non-numerice** modelează doar codurile pe care
aplicația le *generează* pentru dumneavoastră, iar formularul nu arată
niciun indicator de validitate. Păstrarea codurilor tastate manual în
acord cu tiparul rămâne în sarcina dumneavoastră.

### Editarea unui cod de loc nu îi reîmprospătează conținutul QR

⚠️ La salvare, aplicația derivă conținutul din codul locului **doar când
câmpul QR este gol**. Schimbați manual un cod la un loc care are deja un
conținut și vechiul conținut rămâne pe loc — textul lizibil și pixelii QR
indică atunci lucruri diferite.

După o editare manuală, apăsați ✨ de lângă câmpul **Identificator
resursă cod QR** (sau goliți acel câmp înainte de salvare), ca cele două
să se potrivească din nou.

### Duplicate

- În interiorul unei peșteri, un cod de loc duplicat ridică un dialog
  **Cod QR duplicat** — *Locul „X" folosește deja codul QR Y. Salvați cu
  duplicat?* — și puteți accepta, păstrându-le pe amândouă.
- În fereastra **Adăugare loc peșteră** același duplicat este refuzat din
  start (*Codul QR X este deja folosit de „…"*) și trebuie să îl
  schimbați înainte de salvare.
- Codurile nu sunt niciodată verificate față de *alte* peșteri, așa că
  duplicatele între peșteri trec în tăcere. Scanarea unuia oferă apoi o
  listă de alegere a peșterilor care se potrivesc.
- Conținutul QR *este* verificat pe întregul set de date, dar numai când
  ați editat dumneavoastră câmpul QR, iar acea verificare este tot o
  întrebare de tip salvează-oricum, nu un blocaj.

### Rândul codului de loc poate fi ascuns

Când modul de generare este **Identic cu codul locului** iar codul și
conținutul unui loc sunt identice, formularul ascunde rândul
**Identificator cod loc** ca să economisească spațiu — vedeți doar rândul
QR. Un buton cu ochi de pe rândul ariei peșterii (indiciu **Afișează
codul locului**) îl aduce înapoi când trebuie să editați codul.

### Scanarea în câmpul QR

Butonul de scanare de lângă câmpul **Identificator resursă cod QR** scrie
direct în el un conținut scanat:

- Dacă un alt loc folosește deja acel conținut, primiți un avertisment și
  nu se scrie nimic.
- Dacă în câmp se află deja o altă valoare, **Înlocui codul QR?**
  întreabă mai întâi.
- În modul Identic cu codul locului, când câmpul codului de loc este încă
  gol, valoarea scanată este copiată și în el.

În versiunile pentru dezvoltatori, ținerea apăsată a butonului de
scanare aproximativ 2,5 secunde deschide în schimb **Căutare manuală
cod QR**, pentru a tasta un cod atunci când nu există etichetă de
scanat. Aplicația publicată nu are această scurtătură; butonul de
scanare deschide doar scanerul.

## Tipărirea etichetelor înainte ca locurile să existe

Puteți tipări etichete pentru peșteri și locuri pe care nu le-ați
înregistrat încă. Nimic nu este scris în baza de date — luați etichetele
tipărite în subteran, le montați și înregistrați locurile mai târziu, pe
codurile pe care le-ați tipărit deja.

- Lista locurilor din peșteră → butonul QR cu indiciul **Generează coduri
  QR pentru locuri (interval)** cere un interval **De la indexul** /
  **Până la indexul** și produce codurile pe care acele locuri *le vor*
  primi în această peșteră.
- **Arii de suprafață** → butonul QR de pe rândul unei arii (**Generează
  coduri QR de intrare (interval)**) face același lucru pentru intrările
  principale ale peșterilor numerotate în acea arie.

Amândouă deschid vizualizatorul **Coduri QR generate**, de unde puteți
exporta un PDF și îl puteți tipări — vedeți [Coduri QR](qr-codes.md).

Limite de știut:

- Cel mult **500** coduri per cerere.
- Indecșii care aparțin deja unei peșteri sau unui loc înregistrat sunt
  săriți, iar aplicația vă spune câți.
- Indexul rezervat intrării principale este întotdeauna lăsat în afara
  unui interval de locuri din peșteră.
- Funcționează doar cu **Ierarhic global** și doar după ce codurile de
  țară și de organizație sunt setate (*„Setați mai întâi codurile de țară
  și organizație în setările codurilor."*).
- Pentru un interval de locuri din peșteră, peștera trebuie să aibă deja
  un index local al peșterii (*„Această peșteră nu are încă un index
  local — atribuiți unul mai întâi."*).

## Ce potrivește o scanare

Când scanați un cod QR, tastați un cod în caseta de căutare manuală sau
deschideți un [deep link](deep-links.md) `sp://`, aplicația caută un loc
al cărui **cod de loc** *sau* **conținut QR** se potrivește, ignorând
majusculele și minusculele. Asta are trei consecințe utile:

- Un cod de loc lizibil își găsește locul chiar și după ce treceți la
  conținuturi hash-uite.
- O etichetă mânjită poate fi tastată manual după textul lizibil.
- Același cod poate potrivi locuri din două peșteri diferite, caz în care
  apare o alegere (**Alege punctul / peșteră**). Puteți dezactiva acea
  alegere din **Setări → General → Selectează peștera la scanare QR
  ambiguă**, după care aplicația deschide în tăcere potrivirea din ultima
  peșteră deschisă. Deep link-urile sunt guvernate de propriul comutator
  de lângă el, **Selectează peștera la deep link ambiguu**.

<a id="living-with-printed-labels"></a>

## Viața cu etichete tipărite

1. **Trecerea de la Identic cu codul locului la Hash este suportabilă;
   întoarcerea nu este.** O etichetă tipărită în modul identic poartă
   codul locului, iar o scanare potrivește și codurile de loc, așa că ea
   continuă să funcționeze după ce treceți la hash. O etichetă tipărită
   în modul hash poartă doar hash-ul — odată ce reveniți la Identic cu
   codul locului și recalculați, nimic nu se mai potrivește cu ea și
   trebuie retipărită.
2. **Când regenerați, răspundeți Păstrează-le pe toate la fel** la primul
   mesaj *Suprascrieți valoarea existentă?*, dacă nu sunteți sigur că
   puteți înlocui etichetele fizice. Codurile existente rămân atunci
   neatinse, iar locurile care nu au încă un cod tot primesc unul.
3. **Setați salt-ul de hash o singură dată**, înainte de tipărire.
   Schimbarea lui ulterioară schimbă fiecare conținut hash-uit.
4. Pentru o singură etichetă care a căzut sau a devenit ilizibilă,
   retipăriți **doar acea etichetă**, nu întregul lot.
5. **Un `/` sau un `=` în interiorul codurilor dumneavoastră nu mai
   poate fi reparat după tipărire.** Etichetele care poartă o adresă de
   destinație și au plecat cu astfel de coduri sunt tăiate scurt de
   fiecare scanare, iar nimic din aplicație nu le mai poate salva —
   corectați [separatorul de segmente](#global-hierarchical-default) și
   retipăriți.

## Vezi și

- [Coduri QR — amplasare, scanare, tipărire](qr-codes.md)
- [Locuri din peșteră](cave-places.md)
- [Arii de suprafață](surface-areas.md)
- [Deep link-uri](deep-links.md)
- [Import CSV al locurilor din peșteră](csv-import.md)
- [Setări](settings.md)
