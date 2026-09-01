# Server de club (SilexGIS)

[← Înapoi la cuprins](../README.md)

SpeleoLoc poate dialoga cu o instalare SilexGIS pe care o ține clubul
dumneavoastră, astfel încât peșterile de pe telefon și peșterile din
registrul clubului să rămână la pas. Pagina de față acoperă adăugarea unui
server, autentificarea, alegerea a ceea ce poartă acest dispozitiv, rularea
unei sincronizări și citirea rezultatului.

> **Este ceva nou.** Ecranul este o lucrare recentă și are asperități,
> semnalate acolo unde contează. Nimic altceva din aplicație nu depinde de
> el: dacă nu deschideți niciodată acest ecran, SpeleoLoc se poartă exact ca
> întotdeauna.

## Ce este un server de club și când aveți nevoie de unul

O instalare SilexGIS este un registru de peșteri pe care un club îl ține pe
propriul server, cu interfață web, conturi și permisiuni. Acolo unde un
folder FTP doar păstrează fișiere, un registru păstrează *rânduri*: el știe
cine poate vedea care peșteră, cărui club speologic îi aparține o peșteră și
cine ce a modificat. A sincroniza cu el înseamnă că dispozitivul
dumneavoastră și registrul schimbă între ele peșteri, zone de peșteră și
locuri unul câte unul, fiecare cu răspunsul lui.

Aveți nevoie de unul doar dacă clubul dumneavoastră are deja o astfel de
instalare. Când nu este configurat nimic, ecranul o spune deschis:

> **Niciun server de club configurat**
> SpeleoLoc funcționează și fără. Adaugă un server doar dacă clubul tău are
> o instalare SilexGIS și vrei ca acest dispozitiv să poarte o parte din
> peșterile ei.

Aceasta este starea obișnuită, nu o defecțiune. Tot ce se află pe
dispozitivul dumneavoastră este al dumneavoastră, fie că există un server,
fie că nu — aplicația nu are niciodată nevoie de unul ca să funcționeze, iar
niciun alt ecran nu se schimbă când adăugați unul.

**Setări → Server de club (SilexGIS)** este singura cale de intrare. Nu
există niciun buton de server de club în bara paginii principale și niciun
card pentru el în meniul aplicației, așa că o sincronizare are loc
întotdeauna doar pentru că ați deschis acest ecran și ați cerut una.

### Ce nu circulă niciodată

Se schimbă doar peșteri, zone de peșteră, locuri din peșteră și arii de
suprafață, cu numele, descrierile, coordonatele, adâncimea, codurile de loc,
conținutul codurilor QR și marcajul de intrare ale acestora. Documentele și
fotografiile, hărțile raster, turele și rapoartele de tură, înregistrările
beaconurilor, utilizatorii și istoricul modificărilor **nu** fac deloc parte
din această sincronizare. Dacă aveți nevoie ca acestea să ajungă pe alt
dispozitiv, folosiți una dintre cele două rute de mai jos.

## Ce rută de sincronizare să folosiți

SpeleoLoc are trei moduri de a muta date, iar acestea nu se suprapun prea
mult.

| Rută | Ce circulă | Când o folosiți |
|---|---|---|
| [Sincronizare manuală](sync-and-change-log.md) | Un instantaneu complet al dispozitivului, cu documente și hărți raster incluse, sub forma unui fișier pe care îl duceți de mână | Predați date unei singure persoane, pe stick sau prin e-mail, ori vreți să importați o arhivă cu conflictele arătate |
| [Sincronizare FTP / SFTP](ftp-sync.md) | Aceleași instantanee complete, printr-un folder partajat | O echipă de dispozitive SpeleoLoc se ține singură la pas și nu este implicat niciun registru — un NAS de club, o găzduire web |
| **Server de club (SilexGIS)** | Peșteri, zone de peșteră, locuri și arii de suprafață, rând cu rând | Registrul clubului este copia de referință, mai multe persoane îl modifică prin interfața lui web, iar telefonul ar trebui să ducă o parte din el pe teren |

Sunt independente și pot fi folosite împreună: o sincronizare cu serverul de
club nu atinge profilurile dumneavoastră FTP și invers. Peșterile care sosesc
de la serverul de club nu sunt înregistrate ca modificări proprii, așa că
aducerea lor nu face de la sine ca dispozitivul să încarce o nouă arhivă FTP.

