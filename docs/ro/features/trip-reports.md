# Rapoarte de tură și șabloane

[← Înapoi la cuprins](../README.md)

SpeleoLoc transformă o tură într-un document ODT sau DOCX luând un
șablon pe care îl furnizați dumneavoastră și adăugând la finalul lui
textul jurnalului turei. Tot ce este util în raport vine deci din două
lucruri: șablonul pe care l-ați scris și jurnalul turei.

## Ce este de fapt un raport

Fișierul exportat este o copie exactă a șablonului dumneavoastră, cu
jurnalul turei adăugat ca paragrafe simple chiar la final. Asta este
tot:

- **Nu există substituenți sau variabile.** SpeleoLoc nu caută nimic în
  șablon și nu înlocuiește valori în el.
- **Nu există listă automată de locuri, bloc de date despre tură sau
  imagine de hartă.** Numele peșterii, adâncimile, identificatorii cod
  loc și identificatorii QR nu ajung niciodată singuri în document.
- **Formatul de ieșire este întotdeauna cel al șablonului** — un șablon
  ODT produce un ODT, un șablon DOCX produce un DOCX. Nu vi se cere să
  alegeți un format.

Orice altceva doriți în raport fie puneți în șablon ca text fix, fie
scrieți în jurnalul turei înainte de export, fie adăugați manual în
procesorul de text după ce fișierul este generat.

Raportul este un document de birou obișnuit. Nimic nu îl leagă înapoi
de șablon sau de SpeleoLoc, așa că îl puteți edita, tipări și distribui
liber.

## Jurnalul turei

Raportul este construit din jurnalul turei, deci jurnalul este locul
unde se face treaba. Deschideți-l din bara de instrumente a unei ture:
**Jurnal**.

### Ce înregistrează SpeleoLoc pentru dumneavoastră

Jurnalul se scrie singur pe măsură ce tura se desfășoară. El acoperă:

- **începerea** turei, cu titlul turei,
- fiecare **oprire** în ordine — un loc pe care l-ați scanat sau ales —
  împreună cu orice notă atașată acelei opriri (stilul **Brut** lasă
  notele deoparte),
- fiecare **document** pe care îl creați sau îl legați cât timp tura
  este activă, după titlu,
- o **repornire**, dacă reporniți o tură încheiată,
- **încheierea** turei.

**Pauzele și reluările nu se scriu în jurnal.** Punerea în pauză doar
oprește înregistrarea de noi opriri și documente până la reluare; nu
lasă nicio urmă în text și niciun gol pe care să îl puteți arăta
ulterior.

În jurnal apare doar *titlul* unui document. Conținutul lui rămâne la
document.

Propozițiile jurnalului sunt scrise în limba în care era setată
aplicația în momentul în care a fost generată fiecare linie, așa că un
jurnal construit pe o aplicație în limba română conține text în română.
Schimbarea ulterioară a **Setări → General → Limba aplicației** nu
rescrie textul deja aflat în jurnal — doar o regenerare (o schimbare de
stil sau o repornire a turei) îl rescrie în limba folosită atunci.

### Editarea manuală a jurnalului

Pagina jurnalului turei este un editor de text simplu, cu font
monospațiat. Scrieți în el ce doriți — membrii echipei, vremea,
echipamentul, concluziile.

Două lucruri vă pot păcăli:

1. **Nimic nu se salvează până nu apăsați pictograma de salvare** din
   bara de sus. Salvarea afișează **Jurnalul turei a fost salvat** și
   închide pagina. Ieșirea pe orice altă cale — butonul înapoi, o
   glisare — aruncă ce ați scris fără să întrebe. Salvați întotdeauna
   înainte de export, pentru că exportul citește jurnalul salvat, nu ce
   este pe ecran.
2. **Unele acțiuni reconstruiesc jurnalul de la zero** și vă aruncă
   textul. Repornirea unei ture face asta, schimbarea stilului de
   jurnal face asta și — doar cu stilul **Narativ** — o face și fiecare
   eveniment nou cât timp tura este încă în desfășurare.

Cu **Brut**, **Clasic** sau **Jurnal de teren**, un eveniment nou se
adaugă ca încă o linie după ce se află deja în jurnal, așa că textul
dumneavoastră supraviețuiește. **Narativ** trebuie să reconstruiască
tot, ca paragrafele să se citească cum trebuie. Dacă vreți să adnotați
jurnalul unei ture aflate încă în desfășurare, folosiți unul dintre
celelalte trei stiluri sau așteptați până ați oprit tura.

### Stiluri de jurnal

Sunt disponibile patru stiluri și ele schimbă felul în care se citește
tot jurnalul.

