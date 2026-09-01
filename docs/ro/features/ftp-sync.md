# Sincronizare FTP / SFTP

[← Înapoi la cuprins](../README.md)

SpeleoLoc poate ține o echipă întreagă la zi printr-un simplu folder FTP,
FTPS sau SFTP: fiecare dispozitiv lasă acolo un instantaneu al bazei sale
de date și le preia pe cele lăsate de ceilalți. Pagina de față acoperă
configurarea unui profil de server, rularea unei sincronizări și citirea
rezultatului.

> Nu există niciun server SpeleoLoc. Orice cont FTP, FTPS sau SFTP este
> bun — un NAS de club, o găzduire web, o mașină de acasă — atâta timp cât
> toți cei din echipă pot citi **și scrie** în același folder.

Pentru arhivele purtate de mână (un fișier pe un stick, un fișier trimis
prin e-mail), vedeți [Sincronizare manuală și istoricul
modificărilor](sync-and-change-log.md).

## Ce face o rulare

1. Se conectează la profilul de server **implicit** și listează folderul.
2. Descarcă fiecare arhivă pe care nu a mai văzut-o, o verifică față de
   suma ei de control și o îmbină în baza dumneavoastră de date.
3. Dacă — și numai dacă — ați făcut modificări pe acest dispozitiv de la
   ultima încărcare, construiește un instantaneu proaspăt al întregii
   baze de date și îl încarcă, împreună cu un mic fișier de sumă de
   control alături.

Fiecare arhivă este un **instantaneu complet** al dispozitivului care a
produs-o, nu o listă de modificări recente. Dispozitivul care o primește
deduce singur ce este nou atunci când o îmbină, așa că nu se pierde nimic
dacă săriți câteva sincronizări; prețul este că fiecare încărcare cară din
nou întregul set de date.

## Configurarea unui profil de server

**Setări → Sincronizare FTP / SFTP** deschide lista de profiluri. Pe o
versiune instalată de dumneavoastră, ea scrie **Niciun profil FTP** până
când adăugați unul; apăsați **Adaugă profil**.

Versiunile distribuite la un eveniment sau de către un club pot veni cu
contul comun deja configurat: un profil este în listă chiar de la prima
pornire, marcat deja ca implicit, și nu aveți nimic de tastat — cardul de
sincronizare din meniul aplicației scrie **Sincronizează acum**, nu
**Configurează FTP pentru sincronizare**. Îl editați ca pe orice alt
profil, iar modificările dumneavoastră se păstrează, parola inclusă. Dacă
îl ștergeți, reapare, tot ca implicit, la următoarea pornire a
aplicației — și la fel după orice operație care înlocuiește întreaga bază
de date, cum ar fi restaurarea dintr-o copie de siguranță.

