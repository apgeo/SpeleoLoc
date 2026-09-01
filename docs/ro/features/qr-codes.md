# Coduri QR — amplasare, scanare, printare

[← Înapoi la cuprins](../README.md)

Etichetele QR sunt puntea fizică între peștera reală și datele din
SpeleoLoc: le printați la suprafață, le lipiți pe rocă și le scanați în
subteran ca să știți exact unde vă aflați.

<a id="what-a-printed-label-contains"></a>

## Ce conține o etichetă printată

Implicit, pixelii codifică `sp://` urmat de identificatorul resursei
codului QR al locului — de exemplu `sp://k3f9x2`. `sp://` este schema
de linkuri proprie SpeleoLoc: pe Android sistemul propune SpeleoLoc ca
aplicație pentru deschiderea unui astfel de link, în timp ce pe iOS
nimic nu o revendică. Un telefon fără SpeleoLoc nu obține oricum nimic
utilizabil dintr-o etichetă `sp://`.

Două setări schimbă ce se printează. Niciuna dintre ele nu schimbă
identificatorul stocat în baza dumneavoastră de date.

- Dezactivarea opțiunii **Setări → Generare grafică cod QR → Include
  prefix deep link** printează identificatorul simplu, fără prefix —
  util când aceleași etichete sunt citite și de un alt sistem.
- Completarea câmpului **Adresa de destinație pentru etichetele
  tipărite**, din aceeași pagină de setări, printează acea adresă urmată
  de identificator (`https://speo.example.org/q/k3f9x2`), pe care camera
  oricărui telefon o poate deschide în browser. Adresa de destinație are
  prioritate față de prefixul deep link: cât timp una este setată,
  comutatorul **Include prefix deep link** rămâne gri.

Scanerul propriu al aplicației citește toate cele trei forme.

Sub cod, aplicația printează un rând scurt de text construit din
**Șablon etichetă cod QR**, care implicit conține titlul locului și
adâncimea lui (`@place_title, @depth`). Codul lizibil al locului *nu*
este printat decât dacă adăugați chiar dumneavoastră
`@place_code_identifier` în acel șablon. Vedeți
[Coduri de loc (PCI) și conținuturi QR (QCRI)](place-code-identifiers.md)
pentru ce sunt cei doi identificatori și cum alegeți între ei.

## Scanarea unui cod

### Unde se află butonul de scanare

| Unde | Buton |
|---|---|
| Ecranul principal | **Scanează QR** în bara de sus — sau primul buton din bara de acțiuni, când **Afișează bara de acțiuni** este activat |
| Lista de locuri a unei peșteri | **Scanează QR**, primul buton din bara de sus |
| Meniul aplicației | **Scanează** |
| Formularul locului din peșteră | butonul de scanare de pe rândul **Identificator resursă cod QR** — acesta *completează câmpul*, nu navighează nicăieri |

Scanerul este o simplă vizualizare a camerei, intitulată **Scanează
QR**, cu un buton de lanternă în bara de sus care aprinde și stinge
lanterna telefonului fără a părăsi camera. În subteran, lanterna este de
obicei cea care face lizibilă o etichetă murdară sau cu contrast slab —
dar consumă rapid bateria, așa că stingeți-o la loc. Scanerul se închide
singur în momentul în care detectează un cod.

### Ce face aplicația cu ce a citit

Conținutul citit este curățat înainte de orice căutare:

- prefixul `sp://` este întotdeauna eliminat;
- o adresă simplă `http://` sau `https://` este redusă la partea de după
  ultimul `/` sau `=`, astfel încât o etichetă printată de un alt sistem
  ca `https://example.org/cave/ABC12` se rezolvă tot la `ABC12`.

Tratarea URL-urilor se configurează în **Setări → Generare grafică cod
QR → Setări scanare QR**: **Extrage identificatorul din URL** o
dezactivează complet, iar **Caractere delimitatoare URL** schimbă ce
caractere sunt folosite pentru a găsi punctul de tăiere.

Ce rămâne este căutat **atât** în identificatorul resursei codului QR,
**cât și** în identificatorul cod loc al locurilor din peșteră, fără să
conteze majusculele. Asta face util codul lizibil scris cu markerul
lângă etichetă: îl tastați în căutarea manuală și se rezolvă la fel de
bine ca scanarea.

Apoi:

- **Un singur loc din peșteră găsit** → aplicația deschide acel loc **pe
  prima hartă care are un punct pentru el**, așa că vedeți imediat unde
  vă aflați pe planul peșterii. Dacă nicio hartă nu are un punct pentru
  acel loc, apare mesajul „Acest loc din peșteră nu este definit pe
  nicio hartă." și se deschide în schimb formularul locului din peșteră.
  În ambele cazuri urmează o confirmare — „Locul din peșteră a fost
  identificat" plus titlul locului.
