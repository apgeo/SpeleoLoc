# Prezentare generală

[← Înapoi la cuprins](README.md)

La ce folosește SpeleoLoc, cele câteva concepte pe care se sprijină tot
restul și — la fel de util — ce anume nu își propune să facă.

## Problema pe care o rezolvă SpeleoLoc

Peșterile sunt greu de parcurs. GPS-ul nu funcționează în subteran, iar
hărțile pe hârtie sunt incomode în noroi, în apă și în galerii strâmte.
Echipele care explorează aceeași peșteră ani la rând adună notițe, schițe,
fotografii și coordonate în formate răzlețe, așa că devine greu de găsit
ce notițe țin de ce galerie data următoare când intră o echipă.

SpeleoLoc rezolvă asta printr-o idee simplă:

> **Puneți un marcaj fizic la fiecare punct de interes din peșteră și
> legați de acel marcaj tot ce știm despre locul respectiv.**

După ce marcajele sunt montate, orice membru al echipei poate identifica
mai târziu un loc cu ajutorul aplicației și, pe loc:

1. Vede **unde se află** pe hărțile peșterii.
2. Vede **tot ce s-a documentat până atunci** pentru acel loc (fotografii,
   notițe, adâncime, schițe…).
3. **Adaugă observații noi** (fotografii, înregistrări audio, notițe text
   și text formatat) care ajung la toate celelalte echipe odată ce datele
   sunt partajate.

## Cum știe SpeleoLoc unde vă aflați

Există două feluri de marcaj, iar un loc din peșteră le poate purta pe
amândouă.

**Etichete QR.** Tipăriți o etichetă pentru un loc din peșteră, o lipiți
pe rocă și o scanați în subteran cu **Scanează QR**. Eticheta poartă
identificatorul locului, implicit în spatele prefixului `sp://` propriu
aplicației SpeleoLoc, pe care nimic altceva decât SpeleoLoc nu îl rezolvă.
Un club care își ține propriul server poate completa în schimb
**Setări → Generare grafică cod QR → Adresa de destinație pentru
etichetele tipărite**, iar atunci același pătrat se deschide și în
browserul unui telefon obișnuit. Vedeți [Coduri QR](features/qr-codes.md).

**Taguri Bluetooth (BLE).** Puteți înregistra un tag iBeacon sau un tag
senzor Ruuvi pentru un loc din peșteră. Cu **Setări → Detectare beaconuri
→ Detectează beaconurile automat** activat, simpla trecere pe lângă un tag
înregistrat identifică locul: aplicația afișează *Loc detectat*, adaugă un
punct de tură dacă în acea peșteră este o tură pornită și — dacă ați
activat **Deschide locul la detectare** — deschide locul direct, fără
scanare și fără mâini. Vedeți [Beaconuri BLE](features/ble-beacons.md).

Tagurile Ruuvi fac o dublă treabă: aceleași transmisii care identifică un
loc poartă și temperatura, umiditatea, presiunea atmosferică și nivelul
bateriei, pe care aplicația le arată în timp real și le poate descărca din
tag ca istoric de măsurători stocat. Vedeți
[Taguri senzor Ruuvi](features/ruuvi-sensors.md).

La suprafață, locurile din peșteră care au coordonate sunt desenate pe
**Harta peșterilor**, o hartă geografică ce funcționează offline din dale
memorate sau din fișiere `.mbtiles` importate de dumneavoastră. Vedeți
[Harta peșterilor](features/surface-map.md).

## Modelul de bază

SpeleoLoc organizează datele în câteva concepte:

```
Zonă de suprafață (regiune geografică)
└── Peșteră
    ├── Zonă peșteră (o zonă denumită din interiorul peșterii, opțională)
    │   └── Loc din peșteră ← punctul de interes
    │       ├── Documente (fotografii, audio, text, text formatat, linkuri, ...)
    │       ├── O etichetă QR și/sau unul ori mai multe taguri BLE
    │       ├── Coordonate → pinul lui pe harta geografică a peșterilor
    │       └── Definiție/definiții de punct pe hartă/hărți raster
    ├── Hărți raster (vedere plană, profil proiectat, profil extins, ...)
    └── Ture (o sesiune de speologie, cu un traseu prin locurile din peșteră)
```

