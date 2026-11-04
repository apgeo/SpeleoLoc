# Server de club (SilexGIS)

[← Înapoi la cuprins](../README.md)

SpeleoLoc poate dialoga cu o instalare SilexGIS pe care o ține clubul
dumneavoastră, astfel încât peșterile de pe telefon și peșterile din
registrul clubului să rămână la pas — și, acolo unde instalarea le oferă,
fotografiile, turele și hărțile raster care merg cu ele. Pagina de față
acoperă adăugarea unui server, autentificarea, alegerea a ceea ce poartă
acest dispozitiv, ce circulă și cum, rularea unei sincronizări și citirea
rezultatului.

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
dumneavoastră și registrul schimbă între ele peșteri, locuri, ture, hărți și
celelalte unul câte unul, fiecare cu răspunsul lui.

Aveți nevoie de unul doar dacă clubul dumneavoastră are deja o astfel de
instalare. Când nu este configurat nimic, ecranul o spune deschis:

> **Niciun server de club configurat**
> SpeleoLoc funcționează și fără. Adaugă un server doar dacă clubul tău are
> o instalare SilexGIS și vrei ca acest dispozitiv să poarte o parte din
> peșterile ei.

Aceasta este starea obișnuită, nu o defecțiune. Tot ce se află pe
dispozitivul dumneavoastră este al dumneavoastră, fie că există un server,
fie că nu — aplicația nu are niciodată nevoie de unul ca să funcționeze.
Alte ecrane se schimbă doar acolo unde serverul a adus ceva: o secțiune cu
fișierele serverului sub documentele unei peșteri, turele altui telefon în
lista de ture, un speolog de ales pentru un utilizator al telefonului.

**Setări → Server de club (SilexGIS)** este singura cale de intrare. Nu
există niciun buton de server de club în bara paginii principale și niciun
card pentru el în meniul aplicației, așa că o sincronizare are loc
întotdeauna doar pentru că ați deschis acest ecran și ați cerut una. Unele
versiuni ale aplicației sunt construite fără serverul de club; în acestea
intrarea lipsește pur și simplu din **Setări**.

## Ce circulă

Peșterile, zonele de peșteră, locurile din peșteră și ariile de suprafață
circulă întotdeauna, în ambele sensuri, cu numele, descrierile,
coordonatele, adâncimea, codurile de loc, conținutul codurilor QR și
marcajul de intrare ale acestora. Tot restul circulă doar când instalarea
oferă acea parte:

