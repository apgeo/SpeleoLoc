# Beaconuri BLE

[← Înapoi la cuprins](../README.md)

Un beacon BLE este o mică etichetă Bluetooth cu baterie, montată într-un
punct de interes. SpeleoLoc recunoaște etichetele pe care le-ați
înregistrat și vă spune în ce loc din peșteră vă aflați fără să atingeți
telefonul.

## Ce aduce un beacon în plus față de o etichetă QR

O [etichetă QR](qr-codes.md) este ieftină, nu are nevoie de baterie și
ține cât ține lipiciul — dar trebuie să scoateți telefonul, să găsiți
eticheta cu camera și să o țineți nemișcată. Un beacon lucrează invers:
eticheta își strigă identitatea de câteva ori pe secundă, iar telefonul
din buzunarul de la piept o aude în timp ce treceți pe lângă ea.

| | Etichetă QR | Beacon BLE |
|---|---|---|
| Cum se citește | Cu camera, îndreptată spre etichetă | Prin radio, fără mâini |
| Costuri | Hârtie și lipici | O etichetă și o baterie de schimbat |
| Precizie | Exactă — sunteți chiar la acea etichetă | Aproximativă — aplicația se declanșează când semnalul devine destul de puternic, de regulă în câțiva metri |
| Poate porni sau opri o tură | Da, la o intrare | Nu, niciodată — doar înregistrează puncte |
| Funcționează cu telefonul în buzunar | Nu | Da, iar pe Android chiar și cu ecranul stins |

Cele două nu sunt alternative: un loc poate avea și una, și alta, iar
majoritatea peșterilor sunt cel mai bine servite dacă etichetați totul și
puneți beaconuri doar acolo unde vreți confirmare fără mâini — la
intersecții, în capul unui puț, într-o serie de intrare.

Fiți realiști în privința a ceea ce înseamnă detectarea. Aplicația nu
măsoară o distanță și nici o direcție; raportează orice tag înregistrat
al cărui semnal a trecut de prag. Roca, apa și propriul corp atenuează
puternic undele radio de 2,4 GHz, așa că raza practică într-o galerie
este de câțiva metri și variază după felul în care este montat tagul.
Detectarea este oprită implicit, iar scanarea QR rămâne metoda exactă.

## Taguri compatibile

Sunt recunoscute două familii.

**Taguri de tip iBeacon.** Orice tag care emite un cadru iBeacon
standard, inclusiv familia HoneyComm BP1003 (HCBB01, HCBB07, HCBB16,
HCBB22, HCBB62, H8), al cărei identificator de proximitate din fabrică
este `FDA50693-A4E2-4FB1-AFCF-C6EB07647825`. Un astfel de tag este
identificat prin trei valori: identificatorul său de proximitate plus un
număr **major** și unul **minor**. SpeleoLoc nu reține nimic altceva
despre el — doar când a fost auzit ultima dată, fără citirea bateriei și
fără valori de senzor — chiar dacă Laborator beacon poate decoda cifrele
suplimentare pe care un tag HoneyComm le emite alături de identitate.

**Taguri senzor Ruuvi.** RuuviTag și RuuviTag Pro (2-in-1 și 3-in-1). Un
tag Ruuvi este identificat prin adresa MAC din emisia sa și transmite în
plus temperatura, umiditatea, presiunea atmosferică, tensiunea bateriei
și mișcarea. SpeleoLoc culege aceste valori din emisii cât timp rulează
detectarea și oferă o citire în timp real și un istoric de măsurători
descărcabil — vedeți [Taguri senzor Ruuvi](ruuvi-sensors.md).

Pe Android telefonul aude orice iBeacon din rază, indiferent de
identificatorul său de proximitate. Pe iPhone sistemul de operare
raportează doar tagurile al căror identificator de proximitate este deja
cunoscut aplicației: identificatorul din fabrică de mai sus funcționează
direct, oricare altul trebuie adăugat mai întâi în Laborator beacon (mai
jos), altfel tagul nu va apărea niciodată în selectorul **Beaconuri în
apropiere**.