Două lucruri stau în afara acestui arbore și se aplică tuturor: lista
**Utilizatori**, care marchează cine a făcut fiecare modificare, și
**Istoric modificări**, evidența continuă a fiecărei editări, pe care
sincronizarea o folosește ca să îmbine munca unui dispozitiv cu a altuia.

Vedeți [glosarul](glossary.md) pentru definiții precise ale fiecărui
termen.

## Cele trei lucruri mari pe care le faceți cu SpeleoLoc

1. **Pregătiți peștera** (o dată, apoi treptat):
   - Adăugați peștera în aplicație.
   - Importați una sau mai multe hărți scanate ca **Hărți**.
   - Creați **Locuri din peșteră** pentru fiecare punct de interes,
     tipăriți-le etichetele QR și montați fizic etichetele în peșteră.
   - Acolo unde merită bateriile, înregistrați pe loc și un **tag BLE**,
     ca să se anunțe singur, fără scanare.
   - Fixați fiecare loc din peșteră în poziția lui pe fiecare hartă
     relevantă și dați intrărilor coordonatele lor, ca să apară pe harta
     geografică a peșterilor.
   - Vedeți
     [Documentarea unei peșteri noi](workflows/documenting-a-new-cave.md).

2. **O folosiți în subteran**:
   - Scanați o etichetă QR — sau treceți pe lângă un tag înregistrat — ca
     să știți unde vă aflați și să citiți ce există deja acolo.
   - Înregistrați observații noi (fotografii, înregistrări audio, notițe)
     atașate acelui loc.
   - Opțional, porniți o **tură** care vă înregistrează traseul din punct
     în punct și salvează succesiunea ca rută pe hartă.
   - Vedeți [Orientarea în subteran](workflows/navigating-underground.md)
     și [Desfășurarea unei ture](workflows/running-a-trip.md).

3. **Partajați și raportați după tură**:
   - Îmbinați munca dumneavoastră cu a unui coechipier schimbând manual o
     arhivă de sincronizare sau lăsați aplicația să o facă prin serverul
     **FTP/SFTP** al echipei.
   - Exportați întreaga bază de date împreună cu documentele ca o singură
     arhivă pentru altă echipă sau dați coordonatele ca GPX/KML.
   - Generați un raport de tură tipăribil dintr-un șablon ODT sau DOCX.
   - Vedeți [Partajarea datelor](workflows/sharing-data.md) și
     [Rapoarte de tură](features/trip-reports.md).

## Ce **nu** face SpeleoLoc (încă)

- **Nu vă urmărește între marcaje.** Nu există urmărire inerțială sau prin
  navigație estimată în subteran. SpeleoLoc știe unde vă aflați pentru că
  ați scanat o etichetă QR sau ați trecut pe lângă un tag BLE înregistrat
  de dumneavoastră; într-o galerie fără niciunul, nu vă poate spune unde
  sunteți.
- **Nu ține un serviciu în cloud pentru dumneavoastră.** Sincronizarea
  trece printr-un fișier de arhivă schimbat manual, printr-un server
  FTP/SFTP pus la dispoziție și controlat de echipa dumneavoastră sau prin
  **Server de club (SilexGIS)** ținut de clubul dumneavoastră — niciodată
  printr-un serviciu pe care SpeleoLoc l-ar opera în numele dumneavoastră.
  Vedeți [Sincronizare FTP / SFTP](features/ftp-sync.md).
- **Nu face topografie și nu desenează.** SpeleoLoc consumă hărți
  existente (imagini bitmap); nu le produce și nu are un model 3D al
  peșterii.
- **Nu publică nimic pe web de la sine.** O etichetă tipărită cu prefixul
  implicit `sp://` nu face nimic pe un telefon fără SpeleoLoc, iar orice
  pagină publică pe care o deschide totuși o etichetă este găzduită de
  clubul dumneavoastră, nu oferită de SpeleoLoc.

SpeleoLoc este în **alfa** — unele ecrane încă se schimbă. Acolo unde o
pagină din acest wiki știe că o funcție este parțială, o spune.

## Vezi și

- [Primii pași](getting-started.md) — instalare și prima pornire
- [Glosar](glossary.md) — înțelesul exact al fiecărui termen de mai sus
- [Documentarea unei peșteri noi](workflows/documenting-a-new-cave.md)
- [Orientarea în subteran](workflows/navigating-underground.md)
- [Ecranul principal](features/home-screen.md)
- [Galerie de capturi de ecran](screenshots/README.md)
