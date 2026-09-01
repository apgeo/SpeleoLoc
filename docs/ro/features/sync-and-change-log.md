# Sincronizarea manuală și istoricul modificărilor

[← Înapoi la cuprins](../README.md)

**Sinc. man.** este ecranul în care predați datele altui dispozitiv sub
forma unui singur fișier arhivă și în care priviți înapoi la fiecare
modificare de înregistrare consemnată pe acest dispozitiv. Are două file:
**Arhivă sincronizare** și **Istoric modificări**.

Alte două căi mută datele fără un fișier pe care să îl purtați cu voi:
[sincronizarea FTP / SFTP](ftp-sync.md) lasă aceleași arhive ale întregului
dispozitiv într-un folder comun, pentru echipă, iar
[Server de club (SilexGIS)](silexgis-sync.md), aflat la **Setări → Server de
club (SilexGIS)**, schimbă peșteri, zone de peșteră, locuri și arii de
suprafață — și nimic altceva — rând cu rând, cu un registru de peșteri pe
care îl administrează clubul vostru.

## Deschiderea ecranului

Trei căi de acces, toate ducând în același loc:

- **Setări → Sinc. man.**
- **pictograma de sincronizare** (săgeți circulare simple) din bara de
  instrumente a paginii principale
- **Sinc. man.** din meniul aplicației, deschis cu butonul ⋮ din colțul
  din dreapta sus al majorității ecranelor

Atenție la **pictograma cu nor**, aflată chiar lângă pictograma de
sincronizare în bara de instrumente a paginii principale. Ea *nu* deschide
acest ecran: pornește imediat o sincronizare FTP cu profilul de server
implicit și deschide ecranul de sincronizare FTP. Vezi
[Sincronizare FTP](ftp-sync.md).

