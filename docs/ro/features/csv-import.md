# Import CSV

[← Înapoi la cuprins](../README.md)

Când datele dumneavoastră stau deja într-o foaie de calcul, SpeleoLoc le
poate citi în bloc dintr-un fișier CSV. Există două importuri separate —
unul care creează peșteri, altul care umple o singură peșteră cu locuri —
și amândouă folosesc același ecran de alegere a fișierului și de mapare a
coloanelor.

Denumirile controalelor de pe această pagină sunt cele din aplicația în
română. Aplicația pornește în română; engleza se alege din **Setări →
General → Limba aplicației**.

## Cele două importuri

| Import | De unde îl porniți | Ce scrie |
|---|---|---|
| Peșteri | **Ecranul principal → ⋮ → Import peșteri din CSV** | Peșteri, și ariile de suprafață în care se află |
| Locuri din peșteră | Deschideți o peșteră, apoi **⋮ → Import locuri din CSV** | Locuri din acea singură peșteră |

Amândouă au și câte o pictogramă de încărcare, cu o singură apăsare: pe
bara de acțiuni a paginii principale (rândul de butoane-pictogramă de sub
bara de sus, comutat din **Setări → General → Afișează bara de acțiuni pe
pagina principală**) și pe bara de instrumente a listei de locuri a unei
peșteri. Pictogramele deschid exact aceleași ecrane ca intrările din
meniu.

Importul de locuri lucrează întotdeauna pe peștera din care l-ați
deschis — nu există nicio cale de a împrăștia un fișier peste mai multe
peșteri. Ca să umpleți mai multe peșteri, importați fișierul fiecărei
peșteri din interiorul acelei peșteri; dacă peșterile nu există încă,
creați-le întâi cu importul de peșteri.

## Formatul fișierului

- Text simplu salvat ca **UTF-8**, cu extensia `.csv` sau `.txt` —
  selectorul de fișiere nu oferă altceva, iar un fișier salvat în altă
  codificare nu se încarcă și dă un mesaj de eroare.
- Primul rând trebuie să fie un **rând de antet** cu numele coloanelor.
  Numele în sine nu contează: alegeți întotdeauna dintr-o listă derulantă
  ce coloană alimentează ce câmp.
- **Separate prin virgulă.** Fișierele separate prin punct și virgulă, pe
  care multe setări europene de foi de calcul le produc implicit, se
  încarcă drept o singură coloană, fără nimic pe care să mapați câmpurile
  individuale — reexportați cu virgule.
- Valorile care conțin o virgulă sau o întrerupere de rând trebuie
  încadrate în ghilimele duble.
- Terminațiile de rând Windows și Unix funcționează amândouă.
- Coloanele pe care nu le mapați sunt ignorate. Coloanele suplimentare,
  precum adâncimea sau referințele topografice, nu strică nimic, dar
  nimic din ele nu se importă.

Un fișier gol este refuzat cu „Fișierul CSV selectat este gol.”

## Ecranul de import

Amândouă importurile deschid același ecran, iar pașii sunt întotdeauna
aceștia:

1. Apăsați **Selectează fișier CSV** și alegeți fișierul. Numele lui
   apare lângă buton.
2. Apare secțiunea **Mapare coloane**, în capul căreia stă **Rânduri de
   date găsite** — numărul de linii de după antet, inclusiv cele pe care
   importul le va lăsa mai târziu deoparte.
3. Setați câte o listă derulantă pentru fiecare câmp. Fiecare listă
   conține numele de antet din fișierul dumneavoastră plus **Niciuna**.
   Câmpurile marcate cu `*` sunt obligatorii.
4. Verificați tabelul **Previzualizare date** de sub buton: primele zece
   rânduri de date, exact așa cum a fost citit fișierul, derulându-se
   lateral dacă fișierul este lat. Folosiți-l ca să confirmați că
   separatorul și rândul de antet au fost înțelese, înainte să importați
   ceva.
