# Documente

[← Înapoi la cuprins](../README.md)

Documentele (aplicația le numește și **fișiere documentație**) sunt
fotografiile, înregistrările, notele și fișierele pe care le atașați unei
peșteri sau unui loc din peșteră. Fiecare listă de documente din aplicație
este același ecran, așa că ce învățați pe un loc din peșteră vă folosește
peste tot.

## La ce poate fi atașat un document

- unui **loc din peșteră** — cazul cel mai frecvent: fotografia unei
  bifurcații, o notă vocală la o strâmtoare, schița unui detaliu de galerie;
- unei **peșteri** — material despre toată peștera, de exemplu un PDF cu
  topografia sau o descriere a accesului.

Datele stocate permit documente și pe o **zonă peșteră**, dar niciun ecran
din aplicație nu oferă asta. Documentele atașate unei zone peșteră — de
exemplu cele sosite în arhiva unui coechipier — se pot vedea doar în
browserul global **Documente** descris mai jos.

## Deschiderea unei liste de documente

Acțiunea este de obicei o **pictogramă de folder** din bara de titlu, cu
indicația **Documente**.

| Unde vă aflați | Ce arată pictograma de folder |
|---|---|
| Un loc din peșteră | Documentele acelui loc. Pictograma apare doar după ce locul a fost salvat. |
| Lista locurilor unei peșteri | Documentele **peșterii înseși**, nu ale vreunui loc anume. |
| Formularul de editare a peșterii | Documentele acelei peșteri. Pictograma apare doar când editați o peșteră existentă, nu și când creați una nouă. |
| Editorul de puncte de pe harta raster | Documentele locului selectat în acel moment pe hartă (o pictogramă de document în bara de acțiuni a editorului). |

Bara de titlu a ecranului de documente arată numele locului sau al peșterii,
cu numele peșterii dedesubt, ca reper pentru locul în care vă aflați.

## Lista de documente

