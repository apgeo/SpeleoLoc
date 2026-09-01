# Setări

[← Înapoi la cuprins](../README.md)

Setările adună într-o singură listă de subpagini toate preferințele
globale și acțiunile de gestionare a datelor. Pagina de față este harta
acelei liste: ce conține fiecare intrare și unde se află descrierea ei
completă.

## Deschiderea setărilor

Deschideți **Setări** din meniul ⋮ al barei de sus, prezent pe aproape
orice ecran. Dacă **Afișează bara de acțiuni pe pagina principală** este
activă, pagina principală arată în bara ei și un buton cu rotiță care
duce direct acolo.

Fiecare alegere făcută în Setări este păstrată de aplicație și
supraviețuiește unei reporniri. Cele mai multe rămân pe dispozitiv;
excepție fac strategia codurilor de loc și setările identificatorului de
resursă al codului QR — acestea călătoresc în arhivele de sincronizare,
așa că o echipă poate folosi în comun aceeași schemă de numerotare.

## Lista de setări

Lista respectă ordinea din aplicație.

| Intrare | Ce cuprinde |
|---|---|
| **General** | Limba și preferințe generale |
| **Compresie imagini** | Comprimă și redimensionează imaginile la import |
| **Generare grafică cod QR** | Dimensiune QR, culori, corecția erorilor |
| **Identificatori cod loc** | Strategie, reguli și mod generare pentru codurile locurilor din peșteri și coduri QR |
| **Ieșire PDF** | Aranjare grilă, șablon etichetă |
| **Hartă** | Straturile hărții de suprafață și fișierele MBTiles offline |
| **Baza de date** | Reinițializare, export baza de date |
| **Utilizatori** | Gestionează utilizatorii și selectează utilizatorul curent |
| **Sinc. man.** | Schimbă date cu alte dispozitive prin fișiere arhivă |
| **Sincronizare FTP / SFTP** | Sincronizează printr-un server FTP sau SFTP partajat |
| **Server de club (SilexGIS)** | Sincronizează peșterile cu o instalare SilexGIS a clubului |
| **Export / Import Date** | Exportă sau importă toate datele aplicației |
| **Detectare beaconuri** | Detectare automată a locurilor prin beaconuri BLE, praguri, diagnostic |
| **Informații depanare** *(doar în modul depanare)* | Calea bazei de date, directorul de date, tabela configurații |