| Stil | Ce produce | Prefixul liniei |
|---|---|---|
| **Brut (marcaje de timp + mesaje scurte)** | Linii scurte și seci: `Tură începută: "Cartare duminicală"`, `Punct: "Intrare"`, `Document adăugat: "Foto sifon"`. | `[yyyy/MM/dd HH:mm:ss]` |
| **Clasic (propoziții complete)** *(implicit)* | Câte o propoziție completă pentru fiecare eveniment: `Tura „Cartare duminicală” a început.`, `S-a ajuns la „Intrare”.`, cu nota opririi în paranteze după ea. | `[yyyy/MM/dd HH:mm:ss]` |
| **Jurnal de teren (timp scurs + secvență)** | Propoziții care își cunosc poziția în tură: `Prima oprire: „Intrare”.`, apoi `S-a continuat spre „Galerie”.`, fiecare marcată cu timpul scurs de la început. | `[HH:mm · +Δ]` |
| **Narativ (paragrafe)** | Proză. O propoziție de deschidere cu titlul turei, data și ora de început; opriri consecutive înlănțuite într-o singură propoziție care poartă intervalul dintre ele (`După 15 min, echipa a ajuns la "Intrare", apoi a continuat spre "Galerie" (după încă 5 min)`); câte o propoziție pentru fiecare notă de oprire și fiecare document; și o propoziție de încheiere cu ora de final și durata totală. | niciunul |

**Narativ** este cel care se citește bine adăugat la un raport.

### Schimbarea stilului

1. Deschideți o tură și apăsați **Jurnal**.
2. Apăsați pictograma cu cartea deschisă din bara de sus (**Schimbă
   metoda de generare**) și alegeți un stil. O bifă marchează stilul
   folosit.
3. Un dialog **Regenerăm jurnalul turei?** vă avertizează: *„Jurnalul
   va fi regenerat din evenimentele înregistrate folosind metoda
   selectată. Modificările manuale vor fi pierdute.”* Apăsați
   **Regenerează** ca să continuați.
4. Jurnalul este rescris în noul stil și salvat imediat.

Stilul este o **setare unică pentru acest dispozitiv**, nu una per
utilizator sau per tură — schimbarea lui îl schimbă pentru toți cei
care folosesc dispozitivul și se aplică și turei următoare. Trebuie
stabilit o singură dată.

> **Sfat**: **Narativ** dă proza cea mai potrivită pentru un raport,
> așa că alegeți-l *înainte* de a scrie ceva manual în jurnal. Nu
> comutați stilurile înainte și înapoi în jurul unui jurnal pe care
> l-ați adnotat deja — fiecare comutare vă aruncă textul. Exportați
> întâi, apoi editați documentul final în procesorul de text.

## Șabloane

Un șablon este un document ODT sau DOCX obișnuit — antetul clubului
dumneavoastră, o pagină de titlu, titluri, o secțiune fixă
„Participanți” sau „Echipament”, orice doriți deasupra jurnalului. Nu
are nevoie de niciun fel de marcaj special, pentru că SpeleoLoc doar
adaugă text la finalul lui. Lăsați finalul documentului gol: acolo
aterizează jurnalul.

Aplicația nu vine cu niciun șablon exemplu.

### Ajungerea la ecranul șabloanelor

Deschideți o tură, apăsați **Export raport**, apoi **Administrare
șabloane** în dialogul de șabloane. **Aceasta este singura cale de
intrare** — nu există nicio intrare pentru șabloane din ecranul
principal sau din Setări.

Prima dată când faceți asta nu veți avea niciun șablon, așa că în loc
de un selector primiți **Nu există șabloane. Adăugați un șablon mai
întâi.** cu un buton **Administrare șabloane** lângă **Anulează**. Acel
buton este calea prevăzută.

Ecranul se numește **Șabloane documente**. Fiecare rând arată numele
șablonului, formatul lui și dimensiunea fișierului, de exemplu
`ODT · 42.7 KB`. O listă goală arată *„Nu există șabloane. Apasă +
pentru a adăuga un șablon ODF sau DOCX.”*

### Adăugarea unui șablon

1. Pe **Șabloane documente**, apăsați butonul **+**.
2. Alegeți un fișier `.odt` sau `.docx` de pe dispozitiv. Orice altceva
   este refuzat cu **Format nesuportat. Selectați un fișier ODT sau
   DOCX.**
3. Se deschide un dialog **Adaugă șablon** cu un câmp **Numele
   șablonului**, precompletat cu numele fișierului fără extensie. Acest
   nume este cel pe care îl veți vedea în lista de șabloane și când
   alegeți un șablon pentru un raport, așa că faceți-l ușor de
   recunoscut.
4. Apăsați **OK**. Confirmarea este **Șablon adăugat**.

Fișierul este copiat în spațiul de stocare propriu al SpeleoLoc, așa că
puteți muta sau șterge originalul după aceea fără să stricați nimic.

Dacă goliți câmpul cu numele și apăsați **OK**, nu se adaugă nimic și
nu se afișează niciun mesaj — pare pur și simplu că dialogul s-a
închis.

### Ștergerea unui șablon

Apăsați pictograma roșie de ștergere de pe rând și confirmați **Ștergi
șablonul "<name>"?** cu **Da**. Aceasta înlătură atât intrarea, cât și
copia documentului păstrată de SpeleoLoc; nu poate fi anulată din
interiorul aplicației. Fișierul dumneavoastră original, de oriunde
l-ați ales, rămâne neatins, iar rapoartele deja exportate nu sunt
afectate.

