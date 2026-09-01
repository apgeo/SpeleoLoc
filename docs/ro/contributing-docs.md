# Contribuții la acest wiki

[← Înapoi la cuprins](README.md)

Această pagină descrie cum este alcătuit wiki-ul pentru utilizatorii SpeleoLoc,
astfel încât o pagină nouă să arate ca cele deja existente, iar un ecran
modificat să nu lase documentația greșită pe tăcute.

Wiki-ul este scris pentru **speologii care folosesc aplicația**, nu pentru cei
care lucrează la ea. Notele destinate dezvoltatorilor stau în altă parte a
depozitului și, în mod deliberat, nu sunt legate de aici.

## Organizare

```
docs/
├── README.md              cuprinsul — orice pagină este accesibilă din el
├── overview.md            la ce folosește aplicația și modelul ei de date
├── getting-started.md     instalarea și prima pornire
├── glossary.md            vocabularul folosit în tot wiki-ul
├── contributing-docs.md   această pagină
├── features/              câte o pagină pentru fiecare ecran sau subiect
├── workflows/             ghiduri pas cu pas, orientate pe sarcini
├── screenshots/           galeriile — fiecare captură de ecran, descrisă
├── images/                fișierele capturilor de ecran
└── ro/                    ediția în română, oglindind tot ce este mai sus
```

`features/` răspunde la întrebarea *„ce face acest ecran?”*. `workflows/`
răspunde la *„cum duc la capăt această treabă?”* și trimite mai departe către
paginile de funcții, în loc să le repete. Dacă o pagină începe să le facă pe
amândouă, împărțiți-o.

## Convenții pentru pagini

- Începeți cu `# Titlul paginii`, scris ca o propoziție obișnuită, un rând gol,
  apoi legătura de întoarcere: `[← Înapoi la cuprins](../README.md)` dintr-un
  subdirector, `(README.md)` de la primul nivel.
- Continuați cu una sau două propoziții care spun ce acoperă pagina.
- Folosiți `##` pentru secțiuni și `###` pentru subsecțiuni, și un tabel oriunde
  enumerați câmpuri sau opțiuni.
- Încheiați cu o listă `## Vezi și` cu trei până la șase pagini înrudite.
- Aranjați textul pe aproximativ 78 de coloane.

## Denumirile folosite de aplicație

Fiecare control are o denumire oficială în engleză, în fișierul de traduceri al
aplicației. Căutați denumirea acolo, în loc să inventați una, și scrieți
traseul din meniu cu săgeți: **Setări → General → Afișează bara de acțiuni pe
pagina principală**.

Limba implicită a aplicației este **Română**; **English** se alege din
**Setări → General → Limba aplicației**. De aceea capturile de ecran arată
denumirile românești, în timp ce paginile în engleză le folosesc pe cele
englezești — galeriile le dau pe amândouă.

Nu numiți fișiere sursă, clase, tabele din baza de date sau chei de
configurare. Excepția este un text pe care utilizatorul chiar îl scrie sau îl
vede, cum ar fi o variabilă din **Șablon etichetă cod QR**.

## Capturi de ecran

Imaginile sunt păstrate **o singură dată**, în `docs/images/`, și sunt folosite
de ambele ediții. Fiecare este descrisă **o singură dată**, într-o pagină de
galerie din `docs/screenshots/`. Paginile de funcții nu includ imagini — ele
trimit către intrarea din galerie:

```markdown
> 📷 [Fila de jurnal a sincronizării](../screenshots/06-sync-and-sharing.md#ftp-sync-log-tab) — fiecare pas al ultimei rulări, cea mai nouă prima.
```

Așa descrierea unui ecran rămâne într-un singur loc, paginile de funcții rămân
ușor de citit, iar o captură refăcută trebuie descrisă din nou o singură dată.

### Adăugarea unei capturi de ecran

1. Faceți captura pe telefon, în orientare portret, cu aplicația în starea ei
   obișnuită — fără meniuri deschise pe jumătate și, pe cât se poate, fără
   straturi de depanare.
2. Tăiați bara de stare și bara de navigare ale telefonului, scalați imaginea la
   **640 px lățime** și salvați-o ca JPEG progresiv, la calitate ~86. Nimic din
   interiorul ferestrei aplicației nu are voie să fie retușat.
3. Denumiți-o după ce arată, nu după momentul în care a fost făcută:
   `cave-map-measure-distance.jpg`, niciodată `Screenshot_20260901_024828.jpg`.
   Numele este o ancoră permanentă, așa că alegeți unul care rezistă și după o
   nouă captură.
4. Adăugați o intrare în pagina de galerie potrivită, cu o ancoră
   `<a id="the-slug"></a>` deasupra titlului, imaginea, o legendă de un rând, o
   scurtă descriere a ceea ce face ecranul și — acolo unde captura este în
   română — o listă pliabilă care pune textele vizibile în corespondență cu cele
   în engleză.
5. Legați-o din paginile de funcții pe care le ilustrează.

Înlocuirea unei capturi înseamnă suprascrierea fișierului și revizuirea intrării
din galerie. Ancora și numele fișierului rămân pe loc, așa că nu se rupe nicio
legătură.

## Ediția în română

`docs/ro/` oglindește arborele în engleză fișier cu fișier: aceleași nume de
fișiere, aceleași titluri, aceleași ancore, astfel încât o legătură se traduce
schimbând prefixul căii. Se traduce doar textul.

Paginile în română trebuie să folosească **exact formulările afișate de
aplicație**, luate din fișierul de traduceri în română — speologul care citește
pagina are interfața în română în fața lui, așa că o traducere inventată a
numelui unui buton este mai rea decât nimic. Acolo unde un termen nu are o
formă românească consacrată, dați varianta românească și puneți engleza în
paranteze la prima folosire.

Când modificați o pagină în engleză, modificați și perechea ei în română în
același commit sau spuneți limpede în mesajul commit-ului că traducerea are încă
de recuperat.

## Cum ținem wiki-ul cinstit

- Verificați o afirmație în aplicație înainte să o scrieți. Dacă nu puteți
  confirma ce face un control, mai bine lăsați-l afară decât să ghiciți.
- Spuneți limpede când o acțiune este distructivă, ireversibilă sau vizibilă
  doar în modul de depanare.
- Aplicația este în stadiu alfa și se schimbă repede. O pagină rămasă în urmă
  merită îndreptată chiar dacă îndreptați o singură secțiune din ea.

## Vezi și

- [Cuprinsul wiki-ului](README.md)
- [Galeria de capturi de ecran](screenshots/README.md)
- [Glosar](glossary.md)