> 📷 [Întreaga listă de setări](../screenshots/07-settings.md#settings-main-full) — Meniul Setări complet, toate cele douăsprezece categorii într-o singură captură.

## General

- **Limba aplicației** — o listă derulantă cu limbile livrate împreună cu
  aplicația, trecute prin codurile lor de două litere: `en` (engleză) și
  `ro` (română). Aplicația pornește în română, așa că de aici treceți pe
  engleză. Alegerea are efect imediat — nu repornește nimic — iar un
  ecran rămas deschis în spatele Setărilor arată noua limbă de îndată ce
  reveniți la el.
- **Afișează bara de acțiuni pe pagina principală** — arată butoanele de
  scanare / adăugare / documente / setări într-o bară pe pagina
  principală. Cu opțiunea dezactivată, **Scanează QR**, **Adaugă peșteră
  nouă** și **Sincronizare FTP / SFTP** urcă în bara de sus; meniul ⋮
  conține aceleași intrări în ambele cazuri. Butonul mic de bară de
  deasupra listei de peșteri („Afișează bara de acțiuni" / „Ascunde bara
  de acțiuni") comută aceeași setare fără să mai treceți pe aici.
- **Adaugă automat intrarea la creare peșteră** — creează automat un loc
  de tip intrare ori de câte ori adăugați o peșteră nouă. Activată
  implicit; dezactivați-o dacă preferați să creați singuri intrarea.
- **Permite ștergerea în masă a peșterilor** — afișează un buton de
  ștergere în modul de selecție al listei de peșteri de pe pagina
  principală, astfel încât toate peșterile selectate să poată fi șterse
  dintr-o dată. Dezactivați-o pentru a reduce riscul unei ștergeri
  masive accidentale. Nu are efect asupra zonelor peșteră sau a
  locurilor din peșteră.
- **Selectează peștera la scanare QR ambiguă** — când un cod scanat se
  potrivește cu locuri din mai multe peșteri, un dialog întreabă la care
  v-ați referit. Cu opțiunea dezactivată, aplicația deschide în tăcere
  potrivirea din peștera deschisă ultima dată.
- **Selectează peștera la deep link ambiguu** — aceeași regulă pentru
  linkurile `sp://` deschise din afara aplicației. Vedeți
  [Linkuri directe](deep-links.md).
- **Resetează tururile de ghidare** — șterge marcajul „deja afișat" al
  fiecărui tur de ghidare, astfel încât explicațiile de la prima vizită
  apar din nou data viitoare când deschideți fiecare ecran. Un mesaj
  confirmă: „Toate tururile de ghidare au fost resetate".

## Compresie imagini

Controlează comprimarea și redimensionarea aplicate fotografiilor pe
măsură ce sunt făcute sau importate.

- **Activează comprimarea imaginilor** — comutatorul principal. Cât timp
  este oprit, originalele se păstrează neatinse, iar restul paginii este
  estompat.
- **Profil de comprimare** — **Reducere scăzută**, **Reducere medie**,
  **Reducere mare**, **Reducere foarte mare** sau **Manual**.
- **Rezoluție maximă (px)** și **Calitate imagine (%)** — pot fi
  modificate doar când profilul este **Manual**. Cu oricare profil
  predefinit, cele două câmpuri sunt estompate, iar valorile produse de
  acel profil sunt afișate dedesubt ca text needitabil.

Reduceți-o pentru expediții lungi, când spațiul de stocare este strâmt;
creșteți-o pentru calitate de arhivă.

## Generare grafică cod QR

Controlează felul în care sunt produse etichetele QR și felul în care
sunt citite codurile scanate.

- **Ieșire QR** — dacă tipărirea produce un **PDF** sau **Imagini**.
- **Dimensiune QR (px)** și **Spațiu imagine QR (px)**.
- **Dimensiune font etichetă** și **Familie font etichetă**.
- **Culoare fond QR** și **Culoare prim-plan QR** — se introduc ca
  valori `0xAARRGGBB`, cu un eșantion de culoare pe care îl puteți apăsa
  pentru a alege.
- **DPI (calitate)**.
- **Corecția erorii** — L, M, Q sau H. O valoare mai mare tolerează mai
  multe deteriorări ale etichetei tipărite, dar face codul mai dens.
  Modulele QR sunt întotdeauna pătrate; nu există o setare de formă.
- **Exportă imaginile ca zip** — adună imaginile generate într-un singur
  fișier zip, în loc să le scrie separat. Mai ușor de mutat de pe
  telefon.
- **Include prefix deep link** — scrie `sp://` în valoarea codificată.
  `sp://` este schema de linkuri proprie SpeleoLoc, așa că un telefon
  fără SpeleoLoc nu obține nimic utilizabil dintr-o astfel de etichetă.
  Cu opțiunea dezactivată, codul poartă identificatorul simplu, forma
  care trebuie tipărită atunci când aceleași etichete sunt citite și de
  un alt sistem. Scanerul propriu al aplicației le citește pe amândouă.
- **Adresa de destinație pentru etichetele tipărite** — adresa serverului
  clubului dumneavoastră, pentru etichetele tipărite, de exemplu
  `https://speo.example.org/q/`: codul poartă atunci acea adresă plus
  identificatorul, așa că se deschide din camera oricărui telefon, iar
  SpeleoLoc îl citește în continuare. Goală implicit, iar cât timp una este
  stabilită, ea are întâietate față de **Include prefix deep link**, care
  rămâne estompat. Vedeți [Coduri QR](qr-codes.md).
- **Spațiere cod QR în PDF (pt)** — **Spațiere orizontală** și
  **Spațiere verticală** între etichetele tipărite. Rețineți că această
  setare se află aici, nu în pagina Ieșire PDF.
- **Șablon etichetă cod QR** — ce se tipărește sub fiecare cod, cu lista
  variabilelor disponibile și a codurilor de formatare afișată sub câmp.
  Vedeți [Coduri QR](qr-codes.md).

### Setări scanare QR

La baza aceleiași pagini, acest grup decide cum sunt citite codurile
făcute de alte sisteme:

- **Extrage identificatorul din URL** — când un cod scanat este o adresă
  HTTP sau HTTPS, doar partea de după ultimul caracter delimitator este
  folosită drept identificator.
- **Caractere delimitatoare URL** — lista caracterelor individuale care
  contează drept delimitatori, separate prin virgulă sau spațiu (de
  exemplu `/, =`). Câmpul apare doar cât timp extragerea este activă.

> 📷 [Setările de generare QR](../screenshots/04-places-and-qr-codes.md#settings-qr-generation) — Setările care controlează felul în care etichetele QR sunt redate și scanate.

## Identificatori cod loc

Două file, fiecare cu propria acțiune care rulează peste întregul set de
date.

**Strategie** — alegeți modul de alocare din lista **Strategie de
generare / alocare a codurilor locurilor din peșteră și a codurilor
peșterilor** și stabiliți-i regulile. Sub listă stă o descriere scurtă,
iar **Mai multe informații** deschide explicația completă.

- **Ierarhic global** — **Cod țară**, **Cod organizație**, **Nr. cifre
  identificator zonă generală**, **Nr. cifre index local peșteră**,
  **Nr. cifre index local loc**, **Sufix intrare principală**,
  **Separator segmente** și **Permite segmente non-numerice**. Un `/` sau un
  `=` în **Separator segmente** trunchiază orice cod tipărit atunci când este
  scanat înapoi; câmpul vă avertizează, dar nimic nu vă împiedică să îl
  salvați. Vedeți [Coduri de loc (PCI) și conținutul codurilor QR
  (QCRI)](place-code-identifiers.md).
- **Secvențial per peșteră** și **Secvențial per zonă** — **Începe de
  la**, **Pas**, **Nr. cifre umplere cu zerouri** și **Intrarea
  principală prima**.

**Generează coduri pentru întregul set de date** alocă un cod fiecărui
loc din peșteră.

**Identificatori coduri QR** — stabilește **Identificator cod QR**, fie
**Identic cu codul locului**, fie **Hash (identificator scurt derivat)**,
cu **Lungime hash**, **Salt hash** și, în modul identic, **Hash pentru
intrări**. Un exemplu lucrat, sub câmpuri, previzualizează rezultatul.
**Recalculează toate QCRI-urile** reconstruiește conținutul QR al
fiecărui loc din peșteră cu modul curent.

Ambele acțiuni la nivel de set de date cer mai întâi o confirmare, apoi
întreabă ce să facă de fiecare dată când sunt pe cale să suprascrie o
valoare deja existentă. Recalcularea schimbă conținutul codurilor, așa
că etichetele QR deja tipărite nu mai corespund — tipăriți-le din nou.

Vedeți [Coduri de loc (PCI) și conținutul codurilor QR
(QCRI)](place-code-identifiers.md).

## Ieșire PDF

Un singur grup, **Coduri QR pe pagină**: **Coloane** (1–10) și
**Rânduri** (1–20), fiecare stabilit cu un buton pas cu pas sau prin
tastarea numărului.

Spațierea dintre etichetele tipărite și șablonul etichetei se află în
pagina Generare grafică cod QR, nu aici.

## Hartă

- **Formatul de afișare a coordonatelor** — cum sunt scrise pozițiile în
  toată aplicația: **Grade zecimale** (implicit), **Grade, minute,
  secunde (DMS)** sau **UTM**. Schimbă doar afișarea — cardul de
  informații și bara de amplasare ale hărții de suprafață, plus linia
  formatată suplimentară de sub latitudinea și longitudinea unui loc din
  peșteră. Câmpurile de introducere rămân în grade zecimale, iar
  introducerea coordonatelor acceptă toate cele trei formate, indiferent
  de această setare. Afișarea UTM revine la grade zecimale pentru
  pozițiile aflate dincolo de aproximativ 80° S / 84° N. Vedeți [GPS și
  coordonate](gps-and-coordinates.md).
- **Stochează hărțile online** — păstrează pe dispozitiv dalele
  descărcate ale hărții de bază, astfel încât zonele vizitate să
  funcționeze și în subteran sau fără semnal. Rândul **Cache-ul de
  hartă** de dedesubt arată cât spațiu ocupă și are un buton de golire.
- **Încărcare automată MBTiles** — oferă ca straturi de hartă fișierele
  de hartă offline găsite în folderul MBTiles al aplicației.
- **Folder MBTiles** — folderul în care se copiază fișierele `.mbtiles`,
  cu un buton de copiere a căii și o explicație a ce anume îi aparține.
  Doar fișiere raster; fișierele vectoriale sunt listate, dar nu pot fi
  desenate.
- **Importă fișier MBTiles** — căutați un fișier și copiați-l înăuntru.
  Dacă acolo există deja un fișier cu același nume, aplicația întreabă
  înainte de a-l suprascrie.
- **Fișiere detectate** — fiecare fișier găsit. Fiecare fișier raster
  are o listă derulantă prin care se alege dacă este folosit ca **Hartă
  de bază** sau ca **Suprapunere**; un fișier vectorial este trecut ca
  nesuportat și nu are listă derulantă. Bara de sus are și un buton de
  rescanare.

Vedeți [Harta peșterii](surface-map.md) și [Straturi
MBTiles](../workflows/mbtiles-layers.md).

## Baza de date

Uneltele brutale. Tot ce se află aici, în afară de **Exportă baza de
date**, distruge date care nu sunt salvate în altă parte.

- **Reinițializează baza de date cu date de test** — șterge tot și umple
  baza de date cu setul de date exemplu inclus în aplicație.
- **Reinițializați baza de date** — șterge tot și lasă o bază de date
  goală.
- **Restaurează baza de date din fișier** — înlocuiește baza de date
  curentă cu un fișier `.sqlite` sau `.db` ales de dumneavoastră.
- **Exportă baza de date** — salvează o copie a fișierului bazei de date
  într-un folder ales de dumneavoastră, cu numele
  `speleo_loc_export.sqlite`. Este instantaneul rapid pe care să îl
  faceți înainte de orice operațiune riscantă și este exact ce așteaptă
  înapoi **Restaurează baza de date din fișier**. Conține doar baza de
  date: fotografiile, documentele și imaginile hărților nu sunt în ea,
  așa că pentru o copie de siguranță completă folosiți Export / Import
  Date.
- **Deschide executant comenzi SQL** *(doar în modul depanare)* —
  rulează comenzi SQL direct pe baza de date locală. Nimic de aici nu
  este verificat și nimic nu se poate anula.

Cele două acțiuni de reinițializare cer confirmarea de **două ori**.
Restaurarea întreabă **o singură dată** și apoi deschide selectorul de
fișiere — așa că o restaurare este mai ușor de declanșat decât o
reinițializare și este la fel de ireversibilă. Prima confirmare a
fiecăreia dintre aceste acțiuni avertizează că aplicația va fi
repornită, iar aceasta chiar repornește automat odată ce operațiunea se
încheie.

Vedeți [Export, import și copie de siguranță a bazei de
date](database-export-import.md).

## Utilizatori

Lista identităților de speologi folosite pentru atribuirea modificărilor
și selectorul utilizatorului curent. Vedeți [Utilizatori](users.md).

## Sinc. man.

Schimb manual de date, prin fișiere, cu alte dispozitive. Două file:
**Arhivă sincronizare**, care produce și importă arhive de sincronizare,
și **Istoric modificări**, evidența needitabilă a ce s-a schimbat și
cine a schimbat. Vedeți [Panoul de sincronizare și istoricul
modificărilor](sync-and-change-log.md).

## Sincronizare FTP / SFTP

Gestionează doar profilurile de conexiune: adăugați un profil, editați
sau ștergeți unul, rulați **Testează conexiunea** și marcați unul ca
implicit cu **Setează ca implicit** din meniul lui ⋮. Rulările de
sincronizare propriu-zise pornesc din pagina principală sau din cardul
de sincronizare FTP din meniul aplicației, nu din această pagină.
Vedeți [Sincronizare FTP / SFTP](ftp-sync.md).

> 📷 [Lista profilurilor FTP](../screenshots/06-sync-and-sharing.md#ftp-sync-profile-list) — Ecranul de setări Sincronizare FTP / SFTP, cu profilurile de server configurate.

## Server de club (SilexGIS)

Conexiunea cu un registru de peșteri pe care clubul dumneavoastră îl
ține pe propriul server: adăugați serverul, vă autentificați, alegeți
peșterile purtate de dispozitiv și porniți o rulare. Circulă doar
peșterile, zonele peșteră, locurile din peșteră și ariile de suprafață —
documentele, fotografiile, hărțile raster, turele și istoricul
modificărilor nu. Spre deosebire de sincronizarea FTP, nu există niciun
buton pentru ea altundeva în aplicație, așa că o sincronizare are loc
doar când o cereți de aici. Este o lucrare recentă, cu asperități, și
merită folosită doar dacă clubul dumneavoastră are deja o astfel de
instalare. Vedeți [Sincronizare cu serverul de club](silexgis-sync.md).

## Export / Import Date

Export și import complet al bazei de date, împreună cu fișierele ei.

- **Setări export** — **Include fișiere documentație**, **Include
  imagini hărți** și **Export diferențial (doar fișiere noi)**, care
  împachetează doar fișierele adăugate de la ultimul export complet.
  **Exportă Arhivă** cere apoi folderul de destinație. Parolele FTP
  salvate nu sunt scrise niciodată într-o arhivă exportată.
- **Import** — **Importă Arhivă** citește o arhivă înapoi, întrebând
  dacă să înlocuiască sau să îmbine și cerând o decizie la fiecare
  conflict.
- **Date de test** — **Descarcă date de test** aduce setul de date
  exemplu și înlocuiește cu el tot ce aveți acum, după o confirmare.
  Această secțiune face ceva doar în versiunile compilate cu o adresă
  pentru datele de test; altfel afișează un avertisment că URL-ul
  arhivei cu date de test nu este configurat.

Vedeți [Export, import și copie de siguranță a bazei de
date](database-export-import.md) și [Partajarea
datelor](../workflows/sharing-data.md).

## Detectare beaconuri

Recunoaște unde vă aflați după beaconurile Bluetooth amplasate în
peșteră, fără să scanați nimic.

- **Detectează beaconurile automat** — comutatorul principal. Prima
  activare cere permisiunile de Bluetooth și de localizare de care are
  nevoie scanarea. Fiecare cursor și comutator de sub el rămâne estompat
  până când acesta este pornit.
- **Prag de declanșare a semnalului** — un cursor de la −100 la −40 dBm,
  −75 implicit. Mai aproape de 0 înseamnă că trebuie să fiți mai aproape
  de beacon înainte ca acesta să conteze drept atins.
- **Pauză între redeclanșări** — de la 1 la 30 de minute, 5 implicit:
  cât timp rămâne tăcut același beacon după ce s-a declanșat, ca să nu
  se tot declanșeze cât zăboviți acolo.
- **Deschide locul la detectare** — dezactivată implicit. Activată, o
  detectare deschide locul așa cum ar face-o o scanare QR; dezactivată,
  doar vă anunță.
- **Sunet la detectare** — activat implicit; redă o alertă când un
  beacon este recunoscut.
- **Continuă detectarea în fundal** — scanarea continuă cu ecranul stins
  sau cu altă aplicație în față, anunțând printr-o notificare.
  Activarea cere permisiunea pentru notificări și o excepție de la
  optimizarea bateriei.
- **Interval de scanare în fundal** — de la 5 la 60 de secunde, 30
  implicit. Intervalele mai lungi economisesc bateria. Acest cursor are
  nevoie atât de detectarea în fundal, cât și de comutatorul principal.

Două subpagini stau la bază și amândouă rămân accesibile indiferent dacă
detectarea este pornită sau nu:

- **Administrare tag-uri** — titlurile, fotografiile și locul de care
  aparține fiecare tag înregistrat.
- **Laborator beacon** — diagnostic de scanare în timp real, pentru când
  detectarea nu se declanșează și trebuie să știți dacă telefonul aude
  sau nu beaconul.

Vedeți [Beaconuri BLE](ble-beacons.md).

## Informații depanare *(doar în modul depanare)*

Modul de depanare este oprit până când îl porniți: apăsați de nouă ori
la rând, rapid, pe titlul paginii principale — o pauză mai lungă de vreo
trei secunde resetează numărătoarea — iar un mesaj confirmă „Debug mode
activated" (mod de depanare activat). Nu este ținut minte, așa că este
din nou oprit după repornirea aplicației; oprirea manuală cere douăzeci
de apăsări.

Cât timp este pornit, în josul Setărilor apare intrarea **Informații
depanare**, iar în pagina Baza de date apare butonul **Deschide
executant comenzi SQL**. Informații depanare arată directorul de date al
aplicației și calea fișierului bazei de date, fiecare cu un buton de
copiere și, pentru baza de date, dacă fișierul chiar există. Dedesubt
listează fiecare setare stocată ca o cheie și o valoare: apăsați pe un
rând ca să editați valoarea într-un dialog, folosiți butonul + ca să
adăugați o intrare, copiați orice valoare cu butonul ei de copiere și
citiți pictograma de nor care spune dacă acea intrare este inclusă în
sincronizare.

Este o unealtă de asistență și de depanare. O valoare tastată greșit
aici poate opri funcționarea unei funcții până când este corectată, iar
nimic nu vă avertizează înainte.

## Vezi și

- [Pagina principală](home-screen.md)
- [Export, import și copie de siguranță a bazei de date](database-export-import.md)
- [Coduri de loc (PCI) și conținutul codurilor QR (QCRI)](place-code-identifiers.md)
- [Panoul de sincronizare și istoricul modificărilor](sync-and-change-log.md)
- [Sincronizare FTP / SFTP](ftp-sync.md)
- [Sincronizare cu serverul de club](silexgis-sync.md)
- [Beaconuri BLE](ble-beacons.md)
