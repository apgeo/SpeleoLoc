# Filtrare, sortare și selecție în liste

[← Înapoi la cuprins](../README.md)

Lista peșterilor de pe ecranul principal și lista locurilor din peșteră
dinăuntrul unei peșteri folosesc același antet de listă: o casetă de
filtrare, un selector **Sortează după** și un mod de selecție cu acțiuni în
masă. Pagina aceasta descrie acel antet o singură dată; celelalte pagini
trimit aici în loc să îl repete.

## Unde apare acest antet

Doar două liste din aplicație folosesc antetul complet. Alte liste oferă o
parte dintre aceleași idei în aranjamentul lor propriu, descris la sfârșitul
acestei pagini.

| Listă | Filtru | Sortează după | Mod selecție |
| --- | --- | --- | --- |
| Lista peșterilor, pe [ecranul principal](home-screen.md) | da | da | da |
| Lista [locurilor din peșteră](cave-places.md), dinăuntrul unei peșteri | da | da | da |
| Browserul de [documente](documents.md) | o casetă de căutare permanentă | meniu propriu | nu |
| Banda de locuri de deasupra unei [hărți raster](raster-maps.md) | lupă proprie | dialoguri proprii | nu |
| Ecranul Hărți al unei peșteri | nu | trageți pentru reordonare | nu |

## Rândul de antet

Antetul stă direct deasupra listei și afișează, în stânga, numele a ceea ce
este listat, urmat de un număr între paranteze — **Peșteri:** pe ecranul
principal, **Locuri din peșteră:** înăuntrul unei peșteri. Numărul este viu:
afișează `(45)` în mod normal și `(5 /45)` cât timp un filtru îngustează
lista, așa că vedeți întotdeauna cât de mult ascundeți.

În dreapta stau **Mod selecție**, **Sortează după** și **Arată filtrul**, în
această ordine. Lista peșterilor mai adaugă două butoane după ele,
**Generează coduri QR pentru peșteri** și comutatorul **Ascunde bara de
acțiuni** / **Afișează bara de acțiuni**. **Sortează după** și **Arată
filtrul** se desenează într-o casetă rotunjită colorată cât timp sunt
active, iar pictograma **Mod selecție** capătă culoarea de accent cât timp
selecția este pornită, așa că vă dați seama dintr-o privire de ce arată o
listă așa cum arată.

Cât timp modul de selecție este pornit, numele și numărul din stânga dispar,
iar butoanele de acțiuni în masă se alătură rândului de pictograme din
dreapta.

## Filtrare

Caseta de filtrare stă ascunsă până când o cereți.

1. Apăsați **Arată filtrul**. Între antet și listă apare o casetă —
   etichetată **Filtru** pe lista peșterilor și **Filtrare locuri peșteră**
   înăuntrul unei peșteri.
2. Scrieți. Lista se îngustează pe măsură ce scrieți; nu aveți nimic de
   confirmat.
3. Apăsați din nou **Arată filtrul** pentru a închide caseta. Închiderea
   șterge și ce ați scris și readuce lista întreagă.

Potrivirea nu ține cont de majuscule și se face oriunde în text, nu doar la
început, iar spațiile de la început și de la sfârșit sunt ignorate. Ce caută
fiecare listă:

| Listă | Filtrul se potrivește pe |
| --- | --- |
| Lista peșterilor | titlul peșterii și numele zonei ei de suprafață |
| Lista locurilor din peșteră | titlul locului, codul lui de loc și numele zonei lui din peșteră |

Scrierea numelui unei zone de suprafață pe ecranul principal este deci cea
mai rapidă cale de a reduce lista la o singură regiune, iar scrierea numelui
unei zone din peșteră, înăuntrul unei peșteri, o reduce la o singură parte a
sistemului.

Dacă nu se potrivește nimic, lista este pur și simplu goală, iar numărul
afișează `(0 /45)`. Filtrul nu este ținut minte — fiecare vizită pe ecran
începe cu caseta închisă și cu lista întreagă la vedere.

## Sortare

**Sortează după** deschide un dialog cu două secțiuni, **Primar** și
**Secundar**. Câmpul secundar decide doar ordinea rândurilor aflate la
egalitate pe cel primar.

Pentru a alege un câmp:

- apăsați numele lui, ca să sortați după el, crescător;
- apăsați numele din nou, ca să îl răsturnați pe descrescător;
- sau apăsați direct săgețile **Crescător** / **Descrescător** din dreapta
  lui.

