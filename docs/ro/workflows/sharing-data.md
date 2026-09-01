# Flux de lucru: Partajarea datelor între echipe

[← Înapoi la cuprins](../README.md)

Datele circulă între telefoane sub formă de **arhive zip** — fie predate
din mână în mână, fie lăsate într-un folder FTP/SFTP partajat pe care
aplicația îl citește și îl scrie în locul dumneavoastră. Un club care își
ține propriul registru SilexGIS are o a treia rută, în care peșterile
călătoresc către și dinspre acel server, nu într-un fișier. Pagina de față
le parcurge pe toate trei și uneltele mai brutale, la nivel de bază de
date întreagă, care stau sub ele.

## Două feluri de arhivă — nu le confundați

Aplicația face două arhive diferite pe două ecrane diferite și niciunul
dintre ecrane nu poate citi fișierul celuilalt. Alegerea greșită este cel
mai frecvent mod în care un schimb de date eșuează.

| | Arhivă de sincronizare | Arhivă completă |
|---|---|---|
| Se face în | **Sinc. man. → Arhivă sincronizare** și prin sincronizare FTP | **Export / Import Date** |
| Nume fișier | `speleo_loc_sync_1756738327000.zip` | `speleo_loc_2026-09-01_14-32-07.zip` |
| Conținut | câte o linie pentru fiecare înregistrare, fiecare marcată cu momentul ultimei modificări, plus istoricul modificărilor | o copie a întregii baze de date, plus fișierele media |
| Îmbinare | automată, **câștigă modificarea cea mai nouă**, fără nicio întrebare (dacă nu le cereți) | vă întreabă la fiecare titlu sau cod duplicat |
| Ștergeri | **rejucate** pe dispozitivul dumneavoastră | nu călătoresc în fișier — dar **Înlocuire totală** șterge ce se află deja pe telefon |
| Se importă în | **Sinc. man. → Importă arhivă de sincronizare** | **Export / Import Date → Importă Arhivă** |

Importați fiecare fel de arhivă pe ecranul care a produs-o. O arhivă de
sincronizare dată lui **Importă Arhivă** eșuează pentru că înăuntru nu
există nicio bază de date; o arhivă completă dată lui **Importă arhivă de
sincronizare** eșuează pentru că îi lipsește descrierea de sincronizare pe
care o caută importatorul.

Regulă practică: **arhive de sincronizare pentru lucrul în echipă între
ture**, **arhive complete pentru mutarea pe un telefon nou sau pentru
predarea unui set de date întreg**.

## Ruta 1: predați o arhivă de sincronizare altui dispozitiv

Acesta este cazul de zi cu zi — doi speologi au cartat galerii diferite pe
telefoanele lor și vor să ajungă amândoi cu ambele jumătăți.

Trei căi către acest ecran, toate în același loc:

- **Setări → Sinc. man.**
- pictograma simplă cu săgeți circulare de **sincronizare** din bara de
  unelte a ecranului principal
- **Sinc. man.** din meniul aplicației (butonul ⋮ din colțul din dreapta
  sus al majorității ecranelor)

Atenție la pictograma **nor** aflată lângă pictograma de sincronizare din
bara de unelte a ecranului principal: ea nu deschide acest ecran, ci
pornește imediat o sincronizare FTP (vezi ruta 2).

