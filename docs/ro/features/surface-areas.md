# Arii de suprafață

[← Înapoi la cuprins](../README.md)

O **arie de suprafață** este o regiune denumită de la suprafață — un platou
carstic, un masiv, o vale — folosită pentru a grupa peșterile. Tot aici
păstrează aplicația codul scurt de arie din care se construiesc
[codurile de loc](place-code-identifiers.md) structurate, și tot aici stau
două unelte de generare a codurilor care lucrează pe o regiune întreagă
deodată.

## Ce face o arie de suprafață pentru dumneavoastră

- Grupează peșterile în lista principală: puteți sorta și grupa lista de
  peșteri după aria de suprafață, iar titlul ariei apare cu gri sub
  titlul fiecărei peșteri.
- Restrânge caseta de filtrare: dacă tastați numele unei arii în filtrul
  listei de peșteri, rămân doar peșterile din acea arie.
- Furnizează **segmentul de arie** al fiecărui cod de loc structurat
  generat pentru peșterile din ea.
- Vă dă un loc de unde rulați generarea codurilor pentru o regiune
  întreagă deodată și de unde pre-tipăriți etichete de intrare pentru
  peșteri pe care nu le-ați înregistrat încă.

Ariile de suprafață sunt **opționale** pentru răsfoirea și organizarea
peșterilor — puteți folosi aplicația fără să creați nici măcar una. Ele
încetează să fie opționale din momentul în care folosiți coduri de loc
structurate:

- Strategia **Secvențial per zonă** sare peste o peșteră fără arie de
  suprafață la generarea în lot și refuză să accepte un cod tastat manual
  pentru ea (**Această peșteră nu are zonă de suprafață atribuită**).
- Strategia **Ierarhic global** nu sare peste o astfel de peșteră; pune în
  schimb un segment de arie de rezervă — numai zerouri când peștera nu are
  arie de suprafață, numai cifre de nouă când aria există, dar nu are
  identificator zonă generală. **Sumar generare**, la finalul lotului,
  arată câte peșteri și câte locuri au primit fiecare valoare de rezervă.
  Acele coduri nu se vor potrivi cu restul setului dumneavoastră de date.

## Câmpuri

| Câmp | Observații |
|---|---|
| **Introduceți titlul ariei de suprafață** | Obligatoriu și unic în toată baza de date — două arii nu pot avea același titlu. |
| **Identificator zonă generală** | Codul scurt (de exemplu `07`) pe care strategia Ierarhic global îl inserează în codul de loc al fiecărei peșteri din această arie. |
| **Descriere** | Text liber. Apare cu litere mici gri sub titlu, în lista ariilor de suprafață. |

Identificatorul se inserează în codul de loc **exact așa cum îl tastați** —
nu este completat cu zerouri în față. Dacă **Setări → Identificatori cod
loc → Nr. cifre identificator zonă generală** este 3, tastați `007`, nu
`7`, altfel codurile ies cu o cifră mai scurte. Lăsați identificatorul gol
doar dacă nu folosiți coduri de loc structurate.

Setați identificatorul **înainte** de a genera coduri pentru vreo peșteră
din arie. Schimbarea lui ulterioară schimbă codurile generate de atunci
înainte, ceea ce invalidează etichetele deja tipărite.

## Deschiderea ecranului ariilor de suprafață

Sunt trei căi de intrare, toate ducând la același ecran **Arii de
suprafață**:

- **Ecranul principal (Home) → ⋮ → Arii de suprafață**.
- Pictograma cu peisaj din bara de acțiuni a ecranului principal. Bara
  este afișată implicit și se ascunde sau se readuce cu butonul **Ascunde
  bara de acțiuni** / **Afișează bara de acțiuni** din antetul listei de
  peșteri.
- Pictograma cu peisaj de lângă lista derulantă **Titlul ariei (opțional)**
  din formularul **Adaugă peșteră nouă** / **Editează peștera**. Aceasta
  este calea utilă în timp ce introduceți o peșteră: la întoarcere lista
  derulantă a fost reîncărcată, iar aria tocmai creată poate fi aleasă pe
  loc.

