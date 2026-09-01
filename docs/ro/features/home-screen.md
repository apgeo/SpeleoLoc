# Pagina principală

[← Înapoi la cuprins](../README.md)

Pagina principală — intitulată **Speleo Loc** — este punctul de intrare al
aplicației. Ea listează fiecare peșteră păstrată pe dispozitiv și adună
acțiunile care se aplică peșterilor în ansamblu: scanare, adăugare, import,
cartare, sincronizare și tipărirea foilor de coduri QR.

> 📷 [Pagina principală și lista ei de peșteri](../screenshots/01-home-and-caves.md#home-cave-list) — Pagina principală listează fiecare peșteră cu numărul ei de locuri și de hărți.

## Bara de sus

Bara de sus ține titlul aplicației în stânga și butonul **⋮** în dreapta. Ce
stă între ele depinde de bara de acțiuni:

- cât timp bara de acțiuni este afișată — situația implicită — bara de sus
  nu mai poartă nimic altceva;
- cât timp bara de acțiuni este ascunsă, trei pictograme urcă în bara de
  sus: **Scanează QR**, **Adaugă peșteră nouă** și **Sincronizare FTP /
  SFTP**.

Apăsarea pe **⋮** deschide meniul aplicației, descris mai jos în această
pagină. Apăsarea repetată pe titlu pornește și oprește **modul depanare**
(debug mode), ascuns — descris tot mai jos.

## Bara de acțiuni

Un rând de butoane-pictogramă stă chiar sub bara de titlu. Este afișat
implicit și ține, de la stânga la dreapta:

| Buton | Ce face |
| --- | --- |
| **Scanează QR** | Deschide scanerul camerei. Vezi [Coduri QR](qr-codes.md). |
| **Adaugă peșteră nouă** | Deschide formularul de peșteră nouă. Vezi [Peșteri și zone de peșteră](caves-and-areas.md). |
| **Documente** | Deschide navigatorul care ține fiecare document din aplicație. Vezi [Documente](documents.md). |
| **Harta peșterilor** | Deschide [harta peșterilor](surface-map.md) pe peșterile vizate în acel moment. |
| **Arii de suprafață** | Deschide lista [ariilor de suprafață](surface-areas.md). |
| **Import peșteri din CSV** | Creează în masă peșteri dintr-un fișier CSV. Vezi [Import CSV](csv-import.md). |
| **Importă documente în peșteri** | Atașează un dosar de fișiere mai multor peșteri deodată. |
| **Setări** | Deschide [Setări](settings.md). |
| **Sinc. man.** | Deschide [panoul de sincronizare](sync-and-change-log.md). |
| **Sincronizare FTP / SFTP** | Pornește pe loc o sincronizare și deschide [pagina de progres](ftp-sync.md). |

Butoanele sunt numai pictograme; țineți apăsat pe unul ca să-i vedeți
numele.

**Sincronizare FTP / SFTP** este singurul buton fără pas de confirmare:
pornește o sincronizare cu profilul dumneavoastră de server implicit din
clipa în care îl apăsați, apoi deschide pagina de progres. Dacă nu este
setat niciun profil implicit sau dacă nu este păstrată nicio parolă pentru
el, rularea eșuează imediat, iar pagina de progres arată eroarea. Dacă o
sincronizare este deja în curs, apăsarea butonului pur și simplu vă duce la
ea.

Importul *locurilor* din peșteră dintr-un CSV nu se oferă aici — deschideți
peștera și folosiți **Import locuri din CSV** din lista ei de locuri.

### Ascunderea și afișarea barei de acțiuni

Butonul **Ascunde bara de acțiuni** de la capătul din dreapta al antetului
listei de peșteri pliază bara; același buton scrie apoi **Afișează bara de
acțiuni** și o aduce înapoi. Comutatorul din **Setări → General → Afișează
bara de acțiuni pe pagina principală** („Afișează butoanele
scanare/adăugare/documente/setări într-o bară pe pagina principală”)
controlează exact același lucru, așa că cele două sunt mereu de acord odată
ce ați folosit oricare dintre ele. La o instalare nouă bara este afișată deși
comutatorul arată încă oprit; pornirea și oprirea lui pune afișarea în pas cu
comutatorul.

Ascunderea barei nu îi mută acțiunile în meniul ⋮ — meniul este același în
ambele cazuri. Reapar numai **Scanează QR**, **Adaugă peșteră nouă** și
**Sincronizare FTP / SFTP**, în bara de sus.

### Scanează QR și tastarea unui cod cu mâna

Apăsarea pe **Scanează QR** deschide scanerul; un cod recunoscut sare drept
la locul căruia îi aparține. Ținerea apăsată a aceluiași buton vreo două
secunde și jumătate deschide în schimb **Căutare manuală cod QR**, unde
puteți tasta în câmpul **Mod de generare identificatori cod QR**
identificatorul tipărit pe etichetă și apăsa **Caută loc după id cod QR**.
Aceasta este calea de intrare când o etichetă este prea deteriorată sau prea
murdară ca să fie scanată. Este mereu disponibilă și nu are nicio setare.

## Lista de peșteri

Fiecare rând arată titlul peșterii, numele ariei ei de suprafață dedesubt
(când are una) și două contoare: o pictogramă de reper cu numărul de
[locuri din peșteră](cave-places.md) și o pictogramă de hartă cu numărul de
[hărți](raster-maps.md). Apăsarea pe un rând deschide lista de locuri a acelei
peșteri.

Lista se ține singură la zi: peșterile adăugate, modificate sau șterse de un
import, de o sincronizare sau de un alt ecran apar imediat, așa că nu aveți
ce trage în jos ca să reîmprospătați.

Rândurile de peșteri nu au acțiuni la apăsare lungă sau la glisare. Ca să
redenumiți o peșteră, deschideți-o și folosiți **⋮ → Editează peștera**; ca
să ștergeți peșteri, folosiți modul de selecție descris mai jos.

### Filtrare și sortare

Antetul listei de peșteri poartă eticheta **Peșteri:** cu un număr, apoi
butoanele **Mod selecție**, **Sortează după**, **Arată filtrul**, **Generează
coduri QR pentru peșteri** și comutatorul barei de acțiuni.

- **Arată filtrul** deschide o casetă deasupra listei. Ce tastați este
  comparat atât cu titlul peșterii, cât și cu numele ariei ei de suprafață,
  așa că numele unei arii este o cale rapidă de a îngusta lista la o singură
  regiune. Cât timp un filtru este activ, numărul se schimbă, de pildă, din
  „(45)” în „(5 /45)”. Închiderea casetei șterge filtrul.
- **Sortează după** oferă **Ultima modificare** (implicit, cele mai noi
  întâi), **Titlu**, **Zonă de suprafață** și **Număr de locuri**, fiecare
  crescător sau descrescător, cu un al doilea câmp opțional. Sortarea după
  Titlu sau după Zonă de suprafață grupează și rândurile sub titluri.
  Alegerea vă este ținută minte pentru data viitoare.

Același antet se poartă la fel pe celelalte liste din aplicație — vezi
[Filtrare, sortare și selecție în liste](lists-filter-sort-select.md).

### Modul de selecție

Apăsarea pe pictograma de listă bifată (**Mod selecție**) pune o casetă de
bifat pe fiecare rând; o nouă apăsare iese din modul de selecție și șterge
bifele. Cât timp modul de selecție este pornit, apăsarea pe un rând îl
bifează sau îl debifează în loc să deschidă peștera, iar în antet apar încă
trei butoane:

- **Selectează tot** — bifează fiecare peșteră *vizibilă în acel moment după
  filtrare*, nu toată baza de date;
- **Inversează selecția** — răstoarnă bifele de pe peșterile vizibile;
- **Șterge selectate** — vezi mai jos.

> 📷 [Modul de selecție pe lista de peșteri](../screenshots/01-home-and-caves.md#home-cave-list-selection-mode) — Lista de peșteri de pe pagina principală în modul de selecție, cu două peșteri bifate.

### Ștergerea peșterilor

Ștergerea unei peșteri ia cu ea toate locurile, hărțile și turele ei și nu
poate fi anulată. Documentele nu sunt șterse: rămân în aplicație, dar își
pierd legătura cu peștera. De aceea aplicația întreabă de trei ori:

1. „Ștergeți N elemente selectate?”
2. „Ștergeți definitiv N peșteri și toate datele aferente? Această acțiune
   nu poate fi anulată.”
3. „Confirmați din nou: ștergeți N peșteri cu toate punctele, hărțile și
   înregistrările?”

Butoanele de pe al treilea dialog sunt inversate intenționat — **Șterge** în
stânga, **Anulează** în dreapta — așa că citiți-l înainte de a apăsa.

**Șterge selectate** apare numai cât timp **Setări → General → Permite
ștergerea în masă a peșterilor** este pornit. Este pornit implicit; oprirea
lui înlătură singura cale de a șterge o peșteră din acest ecran.

### Acțiuni care urmează selecția sau filtrul

Patru acțiuni lucrează pe o mulțime de peșteri, nu pe toate: **Harta
peșterilor**, **Importă documente în peșteri**, **Exportă punctele
(GPX/KML)** și **Generează coduri QR pentru peșteri**. Toate folosesc aceeași
regulă, fără să o spună pe ecran:

- cu modul de selecție pornit, folosesc numai peșterile bifate;
- altfel folosesc fiecare peșteră rămasă vizibilă după filtrul curent.

Așadar tastarea câtorva litere în caseta de filtru, sau bifarea a trei
peșteri, este calea de a limita o vedere pe hartă, un export sau o foaie de
coduri QR numai la acele peșteri. Dacă mulțimea vizată iese goală, **Importă
documente în peșteri**, **Generează coduri QR pentru peșteri** și **Exportă
punctele (GPX/KML)** se opresc cu un mesaj scurt — de pildă „Nicio peșteră
pentru importul documentelor.” — în loc să nu facă nimic. **Harta
peșterilor** este excepția: o mulțime vizată goală este tratată ca lipsă de
restricție, iar harta se deschide pe toate peșterile.

### Generează coduri QR pentru peșteri

Butonul QR din antetul listei de peșteri adună locurile fiecărei peșteri
vizate și deschide foaia de coduri QR de tipărit pentru ele, care este calea
cea mai rapidă de a scoate dintr-o dată etichete de intrare pentru o arie
întreagă.

1. Îngustați lista cu filtrul sau bifați peșterile dorite.
2. Apăsați **Generează coduri QR pentru peșteri**.
3. Dacă vreuna dintre acele peșteri ține locuri care nu sunt intrări,
   aplicația întreabă **Generează coduri QR**: alegeți **Doar intrări** sau
   **Toate locurile**.
4. Se deschide foaia de coduri QR, gata de tipărit sau de exportat. Vezi
   [Coduri QR](qr-codes.md).

Dacă nu este nimic de lucrat, primiți „Nu există peșteri pentru care să se
genereze coduri QR” sau „Nu există locuri pentru care să se genereze coduri
QR”.

## Meniul ⋮ al aplicației

Butonul **⋮** deschide un sertar dinspre marginea din dreapta. Partea lui de
sus este specifică paginii principale; tot ce se află sub linia despărțitoare
este la fel pe fiecare ecran din aplicație.

> 📷 [Meniul global (sertarul lateral)](../screenshots/01-home-and-caves.md#home-global-menu) — Sertarul global deschis din butonul de meniu al paginii principale.

### Intrările paginii principale

- **Adaugă peșteră nouă** — deschide formularul de peșteră nouă.
- **Documente** — deschide navigatorul care ține fiecare document din
  aplicație.
- **Arii de suprafață** — vezi [Arii de suprafață](surface-areas.md).
- **Import peșteri din CSV** — vezi [Import CSV](csv-import.md).
- **Importă documente în peșteri** — alegeți un dosar, iar fiecare subdosar
  al lui este pus în corespondență cu una dintre peșterile vizate; fișierele
  dinăuntru sunt importate ca documente ale acelei peșteri. Este gândit
  pentru fotografii și notițe organizate pe calculator ca un dosar de
  peșteră.
- **Harta peșterilor** — [harta peșterilor](surface-map.md), încadrată pe
  peșterile vizate.
- **Exportă punctele (GPX/KML)** — scrie locurile peșterilor vizate într-un
  fișier GPX sau KML pentru Garmin, Locus, QGIS sau Google Earth. Se scriu
  numai locurile care au coordonate; dacă niciunul nu are, primiți „Nu există
  puncte cu coordonate de exportat”.
- **Importă puncte (GPX/KML)** — citește un astfel de fișier înapoi; alegeți
  întâi fișierul, apoi alegeți cărei peșteri îi aparțin punctele.

Aceste două intrări de meniu sunt singura cale către transferul GPX/KML — nu
există butoane de bară pentru el. Vezi
[Transfer de locuri GPX/KML](place-transfer.md).

### Navigația și cardurile comune

Sub linia despărțitoare sertarul arată un rând de pictograme de navigație —
**Peșteri**, **Sinc. man.** ([panoul de
sincronizare](sync-and-change-log.md)), **Documente**, **Setări** și
**Scanează** — urmate de:

- un comutator **Detectare beaconuri**. Nu este o legătură, ci același
  comutator principal ca cel din Setări, așa că puteți amuți sau reactiva
  detectarea automată fără să părăsiți ecranul pe care sunteți; pornirea lui
  cere aceleași permisiuni. Vezi [Beaconuri BLE](ble-beacons.md).
- un card **Sincronizare FTP** prins lângă partea de jos. Fără niciun profil
  de server scrie „Configurează FTP pentru sincronizare” și vă duce la
  setările FTP. Cu un profil arată **Sincronizează acum** și numele
  profilului și pornește sincronizarea când îl apăsați; cât timp o rulare
  este în curs devine o bară de progres cu faza curentă și un buton de pauză;
  după aceea arată rezultatul — verde la reușită, roșu la eșec, portocaliu la
  anulare — cu un buton pentru pornirea altei rulări. Apăsarea cardului în
  timpul sau după o rulare deschide [pagina de progres](ftp-sync.md)
  întreagă.
- un card pentru **tura activă**, când există una: verde cât timp
  înregistrează, portocaliu cât timp este în pauză. Dă titlul turei, peștera,
  de cât timp rulează tura, câte puncte ține și ultimele cinci locuri scanate
  cu orele lor, plus butoane pentru a vedea tura, a o pune în pauză sau a o
  relua și a o opri. Aceasta este calea cea mai rapidă de a pune o tură în
  pauză în plină peșteră. Vezi [Ture](trips.md).

Chiar la bază stau un buton **Tur de ghidare** (?), un buton **Despre** (i)
și versiunea instalată, tipărită ca ceva de felul „v0.2.1+328” — citați-o
când raportați o problemă. Dialogul Despre în sine nu face decât să trimită
către situl SpeoSilex și către pagina proiectului de pe GitHub.

Meniul se deschide de obicei ca acest sertar. Dacă se deschide vreodată ca o
listă compactă în schimb, butonul de la baza acelei liste îl face la loc
sertar pentru totdeauna, pe fiecare ecran.

## Oferta de date de test la prima pornire

La oricare dintre primele patru porniri ale aplicației, dacă nu există încă
peșteri, aplicația întreabă **Încărcați date de test?** — „Baza de date este
goală. Doriți să o populați cu peșteri și locuri de test?”

Acceptarea este distructivă și nu poate fi anulată: înlocuiește toată baza de
date locală și fiecare fișier păstrat cu conținutul unei arhive de test gata
făcute, apoi repornește aplicația. Când aplicația găsește hărți sau documente
deja pe dispozitiv, dialogul adaugă avertismentul „Atenție: hărțile și/sau
documentele existente vor fi șterse definitiv și înlocuite cu datele de
test.” Alegeți **Nu** ca să mergeți mai departe cu o bază de date goală.

Dacă acceptați, arhiva este adusă — descărcată, când versiunea instalată
trimite către o adresă web — în spatele unui dialog „Se descarcă arhiva cu
date de test...”, importată, iar aplicația repornește pe datele de probă.
Versiunile care nu poartă nicio arhivă de test răspund cu „URL-ul arhivei cu
date de test nu este configurat (test_archive_url).” și nu schimbă nimic.

Vezi [Primii pași](../getting-started.md) și
[Export și import al bazei de date](database-export-import.md) dacă doriți să
salvați întâi ce aveți deja.

## Tururi ghidate

Prima dată când deschideți un ecran care are un tur, indiciile lui apar de la
sine, fiecare pas cu un buton **Următor**, un buton **Omite** și un buton
**Dezactivează tururile automate**. Fiecare ecran ține minte că i-ați văzut
turul. Pe pagina principală turul așteaptă ca întrebarea „Încărcați date de
test?” să primească răspuns înainte să pornească, așa că cele două nu se bat
pe ecran.

**Dezactivează tururile automate** oprește indiciile automate peste tot și
confirmă cu „Tururile automate au fost dezactivate. Poți porni oricând manual
turul de ajutor din meniul lateral.” Butonul **Tur de ghidare** de la baza
meniului ⋮ reia indiciile pentru ecranul pe care sunteți, fie că tururile
automate sunt oprite, fie că nu.

## Modul depanare

Apăsarea de nouă ori pe titlul aplicației, cu cel mult vreo trei secunde
între apăsări, pornește **modul depanare** și arată un mesaj de confirmare.
Oprirea lui cere douăzeci de apăsări. Modul depanare nu este ținut minte —
este oprit din nou după următoarea pornire a aplicației.

Cât timp este pornit, Setări capătă o secțiune **Informații depanare** (calea
bazei de date, directorul de date, tabela configurații), **Setări → Baza de
date** capătă un buton **Deschide executant comenzi SQL**, iar aplicația
înregistrează jurnale mai amănunțite. Nimic din toate acestea nu este necesar
pentru folosința obișnuită în peșteră; executantul de comenzi SQL în special
scrie direct în baza de date și vă poate strica datele.

## Vezi și

- [Peșteri și zone de peșteră](caves-and-areas.md)
- [Filtrare, sortare și selecție în liste](lists-filter-sort-select.md)
- [Locuri din peșteră](cave-places.md)
- [Panoul de sincronizare și istoricul modificărilor](sync-and-change-log.md)
- [Sincronizare FTP](ftp-sync.md)
- [Setări](settings.md)
