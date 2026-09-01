# Primii pași

[← Înapoi la cuprins](README.md)

Cum se instalează SpeleoLoc, ce vă cere la primele porniri și lucrurile
care merită configurate înainte de a coborî cu telefonul în subteran.

## Instalarea aplicației

SpeleoLoc este construit în primul rând pentru Android; există versiuni și
pentru iOS, Windows, macOS și Linux. Aplicația este în stadiu alfa, așa că
de obicei veți primi un fișier — un APK de Android sau o versiune de
desktop — în loc să o găsiți într-un magazin. Instalați-o ca pe orice altă
aplicație.

Nu mai este nevoie de nimic altceva pentru a începe. SpeleoLoc păstrează
toate datele pe dispozitiv, iar funcțiile din subteran merg complet fără
rețea. O conexiune contează doar pentru descărcarea datelor de exemplu
descrise mai jos, pentru sincronizarea FTP/SFTP și pentru dalele de hartă
online de pe harta peșterilor.

## Aplicația vorbește românește din start

SpeleoLoc este livrat cu **româna** ca limbă implicită. Acest wiki
folosește etichetele în engleză, așa că, dacă vreți ca cele două să se
potrivească, comutați mai întâi aplicația pe engleză:

1. Deschideți **Setări** — pictograma roată din meniul **⋮** sau butonul
   **Setări** din bara de acțiuni a ecranului principal.
2. Deschideți **General**.
3. Apăsați lista derulantă de lângă **Limba aplicației** și alegeți `en`.

Lista derulantă afișează prin coduri cele două limbi cu care vine
aplicația, `ro` și `en`. Ecranele desenate după schimbare apar în noua
limbă, iar alegerea este ținută minte la următoarea pornire.

## Prima pornire

Primul lucru pe care îl vedeți este ecranul principal, intitulat **Speleo
Loc**. Lista lui de peșteri este goală, pentru că aplicația pornește fără
date proprii.

### Oferta de a încărca date de test

Cât timp lista de peșteri este goală, o versiune de dezvoltare sau de test
a SpeleoLoc se oferă să o umple cu un exemplu lucrat:

> **Încărcați date de test?**
> Baza de date este goală. Doriți să o populați cu peșteri și locuri de
> test?

- **Da** aduce arhiva de exemplu, înlocuiește cu ea tot ce este stocat
  acum pe dispozitiv și repornește aplicația. Ajungeți cu peșteri de
  exemplu, locuri din peșteră, hărți cu definițiile lor de puncte și
  documente, toate deja legate între ele — un mod bun de a vedea cum ar
  trebui să arate ecranele înainte de a introduce ceva real.
- **Nu** lasă baza de date goală, ca să vă puteți introduce propriile
  date.

Câteva lucruri merită știute înainte de a răspunde:

- Versiunea publicată, cea dată pe mână pentru speologie obișnuită, nu
  face niciodată această ofertă: uneltele pentru datele de exemplu sunt
  lăsate în afara ei, așa că o instalare nouă pornește pur și simplu cu o
  listă de peșteri goală, iar prima peșteră o introduceți dvs.
- Oferta apare doar cât timp nu există nicio peșteră **și** doar la
  primele patru porniri ale aplicației. După aceea nu mai întreabă.
- **Da este distructiv.** Dacă dispozitivul conține deja hărți sau
  documente — dintr-un import lăsat la jumătate, de pildă — dialogul
  adaugă un avertisment că acestea vor fi șterse definitiv și înlocuite,
  și chiar așa se întâmplă. Nu există anulare.
- Încărcarea arhivei are nevoie de conexiune la internet. Dacă versiunea
  dvs. nu are date de test, nu sunteți întrebat deloc: nu apare niciun
  dialog și nu se afișează niciun mesaj.

Puteți goli oricând baza de date cu **Reinițializați baza de date** din
**Setări → Baza de date**. Reîncărcarea datelor de exemplu din
**Setări → Export / Import Date** este posibilă doar într-o versiune de
dezvoltare sau de test; aplicația publicată nu are o secțiune
**Date de test**. Vedeți
[Export, import și backup al bazei de date](features/database-export-import.md).

## Ce permisiuni cere aplicația

SpeleoLoc nu cere nimic la instalare. Fiecare permisiune este cerută în
momentul în care folosiți prima dată funcția care are nevoie de ea, așa că
un speolog care nu înregistrează niciodată sunet nu este întrebat
niciodată despre microfon.

