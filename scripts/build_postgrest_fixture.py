from __future__ import annotations

import base64
import getpass
import json
import os
import statistics
import urllib.parse
import urllib.request
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BASE = "https://dbs.informatik.uni-halle.de/sciencedata"
SCHEMA = "energycharts"
START = datetime.fromisoformat(os.environ.get("ENERGYCHARTS_START", "2025-05-01")).replace(tzinfo=timezone.utc)
END = datetime.fromisoformat(os.environ.get("ENERGYCHARTS_END", "2025-06-01")).replace(tzinfo=timezone.utc)
PAGE_SIZE = 1000

GENERATION_GROUPS = {
    "renewables": [
        "wind_onshore_in_gw",
        "wind_offshore_in_gw",
        "solar_in_gw",
        "biomass_in_gw",
        "hydro_run_of_river_in_gw",
        "hydro_water_reservoir_in_gw",
        "geothermal_in_gw",
    ],
    "coal": ["fossil_brown_coal_lignite_in_gw", "fossil_hard_coal_in_gw"],
    "gas": ["fossil_gas_in_gw"],
    "other": [
        "fossil_oil_in_gw",
        "fossil_coal_derived_gas_in_gw",
        "others_in_gw",
        "waste_in_gw",
        "hydro_pumped_storage_in_gw",
        "nuclear_energy_in_gw",
    ],
}


def request_json(url: str, headers: dict[str, str], method: str = "GET") -> object:
    data = b"" if method == "POST" else None
    request = urllib.request.Request(url, data=data, method=method, headers=headers)
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


def authenticate(username: str, password: str) -> str:
    basic = base64.b64encode(f"{username}:{password}".encode()).decode()
    payload = request_json(
        f"{BASE}/token",
        {"Authorization": f"Basic {basic}"},
        method="POST",
    )
    return payload["token"]


def fetch_table(
    token: str,
    table: str,
    params: list[tuple[str, str]],
    max_rows: int,
) -> list[dict]:
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept-Profile": SCHEMA,
        "Accept": "application/json",
    }
    rows: list[dict] = []
    offset = 0
    while offset < max_rows:
        page_params = params + [("limit", str(PAGE_SIZE)), ("offset", str(offset))]
        url = f"{BASE}/{table}?{urllib.parse.urlencode(page_params)}"
        page = request_json(url, headers)
        if not isinstance(page, list):
            raise RuntimeError(f"Unerwartete Antwort von {table}")
        rows.extend(page)
        if len(page) < PAGE_SIZE:
            return rows
        offset += PAGE_SIZE
    raise RuntimeError(f"Sicherheitslimit von {max_rows} Zeilen für {table} erreicht")


def common_filters(identifier: tuple[str, str], order: str) -> list[tuple[str, str]]:
    return [
        identifier,
        ("unix_seconds", f"gte.{int(START.timestamp())}"),
        ("unix_seconds", f"lt.{int(END.timestamp())}"),
        ("order", order),
    ]


def hourly_rows(rows: list[dict], field: str, scale: float = 1.0) -> dict[int, float]:
    buckets: dict[int, list[float]] = defaultdict(list)
    for row in rows:
        value = row.get(field)
        if value is not None:
            timestamp = int(row["unix_seconds"])
            hour = timestamp - timestamp % 3600
            buckets[hour].append(float(value) / scale)
    return {timestamp: statistics.fmean(values) for timestamp, values in buckets.items()}


def grouped_generation(rows: list[dict]) -> dict[str, dict[int, float]]:
    result: dict[str, dict[int, float]] = {}
    for group, fields in GENERATION_GROUPS.items():
        buckets: dict[int, list[float]] = defaultdict(list)
        for row in rows:
            timestamp = int(row["unix_seconds"])
            hour = timestamp - timestamp % 3600
            # The official Energy-Charts /total_power endpoint documents MW.
            # The seminar view retains those numeric values despite its _in_gw suffix.
            buckets[hour].append(sum(float(row.get(field) or 0) for field in fields) / 1000)
        result[group] = {timestamp: statistics.fmean(values) for timestamp, values in buckets.items()}
    return result


