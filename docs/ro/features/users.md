# Utilizatori

[← Înapoi la cuprins](../README.md)

SpeleoLoc marchează fiecare modificare a datelor cu speologul care a
făcut-o. Pagina de față acoperă lista identităților de speolog din
**Setări → Utilizatori** și modul în care este ales și predat
**utilizatorul curent** — identitatea către care trimit aceste marcaje.

> Un „utilizator” este aici o identitate de speolog, nu un cont de
> autentificare. Nu există parolă și nimic nu este blocat: schimbarea
> utilizatorului curent înseamnă o singură apăsare de buton, pe care o
> poate face oricine ține telefonul în mână.

## La ce servește utilizatorul curent

Cât timp un utilizator este selectat, tot ce creați, editați sau
ștergeți poartă acea identitate, iar fiecare dintre aceste modificări
produce și o intrare în [istoricul
modificărilor](sync-and-change-log.md#change-log) (**Setări → Sinc.
man. → Istoric modificări**). Fiecare intrare poartă eticheta *de*
urmată de numele de utilizator, așa că după o tură puteți răspunde la
„cine a adăugat locul acesta?” sau „cine a mutat punctul acela?” fără
ca cineva să fi luat notițe.

Atât face utilizatorul curent. Nu filtrează ce vedeți, nu restrânge ce
puteți modifica și niciun ecran nu se comportă diferit în funcție de
cine este selectat.

## Lista utilizatorilor

**Setări → Utilizatori** listează fiecare speolog cunoscut de această
bază de date. Pe un dispozitiv pe care nu s-a scris încă nimic, lista
este goală și afișează *Niciun utilizator*.

Fiecare rând arată:

- o pictogramă de persoană — plină și în culoarea de accent pentru
  utilizatorul curent, conturată pentru toți ceilalți;
- **numele de utilizator** ca titlu al rândului;
- prenumele și numele dedesubt, sau textul din **Detalii** când nu a
  fost introdus niciun nume;
- în dreapta, o etichetă **Curent** pentru utilizatorul curent, sau un
  buton **Selectează** pentru toți ceilalți.

Un rând face exact două lucruri:

- **Selectează** — apăsați-l pentru a face din acea persoană
  utilizatorul curent. Din acel moment, modificările se înregistrează
  pe numele ei.
- **Apăsați pe rând** — deschide dialogul **Editează utilizator**
  pentru acea persoană. *Nu* o selectează.

## Adăugarea unui speolog

1. Deschideți **Setări → Utilizatori**.
2. Apăsați butonul de adăugare persoană din dreapta jos (**Adaugă
   utilizator**).
3. Completați câmpurile de mai jos și apăsați **Salvează**.
4. Înapoi în listă, apăsați **Selectează** pe rândul nou — adăugarea
   unui utilizator nu îl selectează.

| Câmp | Obligatoriu | La ce servește |
| --- | --- | --- |
| **Nume de utilizator** | da | Numele scurt sub care este cunoscută persoana. Este titlul rândului, eticheta din istoricul modificărilor și cheia folosită când dispozitivele se sincronizează. Trebuie să fie unic; spațiile de la capete sunt eliminate. |
| **Prenume** | nu | Afișat sub numele de utilizator în listă și între paranteze în istoricul modificărilor. |
| **Nume** | nu | La fel; cele două nume sunt afișate împreună. |
| **Detalii** | nu | O notă în text liber, pe trei rânduri — club, număr de telefon, rol, orice este util. Afișată sub numele de utilizator când nu au fost introduse prenumele și numele. |

Două lucruri la care să vă așteptați de la dialog:

- Cu **Nume de utilizator** gol, **Salvează** nu face absolut nimic și
  nu dă niciun mesaj. Scrieți un nume de utilizator sau apăsați
  **Anulează**.
- Dacă numele de utilizator este deja luat, dialogul rămâne deschis și
  în partea de jos a ecranului apare un mesaj de eroare tehnic. Alegeți
  alt nume de utilizator și apăsați din nou **Salvează**.

## Editarea unui speolog

Apăsați pe orice rând pentru a redeschide dialogul ca **Editează
utilizator** și pentru a schimba numele de utilizator, numele sau
detaliile.

Redenumirea este **retroactivă**. Istoricul modificărilor caută
autorul fiecărei intrări atunci când lista este desenată, așa că o
intrare făcută acum câteva luni este reetichetată cu numele de
utilizator de acum. Funcționează în ambele sensuri: completarea
ulterioară a prenumelui și a numelui îmbunătățește și intrările vechi,
care apoi se citesc `anna (Anna Popescu)` în loc de simplul `anna`.