| Permisiune | Când este cerută | Pentru ce este |
| --- | --- | --- |
| **Cameră** (Camera) | prima scanare sau fotografie | scanarea etichetelor QR, fotografiere |
| **Microfon** (Microphone) | prima înregistrare audio | documente de tip notă audio |
| **Stocare** (Storage) | alegeți **Salvează în Imagini** la exportul unei singure imagini QR și doar pe Android 9 sau mai vechi | scrierea fișierului PNG în folderul comun Imagini |
| **Locație** (Location) | deschideți **Înregistrare punct GPS** sau apăsați **Locația mea** pe harta peșterilor | coordonate GPS pentru intrări și locuri de suprafață |
| **Bluetooth** (scanare și conectare) plus **Locație** | porniți detectarea beaconurilor sau deschideți un selector care scanează etichete din apropiere | găsirea beaconurilor BLE și a etichetelor Ruuvi |
| **Notificări** (Notifications) | porniți **Continuă detectarea în fundal** | alerta ridicată când un beacon este detectat cu aplicația nevăzută |
| **Utilizare nerestricționată a bateriei** (Unrestricted battery usage) | în același moment | ca o scanare să poată rula ore întregi |

Importul în masă de documente și exporturile — arhiva, arhiva de
sincronizare și copia bazei de date — nu cer nicio permisiune: dialogurile
de sistem pentru alegerea folderului și cele de **salvare ca** prin care
treceți poartă cu ele accesul la locul pe care îl alegeți. Folderul ales
pentru un import poate fi citit în întregime, indiferent dacă fișierele
lui sunt sau nu fotografii. Nici **Alege locație…** nu cere nimic, iar pe
Android 10 și mai nou nici **Salvează în Imagini**.

### Dacă refuzați una

Refuzul unei permisiuni dezactivează funcția care a cerut-o și nimic
altceva. Refuzați locația, de exemplu, și **Înregistrare punct GPS** se
deschide pe un panou *Permisiune locație refuzată* cu un buton **Deschide
setări**; toate celelalte ecrane merg mai departe ca înainte.

Dacă refuzați definitiv, sistemul de operare nu mai afișează deloc
cererea. Aplicația observă asta și oferă în schimb o scurtătură — fie un
dialog *Permisiune necesară* cu **Deschide setări**, fie pagina de setări
de sistem deschisă direct — așa că o permisiune la care ați închis ușa
este întotdeauna recuperabilă.

### Pe Android, scanările de beaconuri au nevoie și de comutatorul de localizare pornit

Android leagă *rezultatele* scanărilor Bluetooth de comutatorul de
localizare al dispozitivului. SpeleoLoc nu vă citește niciodată poziția ca
să găsească un beacon, dar cu acel comutator oprit o scanare nu returnează
nimic, în tăcere. Când se întâmplă asta, aplicația explică situația în loc
să pară că s-a blocat:

> **Activează localizarea**
> Pe Android, scanările Bluetooth pentru beaconuri returnează rezultate
> doar când comutatorul de localizare (GPS) al dispozitivului este pornit
> — deși nu se preia nicio poziție GPS. Activează localizarea, apoi
> încearcă din nou asocierea beaconului.

Apăsați **Deschide setări**, porniți localizarea și încercați din nou.
Vedeți [Beaconuri BLE](features/ble-beacons.md).

## Cum vă orientați în aplicație

### Bara de sus

Fiecare ecran are o bară de sus: titlul ecranului în stânga, eventualele
pictograme pentru acțiunile specifice acelui ecran și butonul **⋮** la
capătul din dreapta.

### Meniul aplicației (⋮)

**⋮** deschide meniul aplicației. Implicit, acesta intră din dreapta ca un
sertar; există și o formă compactă, de tip popup, iar pictograma din josul
popup-ului comută înapoi la sertar. Aplicația ține minte pe care dintre
cele două ați folosit-o ultima dată.

În oricare dintre forme, meniul conține acțiunile ecranului pe care vă
aflați, apoi cinci pictograme de navigare care funcționează de oriunde —
**Peșteri**, **Sinc. man.**, **Documente**, **Setări** și **Scanează** —
și **Tur de ghidare**. Forma de sertar adaugă un comutator rapid pentru
detectarea automată a beaconurilor, un card de sincronizare cu ultimul
rezultat FTP/SFTP și un buton de sincronizare imediată, un card pentru
tura în desfășurare atunci când există una, și **Despre** cu numărul
versiunii în partea de jos.

### Ecranul principal

