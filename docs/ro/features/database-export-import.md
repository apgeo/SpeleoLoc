# Export, import și copie de siguranță a bazei de date

[← Înapoi la cuprins](../README.md)

Tot ce știe aplicația — peșteri, locuri, hărți, ture, înregistrări de
documente — se află într-un singur fișier de bază de date, cu imaginile
documentelor și ale hărților alături. Această pagină acoperă ecranele care
copiază tot acest set de pe dispozitiv și îl pun la loc:
**Setări → Export / Import Date** și **Setări → Baza de date**.

Etichetele folosite mai jos sunt cele în limba română. Aplicația pornește
în română; limba se schimbă din **Setări → General → Limba aplicației**.

## Ce cale folosiți

Aplicația are două moduri destul de diferite de a muta datele, iar ele nu
sunt interschimbabile.

| | **Export / Import Date** | **Sinc. man.** |
|---|---|---|
| Arhiva conține | o copie a întregii baze de date, plus fișierele media | câte o linie pentru fiecare înregistrare, plus istoricul modificărilor |
| Reconstruirea unui dispozitiv de la zero | da — **Înlocuire totală** | nu |
| Schimb de rutină în echipă | greoi — întreabă la fiecare ciocnire | da — câștigă cea mai recentă modificare, fără întrebări |
| Ștergerile făcute în altă parte | nu se aplică niciodată | se reiau pe dispozitivul dumneavoastră |
| Acoperă beaconurile, utilizatorii, șabloanele | doar la **Înlocuire totală** | da |

Folosiți **Export / Import Date** pentru copii de siguranță, pentru mutarea
pe un telefon nou și pentru a da cuiva care pornește de la zero un set
complet de date. Folosiți
[Sincronizarea manuală și istoricul modificărilor](sync-and-change-log.md)
pentru schimbul dus-întors dintre ture și
[Sincronizarea FTP](ftp-sync.md) când un server face acel schimb în locul
dumneavoastră.

## Ce călătorește și ce nu

Aproape totul poate fi împachetat și schimbat, dar există trei excepții
care merită știute înainte să vă bazați pe o arhivă drept copie de
siguranță.

- **Fotografiile atașate tagurilor BLE** (făcute în Administrare
  tag-uri, vedeți [Beaconuri BLE](ble-beacons.md)) sunt păstrate ca
  fișiere imagine obișnuite lângă baza de date și nu ajung în *nicio*
  arhivă. Rămân pe dispozitivul care le-a făcut.
- **Istoricul senzorilor Ruuvi** descărcat de pe un tag se află în
  interiorul fișierului bazei de date, așa că supraviețuiește unui import
  **Înlocuire totală** sau unei restaurări brute a bazei de date, dar
  **Îmbinare cu datele existente** și sincronizarea manuală îl ignoră
  amândouă. Ca să îl dați cuiva, folosiți **Exportă CSV** din ecranul de
  istoric — vedeți [Senzori Ruuvi](ruuvi-sensors.md).
- **Înregistrările tagurilor** — care tag este fixat în care loc —
  călătoresc cu fișierul bazei de date, așa că ajung cu oricare dintre
  modurile de import și cu sincronizarea manuală.

## Exportarea

### O arhivă (baza de date plus fișierele media)

**Setări → Export / Import Date → Exportă Arhivă**. Aplicația construiește
un singur zip numit după momentul în care l-ați făcut, de exemplu
`speleo_loc_2026-09-01_14-32-07.zip`. Pe Android se deschide apoi dialogul
de salvare al dispozitivului, cu acel nume deja completat, iar
dumneavoastră spuneți unde ajunge fișierul — dacă renunțați acolo, nu se
salvează nimic. Pe iOS și pe desktop alegeți în schimb mai întâi dosarul
de destinație. Înăuntru se află baza de date, fișierele media pe care
le-ați cerut și un mic manifest care descrie exportul.

La **Setări export**, trei comutatoare controlează ce intră în arhivă; un
al patrulea apare doar în versiuni speciale. Primele două sunt pornite
când deschideți ecranul.

| Comutator | Efect |
|---|---|
| **Include fișiere documentație** | Adaugă fotografiile, schițele și PDF-urile atașate peșterilor și locurilor. |
| **Include imagini hărți** | Adaugă imaginile scanate din spatele hărților dumneavoastră. |
| **Export diferențial (doar fișiere noi)** | Reduce fișierele media la cele apărute de la ultimul export complet — vedeți mai jos. |
| **Include parolele conturilor FTP** | Doar în versiuni speciale — vedeți avertismentul de mai jos. |