## Asocierea unui tag cu un loc din peșteră

Un tag nu înseamnă nimic până nu este legat de un loc din peșteră.
Faceți asta în peșteră, stând chiar în punctul pe care îl echipați.

1. Montați tagul. Deschideți peștera, deschideți locul din peșteră și
   derulați formularul până la secțiunea **Beaconuri BLE**. Ea apare doar
   după ce locul a fost salvat cel puțin o dată.
2. Apăsați **Asociază beacon**. Pe Android aplicația cere prima dată
   permisiunile de Bluetooth și de localizare, iar dacă comutatorul de
   localizare al telefonului este oprit afișează **Activează
   localizarea**, cu o scurtătură către setarea de sistem — Android nu
   livrează niciun rezultat de scanare Bluetooth cât timp acel comutator
   este oprit, deși SpeleoLoc nu preia nicio poziție.
3. Se deschide dialogul **Beaconuri în apropiere**, care scanează
   continuu și afișează „Se caută beaconuri… ține telefonul lângă tag”
   până când aude ceva. Intrările sunt ordonate cu semnalul cel mai
   puternic primul, așa că ținând telefonul lipit de tagul tocmai montat
   acesta ajunge de obicei în capul listei. Un tag care nu mai este auzit
   timp de 15 secunde dispare din listă, deci o citire veche nu poate
   trece înaintea celei pe care o aveți în mână.
4. Apăsați tagul. Înregistrarea este scrisă imediat, iar aplicația
   confirmă „Beacon asociat acestui loc”.

