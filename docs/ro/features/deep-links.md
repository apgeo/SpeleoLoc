# Linkuri directe (`sp://`)

[← Înapoi la cuprins](../README.md)

Un link direct este o adresă scurtă de forma `sp://<identifier>` care
deschide direct un loc din peșteră. Este ceea ce poartă o etichetă QR
tipărită, dacă nu cumva puneți SpeleoLoc să tipărească în schimb o adresă
web (vedeți [Etichetele care poartă
prefixul](#labels-that-carry-the-prefix)), și ceea ce camera telefonului
predă către SpeleoLoc atunci când o îndreptați spre acea etichetă.

## Unde funcționează linkurile directe

Pe **Android**, SpeleoLoc înregistrează schema `sp://` în sistem: dacă
apăsați un astfel de link într-un mesaj, într-un browser sau într-o
aplicație de notițe, sau dacă îl scanați cu aplicația de cameră a
telefonului, SpeleoLoc este oferit ca aplicație cu care să fie deschis.

Pe **iOS schema nu este înregistrată**, așa că linkurile `sp://` nu fac
nimic acolo — nicio aplicație nu le preia. Tot restul de pe această
pagină funcționează și pe iOS, prin scanerul propriu al aplicației și
prin introducerea manuală; lipsește doar predarea de către sistemul de
operare.

## Cum arată linkul

```
sp://<identifier>
```

Identificatorul este **QCRI**-ul unui loc (conținutul dinăuntrul
pixelilor QR) sau **PCI**-ul lui (codul de loc lizibil de om) — se caută
după amândouă, deci un link construit din oricare dintre ele
funcționează. Vedeți
[Identificatori cod loc (PCI) și identificatori coduri QR (QCRI)](place-code-identifiers.md).

Exemple:

- `sp://1547` — deschide locul al cărui cod sau conținut QR este `1547`.
- `sp://RO-CLB-001-002-005` — un cod de loc ierarhic.
- `sp://a1b2c3d4` — un conținut QR de 8 caractere, trecut prin hash.

Două reguli contează în practică:

- **Tot ce urmează după `sp://` este preluat exact așa cum este scris**;
  se elimină doar spațiile din jur. O bară oblică la final, un segment de
  cale în plus sau un `?query=…` devin parte din valoarea căutată, așa că
  `sp://1547/` *nu* va găsi locul pe care îl deschide `sp://1547`.
- **Literele mari și mici nu contează.** `sp://AB12CD34` și
  `sp://ab12cd34` deschid același loc.

## Cum ajunge un link la SpeleoLoc

Există trei căi de intrare, iar ele se comportă puțin diferit.

| Cale | Ce se întâmplă |
|---|---|
| **Scanerul din aplicație** — butonul de scanare de pe pagina principală sau din lista de locuri a unei peșteri | Camera citește eticheta, aplicația elimină prefixul și caută valoarea. Aceasta este calea sigură în subteran. |
| **Camera sistemului sau un link apăsat** (doar pe Android) | Sistemul de operare întreabă cu ce aplicație să deschidă linkul. SpeleoLoc sare la loc atunci când **rulează deja**, în prim-plan sau în fundal. Un link care trebuie să pornească SpeleoLoc de la rece îl deschide pe pagina principală, fără să navigheze — după ce aplicația a pornit, apăsați linkul din nou. |
| **Introducere manuală** | În lista de locuri a unei peșteri, apăsați **Căutare manuală cod QR** din bara de instrumente. Scrieți fie identificatorul simplu, fie o valoare `sp://…` întreagă în câmpul **Mod de generare identificatori cod QR** și apăsați **Caută loc după id cod QR**. (În versiunile pentru dezvoltatori, aceeași căutare se poate deschide și ținând butonul de scanare apăsat aproximativ două secunde și jumătate.) |

Introducerea manuală este răspunsul pentru o etichetă acoperită de
noroi, crăpată sau ajunsă după o strâmtoare — citiți codul tipărit cu
ochii și scrieți-l. Pentru că rulează întotdeauna din lista de locuri a
unei peșteri, căutarea este limitată la acea peșteră, deci nu poate fi
niciodată ambiguă. (Într-o versiune pentru dezvoltatori, aceeași apăsare
lungă pe câmpul QR al unui loc din peșteră face altceva: completează
identificatorul acelui loc, în loc să caute un loc.)

## Ce face SpeleoLoc cu valoarea

1. **Prefixul `sp://` este eliminat.** Ambalajele de tip URL sunt
   desfăcute doar pentru codurile citite de scanerul din aplicație sau
   scrise de mână: un conținut `http://` sau `https://` este redus la
   textul de după ultimul caracter delimitator — așa se face că o
   etichetă tipărită cu adresa de destinație a
   clubului dvs. deschide în continuare locul în aplicație. Acest
   comportament este **Setări → Generare grafică cod QR → Extrage
   identificatorul din URL**, cu **Caractere delimitatoare URL** `/` și
   `=` în mod implicit. Un link predat de sistemul de operare sare
   complet peste acest pas — ce urmează după `sp://` este folosit exact
   așa cum este scris.
2. **Se caută orice loc din peșteră al cărui conținut QR sau cod de loc
   este egal cu acea valoare**, fără a ține cont de literele mari și
   mici. Pentru că se caută și codul de loc, un link construit dintr-un
   cod de loc funcționează chiar și atunci când conținuturile QR sunt
   trecute prin hash.
3. **Rezultatul depinde de câte locuri au fost găsite.**

| Potriviri | Rezultat |
|---|---|
| 0 | Apare avertismentul *Locul din peșteră nu a fost găsit*, împreună cu valoarea căutată. |
| 1 | Locul se deschide **pe o hartă** — prima hartă raster, în ordinea dvs. de sortare a hărților, care are un punct definit pentru el. Dacă nicio hartă nu are un punct pentru acel loc, primiți *Acest loc din peșteră nu este definit pe nicio hartă.* și, în locul hărții, pagina simplă a locului din peșteră. În ambele cazuri apare confirmarea *Locul din peșteră a fost identificat*. |
| 2 sau mai multe | Un dialog **Alege punctul / peșteră** listează fiecare potrivire, cu peștera ei dedesubt. Vedeți mai jos. |

Când o [tură](trips.md) este în desfășurare în peștera căreia îi aparține
locul găsit, deschiderea unui loc care **nu** este intrare îl
înregistrează și ca punct al turei și confirmă cu *Punct adăugat la
tură*. Un loc de tip intrare întreabă în schimb despre tură — vedeți
[Scanarea unei intrări](#scanning-an-entrance).

### Când același cod este folosit în mai multe peșteri

Nimic nu împiedică folosirea aceluiași cod în două peșteri diferite: un
cod pe care îl scrieți este verificat doar față de celelalte locuri din
aceeași peșteră, iar și acolo un duplicat este o întrebare la care puteți
răspunde *da*. În mod implicit, SpeleoLoc întreabă la care dintre ele
v-ați referit, prin dialogul **Alege punctul / peșteră**. Butonul lui
**Deschide setări** duce direct la cele două comutatoare care guvernează
acest lucru:

| Comutator (**Setări → General**) | Implicit | Dezactivat înseamnă |
|---|---|---|
| **Selectează peștera la scanare QR ambiguă** | Activat | O scanare cu camera sau un cod scris deschide silențios potrivirea din ultima peșteră deschisă. |
| **Selectează peștera la deep link ambiguu** | Activat | Un link `sp://` deschide silențios potrivirea din ultima peșteră deschisă. |

„Ultima peșteră deschisă” este ultima peșteră a cărei listă de locuri
ați vizitat-o. Dacă nicio potrivire nu aparține acelei peșteri, se
deschide prima potrivire. Cele două comutatoare sunt independente, deci
puteți păstra întrebarea pentru o cale și o puteți suprima pentru
cealaltă.

<a id="scanning-an-entrance"></a>

## Scanarea unei intrări

Scanarea sau deschiderea unui loc de tip **intrare** nu pornește și nu
oprește niciodată o tură de la sine — întreabă întotdeauna mai întâi.

- **Nicio tură în desfășurare** — **Începe tura**: *„Ai scanat o intrare
  în peșteră. Vrei să începi o tură nouă?”* Răspundeți **Da** și apare
  dialogul **Începe o tură nouă**, cu un titlu sugerat în câmpul
  **Titlul turei**, pe care îl puteți edita.
- **O tură în desfășurare în această peșteră** — **Oprește**: *„Ai
  scanat o intrare în peșteră. Ieși din peșteră? Oprești tura activă?”*
  Răspundeți **Nu** și scanarea este înregistrată în schimb ca punct al
  turei, așa că puteți trece pe la intrare fără să încheiați tura.
- **O tură în desfășurare în altă peșteră** — SpeleoLoc numește acea
  peșteră și întreabă dacă să îi oprească tura; dacă sunteți de acord,
  vă propune apoi să începeți o tură aici.

Vedeți [Ture](trips.md) pentru ce anume înregistrează o tură.

<a id="labels-that-carry-the-prefix"></a>

## Etichetele care poartă prefixul

În mod normal, fiecare etichetă QR tipărită de SpeleoLoc codifică
`sp://<identifier>`, nu identificatorul simplu. Acel prefix este cel care
face ca eticheta să însemne ceva în afara aplicației: camera de sistem a
telefonului îl recunoaște ca link și propune deschiderea SpeleoLoc.

Dezactivați **Setări → Generare grafică cod QR → Include prefix deep
link** și etichetele vor purta doar identificatorul — în continuare
perfect lizibil pentru scanerul din aplicație și cu o imagine QR puțin
mai simplă, dar inert pentru camera de sistem. Decideți înainte de a
tipări un lot: etichetele deja tipărite rămân cu ce au fost tipărite, iar
scanerul acceptă oricum ambele forme.

O adresă de destinație are prioritate față de acest comutator. Cât timp
una este setată, fiecare etichetă poartă acea adresă în loc de `sp://`,
iar **Include prefix deep link** rămâne gri — un pătrat poartă un prefix
sau celălalt, niciodată pe amândouă.

SpeleoLoc tot **nu are o pagină web publică proprie pentru un loc** —
pagina pe care ajunge un vizitator este una găzduită de clubul dvs. Ce
face SpeleoLoc acum este să compună adresa în locul dvs., așa că nu o
mai construiți de mână, în afara aplicației. Completați **Setări →
Generare grafică cod QR → Adresa de destinație pentru etichetele
tipărite** cu adresa de destinație a serverului clubului dvs. și fiecare
etichetă tipărită poartă acea adresă, cu identificatorul la sfârșit
(`https://speo.example.org/q/k3f9x2`). Un vizitator fără aplicație o
scanează cu camera proprie a telefonului și ajunge la pagina clubului
dvs.; pentru că identificatorul stă chiar la final, **Extrage
identificatorul din URL** îl recuperează în continuare atunci când un
speolog scanează aceeași etichetă cu SpeleoLoc. Vedeți
[Coduri QR](qr-codes.md) pentru setarea în sine.

Un lucru de verificat înainte de a tipări etichete ca adrese web: un
identificator care conține un `/` sau un `=` nu supraviețuiește drumului
înapoi. Scanerul păstrează doar ce urmează după ultimul dintre ele, așa
că restul codului este aruncat și locul nu este găsit — dintr-o etichetă
tipărită perfect. SpeleoLoc vă avertizează despre singurul câmp care ar
strica dintr-odată toate codurile viitoare: scrieți oricare dintre cele
două caractere în **Setări → Identificatori cod loc → Separator
segmente**, în strategia ierarhică, și sub câmp apare un avertisment.
Este doar un avertisment — valoarea este totuși salvată, iar un cod pe
care îl scrieți dvs. într-un loc nu este verificat de nimic.
Conținuturile QR trecute prin hash nu conțin niciodată vreunul dintre
cele două caractere.

## Depanare

- **„Locul din peșteră nu a fost găsit: …”** — valoarea nu corespunde
  nici conținutului QR, nici codului de loc al vreunui loc de pe acest
  dispozitiv. Sincronizați sau importați ultimele date și încercați din
  nou; verificați dacă nu a rămas o bară oblică în plus la final, în
  cazul în care ați scris sau ați construit linkul manual. Pe o etichetă
  tipărită cu o adresă de destinație, verificați în plus că nici codul în
  sine nu conține `/` sau `=` — acolo scanerul l-ar fi tăiat scurt.
- **„Cod QR invalid”** — după eliminarea prefixului nu a mai rămas nimic
  de căutat. Din scaner sau din introducerea manuală, mesajul este *Cod
  QR invalid (nu poate fi interpretat conform regulilor)*, împreună cu
  valoarea citită; dintr-un link, apare ca dialog cu titlul **Link
  direct**. Un link care nu conține decât `sp://` este ignorat fără
  niciun mesaj. Rețineți că o valoare care există, dar este necunoscută,
  nu este „invalidă” — aceea dă *Locul din peșteră nu a fost găsit*.
- **Dialogul de alegere apare de fiecare dată** — apăsați **Deschide
  setări** în el și dezactivați *Selectează peștera la deep link ambiguu*
  (sau *Selectează peștera la scanare QR ambiguă*) pentru ca SpeleoLoc să
  aleagă ultima peșteră deschisă. Rezolvarea de durată este eliminarea
  codurilor de loc duplicate dintre peșteri; trecerea la conținuturi QR
  trecute prin hash nu ajută, pentru că se caută și codul de loc.
- **Un link apăsat a deschis doar pagina principală** — SpeleoLoc nu
  rula încă. Apăsați linkul a doua oară, acum că rulează.
- **Pe iPhone nu se întâmplă absolut nimic** — este de așteptat: schema
  `sp://` nu este înregistrată pe iOS. Folosiți scanerul din aplicație
  sau introducerea manuală.

## Vezi și

- [Coduri QR — amplasare, scanare, tipărire](qr-codes.md)
- [Identificatori cod loc (PCI) și identificatori coduri QR (QCRI)](place-code-identifiers.md)
- [Locuri din peșteră](cave-places.md)
- [Ture](trips.md)
- [Setări](settings.md)
- [Navigarea în subteran](../workflows/navigating-underground.md)