> 📷 [Lista profilurilor FTP](../screenshots/06-sync-and-sharing.md#ftp-sync-profile-list) — Ecranul de setări Sincronizare FTP / SFTP, cu profilurile de server configurate.

| Câmp | Ce puneți în el |
|---|---|
| **Nume** | Etichetă liberă, obligatorie, de exemplu „NAS-ul echipei”. Apare pe rândul profilului, pe cardul de sincronizare din meniul aplicației și sub titlul de pe ecranul de sincronizare. |
| **Protocol** | **FTP**, **FTPS (TLS explicit)** sau **SFTP (prin SSH)**. FTPS înseamnă aici TLS explicit pe portul FTP obișnuit; FTPS implicit pe portul 990 nu este acceptat. |
| **Server** | Obligatoriu. Numele sau adresa serverului, fără prefix de protocol. |
| **Port** | Lăsați-l gol pentru a folosi valoarea implicită a protocolului — 21 pentru FTP și FTPS, 22 pentru SFTP. Căsuța nu se completează singură: valoarea implicită apare doar ca text gri de sugestie. Un număr în afara intervalului 1–65535 este respins cu **Port invalid**. |
| **Utilizator** | Obligatoriu. |
| **Parolă** | Obligatorie la un profil nou. Se păstrează în seiful securizat al dispozitivului, nu în baza de date. La un profil salvat, căsuța arată un substituent `********`, cu textul ajutător **Lasă gol pentru a păstra parola curentă** — atingeți-o pentru a tasta una nouă sau lăsați-o în pace pentru a o păstra pe cea veche. |
| **Folder pe server** | Folderul în care SpeleoLoc citește și scrie arhive, de exemplu `/speleo_loc/sync/`. Dacă îl lăsați gol, se folosește rădăcina serverului, `/`. Toți cei din echipă trebuie să indice *același* folder. |
| **Mod pasiv** | Doar FTP și FTPS, pornit implicit. „Recomandat când serverul e în spatele NAT” — el este cel care face FTP-ul să meargă prin routerele de acasă și prin rețelele mobile. Opriți-l doar dacă serverul dumneavoastră insistă pe modul activ. |
| **Acceptă certificat TLS invalid** | Doar FTPS, oprit implicit, gândit pentru un server de încredere cu certificat auto-semnat. În versiunea curentă acest comutator este reținut împreună cu profilul, dar **nu este aplicat conexiunii**, așa că un server FTPS auto-semnat poate fi în continuare refuzat. |

Butonul cu ochi de lângă parolă aduce parola stocată și o arată pe ecran
în clar, așa că folosiți-l doar când nu se uită nimeni peste umărul
dumneavoastră.

Dacă folderul de pe server nu există încă, SpeleoLoc încearcă să îl creeze
la prima conectare — inclusiv în timpul unui test de conexiune. Dacă
contul dumneavoastră nu are voie să creeze foldere, conexiunea eșuează;
creați folderul de mână sau indicați unul care există deja.

### Testează conexiunea

**Testează conexiunea** este un buton din formularul de adăugare/editare,
nu un element din meniul listei de profiluri. Se autentifică, listează
folderul de pe server, apoi scrie un mic fișier de probă și îl șterge la
loc — deci dovedește că puteți **scrie** acolo, nu doar citi. Verdictul
apare ca un mesaj verde **Conexiune reușită** sau ca unul roșu
**Conexiune eșuată** / **Autentificare eșuată** în partea de jos a
ecranului. La un profil nou-nouț trebuie să tastați parola înainte ca
testul să pornească, altfel primiți **Parola este obligatorie**.

> 📷 [Editarea unui profil FTP](../screenshots/06-sync-and-sharing.md#ftp-sync-profile-edit) — Editarea unui profil de sincronizare FTP după un test de conexiune reușit.

### Profilul implicit și meniul profilului

În formular nu există un comutator „implicit”. Din meniul ⋮ al unui rând
de profil:

- **Setează ca implicit** — orice sincronizare folosește acest profil.
  Rândul implicit este evidențiat în listă.
- **Editează** — la fel ca atingerea rândului însuși.
- **Șterge** — întreabă întâi **Ștergi profilul?**, apoi înlătură profilul
  și parola lui stocată. Operația nu poate fi anulată.

**Primul** dumneavoastră profil devine automat cel implicit, iar dacă
ștergeți profilul implicit, altul îi ia locul. Cum orice sincronizare
folosește profilul implicit și nu există niciun selector nicăieri,
asigurați-vă că profilul potrivit este cel marcat înainte să porniți.

## Rularea unei sincronizări

Porniți o rulare din oricare dintre acestea:

- **pictograma nor** din bara de acțiuni a paginii principale (urcă în
  bara de sus când bara de acțiuni este ascunsă). Atenție la pictograma
  simplă cu **săgeți circulare** de lângă ea — aceea deschide
  [Sinc. man.](sync-and-change-log.md);
- cardul de sincronizare de lângă baza meniului aplicației, deschis cu
  butonul ⋮ din dreapta sus a majorității ecranelor. Înainte să existe un
  profil, el scrie **Configurează FTP pentru sincronizare** și vă duce la
  setări; odată ce există un profil implicit, scrie **Sincronizează
  acum**, cu numele profilului dedesubt și cu un buton de pornire care
  lansează rularea *fără să închidă meniul*, așa că bara și numele
  fișierului curent vă rulează în față;
- butonul de pornire din bara de sus a ecranului **Sincronizare FTP**.

Ce se întâmplă apoi:

1. Rularea începe **imediat** — nu există confirmare și nici selector de
   profil — și, dacă nu ați pornit-o din meniul aplicației, ecranul
   **Sincronizare FTP** se deschide peste ea. Dacă nu există profil
   implicit sau dacă acesta nu are parolă stocată, rularea eșuează pe loc.
2. Antetul din fila **Progres** numește faza curentă: **Conectare…**,
   **Listare arhive pe server…**, **Se descarcă arhiva**, **Se importă
   arhiva**, **Se generează arhiva locală…**, **Se încarcă arhiva**,
   **Finalizare…**. Dedesubt stau numele profilului și **Început la**.
3. **Progres total** este o singură bară pentru întreaga rulare, cu un
   contor **Arhive: 2 / 5** odată ce coada de descărcare este cunoscută.
   Sub **Fișier curent** aveți numele fișierului, cât s-a **Transferat**
   din totalul lui, **Viteză** și **Rămas** — toate pentru acel singur
   fișier, nu pentru rulare. Viteza este netezită peste ultimele momente,
   așa că se așază după o secundă-două în loc să sară de colo-colo.
4. Când se termină, antetul scrie **Sincronizare reușită**,
   **Sincronizare eșuată**, **Sincronizare anulată** sau **Sincronizare
   în pauză**. Aici nu există un rezumat pe pași — ce a făcut de fapt
   rularea se află în fila **Jurnal**.

> 📷 [O încărcare în desfășurare](../screenshots/06-sync-and-sharing.md#ftp-sync-upload-running) — Încărcarea unei arhive în curs, cu valorile Transferat, Viteză și Rămas în timp real.

### Cele trei file

| Filă | Ce arată |
|---|---|
| **Progres** | Antetul de fază, bara generală și fișierul curent, ca mai sus. La o eșuare, un banner roșu cu textul erorii. |
| **Jurnal** | O relatare cu marcaj de timp a tot ce a făcut rularea, cea mai nouă prima, cu linii de informare albastru-gri, avertismente portocalii și erori roșii, plus o insignă care numără liniile. Rulările sunt despărțite de un separator `─── sincronizare nouă ───`. Se păstrează ultimele 200 de linii. |
| **Istoric modificări** | Istoricul local al modificărilor — aceeași vedere ca fila **Istoric modificări** din Sinc. man., ca să puteți urmări ce urmează să trimită dispozitivul dumneavoastră. |

Fila **Jurnal** este locul unde o sincronizare se explică pe sine: câte
arhive noi au fost găsite, fiecare fișier descărcat cu dimensiunea lui,
fiecare sumă de control verificată, câte rânduri a adăugat, a schimbat și
a sărit un import și fiecare arhivă sărită, cu motivul. Când o rulare nu a
făcut ce vă așteptați, acolo să vă uitați întâi.

> 📷 [Fila de jurnal a sincronizării](../screenshots/06-sync-and-sharing.md#ftp-sync-log-tab) — Fila Jurnal listând fiecare pas al ultimei sincronizări FTP, cea mai nouă prima.

### Butoanele din bara de sus

- **Pornește sincronizarea** (pornire) — afișat când nicio rulare nu este
  în curs sau în pauză; pornește o rulare nouă cu profilul implicit.
- **Pauză** / **Reia sincronizarea**.
- **Anulează sincronizarea** (stop) — întrerupe transferul în curs de
  îndată ce observă. Ce nu a fost încă importat este pur și simplu preluat
  data viitoare.
- **Setări sincronizare FTP** (roată dințată) — deschide lista de
  profiluri, pentru când observați o configurare greșită în mijlocul unei
  rulări.

## Ce circulă de fapt

### La coborâre

Se descarcă doar arhiva **cea mai nouă** de la fiecare celălalt
dispozitiv. Cum fiecare este un instantaneu complet, arhivele mai vechi de
la același dispozitiv sunt de prisos; fila Jurnal le notează ca
*superseded* și sunt trecute la pierderi abia după ce arhiva cea mai nouă
a acelui dispozitiv a fost rezolvată, așa că un fișier corupt nu poate
lăsa pe drum un instantaneu mai vechi, dar bun. Fișierele din folder care
nu sunt arhive SpeleoLoc sunt ignorate cu totul. Arhivele sunt tratate în
ordine, de la cea mai veche.

Fiecare arhivă publicată de o versiune recentă a aplicației are alături un
fișier însoțitor cu suma de control. După descărcare, SpeleoLoc
recalculează amprenta și compară: dacă diferă, arhiva este aruncată în loc
să fie importată, fila Jurnal o spune, iar fișierul rămâne pe server
pentru o încercare ulterioară. Așa se prind atât deteriorările din
transport, cât și un fișier stricat pe server. Arhivele mai vechi, care nu
au fișier însoțitor, sunt importate fără această verificare.

### La urcare

Încărcarea este un **instantaneu complet al acestui dispozitiv**: fiecare
tabel sincronizat, tot istoricul modificărilor și *toate* fișierele
dumneavoastră de documentație și imaginile de hărți. Nimic nu poate fi
lăsat deoparte — comutatoarele **Include fișiere documentație** și
**Include imagini hărți** stau pe ecranul Sinc. man. și pe ecranul de
export al datelor și se aplică doar arhivelor pe care le exportați de mână
acolo. O bibliotecă mare de fotografii sau de hărți face, prin urmare,
fiecare încărcare mare.

Alături de arhivă, SpeleoLoc încarcă și fișierul ei de sumă de control, ca
celelalte dispozitive să poată verifica ce descarcă. Dacă acea mică
încărcare suplimentară eșuează, arhiva rămâne valabilă, iar fila Jurnal
consemnează că a urcat fără amprentă de integritate.

### Când nu se încarcă nimic

Dacă nu ați făcut modificări proprii de la ultima încărcare, jumătatea de
încărcare este **sărită**, iar rularea se încheie doar cu descărcările
făcute.

Contează numai modificările făcute pe *acest* dispozitiv. Importul arhivei
unui coechipier nu declanșează, prin el însuși, o încărcare — asta oprește
două dispozitive să-și paseze la nesfârșit aceleași date. Decizia se ia
înainte de a se importa ceva, comparând intrările proprii din istoricul
modificărilor de pe acest dispozitiv cu cea mai nouă arhivă pe care o are
deja pe server (sau, dacă nu există niciuna acolo, cu propria evidență a
momentului ultimei încărcări).

## Cum se încheie o rulare

Orice s-ar fi întâmplat, antetul unei rulări reușite scrie **Sincronizare
reușită**. Ultima linie din fila **Jurnal** este mai precisă și spune una
dintre:

- *already in sync, no transfer needed* — nimic nou pe server și nimic nou
  de trimis de la dumneavoastră;
- *downloaded N archive(s); no upload needed* — ați preluat munca altora,
  dar nu ați avut nimic propriu de publicat;
- *Sync complete* de unul singur — au rulat ambele jumătăți: ați importat
  ce era nou și v-ați publicat propriul instantaneu.

Ultima distincție contează când vreți să fiți siguri că munca
dumneavoastră a ajuns într-adevăr pe server.

O rulare care a dat de necaz se încheie cu **Sincronizare eșuată** și un
banner roșu care numește prima problemă — chiar dacă cea mai mare parte a
reușit. O arhivă care nu s-a descărcat, care nu a trecut de suma de
control sau care nu s-a importat nu oprește restul și nu vă oprește nici
propria încărcare. Așadar, un rezultat roșu nu înseamnă că nu a mers
nimic: citiți fila Jurnal ca să vedeți ce a mers. Tot ce a eșuat este
lăsat dinadins nemarcat, așa că e destul să rulați sincronizarea din nou
ca să se reîncerce.

La o eșuare de conexiune sau de autentificare, bannerul roșu poartă și un
buton **Deschide setări**, care sare direct la lista de profiluri.

> 📷 [O rulare de sincronizare încheiată](../screenshots/06-sync-and-sharing.md#ftp-sync-complete) — Fila Progres după o rulare de sincronizare FTP reușită.

## Pauză, reluare și ce nu supraviețuiește

**Reia sincronizarea** repornește rularea **de la început**: se
reconectează, listează serverul din nou și redescarcă tot ce apucase să ia
înainte de pauză. Aplicația o spune chiar pe ecranul de pauză —
*„Reluarea repornește pasul curent de la început.”* Nimic nu se strică din
asta (importul aceleiași arhive de două ori este inofensiv), dar plătiți
transferul de două ori, așa că pe o legătură lentă este de obicei mai bine
să lăsați o rulare să se termine decât să o puneți în pauză.

Afișarea progresului și jurnalul sincronizării trăiesc doar cât timp
aplicația rulează. Închideți sau opriți forțat aplicația și ecranul revine
la **Inactiv**, cu fila Jurnal goală, iar o rulare pusă în pauză nu mai
poate fi reluată — porniți una nouă. Întreruperea unei sincronizări nu vă
va strica baza de date: o arhivă care nu a fost descărcată și importată
complet rămâne nemarcată, așa că rularea următoare o culege.

## Conflictele se rezolvă în tăcere

Sincronizarea FTP îmbină întotdeauna cu **ultimul care scrie câștigă** și
nu întreabă niciodată, indiferent ce ați ales pe ecranul Sinc. man. Acea
alegere automat/manual se aplică doar arhivelor pe care le importați de
mână acolo și revine la automat de fiecare dată când deschideți ecranul.

Dacă aveți nevoie să vedeți ce a suprascris o modificare venită din afară,
uitați-vă în [istoricul modificărilor](sync-and-change-log.md#change-log)
sau schimbați arhiva de mână și importați-o pe ecranul Sinc. man. cu
rezolvarea manuală a conflictelor pornită.

## Întreținerea pe server

SpeleoLoc **nu șterge niciodată nimic** din folderul de pe server. Fiecare
sincronizare care încarcă adaugă o arhivă plus un mic fișier de sumă de
control, așa că folderul crește constant — o pereche pentru fiecare
dispozitiv, la fiecare încărcare.

Curățenia rămâne în sarcina dumneavoastră și este sigură: ștergeți din
folder arhivele vechi (și fișierele lor de sumă de control), păstrând-o pe
cea mai nouă de la fiecare dispozitiv. Aplicația reține și numele
arhivelor de care s-a ocupat deja — cele mai recente 500 — ca să nu le
aducă de două ori.

## Securitate

- Preferați **SFTP (prin SSH)** sau **FTPS (TLS explicit)**. **FTP**-ul
  simplu există pentru servere vechi, dar trimite prin rețea, în clar,
  numele dumneavoastră de utilizator, parola și întreaga bază de date
  speologică.
- SFTP folosește **doar autentificare cu parolă**; fișierele de cheie nu
  sunt încă acceptate.
- Parolele ajung în seiful securizat al dispozitivului, nu în baza de
  date, și nu sunt scrise niciodată într-o arhivă de sincronizare.
- Arhivele de date exportate din ecranul de export al datelor **nu conțin
  niciodată** parole FTP într-o versiune obișnuită — nu există niciun
  comutator pentru asta. (O opțiune „Include parolele conturilor FTP”
  există doar în versiunile speciale de test.)

## Depanare

- **Autentificare eșuată** — verificați numele de utilizator și parola;
  pentru SFTP asigurați-vă că serverul permite autentificarea cu parolă.
  Rețineți că la un profil salvat căsuța de parolă arată doar un
  substituent: butonul cu ochi dezvăluie ce este stocat de fapt.
- **Folderul de pe server nu poate fi listat sau scris** — folder greșit
  sau un cont fără drept de scriere acolo. SpeleoLoc trebuie să listeze,
  să descarce *și* să încarce în acel folder, așa că **Testează
  conexiunea** eșuează dacă fișierul lui de probă nu poate fi scris, chiar
  și atunci când listarea merge.
- **Bannerul de eșec arată un cod scurt în loc de o propoziție** —
  `no_default_profile` înseamnă că niciun profil nu este marcat ca
  implicit, iar `no_password_stored` înseamnă că profilul implicit nu are
  parolă salvată. Ambele se rezolvă în **Setări → Sincronizare FTP /
  SFTP**.
- **O arhivă a fost sărită din cauza versiunii aplicației** — fila Jurnal
  spune în ce sens. De la o versiune *mai nouă* de SpeleoLoc: mesajul
  numește versiunea de care aveți nevoie, iar odată actualizat acest
  dispozitiv, arhiva se importă singură la sincronizarea următoare. De la
  o versiune *mai veche*: este sărită definitiv pe acest dispozitiv, iar
  singurul leac este să actualizați aplicația care a produs-o și să lăsați
  acel dispozitiv să sincronizeze din nou. În ambele cazuri, restul
  rulării merge mai departe.
- **Sumă de control nepotrivită** — arhiva este coruptă pe server sau a
  fost deteriorată în transport. Este lăsată pe loc și reîncercată data
  viitoare; dacă tot eșuează, cereți acelui dispozitiv să sincronizeze din
  nou și ștergeți fișierul stricat din folder.
- **Sincronizări lente** — nu există nimic de oprit: o rulare trimite
  mereu fiecare fișier de documentație și fiecare hartă. Sincronizați pe o
  conexiune bună când puteți și mai curățați din când în când arhivele
  vechi din folderul de pe server.
- **`ftp_no_device_uuid`** — acest dispozitiv nu are identificator propriu.
  Foarte rar, de vreme ce aplicația își atribuie singură unul. Descărcările
  funcționează în continuare; doar încărcarea este blocată.

## Vezi și

- [Sincronizare manuală și istoricul modificărilor](sync-and-change-log.md)
- [Partajarea datelor între echipe](../workflows/sharing-data.md)
- [Export, import și copie de siguranță a bazei de date](database-export-import.md)
- [Utilizatori](users.md)
- [Setări](settings.md)
- [Pagina principală](home-screen.md)