def partner_series(rows: list[dict], field: str) -> dict[str, dict[int, float]]:
    buckets: dict[str, dict[int, list[float]]] = defaultdict(lambda: defaultdict(list))
    for row in rows:
        country = str(row["country_name"])
        if country.lower() == "sum":
            continue
        timestamp = int(row["unix_seconds"])
        hour = timestamp - timestamp % 3600
        buckets[country][hour].append(float(row.get(field) or 0))
    return {
        country: {timestamp: statistics.fmean(values) for timestamp, values in hours.items()}
        for country, hours in buckets.items()
    }


def main() -> None:
    if END <= START:
        raise SystemExit("ENERGYCHARTS_END muss nach ENERGYCHARTS_START liegen.")

    username = os.environ.get("ENERGYCHARTS_USER", "www26_test")
    password = os.environ.get("ENERGYCHARTS_PASSWORD") or getpass.getpass("PostgREST-Passwort: ")
    token = authenticate(username, password)

    cbpf = fetch_table(
        token,
        "v_cbpf",
        [("select", "unix_seconds,country_name,cross_boarder_physical_flow_in_gw")]
        + common_filters(("country_id", "eq.de"), "unix_seconds.asc,country_name.asc"),
        max_rows=50000,
    )
    cbet = fetch_table(
        token,
        "v_cbet",
        [("select", "unix_seconds,country_name,cross_boarder_electricity_trading_in_gw")]
        + common_filters(("country_id", "eq.de"), "unix_seconds.asc,country_name.asc"),
        max_rows=50000,
    )
    totalpower = fetch_table(
        token,
        "v_totalpower",
        [("select", "unix_seconds," + ",".join(sorted({field for fields in GENERATION_GROUPS.values() for field in fields})))]
        + common_filters(("country_id", "eq.de"), "unix_seconds.asc"),
        max_rows=5000,
    )
    price = fetch_table(
        token,
        "v_price",
        [("select", "unix_seconds,price")]
        + common_filters(("market_id", "eq.DE-LU"), "unix_seconds.asc"),
        max_rows=2000,
    )

    physical = partner_series(cbpf, "cross_boarder_physical_flow_in_gw")
    trading = partner_series(cbet, "cross_boarder_electricity_trading_in_gw")
    generation = grouped_generation(totalpower)
    prices = hourly_rows(price, "price")
    hours = sorted(
        set(prices)
        & set(generation["renewables"])
        & set(generation["coal"])
        & set(generation["gas"])
        & set(generation["other"])
    )
    expected_hours = int((END - START).total_seconds() / 3600)
    if len(hours) != expected_hours:
        raise RuntimeError(f"Erwartet: {expected_hours} vollständige Stunden; gefunden: {len(hours)}")

    partners = sorted(
        country
        for country, series in physical.items()
        if all(timestamp in series for timestamp in hours)
    )
    if not partners:
        raise RuntimeError("Keine Partnerländer mit vollständiger Abdeckung gefunden")

    samples = []
    for timestamp in hours:
        samples.append(
            {
                "timestamp": timestamp,
                "label": datetime.fromtimestamp(timestamp, tz=timezone.utc).strftime("%d.%m. %H h"),
                "generation": {key: round(series[timestamp], 3) for key, series in generation.items()},
                "price": round(prices[timestamp], 2),
                "flows": [
                    {
                        "country": country,
                        "value": round(physical[country].get(timestamp, 0), 3),
                        "trade": round(trading.get(country, {}).get(timestamp, 0), 3),
                    }
                    for country in partners
                ],
            }
        )

    output = {
        "source": "Energy-Charts · PostgreSQL/PostgREST",
        "sourceStatus": "v_totalpower: MW→GW · v_cbpf/v_cbet: GW · v_price: EUR/MWh",
        "period": f"{START.strftime('%d.%m.%Y')}–{(END - timedelta(days=1)).strftime('%d.%m.%Y')} (UTC)",
        "samples": samples,
    }
    target = ROOT / "public" / "data" / "energy.json"
    target.write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8")
    print(
        f"{target}: {len(samples)} Stunden, {len(partners)} Partner; "
        f"Rohzeilen cbpf={len(cbpf)}, cbet={len(cbet)}, totalpower={len(totalpower)}, price={len(price)}"
    )


if __name__ == "__main__":
    main()
