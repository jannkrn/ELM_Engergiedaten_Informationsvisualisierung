from __future__ import annotations

import json
import statistics
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATASET = ROOT / "public" / "data" / "energy.json"
OUTPUT = ROOT / "experiments" / "results" / "fallstudie_mai_2025.md"


def de(value: float, digits: int = 2) -> str:
    return f"{value:.{digits}f}".replace(".", ",")


def main() -> None:
    data = json.loads(DATASET.read_text(encoding="utf-8"))
    samples = data["samples"]

    prices = [float(sample["price"]) for sample in samples]
    renewables = [float(sample["generation"]["renewables"]) for sample in samples]
    totals = [sum(float(value) for value in sample["generation"].values()) for sample in samples]
    shares = [renewable / total for renewable, total in zip(renewables, totals)]
    net_flows = [sum(float(flow["value"]) for flow in sample["flows"]) for sample in samples]

    import_indexes = [index for index, value in enumerate(net_flows) if value >= 0]
    export_indexes = [index for index, value in enumerate(net_flows) if value < 0]

    def mean_at(values: list[float], indexes: list[int]) -> float:
        return statistics.fmean(values[index] for index in indexes)

    def line_for(index: int) -> str:
        sample = samples[index]
        return (
            f"| {sample['label']} | {de(prices[index])} | {de(renewables[index], 3)} | "
            f"{de(shares[index] * 100, 1)} % | {de(net_flows[index])} |"
        )

    min_price = min(range(len(samples)), key=prices.__getitem__)
    max_price = max(range(len(samples)), key=prices.__getitem__)
    max_renewables = max(range(len(samples)), key=renewables.__getitem__)
    max_import = max(range(len(samples)), key=net_flows.__getitem__)
    max_export = min(range(len(samples)), key=net_flows.__getitem__)

    countries = [flow["country"] for flow in samples[0]["flows"]]
    country_rows = []
    for country in countries:
        series = [next(float(flow["value"]) for flow in sample["flows"] if flow["country"] == country) for sample in samples]
        country_rows.append(
            f"| {country} | {de(statistics.fmean(series), 3)} | {de(min(series), 3)} | "
            f"{de(max(series), 3)} | {sum(value >= 0 for value in series)} | {sum(value < 0 for value in series)} |"
        )

    text = f"""# Fallstudienanalyse Mai 2025

Positive Flüsse bedeuten Import nach Deutschland, negative Export. Der
`summierte Fluss` ist die Summe der elf bilateralen CBPF-Werte je Stunde und
damit eine abgeleitete explorative Größe.

## Korrelationen (Pearson)

| Variablen | r |
|---|---:|
| Strompreis und erneuerbare Leistung | {de(statistics.correlation(prices, renewables), 3)} |
| Strompreis und Anteil Erneuerbarer | {de(statistics.correlation(prices, shares), 3)} |
| Strompreis und summierter Fluss | {de(statistics.correlation(prices, net_flows), 3)} |
| Erneuerbare Leistung und summierter Fluss | {de(statistics.correlation(renewables, net_flows), 3)} |

Die Werte beschreiben lineare Gleichläufigkeit im ausgewählten Monat und
belegen keine Kausalität.

## Vergleich nach Richtung des summierten Flusses

| Zustand | Stunden | mittlerer Preis (EUR/MWh) | mittlere Erneuerbare (GW) | mittlerer Anteil Erneuerbarer |
|---|---:|---:|---:|---:|
| positiver Summenfluss | {len(import_indexes)} | {de(mean_at(prices, import_indexes))} | {de(mean_at(renewables, import_indexes))} | {de(mean_at(shares, import_indexes) * 100, 1)} % |
| negativer Summenfluss | {len(export_indexes)} | {de(mean_at(prices, export_indexes))} | {de(mean_at(renewables, export_indexes))} | {de(mean_at(shares, export_indexes) * 100, 1)} % |

## Auffällige Stunden

| Zeitpunkt (UTC) | Preis (EUR/MWh) | Erneuerbare (GW) | Anteil Erneuerbare | summierter Fluss (GW) |
|---|---:|---:|---:|---:|
{line_for(min_price)}
{line_for(max_price)}
{line_for(max_renewables)}
{line_for(max_import)}
{line_for(max_export)}

## Partnerprofile

| Partner | Mittelwert (GW) | Minimum (GW) | Maximum (GW) | Importstunden | Exportstunden |
|---|---:|---:|---:|---:|---:|
{chr(10).join(country_rows)}
"""
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(text, encoding="utf-8")
    print(OUTPUT)


if __name__ == "__main__":
    main()
