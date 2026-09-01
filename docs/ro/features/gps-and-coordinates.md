# GPS și coordonate

[← Înapoi la cuprins](../README.md)

Cum ajunge o poziție de la suprafață pe un loc din peșteră: înregistratorul
GPS și media sa continuă, scrierea sau lipirea coordonatelor în format
zecimal, DMS sau UTM, și la ce acuratețe să vă așteptați stând la o intrare.

## Ce înseamnă aici o poziție

O poziție aparține întotdeauna unui **loc din peșteră** — aplicația nu
păstrează coordonate în altă parte. Sunt trei numere:

| Câmp | Semnificație |
| --- | --- |
| **Latitudine** | Grade zecimale, nordul pozitiv (WGS84, aceeași referință folosită de receptoarele GPS și de Google Earth). |
| **Longitudine** | Grade zecimale, estul pozitiv. |
| **Altitudine** | Metri, opțional, exact așa cum a raportat-o receptorul GPS. |

Orice loc poate avea una, nu doar intrările, iar fiecare loc care are una
este desenat pe [harta peșterilor](surface-map.md).

Cele trei câmpuri stau în formularul locului din peșteră, dar sunt ascunse
până când bifați **Arată/Ascunde coordonate GPS** din meniul ⋮ al locului.
Alegerea nu este reținută între vizite — vezi
[Locuri din peșteră](cave-places.md).

**Nimic nu se scrie în loc până nu îl salvați.** Înregistratorul, alegerea
pe hartă și dialogul de scriere fac același lucru: completează câmpurile
formularului și se închid. Cât timp textul unui câmp diferă de ce este
păstrat pentru loc, câmpul are o nuanță verde palidă, așa că o poziție
nesalvată se observă ușor; salvarea șterge nuanța.

## Cele patru moduri de a le completa

| Mod | Unde se află | Ce completează |
| --- | --- | --- |
| **Înregistrare punct GPS** | Butonul cu reticul de la capătul rândului de coordonate | Latitudine, longitudine **și** altitudine |
| **Alege coordonatele pe hartă** | Butonul glob de pe rând și globul din bara de aplicație — acela funcționează chiar și când rândul este ascuns | Doar latitudine și longitudine |
| **Introdu coordonatele** | Butonul cu tastatură de pe rând | Doar latitudine și longitudine |
| **Importă puncte (GPX/KML)** | Meniul ecranului principal; creează locuri întregi, nu editează unul | Latitudine, longitudine și elevația din fișier |