## Adăugarea unui server

Apăsați **Adaugă un server** pe ecranul gol sau creionul de pe cardul
serverului pentru a-l modifica pe cel pe care îl aveți deja. Formularul este
scurt.

| Câmp | Ce puneți în el |
|---|---|
| **Nume** | Etichetă liberă pentru instalare, de exemplu „Clubul Speo Example”. Este numele sub care o arată cardul și mesajul de autentificare. |
| **Adresă** | Adresa web completă a instalării, începând cu `https://` — căsuța este precompletată cu atât. Dacă stă sub un subdirector, păstrați subdirectorul: calea este folosită așa cum este dată. |

O adresă greșită este refuzată când apăsați **Salvează**: căsuța de sub câmp
devine roșie și scrie **Introdu o adresă completă, de exemplu
https://speo.example.org**, iar dialogul rămâne deschis până o corectați. Se
verifică doar *forma* — că există o schemă și o gazdă. O adresă bine formată,
dar care nu indică nimic sau indică ceva ce nu este o instalare SilexGIS,
este acceptată în tăcere; aflați abia când încercați să vă autentificați.

Aici nu există buton **Testează conexiunea**, așa cum există pe ecranul FTP.
Autentificarea este primul lucru care contactează efectiv serverul.

Preferați `https://`. O adresă simplă `http://` este acceptată și ar trimite
parola și peșterile dumneavoastră prin rețea în clar.

Ecranul lucrează cu **un singur** server. Adăugarea unui al doilea nu este
oferită.

## Autentificarea

**Autentificare** de pe cardul serverului cere **E-mail** și **Parolă** —
contul dumneavoastră de pe acea instalare, același pe care îl folosiți în
interfața ei web. Căsuța de e-mail este precompletată cu ultimul cont
folosit.

Parola este folosită pentru autentificare și apoi aruncată. Ce păstrează
dispozitivul este acreditarea returnată de server, iar aceasta ajunge în
seiful securizat al telefonului, niciodată în baza de date — așa că un export
al bazei de date nu o poate duce cu el. După aceea dispozitivul își
reînnoiește singur acreditarea, iar dumneavoastră nu mai sunteți întrebat
până când aceasta expiră.

O autentificare reușită arată un **Autentificat** verde, iar e-mailul
contului apare sub adresă pe cardul serverului. Un eșec arată cu roșu propria
frază a serverului, cuvânt cu cuvânt — aplicația nu inventează un diagnostic,
așa că ce vedeți este ce a spus instalarea.

### Pasul autentificării în doi pași

Dacă pe cont este pornită autentificarea în doi pași, înainte de finalizarea
autentificării apare un dialog **Cod în doi pași**.

- O căsuță **Cod** pentru codul propriu-zis.
- Câte un buton pentru fiecare metodă pe care o poate folosi contul, scriind
  **Trimite un cod prin email**, **Trimite un cod prin sms** și așa mai
  departe — cuvântul este al serverului. Apăsarea unuia cere serverului să îl
  trimită și confirmă cu **Cod trimis**.
- O aplicație de autentificare nu primește niciodată un buton: acel cod se
  află deja în propria dumneavoastră aplicație și nu este nimic de trimis.
  Doar tastați-l.
- Un comutator, **Folosește un cod de recuperare**, oferit întotdeauna.
  Porniți-l și eticheta căsuței devine **Cod de recuperare**; tastați unul
  dintre codurile primite când a fost configurată autentificarea în doi pași.
  Aceasta este calea de întoarcere când telefonul care primește codurile nu
  este cu dumneavoastră.

Apăsați **OK** pentru a încheia. Anularea dialogului oprește autentificarea;
nu se salvează nimic și puteți relua.

### „Serverul nu a acordat o sesiune de durată”

Uneori autentificarea reușește, iar un mesaj galben spune:

> Serverul nu a acordat o sesiune de durată; s-ar putea să ți se ceară din
> nou parola în curând.