Cu un [server de club](silexgis-sync.md) a cărui instalare oferă
**Persoane**, dialogul **Editează utilizator** se încheie și cu o
căsuță **Speolog pe …**, în care spuneți care dintre speologii clubului
este acest utilizator al telefonului. Vedeți
[Persoane](silexgis-sync.md#persoane).

## Utilizatorii nu pot fi șterși

Nu există ștergere nicăieri pe acest ecran — nici apăsare lungă, nici
meniu. Odată creată, o identitate rămâne în listă, pentru că rândurile
și intrările din istoricul modificărilor continuă să trimită la ea.
Dacă cineva a fost adăugat din greșeală, editați rândul și refolosiți-l
pentru un speolog real.

## Cine folosește aplicația? — întrebarea de la pornire

Când aplicația pornește și pe acest dispozitiv nu a fost ales încă
nimeni, ea deschide, înainte să puteți lucra, o pagină pe tot ecranul:
**Cine folosește aplicația?**. Pagina nu se închide cu Înapoi; dispare
odată ce a fost ales un utilizator. Ea oferă:

- **Alegeți un utilizator existent** — toți utilizatorii din această
  bază de date, în afară de cei șterși și de utilizatorul automat
  *system*. Apăsați pe dumneavoastră.
- **Creați un utilizator nou** — aceleași câmpuri ca la [Adăugarea unui
  speolog](#adăugarea-unui-speolog), apoi **Creează și continuă**.
  Utilizatorul nou este selectat imediat, iar chiar crearea lui este
  înregistrată pe numele lui. Un nume de utilizator deja folosit de
  oricine, inclusiv de un utilizator șters, este refuzat cu *Acest nume
  de utilizator este deja folosit*.

Aceeași pagină revine la o pornire ulterioară în două cazuri, cu un
rând în partea de sus care spune de ce:

- **Datele au fost înlocuite și utilizatorul dumneavoastră nu este în
  ele** — după o [restaurare sau un import complet](database-export-import.md)
  care a înlocuit întreaga bază de date. *Utilizatorul „…” nu a fost
  găsit în datele tocmai încărcate.* Când nici acel nume de utilizator,
  nici identitatea lui nu există în datele noi, pagina mai oferă
  **Păstrați utilizatorul anterior** — **Continuați ca „…” (adăugat în
  aceste date)**, care vă adaugă în datele noi sub aceeași identitate,
  astfel încât modificările dumneavoastră de acolo și de pe alte
  dispozitive să rămână atribuite unei singure persoane.
- **Utilizatorul dumneavoastră a fost șters** — de obicei pe alt
  dispozitiv, apoi sincronizat aici. *Utilizatorul „…” a fost șters,
  probabil pe alt dispozitiv și apoi sincronizat aici.* Alegeți sau
  creați alt utilizator.

Oferta de date de exemplu pe o bază de date goală, când versiunea
aplicației are una, vine prima; întrebarea urmează după ea.

### Când datele sunt înlocuite

Înlocuirea întregii baze de date — restaurarea unui fișier, un import
complet de arhivă, încărcarea datelor de exemplu — nu mai preia
utilizatorul pe care îl avea selectat cel care a exportat datele.
Utilizatorul selectat pe acest telefon înainte de înlocuire este
păstrat: dacă datele noi conțin același utilizator (după identitate
sau, altfel, după același nume de utilizator), el rămâne selectat fără
nicio întrebare; altfel se pune întrebarea de la pornire de mai sus.

### Utilizatorul automat „system”

Identificatorul propriu al dispozitivului nu este folosit niciodată ca
persoană. Dacă o modificare este scrisă în timp ce nu este ales niciun
utilizator — de exemplu când întrebarea de la pornire nu a putut fi
afișată — SpeleoLoc creează un utilizator numit **system** (prenume
*System*, detalii *Auto-generated default user.*) și îl selectează,
astfel încât marcajele cine-ce-a-modificat să nu fie niciodată goale.
*system* nu reprezintă pe nimeni anume: nu este oferit niciodată pe
pagina de la pornire, iar un telefon rămas pe *system* este întrebat
din nou la următoarea pornire. Tot ce s-a făcut deja sub *system*
rămâne atribuit lui și nu mai poate fi reatribuit după aceea.

## Predarea telefonului altcuiva

Utilizatorul curent poate fi schimbat oricând; nu trebuie repornit
nimic, iar modificările deja înregistrate își păstrează autorul
original.

1. Deschideți **Setări → Utilizatori**.
2. Apăsați **Selectează** pe rândul persoanei noi.
3. Predați telefonul.

Faceți din asta o parte a ritualului de predare, pentru că **niciun alt
ecran nu arată cine este selectat în acest moment**. Dacă schimbarea
este uitată, nimic nu pare în neregulă — greșeala iese la iveală abia
mai târziu, când cineva deschide istoricul modificărilor și găsește
munca unei dimineți sub un nume greșit.

## Numele de utilizator între dispozitive

Utilizatorii circulă între dispozitive în [arhivele de
sincronizare](sync-and-change-log.md) ca orice altă înregistrare, iar
**numele de utilizator este cel care identifică o persoană**.

Când datele de pe alt dispozitiv sunt îmbinate aici, un utilizator
sosit al cărui nume de utilizator există deja aici este contopit cu cel
local, iar fiecare rând și fiecare intrare din istoricul modificărilor
care trimitea la el îl urmează. Tot așa se îmbină și utilizatorul
automat *system* pe care fiecare dispozitiv și-l creează singur.

Potrivirea este exactă, inclusiv scrierea cu majuscule. Așa că
stabiliți o singură ortografie pentru fiecare speolog și folosiți-o pe
fiecare dispozitiv: `anna` și `Anna` sunt două persoane diferite, iar
odată ce ambele există nu mai există nicio cale de a le îmbina din
interiorul aplicației.

## Vezi și

- [Panoul de sincronizare și Istoric modificări](sync-and-change-log.md)
- [Sincronizare FTP](ftp-sync.md)
- [Server de club (SilexGIS)](silexgis-sync.md)
- [Setări](settings.md)
- [Ture](trips.md)
- [Desfășurarea unei ture](../workflows/running-a-trip.md)
- [Primii pași](../getting-started.md)