O bifă marchează câmpul aflat în uz, iar săgeata aflată în uz este colorată.
Sub **Secundar** există o intrare **Niciuna**, aleasă implicit; același câmp
nu poate fi și primar, și secundar, așa că oricare l-ați alege ca primar
iese din lista secundară. Câmpurile secundare rămân gri până când este ales
un câmp primar.

Butoanele dialogului sunt **Șterge sortarea**, **Anulează** și **OK**.
**OK** rămâne gri până când ați ales un câmp primar. **Șterge sortarea**
este oferit doar dacă o sortare era deja în vigoare când ați deschis
dialogul; el readuce lista la ordinea în care se întâmplă să fie stocate
înregistrările, ceea ce rareori este ce vă trebuie — alegeți din nou un câmp
ca să obțineți o ordine previzibilă.

Alegerea dumneavoastră este salvată separat pentru fiecare dintre cele două
liste și restaurată data următoare când deschideți ecranul. Ambele liste
pornesc de la **Ultima modificare**, cele mai noi primele.

### Câmpurile

| Lista peșterilor | Lista locurilor din peșteră |
| --- | --- |
| **Ultima modificare** (implicit) | **Ultima modificare** (implicit) |
| **Titlu** | **Titlu** |
| **Zonă de suprafață** | **Zonă peșteră** |
| **Număr de locuri** | **Adâncime** |
| | **Mod de generare identificatori cod QR** |
| | **Intrare** |
| | **Are cod QR** |
| | **Hărți cu poziție** |

Locurile fără adâncime înregistrată și locurile fără cod de loc se duc la
sfârșitul listei când ordinea este crescătoare.

### Titluri de grup

Unele câmpuri împart lista și în grupuri, fiecare sub un mic titlu gri:

- **Titlu** — câte un titlu pentru fiecare literă inițială;
- **Zonă de suprafață** (lista peșterilor) și **Zonă peșteră** (lista
  locurilor) — câte un titlu pentru fiecare zonă, iar tot ce nu este
  atribuit se adună sub un titlu care afișează `—`;
- **Intrare** — **Intrare principală**, **Intrare** și **Non-intrare**;
- **Are cod QR** — **Are cod QR** și **Fără cod QR**.

Titlurile apar doar pentru câmpul primar, iar sortarea descrescătoare
inversează ordinea titlurilor.

## Mod selecție

Apăsați pictograma cu listă de bifat (**Mod selecție**) ca să puneți o
casetă de bifat pe fiecare rând. Cât timp este pornit, apăsarea unui rând îl
bifează sau îl debifează în loc să îl deschidă, iar în antet apar trei
butoane:

| Buton | Ce face |
| --- | --- |
| **Selectează tot** | Înlocuiește selecția cu fiecare rând pe care filtrul îl lasă vizibil în acel moment — nu cu toată baza de date. |
| **Inversează selecția** | Răstoarnă bifa de pe fiecare rând vizibil, lăsând neatinse celelalte bife. |
| **Șterge selectate** | Șterge înregistrările bifate. Stă gri cât timp nu este nimic bifat. |

Apăsarea din nou a pictogramei cu listă de bifat părăsește modul de selecție
și șterge fiecare bifă.

Bifele supraviețuiesc unei schimbări de filtru. Dacă bifați trei peșteri și
apoi scrieți ceva care le ascunde, ele rămân bifate și contează mai departe
ca selectate — inclusiv pentru **Șterge selectate**. **Selectează tot**
șterge astfel de bife ascunse, pentru că înlocuiește selecția cu totul;
**Inversează selecția** nu. La îndoială, ștergeți filtrul și uitați-vă la ce
este bifat înainte de a șterge.

### Ștergerea mai multor înregistrări deodată

Ștergerea în masă este definitivă și nu poate fi anulată. Fiecare listă
întreabă întâi:

> Ștergeți N elemente selectate?

Ștergerea locurilor din peșteră se oprește aici. Ștergerea peșterilor ia cu
ea locurile lor, zonele din peșteră, hărțile raster, punctele de pe hartă,
turele și înregistrările de beacon, așa că lista peșterilor mai întreabă de
două ori:

> Ștergeți definitiv N peșteri și toate datele aferente? Această acțiune nu
> poate fi anulată.