- **Potriviri în mai multe peșteri** → un dialog **Alege punctul /
  peșteră** listează fiecare potrivire cu peștera ei, ca să o alegeți pe
  cea corectă; oferă și o scurtătură **Deschide setări** lângă
  **Anulează**. Dezactivarea opțiunii **Setări → General → Selectează
  peștera la scanare QR ambiguă** înlocuiește dialogul cu alegerea
  tăcută a potrivirii din ultima peșteră deschisă. O scanare pornită din
  lista de locuri a unei peșteri caută doar în acea peșteră, așa că
  acolo dialogul de alegere nu apare niciodată.
- **Nicio potrivire** → mesajul scurt „Locul din peșteră nu a fost
  găsit", cu codul care a fost citit.
- **Nimic rămas după curățarea de mai sus** → mesajul scurt „Cod QR
  invalid (nu poate fi interpretat conform regulilor)".

Ultimele două sunt mesaje scurte pe ecran, nu dialoguri — scanerul s-a
închis deja când ele apar.

### Scanarea unei intrări pornește, oprește sau schimbă tura

Etichetele de intrare se comportă altfel decât toate celelalte, și
aceasta este calea cea mai rapidă de a conduce o [tură](trips.md) fără
să umblați prin meniuri.

- **Nicio tură pornită** — aplicația întreabă „Ai scanat o intrare în
  peșteră. Vrei să începi o tură nouă?" Răspundeți **Da** și apare
  dialogul **Începe o tură nouă**, cu **Titlul turei** deja completat
  (numele peșterii plus data de azi); îl modificați sau apăsați **OK**.
- **O tură este pornită pentru această peșteră** — aplicația întreabă
  „Ai scanat o intrare în peșteră. Ieși din peșteră? Oprești tura
  activă?" **Da** o oprește și confirmă cu „Tură oprită". **Nu**
  înregistrează pur și simplu scanarea ca încă un punct al turei.
- **O tură este pornită pentru altă peșteră** — aplicația numește acea
  peșteră și întreabă dacă să îi oprească tura; dacă acceptați, vă
  propune apoi să începeți o tură nouă pentru peștera în care vă aflați.

Cât timp o tură este activă, scanarea oricărui loc **obișnuit** din
aceeași peșteră înregistrează tăcut un punct de tură și confirmă cu
„Punct adăugat la tură" — așa că traseul prin peșteră se construiește
singur pe măsură ce scanați.

### Tastarea unui cod în loc de scanare

Când o etichetă este deteriorată sau camera nu focalizează pe o
suprafață udă, puteți introduce codul manual:

1. Deschideți lista de locuri a peșterii și apăsați **Căutare manuală
   cod QR** din bara ei de sus.
2. Se deschide un mic panou de căutare direct în pagină; tastați codul
   în câmpul **Mod de generare identificatori cod QR**.
3. Apăsați **Caută loc după id cod QR**.

De acolo încolo, aplicația se comportă exact ca și cum ați fi scanat
eticheta. Pentru că panoul rămâne deschis, este varianta comodă când
lucrați cu mai multe coduri scrise de mână, unul după altul.

Versiunile de dezvoltare adaugă o scurtătură pe care aplicația publicată
nu o are: țineți apăsat butonul de scanare circa două secunde și
jumătate — pe ecranul principal, pe lista de locuri a unei peșteri sau
pe butonul de scanare din formularul locului din peșteră — și se
deschide aceeași **Căutare manuală cod QR**, ca dialog. În aplicația
publicată, apăsarea lungă nu face nimic.

### Permisiunea pentru cameră

Prima dată când scanați, telefonul cere permisiunea pentru cameră. Dacă
ați refuzat-o definitiv, scanerul nu se mai deschide: un dialog
**Permisiune necesară** explică asta și oferă **Deschide setări**, care
vă duce în setările de sistem ale aplicației, ca să o puteți acorda. Un
refuz care nu este definitiv produce doar mesajul „Permisiune pentru
cameră refuzată". Acordați-o la suprafață, înainte de a coborî.

## Printarea etichetelor

### Pentru o singură peșteră

1. Deschideți **lista de locuri** a peșterii și apăsați butonul de
   imprimantă (**Printează coduri QR**) din bara de sus. Dacă ați bifat
   mai întâi locuri individuale în listă, doar acelea primesc etichetă;
   altfel, toate locurile din peșteră.
