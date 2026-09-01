# Harta peșterilor

[← Înapoi la galeria de capturi](README.md) · [← Înapoi la cuprins](../README.md)

Harta geografică pe tot ecranul, care desenează fiecare loc din peșteră ce are
coordonate GPS.

> Aplicația rulează implicit în **română**, așa că imaginile arată etichetele
> în română. Fiecare intrare listează textul de pe ecran alături de
> echivalentul lui în engleză.

**Pe această pagină:** [Harta peșterilor pe un strat de bază topografic](#cave-map-topo-entrances) · [Etichetele degajate ale intrărilor](#cave-map-decluttered-labels) · [Vedere depărtată peste un masiv întreg](#cave-map-zoomed-out) · [Gruparea marcajelor sub zoomul 14](#cave-map-clusters) · [Reperele intrărilor de aproape](#cave-map-entrance-markers) · [Trecerea la un strat de bază satelitar](#cave-map-satellite-layer) · [Panoul cu toate locurile](#cave-map-all-places-panel) · [Măsurarea unei distanțe pe hartă](#cave-map-measure-distance) · [Adăugarea unei peșteri sau a unei intrări de pe hartă](#cave-map-add-point-menu) · [Plasarea punctului pentru o peșteră nouă](#cave-map-new-cave-placement)

---

<a id="cave-map-topo-entrances"></a>

## Harta peșterilor pe un strat de bază topografic

![Harta peșterilor pe un strat de bază topografic](../../images/cave-map-topo-entrances.jpg)

*Harta de suprafață arătând intrări de peșteră pe un strat de bază topografic.*

Harta de suprafață pe tot ecranul desenează pe un strat de bază topografic
fiecare loc din peșteră care are coordonate GPS; nu are bară de aplicație, așa
că o bară de instrumente compactă stă direct peste hartă. Două intrări sunt
desenate cu reperul în formă de arcadă de peșteră și etichetate (Avenul
Guguiova, Pestera F. P. din Dealul Runcului), iar balonul albastru marcat cu 2
este o grupare de marcaje care, apăsată, mărește exact pe membrii ei. Din bara
de instrumente harta se recentrează cu Locația mea, se deschid Straturi hartă,
se comută Ascunde locurile din alte peșteri și Ascunde locurile care nu sunt
intrări (ambele active aici, arătate în albastru), se deschid panourile Toate
locurile din peșteri sau Intrări, se pornește Măsoară distanța ori se
folosește Adaugă punct. Linia de atribuire pentru OpenStreetMap, SRTM și
OpenTopoMap trece de-a lungul marginii de jos.

<details><summary>Textul de pe ecran (română → engleză)</summary>

- Înapoi — Back (săgeata, în extrema stângă a barei de instrumente)
- Locația mea — My location (pictogramă cu reticul, inactivă)
- Straturi hartă — Map layers (pictogramă cu foi suprapuse)
- Ascunde locurile din alte peșteri — Hide places from other caves (comutator glob, activ/albastru)
- Ascunde locurile care nu sunt intrări — Hide non-entrance places (comutator cu puncte împrăștiate, activ/albastru)
- Toate locurile din peșteri — All cave places (pictogramă cu listă marcată)
- Intrări — Entrances (pictogramă cu ușă)
- Măsoară distanța — Measure distance (pictogramă cu riglă)
- Adaugă punct — Add point (pin de adăugare a locației, la marginea dreaptă)
- Marcaje de intrare etichetate „Avenul Guguiova” și „Pestera F. P. din Dealul Runcului”
- Balon albastru de grupare care arată numărul „2”
- Linia de atribuire „© OpenStreetMap contributors, SRTM | © OpenTopoMap (CC-BY-SA)”

</details>

**Descris în:** [Harta peșterilor](../features/surface-map.md)

---

<a id="cave-map-decluttered-labels"></a>

## Etichetele degajate ale intrărilor

![Etichetele degajate ale intrărilor](../../images/cave-map-decluttered-labels.jpg)

*Harta de suprafață pe OpenTopoMap, cu reperele intrărilor etichetate cu titlurile peșterilor.*

Harta de suprafață pe tot ecranul nu are bară de aplicație; o bară de
instrumente compactă stă direct pe hartă, cu Înapoi, Locația mea, Straturi
hartă, Ascunde locurile din alte peșteri (globul, evidențiat pentru că
locurile altor peșteri sunt arătate), Arată locurile care nu sunt intrări
(momentan oprit, așa că se desenează doar intrările), Toate locurile din
peșteri, Intrări, Măsoară distanța și Adaugă punct. Stratul de bază
OpenTopoMap este selectat, așa că în spatele marcajelor se văd curbele de
nivel și valea Cernei. Fiecare intrare este un reper maro în formă de arcadă
de peșteră, cu o etichetă degajată care poartă titlul peșterii, iar acolo unde
intrările stau la câțiva metri una de alta reperele se suprapun într-o mică
stivă. Apăsarea oricărui reper deschide cardul informativ al locului, cu
coordonatele lui și cu o legătură către pagina locului din peșteră.

<details><summary>Textul de pe ecran (română → engleză)</summary>

- Înapoi — Back (săgeata, primul buton din stânga barei de instrumente)
- Locația mea — My location (reticul, inactiv: nu se urmărește nicio fixare GPS)
- Straturi hartă — Map layers (pictogramă cu strat de foi, panou închis)
- Ascunde locurile din alte peșteri — Hide places from other caves (glob, evidențiat = locurile altor peșteri sunt vizibile)
- Arată locurile care nu sunt intrări — Show non-entrance places (pictogramă conturată cu puncte împrăștiate, comutator oprit)
- Toate locurile din peșteri — All cave places (buton de panou-listă)
- Intrări — Entrances (pictogramă cu ușă, buton de panou-listă)
- Măsoară distanța — Measure distance (riglă)
- Adaugă punct — Add point (pictogramă cu pin, marginea dreaptă)
- Repere de intrare de peșteră cu etichetele: belvedere, peșteră regasita, abrimare207, 212intraresapata, 2065m, tub205, tub decolmatare Adi G. 5 m, Rafaila
- Bara de atribuire a plăcilor: © OpenStreetMap contributors, SRTM | © OpenTopoMap (CC-BY-SA)

</details>

**Descris în:** [Harta peșterilor](../features/surface-map.md) · [Documentarea unei peșteri noi](../workflows/documenting-a-new-cave.md)

---

<a id="cave-map-zoomed-out"></a>

## Vedere depărtată peste un masiv întreg

![Vedere depărtată peste un masiv întreg](../../images/cave-map-zoomed-out.jpg)

*Aceeași hartă de suprafață, cu zoomul depărtat; etichetele aglomerate sunt eliminate după prioritate.*

Aceeași vedere OpenTopoMap peste valea Cernei, depărtată cu un pas, ca să
încapă pe ecran mai multe peșteri. Se vede eliminarea etichetelor: grupul dens
de intrări din mijloc păstrează doar câteva etichete, în timp ce intrările
izolate, precum Avenul Gugui, F. P. din Dealul Runcului, Rafaila și test, și
le păstrează pe ale lor. Starea barei de instrumente este neschimbată —
locurile din alte peșteri sunt arătate, Arată locurile care nu sunt intrări
este tot oprit — așa că fiecare marcaj de pe ecran este o intrare de peșteră.
Deplasarea hărții și apropierea sau depărtarea cu două degete sunt tot ce
trebuie pentru a trece între aceste două vederi; poziția camerei este reținută
pentru vizita următoare.

<details><summary>Textul de pe ecran (română → engleză)</summary>

- Înapoi — Back (săgeată)
- Locația mea — My location (reticul, inactiv)
- Straturi hartă — Map layers
- Ascunde locurile din alte peșteri — Hide places from other caves (glob, evidențiat)
- Arată locurile care nu sunt intrări — Show non-entrance places (comutator oprit)
- Toate locurile din peșteri — All cave places
- Intrări — Entrances
- Măsoară distanța — Measure distance
- Adaugă punct — Add point
- Etichete de intrare: Avenul Gugui…, peșteră regasita, abrimare207, tub decolmatare Adi G. 5 m, Rafaila, F. P. din Dealul Runcului, test
- Bara de atribuire a plăcilor: © OpenStreetMap contributors, SRTM | © OpenTopoMap (CC-BY-SA)

</details>

**Descris în:** [Harta peșterilor](../features/surface-map.md)

---

<a id="cave-map-clusters"></a>

## Gruparea marcajelor sub zoomul 14

![Gruparea marcajelor sub zoomul 14](../../images/cave-map-clusters.jpg)

*Harta de suprafață arătând intrări de peșteră și locuri grupate pe plăci topografice.*

Harta peșterilor este o hartă geografică pe tot ecranul, fără bară de
aplicație; o bară de instrumente compactă plutește de-a lungul marginii de
sus, cu Înapoi, Locația mea, Straturi hartă, arată/ascunde celelalte peșteri,
arată/ascunde locurile care nu sunt intrări, Toate locurile din peșteri,
Intrări, Măsoară distanța și Adaugă punct. Intrările de peșteră sunt desenate
ca repere în formă de arcadă, cu etichete degajate precum „Peștera D3 din
Piatra Lupului - Intrare”, „Peștera G1 din Piatra Lupului - Intrare 2” și
„Avenul Guguiova”, iar locurile apropiate se strâng în baloane albastre
numerotate, care se desfac pe măsură ce măriți. Stratul de bază este aici
OpenTopoMap, cu curbe de nivel, iar atribuirea lui este arătată de-a lungul
marginii de jos.

<details><summary>Textul de pe ecran (română → engleză)</summary>

- Înapoi — Back
- Locația mea — My location
- Straturi hartă — Map layers
- Ascunde/Arată locurile din alte peșteri — Hide/Show other caves (comutator glob, activ)
- Ascunde/Arată locurile care nu sunt intrări — Hide/Show non-entrance places (comutator cu puncte)
- Toate locurile din peșteri — All cave places
- Intrări — Entrances
- Măsoară distanța — Measure distance
- Adaugă punct — Add point (parțial tăiat la marginea dreaptă)
- Marcaje de intrare în formă de arcadă de peșteră, cu etichetele: Peștera D3 din Piatra Lupului - Intrare, Peștera G1 din Piatra Lupului - Intrare 2, Avenul Guguiova
- Baloane de grupare numerotate (3, 3, 5, 5, 5, 2)
- Linia de atribuire OpenStreetMap / OpenTopoMap

</details>

**Descris în:** [Harta peșterilor](../features/surface-map.md)

---

<a id="cave-map-entrance-markers"></a>

## Reperele intrărilor de aproape

![Reperele intrărilor de aproape](../../images/cave-map-entrance-markers.jpg)

*Harta de suprafață desenând intrări de peșteră cu etichete degajate peste un strat de bază topografic.*

Harta de suprafață pe tot ecranul, care nu are bară de aplicație: o bară de
instrumente compactă stă direct pe hartă, iar restul ecranului este stratul de
bază topografic, cu locurile din peșteri desenate peste el. Fiecare intrare
este un reper în formă de arcadă de peșteră care își poartă eticheta;
etichetele sunt eliminate după prioritate, așa că, acolo unde mai multe
marcaje se suprapun, rămâne un singur nume. Aici Ascunde locurile din alte
peșteri este activ (globul este evidențiat), iar Arată locurile care nu sunt
intrări este oprit, așa că se desenează doar intrările. Din această stare
harta se deplasează și se mărește, se apasă un marcaj pentru a-i deschide
cardul informativ sau se folosesc Straturi hartă, Măsoară distanța ori Adaugă
punct din bara de instrumente.

<details><summary>Textul de pe ecran (română → engleză)</summary>

- Înapoi — Back (săgeata din bara de instrumente)
- Locația mea — My location
- Straturi hartă — Map layers
- Ascunde locurile din alte peșteri — Hide places from other caves (glob, activ)
- Arată locurile care nu sunt intrări — Show non-entrance places (inactiv)
- Toate locurile din peșteri — All cave places
- Intrări — Entrances
- Măsoară distanța — Measure distance (riglă)
- Adaugă punct — Add point (parțial în afara ecranului, la dreapta)
- Marcaje de intrare în formă de arcadă de peșteră, cu etichetele: „pesteră regasita”, „abrimare207”, „tub decolmatare Adi G. 5 m”, „Rafaila”, „F. P. din Dealul Runcului”, „Avenul Guguiova”, „test”
- Atribuirea stratului de bază: „© Esri, HERE, Garmin, FAO, NOAA, USGS”

</details>

**Descris în:** [Harta peșterilor](../features/surface-map.md)

---

<a id="cave-map-satellite-layer"></a>

## Trecerea la un strat de bază satelitar

![Trecerea la un strat de bază satelitar](../../images/cave-map-satellite-layer.jpg)

*Harta de suprafață peste imagini satelitare Google, cu aceleași intrări pe fotografie aeriană.*

Aceeași încadrare a hărții după alegerea unui strat de bază aerian Google din
Straturi hartă, utilă pentru citirea terenului din jurul unei intrări —
pantele, poienile și albia pârâului se văd acolo unde stratul topografic
desenează doar curbe de nivel. Marcajele proprii ale aplicației sunt
neschimbate: repere maro în formă de arcadă de peșteră, cu etichetele lor
purtând titlul peșterii, cu Ascunde locurile din alte peșteri activ și Arată
locurile care nu sunt intrări oprit. Pinurile violet de aparat foto și numele
precum Pestera lui Ionita, Pestera lui Rafaila și Cascada Moara dracilor, ca
și limita de județ, fac parte din plăcile furnizorului de imagini, nu din
datele SpeleoLoc. Atribuirea © Google înlocuiește creditul OpenTopoMap din
bara de jos.

<details><summary>Textul de pe ecran (română → engleză)</summary>

- Înapoi — Back (săgeată)
- Locația mea — My location (reticul, inactiv)
- Straturi hartă — Map layers (folosit pentru trecerea la stratul de bază aerian Google)
- Ascunde locurile din alte peșteri — Hide places from other caves (glob, evidențiat)
- Arată locurile care nu sunt intrări — Show non-entrance places (comutator oprit)
- Toate locurile din peșteri — All cave places
- Intrări — Entrances
- Măsoară distanța — Measure distance
- Adaugă punct — Add point
- Etichetele de intrare ale aplicației: Avenul Gugui…, peșteră regasita, abrimare207, tub decolmatare Adi G. 5 m, Rafaila, F. P. din Dealul Runcului, test
- Etichete de pe plăcile furnizorului (nu date ale aplicației): Cascada Moara dracilor, Pestera lui Ionita, Pestera lui Rafaila, VALCEA COUNTY / GORJ COUNTY
- Bara de atribuire a plăcilor: © Google

</details>

**Descris în:** [Harta peșterilor](../features/surface-map.md)

---

<a id="cave-map-all-places-panel"></a>

## Panoul cu toate locurile

![Panoul cu toate locurile](../../images/cave-map-all-places-panel.jpg)

*Panoul Toate locurile din peșteri, listând fiecare loc cartat, în ordine alfabetică.*

Panoul Toate locurile din peșteri, deschis din bara de instrumente a hărții de
suprafață și desfășurat peste hartă, nu ca dialog. Fiecare loc din peșteră
care are coordonate este listat alfabetic sub forma „<place> - <cave>”, cu o
pictogramă de arcadă de peșteră și cu mențiunea Intrare principală sau Intrare
dedesubt, acolo unde locul este una dintre ele. Apăsarea unui rând închide
panoul și duce harta, în zbor, la acel loc. Butonul Intrări de alături
deschide aceeași listă, restrânsă doar la intrări.

<details><summary>Textul de pe ecran (română → engleză)</summary>

- Toate locurile din peșteri — All cave places (buton de listă, activ)
- Intrări — Entrances (buton de listă, inactiv)
- Ascunde locurile din alte peșteri — Hide places from other caves (glob, activ)
- Arată locurile care nu sunt intrări — Show non-entrance places (inactiv)
- Straturi hartă — Map layers
- Locația mea — My location
- Măsoară distanța — Measure distance
- Titluri de rând „<place> - <cave>”: „Intrare - 2065m”, „Intrare - 208”, „Intrare - 209tub6m”, „Intrare - 210tub10m”, „Intrare - 211descandent”, „Intrare - 212intraresapata”, „Intrare - 213 mare”, „Intrare - 214pdincarpeni1”, „Intrare - abrimare207”, „Intrare - Avenul Guguiova”
- Intrare principală — Main entrance (subtitlu de rând)

</details>

**Descris în:** [Harta peșterilor](../features/surface-map.md)

---

<a id="cave-map-measure-distance"></a>

## Măsurarea unei distanțe pe hartă

![Măsurarea unei distanțe pe hartă](../../images/cave-map-measure-distance.jpg)

*Modul de măsurare: un traseu din mai multe segmente pe hartă, cu distanța totală și azimutul.*

Modul Măsoară distanța pe harta de suprafață, pornit din butonul cu riglă din
bara de instrumente. Fiecare apăsare pe hartă sau pe un marcaj (care fixează
punctul exact al locului) adaugă un vârf la traseul portocaliu punctat. Bara
de jos arată Total-ul curent, aici 2.75 km, precum și lungimea și azimutul
pentru Ultimul segment, 449 m la 266 de grade, cu Șterge ultimul punct și
Închide alături. Vederea este depărtată dincolo de pragul de grupare, așa că
locurile apropiate se strâng în baloane albastre cu număr, care, apăsate,
măresc exact pe membrii lor, iar doar marcajele negrupate își păstrează
etichetele.

<details><summary>Textul de pe ecran (română → engleză)</summary>

- Măsoară distanța — Measure distance (riglă, activ)
- Arată locurile care nu sunt intrări — Show non-entrance places (activ, plin)
- Ascunde locurile din alte peșteri — Hide places from other caves (glob, activ)
- Total: 2.75 km — Total (map_measure_total)
- Ultimul segment: 449 m · 266° — Last leg (map_measure_leg)
- Șterge ultimul punct — Remove last point (săgeată de anulare)
- Închide — Close (X)
- Baloane albastre de grupare cu numărul: 3, 3, 5, 5, 5, 2
- Marcaje de intrare etichetate: „Peștera D3 din Piatra Lupului - Intrare…”, „Peștera G1 din Piatra Lupului - Intrare 2”, „Avenul Guguiova”

</details>

**Descris în:** [Harta peșterilor](../features/surface-map.md)

---

<a id="cave-map-add-point-menu"></a>

## Adăugarea unei peșteri sau a unei intrări de pe hartă

![Adăugarea unei peșteri sau a unei intrări de pe hartă](../../images/cave-map-add-point-menu.jpg)

*Meniul Adaugă punct, care oferă Peșteră nouă sau Intrare nouă în locul ales.*

Apăsarea butonului Adaugă punct din bara de instrumente a hărții de suprafață
(sau apăsarea lungă pe hartă) deschide un panou de jos care întreabă ce fel de
punct se plasează. Peșteră nouă creează o peșteră întreagă, împreună cu prima
ei intrare, în acea poziție, iar Intrare nouă adaugă încă o intrare la o
peșteră care există deja, cerând întâi peștera și apoi numele intrării.
Alegerea oricăreia dintre opțiuni pornește fluxul de plasare, în care pinul
poate fi în continuare tras, mutat printr-o apăsare în alt punct sau mediat
dintr-o fixare GPS înainte de a fi confirmat. Harta rămâne vizibilă și
estompată în spatele panoului, ca să se vadă unde va cădea punctul.

<details><summary>Textul de pe ecran (română → engleză)</summary>

- Peșteră nouă — New cave (opțiune din panoul de jos, pictogramă cu pin de adăugare a locației)
- Creează o peșteră cu o intrare în acest punct — Create a cave with an entrance at this point (subtitlu)
- Intrare nouă — New entrance (opțiune din panoul de jos, pictogramă cu ușă)
- Adaugă o intrare la o peșteră existentă în acest punct — Add an entrance to an existing cave at this point (subtitlu)
- Adaugă punct — Add point (butonul din bara de instrumente care a deschis acest panou)
- Ascunde locurile din alte peșteri — Hide places from other caves (comutator glob, în continuare activ)
- Ascunde locurile care nu sunt intrări — Hide non-entrance places (comutator cu puncte, în continuare activ)
- Harta estompată în spatele panoului, cu intrările etichetate și cu balonul de grupare „2”

</details>

**Descris în:** [Harta peșterilor](../features/surface-map.md) · [Peșteri și zone de peșteră](../features/caves-and-areas.md)

---

<a id="cave-map-new-cave-placement"></a>

## Plasarea punctului pentru o peșteră nouă

![Plasarea punctului pentru o peșteră nouă](../../images/cave-map-new-cave-placement.jpg)

*Plasarea punctului de intrare pentru o peșteră nouă pe harta de suprafață.*

După alegerea opțiunii „Peșteră nouă” din meniul de adăugare a punctului,
harta de suprafață intră în modul de plasare și arată jos bara de plasare,
intitulată „Peșteră nouă”. Indicația „Atinge harta, ține apăsat sau folosește
locația ta” explică cele trei feluri în care se stabilește punctul; butonul
„Folosește locația mea” pornește o captură GPS mediată, a cărei medie curentă
trage pinul pe măsură ce sosesc fixările, iar „Anulează” abandonează plasarea.
Odată ce punctul este stabilit, bara înlocuiește indicația cu coordonatele
formatate și activează butonul Confirmă. Cât timp rulează o plasare, bara de
instrumente renunță la butoanele Măsoară distanța și Adaugă punct, motiv
pentru care aici este mai scurtă decât pe harta obișnuită.

<details><summary>Textul de pe ecran (română → engleză)</summary>

- Peșteră nouă — New cave (titlul barei de plasare)
- Atinge harta, ține apăsat sau folosește locația ta — Tap the map, long-press, or use your location
- Folosește locația mea — Use my location (buton conturat)
- Anulează — Cancel (buton text)
- Bara de instrumente: Înapoi — Back
- Bara de instrumente: Locația mea — My location
- Bara de instrumente: Straturi hartă — Map layers
- Bara de instrumente: Ascunde locurile din alte peșteri — Hide places from other caves (comutator glob, activ)
- Bara de instrumente: Ascunde locurile care nu sunt intrări — Hide non-entrance places
- Bara de instrumente: Toate locurile din peșteri — All cave places
- Bara de instrumente: Intrări — Entrances
- Etichete pe hartă: Peștera D3 din Piatra Lupului - Intrare…, Peștera G1 din Piatra Lupului - Intrare 2, Avenul Guguiova

</details>

**Descris în:** [Harta peșterilor](../features/surface-map.md) · [Documentarea unei peșteri noi](../workflows/documenting-a-new-cave.md)

---

[← Înapoi la galeria de capturi](README.md)