> 📷 [Browserul de documente, vedere listă](../screenshots/05-documents.md#documents-list) — Biblioteca de documente în vedere listă, cu selectorul de mod de vizualizare, sortare și căutare.

Un antet fixat în partea de sus a listei poartă trei controale care rămân la
locul lor cât timp derulați.

- **Moduri de vizualizare** — cinci butoane-pictogramă cu indicațiile
  **Listă**, **Listă pe categorii**, **Grilă**, **Grilă pe categorii** și
  **Grilă orizontală**. În **Grilă orizontală** apare dedesubt un control
  suplimentar **Rânduri**, cu care alegeți 1, 2 sau 3 rânduri pentru fiecare
  bandă de categorie.
- **Sortează după** (pictograma de sortare din dreapta butoanelor de
  vizualizare) — **Titlu**, **Tip**, **Dimensiune fișier** sau **Dată**.
  Alegerea câmpului după care sortați deja inversează ordinea; săgeata de
  lângă un câmp arată direcția curentă.
- **Caută documente...** — caută în titlul documentului, în numele
  fișierului și în descrierea lui. Nu caută în interiorul fișierelor.

În modul listă, fiecare rând arată o miniatură, titlul, iar dedesubt
categoria și dimensiunea fișierului. În modurile cu grilă aveți o miniatură
mare, cu titlul sub ea.

Miniaturile sunt informative, nu generice: documentele text arată primele
rânduri din conținutul lor, fotografiile arată imaginea, iar fișierele PDF,
audio, video și cele de birou arată o pictogramă colorată de tip, cu o
insignă mică ce dă extensia fișierului. O fotografie al cărei fișier a
dispărut arată o pictogramă de imagine ruptă.

### Categorii

Categoria vine din tipul fișierului. În cele două aranjamente „pe categorii"
și în **Grilă orizontală**, fiecare categorie prezentă devine un titlu care
poartă numărul de documente din ea; apăsați un titlu pentru a restrânge sau
a extinde acea secțiune.

> 📷 [Listă grupată pe categorii](../screenshots/05-documents.md#documents-list-by-category) — Browserul cu toate documentele în vedere listă pe categorii, cu înregistrări audio și fotografii.

| Titlu | Ce ajunge acolo |
|---|---|
| **Fotografii** | JPG, PNG, GIF, BMP, WEBP, HEIC |
| **Videoclipuri** | MP4, MOV, AVI, MKV, WEBM |
| **Audio** | MP3, WAV, OGG, M4A, FLAC |
| **Documente text** | Text simplu și Markdown, **documente cu text formatat**, PDF și fișiere Word / OpenDocument |
| **Linkuri web** | Nimic din ce puteți crea în aplicație — vedeți mai jos |
| **Altele** | Orice tip de fișier pe care aplicația nu îl recunoaște |

Două grupări îi surprind pe oameni: o notă cu text formatat și un PDF de
topografie intră amândouă la **Documente text**, iar o foaie de calcul sau o
arhivă ajunge la **Altele**. **Linkuri web** poate apărea ca titlu, dar
nimic din aplicație nu creează un document de tip link web — asemenea
rânduri sosesc doar din date importate sau sincronizate.

## Adăugarea documentelor

Implicit, un rând de cinci butoane-pictogramă stă chiar sub bara de titlu.
De la stânga la dreapta:

| Buton | Ce face |
|---|---|
| **Document text nou** | Un editor de text simplu, cu un câmp pentru titlu. |
| **Text formatat nou** | Un editor cu bară de formatare (bold, italic, liste, titluri). |
| **Fă o fotografie** | Deschide camera dispozitivului. |
| **Înregistrare audio** | Reportofonul, cu formă de undă în timp real. |
| **Adaugă din fișier** | Alegeți dintr-o dată unul sau mai multe fișiere de pe dispozitiv. |

Bara poate fi oprită din **meniul ⋮ → Ascunde bara de acțiuni**. Cu ea
ascunsă, în bara de titlu apar în schimb un buton **+** și un buton cu
agrafă, care oferă exact aceleași cinci acțiuni. Alegerea este reținută și
se aplică fiecărei liste de documente din aplicație.

Documentele noi sunt atașate peșterii sau locului a cărui listă ați
deschis-o.

### Fotografierea

**Fă o fotografie** deschide camera pe loc. După ce aveți un cadru, sub
previzualizare apar trei butoane:

1. **Refă** — deschide iar camera.
2. **Editează în editor** — trimite imaginea în editorul de imagini
   (decupare și rotire, unelte de desen, filtre, texte suprapuse) și
   salvează rezultatul.
3. **Salvează** — stochează fotografia așa cum este.

Ieșirea din cameră închide tot ecranul, fără să adauge nimic. Pagina de sub
cameră mai oferă și **Alege din galerie**, care atașează o imagine făcută
mai devreme cu altă aplicație.

O fotografie salvată direct primește un titlu automat, de forma
`Photo 2026-09-01T14:32:05`; una salvată prin editorul de imagini se
numește `image_` plus o marcă de timp. Nu aveți ocazia să vă scrieți propriul
titlu, iar fotografiile nu pot fi redenumite ulterior.

### Înregistrarea audio

Reportofonul scrie **WAV** necomprimat, care este considerabil mai mare
decât un MP3 sau M4A de aceeași lungime — o înregistrare lungă în subteran
va ocupa spațiu real în arhiva dumneavoastră.

Apăsați butonul cu microfon pentru a porni, butonul de pauză pentru a
întrerupe și a relua, iar butonul de oprire pentru a termina. Completați
**Titlu** înainte de salvare; dacă îl lăsați gol, înregistrarea se numește
`rec_` plus data și ora. Salvați cu pictograma de salvare din bara de titlu.

La prima înregistrare, telefonul cere permisiunea pentru microfon. Dacă ați
refuzat-o definitiv mai devreme, SpeleoLoc afișează un dialog **Permisiune
necesară**, cu un buton **Deschide setări** care duce direct la pagina de
permisiuni a aplicației.

### Adăugarea mai multor fișiere deodată

**Adaugă din fișier** acceptă o selecție multiplă, nu doar un singur fișier.
Alegeți câte doriți; o casetă de progres le numără pe măsură ce sunt copiate
și nu poate fi anulată sau închisă cât timp rulează.

Fiecare fișier își păstrează numele, fără extensie, drept titlu al
documentului — nu există ocazia de a le denumi unul câte unul, așa că
folosiți editoarele atunci când contează un titlu ca lumea.

Fișierele al căror conținut se potrivește exact cu al unui document deja
atașat acestei peșteri sau acestui loc sunt omise în tăcere, așa că
re-adăugarea aceluiași folder nu creează duplicate. Dacă tot ce ați ales era
deja acolo, confirmarea arată „Importate: 0".

## Deschiderea unui document

Ce face o apăsare depinde de tip.

| Tip | Ce se deschide |
|---|---|
| **Fotografie** | Galeria pe tot ecranul. |
| **Text, text formatat, audio** | **Editorul** lor, când sunteți într-o listă de documente ale unei peșteri sau ale unui loc. |
| **PDF** | Cititorul PDF încorporat — derulați paginile, apropiați degetele pentru zoom. |
| **Video, foi de calcul, arhive, orice nu este recunoscut** | O pagină substitut care arată extensia fișierului și un buton **Salvează**. Nu există player și nici previzualizare. |

Butonul **Salvează** de pe acea pagină substitut scrie o copie a fișierului
în folderul temporar al dispozitivului și vă spune calea. Este singurul mod
de a scoate un singur document din aplicație; pentru orice altceva, folosiți
exportul de arhivă.

**Apăsarea lungă** pe un document oferă până la două opțiuni: **Deschide**
(vizualizatorul, doar pentru citire) și, pentru documentele text, text
formatat, fotografie și audio, **Editează** (editorul potrivit).
Videoclipurile și tipurile de fișiere nerecunoscute nu au niciuna, așa că
apăsarea lungă pe ele doar le deschide.

Distincția contează cel mai mult la audio: apăsarea unei note audio într-o
listă de peșteră sau de loc deschide **reportofonul**, nu un player. Ca doar
să ascultați, apăsați lung pe ea și alegeți **Deschide** — redarea pornește
singură de îndată ce forma de undă este gata, dedesubt stă un buton de
redare/pauză, puteți apăsa sau trage forma de undă pentru a derula, iar
playerul se închide singur când se termină înregistrarea.

### Galeria foto

Apăsarea oricărei fotografii o deschide pe tot ecranul, pe fundal negru.
Glisați la stânga și la dreapta ca să treceți prin toate celelalte
fotografii din listă fără să vă întoarceți, apropiați degetele pentru zoom
și trageți ca să deplasați imaginea. Antetul arată titlul fotografiei și
poziția ei, de exemplu „3 / 17".

Galeria respectă filtrul și ordinea de sortare pe care lista le folosește în
acel moment, așa că o căutare făcută întâi este o cale rapidă de a răsfoi
doar fotografiile care vă interesează. Este doar pentru vizualizare — ca să
schimbați o fotografie, întoarceți-vă, apăsați lung pe ea și alegeți
**Editează**.

> 📷 [Vedere grilă](../screenshots/05-documents.md#documents-grid) — Același browser de documente în vedere grilă simplă, cu miniaturi de fotografii.

## Editarea

| Tip | Ce puteți schimba |
|---|---|
| **Text** | Titlul și conținutul, în editorul de text. |
| **Text formatat** | Titlul și conținutul formatat, în editorul de text formatat. |
| **Audio** | Titlul și înregistrarea în sine (vedeți mai jos). |
| **Fotografie** | Imaginea, în editorul de imagini. Titlul rămâne cum a fost. |
| **PDF, video, documente de birou, orice altceva** | Nimic — acestea nu pot fi schimbate deloc în aplicație, nici măcar titlul lor. |

**Descrierea** unui document nu poate fi editată nicăieri în aplicație; ea
sosește doar odată cu datele importate sau sincronizate, unde contează
totuși pentru caseta de căutare.

Salvarea unei modificări **suprascrie pe loc fișierul stocat**. Versiunea
anterioară a unei fotografii, a unei note sau a unei înregistrări nu este
păstrată nicăieri.

Dacă apăsați înapoi cu modificări nesalvate în editorul de text sau în cel
de text formatat, un dialog oferă **Salvează**, **Anulează** (renunțarea la
modificări) și **Anulează** (revenirea în editor), așa că o apăsare greșită
nu pierde o notă scrisă în subteran. Ambele editoare refuză să salveze fără
titlu, iar editorul de text simplu refuză să salveze și un document gol.
Dacă un document text nou are conținutul identic cu al unuia deja stocat în
aplicație, un avertisment scurt o spune — este doar o înștiințare,
documentul se salvează oricum.

### Reînregistrarea audio

Deschiderea unui document audio în reportofon nu pornește de la zero. Redați
înregistrarea existentă, trageți de forma de undă până în punctul dorit,
apoi apăsați înregistrare: tot ce urmează după acel punct este înlocuit de
noua preluare, iar tot ce este înainte se păstrează. Nu există funcție de
tăiere, iar salvarea suprascrie fișierul original.

## Ce nu puteți face

Nu există nicăieri în SpeleoLoc vreo acțiune de redenumire, ștergere,
desprindere, partajare sau deschidere în altă aplicație pentru documente.
Odată atașat, un fișier rămâne atașat, iar singurul mod de a-i schimba
titlul este să îl salvați din nou în editorul de text, de text formatat sau
audio. Gândiți-vă din vreme la titluri — mai ales pentru fotografii și
pentru fișierele importate, care nu pot fi redenumite deloc.

## Documentele și turele

Dacă o tură este pornită și nu este în pauză, documentele pe care le
**creați în aplicație** — note text, text formatat, fotografii, schițe și
înregistrări — sunt legate și de tura în curs și apar în jurnalul ei,
alături de locurile pe care le vizitați.

Fișierele aduse cu **Adaugă din fișier** sau cu importul în masă de
documente în peșteri sunt atașate doar peșterii sau locului. Ele nu sunt
niciodată adăugate turei, nici măcar când una este pornită. Vedeți
[Ture](trips.md).

## Browserul cu toate documentele

Deschideți-l de pe pagina principală din **meniul ⋮ → Documente**, de la
pictograma **Documente** din bara de acțiuni a paginii principale (care la
rândul ei se pornește din **Setări → General → Afișează bara de acțiuni pe
pagina principală**) sau din intrarea **Documente** a meniului ⋮ de pe alte
ecrane. Pagina se numește **Documente** și listează fiecare document stocat
în aplicație, indiferent cărei peșteri sau cărui loc îi aparține.

Este o vedere doar pentru răsfoire. Puteți căuta, sorta, comuta
aranjamentele, deschide documente și edita conținutul documentelor text,
text formatat, fotografie și audio — dar nu puteți adăuga documente noi
acolo și nu puteți schimba cărei peșteri sau cărui loc îi aparține un
document.

Fiindcă nu există o peșteră sau un loc în context, apăsarea aici pe un
document text, text formatat sau audio deschide întâi **vizualizatorul**, cu
un buton mic cu creion în colț pentru trecerea în editor. O ciudățenie: un
document cu text formatat nu are vizualizator propriu, așa că arată aceeași
pagină substitut ca un fișier nerecunoscut — folosiți butonul cu creion ca
să-l citiți ca lumea.

## Import în masă: câte un folder de documente pentru fiecare peșteră

Dacă vă țineți deja fotografiile și topografiile în foldere — câte un folder
de peșteră — puteți atașa tot lotul dintr-o singură trecere.

1. Pe pagina principală alegeți **meniul ⋮ → Importă documente în peșteri**
   sau pictograma de încărcare folder din bara de acțiuni a paginii
   principale.
2. Alegeți folderul părinte — cel care *conține* subfolderele pe peșteri.
3. SpeleoLoc listează fiecare subfolder cu numărul de fișiere pe care le
   ține și încearcă să afle cărei peșteri îi aparține: întâi printr-o
   potrivire exactă a numelui folderului cu titlul unei peșteri, apoi după
   un token inițial `<cod zonă>-<cod peșteră>`, de exemplu
   `2046-18 P. Fisurii`. O etichetă colorată pe fiecare rând arată
   rezultatul — **după titlu**, **după cod**, **manual** sau **nepotrivit**.
4. Corectați ce a nimerit greșit: fiecare rând are o listă derulantă cu
   peșterile luate în calcul, plus **— omite —** pentru a lăsa acel folder
   pe dinafară. Rândurile care arată 0 fișiere nu pot fi selectate.
5. Apăsați **Importă**. Un rezumat raportează câte fișiere au fost
   importate, câte peșteri au fost actualizate, câte au fost omise ca
   duplicate și câte au eșuat.

Se importă doar fișierele care stau *direct* în fiecare subfolder —
subfolderele mai adânci sunt ignorate — iar fișierele ascunse sunt omise.
Rularea aceluiași import de două ori este sigură: fișierele al căror
conținut se potrivește deja cu un document de pe acea peșteră sunt omise, nu
duplicate.

Peșterile oferite sunt cele luate în calcul în acel moment pe pagina
principală: dacă sunteți în modul de selecție, peșterile bifate; altfel,
fiecare peșteră lăsată vizibilă de filtru. Îngustați întâi lista de pe
pagina principală dacă vreți să importați doar în câteva peșteri.

### Dacă fiecare folder raportează „0 fișiere"

Pe Android este obișnuit ca importatorul să vă listeze corect subfolderele,
dar să arate „0 fișiere" la toate. Acesta este Android-ul care ascunde
fișierele altor aplicații, nu un folder gol. Când fiecare rând este scanat
ca gol, un banner portocaliu explică asta și oferă **Permite accesul la
toate fișierele**, care vă duce la pagina de permisiuni a sistemului, și
**Rescanează**, pentru a încerca din nou după ce ați acordat accesul.
Acordați accesul, reveniți, rescanați și numerele ar trebui să apară.

## Dimensiunea fotografiilor și comprimarea imaginilor

**Setări → Compresie imagini** hotărăște dacă fotografiile sunt micșorate pe
măsură ce intră în aplicație. Este **oprită implicit**, așa că fotografiile
sunt stocate la dimensiunea întreagă până când o porniți.

Cu **Activează comprimarea imaginilor** pornit, alegeți un **Profil de
comprimare**:

| Profil | Latura cea mai lungă | Calitate |
|---|---|---|
| Reducere scăzută | 3840 px | 92% |
| Reducere medie | 1920 px | 80% |
| Reducere mare | 1280 px | 65% |
| Reducere foarte mare | 800 px | 45% |
| Manual | valoarea dumneavoastră | valoarea dumneavoastră |

Comprimarea se aplică fotografiilor făcute cu camera, fotografiilor adăugate
cu **Adaugă din fișier** și fotografiilor aduse de importul în masă de
documente în peșteri. Sunt micșorate efectiv doar imaginile mai mari decât
limita, iar copia stocată este salvată din nou ca JPEG. Nu atinge
videoclipurile, fișierele PDF, fișierele audio și nici schițele salvate din
editorul de imagini și nu modifică niciodată fișierul original de pe
dispozitivul dumneavoastră — doar copia pe care o ține aplicația.

## Unde stau fișierele

Adăugarea unui document face întotdeauna o **copie**. Fișierele
dumneavoastră originale rămân exact unde erau; nimic nu este mutat, șters
sau modificat.

Copiile ajung într-un folder privat, în stocarea proprie a aplicației, iar
fiecare este redenumită cu o marcă de timp pusă în fața numelui original de
fișier, așa că două fișiere care poartă același nume nu se pot ciocni
niciodată.

Acel folder aparține aplicației, așa că **dezinstalarea SpeleoLoc șterge
odată cu ea fiecare document**. Exportați o arhivă înainte de dezinstalare
sau înainte de a șterge datele aplicației. La exportul unei arhive,
fișierele documentație sunt incluse opțional; vedeți
[Export, import și copie de siguranță a bazei de date](database-export-import.md).

## Vezi și

- [Locuri din peșteră](cave-places.md)
- [Peșteri și zone de peșteră](caves-and-areas.md)
- [Ture](trips.md)
- [Pagina principală](home-screen.md)
- [Setări](settings.md)
- [Export, import și copie de siguranță a bazei de date](database-export-import.md)