Nu există un selector de peșteri: fiecare export acoperă toată baza de
date. Pe Android aplicația nu cere niciodată o permisiune de stocare —
construiește arhiva în privat, apoi deschide dialogul de salvare al
sistemului, unde alegeți destinația, iar dialogul acordă el însuși dreptul
de scriere.

#### Ce este de fapt un export diferențial

**Export diferențial (doar fișiere noi)** *nu* face o bază de date mai
mică. Baza de date iese întotdeauna întreagă. Comutatorul afectează doar
fișierele media atașate și împachetează doar fișierele de documentație și
imaginile de hărți **adăugate** de la ultimul dumneavoastră export
*complet*.

Două consecințe îi prind pe oameni pe picior greșit:

- Înlocuirea unei imagini pe loc nu o face „fișier nou”. O hartă rescanată
  care refolosește vechiul nume de fișier nu intră în exportul
  diferențial.
- Un export diferențial nu mută reperul. Următorul dumneavoastră export
  diferențial este tot măsurat față de același export complet, nu față de
  cel diferențial pe care tocmai l-ați făcut.

Așadar un export diferențial este o comoditate pentru a-i completa datele
unui coleg care are deja arhiva completă de luna trecută. Nu este o copie
de siguranță.

#### Comutatorul pentru parolele FTP

**Include parolele conturilor FTP** nu este prezent pe o instalare
normală — apare doar în versiuni speciale de test, iar versiunile
obișnuite refuză oricum să scrie parole într-o arhivă. Acolo unde apare și
este pornit, arhiva poartă datele dumneavoastră de autentificare la server
în formă lizibilă, iar importarea ei pe alt dispozitiv le instalează în
[profilurile FTP](ftp-sync.md) salvate ale acelui dispozitiv fără să
întrebe, la **ambele** tipuri de import, Înlocuire și Îmbinare. Nu dați
niciodată o astfel de arhivă nimănui.

Aceeași regulă se aplică și invers: importați arhive doar de la oameni
cărora le-ați încredința propriile date de autentificare la server.

### O copie brută a bazei de date

**Setări → Baza de date → Exportă baza de date**. Scrie o copie a bazei de
date ca `speleo_loc_export.sqlite` — pe Android și pe desktop se deschide
dialogul de salvare al dispozitivului cu acel nume deja completat și
alegeți unde ajunge; pe iOS alegeți dosarul.

Este mică și rapidă, dar nu conține **niciun** fișier de documentație și
**nicio** imagine de hartă. Restaurarea ei pe un dispozitiv care nu are
deja acele fișiere lasă fiecare fotografie și hartă marcată ca lipsă.
Folosiți-o pentru instantanee rapide pe care intenționați să le
restaurați pe **același dispozitiv**.

### Exporturi mai mici, punctuale

Câteva ecrane exportă un singur lucru, nu totul:

- **Generează coduri QR pentru peșteri** produce un PDF sau un zip cu
  imagini — vedeți [Coduri QR](qr-codes.md).
- **Export raport** al unei ture produce un singur fișier de raport —
  vedeți [Rapoarte de tură](trip-reports.md).
- Istoricul Ruuvi are propriul **Exportă CSV** — vedeți
  [Senzori Ruuvi](ruuvi-sensors.md).

## Importul unei arhive

**Setări → Export / Import Date → Importă Arhivă**, apoi alegeți zip-ul.
Există un singur buton pentru ambele moduri; aplicația întreabă pe care îl
vreți *după* ce ați ales fișierul.

Dialogul **Mod import** oferă:

- **Înlocuire totală** — „Înlocuiește baza de date și toate fișierele.
  Aplicația se va reporni.”
- **Îmbinare cu datele existente** — „Îmbină datele importate cu cele
  existente. Puteți rezolva conflictele.”

Această întrebare este pusă doar când dispozitivul dumneavoastră are deja
cel puțin o peșteră. Pe un dispozitiv fără peșteri, arhiva este importată
în modul **Înlocuire totală**, fără a vi se oferi alegerea.

### Înlocuire totală

O singură confirmare, apoi baza de date din arhivă ia locul celei
dumneavoastră, iar fișierele ei media suprascriu orice fișier cu același
nume. Aplicația repornește.

**Este distructiv și nu există anulare.** Tot ce se află acum pe
dispozitiv dispare. Exportați întâi o arhivă dacă nu sunteți sigur.

Dispozitivul dumneavoastră își păstrează propria identitate printr-o
înlocuire — nu începe să pretindă că este dispozitivul care a făcut
arhiva, iar asta este ceea ce împiedică sincronizarea să se încurce după
aceea.

### Îmbinare cu datele existente

