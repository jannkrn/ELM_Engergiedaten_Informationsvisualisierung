# Implementierung des Elm-Prototyps

## Architektur

Der Prototyp folgt The Elm Architecture:

```text
HTTP-Datensatz
    ↓
Api.elm → Dataset
    ↓
Main.elm: Model / Msg / update
    ├── View.Chord
    ├── View.TimeSeries
    └── View.FlowMatrix
```

### `Domain.elm`

Definiert `Dataset`, `Sample`, `Generation` und `Flow`. Ein `Sample` enthält
einen Zeitpunkt, den Erzeugungsmix, den Preis sowie physische Flüsse und
Handelswerte zu allen Partnerländern. Positive Flüsse bedeuten Import nach
Deutschland, negative Flüsse Export aus Deutschland.

### `Api.elm`

Lädt `data/energy.json` mit `Http.get`. Die JSON-Decoder bilden die Daten in die
gemeinsamen Domänentypen ab. Lade- und Fehlerzustand sind sichtbare Zustände der
Anwendung.

### `Main.elm`

Der gemeinsame Zustand enthält:

```elm
type alias State =
    { dataset : Dataset
    , selectedIndex : Int
    , selectedPartner : Maybe String
    }
```

Relevante Nachrichten sind `SelectPartner`, `SelectTime`, `SelectCell` und
`Reset`. Dadurch existiert eine einzige Quelle der Wahrheit für alle Ansichten.

## Visualisierungen

### Gerichtete Flussansicht

`View/Chord.elm` ordnet Deutschland und die Partnerländer radial an. SVG-Pfade
verbinden Quelle und Ziel. Pfeilspitze und Farbe codieren die Richtung redundant:

- Rot: Import nach Deutschland,
- Blau: Export aus Deutschland,
- Linienbreite: Betrag des Flusses.

Die Auswahl eines Partnerlands reduziert die Deckkraft der übrigen Verbindungen
und aktiviert denselben Filter in Zeitreihe und Matrix.

### Gestapelte Zeitreihe

`View/TimeSeries.elm` erzeugt vier gestapelte SVG-Flächen für Erneuerbare,
Kohle, Gas und Sonstige. Für das ausgewählte Länderpaar wird zusätzlich eine
violette Flusslinie dargestellt. Eine gestrichelte Vertikale markiert den
gewählten Zeitpunkt. Unsichtbare Trefferflächen machen jede Stunde anklickbar.

### Pixelmatrix

`View/FlowMatrix.elm` bildet Partnerländer auf Zeilen und Stunden auf Spalten ab.
Eine divergierende Farbskala codiert Flussrichtung und Betrag. Ein Klick auf eine
Zelle setzt Partnerland und Zeitpunkt gleichzeitig.

## Buildprüfung

Der Stand wurde am 21.08.2026 mit Elm 0.19.1 geprüft:

```text
Success! Compiled 6 modules.
Main ---> public/elm.js
```

Der generierte JavaScript-Build liegt in `public/elm.js`. `elm-stuff` bleibt
durch `.gitignore` vom Repository ausgeschlossen.

## PostgREST-Anbindung

`scripts/build_postgrest_fixture.py` authentifiziert sich an
`/sciencedata/token` und verwendet anschließend `Accept-Profile: energycharts`.
Die begrenzten Abfragen laden `v_cbpf`, `v_cbet`, `v_price` und
`v_totalpower`. Der Export normalisiert Viertelstundenwerte zu Stundenwerten und
schreibt `public/data/energy.json`. Zugangsdaten und Token werden nicht in Elm
oder Git gespeichert.

Elm lädt bewusst nur den normalisierten Export. Dadurch bleibt die Anwendung
auf statischen GitLab Pages ausführbar. Die Handelswerte aus `v_cbet` sind Teil
des Flow-Datentyps und erscheinen gemeinsam mit dem physischen Wert im
SVG-Tooltip der Flussansicht.
