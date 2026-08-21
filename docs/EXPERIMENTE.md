# Experimente und Verifikation

## E1: Kompilierbarkeit

**Ziel:** Prüfen, ob der Prototyp ein gültiges Elm-Programm ist.

**Vorgehen:** `elm make src/Main.elm --output=public/elm.js` mit Elm 0.19.1.

**Ergebnis:** Erfolgreicher Build von sechs Modulen und Ausgabe von
`public/elm.js`.

## E2: Laden über HTTP

**Ziel:** Sicherstellen, dass die Visualisierung Daten nicht direkt in Elm
einbettet.

**Vorgehen:** Lokaler HTTP-Server auf Port 8765; Aufruf der Anwendung im Browser.

**Ergebnis:** `Api.elm` lädt 48 Stunden aus `public/data/energy.json`. Die Datei
wurde zuvor aus den PostgreSQL-Views des Schemas `energycharts` erzeugt. Die
drei SVG-Ansichten werden anschließend sichtbar aufgebaut; der Datenbankstatus
ist im Kopf der Anwendung sichtbar.

## E3: Verknüpfte Interaktion

Die folgenden Zustandsübergänge wurden im laufenden Browser geprüft:

1. Klick auf `France` in der Flussansicht → Toolbar zeigt `Auswahl: France`.
2. Klick auf Stunde 24 der Zeitreihe → Zeitpunkt wechselt auf `02.01. 00 h`,
   die Partnerauswahl bleibt erhalten.
3. Klick auf eine Matrixzelle → Partner und Zeitpunkt werden gemeinsam gesetzt.
   Im Test entstand `Auswahl: Denmark · 01.01. 12 h`.

Damit ist nicht nur jede Ansicht einzeln vorhanden; die Interaktion läuft über
das gemeinsame Elm-Model.

## E4: Abbildungen

Die Dateien unter `experiments/figures/elm_*.png` sind Screenshots der mit
`elm make` kompilierten und im Browser ausgeführten Anwendung. Python wurde nur
zum Zuschneiden der Browser-Screenshots verwendet. Inhalt, Geometrie, Farben und
Auswahlzustand der Visualisierungen stammen aus Elm/SVG.

## E5: PostgREST und CORS

Der Energy-Charts-Zugriff wurde gegen `/sciencedata` geprüft. Die
Token-Anforderung, die OpenAPI-Beschreibung und begrenzte Abfragen der vier
verwendeten Views waren erfolgreich. Der Export umfasste 2304 CBPF-Zeilen,
2304 CBET-Zeilen, 192 Erzeugungszeilen und 48 Preiszeilen. Die CORS-Preflights
für `POST /token` und `GET /v_cbpf` antworteten mit HTTP 204 und erlaubten die
benötigten Header.

## Einschränkungen

- Der aktuelle Zweitagesdatensatz ist ein technischer Test und erlaubt keine
  verallgemeinerbaren energiewirtschaftlichen Aussagen.
- `v_publicpower` enthält für Deutschland Nullwerte; deshalb verwendet der
  Export `v_totalpower` und skaliert dessen MW-Werte auf GW.
- Für längere Zeiträume werden Zoom, Aggregation und ein Top-k-Filter benötigt.