O îmbinare funcționează exact ca importul unei arhive de
[sincronizare manuală](sync-and-change-log.md): aceleași reguli decid ce
se adaugă, ce se actualizează și ce se șterge. Înregistrările sunt
potrivite după identitatea ascunsă pe care o primește fiecare la creare,
nu după nume — așa că o peșteră care v-a venit mai demult de la un coleg
este recunoscută ca aceeași peșteră, în timp ce două peșteri create
separat pe două telefoane rămân două peșteri, chiar dacă au același titlu.

- O înregistrare pe care nu o aveți este **adăugată**.
- O înregistrare pe care o aveți amândoi, cu același conținut, este lăsată
  neatinsă.
- O înregistrare pe care o aveți amândoi, dar cu conținut diferit, oprește
  importul cu un dialog **Conflict în …**: câmpurile care diferă, când a
  modificat fiecare parte înregistrarea ultima dată și un tabel alăturat
  **Local** / **Din arhivă**.

| Buton | Ce face |
|---|---|
| **Păstrează local** | Păstrează înregistrarea pe care o aveți deja. |
| **Folosește din arhivă** | O înlocuiește cu cea primită. |
| **Păstrează toate local** | Păstrează varianta dumneavoastră la fiecare conflict rămas din acest import. |
| **Folosește toate din arhivă** | Ia varianta primită la fiecare conflict rămas. |
| **Anulează importul** | Oprește și desface tot importul — vedeți mai jos. |

**Păstrează toate local** și **Folosește toate din arhivă** se aplică
fiecărui conflict rămas din tot importul, la toate tipurile de
înregistrări. Dacă închideți dialogul fără să alegeți, înregistrarea
dumneavoastră este păstrată.

O înregistrare nouă al cărei nume se ciocnește cu o înregistrare *diferită*
de-a dumneavoastră — același titlu de loc în aceeași peșteră, creat separat
pe două telefoane — nu este adăugată: a dumneavoastră este păstrată, iar
cea primită este numărată ca omisă.

#### O îmbinare și șterge

Arhiva duce cu ea ce a șters celălalt dispozitiv, iar o îmbinare repetă
acele ștergeri: o peșteră pe care colegul dumneavoastră a eliminat-o este
eliminată și de pe dispozitivul dumneavoastră, cu excepția cazului în care
ați modificat-o după ce a ștears-o el. Nu sunteți întrebat nimic. Dacă nu
sunteți sigur de o arhivă, exportați întâi propriile date.

#### Ce aduce o îmbinare

Tot ce duce [sincronizarea manuală](sync-and-change-log.md): peșteri, zone
și locuri, înregistrările tagurilor BLE, hărți și puncte de hartă, fișiere
de documentație și legăturile lor, ture și puncte de tură, utilizatori,
șabloane de raport de tură, setările partajate și istoricul modificărilor.

Rămân în urmă:

- **istoricul senzorilor Ruuvi**,
- setările locale ale dispozitivului, cum ar fi peștera pe care o aveați
  deschisă și arhivele FTP pe care acest dispozitiv le-a descărcat deja.

O arhivă făcută de o versiune *mai nouă* a aplicației este refuzată;
actualizați întâi aplicația. Una făcută de o versiune mai veche este adusă
la zi pe parcursul importului.

#### Fișierele media nu sunt niciodată suprascrise de o îmbinare

O îmbinare copiază o fotografie, o schiță sau o imagine de hartă din
arhivă doar când pe dispozitivul dumneavoastră nu există deja un fișier cu
acel nume. Un fișier primit care are același nume cu unul de-al
dumneavoastră este omis — așa că, dacă cineva a refotografiat o poză sau a
reexportat o imagine de hartă sub același nume, păstrați poza veche, iar
numărul de la **Fișiere copiate** iese mai mic decât vă așteptați. Doar
**Înlocuire totală** suprascrie fișierele media.

#### Rezumatul Import Complet

Când o îmbinare se termină, un dialog **Import Complet** raportează patru
numere: **Înregistrări importate** (adăugate), **Înregistrări omise**
(neschimbate, păstrate local sau în coliziune), **Înregistrări
suprascrise** (actualizate) și **Fișiere copiate**. Dacă ceva a mers prost
pe parcurs — un fișier care nu s-a putut copia, un utilizator potrivit cu
unul de-al dumneavoastră după numele de utilizator — dedesubt sunt listate
cu portocaliu până la zece **Avertismente**, cu un rând „… și N în plus”
dacă au fost și altele.

#### Anularea unei îmbinări

**Anulează importul** desface toate modificările de înregistrări pe care
le făcuse importul; primiți un scurt mesaj „Import anulat” și niciun
rezumat. Fișierele media și profilurile FTP nu sunt atinse, pentru că acei
pași rulează după înregistrări.

