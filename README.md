# Deutschlands Rolle im europäischen Stromnetz

Elm-Projekt für eine interaktiv verknüpfte Visual-Analytics-Anwendung zu
physischen Stromflüssen, Erzeugungsmix und Strompreisen in Europa.

## Ordnerstruktur

```text
src/                    Elm-Quellcode
  View/                 Chord-, Zeitreihen- und Pixelmatrix-Ansichten
public/                 Dateien für die Webauslieferung
  data/                 per HTTP geladene Datensätze/Testdaten
  assets/               CSS, Bilder und sonstige Webressourcen
scripts/                Datenabruf und Datenaufbereitung
experiments/
  figures/              Abbildungen aus Vorversuchen
  results/              Messwerte und Versuchsergebnisse
report/
  zwischenstaende/      eingereichte Zwischenstände als PDF
  entwuerfe/            bearbeitbare Berichtsentwürfe
  abbildungen/           Abbildungen für den Bericht
material/               Aufgabenstellung, Vorlagen und Feedback
tests/                  Tests und kleine Testdatensätze
```

## Projektregeln

- Produktive Daten werden über HTTP geladen.
- Zugangstoken und Passwörter werden niemals eingecheckt.
- Die drei Ansichten verwenden einen gemeinsamen Auswahl- und Zeitstatus.
- Vor einem Commit muss die Elm-Anwendung ohne Fehler kompilieren.