Sub titlu, ecranul principal afișează o bară de acțiuni: un rând de
butoane cu pictograme pentru **Scanează QR**, **Adaugă peșteră nouă**,
**Documente**, **Harta peșterilor**, **Arii de suprafață**, **Import
peșteri din CSV**, **Importă documente în peșteri**, **Setări**, **Sinc.
man.** și **Sincronizare FTP / SFTP**. Sunt doar pictograme — țineți
apăsat pe una ca să îi vedeți numele. **Ascunde bara de acțiuni** din
antetul listei de peșteri strânge rândul la loc, iar aceeași preferință se
află în **Setări → General → Afișează bara de acțiuni pe pagina
principală**. Restul ecranului este lista de peșteri. Vedeți
[Ecranul principal](features/home-screen.md) pentru turul complet.

### Tururile de ghidare

Prima dată când deschideți unul dintre ecranele principale, un tur ghidat
întunecă ecranul și evidențiază pe rând controalele lui. **Omite** încheie
turul curent; **Dezactivează tururile automate** oprește pornirea de la
sine a oricărui tur, lăsându-le disponibile la cerere. Puteți relua
oricând turul unui ecran din **⋮ → Tur de ghidare**, iar
**Setări → General → Resetează tururile de ghidare** face ca toate să se
comporte ca și cum nu le-ați fi văzut niciodată.

## Înainte de a coborî în subteran

1. **Spuneți cine sunteți.** În **Setări → Utilizatori**, adăugați un
   utilizator, apoi apăsați **Selectează** pe rândul dvs. ca să afișeze
   eticheta **Curent**. De atunci înainte, fiecare modificare pe care o
   faceți este marcată cu acea identitate în istoricul modificărilor —
   util după o tură, când cineva întreabă cine a mutat un punct. Vedeți
   [Utilizatori](features/users.md).
2. **Aduceți date pe dispozitiv.** Fie le construiți singur, urmând
   [Documentarea unei peșteri noi](workflows/documenting-a-new-cave.md),
   fie luați o arhivă de la altă echipă: **Setări → Export / Import Date →
   Importă Arhivă**, alegând **Înlocuire totală** sau **Îmbinare cu datele
   existente**. Vedeți
   [Export, import și backup al bazei de date](features/database-export-import.md).
3. **Verificați că hărțile sunt chiar pe telefon.** Hărțile călătoresc în
   interiorul arhivei, dar dalele offline de suprafață nu — vedeți
   [Straturi MBTiles offline](workflows/mbtiles-layers.md).
4. **Încercați o scanare la suprafață**, ca să știți că permisiunea
   camerei și etichetele QR funcționează înainte de a sta în întuneric.
   Vedeți [Coduri QR](features/qr-codes.md).

## Modul de depanare

Apăsarea titlului de pe ecranul principal de nouă ori în succesiune rapidă
— lăsați mai mult de trei secunde între apăsări și numărătoarea o ia de la
capăt — pornește modul ascuns de depanare al aplicației, confirmat de un
mesaj *Debug mode activated*. Douăzeci de apăsări îl opresc la loc, iar
oricum este oprit după următoarea repornire.

Cât timp este activ, în Setări apare o secțiune **Informații depanare**,
care arată calea bazei de date, directorul de date și tabela de
configurații, iar aplicația înregistrează mult mai multe detalii în
jurnal. Într-o versiune de dezvoltare sau de test, **Setări → Baza de
date** capătă în plus și un buton **Deschide executant comenzi SQL**;
aplicația publicată nu îl afișează niciodată, oricum ar fi setat modul de
depanare. Executantul SQL scrie direct în datele dvs., fără confirmare și
fără anulare — lăsați-l în pace dacă nu vă îndrumă cineva printr-o
reparație.

## Câteva convenții folosite în tot wiki-ul

- **Loc din peșteră** înseamnă punctul de interes numit și codificat QR,
  nu doar un ac pe hartă.
- **Hartă** înseamnă imaginea bitmap a unei hărți de peșteră (plan,
  profil, …) importată dintr-un fișier imagine; SpeleoLoc nu desenează el
  însuși hărți.
- **Definiția punctului** este poziția în pixeli care leagă un loc din
  peșteră de o anumită hartă. Același loc din peșteră poate avea o
  definiție de punct diferită pe fiecare hartă pe care apare.

Vocabularul complet în [Glosar](glossary.md).

## Vezi și

- [Prezentare generală](overview.md) — pentru ce este aplicația și ideile
  din spatele ei
- [Ecranul principal](features/home-screen.md) — ecranul de la care
  porniți
- [Setări](features/settings.md) — tot ce se află sub pictograma roată
- [Utilizatori](features/users.md) — alegerea identității de speolog
  curente
- [Export, import și backup al bazei de date](features/database-export-import.md)
- [Documentarea unei peșteri noi](workflows/documenting-a-new-cave.md) —
  prima treabă reală de încercat
