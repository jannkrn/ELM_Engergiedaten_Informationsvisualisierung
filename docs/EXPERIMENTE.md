# Experimente und Verifikation

Stand: 10.09.2026

## E1: Datenvollständigkeit und Einheiten

`scripts/validate_dataset.py` prüfte den normalisierten Export. Ergebnis:

```text
Zeitraum: 01.05.2025 00:00 UTC bis 31.05.2025 23:00 UTC
Stunden: 744; Partnerländer: 11
Summierter physischer Fluss: 123 Importstunden, 621 Exportstunden
Richtungswechsel: 40
Negative Preisstunden: 129
Minimum Preis: -250,32 EUR/MWh am 11.05.2025 11:00 UTC
Maximum Preis: 229,11 EUR/MWh am 19.05.2025 18:00 UTC
Maximum Erneuerbare: 71,465 GW
```

Zusätzlich werden lückenlose Stundenschritte, Partnerabdeckung, endliche Werte
und Plausibilitätsgrenzen nach der MW-zu-GW-Umrechnung automatisch geprüft.

## E2: Kompilierbarkeit und HTTP-Laden

`elm make src/Main.elm --output=public/elm.js` war erfolgreich. Die Anwendung
wurde über einen lokalen HTTP-Server geöffnet; `Api.elm` lud alle 744 Stunden aus
`public/data/energy.json`. Im Browser traten keine JavaScript- oder HTTP-Fehler
auf. Der einzige Konsolenhinweis im Entwicklungsbuild empfiehlt den
`--optimize`-Schalter; der Auslieferungsbuild verwendet diesen Schalter.

## E3: Zeitraumsteuerung

Folgende Zustände wurden im laufenden Browser geprüft:

1. Standardansicht: `01.05. 00 h – 07.05. 23 h`.
2. Auswahl `48 Stunden`: `01.05. 00 h – 02.05. 23 h`.
3. Klick auf `nächster Zeitraum`: `03.05. 00 h – 04.05. 23 h`; die
   Partnerauswahl blieb erhalten und der Zeitpunkt wurde gültig in das neue
   Fenster gesetzt.
4. Auswahl `Gesamter Monat`: `01.05. 00 h – 31.05. 23 h`; beide
   Navigationsschaltflächen waren deaktiviert.

Damit ist die im Feedback geforderte Auswahl anderer Zeiträume umgesetzt.

## E4: Koordinierte Interaktion

1. Klick auf `France` im Netzwerkgraphen: Kopfzeile zeigt `Auswahl: France`;
   andere Kanten werden abgeblendet und die violette Flusslinie erscheint.
2. Klick auf 11.05.2025, 11 Uhr in der Zeitreihe: Länderwahl bleibt bestehen,
   die vertikale Markierung und alle drei Views wechseln auf dieselbe Stunde.
3. Klick auf die Matrixzelle `Denmark · 03.05. 12 h`: Kopfzeile zeigt
   `Auswahl: Denmark · 03.05. 12 h`; Netzwerk, Linie, Detailwerte und das
   Zeilen-/Spaltenfadenkreuz werden gemeinsam aktualisiert.

Die Matrixauswahl bietet gegenüber der gemeinsamen X-Achse zusätzlich die
simultane Wahl einer von elf Länderzeilen. Das Fadenkreuz macht beide gewählten
Dimensionen direkt sichtbar.

## E5: Vergleichbarkeit der Matrixfarben

Die Farbgrenze wird einmal aus allen physischen Flüssen des Monats berechnet
und nicht pro Zeile oder sichtbarem Fenster. Gleiche Rot- oder Blautöne bedeuten
daher in jeder Zeile denselben absoluten GW-Betrag. Eine beschriftete Legende
zeigt den globalen negativen und positiven Skalenrand sowie null. Der neutrale
Bereich ist hellgrau; unbegründete weiße Zelllücken wurden entfernt.

## Grenzen

- Der Monat erlaubt fallbezogene, aber keine saisonalen oder mehrjährigen
  Aussagen.
- Die Summe bilateraler CBPF-Werte wird nur als explorative Kenngröße genutzt;
  sie ersetzt keine Netzverlust- oder Bilanzanalyse.
- `v_totalpower` umfasst laut Energy-Charts auch industrielle Eigenerzeugung.
- Die vier Erzeugungsgruppen reduzieren Detail und können innerhalb einer
  Gruppe gegenläufige Technologien verdecken.