Înseamnă că instalarea a emis o acreditare bună doar pentru următoarele
câteva minute și nimic cu care să o reînnoiască. Sunteți autentificat și
puteți sincroniza acum, dar dispozitivul va avea nevoie din nou de parola
dumneavoastră foarte curând, și iar după aceea. Nimic de pe telefon nu poate
remedia asta — o decid setările de cont ale instalării, așa că este treaba
celui care administrează serverul.

### Când expiră acreditarea

O rulare care găsește acreditarea salvată dincolo de reînnoire se oprește și
scrie **Autentifică-te din nou la *nume*** [Sign in to *name* again]. Nu se
pierde nimic și nu se redescarcă nimic: peșterile dumneavoastră sunt oricum
pe dispozitiv. Schimbarea sau resetarea parolei contului pe server
invalidează acreditarea pe **fiecare** dispozitiv autentificat cu ea, așa că
așteptați-vă să vă autentificați din nou după o schimbare de parolă.

## Peșterile purtate de dispozitiv

Un telefon nu poartă întregul registru. Ce poartă este o **selecție** — o
listă cu nume de puncte de pornire de pe server, cu tot ce se află în ele.
Apăsați **Alege** pentru a alege una. Până când o faceți, rândul scrie
**Neales încă**, iar ambele butoane de rulare sunt gri.

Trebuie să fiți autentificat mai întâi; altfel aplicația spune
**Autentifică-te mai întâi pe server** și se oprește.

Selectorul listează selecțiile, fiecare cu numele ei și cu numărul punctelor
ei de pornire, de exemplu *3 rădăcini*. O „rădăcină” este o arie de suprafață
sau o peșteră de la care pornește selecția: vine și tot ce este cuprins în
ea, inclusiv ce se adaugă înăuntru mai târziu, așa că selecția nu are nevoie
de întreținere de fiecare dată când clubul adaugă o galerie.

**Dacă acel cont nu are niciuna**, dialogul o spune:

> Contul nu are încă nicio selecție pe acel server. Creează una din interfața
> web.

Selecțiile se fac pe server, nu în aplicație — acest ecran poate doar să
aleagă dintre cele pe care contul dumneavoastră le are deja. Selecția
altcuiva nu vă este arătată nici dacă îi puteți vedea peșterile.

### Avertismentul despre clubul speologic

O selecție poate exista fără să numească un club speologic. Acestea sunt
marcate în selector cu un triunghi de avertizare, iar alegerea uneia produce:

> Selecția nu numește niciun club, deci tot ce adaugi va fi refuzat. Alege-i
> un club din interfața web.

Citirea funcționează perfect printr-o astfel de selecție. Eșuează tot ce
*trimiteți*: serverul refuză fiecare rând pentru că nu poate spune cărui club
ar trebui să îi aparțină, iar refuzul numește selecția, nu peștera
dumneavoastră, motiv pentru care aplicația vă avertizează în momentul în care
o alegeți, nu după o sincronizare încurcată. Remediul este pe server —
deschideți acea selecție în interfața web și dați-i un club speologic.

### După ce ați ales

Rândul arată apoi **identificatorul** selecției de pe server, nu numele pe
care l-ați ales. Este o asperitate a acestei versiuni; nu este nimic în
neregulă, iar selectorul arată în continuare numele când reintrați în el.

Dacă cineva modifică selecția în interfața web — adaugă o rădăcină, îi
schimbă setările — poziția salvată a dispozitivului rămâne fără sens, iar
următoarea rulare citește singură din nou întreaga selecție. Este normal și
costă doar timp.

## Trimite peșterile explorate în altă parte

Un comutator sub selecție, **oprit implicit**:

> Oprit, se trimit doar peșterile purtate și ce adaugi în ele. Pornit, pleacă
> și o peșteră explorată într-un loc nou - singurul mod de a duce una pe
> server.

Cu el **oprit**, în sus pleacă ce v-a dat deja serverul, plus tot ce ați pus
între timp înăuntru: un loc nou într-o peșteră a clubului, o zonă nouă, o
poziție corectată a intrării. O peșteră pe care ați explorat-o într-un masiv
fără legătură rămâne pe telefon. Este intenționat — configurarea unui server
de club nu ar trebui să vă publice munca proprie, fără legătură cu el.

