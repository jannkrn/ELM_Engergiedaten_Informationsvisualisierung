from __future__ import annotations

import json
import statistics
import urllib.request
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BASE = "https://api.energy-charts.info"
START = "2025-01-01"
END = "2025-01-02"


def fetch(path: str) -> dict:
    with urllib.request.urlopen(f"{BASE}/{path}", timeout=30) as response:
        return json.load(response)


def hourly(timestamps: list[int], values: list[float]) -> dict[int, float]:
    buckets: dict[int, list[float]] = defaultdict(list)
    for timestamp, value in zip(timestamps, values):
        hour = int(timestamp) - int(timestamp) % 3600
        buckets[hour].append(float(value or 0))
    return {key: statistics.fmean(group) for key, group in buckets.items()}


def main() -> None:
    cbpf = fetch(f"cbpf?country=de&start={START}&end={END}")
    power = fetch(f"public_power?country=de&start={START}&end={END}")
    price = fetch(f"price?bzn=DE-LU&start={START}&end={END}")

    timestamps = [int(value) for value in cbpf["unix_seconds"]]
    flow_series = {
        item["name"]: hourly(timestamps, [float(value or 0) for value in item["data"]])
        for item in cbpf["countries"]
        if item["name"].lower() != "sum"
    }
    production = {item["name"]: item["data"] for item in power["production_types"]}

    groups = {
        "renewables": ["Wind onshore", "Wind offshore", "Solar", "Biomass", "Hydro Run-of-River", "Hydro water reservoir", "Geothermal"],
        "coal": ["Fossil brown coal / lignite", "Fossil hard coal"],
        "gas": ["Fossil gas"],
        "other": ["Fossil oil", "Fossil coal-derived gas", "Others", "Waste", "Hydro pumped storage"],
    }
    generation = {}
    for key, names in groups.items():
        values = [sum(float(production[name][i] or 0) for name in names if name in production) / 1000 for i in range(len(timestamps))]
        generation[key] = hourly(timestamps, values)

    price_hourly = hourly([int(value) for value in price["unix_seconds"]], [float(value) for value in price["price"]])
    hours = sorted(set(price_hourly) & set(generation["renewables"]))
    samples = []
    for timestamp in hours:
        samples.append(
            {
                "timestamp": timestamp,
                "label": datetime.fromtimestamp(timestamp, tz=timezone.utc).strftime("%d.%m. %H h"),
                "generation": {key: round(series[timestamp], 3) for key, series in generation.items()},
                "price": round(price_hourly[timestamp], 2),
                "flows": [
                    {"country": country, "value": round(series.get(timestamp, 0), 3)}
                    for country, series in flow_series.items()
                ],
            }
        )

    output = {
        "source": "Energy-Charts-Daten · Elm-HTTP-Fixture",
        "sourceStatus": "Fallback, da Seminar-Schema leer",
        "period": "01.–02. Januar 2025",
        "samples": samples,
    }
    target = ROOT / "public" / "data" / "energy.json"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"{target} ({len(samples)} Stunden)")


if __name__ == "__main__":
    main()
