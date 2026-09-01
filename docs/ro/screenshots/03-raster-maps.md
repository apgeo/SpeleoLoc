# Hărți raster și amplasarea punctelor

[← Cuprinsul capturilor de ecran](README.md) · [← Cuprinsul wiki-ului](../README.md)

Hărți de peșteră scanate și editorul care fixează locurile din peșteră pe ele.

> Aplicația rulează implicit în **română**, așa că în capturile de ecran apar etichetele în limba română. Fiecare intrare indică formularea de pe ecran alături de echivalentul ei în engleză.

**Pe această pagină:** [Hărțile unei peșteri](#cave-raster-maps-list) · [Selectorul de locuri pe harta raster](#raster-map-place-selector) · [Definirea unui punct pe o hartă raster](#raster-map-define-point) · [O hartă raster în vizualizatorul pe ecran complet](#raster-map-full-screen)

---

<a id="cave-raster-maps-list"></a>

## Hărțile unei peșteri

![Hărțile unei peșteri](../../images/cave-raster-maps-list.jpg)

*Lista Hărți a unei peșteri, cu acțiunile de editare și ștergere pentru fiecare hartă.*

Acest ecran listează fiecare hartă raster înregistrată pentru peștera curentă,
fiecare rând arătând o miniatură a imaginii hărții și titlul ei. Apăsarea unui
rând deschide harta pe tot ecranul; creionul deschide Editează harta, iar coșul
rulează Șterge harta, care avertizează mai întâi atunci când pe acea hartă
există definiții de puncte. Bara de sus poartă Adaugă hartă, iar butonul de
sortare din banda de sub ea comută lista în modul Reordonare hărți, astfel
încât intrările să poată fi trase în ordinea folosită în restul aplicației.

<details><summary>Textul de pe ecran (română → engleză)</summary>

- Hărți — Raster maps (titlul barei de sus)
- Adaugă hartă — Add raster map (pictograma + din bara de sus)
- Reordonare hărți — Reorder maps (pictograma de sortare din banda de instrumente)
- Editează harta — Edit raster map (pictograma creion de pe fiecare rând)
- Șterge harta — Delete raster map (pictograma coș de pe fiecare rând)
- Rânduri de hărți cu miniatură și titlu: 2019, 2025 3d, 2025, 1986, plan 3D, 2017, 2018, profil 545, 1988 G. Popescu, 2025 815 p, terminus

</details>

**Descris în:** [Hărți raster](../features/raster-maps.md)

---

<a id="raster-map-place-selector"></a>

## Selectorul de locuri pe harta raster

![Selectorul de locuri pe harta raster](../../images/raster-map-place-selector.jpg)

*Amplasarea locurilor din peșteră pe o hartă raster, cu barele de navigare pentru hărți și locuri.*

Selectorul de locuri pe harta raster arată o singură hartă raster pe tot
ecranul, cu fiecare loc din peșteră care are o definiție de punct desenat pe
ea ca un pin roșu cu etichetă. Bara de sus numește harta selectată, iar sub ea
apare locul din peșteră selectat; cele două benzi de deasupra imaginii sunt
rândul de miniaturi Afișează lista hărților și rândul de etichete de locuri
Afișează lista locurilor, oricare dintre ele schimbând vederea fără a părăsi
ecranul. Bara de jos ține Comutare legendă, comutatorul modului de atingere
(Mod atingere: Definește punct nou), Resetează punctul la poziția inițială,
Elimină definiția punctului, Adăugare loc peșteră, Deschide locul și Documente.
Săgeata de pe marginea din stânga scoate la iveală bara de instrumente
laterală, iar controalele plutitoare din dreapta jos resetează și măresc
imaginea.

<details><summary>Textul de pe ecran (română → engleză)</summary>

- 2025 3d — titlul hărții raster selectate (bara de sus)
- Canionul Alb — titlul locului din peșteră selectat (subtitlul barei de sus)
- Comutare navigare compactă — Toggle compact navigation (pictogramă din bara de sus)
- Afișează lista hărților — Show maps list (banda de miniaturi: 2019, 2025 3d, 2025, 1986, plan 3D)
- Afișează lista locurilor — Show cave places list (etichete: put, Intrare, Turnul de Cleștar, Meandrul E.G. 2019, Urechile Acului 2)
- Comutare legendă — Toggle legend (pictograma info, bara de jos)
- Mod atingere: Definește punct nou — Tap mode: Define new point (pictograma pin albastru, bara de jos)
- Resetează punctul la poziția inițială — Reset point to initial position (pictograma de anulare)
- Elimină definiția punctului — Remove point definition (pictograma coș roșu)
- Adăugare loc peșteră — Quick add cave place (pictograma de adăugare a unui loc)
- Deschide locul — Open cave place (pictograma de deschidere într-o fereastră nouă)
- Documente — Documents (pictograma de document)
- Afișează bara de instrumente — Show toolbar (săgeata de pe marginea din stânga a hărții)

</details>

**Descris în:** [Vizualizatorul de hărți](../features/map-viewer.md) · [Hărți raster](../features/raster-maps.md)

---

<a id="raster-map-define-point"></a>

## Definirea unui punct pe o hartă raster

![Definirea unui punct pe o hartă raster](../../images/raster-map-define-point.jpg)

*Amplasarea locurilor din peșteră pe o ridicare topografică scanată, cu editorul de puncte al hărții raster.*

Acesta este selectorul de locuri pe harta raster, unde o ridicare topografică
scanată este folosită pentru a da locurilor din peșteră poziția lor pe hartă.
Bara de navigare de sus ține o bandă cu hărțile raster ale peșterii și, sub ea,
o bandă cu locurile din peșteră (cel selectat, p3, este repetat sub titlul
barei de sus); apăsarea unui loc îl face să fie cel poziționat. Indiciul
plutitor spune „Apăsați pe hartă pentru a defini un punct nou sau schimbați
modul de interacțiune”, iar bara de acțiuni de jos poartă Comutare legendă,
comutatorul modului de atingere (acum Mod atingere: Definește punct nou),
Resetează punctul la poziția inițială, Elimină definiția punctului, Adăugare
loc peșteră, Deschide locul și Documente. Bara de instrumente pliabilă din
stânga adaugă Următorul loc fără coordonate, Filtrare locuri peșteră,
Vizualizare bară navigație, Mai multe acțiuni, ecran complet, Inversare culori
și Procesare imagine, peste o scară de culori a adâncimii.

<details><summary>Textul de pe ecran (română → engleză)</summary>

- Apăsați pe hartă pentru a defini un punct nou sau schimbați modul de interacțiune — Click on the map to define a new point or change the interaction mode
- Titlul barei de sus = numele fișierului hărții raster, subtitlul = locul din peșteră selectat (p3)
- Banda de miniaturi ale hărților raster (ps_202501…, ps_profil_pr…, geo_art_tirl…, ps_plan_1_…, cerna_ps_p…)
- Etichete de locuri din peșteră: p2 diaclaza exp, ? g perete, p4 horn, p3 (selectat), C1 baza
- Pictograma info din bara de jos — Comutare legendă — Toggle legend
- Pictograma pin albastru din bara de jos — Mod atingere: Definește punct nou — Tap mode: Define new point
- Pictograma de anulare din bara de jos — Resetează punctul la poziția inițială — Reset point to initial position
- Pictograma coș roșu din bara de jos — Elimină definiția punctului — Remove point definition
- Pictograma de adăugare a unui pin din bara de jos — Adăugare loc peșteră — Quick add cave place
- Pictograma de deschidere într-o fereastră nouă din bara de jos — Deschide locul — Open cave place
- Pictograma de document din bara de jos — Documente — Documents
- Pictograma țintă din bara de instrumente din stânga — Următorul loc fără coordonate — Next place without location
- Pictograma de căutare din bara de instrumente din stânga — Filtrare locuri peșteră — Filter cave places
- Pictograma de straturi din bara de instrumente din stânga — Vizualizare bară navigație — Nav bar views
- ⋮ din bara de instrumente din stânga — Mai multe acțiuni — More actions
- Săgeata din bara de instrumente din stânga — Ascunde bara de instrumente — Hide toolbar, plus comutatorul de ecran complet
- Pictograma de contrast din bara de instrumente din stânga — Inversare culori — Invert colors; pictograma cu cursoare — Procesare imagine — Image processing
- Butoanele de micșorare / resetare a vederii / mărire și scara de culori a adâncimii de pe hartă
- Pini roșii cu etichetele locurilor din peșteră suprapuși peste desenul ridicării

</details>

**Descris în:** [Vizualizatorul de hărți](../features/map-viewer.md) · [Hărți raster](../features/raster-maps.md)

---

<a id="raster-map-full-screen"></a>

## O hartă raster în vizualizatorul pe ecran complet

![O hartă raster în vizualizatorul pe ecran complet](../../images/raster-map-full-screen.jpg)

*O hartă raster de peșteră deschisă pe ecran complet pentru inspecție prin pinch-zoom.*

Apăsarea unei hărți raster din lista de hărți a unei peșteri (sau a miniaturii
de previzualizare din formularul hărții) deschide imaginea pe tot ecranul, pe
fundal negru, cu titlul hărții în bara de sus și un buton de închidere pentru a
reveni. Imaginea în sine este o vizualizare foto cu mărire prin ciupire și
deplasare prin tragere, așa că o planșă de ridicare scanată rămâne lizibilă la
orice nivel de mărire. Aici harta încărcată este un profil de adâncime colorat
al Avenului din Grind, cu legenda lui de altitudine, indicatorul de nord și
scara grafică de 25 m. Din această vedere nu se poate edita nimic; amplasarea
punctelor se face în schimb în vizualizatorul de hărți.

<details><summary>Textul de pe ecran (română → engleză)</summary>

- Titlul barei de sus arată titlul propriu al hărții raster — aici numele generat automat „raster_1779450715618”
- Butonul de închidere (X), stânga sus — părăsește ecranul complet
- Zona de imagine cu mărire prin ciupire / deplasare, pe fundal negru
- Conținutul desenului ridicării (nu interfața aplicației): „Avenul din Grind (Gaura din Funduri)”, „Munții Piatra Craiului” — numele peșterii și al masivului, tipărite pe scanare
- „profil S > N” — direcția profilului ridicării, tipărită pe scanare
- „Denivelare: 125 m” — diferența de nivel; „Altitudine: ~ 1680 m” — altitudinea, ambele tipărite pe scanare
- Legenda de culori a altitudinii și scara grafică de 25 m desenate pe scanare

</details>

**Descris în:** [Hărți raster](../features/raster-maps.md) · [Vizualizatorul de hărți](../features/map-viewer.md)

---

[← Înapoi la cuprins](README.md)