5. Apăsați **Pornește importul**. Dacă un câmp obligatoriu a rămas
   nemapat, un mesaj îl numește („Nume peșteră coloana trebuie
   selectată.”) și nu se întâmplă nimic.

Prima dată când deschideți acest ecran, un scurt tur ghidat vă arată
selectorul de fișiere, maparea coloanelor și previzualizarea. El arată
doar părțile aflate pe ecran în acel moment, așa că rulați-l din nou din
**⋮ → Tur de ghidare** după ce ați încărcat un fișier, ca să vedeți și
pașii de mapare și de previzualizare.

## Importul peșterilor

### Coloanele pe care le puteți mapa

| Câmp | Obligatoriu | Ce face |
|---|---|---|
| **Nume peșteră** | Da | Numele peșterii. Totodată jumătate din fiecare verificare de duplicat. |
| **Descriere** | Nu | Text liber păstrat pe peșteră. |
| **Index local peșteră** | Nu | Numărul scurt de catalog al peșterii. Totodată o cheie de potrivire — vedeți mai jos. |
| **Zona de suprafață** | Nu | Aria în care se află peștera. O arie cu acel nume este creată dacă nu aveți încă una. |
| **Identificator zonă generală** | Nu | Codul scurt al ariei. |

Aici nu există o coloană de zonă a peșterii și niciun import CSV nu
creează zone de peșteră — pe acelea le adăugați pe locul însuși.

### Cum este aleasă aria de suprafață

Dacă una dintre [ariile dumneavoastră de suprafață](surface-areas.md)
poartă deja codul din **Identificator zonă generală**, acea arie este
folosită oricum s-ar numi, așa că puteți redenumi arii în aplicație fără
să stricați importurile ulterioare. Altfel este folosită aria numită în
**Zona de suprafață**, iar codul este scris pe ea dacă nu avea niciunul;
o arie care poartă deja un cod diferit nu este niciodată suprascrisă.
Dacă mapați numai coloana de identificator și nicio coloană de nume, se
creează o arie nouă, numită după cod. Diferența dintre majuscule și
minuscule este ignorată la compararea codurilor și a numelor de arii.

### Cum sunt potrivite rândurile cu peșterile pe care le aveți deja

Un rând contează drept o peșteră pe care o aveți deja atunci când se
potrivesc numele peșterii plus indexul local, sau atunci când se
potrivesc numele peșterii plus aria de suprafață. Diferența dintre
majuscule și minuscule este ignorată peste tot. Un rând care numește o
arie de suprafață pe care nu o aveți încă trece drept peșteră nouă, în
afară de cazul în care numele peșterii și indexul local se potrivesc cu
ale unei peșteri pe care o aveți deja.

Asta face ca cele două coloane-cheie opționale să merite mapate:

- **Cu un index local peșteră**, un rând este recunoscut ca fiind aceeași
  peșteră chiar dacă este trecută la altă arie. Aceasta este calea sigură
  de a actualiza un catalog pe care l-ați importat deja o dată.
- **Fără el**, potrivirea cade înapoi pe nume plus arie, iar o
  nepotrivire acolo produce o a doua copie a peșterii: un fișier fără
  coloană de arie nu recunoaște peșterile păstrate într-o arie, iar un
  fișier care mută o peșteră în altă arie nu o recunoaște nici el.

### Întrebările pe care le pune importul

Întâi, dacă s-au potrivit rânduri, un dialog **Înregistrări existente
găsite** raportează „Înregistrări deja existente în bază” împreună cu
numărul lor, le listează pe primele cinci și întreabă dacă să continue.
**Anulează** abandonează tot importul.

Apoi, pentru fiecare peșteră potrivită ale cărei valori păstrate diferă
de cele din fișier, apare un dialog **Actualizare peșteră existentă**,
numerotat (de exemplu 3/12), ca să vedeți câte au mai rămas. El listează
fiecare câmp care s-ar schimba sub forma „vechi → nou” — Descriere, Index
local peșteră și Zona de suprafață — și oferă patru butoane:

- **Actualizează** — aplică valorile din fișier acestei peșteri.
- **Omite** — lasă peștera așa cum este; se numără la Peșteri omise
  (duplicate).
- **Actualizează toate** / **Omite toate** — răspunde la fel pentru toate
  peșterile rămase.

Dialogul nu poate fi închis apăsând în afara lui, așa că nimic nu se
decide din greșeală.

Aprobarea unei actualizări poate și să mute peștera în aria de suprafață
numită în fișier, iar mutarea este listată ca orice altă modificare. Un
caz este lăsat în pace intenționat: dacă în aria-țintă stă deja o altă
peșteră cu același nume, mutarea este abandonată ca să nu se poată ciocni
cele două, iar restul câmpurilor se aplică oricum.

### Fiecare peșteră atinsă de import primește o intrare

Dacă nu dezactivați asta, fiecare peșteră creată de import primește un
loc de intrare principală numit **Intrare** — aceeași valoare implicită
pe care o obțineți când adăugați o peșteră de mână. Peșterile pe care
fișierul le-a potrivit primesc și ele una dacă nu au niciuna, chiar și
atunci când ați ales să nu le actualizați. Comutatorul este **Setări →
General → Adaugă automat intrarea la creare peșteră**, pornit implicit.
Opriți-l înainte de import dacă aveți de gând să adăugați dumneavoastră
intrările, altfel veți avea de curățat un loc în plus în fiecare peșteră.

### Rânduri repetate pentru aceeași peșteră

Dacă fișierul dumneavoastră listează aceeași peșteră de mai multe ori,
primul rând o creează, iar rândurile de mai târziu aplică în tăcere
descrierea sau indexul local pe care le poartă — completând ce a lăsat
gol primul rând și înlocuind o valoare care nu se potrivește. Despre
acestea nu sunteți întrebat, pentru că peștera a fost creată de același
import; ele se numără la Peșteri actualizate. Rândurile care se potrivesc
cu o peșteră aflată deja în baza de date trec în schimb prin întrebarea
de actualizare.

### Ce raportează sumarul

Un dialog **Import finalizat** încheie rularea cu patru contoare:

- **Peșteri create**
- **Peșteri actualizate**
- **Zone de suprafață create**
- **Peșteri omise (duplicate)**

## Importul locurilor din peșteră

Deschideți peștera, apoi **⋮ → Import locuri din CSV** din lista ei de
locuri. Fiecare rând intră în acea peșteră.

### Coloanele pe care le puteți mapa

| Câmp | Obligatoriu | Ce face |
|---|---|---|
| **Nume loc peșteră** | Da | Numele locului. |
| **Cod QR** | Nu | Devine [codul de loc](place-code-identifiers.md) al locului. |

Descrierile, adâncimile, coordonatele și zonele de peșteră nu pot fi
importate pe această cale — pe acestea le adăugați pe loc, ulterior.

Un cod adus de import este transformat imediat în conținutul QR
corespunzător, așa că locurile sunt gata de printat, de scanat și de
deschis prin [link direct](deep-links.md) de la bun început. Nu trebuie
să rulați peste ele o trecere de generare a codurilor.

### Cum sunt potrivite rândurile cu locurile pe care le aveți deja

Un rând al cărui nume este exact numele unui loc din această peșteră
contează drept acel loc; orice alt rând creează un loc nou. Potrivirea
este exactă, inclusiv majusculele și minusculele.

Dialogul de avertizare numără potrivirile altfel: el ignoră majusculele
și minusculele. Așa că „Sifon” și „sifon” sunt raportate ca un singur loc
existent și apoi importate ca două.

### Întrebările pe care le pune importul

**Înregistrări existente găsite** listează locurile din această peșteră
cu ale căror nume se potrivește deja un rând, împreună cu codul pe care
fiecare dintre ele îl poartă acum, și întreabă dacă să continue.
Continuarea importă rândurile noi și lasă locurile existente unde sunt —
deși codul lor poate fi totuși înlocuit de întrebarea următoare.

