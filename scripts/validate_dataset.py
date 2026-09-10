from __future__ import annotations

import json
import math
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATASET = ROOT / "public" / "data" / "energy.json"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> None:
    data = json.loads(DATASET.read_text(encoding="utf-8"))
    samples = data["samples"]
    require(len(samples) == 744, f"744 Stunden erwartet, gefunden: {len(samples)}")

    timestamps = [int(sample["timestamp"]) for sample in samples]
    require(
        all(right - left == 3600 for left, right in zip(timestamps, timestamps[1:])),
        "Zeitreihe ist nicht lückenlos stündlich.",
    )

    partners = [flow["country"] for flow in samples[0]["flows"]]
    require(len(partners) == 11, f"11 Partnerländer erwartet, gefunden: {len(partners)}")
    require(len(set(partners)) == len(partners), "Partnerländer sind nicht eindeutig.")

    physical_values: list[float] = []
    prices: list[float] = []
    renewable_values: list[float] = []
    for sample in samples:
        current_partners = [flow["country"] for flow in sample["flows"]]
        require(current_partners == partners, "Partnerreihenfolge oder -abdeckung ist inkonsistent.")
        values = [
            *sample["generation"].values(),
            sample["price"],
            *(flow["value"] for flow in sample["flows"]),
            *(flow["trade"] for flow in sample["flows"]),
        ]
        require(all(math.isfinite(float(value)) for value in values), "Nicht-endlicher Messwert gefunden.")
        require(all(float(value) >= 0 for value in sample["generation"].values()), "Negative Erzeugung gefunden.")
        require(sum(float(value) for value in sample["generation"].values()) < 200, "Erzeugung außerhalb plausibler GW-Grenze.")
        physical_values.extend(float(flow["value"]) for flow in sample["flows"])
        prices.append(float(sample["price"]))
        renewable_values.append(float(sample["generation"]["renewables"]))

    require(min(physical_values) < 0 < max(physical_values), "Import- und Exportwerte müssen beide vorkommen.")
    require(max(abs(value) for value in physical_values) < 20, "Grenzfluss außerhalb plausibler GW-Grenze.")

    net = [sum(float(flow["value"]) for flow in sample["flows"]) for sample in samples]
    direction_changes = sum(
        1 for left, right in zip(net, net[1:]) if (left < 0 <= right) or (left >= 0 > right)
    )
    min_price_index = min(range(len(prices)), key=prices.__getitem__)
    max_price_index = max(range(len(prices)), key=prices.__getitem__)

    def stamp(index: int) -> str:
        return datetime.fromtimestamp(timestamps[index], tz=timezone.utc).strftime("%d.%m.%Y %H:%M UTC")

    print("Datensatzprüfung erfolgreich")
    print(f"Zeitraum: {stamp(0)} bis {stamp(len(samples) - 1)}")
    print(f"Stunden: {len(samples)}; Partnerländer: {len(partners)}")
    print(f"Summierter physischer Fluss: {sum(value >= 0 for value in net)} Importstunden, {sum(value < 0 for value in net)} Exportstunden")
    print(f"Richtungswechsel: {direction_changes}")
    print(f"Negative Preisstunden: {sum(value < 0 for value in prices)}")
    print(f"Minimum Preis: {prices[min_price_index]:.2f} EUR/MWh am {stamp(min_price_index)}")
    print(f"Maximum Preis: {prices[max_price_index]:.2f} EUR/MWh am {stamp(max_price_index)}")
    print(f"Maximum Erneuerbare: {max(renewable_values):.3f} GW")


if __name__ == "__main__":
    main()