Cu el **pornit**, se trimite și o peșteră complet nouă (și o arie de
suprafață complet nouă). Acesta este **singurul** mod în care o peșteră
despre care serverul nu a auzit niciodată poate ajunge la el: o selecție
poate porni doar de la ceva ce există deja acolo, așa că o peșteră pe care nu
a încărcat-o nimeni nu poate fi niciodată adăugată într-o selecție.

Porniți-l când contribuiți deliberat cu peșteri noi la registrul clubului și
luați în calcul să îl opriți din nou după aceea.

## Rularea unei sincronizări

Două butoane pe cardul **Sincronizare**, ambele dezactivate până când este
aleasă o selecție și cât timp o rulare este în curs (lângă titlu apare un mic
indicator rotativ):

| Buton | Ce face |
|---|---|
| **Sincronizează acum** | Rularea obișnuită. Trimite ce s-a schimbat aici, apoi citește ce s-a schimbat pe server de la ultima citire a acestui dispozitiv. |
| **Citește tot** | Aceeași rulare, doar că jumătatea de citire pornește selecția de la început, nu de unde a rămas. |

Ambele **trimit întâi și citesc apoi**, intenționat: altfel, o peșteră pe
care ați șters-o aici v-ar fi înapoiată direct de citirea care ar rula
înaintea trimiterii.

Folosiți **Citește tot** când lipsește ceva la care vă așteptați — mai ales
după ce cineva acordă contului dumneavoastră acces la o peșteră. Primirea
permisiunii nu schimbă peștera în sine, așa că o rulare obișnuită nu are
motiv să o observe și nu o va observa niciodată; o citire completă este cea
care o aduce. Este întotdeauna sigură, doar mai lentă.

### Citirea rezultatului

Când rularea se încheie, cardul arată o frază și, sub ea, un mic rând de
numere:

> 3 primite, 2 trimise, 1 șterse

- **primite** — rânduri scrise în baza dumneavoastră de date, fie nou
  adăugate, fie actualizate din versiunea serverului.
- **trimise** — rânduri pe care serverul le-a luat de la dumneavoastră.
- **șterse** — rânduri șterse aici pentru că au fost șterse pe server.

Când nu este nimic de făcut în niciun sens, fraza scrie **La același nivel cu
serverul** [Already level with the server]. O rulare eșuată arată motivul cu
roșu, în cuvintele serverului acolo unde există unele.

Nu există bară de progres, nici detaliu pe fișier și nicio filă de jurnal
cum există pe ecranul FTP; o rulare fie se încheie cu numere, fie eșuează cu
o frază.

### Ștergerile circulă și iau lucruri cu ele

Aceasta este partea distructivă, în ambele sensuri.

- O peșteră sau un loc **șters pe server** este șters și aici la următoarea
  citire, împreună cu ce atârnă de el pe acest dispozitiv — legăturile lui cu
  hărțile, punctele de tură, legăturile către documente și înregistrările
  beaconurilor. Nu ajunge într-un coș; a dispărut.
- O peșteră sau un loc **pe care îl ștergeți aici**, dacă serverul îl
  cunoștea deja, este trimis ca ștergere la următoarea rulare, iar serverul îl
  elimină *cu tot ce se află în el*.

Niciuna nu cere confirmare în momentul sincronizării. Confirmarea a fost
însăși ștergerea. Dacă nu sunteți sigur, faceți o copie de siguranță înainte
de a sincroniza — vedeți [Export, import și copie de siguranță a bazei de
date](database-export-import.md).

## Necesită atenția ta

Când o rulare lasă ceva de decis pentru dumneavoastră, sub cardul de
sincronizare apare un card **Necesită atenția ta**. Rămâne acolo cât timp
aplicația rulează, inclusiv dacă părăsiți ecranul și reveniți, dar nu este
consemnat: închiderea aplicației îl pierde, iar următoarea rulare va scoate
din nou la suprafață tot ce este încă nerezolvat.

Pot apărea patru feluri de intrări.

### S-a schimbat și pe server

Cineva a modificat aceeași peșteră sau același loc după ultima citire a
acestui dispozitiv, așa că versiunea dumneavoastră **nu** a fost aplicată —
nu s-a pierdut nimic din ce este al dumneavoastră și nu s-a suprascris nimic
din ce este al lor. Intrarea poartă formularea proprie a serverului, iar apoi
fie:

