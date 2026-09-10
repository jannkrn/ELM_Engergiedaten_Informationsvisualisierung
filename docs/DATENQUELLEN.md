# Datenquellen und Datenpfad

## Verwendete Quellen

Die Primärdaten stammen aus Energy-Charts und werden in der Veranstaltung über
PostgREST bereitgestellt:

```text
https://dbs.informatik.uni-halle.de/sciencedata
```

Für fachliche Views wird `Accept-Profile: energycharts` gesetzt. Die
Authentifizierung erfolgt über `POST /token`; Passwort und Token werden weder
im Repository noch im Browsercode gespeichert. Verwendet werden:

| View | Inhalt | Originaleinheit | Verwendung |
|---|---|---:|---|
| `v_cbpf` | grenzüberschreitende physische Flüsse | GW | Netzwerk, Zeitreihe, Matrix |
| `v_cbet` | grenzüberschreitender Stromhandel | GW | Tooltip der Netzwerkansicht |
| `v_price` | Day-Ahead-Preis DE-LU | EUR/MWh | Stundendetail und Analyse |
| `v_totalpower` | gesamte Nettoerzeugung einschließlich industrieller Eigenerzeugung | MW | Erzeugungsmix |

Die Einheiten sind nicht geraten, sondern der offiziellen Energy-Charts-
OpenAPI-Beschreibung entnommen (`/cbpf`, `/cbet`, `/price`, `/total_power`):

```text
https://api.energy-charts.info/openapi.json
```

Energy-Charts definiert für CBPF und CBET positive Werte als Import und
negative Werte als Export. Der Endpunkt `total_power` liefert MW. Die
Seminar-View `v_totalpower` trägt zwar Spaltennamen mit dem Suffix `_in_gw`,
enthält aber die MW-großen Originalwerte; deshalb dividiert das Exportskript
diese Werte explizit durch 1000. Die Anwendung zeigt danach GW.

## Zeitraum und Begründung

Der analysierte Zeitraum ist der gesamte Mai 2025 in UTC. Er umfasst 744
aufeinanderfolgende Stunden und elf Partnerländer. Ein voller Monat ist lang
genug, um Tages- und Wochenmuster sowie Richtungswechsel zu vergleichen, bleibt
aber in einer Pixelmatrix noch ohne zusätzliche Aggregation untersuchbar. Der
Mai 2025 enthält außerdem starke Kontraste: 129 Stunden mit negativem
Day-Ahead-Preis, ein Minimum von -250,32 EUR/MWh am 11.05. um 11 Uhr UTC und ein
Maximum von 229,11 EUR/MWh am 19.05. um 18 Uhr UTC. Damit eignet sich der Monat
für die Forschungsfrage nach Zusammenhängen zwischen Flüssen, Erzeugungsmix
und Preisen, ohne nur ein einzelnes Extremereignis auszuwählen.

## Export und Transformation

`scripts/build_postgrest_fixture.py` nutzt serverseitige Zeit-, Länder- und
Marktfilter sowie Seiten von maximal 1000 Zeilen. Für den Mai 2025 wurden
35.712 CBPF-, 35.712 CBET-, 2.976 Erzeugungs- und 744 Preiszeilen abgerufen.
Viertelstundenwerte werden je Stunde arithmetisch gemittelt. Anschließend werden
die Erzeugungsarten zu vier Gruppen zusammengefasst:

- Erneuerbare: Wind an Land und auf See, Solar, Biomasse, Lauf- und
  Speicherwasser sowie Geothermie,
- Kohle: Braun- und Steinkohle,
- Gas: fossiles Gas,
- Sonstige: Öl, Kohlegase, Abfall, Pumpspeicher, Kernenergie und sonstige
  Erzeugung.

Der normalisierte Datensatz `public/data/energy.json` enthält pro Stunde
Zeitstempel, vier Erzeugungsgruppen in GW, Preis in EUR/MWh sowie physische und
gehandelte Flüsse je Partnerland in GW.

## Qualitätskontrollen

`scripts/validate_dataset.py` prüft:

- genau 744 lückenlose Stunden,
- identische Abdeckung und Reihenfolge von elf Partnerländern,
- endliche Messwerte und nichtnegative Erzeugungsgruppen,
- das Auftreten positiver und negativer Flüsse,
- grobe Plausibilitätsgrenzen nach der Umrechnung in GW.

Die letzte Prüfung am 10.09.2026 ergab 123 Stunden mit positivem und 621
Stunden mit negativem summiertem physischen Fluss sowie 40 Wechsel des
Vorzeichens. Diese Summen sind eine aus den bilateralen Werten abgeleitete
Analysegröße, kein separates Energy-Charts-Messfeld.

## Zugang und Bereitstellung

Der in der Aufgabenbeschreibung genannte Benutzer `www26_test` lieferte am
10.09.2026 bei der Token-Anforderung HTTP 401. Der gespeicherte Datensatz wurde
deshalb mit dem ebenfalls bereitgestellten, funktionierenden Seminarzugang
exportiert. Das Skript verwendet standardmäßig `www26_test`, erlaubt aber eine
explizite Übergabe über `ENERGYCHARTS_USER`.

Die statische Anwendung lädt den normalisierten Export über HTTP. Dadurch
funktioniert sie auf GitLab Pages, ohne vertrauliche Zugangsdaten an
Browsernutzer auszuliefern. Die Daten bleiben durch das Exportskript aus der
PostgreSQL-Datenbank reproduzierbar.