### Șabloanele nu circulă între dispozitive

Acesta este singurul lucru de știut înainte de a vă baza pe șabloane
într-un club.

Un șablon are două părți: o intrare în baza de date și fișierul
`.odt`/`.docx` propriu-zis din interiorul aplicației. **Sincronizarea
și exportul bazei de date duc intrarea, dar nu și fișierul.** Pe un al
doilea telefon șablonul apare deci în listă arătând perfect normal, iar
exportul eșuează apoi cu un mesaj de eroare brut care conține
**Template file not found**.

Dacă în clubul dumneavoastră se folosește un singur șablon de raport,
fiecare dispozitiv trebuie să adauge fișierul pentru el însuși — nu
există nicio cale de a-l distribui prin sincronizare sau printr-o
arhivă. Același lucru este valabil și după restaurarea unei copii de
siguranță pe o instalare nouă.

## Exportul unui raport

**Export raport** se află în bara de instrumente a turei și
funcționează pentru **orice tură, în desfășurare sau încheiată** — nu
trebuie să opriți întâi tura.

1. Deschideți tura: din lista locurilor peșterii apăsați **Ture trecute
   / active**, apoi apăsați tura (sau **Vezi tura** pentru cea activă).
2. Apăsați **Export raport**. Dacă jurnalul turei este gol, primiți
   **Nu există jurnal de excursie de exportat** și nu se întâmplă nimic
   altceva.
3. Apare **Selectează un șablon**. Apăsați șablonul dorit. Dialogul are
   și un buton **Administrare șabloane**, dacă trebuie să adăugați
   întâi unul.
4. Se deschide dialogul de salvare al dispozitivului, intitulat
   **Export raport**, cu numele fișierului deja completat ca
   `trip_report_<trip title>.odt` (sau `.docx`); spațiile și semnele de
   punctuație din titlul turei devin liniuțe de subliniere. Schimbați
   numele sau destinația dacă doriți, apoi confirmați.
5. SpeleoLoc scrie documentul, afișează **Raport exportat cu succes**,
   apoi predă fișierul aplicației de pe dispozitiv care deschide
   fișiere ODT sau DOCX.

Dacă la pasul 5 nu se deschide nimic, raportul a fost totuși scris —
dispozitivul dumneavoastră pur și simplu nu are nicio aplicație
înregistrată pentru acel format.

## Imaginea hărții turei

SpeleoLoc **nu poate** pune o imagine de hartă într-un raport. Harta
este un export separat, pe care îl inserați manual după aceea.

Vederea de hartă a turei are propriul buton **Exportă harta**, care
apare doar cât timp sunteți în vederea de hartă și doar când peștera
are cel puțin o hartă raster. El salvează un PNG al hărții exact așa
cum este afișată — cu linia traseului, săgețile de direcție și opririle
numerotate — în folderul de documente propriu al aplicației, cu numele
`trip_map_<trip title>_<timestamp>.png`, și arată calea completă
într-un mesaj **Harta traseului exportată**. Nu există dialog de
salvare și nici alegere a folderului.

Ca să aduceți acea imagine în raport: exportați harta, exportați
raportul, apoi deschideți raportul în procesorul de text și inserați
PNG-ul unde doriți.

## Depanare

| Mesaj sau simptom | Ce înseamnă |
|---|---|
| **Nu există jurnal de excursie de exportat** | Jurnalul turei este gol, iar raportul se construiește în întregime din jurnal. Deschideți **Jurnal**, puneți ceva în el, salvați, apoi exportați din nou. |
| O eroare care conține **Template file not found** | Șablonul este listat, dar documentul lui lipsește de pe acest dispozitiv. Normal pe un al doilea dispozitiv sau după restaurarea unei copii de siguranță: adăugați fișierul din nou aici. |
| **Format nesuportat. Selectați un fișier ODT sau DOCX.** | Fișierul ales nu este `.odt` sau `.docx`. Salvați-l din nou din procesorul de text în unul dintre aceste două formate. |
| Raportul este doar șablonul cu text lipit la final | Exact asta și este. Nu există niciun pas de substituție. Rearanjați lucrurile în procesorul de text după export. |
| Textul pe care l-ați scris în jurnal a dispărut | Jurnalul a fost regenerat — de o repornire a turei, de o schimbare de stil sau de un eveniment nou cât timp stilul **Narativ** era activ. |
| Nu s-a întâmplat nimic după ce exportul a reușit | Fișierul a fost scris; dispozitivul dumneavoastră nu are nicio aplicație care să gestioneze ODT sau DOCX. |

## Vezi și

- [Ture](trips.md)
- [Documente](documents.md)
- [Vizualizatorul de hărți](map-viewer.md)
- [Desfășurarea unei ture](../workflows/running-a-trip.md)
- [Sincronizarea și istoricul modificărilor](sync-and-change-log.md)
- [Export și import al bazei de date](database-export-import.md)