- **Pe server: *nume*** — versiunea serverului pentru acel rând, ca să vedeți
  cu ce aveți de-a face; fie
- **Citește tot ca să vezi versiunea de pe server.** — serverul nu a returnat
  versiunea lui, pentru că este posibil ca acel cont să nu aibă poziția acelei
  peșteri.

În această versiune nu există o vedere de îmbinare: nimic nu arată cele două
versiuni una lângă alta. Rezolvarea se reduce la a decide care text este cel
corect și a modifica peștera aici până când scrie așa — iar când versiunea
dorită este cea a serverului, la a o schimba acolo.

### Refuzat

Serverul nu a acceptat un rând. Titlul este propriul cod de motiv al
serverului acolo unde a numit unul — un șir tehnic precum
`access.create_forbidden` — altfel doar **Refuzat**, iar sub el fraza
serverului plus un rând care spune ce duce lucrurile mai departe:

| Rând | Ce aveți de făcut |
|---|---|
| **Încearcă din nou mai târziu.** | O problemă trecătoare — serverul era ocupat sau inaccesibil. Sincronizați din nou peste o vreme. |
| **Autentifică-te din nou.** | Acreditarea a expirat în timpul rulării. Apăsați **Autentificare** și rulați din nou. |
| **Se va trimite din nou la următoarea sincronizare.** | Nimic de făcut; dispozitivul a păstrat rândul și îl va reîncerca. |
| **Cineva trebuie să schimbe ceva pe server.** | Aplicația nu poate remedia. De obicei o permisiune, un club speologic lipsă la selecție sau un tip de peșteră pe care instalarea nu îl cunoaște. Citiți fraza serverului și duceți-o celui care administrează instalarea. |
| **Acesta nu poate fi trimis așa cum este.** | Contul dumneavoastră nu are voie să scrie acel rând sau să îl scrie acolo. Restul rulării nu a fost afectat, iar rândul rămâne în siguranță pe dispozitiv. |

Un refuz este pe rând. Patruzeci de peșteri modificate în subteran și una
refuzată înseamnă că treizeci și nouă au plecat în sus.

### Exista deja ceva în apropiere

Nu este nicidecum un refuz — intrarea o spune:

> Rândul tău a fost salvat. Dacă e aceeași peșteră rămâne decizia ta.

Serverul a observat că peștera sau intrarea pe care tocmai ați **creat-o**
stă aproape de ceva ce deține deja și enumeră ce anume, fiecare cu numele lui
și cu cât de departe este (**la 120 m**). Atingeți intrarea pentru a desfășura
lista. Erați offline când ați decis să o adăugați și nu ați putut întreba,
așa că serverul vă spune după aceea.

Ce aveți de făcut: uitați-vă la vecini în interfața web. Dacă sunt aceeași
peșteră, îmbinați-i acolo — aplicația nu o poate face pentru dumneavoastră.
Dacă sunt cu adevărat diferiți, ignorați intrarea.

Două lucruri de știut înainte de a vă încrede în ea. Se caută doar printre
rândurile pe care serverul le-ar putea arăta contului dumneavoastră, iar o
instalare poate opri complet verificarea fără să spună — așa că un raport gol
nu este dovadă că nu există nimic în apropiere.

### Rânduri care nu au putut fi salvate

> *N* rânduri nu au putut fi salvate
> Se află într-o peșteră pe care contul nu o poate vedea.

Serverul v-a trimis un loc sau o zonă, dar nu și peștera căreia îi aparține,
pentru că este posibil ca acel cont să nu poată citi acea peșteră. Un loc
fără peșteră nu este ceva ce SpeleoLoc poate păstra, așa că acele rânduri au
fost aduse și abandonate, în loc să fie salvate pe jumătate. Datele
dumneavoastră nu au nimic în neregulă.

Dacă ar trebui să aveți acces la acea peșteră, cereți-l pe server, apoi
reveniți și apăsați **Citește tot** — o rulare obișnuită nu îl va prelua.

## Uită

**Uită** de pe cardul serverului întreabă mai întâi:

> **Uiți acest server?**
> Peșterile rămân pe acest dispozitiv. Se șterg autentificarea salvată și tot
> ce ține minte dispozitivul despre discuția cu acel server.