> 📷 [Lista de setări, jos](../screenshots/07-settings.md#settings-main-bottom) — Setările derulate în jos, până la intrările pentru partajarea datelor și pentru beacon-uri.

## Arhivă sincronizare

O arhivă de sincronizare este un `.zip` care ține câte o linie pentru
fiecare înregistrare, fiecare marcată cu momentul ultimei modificări.
Dispozitivul care o primește îmbină acele înregistrări cu ce are deja, în
loc să înlocuiască ceva, așa că ambele dispozitive rămân cu reuniunea
celor două seturi de date, iar la orice înregistrare modificată de
amândouă **câștigă modificarea cea mai nouă**.

Asta o face unealta potrivită între ture: doi speologi cartează părți
diferite ale aceleiași peșteri pe telefoanele lor, fac schimb de arhive și
fiecare rămâne cu ambele jumătăți.

> 📷 [Sincronizarea manuală — fila arhivă](../screenshots/06-sync-and-sharing.md#sync-dashboard-archive-tab) — Fila Arhivă sincronizare: setările de export, rezolvarea conflictelor și acțiunea de import.

### Ce călătorește într-o arhivă de sincronizare

| Se transferă | Nu se transferă |
|---|---|
| Peșterile și zonele peșterii, locurile din peșteră și beacon-urile atribuite lor | Identitatea proprie a dispozitivului |
| Hărțile și locurile fixate pe ele | Ce utilizator este conectat acum pe acest dispozitiv |
| Turele și punctele înregistrate în ele | Care peșteră a fost deschisă ultima dată |
| Documentele și legăturile lor către locuri și ture | Orice nu este listat în stânga |
| Șabloanele de raport de tură, utilizatorii, ariile de suprafață | |
| Setările comune de cod de loc și de QR, ca fiecare dispozitiv să genereze codurile la fel | |
| Întregul istoric al modificărilor, întotdeauna | |

Fișierele de documentație (fotografii, schițe, PDF-uri) și imaginile
hărților sunt mari, așa că sunt opționale — vedeți cele două comutatoare
de mai jos.

### Exportul unei arhive de sincronizare

1. Deschideți **Sinc. man. → Arhivă sincronizare**.
2. La **Setări export**, stabiliți ce se împachetează:
   - **Include fișiere documentație** — fotografiile, schițele și
     celelalte fișiere atașate locurilor și turelor.
   - **Include imagini hărți** — imaginile scanate ale ridicărilor
     topografice.

   Ambele sunt active implicit. Dacă le opriți, obțineți o arhivă mult mai
   mică, care duce totuși fiecare înregistrare, dar dispozitivul care o
   primește va afișa substituenți acolo unde ar trebui să fie imaginile.
3. Apăsați **Exportă arhivă de sincronizare**. Pe Android arhiva zip este
   construită mai întâi, apoi se deschide dialogul de salvare al
   dispozitivului cu numele ei deja completat, ca să alegeți unde ajunge
   fișierul; dacă renunțați acolo, nu se salvează nimic. Pe iOS și pe
   desktop vi se cere mai întâi un folder de destinație („Alege folderul
   pentru arhivă”).
4. Arhiva este un singur `.zip` al cărui nume începe cu
   `speleo_loc_sync_`. După ce este salvată, în partea de jos a ecranului
   apare **Arhivă exportată**, urmat de numele fișierului salvat pe
   Android sau de calea lui completă pe iOS și pe desktop. Dacă anulați
   dialogul de salvare, nu apare nicio astfel de linie.

Trimiteți fișierul cum vă convine — cablu, spațiu de stocare în cloud,
aplicație de mesagerie. Vezi
[Partajarea datelor între echipe](../workflows/sharing-data.md).

### Importul unei arhive de sincronizare

Înainte de import, alegeți un mod la **Rezolvarea conflictelor**. Se află
în jumătatea de jos a filei, deasupra butonului de import, și este
alegerea dispozitivului care *importă* — nimic din ea nu se păstrează în
arhivă.

| Mod | Ce se întâmplă |
|---|---|
| **Automat (ultima modificare câștigă)** | Intrările mai vechi sunt suprascrise fără să vi se spună, pe baza momentului modificării. Implicit. |
| **Manual (revizuiește fiecare conflict)** | Vi se cere confirmarea pentru fiecare înregistrare ale cărei câmpuri diferă de copia locală. |

Apoi:

1. Apăsați **Importă arhivă de sincronizare** și alegeți fișierul `.zip`.
2. Confirmați întrebarea **Import arhivă de sincronizare?**. Citiți-o:
   vă avertizează că modificările locale mai noi se păstrează, cele mai
   vechi se suprascriu și că **ștergerile aduse de arhivă se aplică bazei
   voastre de date**.
3. Îmbinarea rulează. În modul Manual apare un dialog pentru fiecare
   înregistrare aflată în conflict (vedeți mai jos).
4. Sub butoane apare un rezumat pe o linie, de exemplu
   `Import finalizat: +12 / ~3 / -1 (57 Istoric modificări, 8 fișiere)` —
   înregistrări adăugate, înregistrări actualizate, înregistrări șterse,
   intrări din istoric îmbinate și fișiere media copiate.

### Revizuirea unui conflict de mână

În modul **Manual (revizuiește fiecare conflict)**, fiecare înregistrare
care se ciocnește deschide un dialog intitulat **Conflict în** *(tipul
înregistrării)*. Acesta enumeră câmpurile care diferă, cele două momente
ale modificării (**Local actualizat** / **Intrare actualizată**) și un
tabel alăturat cu o coloană **Local** și una **Din arhivă**, ca să vedeți
exact la ce ați renunța.

| Buton | Efect |
|---|---|
| **Păstrează local** | Renunță la versiunea din arhivă a acestei singure înregistrări. |
| **Folosește din arhivă** | Suprascrie versiunea voastră a acestei singure înregistrări. |
| **Păstrează toate local** | Răspunde „păstrează local” pentru această înregistrare și pentru toate conflictele rămase, fără să mai întrebe. |
| **Folosește toate din arhivă** | Răspunde „folosește din arhivă” pentru restul importului. |
| **Anulează importul** | Abandonează tot importul. |

**Anulează importul** este aici o operațiune sigură: tot importul este dat
înapoi, iar ecranul raportează *Import anulat — nicio modificare nu a fost
aplicată*. (Acest lucru **nu** este valabil pentru importul
**Îmbinare cu datele existente** de pe ecranul Export / Import Date, care
lasă în urmă tot ce apucase să scrie — vezi
[Export, import și copie de siguranță a bazei de date](database-export-import.md).)

### Importul vă poate șterge înregistrări

O arhivă de sincronizare duce cu ea și ce a *șters* celălalt dispozitiv,
nu doar ce a adăugat și ce a modificat, iar importul repetă acele ștergeri
pe dispozitivul vostru. O peșteră, un loc, o hartă sau un document pe care
colegul de echipă le-a înlăturat vor fi înlăturate și din baza voastră de
date.

Operațiunea este ireversibilă și nimic nu vă întreabă înregistrare cu
înregistrare:

- Înregistrarea supraviețuiește doar dacă ați modificat-o **strict după**
  ce el a șters-o. Dacă cele două s-au petrecut în același moment,
  ștergerea câștigă.
- **Manual (revizuiește fiecare conflict)** nu ajută aici. Dialogul de
  conflict acoperă doar modificările; ștergerile se aplică întotdeauna în
  tăcere.

Dacă nu sunteți sigur pe o arhivă, exportați-vă mai întâi propriile date
(sau faceți o copie de siguranță a bazei de date), ca să puteți recupera o
înregistrare ștearsă.

### Alte lucruri de știut înainte de import

- **Fișierele media nu sunt niciodată suprascrise.** O fotografie sau
  imaginea unei hărți este copiată din arhivă doar dacă pe dispozitivul
  vostru nu există deja un fișier cu acel nume. Dacă cineva a refăcut o
  fotografie și a păstrat numele fișierului, rămâneți cu imaginea veche,
  iar numărul de fișiere din rezumat va fi mai mic decât vă așteptați.
- **Doi oameni cu același nume de utilizator devin unul singur.** Un
  utilizator care vine din arhivă și al cărui nume de utilizator există
  deja pe dispozitivul vostru este tratat ca aceeași persoană, iar
  înregistrările lui sunt atașate utilizatorului local. Asta face ca
  utilizatorul implicit al aplicației să funcționeze pe toate
  dispozitivele — dar dacă doi speologi și-au ales fiecare pe cont propriu
  același nume de utilizator pe telefoane diferite, sincronizarea îi
  contopește fără să spună nimic, iar istoricul modificărilor va trece
  totul pe un singur nume.
- **O arhivă parțial stricată se importă totuși.** O înregistrare coruptă,
  sau care se ciocnește pe un cod unic de o înregistrare locală fără
  legătură cu ea, este sărită, iar restul arhivei este îmbinat oricum. De
  obicei asta și vreți, într-o cabană cu o liniuță de semnal, dar
  înseamnă că un import poate raporta reușită în timp ce câteva
  înregistrări au rămas pe dinafară. Numerele din linia de rezumat sunt
  singurul indiciu — comparați-le cu ce vă așteptați să primiți.
- **Se verifică doar formatul arhivei și versiunea bazei de date.**
  Aplicația nu întreabă niciodată de pe ce dispozitiv vine o arhivă și nu
  afișează niciun avertisment pentru unul necunoscut. O arhivă produsă de
  o aplicație *mai nouă* decât a voastră este refuzată cu un mesaj care vă
  spune la ce versiune să actualizați; una venită de la o aplicație mult
  mai veche este refuzată și ea și trebuie reexportată de pe dispozitivul
  sursă cu o aplicație actualizată.

### Dispozitivul își păstrează identitatea proprie

Ori de câte ori baza de date este înlocuită în întregime — la restaurarea
unui fișier brut de bază de date sau la importul unei arhive cu
**Înlocuire totală** — aplicația pune la loc, după aceea, identificatorul
propriu al acestui dispozitiv, ca să nu înceapă să se dea drept
dispozitivul de la care a venit fișierul. Niciun ecran nu oferă un
comutator pentru asta, iar situația nu apare la importul unei arhive de
sincronizare, care îmbină înregistrările în loc să schimbe baza de date.

### Arhivă sincronizare față de exportul complet al datelor

|  | Arhivă sincronizare (pagina de față) | [Export/import complet al datelor](database-export-import.md) |
|---|---|---|
| Ce se află în fișier | Câte o linie pentru fiecare înregistrare | O copie a întregii baze de date, plus fișierele media |
| Granularitate | Îmbinare înregistrare cu înregistrare | Înlocuirea întregii baze de date sau o îmbinare grosieră, înregistrare cu înregistrare |
| Tratarea conflictelor | Câștigă modificarea cea mai nouă, sau o întrebare la fiecare înregistrare | Întrebări Omite / Suprascrie la fiecare nume sau cod duplicat |
| Ștergerile se repetă? | Da, întotdeauna | Nu (un import cu **Înlocuire totală** aruncă pur și simplu tot ce aveați) |
| Include istoricul modificărilor? | Întotdeauna | Vine cu **Înlocuire totală**, se pierde la **Îmbinare cu datele existente** |
| Cel mai potrivit pentru | Actualizări dese de la un dispozitiv la altul, între ture | Copii de siguranță, pregătirea unui dispozitiv nou, mutarea a tot deodată |

<a id="change-log"></a>

## Istoric modificări

Fiecare înregistrare pe care o adăugați, o modificați sau o ștergeți este
scrisă în istoricul modificărilor, împreună cu momentul, cu utilizatorul
conectat atunci și — pentru modificări și ștergeri — cu valorile pe care
înregistrarea le avea înainte. Nimic din ce faceți în aplicație nu este
consemnat de două ori, iar importul unei arhive nu umple istoricul cu
intrări proprii: în loc de asta, îmbină intrările *originale* de pe
celălalt dispozitiv, așa că istoricul rămâne cinstit cu privire la cine a
schimbat ce și unde.

Istoricul nu este doar o urmă de audit. El este cel care face să meargă
alte două lucruri:

- **duce ștergerile** către celelalte dispozitive, așa că un loc pe care
  îl ștergeți aici dispare și acolo;
- îi permite **sincronizării FTP** să hotărască dacă acest dispozitiv are
  ceva de încărcat — când nu s-a schimbat nimic local de la ultima
  sincronizare, nu se mai construiește și nu se mai trimite nicio arhivă
  (vezi [Sincronizare FTP](ftp-sync.md)).

O [sincronizare cu serverul de club](silexgis-sync.md) nu lasă nicio urmă
aici. Peșterile și locurile pe care le aduce sunt scrise în baza voastră de
date fără o intrare proprie, la fel și cele pe care le înlătură — așa că o
peșteră ștearsă din registrul clubului dispare de pe acest dispozitiv, dar
acea ștergere nu este dusă mai departe, într-o arhivă, către celelalte
dispozitive ale voastre. Ce trimite ea este dedus din înregistrările
înseși, nu din acest istoric.

### Cum se citește

Deschideți **Sinc. man. → Istoric modificări**. Este o listă simplă, cu
cele mai noi intrări la început; trageți în jos ca să o reîmprospătați.
Fiecare intrare arată:

| Partea din intrare | Ce înseamnă |
|---|---|
| Operațiunea | **Adăugat**, **Modificat** sau **Șters**, cu o pictogramă colorată — plus verde, creion albastru, coș roșu. |
| Înregistrarea | Tipul înregistrării și, acolo unde aplicația o mai găsește, titlul ei. |
| Când | Data și ora modificării, până la secundă. |
| Cine | Utilizatorul conectat la acel moment (vezi [Utilizatori](users.md)), afișat cu numele de utilizator și cu numele complet între paranteze. |

> 📷 [Sincronizarea manuală — fila istoric modificări](../screenshots/06-sync-and-sharing.md#sync-dashboard-change-log-tab) — Fila Istoric modificări, cu lista modificărilor recente de înregistrări, cu autor și moment.

### Desfășurarea unei intrări

O intrare **Modificat** se deschide și arată **Câmpuri modificate**:
câmpurile care au fost atinse, fiecare cu valoarea pe care o avea *înainte
de* modificare. Valoarea nouă nu este păstrată — ea este pur și simplu
ceea ce arată acum înregistrarea.

Două limite merită știute:

- Orice valoare anterioară mai lungă de vreo 20 de caractere nu este
  păstrată și apare ca *(valoare trunchiată)*. Descrierile și titlurile
  lungi nu lasă deci niciun istoric care să poată fi citit, ci doar faptul
  că s-au schimbat.
- Intrările **Șters** se desfășoară arătând ultimele valori cunoscute ale
  înregistrării, ceea ce de multe ori ajunge ca să o refaceți de mână.
  Intrările **Adăugat** nu au nimic de desfășurat și nu se deschid.

> 📷 [O intrare desfășurată din istoricul modificărilor](../screenshots/06-sync-and-sharing.md#ftp-sync-change-log-details) — Fila Istoric modificări de pe ecranul de sincronizare FTP, cu lista modificărilor de înregistrări consemnate.

### Ce nu poate face istoricul modificărilor

- **Fără filtre.** Nu există nicio cale de a restrânge lista după dată,
  după tipul înregistrării sau după utilizator.
- **Se încarcă doar cele mai recente 200 de intrări.** Istoricul mai vechi
  este în continuare în baza de date și călătorește în continuare în
  arhivele de sincronizare, dar acest ecran nu vi-l va arăta.
- **Nu se golește niciodată.** Nu există niciun buton pentru asta și nimic
  nu îl curăță în fundal; crește cu fiecare modificare pe care o faceți.
  Singura cale de a scăpa de el este să înlocuiți complet baza de date —
  să o reinițializați sau să importați o arhivă cu **Înlocuire totală**.
- **Fără marcaje de sesiune.** Este o singură listă continuă.

### Istoricul modificărilor în timpul unei sincronizări FTP

Ecranul de sincronizare FTP are aceeași filă **Istoric modificări** ca a
treia filă, alături de **Progres** și **Jurnal**, ca să vedeți ce este pe
cale să trimită dispozitivul chiar în timp ce trimite.

Nu o confundați cu fila **Jurnal** de alături: aceea este jurnalul propriu
de activitate al sincronizării FTP și marchează fiecare rulare cu o linie
despărțitoare `─── sincronizare nouă ───`. Acele linii despărțitoare
aparțin doar acelui jurnal — istoricul modificărilor nu are noțiunea de
sesiune.

## Vezi și

- [Sincronizare FTP](ftp-sync.md)
- [Sincronizare server de club](silexgis-sync.md)
- [Export, import și copie de siguranță a bazei de date](database-export-import.md)
- [Utilizatori](users.md)
- [Partajarea datelor între echipe](../workflows/sharing-data.md)
- [Identificatori cod loc](place-code-identifiers.md)
- [Setări](settings.md)