> 📷 [Gestionarea ariilor de suprafață](../screenshots/01-home-and-caves.md#surface-areas-list) — Lista ariilor de suprafață, unde se creează și se editează regiunile care grupează peșterile.

Fiecare rând din listă arată titlul ariei cu descrierea dedesubt și are
propriile pictograme la capătul din dreapta: o pictogramă QR (**Generează
coduri QR de intrare (interval)**), un creion (editare) și un coș
(ștergere), plus o pictogramă baghetă atunci când pictogramele de generare
sunt pornite.

## Adăugarea, editarea și ștergerea ariilor

### Adăugarea unei arii

1. Apăsați pictograma **+** din bara de sus.
2. Completați **Introduceți titlul ariei de suprafață** și — dacă folosiți
   coduri de loc structurate — **Identificator zonă generală**.
3. Adăugați o **Descriere**, dacă doriți una.
4. Apăsați **Salvează**. Mesajul *Aria de suprafață a fost salvată*
   confirmă operațiunea.

Dacă lăsați titlul gol, **Salvează** nu face nimic. La fel se întâmplă
dacă titlul este deja luat de altă arie: dialogul pur și simplu rămâne
deschis, așa că schimbați titlul și salvați din nou.

### Editarea unei arii

Apăsați pictograma **creion** de la capătul din dreapta al rândului.
Apăsarea rândului în sine nu face nimic. Dialogul are aceleași trei
câmpuri, precompletate, plus un buton **Generează coduri** (vedeți mai
jos).

### Ștergerea unei arii

Apăsați pictograma **coș** și confirmați. Ștergerea unei arii nu poate fi
anulată — aria este scoasă din baza de date, nu arhivată, iar scoaterea
ajunge pe celelalte dispozitive la următoarea sincronizare.

O arie poate fi ștearsă doar când **nicio peșteră nu îi mai este
atribuită**. Mutați întâi acele peșteri în altă parte sau puneți-le
**Titlul ariei (opțional)** înapoi pe *Niciuna*. Ștergerea unei arii încă
folosite eșuează deocamdată fără să vă spună: confirmarea se închide, nu
apare niciun mesaj, iar aria este tot în listă. Dacă se întâmplă asta,
acesta este motivul.

Ștergerea unei arii nu șterge niciodată peșterile din ea.

> Notă: textul de confirmare de pe acest ecran spune *„Aceasta va șterge
> aria. Sigur doriți să continuați?”*. Este formularea dialogului de zonă
> peșteră, refolosită; dumneavoastră ștergeți aria de suprafață pe care
> ați apăsat-o.

## Atribuirea unei peșteri la o arie de suprafață

Când **creați** o peșteră — **Ecranul principal → ⋮ → Adaugă peșteră
nouă**, sau pictograma de adăugare peșteră din ecranul principal — alegeți
aria din lista derulantă **Titlul ariei (opțional)**. Lista derulantă
pornește pe **Niciuna**.

Când **editați** o peșteră: apăsați peștera din lista principală ca să
deschideți lista ei de locuri, apoi **⋮ → Editează peștera**, și alegeți
din aceeași listă derulantă.

> 📷 [Alegerea ariei de suprafață pentru o peșteră](../screenshots/01-home-and-caves.md#cave-form-surface-area-picker) — Alegerea ariei de suprafață căreia îi aparține o peșteră, în formularul peșterii.

Două lucruri de știut:

- O peșteră lăsată pe **Harta peșterilor** cu **Peșteră nouă** este creată
  fără arie de suprafață. Deschideți-o și editați peștera ca să îi
  atribuiți una.
- Importul CSV de peșteri creează ariile în locul dumneavoastră. Mapați o
  coloană **Zona de suprafață** și/sau **Identificator zonă generală**, și
  orice arie numită acolo care nu există încă este creată în timpul
  importului; sumarul rezultatului le numără la **Zone de suprafață
  create**. Potrivirea nu ține cont de majuscule, așa că „Padiș” și
  „padiș” ajung în aceeași arie. Un identificator din fișier este scris și
  pe o arie existentă cu acel titlu care nu are niciunul — dar un
  identificator diferit de cel deja stocat nu este niciodată suprascris.
  Vedeți [Import CSV](csv-import.md).

## Ariile de suprafață în lista de peșteri

Butonul de sortare al listei de peșteri oferă **Ultima modificare**
(implicit, cele mai noi primele), **Titlu**, **Zonă de suprafață** și
**Număr de locuri**. Sortarea după **Zonă de suprafață** rupe lista în
titluri de secțiune, unul pentru fiecare arie, cu peșterile fără arie
adunate sub un titlu **—**. Alegerea de sortare este ținută minte între
sesiuni. Vedeți
[Liste: filtrare, sortare și selecție](lists-filter-sort-select.md).

## Generarea codurilor de loc pentru o arie întreagă

Ecranul ariilor de suprafață poate genera coduri de loc pentru fiecare loc
din fiecare peșteră a unei arii, într-o singură rulare. Două căi de
intrare:

- Deschideți aria cu pictograma **creion** și apăsați **Generează coduri**
  în dialog.
- Porniți **⋮ → Afișează pictogramele de generare**, ceea ce adaugă o
  pictogramă **baghetă** pe fiecare rând, și apăsați bagheta de pe aria
  dorită. Comutatorul este oprit din nou de fiecare dată când deschideți
  ecranul, așa că pictogramele de pe rânduri sunt ascunse implicit.

În ambele feluri, rularea decurge așa:

1. O confirmare — *Generați coduri pentru toate locurile din peșterile
   acestei zone de suprafață?* — cu **Anulează** și **Generează coduri**.
2. Un dialog de progres cât timp rulează lotul.
3. Ori de câte ori un loc are deja un cod diferit de cel nou calculat, o
   întrebare **Suprascrieți valoarea existentă?** care arată valoarea
   existentă și pe cea nouă, cu **Păstrează**, **Păstrează-le pe toate la
   fel**, **Înlocuiește**, **Înlocuiește toate** și **Anulează procesul**.
4. Un **Sumar generare**: câte locuri au fost actualizate, sărite,
   refuzate, câte coduri existente au fost suprascrise, cât a durat și
   care peșteri au căzut pe un segment de arie cu zerouri sau cu nouă.

Aceasta scrie în baza de date. Codurile deja tipărite pe etichete nu se
mai potrivesc dacă le înlocuiți, așa că folosiți **Păstrează** dacă nu
aveți de gând să reetichetați.

Aceeași unealtă de lot este disponibilă la nivelul unei singure peșteri,
din ecranul **Editează peștera**, la **⋮ → Generează coduri**.

## Generează coduri QR de intrare (interval)

Pictograma QR de pe fiecare rând de arie pre-tipărește etichete de intrare
principală pentru peșteri care nu există încă în aplicație — utilă
înaintea unei ture de cartare, când știți că veți marca un șir de intrări
noi în teren.

1. Apăsați pictograma QR de pe rândul ariei.
2. Introduceți **De la indexul** și **Până la indexul** — numerele de
   peșteri pentru care vreți etichete. Ambele trebuie să fie cel puțin 1,
   începutul nu poate trece de sfârșit, iar o singură rulare este limitată
   la 500 de coduri.
3. Apăsați **OK**.

Aplicația compune un cod de intrare principală pentru fiecare număr din
acel interval care nu are încă o peșteră înregistrată, vă spune câte a
sărit pentru că sunt deja luate și deschide ecranul **Coduri QR generate**,
ca să puteți exporta și tipări planșa. Două arii care au același
identificator zonă generală împart un singur set de numere de peșteri, așa
că un număr folosit în oricare dintre ele contează ca luat.

**Nu se scrie nimic în baza de date.** Aceste coduri sunt compuse pe loc;
peșterile în sine urmează să fie create, iar fiecare va prelua codul
potrivit odată ce o înregistrați cu același **Index local peșteră**.

Această unealtă are nevoie de strategia **Ierarhic global**, cu **Cod
țară** și **Cod organizație** completate la **Setări → Identificatori cod
loc**. Cu orice altă strategie spune *Pre-generarea pe interval este
disponibilă doar cu strategia ierarhică de coduri.*; când lipsesc codurile
spune *Setați mai întâi codurile de țară și organizație în setările
codurilor.* Dacă fiecare număr din interval este deja luat, vă spune asta
în loc să deschidă o planșă goală.

## Arie de suprafață vs zonă peșteră

- O **arie de suprafață** este la suprafață și grupează **peșteri**. Stă
  în **Arii de suprafață** și este comună întregii baze de date.
- O **zonă peșteră** este în subteran și grupează **locurile din peșteră**
  dintr-o singură peșteră. Stă pe ecranul **Zonele peșterii** din acea
  peșteră.

Cele două sunt independente și pot fi folosite împreună. Vedeți
[Peșteri și zone de peșteră](caves-and-areas.md).

## Vezi și

- [Peșteri și zone de peșteră](caves-and-areas.md)
- [Coduri de loc (PCI) și conținut QR (QCRI)](place-code-identifiers.md)
- [Ecranul principal](home-screen.md)
- [Liste: filtrare, sortare și selecție](lists-filter-sort-select.md)
- [Import CSV](csv-import.md)
- [Coduri QR](qr-codes.md)