Apăsați **Uită** pentru a confirma sau **Anulează**.

**Ce elimină:** numele și adresa serverului, autentificarea salvată pentru
el, selecția pe care ați ales-o, setarea **Trimite peșterile explorate în
altă parte**, poziția de citire a acestui dispozitiv și evidența
dispozitivului despre ce rânduri deține deja serverul și la ce versiune.

**Ce nu elimină:** nicio peșteră, zonă, loc, document, fotografie, hartă sau
tură. Nu se șterge nimic din baza dumneavoastră de date și absolut nimic de
pe server — registrul clubului rămâne neatins, iar celelalte dispozitive
autentificate la el merg mai departe ca înainte.

Nu se poate anula, dar nu se pierde nimic de valoare: puteți adăuga serverul
din nou și vă puteți autentifica.

Un lucru la care să vă așteptați dacă o faceți. Dispozitivul a uitat ce
conveniseră el și serverul că spune fiecare peșteră comună, așa că următoarea
sincronizare începe acea discuție de la zero, iar la acea primă citire
versiunea serverului pentru un rând pe care îl dețin ambele părți se scrie
peste cea locală. Acolo unde cele două copii au venit din aceeași origine —
exact cazul de după o uitare și o readăugare — o modificare făcută între timp
pe telefon poate fi înlocuită de textul serverului. Sincronizați înainte de a
uita sau trimiteți din nou modificările în sus după aceea.

## Depanare

- **Ambele butoane de rulare sunt gri** — nu a fost aleasă nicio selecție.
  Apăsați **Alege** la **Peșterile purtate de dispozitiv**.
- **„Autentifică-te mai întâi pe server”** — apăsarea butonului **Alege** are
  nevoie de o sesiune activă. Autentificați-vă, apoi alegeți.
- **„Această instalare vorbește versiunea X a protocolului de sincronizare,
  iar această aplicație vorbește Y. Una dintre ele trebuie actualizată.”**
  [„This installation speaks version X of the sync protocol and this
  application speaks Y. One of them needs updating.”] — serverul și aplicația
  sunt din generații diferite și nu vor vorbi până când una dintre ele nu
  este actualizată. Nimic de pe acest ecran nu schimbă asta.
- **O rulare se încheie cu „La același nivel cu serverul”, dar lipsește o
  peșteră** — apăsați **Citește tot**. Permisiunile acordate pe server sunt
  invizibile pentru o rulare obișnuită.
- **Tot ce trimiteți este refuzat** — verificați clubul speologic al
  selecției, ca mai sus, și verificați că acel cont are voie să scrie în acea
  parte a registrului.
- **Nimic din ce trimiteți nu ajunge, dar nici nu se refuză ceva** — o
  peșteră cu adevărat nouă nu este trimisă decât dacă **Trimite peșterile
  explorate în altă parte** este pornit.
- **Numerele par mai mici decât v-ați așteptat** — cardul numără ce a fost
  primit, trimis și șters. Rândurile trimise de server pe care această
  versiune a aplicației nu le modelează și rândurile reținute pentru că aveți
  o modificare proprie netrimisă nu sunt numărate nicăieri pe ecran.

## Asperități în această versiune

Spuse pe față, ca să nu fiți surprins:

- Ecranul ține un singur server; nu există listă și nici selector de
  implicit.
- După ce o selecție este aleasă, rândul arată identificatorul ei, nu numele.
- Nu există detaliu de progres și nici jurnal al unei rulări — doar numerele
  finale.
- Nu există vedere de îmbinare pentru o peșteră care s-a schimbat de ambele
  părți.
- Rapoartele de duplicate și refuzurile trăiesc doar până la închiderea
  aplicației.
- Seturile, rădăcinile și cluburile speologice se creează și se modifică în
  interfața web a instalării, niciodată aici.

## Vezi și

- [Sincronizare FTP / SFTP](ftp-sync.md)
- [Sincronizarea manuală și istoricul modificărilor](sync-and-change-log.md)
- [Partajarea datelor între echipe](../workflows/sharing-data.md)
- [Export, import și copie de siguranță a bazei de date](database-export-import.md)
- [Peșteri și zone de peșteră](caves-and-areas.md)
- [Setări](settings.md)