> 📷 [Formularul locului din peșteră: coduri și beacon](../screenshots/04-places-and-qr-codes.md#cave-place-form-codes-and-beacons) — formularul locului din peșteră, derulat de la Titlu, prin Beaconuri BLE, până la filele Hărți.

Două lucruri despre acel dialog merită știute. Tagurile deja înregistrate
oriunde în **această** peșteră sunt afișate cu o bifă verde și cu
mențiunea „deja asociat” și nu pot fi apăsate — același tag fizic nu
poate fi asociat de două ori în aceeași peșteră. Iar un rând Ruuvi arată
citirile sale în timp real (temperatură, umiditate, presiune, baterie)
lângă puterea semnalului, ceea ce este un mod rapid de a confirma că vă
uitați la tagul potrivit.

Asocierea **nu** face parte din butonul de salvare al formularului. Ea
intră în vigoare în momentul în care apăsați tagul, iar părăsirea
formularului fără salvare nu o anulează.

### Eliminarea unei asocieri

Butonul de dezasociere (**Dezasociază beaconul**) din dreapta unui rând
de beacon întreabă „Elimini beaconul … de la acest loc?” și, la **Da**,
eliberează tagul. Nimic altceva nu este șters — locul din peșteră,
documentele și punctele sale de tură rămân neatinse — iar tagul poate fi
asociat imediat în altă parte. Același buton există și în lista
**Beaconurile peșterii**.

## Pornirea detectării

Detectarea este o preferință a fiecărui dispozitiv. Este oprită implicit
și nu se scanează nimic până nu o porniți.

1. Deschideți **Setări → Detectare beaconuri**.
2. Porniți **Detectează beaconurile automat**. Aplicația cere
   permisiunile de Bluetooth și de localizare dacă nu le are; dacă
   refuzați, avertizează „Permisiunile Bluetooth/localizare sunt
   necesare pentru scanarea beaconurilor”, iar comutatorul rămâne oprit.
3. Dacă scanarea nu poate porni — cel mai adesea pentru că Bluetooth-ul
   însuși este oprit — primiți „Detectarea nu a putut porni — verifică
   dacă Bluetooth este pornit”. Porniți Bluetooth și aplicația se
   rearmează singură.

Odată activată, detectarea pornește din nou de la sine de fiecare dată
când deschideți aplicația, fără să mai întrebe nimic.

### Comutatorul rapid din meniul lateral

Meniul lateral din dreapta (butonul suplimentar din bara aplicației) are
un comutator **Detectare beaconuri** la baza blocului de navigare. Este
același comutator cu cel din Setări și cele două arată mereu la fel, așa
că puteți opri detectarea cât lucrați într-un punct, sau o puteți rearma,
fără să părăsiți ecranul pe care sunteți.

### Opțiuni

Cursoarele și comutatoarele de sub comutatorul principal sunt inactive
până când **Detectează beaconurile automat** este pornit, iar **Interval
de scanare în fundal** are nevoie și de **Continuă detectarea în fundal**.
**Administrare tag-uri** și **Laborator beacon** rămân accesibile oricum.

| Control | Ce face | Implicit |
|---|---|---|
| **Detectează beaconurile automat** | Comutatorul principal. Cu aplicația deschisă, trecerea pe lângă un beacon înregistrat identifică locul și înregistrează un punct de tură. | Oprit |
| **Prag de declanșare a semnalului** | Cursor de la −100 la −40 dBm. Un tag contează doar dacă semnalul său este mai puternic decât atât. O valoare mai apropiată de zero înseamnă că trebuie să fiți mai aproape. | −75 dBm |
| **Pauză între redeclanșări** | Cursor de la 1 la 30 de minute. După o detectare, același tag tace atâta timp, ca lucrul într-un singur punct să nu declanșeze la nesfârșit. | 5 min |
| **Deschide locul la detectare** | Navighează la locul detectat, exact ca la scanarea unui QR. Oprit înseamnă că primiți doar mesajul și punctul de tură. | Oprit |
| **Sunet la detectare** | Redă o alertă sonoră la detectare: un sunet scurt în aplicație când aceasta este pe ecran, sunetul de notificare la detectarea în fundal. | Pornit |
| **Continuă detectarea în fundal** | Doar pe Android — continuă scanarea cu ecranul stins sau cu altă aplicație în față. Vedeți mai jos. | Oprit |
| **Interval de scanare în fundal** | Cursor de la 5 la 60 de secunde: cât de des pornește o scurtă rafală de scanare în timpul detectării în fundal. Mai lung înseamnă baterie economisită. | 30 s |
| **Administrare tag-uri** | Deschide biblioteca de taguri — titluri, poze și locuri pentru fiecare tag înregistrat. | — |
| **Laborator beacon** | Deschide ecranul de diagnostic. | — |

## Ce se întâmplă când treceți pe lângă un tag

Un tag înregistrat declanșează o detectare când semnalul său este mai
puternic decât **Prag de declanșare a semnalului** și a fost auzit **de
două ori în cinci secunde**. A doua auzire este cea care împiedică o
singură reflexie rătăcită să producă o detectare falsă. Tagurile pe care
nu le-ați înregistrat sunt ignorate complet.

La o detectare, cu aplicația pe ecran:

- un mesaj afișează `Loc detectat: "<titlul locului>"`;
- se aude o alertă scurtă, dacă **Sunet la detectare** nu este oprit;
- dacă o tură este în desfășurare **în aceeași peșteră**, se înregistrează
  un punct de tură, iar mesajul primește în plus „· Punct adăugat la
  tură” — vedeți [Ture](trips.md);
- dacă **Deschide locul la detectare** este pornit, aplicația deschide
  locul pe cea mai potrivită hartă a acelei peșteri, revenind la
  formularul simplu al locului atunci când locul nu este marcat pe nicio
  hartă;
- apoi tagul acela tace pe durata **pauzei între redeclanșări**.

### Ce nu face detectarea, în mod deliberat

**Nu pornește și nu oprește niciodată o tură.** Scanarea etichetei QR de
la o intrare vă poate propune să porniți sau să opriți una; o detectare
de beacon nu poate, pentru că un dialog apărut în timp ce treceți pe
lângă un tag ar fi mai rău decât inutil. Chiar și cu un tag pe intrare,
porniți și opriți tura dumneavoastră — la suprafață, înainte de a intra.

**Nu întreabă niciodată la ce peșteră v-ați referit.** Un tag poate fi
înregistrat o singură dată în fiecare peșteră, dar același tag fizic
poate fi înregistrat în două peșteri diferite — după ce a fost mutat la
alt obiectiv, de exemplu. În acest caz aplicația alege în tăcere: câștigă
peștera turei în desfășurare, apoi peștera deschisă cel mai recent, apoi
prima potrivire. **Setări → General → Selectează peștera la scanare QR
ambiguă** nu are niciun efect asupra detectărilor de beacon.

## Detectarea în fundal (Android)

**Continuă detectarea în fundal** lasă scanarea să continue cu ecranul
stins sau cu altă aplicație în față — ceea ce este chiar rostul
beaconurilor, de vreme ce telefonul poate rămâne în buzunarul de la
piept.

Pornirea ei cere permisiunea de notificări (fără ea opțiunea refuză să se
activeze, avertizând „Permisiunea de notificări este necesară pentru
alertele în fundal”) și permisiunea de a rula nerestricționat în fundal.
Cât timp este activă, o notificare permanentă afișează **Detectare
beaconuri SpeleoLoc — Se scanează beaconurile din peșteră…**.

Pentru că trebuie să reziste ore întregi în subteran, scanarea în fundal
este intermitentă: o rafală scurtă cam la fiecare **Interval de scanare
în fundal** secunde, în loc de ascultare continuă. Acesta este
compromisul de înțeles — un interval lung economisește multă baterie, dar
un tag pe lângă care treceți în pas vioi între două rafale pur și simplu
nu este auzit niciodată. În cadrul unei rafale, o singură auzire
puternică este de ajuns pentru declanșare, fiindcă două rafale pot fi la
un minut distanță.

O detectare în fundal se comportă altfel decât una cu aplicația pe ecran:

- în loc de un mesaj ridică o notificare de sistem intitulată
  `Loc detectat: <titlul locului>`, cu vibrație și cu un sunet redat la
  volumul de **alarmă**, ca să îl auziți cu volumul media dat jos;
- apăsarea notificării deschide acel loc din peșteră, chiar dacă între
  timp aplicația fusese închisă;
- **Deschide locul la detectare** nu se aplică — nu se deschide nimic
  până nu apăsați;
- cu **Sunet la detectare** oprit notificarea este silențioasă, dar tot
  apare, iar punctul de tură tot este înregistrat.

Aceasta este o funcție Android. Pe iPhone, și pe Android cu opțiunea
oprită, scanarea se oprește când aplicația părăsește ecranul și se reia
când reveniți la ea.

## Evidența tagurilor

### Beaconurile peșterii — tagurile unei peșteri

Butonul **Peșteră** de la capătul barei de instrumente a unei liste de
locuri din peșteră deschide un mic meniu cu intrarea **Beaconurile
peșterii**, care listează fiecare tag înregistrat oriunde în acea
peșteră. Fiecare rând arată:

| Partea rândului | Ce înseamnă |
|---|---|
| Titlu | Locul din peșteră la care este montat tagul. |
| Linia de identitate | Pentru un tag Ruuvi, modelul și adresa MAC (și versiunea de firmware, dacă este cunoscută); pentru un iBeacon, major/minor și identificatorul de proximitate. |
| **Văzut ultima dată** | Când a auzit acest telefon tagul ultima dată, sau „niciodată”. |
| Citiri | Bateria în mV plus ultimele valori de temperatură, umiditate și presiune raportate de tag — doar la tagurile Ruuvi. |
| Pictogramă portocalie de baterie | **Baterie slabă**: tagul a raportat ultima dată sub 2500 mV. Doar la tagurile Ruuvi. |

Asta o face verificarea firească dinaintea unei expediții: deschideți-o
după ultima tură și vedeți care taguri au amuțit și care au nevoie de
baterii noi. Apăsarea unui rând deschide locul din peșteră; un rând Ruuvi
are și un buton direct către citirile sale în timp real, iar fiecare rând
are butonul de dezasociere.

Citirile se împrospătează doar când un telefon chiar aude tagul, așa că
**Văzut ultima dată** rămâne unde era până când cineva trece cu telefonul
pe lângă tag cu detectarea pornită.

### Administrare tag-uri — toate tagurile pe care le aveți

**Setări → Detectare beaconuri → Administrare tag-uri** listează fiecare
tag înregistrat din toate peșterile, sortat după peșteră și apoi după
loc. Fiecare rând poartă poza tagului, numele pe care i l-ați dat (sau
modelul lui, sau identitatea lui, dacă nu i-ați dat niciunul), peștera și
locul de care aparține și când a fost văzut ultima dată. Dacă nu este
nimic înregistrat încă, scrie „Niciun tag înregistrat încă”.

Deschiderea unui tag vă dă un editor cu:

- o poză a tagului fizic — butoanele de cameră, galerie și ștergere de
  sub imagine sunt **Fă o poză**, **Alege din galerie** și **Șterge
  poza**. Poza este salvată imediat ce o faceți;
- un **Titlu** și o **Descriere**, salvate cu butonul de salvare din bara
  aplicației, care confirmă „Tag salvat” și revine la listă;
- identitatea tagului, când a fost văzut ultima dată și ultima citire a
  bateriei sale;
- **Deschide locul din peșteră**, o scurtătură către locul de care este
  asociat.

Rostul acestor lucruri este recunoașterea hardware-ului pe teren.
Beaconurile arată identic unul cu altul, așa că o poză a tagului chiar pe
rocă și un titlu de tipul „intersecție, peretele stâng, la 2 m înălțime”
sunt cele care vă spun la ce tag vă uitați când unul nu mai răspunde.

Titlul și descrierea ajung pe celelalte dispozitive împreună cu datele
dumneavoastră. **Poza nu** — ea rămâne pe telefonul cu care a fost făcută
și nu este inclusă în sincronizare sau în exporturile de arhivă.

## Când un tag nu este detectat

Parcurgeți lista de mai jos înainte de a presupune că hardware-ul este
mort.

1. **Este Bluetooth pornit?** Activarea detectării cu el oprit
   avertizează „Detectarea nu a putut porni — verifică dacă Bluetooth
   este pornit”.
2. **Pe Android, este pornit comutatorul de localizare al telefonului?**
   Rezultatele scanării Bluetooth sunt livrate doar cât timp este pornit,
   deși SpeleoLoc nu preia nicio poziție. Cu el oprit, scanarea nu
   găsește absolut nimic, în tăcere — ceea ce arată exact ca un hardware
   defect. Selectoarele și ecranele Ruuvi vă avertizează despre asta prin
   dialogul **Activează localizarea**; detectarea automată nu o face, așa
   că verificați dumneavoastră.
3. **Este detectarea chiar pornită?** Verificați comutatorul **Detectare
   beaconuri** din meniul lateral.
4. **Mai este tagul în pauză?** După o detectare tace pe durata pauzei
   între redeclanșări, cinci minute implicit.
5. **Sunteți destul de aproape?** Coborâți **Prag de declanșare a
   semnalului** (mai departe de zero, de exemplu −85 dBm) ca să se
   declanșeze de la distanță mai mare, cu prețul unor detectări false mai
   dese, venite de la puncte vecine.
6. **Este aplicația pe ecran?** Dacă **Continuă detectarea în fundal** nu
   este pornit, scanarea se oprește când aplicația nu mai este pe ecran.
7. **Pe iPhone**, dacă tagul nici măcar nu a ajuns în selectorul
   **Beaconuri în apropiere**, adăugați-i identificatorul de proximitate
   în Laborator beacon și asociați-l din nou — selectorul vede doar
   identificatorii din listă. Un tag deja asociat este detectat
   indiferent de identificatorul său.

### Laborator beacon

**Setări → Detectare beaconuri → Laborator beacon** este ecranul de
depanare hardware. Nu are nicio legătură cu peșterile dumneavoastră —
arată doar ce aude radioul, în formă brută, și este unealta la care
apelați când un tag refuză să fie văzut. Un punct roșu lângă **Linii de
jurnal capturate**, în partea de sus, vă spune că o captură este în
desfășurare, iar numărul de alături numără ce s-a strâns până acum.

Fila **iBeacon** listează tot ce prinde telefonul, cu semnalul cel mai
puternic primul, după ce apăsați **Pornește scanarea**. Fiecare intrare
dă major/minor și identificatorul de proximitate ale tagului, o distanță
estimată în metri, câte pachete au sosit, cu cât timp în urmă a fost
ultimul și cel mai slab și cel mai puternic semnal văzut. Parcurgerea
galeriei cu acest ecran deschis este un mod practic de a verifica o
poziție de montaj și de a găsi unde nu mai este auzit un tag.

Deasupra listei stă lista identificatorilor de proximitate, sub formă de
etichete, cu **Adaugă UUID de proximitate** pentru a introduce încă unul
— necesar dacă tagurile dumneavoastră au fost reprogramate cu alt
identificator decât cel din fabrică. Pe Android aplicația notează că
scanează oricum toate beaconurile iBeacon și că lista este necesară doar
pe iOS; pe iPhone această listă este și ceea ce are voie să vadă
selectorul **Beaconuri în apropiere**. Cel puțin un identificator este
păstrat mereu.

Fila **Scanare brută** coboară cu un nivel, listând orice dispozitiv
Bluetooth din apropiere cu semnalul său și decodând ce poate din emisie —
baterie, MAC, temperatură și umiditate pentru tagurile HoneyComm, setul
complet de senzori pentru Ruuvi. **Afișează doar dispozitivele de tip
beacon** este pornit implicit; opriți-l ca să vedeți fiecare dispozitiv
din jur. Apăsați un rând ca să extindeți detaliile decodate.

Două butoane din bara aplicației se aplică ambelor file: **Exportă
jurnalul de captură** scrie tot ce s-a capturat într-un fișier ales de
dumneavoastră (oferit ca `beacon_lab_<timestamp>.jsonl`), ca să poată fi
trimis mai departe pentru analiză, iar **Șterge datele capturate**
golește listele și jurnalul. Exportul este material citibil de mașină,
pentru cineva care diagnostichează un tag; aplicația nu îl citește
niciodată înapoi.

## Ce ajunge pe celelalte dispozitive

Care tag este montat la care loc este o dată partajată. Înregistrați un
tag o singură dată și fiecare coechipier care vă importă arhiva sau se
sincronizează cu dumneavoastră primește acea înregistrare, așa că și
telefoanele lor încep să îl detecteze — vedeți [Panoul de sincronizare
și Istoric modificări](sync-and-change-log.md).

Cifrele de stare pe care le adună fiecare telefon — văzut ultima dată,
bateria și, la tagurile Ruuvi, ultimele valori de temperatură, umiditate
și presiune — călătoresc odată cu înregistrarea, dar nu produc niciodată
un conflict de sincronizare, pentru că două dispozitive au văzut pe bună
dreptate același tag în momente diferite.

Două lucruri rămân locale: pozele tagurilor și orice istoric de
măsurători Ruuvi descărcat de pe un tag.

## Vezi și

- [Locuri din peșteră](cave-places.md)
- [Taguri senzor Ruuvi](ruuvi-sensors.md)
- [Coduri QR — amplasare, scanare, tipărire](qr-codes.md)
- [Ture — înregistrarea traseului](trips.md)
- [Navigarea în subteran](../workflows/navigating-underground.md)
- [Setări](settings.md)