Alegerea pe hartă este descrisă la
[Folosirea hărții ca selector de coordonate](surface-map.md#using-the-map-as-a-coordinate-picker);
schimbul de fișiere la [Transfer de locuri GPX/KML](place-transfer.md).

## Înregistrarea unui punct cu înregistratorul GPS

**Înregistrare punct GPS** deschide un ecran propriu, cu două carduri și
două butoane. Există pentru că un singur fix GPS la intrarea unei peșteri
este o măsurătoare slabă, iar media multora este una mult mai bună.

### Poziție curentă (medie)

Cardul de sus pornește de la *Aștept fix GPS…* și apoi se actualizează pe
măsură ce sosesc citirile:

| Rând | Ce arată |
| --- | --- |
| **Latitudine** / **Longitudine** | Media tuturor fixurilor luate de la deschiderea ecranului, cu șapte zecimale |
| **Altitudine** | Altitudinea medie, în metri, peste fixurile care au raportat una |
| **Acuratețe** | `±n m` pentru **ultimul fix**, nu pentru medie |
| **Mostre** | Câte fixuri au intrat până acum în medie |

Sub ele, o bară și un cuvânt evaluează acea ultimă cifră de acuratețe:

| Citire | Evaluare |
| --- | --- |
| 5 m sau mai bine | Excelent |
| 5–10 m | Bun |
| 10–20 m | Acceptabil |
| 20–50 m | Slab |
| mai slab de 50 m | Foarte slab |
| fără acuratețe raportată | Necunoscut |

### Capturează, apoi Folosește această poziție

1. Stați nemișcat, cu telefonul în loc deschis, și lăsați **Mostre** să
   crească. Latitudinea și longitudinea mediate nu mai rătăcesc după câteva
   zeci de citiri; această așezare este rostul ecranului.
2. Apăsați **Capturează**. Media curentă este înghețată în cardul de jos,
   *Captură salvată*, împreună cu numărul de mostre din care a fost făcută.
   Acuratețea păstrată cu o captură este **cea mai bună citire individuală
   văzută până atunci**, așa că tratați-o ca pe o cifră optimistă, nu ca pe
   eroarea mediei.
3. Apăsați **Folosește această poziție**. Ecranul se închide, iar
   latitudinea, longitudinea și altitudinea ajung în formularul locului din
   peșteră. Salvați locul.

**Capturează** rămâne stins până sosește primul fix, iar **Folosește această
poziție** până când s-a capturat ceva. × de pe cardul capturii
(**Anulează captura**) o aruncă, ca să puteți captura din nou.

### Media nu repornește cât timp rămâneți pe ecran

Media continuă se adună din momentul în care se deschide înregistratorul și
nu este niciodată resetată cât timp acesta rămâne deschis — nici anularea
unei capturi nu o repornește. Două urmări pe teren:

- primele fixuri sălbatice, luate cât receptorul încă se așeza, rămân în
  medie atâta timp cât stați pe ecran;
- dacă mergeți la a doua intrare fără să părăsiți înregistratorul, citirea
  devine un amestec al ambelor locuri.

Ca să obțineți o medie curată, ieșiți din înregistrator și deschideți-l din
nou.

### Mediere și pe hartă

**Folosește locația mea** din bara de plasare a hărții funcționează la fel:
pornește o medie nouă și tot împinge pinul spre ea pe măsură ce sosesc
citirile. Atingerea hărții sau tragerea pinului oprește medierea, la fel ca
o a doua apăsare a butonului. Nimic din bară nu arată că medierea încă
rulează, așa că stați nemișcat câteva secunde înainte de a confirma. Vezi
[Harta peșterilor](surface-map.md#placing-the-point).

## Scrierea sau lipirea coordonatelor

Butonul cu tastatură deschide **Introdu coordonatele**, o singură casetă
etichetată *Coordonate (zecimal, DMS sau UTM)*. Lipiți o poziție dintr-o
fișă de cartare, dintr-un mesaj sau din altă aplicație; formatul este dedus
din textul însuși, indiferent ce spune setarea de afișare.

| Format | Exemplu acceptat de aplicație |
| --- | --- |
| Grade zecimale | `45.359167, 22.714722` — și `45,359167 22,714722`, cu virgula ca semn zecimal și cu punct și virgulă sau spațiu simplu ca separator. Latitudinea prima. |
| Grade, minute, secunde | `45°21'33.0"N 22°42'53.0"E`. Literele de emisferă sunt obligatorii și fie stau amândouă înaintea numerelor, fie amândouă după ele, așa că merge și `N45 21.55 E22 42.88` (grade și minute zecimale), iar jumătatea E poate fi pusă prima. |
| UTM | `34T 634605 5023721`. Litera de bandă este obligatorie — ea îi spune aplicației la ce emisferă vă referiți — iar coordonata estică vine înaintea celei nordice. |

Cele trei linii de exemplu sunt tipărite sub câmp, ca memento. Dacă textul
nu poate fi citit, dialogul spune **Format de coordonate nerecunoscut** și
rămâne deschis ca să îl puteți îndrepta; o poziție în afara ±90° / ±180°
este refuzată la fel. La **OK** punctul este convertit în grade zecimale și
scris în câmpurile Latitudine și Longitudine. Câmpul Altitudine rămâne
neatins.

### Scrierea direct în câmpuri

Câmpurile Latitudine, Longitudine și Altitudine sunt simple câmpuri
numerice: grade zecimale și metri, nimic altceva. Sunt citite la salvare,
iar **orice nu este un număr este tratat ca lipsă de valoare** — locul se
salvează fără poziție și fără avertisment. O latitudine scrisă pe jumătate,
sau un șir DMS lipit de mână în câmp, se pierde în tăcere. Folosiți
**Introdu coordonatele** pentru orice nu este deja zecimal și aruncați o
privire pe câmpuri după salvare dacă le-ați scris chiar dumneavoastră.

## Formatul de afișare a coordonatelor

**Setări → Hartă → Formatul de afișare a coordonatelor** alege cum sunt
*arătate* pozițiile:

| Opțiune | Cum arată |
| --- | --- |
| **Grade zecimale** (implicit) | `45.359167, 22.714722` |
| **Grade, minute, secunde (DMS)** | `45°21'33.0"N 22°42'53.0"E` |
| **UTM** | `34T 634605 5023721`, rotunjit la metri întregi |

Alegerea este reținută și se aplică la cardul de informații al locului de pe
harta peșterilor, la linia de coordonate din bara de plasare și la o linie
gri în plus sub câmpurile formularului locului din peșteră — acea linie
apare doar când formatul este DMS sau UTM, fiindcă la grade zecimale ar
repeta câmpurile.

Este doar o setare de afișare. Câmpurile Latitudine și Longitudine, ca și
fișierele GPX și KML exportate, țin întotdeauna grade zecimale, iar
introducerea coordonatelor acceptă toate cele trei formate, indiferent ce
alegeți aici. Pozițiile din afara benzii UTM (sub 80° S sau peste 84° N)
revin la grade zecimale.

## La ce să vă așteptați la intrarea unei peșteri

- **Pe orizontală.** În loc deschis, un telefon care a stat nemișcat destul
  cât să ajungă la *Bun* sau *Excelent* va pune de obicei o intrare la
  câțiva metri — destul cât să vă întoarceți la ea. Sub o stâncă, într-o
  dolină sau sub coronament des, cifra de acuratețe crește și media
  derivează; acela este receptorul, nu aplicația. Înregistrați punctul din
  cel mai deschis loc pe care puteți sta și notați decalajul în descrierea
  locului dacă a trebuit să vă îndepărtați de intrare.
- **Pe verticală.** Altitudinea este ce raportează receptorul și este
  întotdeauna cel mai slab dintre cele trei numere — așteptați-vă să nu se
  potrivească cu o hartă sau cu un altimetru, adesea cu zeci de metri.
  Merită înregistrată, dar nu o tratați ca pe o cotă de cartare.
- **Harta nu completează niciodată altitudinea.** Plasarea sau mutarea unui
  punct pe hartă scrie latitudinea și longitudinea și nimic altceva, așa că
  un loc poziționat astfel păstrează altitudinea pe care o avea deja. Dacă
  vă trebuie înălțimea, folosiți **Înregistrare punct GPS** stând acolo, sau
  scrieți-o în câmpul Altitudine.
- **Repetați.** Înregistrarea aceleiași intrări în două vizite și
  compararea celor două medii vă spune mai multe despre acuratețea reală
  decât orice număr de pe ecran.

## Permisiunea de locație

Aplicația cere locația prima dată când deschideți înregistratorul sau
folosiți **Locația mea** pe hartă, și numai cât timp aplicația este în uz —
nu vă urmărește niciodată în fundal. Locația este și ceea ce cere Android
înainte de a da rezultatele scanării Bluetooth, așa că aceeași permisiune
servește [Beaconuri BLE](ble-beacons.md).

Dacă nu poate obține o poziție, înregistratorul înlocuiește ambele carduri
cu o explicație:

| Panou | Ce înseamnă | Butonul lui |
| --- | --- | --- |
| **Servicii de locație dezactivate** | Comutatorul de locație al dispozitivului este oprit | **Deschide setări** duce la ecranul de locație al sistemului; înregistratorul pornește din nou când reveniți |
| **Permisiune locație refuzată** | Permisiunea a fost refuzată | **Deschide setări** duce la pagina de permisiuni a aplicației |
| **Eroare GPS** | Orice altceva a raportat receptorul | **Reîncearcă** |

Pe harta peșterilor, aceleași două situații arată în schimb un avertisment
scurt în partea de jos a ecranului — *Serviciile de localizare sunt oprite*
sau *Permisiune de localizare refuzată* — iar aplicația vă deschide pagina
de setări potrivită acolo unde asta poate ajuta.

## Vezi și

- [Locuri din peșteră](cave-places.md)
- [Harta peșterilor](surface-map.md)
- [Transfer de locuri GPX/KML](place-transfer.md)
- [Setări](settings.md)
- [Documentarea unei peșteri noi](../workflows/documenting-a-new-cave.md)
