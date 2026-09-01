# Hărți

[← Înapoi la cuprins](../README.md)

O **hartă** este o imagine a unei ridicări topografice — o scanare, o
fotografie a unui desen sau o imagine exportată dintr-un program de
topografie — pe care o atașați unei peșteri. SpeleoLoc nu desenează
niciodată singur o hartă: dumneavoastră furnizați imaginea, apoi fixați
pe ea locurile din peșteră, astfel încât o scanare QR sau o baliză să vă
poată arăta mai târziu unde vă aflați.

Etichetele folosite mai jos sunt cele în limba română. Aplicația pornește
în română; limba se schimbă din **Setări → General → Limba aplicației**.

## Deschiderea hărților unei peșteri

1. Deschideți peștera din ecranul principal.
2. Apăsați **pictograma de hartă** din bara de instrumente de deasupra
   listei de locuri din peșteră (indiciu *Vezi hărți*).

Ecranul **Hărți** listează fiecare hartă atașată acelei peșteri, în
ordinea în care le-ați aranjat. Fiecare rând arată o miniatură pătrată a
imaginii și titlul hărții — și nimic altceva; tipul hărții nu este afișat
aici, iar hărțile nu sunt legate de zonele peșterii.

| Control | Ce face |
|---|---|
| Apăsare pe rând | Deschide imaginea pe tot ecranul, unde puteți mări prin ciupire și deplasa imaginea pentru a examina scanarea. Nu sunt desenate puncte și nimic nu poate fi editat acolo. Dacă fișierul imagine a dispărut, apăsarea pe rând deschide în schimb **Editează harta**, ca să puteți alege din nou imaginea. |
| Creion | **Editează harta** — schimbați titlul sau tipul hărții, ori înlocuiți imaginea. |
| Coș | **Șterge harta** — vedeți [Ștergerea unei hărți](#deleting-a-map). |
| **+** din bara de sus | **Adaugă hartă**. Indisponibil cât timp modul de reordonare este activ. |
| Pictograma de sortare din banda de sub bara de sus | Comută lista în modul **Reordonare hărți**. |

Același ecran este accesibil și în timp ce lucrați pe o hartă: butonul ⋮
din bara laterală a hărții și meniul ecranului oferă amândouă
**Administrare hărți**.

> 📷 [Hărțile unei peșteri](../screenshots/03-raster-maps.md#cave-raster-maps-list) — Lista Hărți a unei peșteri, cu acțiunile de editare și ștergere pentru fiecare hartă.

## Adăugarea unei hărți

1. Pe ecranul **Hărți**, apăsați **+** (indiciu *Adaugă hartă*).
2. Apăsați **Selectează imagine** și alegeți harta din fotografiile
   dispozitivului. Selectorul oferă numai imagini, așa că un PDF sau un
   fișier de hartă care nu se află în galeria foto trebuie salvat mai
   întâi ca imagine.
3. Scrieți un **Titlu**. Acesta este numele pe care îl veți vedea pe
   fiecare bandă și filă de hărți, deci merită completat — dacă îl lăsați
   gol, aplicația inventează un nume pornind de la propria copie a
   fișierului, ceva de forma `raster_1756713600000`.
4. Alegeți **Tip hartă** (vedeți mai jos). Hărțile noi pornesc ca
   *vedere plană*.
5. Apăsați **Salvează**.

Dacă lipsește imaginea sau tipul, apare *Selectați o imagine și un tip de
hartă* și nu se salvează nimic.

SpeleoLoc copiază imaginea în propriul spațiu de stocare, așa că harta
funcționează mai departe după ce mutați, redenumiți sau ștergeți
fotografia originală. Copia păstrează rezoluția pe care ați ales-o —
aplicația nu o micșorează.

### Tipuri de hartă

| Tip | Semnificație |
|---|---|
| **vedere plană** | Planul peșterii văzut de sus. |
| **profil proiectat** | Secțiune verticală, proiectată pe un singur plan. |
| **profil extins** | Secțiune verticală, desfășurată de-a lungul galeriei. |
| **Altele** | Orice altceva — fotografia unei schițe de ridicare, o secțiune transversală, o topografie de echipare. |

Tipul este o etichetă pe care o alegeți pentru uzul dumneavoastră. Nu
este afișat nicăieri în afara formularului de adăugare/editare, nu are
niciun efect asupra locului în care ajung punctele, iar lista de hărți nu
este nici ordonată, nici grupată după el. Singurul lui efect practic este
că o peșteră nu poate avea două hărți care au în comun *și* titlul, *și*
tipul — exact ceea ce vă permite să țineți alături o vedere plană
„Sistemul principal” și un profil extins „Sistemul principal”.

### Când aplicația vă oprește

SpeleoLoc încearcă să vă împiedice să atașați de două ori aceeași hartă.

- Dacă o altă hartă din această peșteră are deja acel titlu **și** acel
  tip, salvarea este refuzată cu *Există deja o hartă cu același titlu și
  tip pentru această peșteră*. Schimbați titlul sau tipul și încercați
  din nou.
- Dacă imaginea aleasă este identică octet cu octet cu una deja atașată
  acestei peșteri, un dialog **Imagine duplicată** numește harta
  existentă și oferă **Salvează oricum** sau **Anulează** — așa că o a
  doua copie făcută intenționat rămâne posibilă.

## Ordonarea și sortarea listei de hărți

### Ordine manuală

Apăsați pictograma de sortare din banda de deasupra listei, pe ecranul
**Hărți**. Apare indicația *Trageți rândurile pentru reordonare*,
creionul și coșul sunt înlocuite de un mâner de tragere, iar rândurile
pot fi trase în orice ordine doriți. Fiecare așezare este salvată
imediat. Apăsați din nou pictograma (indiciu *Terminat reordonarea*)
pentru a ieși din modul de reordonare.

Această ordine manuală este ordinea în care apar hărțile peste tot în
rest — benzile de hărți, filele de hărți de pe un loc din peșteră,
vizualizatorul de hărți — atât timp cât sortarea hărților este lăsată pe
*Ordine manuală*.

### Sortare hărți

Orice ecran cu hărți oferă **Sortare hărți**, din meniul ecranului sau de
la butonul ⋮ din bara laterală a hărții. Alegeți un câmp și o direcție:

| Câmp de sortare | Ordonează după |
|---|---|
| **Ordine manuală** | Ordinea stabilită prin tragere (implicită). |
| **Număr de locuri** | Câte locuri din peșteră sunt fixate pe fiecare hartă. |
| **Titlu (alfabetic)** | Titlul hărții. |
| **Dimensiune hartă** | Dimensiunea fișierului imagine. |

Aleasă în vizualizatorul de hărți în doar-citire sau în **Vedere hartă** a
unui traseu, setarea este ținută minte între sesiuni. Aleasă în
**Poziționare locuri pe hartă**, reordonează banda doar pentru vizita
curentă.

### De ce contează ordinea

Când scanați codul QR al unui loc sau când SpeleoLoc îi prinde baliza
BLE, aplicația nu deschide pur și simplu pagina locului: parcurge hărțile
peșterii în această ordine și deschide **prima** hartă care are deja un
punct pentru acel loc, centrată pe reper. Așadar harta pe care vreți să o
vedeți în subteran ar trebui să fie prima care poartă punctele
dumneavoastră. Dacă nicio hartă nu are un punct pentru acel loc, ajungeți
în schimb pe pagina locului din peșteră — după o scanare QR, cu mesajul
*Acest loc din peșteră nu este definit pe nicio hartă.*

## Fixarea locurilor din peșteră pe o hartă

Fixarea locurilor se face în **Poziționare locuri pe hartă**. Puteți
ajunge acolo în trei feluri:

- din secțiunea **Hărți** a unui loc din peșteră — alegeți fila hărții și
  apăsați butonul de reper de pe previzualizare (indiciu *Definește locul
  pe hartă*), sau pur și simplu apăsați previzualizarea. Aceasta pornește
  în modul *definire punct nou*, pregătită pentru locul pe care tocmai îl
  priveați;
- din meniul ecranului peșterii, **⋮ → Poziționare locuri pe hartă**, sau
  din pictograma de reper din bara peșterii. Aceasta deschide prima hartă
  a peșterii cu primul loc din listă selectat, în modul *selectare loc
  existent*;
- din contorul de repere de pe rândul unui loc din peșteră — vedeți
  [Verificarea hărților pe care se află un loc](#checking-which-maps-a-place-is-on).

Dacă peștera nu are încă hărți, primiți *Nu există hărți pentru această
peșteră*; dacă nu are locuri, *Nu există locuri în această peșteră*.

### Cele două benzi de deasupra imaginii

- **Banda de hărți** este un rând de miniaturi de hărți. Apăsați una
  pentru a schimba imaginea de dedesubt fără a părăsi ecranul.
- **Banda de locuri din peșteră** este un rând de insigne rotunde,
  fiecare arătând prima literă din numele unui loc. Culoarea vă spune
  starea lui *pe harta pe care o priviți acum*: gri înseamnă că nu are
  încă punct, roșiatic înseamnă că este deja fixat. Locul curent este
  desenat mai mare și devine albastru odată ce are un punct. Parcurgerea
  benzii după insigne gri este cel mai rapid mod de a vedea cât dintr-o
  peșteră a rămas nefixat.

Apăsarea unei insigne face acel loc curent, deplasează harta la reperul
lui și derulează banda. Dacă locul nu are punct pe această hartă, nu
există nimic către care să se deplaseze — locul devine totuși curent, așa
că îi puteți așeza punctul imediat.

Oricare dintre benzi poate fi ascunsă pentru a reda înălțimea imaginii:
butonul de straturi din bara laterală are casetele de bifat **Afișează
lista hărților** și **Afișează lista locurilor**. Orice acțiune care are
nevoie de o bandă ascunsă o readuce singură, așa că nu puteți rămâne
blocat.

### Așezarea unui punct

1. Selectați în bandă locul dorit.
2. Asigurați-vă că butonul de mod de atingere arată *Mod atingere:
   Definește punct nou* (apăsați-l pentru a comuta; o etichetă în
   stânga-jos a imaginii confirmă modul câteva secunde).
3. Apăsați pe imagine acolo unde se află locul în realitate.

Punctul este scris atunci când **treceți mai departe** — la locul
următor, la altă hartă, sau când folosiți butoanele de adăugare rapidă,
de legendă, de mod de atingere, *Deschide locul* sau *Documente*. Prima
dată când se întâmplă asta într-o rulare a aplicației, un dialog întreabă
*Salvați automat punctul curent când comutați la alt loc sau hartă?*;
răspundeți **Da** și nu mai sunteți întrebat până când reporniți
aplicația. Răspunsul **Anulează** abandonează și salvarea, și comutarea.
Nu există un buton de salvare separat, iar ieșirea din ecran imediat după
apăsare **nu** stochează punctul.

Cât timp un loc este selectat, aveți la dispoziție două corecții:

- **Resetează punctul la poziția inițială** (săgeata de anulare) — aruncă
  punctul tocmai apăsat și revine acolo unde se afla locul înainte;
  totodată recade în modul *selectare loc existent*, astfel încât o
  apăsare rătăcită de după să nu îl poată redefini.
- **Elimină definiția punctului** (coșul) — întreabă *Eliminați definiția
  punctului pentru acest loc pe harta curentă?* și, la **Da**, șterge
  punctul locului de pe această hartă. Locul în sine și punctele lui de
  pe alte hărți rămân neatinse.

> 📷 [Definirea unui punct pe o hartă](../screenshots/03-raster-maps.md#raster-map-define-point) — Fixarea locurilor din peșteră pe o ridicare scanată, cu editorul de puncte de pe hartă.

### Parcurgerea unei peșteri întregi

Primul buton din bara laterală a hărții (o țintă) este *Următorul loc
fără coordonate*. Sare la locul următor care nu are punct pe această
hartă, reluând de la capăt când ajunge la sfârșit, dezvăluie banda de
locuri și derulează până la acel loc. Indiciul lui numără cât a mai rămas
— *Următorul loc fără coordonate (7 rămase)* — și devine gri, cu *Toate
locurile au deja o locație definită*, când ați terminat.

Lupa de lângă el (în meniu, **Filtrare locuri peșteră**) deschide o
casetă de căutare deasupra benzii. Pe măsură ce scrieți, banda se
îngustează la locurile al căror nume, descriere, cod loc sau zonă peșteră
conține ce ați scris. Pe imaginea propriu-zisă, locurile care nu se
potrivesc nu dispar: rămân ca puncte palide, fără etichete, ca să nu vă
pierdeți orientarea. Goliți caseta, sau apăsați din nou lupa, pentru a
readuce tot.

**Sortare locuri peșteră** reordonează banda — după ultima modificare,
titlu, zonă peșteră, adâncime, identificator cod QR, tip intrare, după
dacă locul are cod QR sau după pe câte hărți este deja fixat, crescător
sau descrescător. Alegerea este ținută minte; până când faceți una, banda
urmează sortarea folosită ultima dată în lista de locuri din peșteră.
Sortarea după zonă peșteră face ceva în plus: banda este împărțită în
mici casete cu chenar, câte una pentru fiecare zonă, cu numele zonei
deasupra, ca să puteți lucra pe rând la câte o parte din peșteră.

### Adăugarea unui loc nou de pe hartă

Bara de acțiuni are un buton reper-cu-plus, *Adăugare loc peșteră*.
Apăsați-l și devine verde, cu mesajul *Atingeți harta pentru a defini
punctul pentru noul loc din peșteră*. Apăsați imaginea și se deschide un
dialog scurt de adăugare a locului; confirmați-l și locul este creat
**și** punctul lui stocat în punctul apăsat, dintr-un singur pas. Modul
rămâne armat, așa că puteți parcurge o galerie adăugând loc după loc.
Apăsați din nou butonul verde pentru a-l opri.

### Ajungerea la locul propriu-zis

Odată ce un loc este selectat, la capătul barei de acțiuni apar încă două
butoane: **Deschide locul**, care sare la pagina completă a acelui loc,
și **Documente**, care deschide fotografiile și fișierele atașate lui.
Amândouă stochează punctul tocmai apăsat înainte de a naviga, așa că nu
se pierde nimic. Sunt prezente și în vizualizatorul de hărți în
doar-citire, ceea ce îl face un mod practic de a răsfoi o peșteră:
găsiți reperul, citiți locul, priviți-i fotografiile, reveniți.

Apăsați lung orice reper pentru a primi un mesaj scurt care numește locul
căruia îi aparține — util într-un colț aglomerat al unei ridicări, unde
etichetele se suprapun.

<a id="checking-which-maps-a-place-is-on"></a>

## Verificarea hărților pe care se află un loc

Fiecare rând din lista de locuri din peșteră poartă o pictogramă de reper
cu un număr: pe câte dintre hărțile peșterii este fixat acel loc. Este
roșie la zero, verde când locul se află pe toate hărțile peșterii și gri
între cele două.

Apăsați-o și dialogul **Definiții hărți** listează toate hărțile
peșterii, fiecare cu o bifă verde sau un cerc roșu pentru acest loc.
Apăsarea unei hărți din acea listă deschide **Poziționare locuri pe
hartă** pe acea hartă, cu acest loc selectat.

## Citirea unei scanări în subteran

Efectele de imagine din bara laterală a hărții fac lizibile scanările
palide sau întunecate fără a modifica vreodată imaginea stocată:
**Inversare culori** are propriul buton, iar butonul cu cursoare deschide
**Procesare imagine** cu *Normal (fără filtru)*, *Inversare culori*,
*Tonuri de gri*, *Sepia*, *Contrast ridicat*, *Roșu noapte* și
*Combinare efecte…*, ultimul deschizând un panou în care efectele pot fi
suprapuse, iar luminozitatea și contrastul reglate. Fiecare hartă își
păstrează ultimul efect folosit până când închideți aplicația.

**Ecran complet** ascunde benzile și bara de sus, astfel încât imaginea
primește tot ecranul. Cât timp ecranul complet este activ, butonul Înapoi
al telefonului sau gestul de întoarcere iese din ecranul complet, în loc
să părăsească ecranul; apăsați-l din nou după aceea pentru a ieși.

Gesturile, butoanele de zoom din colțul din dreapta-jos, legenda
punctelor și restul barei laterale sunt descrise în
[Vizualizatorul de hărți și editorul de puncte](map-viewer.md).

> 📷 [O hartă în vizualizatorul pe tot ecranul](../screenshots/03-raster-maps.md#raster-map-full-screen) — O hartă de peșteră deschisă pe tot ecranul pentru examinare cu mărire prin ciupire.

Scanările foarte mari (zeci de megapixeli) funcționează, dar se deschid
mai greu pe un telefon modest; merită reduse la rezoluția pe care o
puteți citi efectiv, înainte de import. Odată deschisă, o imagine este
ținută decodată în memorie, așa că trecerea dintr-o hartă în alta este
rapidă.

## Când o imagine dispare

Dacă fișierul imagine al unei hărți nu mai există — de exemplu după
restaurarea unei baze de date fără imagini — SpeleoLoc vă spune asta în
loc să afișeze un ecran gol. Miniatura din benzi devine o pictogramă de
imagine ruptă, **Poziționare locuri pe hartă** arată *Imaginea nu a fost
găsită*, iar apăsarea hărții pe ecranul **Hărți** vă duce direct în
**Editează harta**, unde *Avertisment: Fișierul imagine nu a fost găsit*
vă spune ce s-a întâmplat, ca să puteți alege din nou imaginea. Fiecare
punct deja așezat pe acea hartă este păstrat.

Ca să evitați asta când mutați date între dispozitive, bifați **Include
imagini hărți** la export — vedeți
[Exportul și importul bazei de date](database-export-import.md).

<a id="deleting-a-map"></a>

## Ștergerea unei hărți

Ștergerea unei hărți este definitivă și elimină definiția punctului
fiecărui loc din peșteră de pe acea hartă. Locurile în sine, și punctele
lor de pe *alte* hărți, nu sunt afectate.

Vi se cere întotdeauna să confirmați. Dacă harta poartă puncte,
întrebarea vă spune exact câte se vor pierde; altfel este un simplu
da/nu. Fișierul imagine în sine rămâne în spațiul de stocare al
aplicației, așa că ștergerea unei hărți nu eliberează spațiu.

## Vezi și

- [Vizualizatorul de hărți și editorul de puncte](map-viewer.md)
- [Locuri din peșteră](cave-places.md)
- [Peșteri și zone de peșteră](caves-and-areas.md)
- [Coduri QR — amplasare, scanare, printare](qr-codes.md)
- [Documentarea unei peșteri noi](../workflows/documenting-a-new-cave.md)
- [Navigarea în subteran](../workflows/navigating-underground.md)
