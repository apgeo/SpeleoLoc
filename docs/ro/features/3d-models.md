# Modele 3D de topografie

[← Înapoi la cuprins](../README.md)

Topografia unei peșteri, așa cum o compilează Therion sau Survex, poate fi
atașată peșterii și privită în 3D pe telefon: rotită, mărită, văzută în plan
sau din orice parte. Punctele peșterii marcate pe hărți pot fi puse și pe
model, ca să vedeți unde sunt în topografie și să treceți de la unul la
altul.

Vizualizatorul funcționează pe Android și iOS și citește două formate:

| Fișier | Scris de | Ce arată |
|---|---|---|
| `.lox` | Therion (`export model`) | Poligonale, stații, vizări laterale, pereți (LRUD și scrapuri), suprafața dacă a fost exportată |
| `.3d` | Survex sau Therion (`export model -fmt survex`) | Poligonale, stații, vizări laterale, pereți din LRUD |

## Atașarea unui model

Deschideți documentele peșterii (butonul dosar din lista de puncte) și
adăugați fișierul ca pe orice document. Apare la **Modele 3D de
topografie**; atingerea lui deschide vizualizatorul. O peșteră poate avea
mai multe modele.

Se deschide primul modelul ales ca implicit (**⋮ → Fă-l modelul implicit
al peșterii**), altfel cel pe care SilexGIS îl marchează drept modelul
curent al peșterii, altfel cel mai nou. Meniul **⋮** le arată pe celelalte.

## Cu SilexGIS

Cu SilexGIS conectat, modelele clubului pentru o peșteră vin la
sincronizare — doar pentru peșterile pe care contul le poate vedea exact,
fiindcă un model poartă poziția peșterii. Cu **Setări → Modele 3D →
Descarcă automat modelele din SilexGIS** pornit (implicit), sincronizarea le descarcă,
dar numai pe o rețea pe care profilul serverului permite fișiere. Altfel
așteaptă: meniul **⋮** al vizualizatorului și butonul 3D al unei peșteri
fără model pe telefon arată modelele rămase pe SilexGIS, iar o atingere
descarcă unul.

Dacă vizualizarea 3D nu se poate deschide (un telefon fără suport 3D sau o
pagină care nu apare în aproximativ 90 de secunde), ecranul spune asta și
oferă **Reîncearcă** și **Înapoi**, în loc de un cerc de încărcare fără sfârșit.

Punctele puse la stațiile unui model pleacă spre SilexGIS și ajung la
celelalte telefoane ale clubului. Dacă SilexGIS are deja punctul la altă
stație a aceluiași model, sincronizarea îl păstrează pe al dumneavoastră și
vă întreabă pe pagina de decizii SilexGIS. Când SilexGIS nu mai oferă un
model, acesta pleacă de pe telefon împreună cu punctele puse pe el.

Un model atașat pe telefon pleacă spre SilexGIS ca date topografice; devine
unul dintre modelele clubului doar când cineva îl face model în browser.

## Privitul

- Un deget rotește modelul, două măresc și deplasează.
- Bara de peste model: stații, nume de stații, plan, colorare. Pe ecran
  lat are și pereții, scrapurile, intrările și cele patru profile; pe
  telefon ținut vertical profilele sunt sub butonul busolă din bara de sus.
- **⋮ → Caută o stație** caută stațiile după nume.
- Atingeți o stație: apare numele și poziția ei, cu **Centrează aici**.

## Punctele peșterii pe model

Fiecare punct poate fi asociat cu o stație — sau cu capătul uneia din
vizările ei laterale — **pentru fiecare model**: un model nou începe fără
asocieri.

Trei moduri de asociere:

1. **Din model.** Atingeți o stație, apoi **Asociază un punct aici** și
   alegeți punctul. **Asociază un capăt de vizare laterală** arată întâi
   vizările stației ca puncte galbene: atingeți-o pe cea dorită.
2. **Din punct.** Pe pagina punctului, sau pe hartă cu punctul selectat,
   atingeți **Vezi în 3D**. Dacă punctul nu e încă asociat, vizualizatorul
   vă cere să atingeți stația lui.
3. **Mai multe deodată.** În lista punctelor asociate, **Asociază cele N
   puncte neasociate** le ia pe rând.

O stație fără punct poate primi unul: **Punct nou aici** îl creează, cu
numele stației, și îl asociază; dacă intrarea peșterii e asociată,
adâncimea se completează din model.

Punctele asociate apar ca marcaje portocalii cu nume; din **Setări →
Modele 3D** pot fi colorate după zona peșterii. Asocierile cu capete de
vizări laterale sunt marcate „de revizuit”.

## Navigarea

- **Lista** punctelor asociate: atingerea zboară camera la punct; butoanele
  deschid punctul pe hartă sau pagina lui.
- **Din punct**, **Vezi în 3D** deschide modelul care îl conține, mărit pe
  stația lui.
- **Atingerea unui marcaj** arată punctele de acolo: deschidere, hartă,
  distanța pe topografie până la alt punct, scoaterea asocierii.
- **Ești aici.** După scanarea codului QR al unui punct sau detectarea unui
  beacon, punctul e marcat timp de o jumătate de oră.
- **Fotografii.** Fotografiile unui punct asociat apar la stația lui.
- **Redarea unei ture.** Pe pagina turei, butonul de redare desenează
  traseul pe topografie prin punctele asociate, cu cursor și redare.

## Oprirea

**Setări → Modele 3D → Puncte pe modelul 3D** oprit ascunde asocierile,
marcajele și lista; asocierile se păstrează.
