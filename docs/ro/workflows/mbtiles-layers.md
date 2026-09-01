# Folosirea straturilor MBTiles offline pe harta peșterilor

[← Înapoi la cuprins](../README.md)

Cum să puneți propria hartă offline peste harta peșterilor — o planșă
topografică scanată sau o zonă exportată din MOBAC, QGIS ori SAS Planet —
astfel încât harta să se deseneze și în subteran, într-o vale fără semnal
sau în străinătate cu datele mobile oprite.

Etichetele folosite mai jos sunt cele în limba română. Aplicația pornește
în română; limba se schimbă din **Setări → General → Limba aplicației**.

## Înainte de a începe

Funcționează doar fișierele `.mbtiles` **raster** (plăci PNG, JPEG sau
WebP). Un fișier **vectorial** (`pbf`) nu este refuzat la import, dar nu
poate fi desenat: ajunge listat cu o pictogramă roșie și mențiunea *MBTiles
vectorial nesuportat*, fără rol de ales și fără intrare în selectorul de
straturi al hărții. Când exportați din MOBAC, QGIS sau SAS Planet, alegeți
ieșirea raster / imagini în plăci.

Dimensiunea contează mai mult decât v-ar plăcea: odată importat, un fișier
nu mai poate fi șters din aplicație (vedeți *Înlocuirea și ștergerea
fișierelor* mai jos), așa că restrângeți exportul la zona pe care chiar o
străbateți înainte de a-l copia.

## Adăugarea unui fișier MBTiles

1. **Produceți un fișier `.mbtiles` raster** pe calculator, care să acopere
   zona de care aveți nevoie și doar nivelurile de zoom de care aveți
   nevoie.

2. **Importați-l din aplicație.** Deschideți **Setări → Hartă** și apăsați
   **Importă fișier MBTiles** (rândul sau butonul de încărcare din bara de
   aplicație), apoi navigați până la fișier. Este verificat și copiat
   pentru dumneavoastră în folderul propriu al aplicației.

   Selectorul oferă intenționat *orice* tip de fișier, pentru că selectorul
   de fișiere din Android nu recunoaște `.mbtiles` — deci alegeți cu
   atenție. Un fișier al cărui nume nu se termină în `.mbtiles` este
   refuzat cu *Te rog alege un fișier .mbtiles*, iar un fișier care nu este
   o bază de date MBTiles lizibilă este refuzat cu *Acel fișier nu este o
   bază de date MBTiles care poate fi citită*; niciunul nu ajunge în
   folder. Dacă un fișier cu acel nume este deja acolo, **Fișierul există
   deja** întreabă înainte de a suprascrie. La reușită primiți *S-a importat
   <nume>* — sau, pentru un fișier vectorial, *S-a importat <nume>, dar
   MBTiles vectorial nu este suportat pe hartă*.

   Această cale nu cere nicio permisiune de stocare și funcționează pe
   instalările de debug sau sideload, unde folderul aplicației nu este
   deloc accesibil dintr-un manager de fișiere. Pe telefon este singura
   cale practică.

3. **Sau copiați dumneavoastră fișierul** (manager de fișiere, cablu USB,
   `adb push`). **Setări → Hartă → Folder MBTiles** arată calea exactă, cu
   un buton **Copiază calea** alături — ea diferă de la o platformă și de
   la un dispozitiv la altul. Pe Android și iOS acel folder este stocare
   privată a aplicației, de obicei accesibilă doar cu adb sau pe un
   dispozitiv rootat.

4. **Verificați-l în listă și dați-i un rol.** Fișierele apar la **Fișiere
   detectate**, fiecare arătându-și numele, apoi numele fișierului,
   formatul plăcilor și intervalul de zoom stocat în fișier (de exemplu
   *z8–16*).

   - După un import din aplicație, lista s-a reîmprospătat deja singură.
   - După o copiere manuală, apăsați **Rescanează folderul** (butonul de
     reîmprospătare din bara de aplicație) sau ieșiți și redeschideți
     pagina.

   Apoi stabiliți rolul fișierului din lista derulantă de pe rândul lui —
   **Suprapunere** sau **Hartă de bază**, descrise în secțiunea următoare.
   Fișierele noi pornesc ca **Suprapunere**.