> 📷 [Sincronizare manuală — fila arhivei](../screenshots/06-sync-and-sharing.md#sync-dashboard-archive-tab) — Fila Arhivă sincronizare: setările de export, rezolvarea conflictelor și acțiunea de import.

### Export

1. Deschideți **Sinc. man.** și rămâneți pe fila **Arhivă sincronizare**.
2. La **Setări export**, hotărâți dacă puneți în arhivă **Include fișiere
   documentație** (fotografii, schițe, notițe) și **Include imagini
   hărți**. Ambele sunt pornite implicit; oprindu-le obțineți un zip mult
   mai mic, care duce totuși fiecare înregistrare.
3. Apăsați **Exportă arhivă de sincronizare**. Pe Android arhiva zip este
   construită mai întâi, iar dialogul de salvare al dispozitivului vă
   întreabă apoi unde să o pună; pe iOS și pe desktop alegeți mai întâi un
   folder de destinație.
4. Ecranul afișează **Arhivă exportată**, urmat de numele fișierului
   salvat pe Android sau de calea lui completă pe iOS și pe desktop.
   Trimiteți acel zip prin ce mijloc vreți — chat, e-mail, folder în
   cloud, cablu.

### Import

1. Pe telefonul care primește, deschideți **Sinc. man. → Arhivă
   sincronizare**.
2. Alegeți un mod la **Rezolvarea conflictelor**:
   - **Automat (ultima modificare câștigă)** — modificarea mai nouă a
     oricărei înregistrări câștigă în tăcere. Aceasta este alegerea
     obișnuită.
   - **Manual (revizuiește fiecare conflict)** — vi se arată fiecare
     înregistrare ale cărei câmpuri diferă, una lângă alta, cu cele două
     momente ale modificării, și alegeți **Păstrează local**, **Folosește
     din arhivă**, **Păstrează toate local**, **Folosește toate din
     arhivă** sau **Anulează importul**.
3. Apăsați **Importă arhivă de sincronizare** și alegeți zip-ul.
4. Confirmați întrebarea **Import arhivă de sincronizare?**. Citiți-o —
   este singurul avertisment că și ștergerile călătoresc.
5. Când se termină primiți o singură linie: **Import finalizat**, urmată
   de câte înregistrări au fost adăugate, actualizate și șterse și câte
   intrări de istoric al modificărilor și câte fișiere au trecut.

**Anulează importul** este sigur aici: tot importul este desfăcut, iar
mesajul spune *Import anulat — nicio modificare nu a fost aplicată*.

### Ce poate face pe tăcute un import datelor dumneavoastră

- **Vă poate șterge înregistrări.** O arhivă de sincronizare duce atât ce
  a șters celălalt dispozitiv, cât și ce a adăugat. Acele ștergeri sunt
  rejucate pe telefonul dumneavoastră: o peșteră, un loc, o hartă sau un
  document pe care colegul le-a scos dispar și de la dumneavoastră. Copia
  dumneavoastră supraviețuiește doar dacă ați modificat-o *strict după* ce
  el a șters-o; dacă cele două s-au petrecut în aceeași clipă, câștigă
  ștergerea. Asta se întâmplă și în modul **Manual** — dialogul de
  revizuire acoperă numai modificări, așa că nu sunteți niciodată întrebat
  înainte ca ceva să dispară.
- **Doi oameni cu același nume de utilizator devin unul singur.** Un
  utilizator sosit al cărui nume există deja pe dispozitivul dumneavoastră
  este tratat ca aceeași persoană, iar înregistrările lui sunt atașate
  utilizatorului local. Asta face ca utilizatorul implicit să funcționeze
  pe mai multe telefoane — dar dacă doi speologi și-au făcut independent
  conturi cu același nume, istoricul modificărilor îi va trece de atunci
  încolo pe amândoi sub un singur nume.
- **Fotografiile și imaginile hărților nu sunt niciodată suprascrise.** Un
  fișier este copiat din arhivă doar dacă nu aveți deja unul cu acel nume.
  Dacă cineva a refotografiat o poză sau a reexportat o imagine de hartă
  sub același nume de fișier, rămâneți cu imaginea veche, iar numărul de
  „fișiere” este mai mic decât vă așteptați.
- **O arhivă stricată tot se importă.** O înregistrare coruptă, sau una
  care se lovește pe un cod unic de o înregistrare locală fără legătură,
  este omisă, iar restul este îmbinat, în loc să pice tot importul.
  Comparați numerele din linia de rezultat cu ce vă așteptați să primiți.
- **O arhivă de la o versiune mai nouă a aplicației este refuzată** din
  capul locului, cu un mesaj care numește versiunea la care trebuie să
  actualizați. Una de la o versiune mult mai veche este refuzată la fel —
  reexportați-o de pe un telefon actualizat.

## Ruta 2: lăsați un folder FTP/SFTP partajat să facă predarea

Aceleași arhive de sincronizare, dar nimeni nu mai are de cărat fișiere:
fiecare telefon își încarcă propria arhivă într-un folder de pe un server
pe care îl controlați și le importă pe cele lăsate acolo de ceilalți.

1. **Setări → Sincronizare FTP / SFTP** → **Adaugă profil**. Completați
   **Nume**, **Protocol** (FTP, FTPS (TLS explicit) sau SFTP (prin SSH)),
   **Server**, **Port**, **Utilizator**, **Parolă** și **Folder pe
   server**, apoi folosiți **Testează conexiunea** înainte de a salva.
2. Cu mai multe profiluri, deschideți meniul ⋮ al unui profil și alegeți
   **Setează ca implicit** — orice sincronizare dintr-o atingere folosește
   profilul implicit.
3. Asigurați-vă că dispozitivul are o identitate: sincronizarea refuză să
   încarce fără una și vă spune să deschideți întâi **Setări →
   Utilizatori**.
4. Porniți o rulare, fie din pictograma **nor** din bara de unelte a
   ecranului principal, fie din cardul de sincronizare FTP din partea de
   jos a meniului aplicației (**Sincronizează acum**), fie cu butonul de
   pornire de pe ecranul **Sincronizare FTP**.

O rulare listează folderul, descarcă cea mai nouă arhivă nevăzută lăsată
acolo de fiecare alt dispozitiv (una mai veche de pe același dispozitiv
este omisă, pentru că fiecare arhivă este un instantaneu complet), le
importă pe fiecare **automat** — regula ultimei modificări, fără întrebări
despre conflicte — și abia apoi încarcă o arhivă proprie, și numai dacă
s-a schimbat ceva local de la ultima ei încărcare. Un telefon care doar a
primit date lasă serverul neatins.

Ecranul **Sincronizare FTP** are trei file: **Progres** (faza,
progresul general, fișierul curent, octeții transferați, viteza, timpul
rămas), **Jurnal** (fiecare pas al fiecărei rulări, cea mai nouă intrare
prima, cu un separator *sincronizare nouă* între rulări) și **Istoric
modificări**. **Pauză** repornește pasul curent de la început când
reluați, așa că o rulare pusă în pauză costă puțină lățime de bandă,
niciodată date.

Tot ce face un import FTP bazei dumneavoastră de date este exact ce
descrie mai sus „Ce poate face pe tăcute un import datelor dumneavoastră”
— inclusiv rejucarea ștergerilor, fără nicio întrebare. Detaliile complete
despre câmpurile profilului și despre jurnal sunt în
[Sincronizare FTP](../features/ftp-sync.md).

## Ruta 3: sincronizați peșterile cu serverul clubului

Dacă clubul dumneavoastră are deja o instalare SilexGIS — un registru de
peșteri cu interfață web, cu conturi și drepturi proprii — acest dispozitiv
poate schimba peșteri direct cu ea, fără să treacă vreo arhivă din mână în
mână.

1. **Setări → Server de club (SilexGIS)** → **Adaugă un server**, și
   dați-i un **Nume** și **Adresa** instalării.
2. **Autentificare** cu contul dumneavoastră de pe acea instalare —
   același pe care îl folosiți în interfața ei web.
3. Apăsați **Alege** la **Peșterile purtate de dispozitiv** și alegeți o
   selecție. Selecțiile se fac pe server, nu în aplicație: dacă în contul
   dumneavoastră nu există niciuna, selectorul v-o spune și nu este încă
   nimic de sincronizat.
4. **Sincronizează acum** trimite ce s-a schimbat aici, apoi citește ce
   s-a schimbat acolo. **Citește tot** recitește toată selecția, iar asta
   este ceea ce aduce o peșteră la care cineva tocmai a dat acces contului
   dumneavoastră.

O peșteră despre care serverul nu a auzit niciodată urcă doar dacă porniți
**Trimite peșterile explorate în altă parte**; lăsat oprit, sincronizarea
duce peșterile care v-au fost date și tot ce ați adăugat în ele.

Ruta aceasta nu le înlocuiește pe celelalte două. Călătoresc doar
peșterile, zonele peșterii, locurile din peșteră și zonele de suprafață;
documentele, fotografiile, imaginile hărților raster, turele, înregistrările
beaconurilor, utilizatorii și istoricul modificărilor nu, așa că o echipă
care are nevoie de ele tot arhive își pasează. Ștergerile călătoresc în
ambele sensuri fără nicio întrebare și iau cu ele ce atârnă de peștera sau
de locul șters.

Nu există niciun buton pentru ea nicăieri altundeva în aplicație, așa că o
rulare se întâmplă doar când deschideți acel ecran și cereți una. Este o
lucrare recentă, cu asperități, și merită doar dacă instalarea există deja
— lăsați ecranul în pace și aplicația se poartă exact ca întotdeauna.
Detaliile complete sunt în
[Sincronizare cu serverul de club](../features/silexgis-sync.md).

## Ruta 4: predați tot setul de date

**Setări → Export / Import Date** este ruta „totul, într-un singur
fișier”: un telefon nou, o predare, o copie de siguranță în afara
dispozitivului.

### Exportarea unei arhive complete

1. Deschideți **Setări → Export / Import Date**.
2. La **Setări export** alegeți:

   | Comutator | Ce face |
   |---|---|
   | **Include fișiere documentație** | împachetează fotografiile, schițele, înregistrările audio și notițele |
   | **Include imagini hărți** | împachetează hărțile scanate ale peșterilor |
   | **Export diferențial (doar fișiere noi)** | baza de date pleacă tot **integral**; se împachetează doar fișierele de documentație și imaginile de hartă *adăugate de la ultimul export complet*. Un export diferențial nu mută acel reper, așa că următorul diferențial se măsoară tot de la același export complet. |
   | **Include parolele conturilor FTP** | prezent doar în copii ale aplicației construite special; salvează datele de autentificare la servere în interiorul arhivei |

   Nu există un selector de peșteri: fiecare export acoperă toată baza de
   date și nu puteți exporta o singură peșteră.
3. Apăsați **Exportă Arhivă**. Pe Android arhiva zip este construită mai
   întâi, apoi se deschide dialogul de salvare al dispozitivului cu numele
   ei deja completat și alegeți unde ajunge; pe iOS și pe desktop alegeți
   mai întâi folderul.
4. Primiți un singur zip numit după momentul în care a fost făcut —
   `speleo_loc_2026-09-01_14-32-07.zip`, sau `..._diff.zip` pentru un
   export diferențial.

### Importarea unei arhive complete

Apăsați **Importă Arhivă**, alegeți zip-ul, iar aplicația întreabă de
**Mod import**. (Pe un telefon fără date încă, sare peste întrebare și
înlocuiește direct.)

**Înlocuire totală** — *distructivă și ireversibilă.* Aruncă baza de date
curentă și pune în locul ei pe cea din arhivă — tot ce ținea cea veche s-a
dus — apoi copiază peste ele fotografiile și imaginile de hartă din
arhivă, suprascriind orice fișier cu același nume, și repornește
aplicația. Confirmați întâi avertismentul. Telefonul își păstrează propria
identitate de dispozitiv, în loc să o adopte pe a expeditorului.

**Îmbinare cu datele existente** — parcurge arhiva înregistrare cu
înregistrare și adaugă ce lipsește:

1. Înregistrările care nu se lovesc de nimic sunt adăugate.
2. La o ciocnire — un titlu duplicat, un cod de loc duplicat — un dialog
   intitulat **Conflict în Peșteri** (sau Locuri din peșteră, Hărți, Ture
   în peșteră, Documente, …) arată **Existent** și **Importat** una lângă
   alta și oferă **Omite**, **Suprascrie**, **Omite Tot**, **Suprascrie
   Tot** sau **Anulează Importul**. **Omite Tot** și **Suprascrie Tot** se
   aplică fiecărui conflict rămas din tot importul, pe toate tipurile de
   înregistrări — nu există o setare pe tip.
3. Fișierele media sunt copiate doar acolo unde nu aveți deja un fișier cu
   acel nume.

> **Anularea unei îmbinări lasă treaba pe jumătate.** Spre deosebire de
> Sinc. man., **Anulează Importul** de aici se oprește pe loc și tot ce a
> fost deja importat sau suprascris rămâne în baza dumneavoastră de date.
> Dacă anulați, fie rulați importul din nou, fie restaurați o copie de
> siguranță.

O îmbinare acoperă în mod deliberat doar o parte din date. Utilizatorii,
atribuirile de beacon, șabloanele de raport de tură și istoricul
modificărilor trec **numai** cu **Înlocuire totală**.

### Sumarul Import Complet

După o îmbinare, un dialog intitulat **Import Complet** raportează
**Înregistrări importate**, **Înregistrări omise**, **Înregistrări
suprascrise** și **Fișiere copiate**. Dacă ceva a mers prost — o
înregistrare care nu a putut fi legată înapoi de peștera ei, un fișier
care nu s-a copiat, un fel de înregistrare lipsă dintr-o arhivă mai veche
— dedesubt sunt listate cu portocaliu până la zece **Avertismente**, cu o
linie „… și N în plus” pentru restul. Citiți-le: sunt singurul semn că o
parte din arhivă nu a ajuns.

### Descărcarea și încărcarea datelor de test

Versiunile pentru dezvoltatori au în partea de jos a aceluiași ecran o
secțiune **Date de test**, care oferă **Descarcă date de test**, ce aduce
un set de date de probă gata făcut. Aceasta este o **înlocuire totală**:
tot ce se află pe dispozitiv — peșteri, hărți, documente — este șters
definitiv întâi, sunteți avertizat o dată, iar aplicația repornește. O
versiune pentru dezvoltatori fără o sursă de date de test arată acolo o
notificare portocalie în locul butonului. Aplicația publicată nu are
deloc o astfel de secțiune — nici buton, nici notificare. Vezi
[Lucrul cu o arhivă de test locală](../../workflows/local-test-archive.md).

## Setări → Baza de date: uneltele brutale

| Acțiune | Ce face |
|---|---|
| **Exportă baza de date** | scrie o copie brută `speleo_loc_export.sqlite` prin dialogul de salvare al dispozitivului (pe iOS, un folder ales de dumneavoastră). Fără fotografii, fără imagini de hartă — doar un instantaneu pentru același dispozitiv. |
| **Restaurează baza de date din fișier** | înlocuiește baza de date cu un fișier `.sqlite` sau `.db` ales de dumneavoastră, după o singură confirmare, apoi repornește aplicația. Nu poate primi un zip — restaurați o arhivă întreagă din **Export / Import Date**. |
| **Reinițializați baza de date** | șterge tot și lasă aplicația goală. |

Versiunile pentru dezvoltatori adaugă deasupra un buton **Reinițializează
baza de date cu date de test**, care șterge tot și umple în schimb
aplicația cu date de probă; aplicația publicată nu îl are.

Reinițializarea este **ireversibilă**, întreabă de două ori și repornește
aplicația după aceea. Ori de câte ori baza de date este înlocuită în bloc,
telefonul își păstrează propria identitate de dispozitiv în loc să o
adopte pe cea din fișier.

Un buton **Deschide executant comenzi SQL** apare în partea de jos a
acestui ecran doar într-o versiune pentru dezvoltatori și, acolo, doar
când modul de depanare este pornit (nouă atingeri rapide pe titlul
ecranului principal); aplicația publicată nu îl are. Rulează comenzi brute
pe baza de date, fără confirmare și fără anulare; este acolo pentru
diagnosticarea unei probleme împreună cu un dezvoltator, iar o comandă
greșit tastată poate distruge date pe care nicio copie de siguranță nu le
acoperă.

## Ce rută să folosesc?

| Vreți să… | Folosiți |
|---|---|
| schimbați cu un coleg munca de cartare a unei ture | Sinc. man. sau sincronizare FTP |
| țineți un club întreg la zi fără să pasați fișiere | sincronizare FTP |
| țineți peșterile la zi cu un registru pe care clubul dumneavoastră îl are deja, editat atât în interfața lui web, cât și în aplicație | Server de club (SilexGIS) — are nevoie de un cont acolo și de o selecție de peșteri aleasă acolo |
| mutați fotografii, hărți, ture, beaconuri sau istoricul modificărilor | orice, numai serverul de club nu: el duce doar peșteri, zone și locuri |
| mutați totul pe un telefon nou | Export / Import Date → export, apoi **Înlocuire totală** |
| topiți un set de date întreg din afară în al dumneavoastră, hotărând de la caz la caz | Export / Import Date → **Îmbinare cu datele existente** |
| faceți repede o copie de siguranță pe care o veți restaura pe același telefon | Setări → Baza de date → **Exportă baza de date** |

## Sfaturi practice

- **Înainte de a intra în peșteră**, asigurați-vă că toată lumea a
  importat cea mai recentă arhivă (sau a rulat o sincronizare FTP).
  Locurile lipsă și hărțile învechite se descoperă în cel mai prost moment
  cu putință.
- **După o tură**, exportați o arhivă de sincronizare și trimiteți-o, sau
  lăsați sincronizarea FTP să o facă.
- **Faceți o copie de siguranță înainte de orice Înlocuire sau Îmbinare.**
  Amândouă pot pierde date — Înlocuirea prin felul în care e gândită,
  Îmbinarea dacă anulați la jumătate.
- **Importați arhive doar de la oameni în care aveți încredere.** O arhivă
  făcută de o copie construită special a aplicației poate conține parolele
  de server FTP sau SFTP ale acelei persoane, iar importarea ei —
  Înlocuire *sau* Îmbinare — scrie acele date de autentificare în telefonul
  dumneavoastră fără să întrebe.
- **Subțiați încărcătura** când contează doar înregistrările: opriți
  **Include fișiere documentație** și **Include imagini hărți**, și un set
  de date mare devine un zip mic.
- **Lăsați numele fișierelor în pace.** Ele poartă deja data și ora, iar
  asta face un morman de arhive lizibil mai târziu.
- **Merge orice canal** — sunt fișiere zip obișnuite. Chat, e-mail, un
  folder în cloud, un cablu USB.

## Vezi și

- [Sincronizarea manuală și jurnalul modificărilor](../features/sync-and-change-log.md)
- [Sincronizare FTP / SFTP](../features/ftp-sync.md)
- [Sincronizare cu serverul de club](../features/silexgis-sync.md)
- [Export, import și copii de siguranță ale bazei de date](../features/database-export-import.md)
- [Utilizatori](../features/users.md)
- [Lucrul cu o arhivă de test locală](../../workflows/local-test-archive.md)
- [Setări](../features/settings.md)