| Ce | În ce sens | Instalarea trebuie să ofere |
|---|---|---|
| Fotografii și documente | În jos la cerere; în sus în timpul unei sincronizări, dacă lăsați fișierele să plece | **Fotografii și documente** ca să le listeze și să le descarce; **Trimiterea fotografiilor și documentelor** ca să le trimită |
| Ture și scanările lor | În ambele sensuri | **Ture** |
| Hărți raster și punctele lor | În ambele sensuri | **Hărți raster**; imaginile lor coboară doar dacă este oferit și **Fotografii și documente** |
| Ce speolog al clubului este un utilizator al telefonului | În ambele sensuri | **Persoane** |
| Deciziile unui verificator despre ce ați trimis | În jos | **Verificare** |
| Modele 3D ale topografiei și locurile puse la stațiile lor | În ambele sensuri | **Modele 3D ale topografiei** — vedeți [Modele 3D de topografie](3d-models.md#cu-silexgis) |

Cardul **Ce oferă serverul** din josul ecranului enumeră aceste părți.
Înainte de prima sincronizare scrie **Nu se știe până la prima
sincronizare.**; după una scrie **La ultima sincronizare, și ce face acest
dispozitiv cu fiecare parte.**, iar fiecare parte spune **Oferit** sau
**Neoferit** și, într-un rând, ce face telefonul cu ea. Cardul păstrează
doar ultimul răspuns: fiecare sincronizare întreabă din nou, iar o
instalare poate opri o parte între două sincronizări. O parte care nu mai
este oferită dispare și de pe celelalte ecrane — lista fișierelor de pe
server, alegerea speologului.

Ce nu circulă niciodată: înregistrările beaconurilor, istoricul
modificărilor, lista participanților unei ture, utilizatorii de pe telefon
(în afară de numele celor care au făcut ceva ce trimiteți — vedeți
[Persoane](#persoane)) și setările dumneavoastră.

## Ce rută de sincronizare să folosiți

SpeleoLoc are trei moduri de a muta date, iar acestea nu se suprapun prea
mult.

| Rută | Ce circulă | Când o folosiți |
|---|---|---|
| [Sincronizare manuală](sync-and-change-log.md) | Un instantaneu complet al dispozitivului, cu documente și hărți raster incluse, sub forma unui fișier pe care îl duceți de mână | Predați date unei singure persoane, pe stick sau prin e-mail, ori vreți să importați o arhivă cu conflictele arătate |
| [Sincronizare FTP / SFTP](ftp-sync.md) | Aceleași instantanee complete, printr-un folder partajat | O echipă de dispozitive SpeleoLoc se ține singură la pas și nu este implicat niciun registru — un NAS de club, o găzduire web |
| **Server de club (SilexGIS)** | Peșteri, zone de peșteră, locuri și arii de suprafață, rând cu rând; și, acolo unde instalarea le oferă, fotografii și documente, ture, hărți raster, persoane și modele 3D ale topografiei | Registrul clubului este copia de referință, mai multe persoane îl modifică prin interfața lui web, iar telefonul ar trebui să ducă o parte din el pe teren |

Sunt independente și pot fi folosite împreună: o sincronizare cu serverul de
club nu atinge profilurile dumneavoastră FTP și invers. Ce sosește de la
serverul de club nu este înregistrat ca modificări proprii, așa că aducerea
lui nu face de la sine ca dispozitivul să încarce o nouă arhivă FTP.

O excepție de la „instantaneu complet”: un fișier descărcat de pe serverul
de club ca o copie fără locație sau ca o imagine redusă rămâne pe telefonul
care l-a descărcat, la fel și o hartă raster a cărei imagine este o astfel
de copie, cu punctele ei. Arhivele sincronizării manuale și FTP le lasă
deoparte. Alt dispozitiv le primește de la server sau deloc. Vedeți
[Copiile de pe server](#copiile-de-pe-server).

## Adăugarea unui server

Apăsați **Adaugă un server** pe ecranul gol sau creionul de pe cardul
serverului pentru a-l modifica pe cel pe care îl aveți deja. Formularul este
scurt.

| Câmp | Ce puneți în el |
|---|---|
| **Nume** | Etichetă liberă pentru instalare, de exemplu „Clubul Speo Example”. Este numele sub care o arată cardul și mesajul de autentificare. |
| **Adresă** | Adresa web completă a instalării, începând cu `https://` — căsuța este precompletată cu atât. Dacă stă sub un subdirector, păstrați subdirectorul: calea este folosită așa cum este dată. |

O adresă greșită este refuzată când apăsați **Salvează**: căsuța de sub câmp
devine roșie și spune motivul, iar dialogul rămâne deschis până o corectați.

| Ce este greșit | Ce scrie sub căsuță |
|---|---|
| Lipsește gazda, căsuța e goală sau adresa conține un spațiu | **Introdu o adresă completă, de exemplu https://speo.example.org** |
| Nu începe cu `https://` — inclusiv o adresă simplă `http://` | **Adresa trebuie să înceapă cu https://** |
| Conține un nume de utilizator sau o parolă (`https://nume:parola@…`) ori o parte după `?` sau `#` | **Lasă deoparte numele de utilizator, parola și orice parte de după ? sau #** |

O adresă `http://` este refuzată pentru că parola și acreditarea primită de
la server ar traversa rețeaua în clar. O bară oblică de la final este
eliminată la salvare.

În rest se verifică doar *forma*. O adresă bine formată, dar care nu indică
nimic sau indică ceva ce nu este o instalare SilexGIS, este acceptată în
tăcere; aflați abia când încercați să vă autentificați.

Aici nu există buton **Testează conexiunea**, așa cum există pe ecranul FTP.
Autentificarea este primul lucru care contactează efectiv serverul.

**Un profil salvat cu o adresă `http://` de o versiune mai veche** o
păstrează, dar aplicația nu o mai contactează: cardul serverului scrie
**Această adresă nu mai este acceptată. Modific-o astfel încât să înceapă cu
https:// înainte să te autentifici sau să sincronizezi.**, iar o
autentificare sau o sincronizare se oprește cu același sfat. Nimic nu este
trimis la vechea adresă. Corectați-o cu creionul; asta contează ca o
schimbare de server, mai jos.

### Schimbarea adresei

Dacă apăsați creionul și salvați alt server — altă gazdă, alt port,
`http`/`https` sau alt subdirector — aplicația întreabă întâi:

> **Muți profilul pe alt server?**
> Noua adresă poate fi o altă instalare. Se șterg autentificarea salvată,
> selecția aleasă și tot ce ține minte dispozitivul despre discuția cu vechea
> adresă, iar tu va trebui să te autentifici din nou. Peșterile rămân pe
> acest dispozitiv.

**Schimbă adresa** merge mai departe; **Anulează** lasă profilul cum era. Se
șterge ce șterge și [Uită](#uită), mai puțin profilul însuși: numele și
setările pentru fotografii și Wi-Fi rămân, iar **Trimite peșterile explorate
în altă parte** revine la oprit, pentru că ce se publică se decide pentru
fiecare server în parte. Apoi autentificați-vă, alegeți o selecție și
sincronizați; prima rulare se poartă ca prima rulare după ce ați uitat
serverul și l-ați adăugat din nou, așa că citiți nota de la finalul
secțiunii [Uită](#uită) înainte să schimbați adresa unui server pentru care
mai aveți modificări netrimise.

Schimbarea doar a numelui, a literelor mari și mici din adresă sau a barei
de la final nu întreabă nimic și vă păstrează autentificat. Creionul este
inactiv cât timp rulează o sincronizare.

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

Selecția hotărăște mai mult decât peșterile: turele, hărțile, fotografiile
și modelele care circulă sunt cele ale peșterilor pe care le poartă.

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

## Fotografii și documente

### Trimiterea lor și datele mobile

Trei comutatoare pe un card separat, sub selecție. Toate trei sunt
**pornite implicit**.

| Comutator | Ce face |
|---|---|
| **Trimite fotografiile și documentele** | *Oprit, se trimit doar peșterile și locurile; fotografiile și documentele rămân pe acest dispozitiv.* Oprit reține și o hartă raster nouă, a cărei imagine este un fișier. Turele, punctele și modificările hărților aflate deja pe server pleacă în continuare. |
| **Doar prin Wi-Fi** | *Fișierele așteaptă Wi-Fi; tot ce nu are fișier pleacă oricum. Hotspotul unui telefon contează ca Wi-Fi.* Și un cablu contează ca Wi-Fi. |
| **Întreabă înainte de a folosi datele mobile** | Folosit doar cât timp **Doar prin Wi-Fi** este pornit. *Oprit, fișierele doar așteaptă Wi-Fi.* |

Cu toate trei pornite și telefonul departe de Wi-Fi, o sincronizare care are
fișiere de trimis se oprește să întrebe:

> **Trimiți fișierele prin date mobile?**
> 3 fotografii și documente (12.4 MB) sunt gata de trimis, iar acest
> dispozitiv nu este conectat la Wi-Fi.

Apăsați **Trimite acum** sau **Așteaptă Wi-Fi**. Bifați întâi **Ține minte
alegerea** și răspunsul devine o setare: **Trimite acum** ținut minte
oprește **Doar prin Wi-Fi**, **Așteaptă Wi-Fi** ținut minte oprește
**Întreabă înainte de a folosi datele mobile**. Amândouă se văd pe card,
unde le puteți porni la loc. Sunteți întrebat cel mult o dată pe
sincronizare, iar răspunsul acoperă la fel fotografiile, documentele și
imaginile hărților. Dacă părăsiți ecranul înainte să vină întrebarea,
fișierele așteaptă.

Telefonul se ia după ce raportează sistemul. Wi-Fi-ul de la hotspotul unui
telefon este Wi-Fi, iar un Wi-Fi taxat pe megabyte nu este deosebit. Când
sistemul raportează date mobile alături de Wi-Fi sau nu poate spune ce rețea
este — un VPN singur, de exemplu — telefonul o tratează ca date mobile și
întreabă.

Ce așteaptă apare la **Necesită atenția ta** ca **3 fotografii și documente
nu au fost trimise**, cu motivele: așteaptă Wi-Fi, nu mai aveți spațiu pe
server, sunt prea mari, sunt de un tip pe care serverul nu îl acceptă, nu
mai sunt pe acest dispozitiv sau au fost întrerupte (**următoarea
sincronizare continuă**). O peșteră, un loc sau o tură de care atârnă o
fotografie care așteaptă pleacă oricum.

### Ce pleacă în sus

Fotografiile, documentele, înregistrările audio și filmele dumneavoastră
pleacă în sus când atârnă de ceva ce serverul deține sau ce trimite aceeași
sincronizare: o peșteră, o zonă, un loc, o tură sau una dintre scanările ei.
După aceea, un titlu sau o descriere modificată pleacă drept modificare, iar
un fișier pe care îl ștergeți aici pleacă drept ștergere.

O fotografie pleacă așa cum este pe telefon, inclusiv locul unde a fost
făcută, dacă fotografia îl înregistrează. Instalarea hotărăște cine poate
vedea locația: un cont care nu are voie primește o copie fără ea.

### Ce coboară

Nimic nu se descarcă de la sine. Lista fotografiilor și documentelor de pe
server coboară odată cu sincronizarea, iar lista de documente a unei
peșteri, a unei zone de peșteră sau a unui loc primește la sfârșit o
secțiune **Pe server**, sub numele instalării, cu fișierele de acolo pe care
telefonul nu le are. Fiecare rând arată felul (**Fotografie**, **Video**,
**Sunet**, **Document**, **Alt fișier**), mărimea acolo unde se știe și
**Ai deja acest fișier** când telefonul are același fișier sub altă intrare
(nu se descarcă din nou) sau **Nu îți este disponibil** când contul
dumneavoastră nu îl poate descărca.

Bifați ce vreți și apăsați **Descarcă (2)**, sau apăsați **Descarcă
fișierele obișnuite** pentru cele pe care cel care îngrijește peștera le-a
marcat ca demne de purtat. O întrebare **Descarcă la** cere apoi o mărime:
**Original, la mărime completă** sau o imagine redusă de **2400 px**,
**1200 px**, **480 px** ori **160 px** în lățime — sunt listate doar
mărimile oferite. **Descarcă fișierele obișnuite** arată cât ar costa
fiecare alegere, de exemplu *8 fișiere, 15.2 MB*; o copie pe care serverul o
face la cerere nu are mărime până nu sosește.

O descărcare merge prin orice rețea are telefonul — comutatoarele de Wi-Fi
privesc trimiterea. La sfârșit, un mesaj numără ce s-a întâmplat: descărcate,
deja pe acest dispozitiv, care nu mai sunt pe server pentru dumneavoastră,
care nu sunt date acestui cont, sau care nu au putut fi descărcate
(**încearcă din nou ca să continui**).

### Copiile de pe server

Ce primește contul dumneavoastră depinde de regulile instalării, fișier cu
fișier:

- **originalul**, fișierul exact cum este păstrat;
- o copie **fără locație** — întreaga imagine, rescrisă fără locul unde a
  fost făcută; astfel de fișiere poartă în listă eticheta **fără locație**;
- doar **imagini reduse** pe care serverul le desenează la mărimile fixe de
  mai sus.

O copie fără locație și o imagine redusă rămân pe telefonul care le-a
descărcat. Nu sunt trimise niciodată înapoi în sus ca și cum ar fi
originalul, iar arhivele sincronizării manuale și FTP le lasă deoparte,
împreună cu ce atârnă de ele.

## Persoane

Registrul clubului își cunoaște speologii; telefonul își cunoaște
utilizatorii. Când instalarea oferă **Persoane**, puteți spune ce speolog
este un utilizator al telefonului.

Deschideți **Setări → Utilizatori** și apăsați pe un utilizator. Dialogul
**Editează utilizator** se încheie atunci cu **Speolog pe Clubul Speo
Example** — numele instalării — cu lista speologilor clubului; cel căruia îi
aparține contul dumneavoastră este marcat *Invented Caver (tu)*. Alegeți
unul. Sub căsuță aplicația scrie **Se trimite la următoarea sincronizare**
până când a plecat, sau **Ales pe server** când legătura a fost făcută în
interfața web.

- Căsuța apare doar pentru un utilizator care există deja — salvați întâi
  unul nou — și doar după ce o sincronizare a adus lista speologilor
  clubului.
- Alegerea nu poate fi ștearsă de pe telefon, doar înlocuită cu alt speolog.
  O legătură se desface în interfața web.
- Ce pleacă în sus despre un utilizator al telefonului este numele de
  utilizator, prenumele și numele, și doar pentru utilizatorii care au
  făcut ceva ce trimite sincronizarea sau pentru care ați ales un speolog.
  Câmpul **Detalii** nu circulă niciodată.

## Ture

Când instalarea oferă **Ture**, turele dumneavoastră din peșterile purtate
pleacă în sus cu scanările lor: titlul, detaliile, jurnalul turei, începutul
și sfârșitul, iar pentru fiecare scanare locul, ora și notițele.
Fotografiile și documentele făcute în timpul turei pleacă odată cu ele când
**Trimite fotografiile și documentele** permite. Lista participanților nu
circulă.

Turele înregistrate pe alte telefoane coboară și ele, dar sunt ținute
deoparte. În lista **Ture trecute / active** a unei peșteri, un comutator
scrie **Arată turele de pe Clubul Speo Example**, cu **2 de pe Clubul Speo
Example ascunse** sub el. Porniți-l ca să le listați. Fiecare poartă atunci
o mică insignă cu un nor (**Înregistrată pe alt telefon, citită de pe
Clubul Speo Example**), iar rândul de sub titlu scrie **înregistrată de
Invented Caver** când lista speologilor clubului numește cine a înregistrat-o.
O tură a altui telefon care încă rulează acolo apare cu **încă deschisă**.
Comutatorul este din nou oprit de fiecare dată când deschideți lista.

O tură care sosește cu numele uneia aflate deja pe telefon, sau o scanare
a aceluiași loc în același moment, nu este salvată; cea de aici se păstrează,
iar **Necesită atenția ta** scrie **2 ture sau scanări nu au fost salvate**.

## Hărți raster

Când instalarea oferă **Hărți raster**, hărțile peșterilor purtate coboară
cu punctele lor, iar ale dumneavoastră pleacă în sus la fel. Punctele
adăugate, mutate sau șterse în interfața web sosesc la următoarea
sincronizare ca orice altă modificare — cu excepția unui punct pe care
l-ați modificat aici și nu l-ați trimis încă, care rămâne cum l-ați lăsat.

O hartă nouă pleacă în sus doar cât timp **Trimite fotografiile și
documentele** este pornit, pentru că imaginea ei este un fișier; altfel
așteaptă, cu punctele ei.

Imaginea unei hărți coboară în timpul sincronizării, prin orice rețea, și
doar dacă instalarea oferă și **Fotografii și documente**. Este originalul
acolo unde contul dumneavoastră îl primește, altfel copia fără locație,
altfel cea mai mare imagine redusă pe care o desenează serverul. Pe o
imagine redusă aplicația scalează punctele ca să se potrivească, iar o notă
deasupra hărții spune ce puteți face:

- **Aceasta este o imagine redusă de pe server. Punctele sunt afișate pe ea,
  dar nu pot fi plasate sau mutate.**
- **Aceasta este o imagine redusă de pe server. Punctele nu pot fi afișate
  sau plasate pe ea; punctele rămân salvate.** — când aplicația nu poate
  spune unde merg, de exemplu la o imagine păstrată culcată pe o parte.

Când imaginea unei hărți este rotită sau oglindită în interfața web,
imaginea redusă este descărcată din nou, dacă nu ați modificat harta aici
între timp.

La **Necesită atenția ta**, **2 hărți raster sau puncte de pe hărți nu au
fost salvate** înseamnă că pe telefon exista deja una cu același nume, sau
un punct al aceluiași loc pe aceeași hartă, și a fost păstrată. **2 imagini
de hartă nu au fost descărcate** înseamnă că acele hărți sunt aici fără
imagine; următoarea sincronizare încearcă din nou.

## Modele 3D ale topografiei

Când instalarea oferă **Modele 3D ale topografiei**, circulă și modelele
clubului pentru peșterile purtate, împreună cu locurile puse la stațiile
lor. Au pagina lor: [Modele 3D de topografie — Cu
SilexGIS](3d-models.md#cu-silexgis).

## Rularea unei sincronizări

Două butoane pe cardul **Sincronizare**, ambele dezactivate până când este
aleasă o selecție și cât timp o rulare este în curs (lângă titlu apare un mic
indicator rotativ):

| Buton | Ce face |
|---|---|
| **Sincronizează acum** | Rularea obișnuită. Trimite ce s-a schimbat aici, apoi citește ce s-a schimbat pe server de la ultima citire a acestui dispozitiv. |
| **Citește tot** | Aceeași rulare, doar că jumătatea de citire pornește fiecare parte de la început, nu de unde a rămas. |

Ambele **trimit întâi și citesc apoi**, intenționat: altfel, o peșteră pe
care ați șters-o aici v-ar fi înapoiată direct de citirea care ar rula
înaintea trimiterii.

Când o sincronizare este întreruptă după trimitere — conexiunea cade înainte
să sosească răspunsul serverului — următoarea sincronizare trimite întâi din
nou aceleași peșteri și locuri, în aceeași cerere. Serverul o recunoaște și
răspunde ce a hotărât prima dată, așa că propriile modificări nu vi se
întorc ca **S-a schimbat și pe server**.

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
  adăugate, fie actualizate din versiunea serverului: peșteri, locuri, ture,
  scanări, hărți, puncte, modele.
- **trimise** — rânduri pe care serverul le-a luat de la dumneavoastră.
- **șterse** — rânduri șterse aici pentru că au fost șterse pe server.

Când încărcările unui cont așteaptă un verificator, fraza adaugă câte
așteaptă (*2 așteaptă verificarea* [2 waiting for review]). Când nu este
nimic de făcut în niciun sens, fraza scrie **La același nivel cu serverul**
[Already level with the server]. O parte pe care instalarea a oprit-o în
timpul rulării este numită la sfârșit — *Serverul nu oferă înregistrările
turelor în acest moment.* [The server does not offer the trip recordings at
the moment.] — iar restul rulării a mers mai departe. O rulare eșuată arată motivul cu
roșu, în cuvintele serverului acolo unde există unele.

Nu există bară de progres, nici detaliu pe fișier și nicio filă de jurnal
cum există pe ecranul FTP; o rulare fie se încheie cu numere, fie eșuează cu
o frază.

### Ștergerile circulă și iau lucruri cu ele

Aceasta este partea distructivă, în ambele sensuri.

- O peșteră sau un loc **șters pe server** este șters și aici la următoarea
  citire, împreună cu ce conține și cu ce atârnă de el pe acest dispozitiv —
  locurile și zonele lui, legăturile cu hărțile, punctele de tură,
  legăturile către documente și înregistrările beaconurilor. Nu ajunge
  într-un coș; a dispărut. Turele, hărțile și punctele șterse pe server
  pleacă la fel; fișierul imagine al unei hărți șterse rămâne.
- În afară de cazul în care conține muncă de-a dumneavoastră pe care
  serverul nu a avut-o niciodată: o modificare încă netrimisă sau care
  așteaptă un verificator, un loc ridicat aici și netrimis, o tură sau o
  hartă neîncărcată, înregistrarea unui beacon. Atunci nu se șterge nimic.
  Peștera sau locul rămâne așa cum este, nu este trimis și ajunge pe pagina
  **Necesită o decizie** ca **Ștearsă pe server, dar conține lucru de-al tău
  pe care serverul nu l-a avut**; vedeți [Pagina Necesită o
  decizie](#pagina-necesită-o-decizie).
- O peșteră sau un loc **pe care îl ștergeți aici**, dacă serverul îl
  cunoștea deja, este trimis ca ștergere la următoarea rulare, iar serverul îl
  elimină *cu tot ce se află în el*.

Niciuna nu cere confirmare în momentul sincronizării. Confirmarea a fost
însăși ștergerea. Dacă nu sunteți sigur, faceți o copie de siguranță înainte
de a sincroniza — vedeți [Export, import și copie de siguranță a bazei de
date](database-export-import.md).

## Necesită atenția ta

Când o rulare lasă ceva de decis sau de știut pentru dumneavoastră, sub
cardul de sincronizare apare un card **Necesită atenția ta**. Rămâne acolo
cât timp aplicația rulează, inclusiv dacă părăsiți ecranul și reveniți, dar
cardul în sine nu este consemnat: închiderea aplicației îl pierde. Ce
așteaptă un verificator sau decizia dumneavoastră *este* consemnat, iar
următoarea rulare îl numără din nou; refuzurile și rapoartele de apropiere
nu sunt, iar următoarea rulare scoate la suprafață doar ce este încă
nerezolvat.

Intrările pe care le poate avea:

- **2 așteaptă decizia ta** — deschide pagina **Necesită o decizie**;
  vedeți [Verificări și decizii](#verificări-și-decizii).
- **2 așteaptă verificarea** — vedeți
  [Verificări și decizii](#verificări-și-decizii).
- **3 fotografii și documente nu au fost trimise** — vedeți
  [Trimiterea lor și datele mobile](#trimiterea-lor-și-datele-mobile).
- **S-a schimbat și pe server**, **Refuzat**, **Exista deja ceva în
  apropiere** și **rânduri care nu au putut fi salvate**, mai jos.
- Ture, hărți și imagini de hartă nesalvate sau nedescărcate — vedeți
  [Ture](#ture) și [Hărți raster](#hărți-raster).

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

Rândul ajunge totodată pe pagina **Necesită o decizie** și nu este trimis
din nou până nu alegeți acolo: înapoi la versiunea serverului, sau o
păstrați pe a dumneavoastră. La fel se întâmplă cu o tură, o hartă, o
fotografie sau un punct care a întâlnit o versiune mai nouă pe server.

În această versiune nu există o vedere de îmbinare: nimic nu arată cele două
versiuni una lângă alta. Ca să ajungeți la un amestec al celor două, luați
versiunea serverului și apoi modificați-o aici.

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

Serverul poate trimite un loc cu o pagină sau mai multe înaintea peșterii
lui. O sincronizare întreruptă între ele — o conexiune pierdută, aplicația
închisă — păstrează un astfel de rând și îl salvează când peștera sosește la
o sincronizare ulterioară; doar o sincronizare care citește până la capăt
numără aici ce încă așteaptă.

Dacă ar trebui să aveți acces la acea peșteră, cereți-l pe server, apoi
reveniți și apăsați **Citește tot** — o rulare obișnuită nu îl va prelua.

## Verificări și decizii

### Când încărcările așteaptă un verificator

O instalare poate marca un cont astfel încât încărcările lui să fie
verificate. Ce trimite acel cont este atunci reținut de server pentru un
verificator, în loc să fie scris. Telefonul numără asta la **Necesită
atenția ta**:

> **2 așteaptă verificarea**
> Ce trimite acest cont este verificat de cineva înainte să fie salvat pe
> server. Până atunci vezi în continuare versiunea ta.

O modificare reținută nu este trimisă din nou cât timp așteaptă. Modificați-o
din nou și noua versiune pleacă în sus și așteaptă în locul ei.

Când instalarea oferă **Verificare**, fiecare sincronizare citește la
sfârșit deciziile verificatorilor. O modificare acceptată devine a
serverului și nu vi se mai cere nimic; când verificatorul a acceptat doar o
parte din ea, versiunea serverului o înlocuiește pe a dumneavoastră aici. O
modificare respinsă, sau acceptată dar care nu a putut fi scrisă, ajunge pe
pagina **Necesită o decizie**.

### Pagina Necesită o decizie

Se ajunge la ea din **2 așteaptă decizia ta** de pe cardul **Necesită
atenția ta**:

> Respinse de un verificator, modificate și pe server sau șterse acolo.
> Alege ce faci cu fiecare.

Fiecare element își arată numele (sau **(fără nume)**), ce este —
**Peșteră, zonă sau loc**, **Utilizator al telefonului**, **Fotografie sau
document**, **Unde este atașată o fotografie sau un document**,
**Înregistrare de tură**, **Scanare din tură**, **Hartă raster**, **Punct pe
o hartă raster**, **Loc la o stație a unui model 3D** — și de ce se află
acolo:

- **Respins** — un verificator a spus nu, cu nota lui dedesubt când a scris
  una;
- **Nu a putut fi salvat** — acceptat, dar refuzat când serverul l-a scris,
  cu codul serverului; adesea contul a pierdut un drept;
- **S-a schimbat și pe server** — vedeți mai sus;
- **Ștearsă pe server, dar conține lucru de-al tău pe care serverul nu l-a
  avut** — vedeți [Ștergerile circulă](#ștergerile-circulă-și-iau-lucruri-cu-ele);
- **Alt punct marchează acest loc pe harta de pe server** — punctul
  dumneavoastră și unul aflat deja pe server stau pentru același loc;
  perechea lui la modelele 3D este **Serverul pune deja acest loc la altă
  stație a acestui model**.

**Ștergerea ta** marchează o ștergere de-a dumneavoastră, iar **Nou aici;
serverul nu l-a avut niciodată** ceva ce există doar pe telefon. Butoanele,
după caz:

| Buton | Ce se întâmplă |
|---|---|
| **Folosește versiunea serverului** | Versiunea dumneavoastră este înlocuită cu a serverului: **Versiunea serverului a fost pusă la loc.** Când telefonul nu a primit versiunea serverului, butonul scrie **Recitește de pe server**, iar răspunsul este **Versiunea serverului vine la următoarea sincronizare.** |
| **Păstrează-o pe a mea, nu o trimite** | **Păstrată pe acest dispozitiv. Se trimite din nou când o modifici.** Pentru ceva șters pe server: **Păstrată doar pe acest dispozitiv. Nu se trimite la server.** |
| **Șterge** | Pentru ceva ce serverul nu a avut niciodată. **Ștergi această ciornă?** — *Serverul nu a avut-o niciodată. Dacă o ștergi, dispare de pe acest dispozitiv.* Pentru ceva șters pe server: **O ștergi și de aici?** — *Serverul nu o mai are. Dacă o ștergi, dispare de pe acest dispozitiv, cu tot ce conține și cu modificările tale netrimise.* |
| **Șterge punctul meu** | Pentru un al doilea punct pe același loc. Punctul dumneavoastră pleacă, iar cel al serverului sosește la următoarea sincronizare. Un loc la stația unui model 3D primește în schimb **Elimină stația mea**. |

Nimic nu se hotărăște în locul dumneavoastră. Până alegeți, fiecare element
rămâne pe telefon așa cum l-ați lăsat și nu este trimis din nou — o peșteră
nouă respinsă rămâne o ciornă locală. Când nu mai rămâne nimic, pagina scrie
**Nimic nu așteaptă decizia ta.**

## Uită

**Uită** de pe cardul serverului întreabă mai întâi:

> **Uiți acest server?**
> Peșterile rămân pe acest dispozitiv. Se șterg autentificarea salvată și tot
> ce ține minte dispozitivul despre discuția cu acel server.

Apăsați **Uită** pentru a confirma sau **Anulează**.

**Ce elimină:** numele și adresa serverului, autentificarea salvată pentru
el, selecția pe care ați ales-o, setarea **Trimite peșterile explorate în
altă parte** și cele trei comutatoare pentru fișiere, pozițiile de citire
ale acestui dispozitiv, evidența lui despre ce rânduri deține deja serverul
și la ce versiune, modificările care așteaptă verificarea și elementele de
pe **Necesită o decizie**, lista speologilor clubului și speologul ales
pentru fiecare utilizator al telefonului, lista fotografiilor și
documentelor de pe server, fișierele trimise pe jumătate și ce știa despre
turele și hărțile pe care le au amândoi în comun.

**Ce nu elimină:** nicio peșteră, zonă, loc, document, fotografie, hartă sau
tură — inclusiv fișierele descărcate și turele și hărțile citite de pe
server. Nu se șterge nimic din baza dumneavoastră de date și absolut nimic de
pe server — registrul clubului rămâne neatins, iar celelalte dispozitive
autentificate la el merg mai departe ca înainte. O modificare reținută
pentru un verificator rămâne reținută acolo; telefonul doar nu o mai
numără.

Nu se poate anula, dar nu se pierde nimic de valoare: puteți adăuga serverul
din nou și vă puteți autentifica.

Lucruri la care să vă așteptați dacă o faceți. Lista de ture nu mai
deosebește turele altui telefon de ale dumneavoastră, așa că nu mai sunt
ascunse. Iar dispozitivul a uitat ce conveniseră el și serverul că spune
fiecare rând comun, așa că următoarea sincronizare începe acea discuție de
la zero, iar la acea primă citire versiunea serverului pentru un rând pe
care îl dețin ambele părți se scrie peste cea locală. Acolo unde cele două
copii au venit din aceeași origine — exact cazul de după o uitare și o
readăugare — o modificare făcută între timp pe telefon poate fi înlocuită de
textul serverului. Sincronizați înainte de a uita sau trimiteți din nou
modificările în sus după aceea.

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
  explorate în altă parte** este pornit. Dacă rezultatul spune că ceva
  așteaptă verificarea, a ajuns pe server și așteaptă un verificator.
- **Fotografiile nu pleacă niciodată** — verificați **Trimite fotografiile
  și documentele** și că **Ce oferă serverul** arată **Trimiterea
  fotografiilor și documentelor** ca **Oferit**. Departe de Wi-Fi, cu
  **Întreabă înainte de a folosi datele mobile** oprit, ele așteaptă Wi-Fi.
- **Nicio secțiune „Pe server” sub documentele unei peșteri** — instalarea
  nu oferă **Fotografii și documente**, nu există acolo nimic ce nu aveți
  deja sau nu a rulat nicio sincronizare de când a fost adăugat.
- **Nicio căsuță „Speolog pe …” la editarea unui utilizator** — utilizatorul
  este nou (salvați-l întâi) sau instalarea nu oferă **Persoane** contului
  dumneavoastră. Rulați o sincronizare după ce începe să le ofere.
- **Lipsesc turele altui telefon** — sunt ascunse; porniți **Arată turele
  de pe …** în lista de ture.
- **Lipsesc punctele de pe o hartă** — harta arată o imagine redusă de pe
  server; nota de deasupra hărții o spune. Punctele sunt în continuare
  salvate.
- **Pagina Necesită o decizie nu poate fi găsită** — se deschide doar de pe
  cardul **Necesită atenția ta**. Rulați o sincronizare; tot ce mai
  așteaptă este numărat din nou.
- **Numerele par mai mici decât v-ați așteptat** — cardul numără ce a fost
  primit, trimis și șters. Rândurile trimise de server pe care această
  versiune a aplicației nu le modelează și rândurile reținute pentru că aveți
  o modificare proprie netrimisă nu sunt numărate nicăieri pe ecran. Nici
  fișierele descărcate din **Pe server** nu sunt numărate.

## Asperități în această versiune

Spuse pe față, ca să nu fiți surprins:

- Ecranul ține un singur server; nu există listă și nici selector de
  implicit.
- După ce o selecție este aleasă, rândul arată identificatorul ei, nu numele.
- Nu există detaliu de progres și nici jurnal al unei rulări — doar numerele
  finale.
- Nu există vedere de îmbinare pentru un rând care s-a schimbat de ambele
  părți.
- Rapoartele de duplicate și refuzurile trăiesc doar până la închiderea
  aplicației.
- Pagina **Necesită o decizie** se deschide doar de pe cardul **Necesită
  atenția ta**, așa că după repornirea aplicației aveți nevoie de o
  sincronizare ca să ajungeți la ea.
- Imaginile hărților coboară în timpul unei sincronizări prin orice rețea;
  comutatoarele de Wi-Fi rețin doar ce se trimite.
- Speologul ales pentru un utilizator al telefonului poate fi schimbat, dar
  nu șters de pe telefon.
- Comutatorul care arată turele altui telefon nu este ținut minte.
- Seturile, rădăcinile și cluburile speologice se creează și se modifică în
  interfața web a instalării, niciodată aici.

## Vezi și

- [Sincronizare FTP / SFTP](ftp-sync.md)
- [Sincronizarea manuală și istoricul modificărilor](sync-and-change-log.md)
- [Partajarea datelor între echipe](../workflows/sharing-data.md)
- [Export, import și copie de siguranță a bazei de date](database-export-import.md)
- [Peșteri și zone de peșteră](caves-and-areas.md)
- [Documente](documents.md)
- [Ture](trips.md)
- [Hărți](raster-maps.md)
- [Utilizatori](users.md)
- [Modele 3D de topografie](3d-models.md)
- [Setări](settings.md)
