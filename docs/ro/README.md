# SpeleoLoc — Wiki pentru utilizatori

Bine ați venit în documentația pentru utilizatori a aplicației **SpeleoLoc**, o
aplicație mobilă pentru speologi care ajută la:

- **Poziționare în subteran** — aflarea locului în care vă aflați pe harta
  peșterii, prin scanarea etichetelor QR amplasate fizic în punctele de
  interes sau prin detectarea unui beacon BLE montat acolo.
- **Documentarea peșterii** — atașarea de fotografii, înregistrări audio, note
  text, schițe și alte fișiere la acele puncte de interes.
- **Poziționare la suprafață** — marcarea fiecărei intrări de peșteră
  cunoscute pe o hartă geografică ce funcționează offline.
- **Înregistrarea turelor și rapoarte** — înregistrarea traseului și a
  evenimentelor unei ture și generarea ulterioară a unui raport de tură.
- **Partajarea datelor** între echipe prin arhive exportabile sau
  sincronizare FTP/SFTP.

Începeți cu [Prezentare generală](overview.md) dacă sunteți la început;
treceți direct la [referința funcțiilor](features/) dacă căutați o anumită
funcție; deschideți [galeria de capturi de ecran](screenshots/README.md) dacă
preferați să vedeți aplicația în loc să citiți despre ea.

> 🇬🇧 **Această documentație este disponibilă și în engleză:**
> [Documentația în engleză](../README.md).

---

## Cuprins

### Începeți aici

1. [Prezentare generală — ce face SpeleoLoc și de ce](overview.md)
2. [Primii pași — prima pornire](getting-started.md)
3. [Glosar de termeni](glossary.md)
4. [Galerie de capturi de ecran — aplicația, ecran cu ecran](screenshots/README.md)

### Fluxuri de lucru (pe activități)

- [Documentarea unei peșteri noi](workflows/documenting-a-new-cave.md)
- [Navigarea în subteran](workflows/navigating-underground.md)
- [Desfășurarea unei ture](workflows/running-a-trip.md)
- [Partajarea datelor între echipe](workflows/sharing-data.md)
- [Folosirea straturilor MBTiles offline](workflows/mbtiles-layers.md)

### Referința funcțiilor (ecran cu ecran)

**Organizarea datelor**

- [Pagina principală](features/home-screen.md)
- [Peșteri și zone peșteră](features/caves-and-areas.md)
- [Locuri din peșteră](features/cave-places.md)
- [Arii de suprafață](features/surface-areas.md)
- [Filtrare, sortare și selecție](features/lists-filter-sort-select.md)

**Orientarea**

- [Harta peșterii](features/surface-map.md)
- [Hărți](features/raster-maps.md)
- [Vizualizatorul de hărți și editorul de puncte](features/map-viewer.md)
- [GPS și coordonate](features/gps-and-coordinates.md)

**Identificarea locurilor**

- [Identificatori cod loc (PCI) și identificatori coduri QR (QCRI)](features/place-code-identifiers.md)
- [Coduri QR — amplasare, scanare, tipărire](features/qr-codes.md)
- [Beaconuri BLE](features/ble-beacons.md)
- [Taguri senzor Ruuvi](features/ruuvi-sensors.md)
- [Linkuri directe (`sp://`)](features/deep-links.md)

**Înregistrarea a ceea ce găsiți**

- [Documente (fotografii, audio, text, text formatat, linkuri)](features/documents.md)
- [Ture — înregistrarea traseului](features/trips.md)
- [Rapoarte de tură și șabloane](features/trip-reports.md)

**Mutarea datelor**

- [Panoul de sincronizare și Istoric modificări](features/sync-and-change-log.md)
- [Sincronizare FTP / SFTP](features/ftp-sync.md)
- [Sincronizare Server de club (SilexGIS)](features/silexgis-sync.md)
- [Export, import și copie de siguranță a bazei de date](features/database-export-import.md)
- [Import CSV](features/csv-import.md)
- [Transfer de locuri GPX/KML](features/place-transfer.md)

**Configurare**

- [Setări](features/settings.md)
- [Utilizatori](features/users.md)

### Meta

- [Lucrul cu o arhivă de test locală](../workflows/local-test-archive.md)

---

## Despre capturile de ecran

Limba implicită a aplicației SpeleoLoc este **româna**, iar aplicația a fost
fotografiată așa cum este livrată — de aceea capturile de ecran arată
etichetele în română, în timp ce aceste pagini le folosesc pe cele în engleză.
Engleza se alege din **Setări → General → Limba aplicației**. Fiecare intrare
din [galeria de capturi de ecran](screenshots/README.md) scrie formularea
românească de pe ecran alături de echivalentul ei în engleză.

## Status

SpeleoLoc este în stadiul **alpha**. Unele funcții sunt implementate parțial
sau se pot schimba; acolo unde este cazul, pagina o spune. Consultați
fișierul [README](../../README.md) al proiectului pentru starea lansărilor.

Acest wiki este în lucru și nu este întotdeauna la zi cu aplicația.
Convențiile pe care le respectă — structura paginilor, felul în care sunt alese
numele comenzilor și felul în care cele două ediții lingvistice sunt ținute la
unison — sunt descrise în ghidul de contribuție al întreținătorilor, care nu
face încă parte din depozitul public.
