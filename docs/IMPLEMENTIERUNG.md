# Implementierung der Elm-Anwendung

## Architektur

Die Anwendung folgt The Elm Architecture:

```text
public/data/energy.json
          |
       Api.elm  ->  Dataset
          |
Main.elm: Model / Msg / update
   |          |           |
FlowNetwork  TimeSeries  FlowMatrix
```

`Domain.elm` definiert `Dataset`, `Sample`, `Generation` und `Flow`.
`Api.elm` lädt die JSON-Datei mit `Http.get` und macht Lade- sowie Fehlerzustand
sichtbar. `Main.elm` besitzt die einzige Quelle der Wahrheit für Auswahl und
Zeitraum:

```elm
type alias State =
    { dataset : Dataset
    , selectedIndex : Int
    , selectedPartner : Maybe String
    , windowStart : Int
    , windowSize : Int
    }
```

Die Nachrichten `SelectPartner`, `SelectTime`, `SelectCell`, `SetWindowSize`,
`MoveWindow` und `Reset` aktualisieren diesen Zustand. Die drei Views erhalten
nur die jeweils benötigten Werte und Ereignisfunktionen.

## Gerichteter Netzwerkgraph

`src/View/FlowNetwork.elm` positioniert Deutschland und elf Partnerländer
radial. Eine gerichtete gekrümmte Kante codiert einen bilateralen physischen
Fluss:

- Rot und Pfeil nach Deutschland: Import,
- Blau und Pfeil vom deutschen Knoten: Export,
- Linienbreite: absoluter Betrag in GW.

Die im zweiten Zwischenstand zu großen Pfeilspitzen wurden von 6 auf 4 SVG-
Einheiten reduziert. Gleichzeitig wurde die maximale Linienbreite auf 21,5
Einheiten erweitert, damit starke Flüsse deutlicher hervortreten. Ein Klick auf
Kante oder Länderknoten setzt `selectedPartner`; nicht ausgewählte Kanten werden
abgeblendet. Der Tooltip zeigt physischen Fluss und Handel getrennt.

## Zeitreihe

`src/View/TimeSeries.elm` zeichnet gestapelte Flächen für Erneuerbare, Kohle,
Gas und Sonstige. Die linke Y-Achse zeigt absolute Erzeugungsleistung in GW.
Unterhalb liegt für das ausgewählte Land ein separates Liniendiagramm mit
symmetrischer GW-Achse. Eine sichtbare Legende erklärt das Vorzeichen: positiv
ist Import nach Deutschland, negativ Export aus Deutschland.

Die Detailkarten nennen für die ausgewählte Stunde Gesamtleistung, absolute
Werte und Anteile der vier Gruppen, Strompreis und gegebenenfalls den Fluss des
Länderpaars. Eine gestrichelte Vertikale verbindet dieselbe Stunde in beiden
Teilplots. Transparente Trefferflächen machen jeden Datenpunkt anklickbar.

## Pixelmatrix

`src/View/FlowMatrix.elm` bildet Länder auf Zeilen und Stunden auf Spalten ab.
Alle Zellen verwenden eine einzige, über den gesamten Monatsdatensatz bestimmte
divergierende Farbskala. Blau steht für Export, Rot für Import und Hellgrau für
Werte nahe null; die Skalenenden werden in GW beschriftet. Damit sind Farben
über alle Zeilen und auch zwischen den 48-Stunden- und 7-Tage-Fenstern
vergleichbar. Zusätzliche weiße Zwischenräume wurden entfernt. Die Auswahl
markiert nicht nur eine Zelle, sondern hebt die gesamte zugehörige Zeile und
Spalte als goldfarbenes Fadenkreuz hervor.

## Zeitraumsteuerung

Der Datensatz kann als 48-Stunden-Fenster, 7-Tage-Fenster oder kompletter Monat
angezeigt werden. Vor- und Zurück-Schaltflächen verschieben begrenzte Fenster
ohne Überlauf. Die globale Datenposition bleibt erhalten; die Views bekommen
den sichtbaren Ausschnitt und einen korrekt umgerechneten lokalen Index.

## Datenanbindung und Sicherheit

`scripts/build_postgrest_fixture.py` authentifiziert sich am Seminarserver,
paginiert begrenzte PostgREST-Abfragen und schreibt den normalisierten Export.
Elm lädt ausschließlich diese Datei per HTTP. So kann die Anwendung statisch
bereitgestellt werden, ohne Passwort oder Bearer-Token in JavaScript zu
veröffentlichen.

## Build

Geprüft mit Elm 0.19.1:

```powershell
elm make src/Main.elm --optimize --output=public/elm.js
```

Der Browser-Build liegt in `public/elm.js`; `elm-stuff` bleibt ignoriert.