2. Se deschide ecranul **Coduri QR generate**, care construiește fișierul
   imediat. În modul PDF, foaia A4 finalizată este afișată chiar acolo —
   derulați și apropiați degetele ca să verificați că etichetele au
   dimensiunea dorită. În modul Imagini nu este nimic de previzualizat și
   ecranul afișează „Nu sunt fișiere generate"; exportul funcționează
   totuși.
3. Bara de sus a acelui ecran conține **Regenerare PDF** plus scurtături
   către **Setări generare QR** și **Setări ieșire PDF** — revenirea din
   oricare dintre ele reconstruiește foaia cu modificările dumneavoastră.
4. Apăsați **Exportă** în dreapta jos și alegeți unde să puneți
   fișierul. Un PDF este oferit ca `cave_places_qr.pdf`; imaginile sosesc
   întotdeauna ca un singur `qr_codes.zip` care conține câte un PNG per
   etichetă, fiecare denumit după locul lui.

> 📷 [Previzualizarea etichetelor QR generate](../screenshots/04-places-and-qr-codes.md#qr-labels-pdf-preview) — Previzualizarea foii cu etichete QR generate, înainte de export.

Dacă obțineți un PDF sau imagini se decide dinainte, nu în acest ecran:
**Setări → Generare grafică cod QR → Ieșire QR** oferă **PDF** (o foaie
tip grilă, pe mai multe pagini) sau **Imagini** (câte un PNG per
etichetă).

### Pentru mai multe peșteri deodată

Lista de peșteri de pe ecranul principal are un buton **Generează coduri
QR pentru peșteri**, care produce o singură foaie de printat pentru mai
multe peșteri. Folosește peșterile bifate sau — dacă nu este bifată
niciuna — toate peșterile lăsate vizibile de filtrul dumneavoastră. Când
vreuna dintre acele peșteri conține locuri care nu sunt intrări,
SpeleoLoc întreabă dacă să genereze **Doar intrări** sau **Toate
locurile**, ceea ce este calea rapidă de a face un set de marcaje de
intrare pentru o zonă carstică întreagă. Fiecare etichetă este atribuită
peșterii ei, așa că `@cave_title` din șablon printează numele corect
pentru fiecare cod.

### Pentru locuri care nu există încă

Puteți printa etichete pentru locuri pe care nu le-ați cartat încă,
duceți banda în subteran și le lipiți pe parcurs.

- În lista de locuri a unei peșteri, **Generează coduri QR pentru locuri
  (interval)** cere un interval **De la indexul** / **Până la indexul**
  și compune codurile pe care acele locuri *le-ar* primi.
- Într-o arie de suprafață, **Generează coduri QR de intrare
  (interval)** face același lucru pentru intrările de peșteră, pentru
  numerotarea peșterilor pe care nu le-ați înregistrat încă.

În ambele cazuri codurile sunt trimise direct în ecranul **Coduri QR
generate** pentru printare; nimic nu se scrie în baza de date. Indicii
care aparțin deja unei peșteri sau unui loc real sunt omiși, iar
aplicația raportează câți, și se produc cel mult 500 de coduri odată.
Aceasta cere strategia ierarhică de coduri de loc, cu codurile de țară
și de organizație deja setate — iar pentru locuri, o peșteră care are
index local. Dacă unul dintre acestea lipsește, aplicația spune care.

## Setări care dau forma etichetei printate

> 📷 [Setări de generare QR](../screenshots/04-places-and-qr-codes.md#settings-qr-generation) — Setările care controlează felul în care etichetele QR sunt desenate și scanate.

Tot ce urmează se află în **Setări → Generare grafică cod QR**, cu
excepția grilei, care este în **Setări → Ieșire PDF**.

| Setare | Ce face |
|---|---|
| **Ieșire QR** | **PDF** (foaie tip grilă) sau **Imagini** (câte un PNG per etichetă). |
| **Dimensiune QR (px)** | Dimensiunea unui cod PNG generat. Într-un PDF, fiecare cod este încadrat în schimb în celula lui de grilă. |
| **Spațiu imagine QR (px)** | Marginea albă din jurul unui cod PNG generat. |
| **Dimensiune font etichetă** | Folosită ca atare pentru etichetele PNG. În PDF, părțile din șablon care nu au propria dimensiune `#fz` sunt desenate la jumătate din această valoare, limitată între 6 și 14 pt. |
| **Familie font etichetă** | Afișată, dar deocamdată nu schimbă nimic — etichetele din PDF sunt scrise întotdeauna cu fontul inclus în aplicație, ca diacriticele românești să se printeze corect. |
| **Culoare prim-plan QR** | Culoarea modulelor codului, atât pe foi cât și pe imagini. Tastați o valoare `0xAARRGGBB` sau apăsați pastila de culoare de lângă ea pentru **Alege culoare** dintr-o paletă sau din roata de culori. |
| **Culoare fond QR** | Afectează doar previzualizarea QR a unui singur loc și imaginea exportată din acea previzualizare. PDF-urile și PNG-urile generate în lot sunt produse întotdeauna pe alb. |
| **DPI (calitate)** | Afișată, dar deocamdată nu schimbă nimic în rezultat. |
| **Corecția erorii** | **L**, **M** (implicit), **Q** sau **H** — cât dintr-un cod deteriorat mai poate fi citit. Se aplică la PDF, la imagini și la previzualizare. |
| **Exportă imaginile ca zip** | Nu are efect în ecranul **Coduri QR generate**, care exportă întotdeauna imaginile ca un singur ZIP. |
| **Include prefix deep link** | Activat implicit: codul poartă `sp://` plus identificatorul. Dezactivat: identificatorul simplu. Gri cât timp este setată o adresă de destinație. |
| **Adresa de destinație pentru etichetele tipărite** | Goală implicit. O setați și codul poartă acea adresă plus identificatorul în loc de `sp://`, așa că o poate deschide în browser camera unui necunoscut. |
| **Spațiere cod QR în PDF (pt)** | **Spațiere orizontală** și **Spațiere verticală** în jurul fiecărui cod, în celula lui de grilă — asta decide cât de mare se printează un cod. |
| **Coduri QR pe pagină** (Ieșire PDF) | **Coloane** (1–10) × **Rânduri** (1–20) pe o pagină A4. Implicit 4 × 5. |

Modulele QR și cele trei repere din colțuri sunt printate întotdeauna ca
pătrate nete; nu există opțiune de formă.

### Șablonul etichetei

Textul de sub fiecare cod printat este construit din **Șablon etichetă
cod QR**, aflat la baza paginii de generare a codurilor QR. Apăsarea
oricăreia dintre variabilele listate sub **Variabile disponibile** o
inserează la poziția cursorului.

| Variabilă | Semnificație |
|---|---|
| `@place_title` | Titlul locului din peșteră |
| `@description` | Descrierea locului din peșteră |
| `@cave_title` | Titlul peșterii |
| `@area_title` | Titlul ariei peșterii |
| `@place_code_identifier` | Identificator pentru loc / punct (PCI) |
| `@qr_res_identifier` | Identificator resursă cod QR (QCRI) |
| `@depth` | Adâncime în peșteră, întotdeauna cu semn `+` sau `-` |
| `\n` | Linie nouă |

Prefixele de formatare se pun imediat înaintea variabilei la care se
aplică:

- `#fz<number>` — dimensiunea fontului, ex. `#fz14@place_title`.
- `#fc<color>` — culoarea fontului ca triplet hexazecimal, ex.
  `#fcFF0000@depth`.

Exemplu de șablon:

```
#fz14@place_title\n#fz10#fc888888@depth\n#fz9@place_code_identifier
```

O variabilă care nu se rezolvă la nimic nu lasă în urmă virgule sau
liniuțe rătăcite — rândurile goale și separatorii rămași sunt curățați
automat.

## Verificarea unui singur cod înainte de a printa un lot

Deschideți un loc din peșteră salvat și apăsați butonul QR din extrema
stângă a rândului **Identificator resursă cod QR** (**Vizualizează cod
QR**). Dialogul codifică același conținut ca o etichetă printată, la
același nivel de corecție a erorilor, cu titlul locului sub el și
identificatorul dedesubt. Butonul apare doar după ce locul a fost salvat
și are un cod.

Două butoane din partea de jos a acelui dialog merită cunoscute:

- Butonul de informații deschide **Informații cod QR**, care raportează
  **Versiune** codului QR, **Dimensiune** grilei de module (de exemplu
  33×33), nivelul de **Corecție erori** scris în cuvinte (Scăzut /
  Mediu / Cuartilă / Înalt) și, la **Conținut codificat**, exact ce se
  codifică — inclusiv prefixul `sp://` sau adresa de destinație, când
  este folosită una. **Copiază valoarea** pune acel conținut în
  clipboard. Cu cât un cod are mai multe module, cu atât mai mare
  trebuie printată eticheta ca să rămână lizibilă la lumina frontalei,
  așa că acesta este cel mai ieftin mod de a judeca dimensiunea unei
  etichete înainte de a arunca un lot întreg pe hârtie impermeabilă.
- Butonul de descărcare exportă acel singur cod ca
  `qr_<place title>.png` — util pentru înlocuirea punctuală a unei
  etichete deteriorate, fără a reprinta tot lotul. SpeleoLoc întreabă
  mai întâi dacă să facă **Salvează în Imagini**, arătând exact folderul
  pe care îl va folosi, sau **Alege locație…**. Această imagine singură
  poartă titlul locului sub cod, nu șablonul de etichetă din lot.

## Atribuirea unui cod unui loc

Formularul unui loc din peșteră are două rânduri: **Identificator cod
loc** și **Identificator resursă cod QR**. Fiecare are propriul lacăt,
propriul buton-scânteie **Generează automat**, și amândouă se deschid
**blocate** de fiecare dată — ca un cod existent să nu poată fi schimbat
din greșeală.

1. Apăsați lacătul din stânga câmpului (**Activează editarea codului
   QR**) ca să îl faceți editabil. Butonul Generează automat de lângă el
   rămâne gri până când faceți asta.
2. Tastați codul sau apăsați **Generează automat** ca să calculați unul
   cu [strategia](place-code-identifiers.md) activă.
3. Salvați.

Când identificatorul resursei codului QR oglindește codul locului și
cele două valori sunt identice, rândul **Identificator cod loc** este
ascuns cu totul; apăsați butonul-ochi (**Afișează codul locului**) de pe
rândul ariei peșterii aflat imediat deasupra ca să îl aduceți înapoi.

Butonul de scanare de pe rândul **Identificator resursă cod QR** citește
o etichetă existentă în acel câmp, în loc să navigheze undeva.
Completează și codul locului atunci când cele două se oglindesc și codul
locului este încă gol. Apoi previzualizarea QR se deschide singură, ca
să verificați ce s-a citit. Trei lucruri o pot întrerupe:

- același cod este deja în câmp → „Același cod QR este deja prezent";
- codul aparține altui loc → „QR code este deja folosit pentru", cu
  numele acelui loc, și nu se completează nimic;
- câmpul conține deja un cod *diferit* → **Înlocui codul QR?** întreabă
  „Un cod QR diferit este deja setat pentru acest loc. Doriți să-l
  înlocuiți?" Aceasta înlocuiește doar valoarea din câmpul din fața
  dumneavoastră; niciun alt loc nu este atins.

### Coduri duplicate la salvare

Salvarea unui loc al cărui **cod de loc** este deja folosit de un alt
loc **din aceeași peșteră** afișează un dialog **Cod QR duplicat** care
spune 'Locul "…" folosește deja codul QR …. Salvați cu duplicat?', cu
**Anulează** (nu se salvează nimic) și **Da** (duplicatul este păstrat).
Dacă ați modificat manual **Identificator resursă cod QR** și acesta
intră în coliziune cu un loc din *orice* peșteră, apare același dialog.
În niciunul dintre cazuri celălalt loc nu este modificat.

Duplicatele în peșteri diferite sunt permise și sunt exact motivul
pentru care există dialogul **Alege punctul / peșteră**.

## Montarea etichetelor în peșteră

- Printați pe **material de etichetă impermeabil** sau laminați.
- Folosiți corecția erorilor **M** sau **Q**, ca o murdărire parțială să
  rămână lizibilă. **H** rezistă la mai multe deteriorări, dar cere mai
  multe module, adică o etichetă fizic mai mare.
- Păstrați **module închise pe alb** — varianta implicită și cea mai
  ușor de recunoscut de o cameră la lumina lanternei.
- Lipiți-le pe rocă curată și uscată acolo unde puteți; evitați
  suprafețele noroioase sau care se exfoliază.
- Scrieți **codul locului** lângă etichetă cu marker permanent, ca
  soluție de rezervă. Aplicația îl acceptă în căutarea manuală, deși
  pixelii QR poartă celălalt identificator.
- Înainte de un tiraj mare, definiți punctele de pe hărți pentru
  locurile pe care le etichetați — o scanare care nu găsește niciun
  punct pe nicio hartă deschide formularul simplu al locului, în loc să
  vă arate unde vă aflați.

## Vezi și

- [Coduri de loc (PCI) și conținuturi QR (QCRI)](place-code-identifiers.md)
- [Locuri din peșteră](cave-places.md)
- [Deep linkuri (`sp://`)](deep-links.md)
- [Ture — înregistrarea traseului](trips.md)
- [Navigare în subteran](../workflows/navigating-underground.md)
- [Setări](settings.md)
