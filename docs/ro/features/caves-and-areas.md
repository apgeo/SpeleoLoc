# Peșteri și zone de peșteră

[← Înapoi la cuprins](../README.md)

O **peșteră** este înregistrarea de nivel superior din SpeleoLoc — locurile,
hărțile, turele, beaconurile și documentele atârnă toate de una. O **zonă de
peșteră** este o zonă denumită *din interiorul* unei singure peșteri, folosită
pentru a-i grupa locurile. Această pagină acoperă crearea, editarea și
ștergerea peșterilor, precum și gestionarea zonelor lor.

## Înregistrarea peșterii

Formularul **Adaugă peșteră nouă** / **Editează peștera** are patru câmpuri:

| Câmp | Observații |
|---|---|
| **Titlul peșterii** | Obligatoriu. Numele afișat peste tot în aplicație. |
| **Descriere** | Text liber, trei rânduri înălțime pe formular. Note de acces, contactul proprietarului de teren, ce echipament să nu uitați — orice nu încape în celelalte câmpuri. |
| **Titlul ariei (opțional)** | [Aria de suprafață](surface-areas.md) căreia îi aparține această peșteră. Alegeți **Niciuna** pentru a o lăsa neatribuită. Pictograma cu peisaj de lângă listă deschide **Arii de suprafață**, ca să puteți adăuga una fără să părăsiți formularul. |
| **Index local peșteră** | Număr scurt opțional care identifică această peșteră în cadrul ariei ei de suprafață. Folosit la construirea codurilor structurate de loc. |

Titlul unei peșteri trebuie să fie unic doar *în cadrul* unei arii de
suprafață. Două peșteri din arii de suprafață diferite pot avea același titlu,
la fel și două peșteri cărora nu le este atribuită nicio arie de suprafață.
Salvarea unei a doua peșteri cu același titlu în aceeași arie de suprafață
eșuează și afișează un mesaj de eroare.

Tot restul care aparține unei peșteri se creează după ea: [locurile din
peșteră](cave-places.md), zonele de peșteră, [hărțile](raster-maps.md),
[turele](trips.md) și punctele de tură înregistrate, asocierile de
[beaconuri BLE](ble-beacons.md) și [documentele](documents.md) legate de ea.

Peștera în sine nu are cod QR și nici cod de loc. Codul QR al intrării aparține
locului din peșteră marcat ca **intrare principală**, iar scanarea lui deschide
acel loc — vedeți [Coduri QR](qr-codes.md).