5. **Activați-l din hartă.** Deschideți harta peșterilor, apăsați
   **Straturi hartă** în bara de instrumente de sus și fișierul este acolo:
   fișierele **Hartă de bază** ca intrări suplimentare în lista **Strat de
   bază**, fișierele **Suprapunere** ca bife la **Suprapuneri**. Apăsați-l
   sau bifați-l și panoul actualizează harta imediat. Alegerea se reține,
   așa că data viitoare harta revine cu aceleași straturi.

   Fiecare fișier este listat cu numele stocat *în interiorul* lui, cu
   numele fișierului dedesubt — exporturile MOBAC și QGIS poartă frecvent
   un nume intern care nu are nicio legătură cu numele fișierului, așa că
   citiți al doilea rând dacă nu vă găsiți fișierul.

## Hartă de bază sau suprapunere

| Rol | Ce face |
|---|---|
| **Suprapunere** | Se desenează peste stratul de bază selectat, ca o casetă de bifat la **Suprapuneri**. Este varianta implicită și alegerea potrivită pentru o hartă mică, locală sau de zonă a peșterii: în afara acoperirii ei se vede pur și simplu stratul de bază de dedesubt. |
| **Hartă de bază** | Se poate alege în lista **Strat de bază** în locul surselor online. Toată harta este acel fișier, deci în afara acoperirii lui primiți plăci goale — potrivit pentru o planșă offline completă, nepotrivit pentru un petic mic. |

Pot fi active mai multe suprapuneri deodată. Se stivuiesc în ordinea
alfabetică a numelui afișat în selector și nimic nu se desenează
semitransparent, așa că o suprapunere opacă ascunde tot ce se află sub ea —
inclusiv o altă suprapunere al cărei nume vine mai devreme în ordine.

## Înlocuirea și ștergerea fișierelor

- **Nu există ștergere.** Rândul unui fișier oferă doar lista derulantă
  Hartă de bază / Suprapunere; nimic din aplicație nu elimină un fișier
  importat, iar pe Android și iOS folderul este privat aplicației, deci
  niciun manager de fișiere nu ajunge la el. Scoaterea de pe dispozitiv a
  unei greșeli de 2 GB înseamnă în general adb sau un telefon rootat.
  Importați cu grijă.
- **Pentru a înlocui un fișier** cu un export mai nou, importați-l cu
  același nume de fișier și acceptați întrebarea **Suprascrie**. Rolurile
  se rețin după numele fișierului, așa că înlocuitorul păstrează rolul pe
  care i l-ați dat celui vechi.
- **Încărcare automată MBTiles** din **Setări → Hartă** este comutatorul
  principal: dezactivați-l și harta nu mai scanează folderul, deci niciun
  strat MBTiles nu mai apare în selectorul de straturi. Este totul sau
  nimic, nu o metodă de a ascunde un singur fișier. Lista **Fișiere
  detectate** arată fișierele în continuare cât timp este dezactivat.

## Când ceva pare în neregulă

- **Linia de atribuire din stânga jos numește stratul care este desenat
  efectiv** — atribuirea furnizorului online sau numele fișierului
  dumneavoastră, când acesta ține loc de hartă de bază. Aruncați-i o
  privire: dacă o hartă de bază MBTiles se dovedește coruptă sau imposibil
  de citit, harta revine la **OpenTopoMap**, stratul de bază implicit, fără
  nicio eroare, iar acea linie este singurul semn. Un fișier care încă se
  deschide își arată propriul nume peste plăci goale o clipă, până apar
  primele plăci.
- **Fișierul nu apare deloc în listă.** Numele lui trebuie să se termine în
  `.mbtiles` — orice altceva din folder este ignorat — iar un fișier corupt
  este sărit în tăcere la rescanare, în loc să fie listat.
- **Hartă goală după schimbarea stratului de bază.** Sunteți în afara
  acoperirii acelui fișier. Reveniți la un strat de bază online sau dați-i
  fișierului rolul **Suprapunere**.
- **Mărirea dincolo de zoomul până la care merge fișierul** nu duce la
  ecran gol: ultimele plăci disponibile sunt scalate în sus, așa că devin
  neclare în loc să dispară.
- **Cache-ul de hartă este altceva.** **Cache-ul de hartă** din **Setări →
  Hartă** păstrează plăcile *online* descărcate și poate fi golit cu
  pictograma de coș; asta nu atinge niciodată fișierele dumneavoastră
  MBTiles.

## Vezi și

- [Harta peșterilor](../features/surface-map.md)
- [Setări](../features/settings.md)
- [GPS și coordonate](../features/gps-and-coordinates.md)
- [Hărți](../features/raster-maps.md)
- [Flux de lucru: Navigarea în subteran cu coduri QR](navigating-underground.md)
- [Capturi de ecran: Setări](../screenshots/07-settings.md)
