# Deutschlands Rolle im europäischen Stromnetz

Interaktive Visual-Analytics-Anwendung in Elm zu Deutschlands physischen
Stromflüssen, Erzeugungsmix und Day-Ahead-Preisen. Drei koordinierte Ansichten
teilen sich einen Auswahlzustand:

1. gerichteter radialer Netzwerkgraph,
2. gestapelte Zeitreihe mit separater Flussskala,
3. Pixelmatrix für Partnerländer und Stunden.

Die Anwendung zeigt den Mai 2025 mit 744 Stunden und elf Partnerländern. Ein
Partner- oder Zeitklick aktualisiert alle Ansichten. Zur Navigation stehen
48 Stunden, sieben Tage oder der gesamte Monat zur Wahl.

## Projektstruktur

```text
src/                     Elm-Quellcode
  Api.elm                HTTP-Laden und JSON-Decoder
  Domain.elm             gemeinsame Datentypen
  Main.elm               Model, Update und Seitenaufbau
  View/                   drei SVG-Visualisierungen
public/                  statisch auslieferbare Webanwendung
  data/energy.json       normalisierter HTTP-Datensatz
scripts/                 PostgREST-Export und Datenvalidierung
docs/                    Daten-, Implementierungs- und Testdokumentation
experiments/             Versuchsergebnisse und Screenshots
report/                  Zwischenstände und finaler LaTeX-Bericht
material/                Aufgabenstellung, Vorlagen und Feedback
```

## Build und lokaler Start

```powershell
elm make src/Main.elm --output=public/elm.js
python -m http.server 8765 --directory public
```

Danach ist die Anwendung unter `http://127.0.0.1:8765/` erreichbar. Elm lädt
`public/data/energy.json` per HTTP; die Daten sind nicht im Quellcode eingebettet.

Produktionsbuild:

```powershell
elm make src/Main.elm --optimize --output=public/elm.js
```

## Daten und Reproduzierbarkeit

Der Datensatz wurde aus den Energy-Charts-Views `v_cbpf`, `v_cbet`, `v_price`
und `v_totalpower` des PostgREST-Dienstes der Universität erzeugt. Der Export
paginiert alle Abfragen und prüft die vollständige stündliche Abdeckung.

```powershell
python scripts/build_postgrest_fixture.py
python scripts/validate_dataset.py
```

Passwort und Bearer-Token werden weder gespeichert noch eingecheckt. Details zu
Einheiten, Transformationen und Quellen stehen in
[`docs/DATENQUELLEN.md`](docs/DATENQUELLEN.md).

## Bericht

Der finale LaTeX-Bericht und das erzeugte PDF liegen unter `report/final/`.
Die Entwicklungs- und Testentscheidungen sind in `docs/` dokumentiert.