> Confirmați din nou: ștergeți N peșteri cu toate punctele, hărțile și
> înregistrările?

Butoanele de pe ultimul dialog sunt inversate intenționat — **Șterge** în
stânga, **Anulează** în dreapta — așa că citiți-l înainte de a apăsa.

**Șterge selectate** apare pe lista peșterilor doar cât timp **Setări →
General → Permite ștergerea în masă a peșterilor** este pornit. Este pornit
implicit; oprirea lui înlătură singura cale de a șterge peșteri de pe
ecranul principal. Lista locurilor nu este afectată de acea setare.

## Acțiuni care urmează selecția sau filtrul

Câteva butoane lucrează discret pe un *set* de înregistrări, nu pe tot, iar
setul este hotărât de acest antet. Nimic de pe ecran nu o spune.

| Acțiune | Cu modul de selecție pornit | Altfel |
| --- | --- | --- |
| **Harta peșterilor**, **Importă documente în peșteri**, **Exportă punctele (GPX/KML)**, **Generează coduri QR pentru peșteri** (ecranul principal) | peșterile bifate | fiecare peșteră pe care filtrul o lasă vizibilă |
| **Harta peșterilor** (lista locurilor din peșteră) | locurile bifate | fiecare loc pe care filtrul îl lasă vizibil |
| **Printează coduri QR** (lista locurilor din peșteră) | locurile bifate | fiecare loc din peșteră — aceasta ignoră filtrul |

Așadar îngustarea listei cu filtrul, sau bifarea câtorva rânduri, este calea
prin care limitați o vedere de hartă, un export sau o foaie tipărită de
coduri QR doar la acele înregistrări.

Aveți grijă când setul iese gol — modul de selecție pornit fără nimic bifat
sau un filtru care nu se potrivește cu nimic. **Importă documente în
peșteri**, **Generează coduri QR pentru peșteri** și **Exportă punctele
(GPX/KML)** se opresc cu un mesaj scurt, de exemplu „Nicio peșteră pentru
importul documentelor.” **Harta peșterilor** și **Printează coduri QR**
citesc un set gol ca pe nicio restricție și revin la a afișa, sau a tipări,
tot.

## Liste care funcționează altfel

**Browserul de documente.** Caseta lui de căutare este mereu vizibilă, este
etichetată **Caută documente...** și se potrivește pe titlul documentului,
pe numele fișierului și pe descriere. Meniul lui **Sortează după** oferă
**Titlu**, **Tip**, **Dimensiune fișier** și **Dată**; alegerea câmpului
aflat deja în uz răstoarnă direcția, în loc să schimbe câmpul. Alegerea nu
este ținută minte între vizite și nu există mod de selecție sau ștergere în
masă. Vedeți [Documente](documents.md).

**Banda de locuri de deasupra unei hărți raster.** Lupa de pe bara laterală
de unelte a hărții deschide o casetă **Filtrare locuri peșteră** care se
potrivește pe titlul locului, pe descrierea lui, pe codul lui de loc și pe
zona lui din peșteră; locurile care nu se potrivesc rămân pe hartă ca puncte
palide, fără etichetă, în loc să dispară. Meniul hărții mai are **Sortare
locuri peșteră** și **Sortare hărți**, fiecare un mic dialog cu o listă de
câmpuri și cu chipsuri **Crescător** / **Descrescător**, confirmat cu
**Aplică**. Nu există mod de selecție. Vedeți [Hărți
raster](raster-maps.md) și [Vizualizatorul de hărți](map-viewer.md).

**Ecranul Hărți al unei peșteri.** Nu are nici filtru, nici mod de selecție.
În schimb **Reordonare hărți** comută lista într-un mod în care trageți
rândurile în ordinea dorită, iar butonul afișează apoi **Terminat
reordonarea**. Acea ordine stabilită de mână este ordinea în care hărțile
sunt listate în restul aplicației, dacă **Sortare hărți** nu o suprascrie.

## Vezi și

- [Ecranul principal](home-screen.md) — lista peșterilor și acțiunile ei cu domeniu limitat
- [Locuri din peșteră](cave-places.md) — lista locurilor dinăuntrul unei peșteri
- [Documente](documents.md) — caseta de căutare și meniul de sortare ale browserului
- [Hărți raster](raster-maps.md) — filtrare și sortare în jurul unei hărți
- [Setări](settings.md) — de unde se pornește și se oprește ștergerea în masă a peșterilor
