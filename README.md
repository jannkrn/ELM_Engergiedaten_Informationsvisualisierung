# Deutschlands Rolle im europäischen Stromnetz

Elm-Prototyp einer Visual-Analytics-Anwendung für physische Stromflüsse,
Erzeugungsmix und Strompreise. Drei Ansichten sind über einen gemeinsamen
Auswahlzustand verbunden:

1. gerichtete Chord-/Flussansicht,
2. gestapelte Zeitreihe,
3. Pixelmatrix.

Die Zeitreihe zeigt absolute Erzeugungsleistungen auf einer beschrifteten
GW-Achse. Für die ausgewählte Stunde werden zusätzlich Einzelwerte und Anteile
angegeben. Der physische Fluss zum gewählten Partnerland liegt in einem eigenen
Diagramm mit separater symmetrischer GW-Skala.

## Projektstruktur

```text
src/                     Elm-Quellcode
  Api.elm                HTTP-Laden und JSON-Decoder
  Domain.elm             gemeinsame Datentypen
  Main.elm               Model, Update und Seitenaufbau
  View/                   drei SVG-Visualisierungen
public/                  auslieferbare Webanwendung
  data/energy.json        normalisierter HTTP-Datensatz
scripts/                 PostgREST-Prüfung und Datenexport
docs/                    Daten- und Implementierungsdokumentation
experiments/             Screenshots und Versuchsergebnisse
report/                  Zwischenstände, Entwürfe und Abbildungen
material/                Aufgabenstellung, Vorlagen und Feedback
```

## Build und lokaler Start

```powershell
elm make src/Main.elm --output=public/elm.js
python -m http.server 8765 --directory public
```

Danach wird die Anwendung unter `http://127.0.0.1:8765/` geöffnet. Die Datei
`public/data/energy.json` wird von Elm per HTTP geladen und nicht in den
Quellcode eingebettet.

## Datenstatus

Der verwendete Seminar-Endpunkt lautet:

```text
https://dbs.informatik.uni-halle.de/sciencedata
```

Mit `Accept-Profile: energycharts` sind 66 Tabellen und Views sichtbar. Der
aktuelle Datensatz wurde mit begrenzten PostgREST-Abfragen aus `v_cbpf`,
`v_cbet`, `v_price` und `v_totalpower` erzeugt. Er umfasst 48 Stunden des
01.-02.01.2025 und elf Partnerländer. Der Export ist über
`scripts/build_postgrest_fixture.py` reproduzierbar.

Details stehen in [docs/DATENQUELLEN.md](docs/DATENQUELLEN.md).

## Sicherheit

- Tokens und Passwörter werden nicht gespeichert oder eingecheckt.
- Ein Bearer-Token darf nicht in Elm eingebettet werden, da Browsercode
  öffentlich einsehbar ist.
- Der sichere Weg für GitLab Pages ist ein vorab erzeugter JSON-Export, der
  anschließend als statische Datei per HTTP geladen wird.