> 📷 [Alegerea ariei de suprafață pentru o peșteră](../screenshots/01-home-and-caves.md#cave-form-surface-area-picker) — Alegerea ariei de suprafață căreia îi aparține o peșteră, pe formularul peșterii.

### Index local peșteră

Acesta este numărul care identifică peștera în cadrul ariei ei atunci când
aplicația compune coduri structurate de loc (de exemplu `12` dintr-un cod
construit din țară, organizație, arie și peșteră). Contează în trei locuri:

- Strategia ierarhică de coduri de loc îl folosește. Dacă acest câmp este gol
  când generați prima dată coduri pentru peșteră, aplicația alocă singură
  următorul număr liber și îl scrie în câmp.
- Unealta **Generează coduri QR pentru locuri (interval)** din lista de locuri
  a peșterii refuză să ruleze pentru o peșteră fără index local și o spune.
- Unealta **Generează coduri QR de intrare (interval)** din ecranul **Arii de
  suprafață** consideră un număr drept „deja ocupat” când vreo peșteră din acea
  arie îl are ca index local.

Completați-l pentru orice peșteră ale cărei locuri intenționați să le etichetați
cu coduri structurate. Vedeți [Coduri de loc (PCI/QCRI)](place-code-identifiers.md).

## Crearea unei peșteri

### Din ecranul principal

1. Apăsați **⋮ → Adaugă peșteră nouă** sau butonul de adăugare din bara de
   acțiuni a paginii principale (bara este afișată cât timp **Setări → General
   → Afișează bara de acțiuni pe pagina principală** este activ; pictograma de
   bară din antet o ascunde și o arată la rândul ei).
2. Completați **Titlul peșterii** și, opțional, **Descriere**, **Titlul ariei
   (opțional)** și **Index local peșteră**.
3. Apăsați **Adaugă**. La o peșteră existentă, același buton scrie
   **Salvează**.
4. Dacă nu ați dezactivat **Setări → General → Adaugă automat intrarea la
   creare peșteră**, noua peșteră conține deja un loc numit „Intrare”, marcat
   atât ca intrare, cât și ca intrare principală.

### De pe harta peșterilor

1. Deschideți [harta peșterilor](surface-map.md) și apăsați **Adaugă punct**.
2. Alegeți **Peșteră nouă** („Creează o peșteră cu o intrare în acest punct”).
3. Fixați punctul — atingeți harta, apăsați lung pe ea sau folosiți poziția GPS
   curentă — apoi confirmați din bara de jos.
4. Completați **Titlul peșterii** și **Numele intrării** (implicit „Intrare”),
   apoi apăsați **Adaugă**.

Astfel se creează peștera și intrarea ei principală, cu poziție, dintr-un
singur pas. Această cale nu oferă alegerea ariei de suprafață, deci noua
peșteră rămâne neatribuită; setați **Titlul ariei (opțional)** mai târziu,
editând peștera.

> 📷 [Adăugarea unei peșteri sau a unei intrări de pe hartă](../screenshots/02-cave-map.md#cave-map-add-point-menu) — Meniul Adaugă punct, care oferă Peșteră nouă sau Intrare nouă în locul ales.

### Dintr-un fișier CSV

Loturi întregi de peșteri intră prin [importul CSV](csv-import.md) de peșteri,
din **⋮ → Import peșteri din CSV** de pe ecranul principal. Acesta citește o
coloană de arie de suprafață și creează orice arie numită acolo care nu există
încă, iar pentru peșterile care există deja poate completa descrierea, indexul
local și aria de suprafață.

## Editarea unei peșteri

Deschideți peștera din lista ecranului principal, apoi folosiți oricare dintre
meniurile listei de locuri:

- meniul **⋮**, care conține **Editează peștera** și **Șterge peștera**,
  alături de **Începe tura**, **Import locuri din CSV**, **Generează coduri** și
  **Poziționare locuri pe hartă**;
- sau butonul **Peșteră** (căsuță) din bara de instrumente de deasupra listei,
  care conține **Editează peștera**, beaconurile peșterii și **Șterge
  peștera**.

Pe ecranul **Editează peștera** apar două lucruri în plus, care lipsesc cât
timp creați o peșteră:

- o pictogramă **Documente** (dosar) în bara de sus, care deschide navigatorul
  de documente filtrat pe această peșteră, ca să puteți atașa sau citi
  topografii, fotografii, notițe și autorizații fără să ieșiți;
- **⋮ → Generează coduri**, care rulează generarea codurilor de loc pentru
  fiecare loc din această singură peșteră. Cere confirmare și, când locurile au
  deja un cod, întreabă cum să le trateze, înainte de a scrie ceva.

## Ștergerea unei peșteri

Ștergerea unei peșteri este definitivă și nu se poate anula.

**O singură peșteră:** deschideți-o și alegeți **Șterge peștera** din oricare
dintre meniuri, apoi răspundeți *Da* la „Aceasta va șterge peștera. Sigur
doriți să continuați?”.

**Mai multe deodată:** în lista ecranului principal, apăsați pictograma **Mod
selecție** (listă bifată) din antetul listei, bifați peșterile, apoi apăsați
**Șterge selectate**. Urmează trei confirmări una după alta — și rețineți că al
treilea dialog inversează ordinea butoanelor, punând **Șterge** în stânga, așa
că citiți-le în loc să apăsați în același loc. Butonul de ștergere apare doar
cât timp **Setări → General → Permite ștergerea în masă a peșterilor** este
activ, ceea ce este cazul implicit.

> 📷 [Modul selecție în lista de peșteri](../screenshots/01-home-and-caves.md#home-cave-list-selection-mode) — Lista de peșteri de pe ecranul principal în mod selecție, cu două peșteri bifate.

Ștergerea unei peșteri elimină tot ce se află sub ea: locurile din peșteră,
zonele de peșteră, hărțile și pozițiile locurilor marcate pe ele, turele și
punctele de tură înregistrate, precum și asocierile de beaconuri BLE (inclusiv
cele deja dezasociate). Documentele atașate peșterii, zonelor sau locurilor ei
sunt **dezasociate**, dar fișierele rămân în biblioteca de documente a
aplicației.

## Găsirea peșterilor în listă

Lista de peșteri are comenzile comune de filtrare, sortare și selecție descrise
în [Liste: filtrare, sortare și selecție](lists-filter-sort-select.md). Două
dintre ele se comportă specific pentru peșteri:

- Caseta de filtrare caută în titlul peșterii **și** în numele ariei ei de
  suprafață, așa că, scriind numele unei arii, restrângeți lista la peșterile
  din acea arie.
- **Sortează după** oferă **Ultima modificare** (implicit, cele mai noi
  primele), **Titlu**, **Zonă de suprafață** și **Număr de locuri**. Sortarea
  după Titlu grupează rândurile sub titluri de literă inițială; sortarea după
  **Zonă de suprafață** le grupează sub titluri de arie, peșterile neatribuite
  fiind adunate la un loc. Alegerea este reținută între sesiuni.

Pictograma QR din antetul listei generează etichete pentru mai multe peșteri
deodată. Lucrează pe peșterile bifate în modul selecție sau — dacă nu selectați
nimic — pe fiecare peșteră pe care filtrul curent o lasă vizibilă. Când vreuna
dintre acele peșteri conține locuri care nu sunt intrări, întreabă întâi dacă
să producă **Doar intrări** sau **Toate locurile**.

## Zone de peșteră

O **zonă de peșteră** este o zonă denumită *din interiorul* unei singure
peșteri: „Zona intrării”, „Galeria principală”, „Sala lacului”. Zonele de
peșteră sunt:

- opționale — un loc fără zonă este perfect normal;
- doar cu titlu și nimic altceva: dialogul de adăugare/editare cere
  **Introduceți titlul ariei** și nu are alt câmp;
- unice după titlu în cadrul peșterii. Dacă refolosiți un nume, **Salvează**
  pare să nu facă nimic — dialogul rămâne pur și simplu deschis, în loc să
  raporteze conflictul.

La ce folosesc de fapt:

- **Filtrarea listei de locuri.** Scriind numele unei zone în caseta de
  filtrare a listei de locuri din peșteră, găsiți locurile atribuite ei.
- **Gruparea listei de locuri.** Alegerea opțiunii de sortare **Zonă peșteră**
  pune rândurile sub titluri de zonă.
- **Gruparea benzii de locuri de pe o hartă.** Când locurile unei hărți sunt
  sortate după **Zonă peșteră**, banda orizontală de la baza hărții se împarte
  în grupuri etichetate, câte un titlu pentru fiecare zonă, așa că puteți sări
  direct la „Sala lacului” în loc să parcurgeți un singur rând lung. Locurile
  fără zonă sunt adunate sub titlul „—”.

Zonele de peșteră **nu** apar în etichetele QR, în jurnalele de tură și nici în
rapoartele de tură exportate.

### Gestionarea zonelor de peșteră

Deschideți peștera, apoi apăsați pictograma **straturi** din bara de
instrumente de deasupra listei de locuri — indiciul ei scrie *Zonele peșterii*.
Aceeași pictogramă stă lângă lista derulantă **Titlul ariei (opțional)** cât
timp adăugați sau editați un loc din peșteră, ca să puteți crea o zonă lipsă
fără să pierdeți ce ați completat.

Ecranul se numește **Zonele peșterii**. De acolo:

- **+** din bara de sus deschide **Adaugă arie** — scrieți un titlu și
  **Salvează**.
- Pictograma creion de pe un rând redenumește zona.
- Pictograma coș o șterge, după „Aceasta va șterge aria. Sigur doriți să
  continuați?”.

### Ștergerea unei zone încă folosite

O zonă poate fi ștearsă doar după ce **niciun loc din peșteră nu îi mai este
atribuit**. Deschideți întâi acele locuri și readuceți **Titlul ariei
(opțional)** la *Niciuna*.

Ștergerea unei zone încă folosite eșuează în prezent în tăcere: dialogul de
confirmare se închide, nu apare niciun mesaj, iar zona rămâne în listă după
aceea. Dacă o ștergere pare să nu facă nimic, acesta este motivul.

### Atribuirea unui loc la o zonă

Există trei căi și niciuna de a reatribui mai multe locuri existente deodată:

- Pe formularul locului din peșteră, lista derulantă **Titlul ariei
  (opțional)**. Ștergerea unei zone deja setate întreabă întâi „Șterge aria
  atribuită acestui loc?”.
- În fereastra **Adăugare loc peșteră** pe care o primiți când adăugați un loc
  atingând o hartă, unde aceeași listă derulantă se numește **Zonă peșteră**.
- În masă, prin [importul CSV](csv-import.md) al locurilor din peșteră, a cărui
  coloană **Zonă peșteră** creează orice zonă care nu există încă în peșteră.
  Potrivirea nu ține cont de majuscule, așa că „Galeria principală” și „galeria
  principală” ajung în aceeași zonă.

## Zonă de peșteră sau arie de suprafață?

Sunt independente, iar majoritatea lucrărilor de documentare ajung să le
folosească pe amândouă.

| | Zonă peșteră | Arie de suprafață |
|---|---|---|
| Unde | În subteran, în interiorul unei singure peșteri | La suprafață, pe o regiune întreagă |
| Grupează | Locurile din acea peșteră | Peșteri |
| Câmpuri | Titlu | Titlu, identificator zonă generală, descriere |
| Gestionată din | Pictograma straturi de deasupra listei de locuri a unei peșteri | **Arii de suprafață** — **⋮** de pe ecranul principal, bara de acțiuni a paginii principale sau pictograma cu peisaj de pe formularul peșterii |

Doar aria de suprafață alimentează codurile structurate de loc, prin
identificatorul ei de zonă generală — vedeți [Arii de suprafață](surface-areas.md).

## Vezi și

- [Locuri din peșteră](cave-places.md)
- [Arii de suprafață](surface-areas.md)
- [Ecranul principal](home-screen.md)
- [Coduri de loc (PCI/QCRI)](place-code-identifiers.md)
- [Hărți](raster-maps.md)
- [Documentarea unei peșteri noi](../workflows/documenting-a-new-cave.md)
