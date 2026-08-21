# Datenquellen und Datenpfad

## Primärquelle: Energy-Charts in PostgreSQL

Die Energy-Charts-Daten sind über PostgREST unter folgender Basis-URL
erreichbar:

```text
https://dbs.informatik.uni-halle.de/sciencedata
```

Die Authentifizierung erfolgt mit `POST /token` und HTTP Basic Authentication.
Nach erfolgreicher Anmeldung wird der JWT als Bearer-Token gesendet. Für alle
fachlichen Tabellen und Views muss zusätzlich dieser Header gesetzt werden:

```http
Accept-Profile: energycharts
```

Am 21.08.2026 lieferte die OpenAPI-Beschreibung 66 Ressourcen. Für den
Prototyp werden ausschließlich folgende Views verwendet:

| View | Verwendung | zentrale Felder |
|---|---|---|
| `v_cbpf` | physische Grenzflüsse | `country_name`, `cross_boarder_physical_flow_in_gw` |
| `v_cbet` | grenzüberschreitender Handel | `country_name`, `cross_boarder_electricity_trading_in_gw` |
| `v_price` | Strompreis DE-LU | `market_id`, `price` |
| `v_totalpower` | deutscher Erzeugungsmix | Erzeugungsarten in separaten Spalten |

`v_publicpower` wurde geprüft, enthält für `country_id=de` jedoch nur
Nullwerte. Deshalb verwendet der Export die inhaltlich gefüllte View
`v_totalpower`. Deren deutschen Erzeugungswerte sind trotz des Suffixes
`_in_gw` als MW-Werte gespeichert; das Exportskript teilt sie durch 1000.

## Begrenzte Abfragen

Der Export für 01.-02.01.2025 filtert bereits auf Zeitraum, Deutschland und
Gebotszone. Jede Anfrage besitzt außerdem ein explizites Limit:

- `v_cbpf`: `country_id=eq.de`, Limit 5000,
- `v_cbet`: `country_id=eq.de`, Limit 5000,
- `v_totalpower`: `country_id=eq.de`, Limit 500,
- `v_price`: `market_id=eq.DE-LU`, Limit 100.

Tatsächlich wurden 2304 CBPF-Zeilen, 2304 CBET-Zeilen, 192 Erzeugungszeilen
und 48 Preiszeilen geladen. Die Viertelstundenwerte werden auf Stundenmittel
aggregiert. Ergebnis sind 48 Stunden und elf Partnerländer.

## Reproduzierbarer Export

Das Skript `scripts/build_postgrest_fixture.py` erzeugt
`public/data/energy.json`. Der Benutzername kann über `ENERGYCHARTS_USER`
gesetzt werden. Das Passwort wird entweder zur Laufzeit verdeckt abgefragt oder
über `ENERGYCHARTS_PASSWORD` bereitgestellt. Passwort und Token werden weder
gespeichert noch ausgegeben.

```powershell
python scripts/build_postgrest_fixture.py
elm make src/Main.elm --output=public/elm.js
```

Die normalisierte JSON-Datei enthält pro Stunde:

- gruppierten deutschen Erzeugungsmix,
- DE-LU-Strompreis,
- physischen Fluss pro Partnerland,
- Handelswert pro Partnerland.

Positive physische Flüsse bedeuten Import nach Deutschland, negative Werte
Export aus Deutschland. Physischer Fluss und Handel bleiben getrennte Werte.

## CORS

Die CORS-Preflight-Anfragen für `POST /token` und `GET /v_cbpf` wurden von der
ScienceData-Schnittstelle mit HTTP 204 beantwortet. Die lokale Origin sowie
`Authorization` und `Accept-Profile` wurden erlaubt. Der produktive Prototyp
lädt dennoch den vorab normalisierten JSON-Export, damit kein Passwort in einer
statischen GitLab-Pages-Anwendung eingegeben oder gespeichert werden muss.