**Conflicte cod QR** apare atunci când ați mapat coloana de cod QR și un
loc oarecare din baza de date poartă deja unul dintre codurile din
fișier. Dialogul listează codul, locul care îl poartă și peștera acelui
loc, apoi întreabă „Doriți să suprascrieți codurile QR existente?”:

- **Omite actualizare QR** — locurile pe care le aveți deja își păstrează
  codul pe care îl au. Asta protejează doar locurile existente: un rând
  care creează un loc nou primește codul din fișier, indiferent ce buton
  apăsați.
- **Suprascrie coduri QR** — când un rând se potrivește cu un loc care
  există deja în această peșteră, codul acelui loc este înlocuit cu cel
  din fișier. Locul care purta înainte acel cod este lăsat în pace, așa
  că după aceea două locuri pot purta același cod — verificați-le pe cele
  listate de dialog.

Verificarea conflictelor nu exclude chiar locurile pe care le
reimportați, așa că importul aceluiași fișier a doua oară ridică acest
dialog chiar dacă nu s-a schimbat nimic.

### Două cazuri care opresc importul

Amândouă vă lasă datele neatinse, arată un mesaj de eroare și închid
ecranul:

- Peștera ține deja două locuri cu exact același nume (posibil când stau
  în zone diferite ale peșterii).
- Două locuri din baza de date poartă deja același cod ca un rând din
  fișier.

### Ce raportează sumarul

Dialogul **Import finalizat** raportează:

- **Zone peșteră create** — aici întotdeauna 0, fiindcă acest import nu
  are coloană de zonă a peșterii.
- **Locuri peșteră create**
- **Coduri QR actualizate** — coduri înlocuite pe locuri pe care le
  aveați deja, nu coduri date locurilor noi.

## Nu se scrie nimic până nu răspundeți la toate întrebările

Fiecare avertizare vine înainte să se scrie vreo dată, iar importul însuși
rulează ca o singură operațiune. Apăsarea pe **Anulează** la dialogul de
înregistrări existente sau la dialogul de conflicte QR abandonează tot
importul și vă lasă baza de date exact cum era. Asta face să fie sigur să
porniți un import doar ca să vedeți ce ar raporta. (Întrebarea de
actualizare per peșteră nu are Anulează: ea decide doar acea peșteră, iar
ieșirea din ea contează drept **Omite**.)

Odată ce îl lăsați să ruleze, importul nu se mai poate anula — nu există
buton de anulare și nici „revino la ultimul import”. Faceți întâi un
[export al bazei de date](database-export-import.md) dacă fișierul este
mare sau dacă nu sunteți sigur de el.

## Rânduri lăsate deoparte fără niciun comentariu

Un rând fără nume de peșteră (importul de peșteri) sau fără nume de loc
(importul de locuri) este omis în tăcere și nu apare în niciun contor,
așa că liniile goale de la sfârșit, rămase dintr-un export de foaie de
calcul, sunt inofensive. Dacă toate rândurile sunt lăsate deoparte,
primiți „Nu s-au găsit rânduri valide în fișierul CSV.” și ecranul se
închide fără să facă nimic.

## Sfaturi

- Țineți un **fișier de probă** de trei-cinci rânduri, ca să verificați
  maparea coloanelor înainte de a vă angaja într-un import complet.
- Mapați **Index local peșteră** dacă vă așteptați să importați același
  catalog și mai târziu; el este cel care face din al doilea import o
  actualizare în loc de un duplicat.
- După ce importați locuri, deschideți lista de locuri a peșterii și
  hărțile, pentru o verificare vizuală rapidă.

## Vezi și

- [Peșteri și zone peșteră](caves-and-areas.md)
- [Locuri din peșteră](cave-places.md)
- [Arii de suprafață](surface-areas.md)
- [Coduri de loc (PCI) și conținuturi QR (QCRI)](place-code-identifiers.md)
- [Coduri QR — amplasare, scanare, tipărire](qr-codes.md)
- [Export, import și copie de siguranță a bazei de date](database-export-import.md)