## Restaurarea unui fișier brut de bază de date

**Setări → Baza de date → Restaurează baza de date din fișier**. Cere
întâi o confirmare, apoi deschide un selector de fișiere care acceptă doar
fișiere `.sqlite` și `.db` — o arhivă zip nu poate fi aleasă aici. Pentru
a restaura totul dintr-o arhivă, folosiți în schimb **Export / Import Date
→ Importă Arhivă → Înlocuire totală**.

Fișierul ales înlocuiește apoi baza de date curentă, iar aplicația
repornește. Dispozitivul dumneavoastră își păstrează propria identitate.
Orice fișiere de documentație sau imagini de hărți la care se referă baza
de date restaurată trebuie să fie deja pe dispozitiv, altfel vor apărea ca
lipsă.

**Este distructiv și ireversibil.** Baza de date pe care o aveați este
ștearsă, nu arhivată.

## Reinițializarea bazei de date

Un singur buton în partea de sus a **Setări → Baza de date** —
**Reinițializați baza de date**, care șterge tot și lasă o bază de date
goală. Versiunile de dezvoltare adaugă deasupra lui un al doilea,
**Reinițializează baza de date cu date de test**, care șterge tot și
încarcă setul de date exemplu inclus în aplicație.

Fiecare întreabă de două ori: o primă confirmare, apoi una formulată fără
menajamente, care avertizează că toate datele vor fi șterse. După aceea
aplicația repornește. Nimic nu este salvat în locul dumneavoastră.

## Încărcarea setului de date de test gata făcut

Într-o versiune de dezvoltare, în partea de jos a **Setări → Export /
Import Date** se află o secțiune **Date de test**, cu butonul **Descarcă
date de test**. Acesta aduce un set de date exemplu de acolo de unde a
fost îndreptată această versiune — de obicei o descărcare de pe internet —
și îl instalează ca **înlocuire completă**: peșterile, hărțile și
documentele aflate acum pe dispozitiv sunt întâi șterse definitiv. Sunteți
avertizat o dată — dar numai dacă aveți ceva de pierdut — iar aplicația
repornește după aceea.

Aplicația publicată nu are deloc o secțiune **Date de test** pe această
pagină. Secțiunea există doar în versiunile de dezvoltare, unde afișează o
notă portocalie care spune că URL-ul arhivei cu date de test nu este
configurat, dacă acelei versiuni nu i s-a dat nicio sursă de date de test.

## Executantul de comenzi SQL

Într-o versiune de dezvoltare și doar când modul de depanare este pornit,
în partea de jos a **Setări → Baza de date** apare un buton suplimentar
**Deschide executant comenzi SQL**. Aplicația publicată nu îl conține, așa
că pornirea modului de depanare nu îl va scoate la iveală. Acesta trimite
comenzi brute direct către baza de date, fără confirmare și fără plasă de
siguranță. Există pentru diagnosticarea unei probleme cu ajutorul unui
dezvoltator. Nu este nimic aici de care un speolog să aibă nevoie în
utilizarea normală, iar o singură comandă scrisă greșit poate distruge
date pe care nicio copie de siguranță nu le acoperă.

## Obiceiuri de copii de siguranță care funcționează

1. **Înainte de orice lucru riscant** — o reinițializare, un
   [import CSV](csv-import.md) mare, încercarea unei versiuni noi —
   exportați o arhivă completă cu ambele comutatoare de fișiere media
   pornite și păstrați-o datată. Numele fișierului poartă deja data și
   ora.
2. **Țineți arhiva în afara dispozitivului.** O copie de siguranță care
   trăiește doar pe telefonul scăpat în sifon nu este o copie de
   siguranță.
3. **Înainte de a intra în subteran**, asigurați-vă că fiecare dispozitiv
   din echipă are datele de care are nevoie. Pentru acel schimb folosiți
   [sincronizarea manuală](sync-and-change-log.md), nu un import de
   îmbinare.
4. **Faceți din când în când un export complet**, nu doar exporturi
   diferențiale — un export diferențial nu înseamnă nimic fără exportul
   complet față de care a fost măsurat.
5. **Nu partajați niciodată o arhivă făcută de o versiune care oferă
   comutatorul pentru parolele FTP.**

## Vezi și

- [Partajarea datelor între echipe](../workflows/sharing-data.md)
- [Sincronizarea manuală și istoricul modificărilor](sync-and-change-log.md)
- [Sincronizare FTP](ftp-sync.md)
- [Setări](settings.md)
- [Documente](documents.md)
- [Senzori Ruuvi](ruuvi-sensors.md)
